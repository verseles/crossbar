// ignore_for_file: avoid_slow_async_io
import 'dart:convert';
import 'dart:io';

import 'package:crossbar_core/crossbar_core.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

import '../services/config_service.dart';
import 'paths/platform_paths.dart'
    if (dart.library.ui) 'paths/platform_paths_flutter.dart';
import 'plugin_executor.dart';

class PluginManager {
  factory PluginManager() => _instance;

  PluginManager._internal();
  static final PluginManager _instance = PluginManager._internal();

  final List<Plugin> _plugins = [];
  final PluginExecutor _pluginExecutor = PluginExecutor();
  final PluginConfigService _configService = PluginConfigService();
  static const int maxConcurrent = 10;
  int _emptyDiscoveryStreak = 0;

  static const List<String> supportedLanguages = [
    'bash',
    'python',
    'node',
    'dart',
    'go',
    'rust',
    'lua', // Embedded - works everywhere
  ];

  static const Map<String, String> extensionToInterpreter = {
    '.sh': 'bash',
    '.py': 'python3',
    '.js': 'node',
    '.dart': 'dart',
    '.go': 'go',
    '.rs': 'rust',
    '.lua': 'lua', // Embedded lua_dardo interpreter
    '.yaml': 'yaml',
    '.yml': 'yaml',
  };

  static const List<String> allowedExtensions = [
    '.sh',
    '.py',
    '.js',
    '.dart',
    '.go',
    '.rs',
    '.lua', // Embedded - works everywhere
    '.yaml',
    '.yml',
  ];

  List<Plugin> get plugins => List.unmodifiable(_plugins);

  String? _customPluginsDirectory;

  @visibleForTesting
  set customPluginsDirectory(String? path) => _customPluginsDirectory = path;

  Future<String> get pluginsDirectory async {
    if (_customPluginsDirectory != null) return _customPluginsDirectory!;

    if (Platform.isAndroid || Platform.isIOS) {
      // Mobile: use app documents directory
      return getMobilePluginsDirectory();
    } else {
      // Desktop: use $HOME/.crossbar/plugins
      final homeDir =
          Platform.environment['HOME'] ??
          Platform.environment['USERPROFILE'] ??
          '';
      return path.join(homeDir, '.crossbar', 'plugins');
    }
  }

  bool _isValidPluginFile(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    return allowedExtensions.contains(ext);
  }

  Future<void> discoverPlugins() async {
    final pluginsDirPath = await pluginsDirectory;
    final pluginsDir = Directory(pluginsDirPath);

    if (!await pluginsDir.exists()) {
      if (_plugins.isNotEmpty) {
        _emptyDiscoveryStreak++;
        if (_emptyDiscoveryStreak < 2) {
          return;
        }
      }
      _emptyDiscoveryStreak = 0;
      _plugins.clear();
      return;
    }

    // Map to group plugins by their directory and base name
    // Key: directory_path:base_name
    final groups = <String, List<File>>{};
    var foundFiles = 0;

    await for (final entity in pluginsDir.list(recursive: true)) {
      if (entity is File && _isValidPluginFile(entity.path)) {
        foundFiles++;
        final dir = path.dirname(entity.path);
        final fileName = path.basename(entity.path);

        // Extract base name (part before the first dot that matches interval pattern)
        // e.g. cpu.10s.sh -> cpu
        final baseName = _extractPluginBaseName(fileName);

        final key = '$dir:$baseName';
        groups.putIfAbsent(key, () => []).add(entity);
      }
    }

    final discovered = <Plugin>[];

    for (final entry in groups.entries) {
      final files = entry.value;
      if (files.isEmpty) continue;

      // Create a single plugin representing this group
      final plugin = await _createPluginFromGroup(files);
      if (plugin != null) {
        discovered.add(plugin);
      }
    }

    if (_plugins.isNotEmpty) {
      final emptyDiscovery =
          foundFiles == 0 || (foundFiles > 0 && discovered.isEmpty);
      if (emptyDiscovery) {
        _emptyDiscoveryStreak++;
        if (_emptyDiscoveryStreak < 2) {
          return;
        }
      }
    }

    _emptyDiscoveryStreak = 0;
    _plugins
      ..clear()
      ..addAll(discovered);
  }

  String _extractPluginBaseName(String fileName) {
    final match = RegExp(
      r'^(.+?)\.(?:\d+(?:\.\d+)?)[smh]\.',
    ).firstMatch(fileName);
    if (match != null) {
      return match.group(1)!;
    }
    // Fallback: name before first dot
    final firstDot = fileName.indexOf('.');
    if (firstDot > 0) {
      return fileName.substring(0, firstDot);
    }
    return path.withoutExtension(fileName);
  }

  Future<Plugin?> _createPluginFromGroup(List<File> files) async {
    // Sort files to have a deterministic primary variant (prefer .lua then .sh then others)
    files.sort((a, b) {
      final extA = path.extension(a.path).toLowerCase();
      final extB = path.extension(b.path).toLowerCase();

      const priority = {
        '.lua': 0,
        '.sh': 1,
        '.py': 2,
        '.js': 3,
        '.dart': 4,
        '.go': 5,
        '.rs': 6,
      };
      final pA = priority[extA] ?? 100;
      final pB = priority[extB] ?? 100;
      return pA.compareTo(pB);
    });

    final variants = <PluginVariant>[];

    for (final file in files) {
      final interpreter = _detectInterpreter(file);
      if (interpreter == null) continue;

      final isEnabled = await _checkIfEnabled(file);
      variants.add(
        PluginVariant(
          path: file.path,
          interpreter: interpreter,
          enabled: isEnabled,
        ),
      );
    }

    if (variants.isEmpty) return null;

    final primaryVariant = variants.first;
    final fileName = path.basename(primaryVariant.path);
    final refreshInterval = _parseRefreshInterval(fileName);

    // ID is the base name if in a subdirectory, otherwise filename
    final dir = path.dirname(primaryVariant.path);
    final pluginsDirPath = await pluginsDirectory;
    final isRoot = path.equals(dir, pluginsDirPath);

    final id = isRoot ? fileName : path.basename(dir);

    final config = await _loadPluginConfig(primaryVariant.path);
    final configValues = await _configService.loadValues(id, schema: config);
    final customTitle = _configService.getCustomTitle(configValues);

    return Plugin(
      id: id,
      path: primaryVariant.path,
      interpreter: primaryVariant.interpreter,
      refreshInterval: refreshInterval,
      customTitle: customTitle,
      enabled: primaryVariant.enabled,
      config: config,
      variants: variants,
    );
  }

  Future<bool> _checkIfEnabled(File file) async {
    final fileName = path.basename(file.path);
    if (fileName.contains('.off.')) return false;

    if (Platform.isLinux || Platform.isMacOS) {
      try {
        final stat = await file.stat();
        return (stat.mode & 0x49) != 0;
      } catch (_) {
        return true;
      }
    }
    return true;
  }

  /// Loads plugin configuration schema from a .schema.json file.
  ///
  /// Looks for a file named `<pluginPath>.schema.json`.
  /// Returns null if no config file exists.
  Future<PluginConfig?> _loadPluginConfig(String pluginPath) async {
    final configPath = '$pluginPath.schema.json';
    final configFile = File(configPath);

    if (!await configFile.exists()) {
      return null;
    }

    try {
      final content = await configFile.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return PluginConfig.fromJson(json);
    } catch (e) {
      // Log error but don't fail plugin loading
      // ignore: avoid_print
      print('Error loading config for $pluginPath: $e');
      return null;
    }
  }

  String? _detectInterpreter(File file) {
    final ext = path.extension(file.path).toLowerCase();

    try {
      final content = file.readAsStringSync();
      final lines = content.split('\n');
      if (lines.isNotEmpty) {
        final firstLine = lines.first;
        if (firstLine.startsWith('#!')) {
          if (firstLine.contains('python')) return 'python3';
          if (firstLine.contains('node')) return 'node';
          if (firstLine.contains('bash')) return 'bash';
          if (firstLine.contains('sh')) return 'sh';
          if (firstLine.contains('dart')) return 'dart';
        }
      }
    } catch (_) {}

    return extensionToInterpreter[ext];
  }

  Duration _parseRefreshInterval(String fileName) {
    final match = RegExp(r'\.(\d+(?:\.\d+)?)([smh])\.').firstMatch(fileName);

    if (match != null) {
      final value = double.parse(match.group(1)!);
      final unit = match.group(2)!;

      Duration interval;
      switch (unit) {
        case 's':
          interval = Duration(milliseconds: (value * 1000).round());
        case 'm':
          interval = Duration(minutes: value.round());
        case 'h':
          interval = Duration(hours: value.round());
        default:
          interval = const Duration(minutes: 5);
      }

      if (interval < const Duration(seconds: 1)) {
        return const Duration(seconds: 1);
      }

      return interval;
    }

    return const Duration(minutes: 5);
  }

  Future<List<PluginOutput>> runAllEnabled() async {
    final outputs = <PluginOutput>[];
    final enabledPlugins = _plugins.where((p) => p.enabled).toList();

    for (var i = 0; i < enabledPlugins.length; i += maxConcurrent) {
      final batch = enabledPlugins.skip(i).take(maxConcurrent);
      final batchOutputs = await Future.wait(batch.map(_runPlugin));
      outputs.addAll(batchOutputs.whereType<PluginOutput>());
    }

    return outputs;
  }

  Future<PluginOutput?> runPlugin(String pluginId) async {
    final plugin = _plugins.where((p) => p.id == pluginId).firstOrNull;
    if (plugin == null) return null;
    return _runPlugin(plugin);
  }

  Future<PluginOutput?> _runPlugin(Plugin plugin) async {
    try {
      // Load config values if plugin has config
      var configEnv = <String, String>{};
      final configValues = await _configService.loadValues(
        plugin.id,
        schema: plugin.config,
      );
      if (configValues.isNotEmpty) {
        configEnv = await _configService.getAsEnvironmentVariables(
          plugin.id,
          schema: plugin.config,
        );
      }

      final output = await _pluginExecutor.run(
        plugin,
        additionalEnv: configEnv,
      );
      final customTitle = _configService.getCustomTitle(configValues);
      final titledOutput = customTitle != null
          ? output.copyWith(title: customTitle)
          : output;

      final index = _plugins.indexWhere((p) => p.id == plugin.id);
      if (index >= 0) {
        _plugins[index] = plugin.copyWith(
          lastRun: DateTime.now(),
          lastError: titledOutput.hasError ? titledOutput.errorMessage : null,
        );
      }

      return titledOutput;
    } catch (e) {
      final index = _plugins.indexWhere((p) => p.id == plugin.id);
      if (index >= 0) {
        _plugins[index] = plugin.copyWith(
          lastRun: DateTime.now(),
          lastError: e.toString(),
        );
      }
      return PluginOutput.error(
        plugin.id,
        e.toString(),
      ).copyWith(title: plugin.displayName);
    }
  }

  Future<void> togglePlugin(String pluginId) async {
    final plugin = getPlugin(pluginId);
    if (plugin == null) return;

    if (plugin.enabled) {
      await disablePlugin(pluginId);
    } else {
      await enablePlugin(pluginId);
    }
  }

  Future<void> enablePlugin(String pluginId) async {
    final plugin = getPlugin(pluginId);
    if (plugin == null) return;

    final fileName = path.basename(plugin.path);
    final dir = path.dirname(plugin.path);

    var newPath = plugin.path;
    var newId = plugin.id;

    // 1. Rename file if contains .off.
    if (fileName.contains('.off.')) {
      final newFileName = fileName.replaceFirst('.off.', '.');
      newPath = path.join(dir, newFileName);

      if (plugin.id == fileName) {
        newId = newFileName;
      }

      try {
        await File(plugin.path).rename(newPath);
      } catch (e) {
        // ignore: avoid_print
        print('Error renaming file: $e');
        return;
      }
    }

    // 2. Chmod +x
    if (Platform.isLinux || Platform.isMacOS) {
      try {
        await Process.run('chmod', ['+x', newPath]);
      } catch (e) {
        // ignore: avoid_print
        print('Error chmod +x: $e');
      }
    }

    // 3. Update list
    _updatePluginInList(pluginId, newId, newPath, true);
  }

  Future<void> disablePlugin(String pluginId) async {
    final plugin = getPlugin(pluginId);
    if (plugin == null) return;

    final fileName = path.basename(plugin.path);
    final dir = path.dirname(plugin.path);

    var newPath = plugin.path;
    var newId = plugin.id;

    // 1. Rename to add .off. if not present
    if (!fileName.contains('.off.')) {
      final ext = path.extension(fileName);
      final base = path.withoutExtension(fileName);
      final newFileName = '$base.off$ext';
      newPath = path.join(dir, newFileName);

      if (plugin.id == fileName) {
        newId = newFileName;
      }

      try {
        await File(plugin.path).rename(newPath);
      } catch (e) {
        // ignore: avoid_print
        print('Error renaming: $e');
        return;
      }
    }

    // 2. Chmod -x
    if (Platform.isLinux || Platform.isMacOS) {
      try {
        await Process.run('chmod', ['-x', newPath]);
      } catch (e) {
        // ignore: avoid_print
        print('Error chmod -x: $e');
      }
    }

    // 3. Update list
    _updatePluginInList(pluginId, newId, newPath, false);
  }

  void _updatePluginInList(
    String oldId,
    String newId,
    String newPath,
    bool enabled,
  ) {
    final index = _plugins.indexWhere((p) => p.id == oldId);
    if (index >= 0) {
      _plugins[index] = _plugins[index].copyWith(
        id: newId,
        path: newPath,
        enabled: enabled,
      );
    }
  }

  Plugin? getPlugin(String pluginId) {
    return _plugins.where((p) => p.id == pluginId).firstOrNull;
  }

  Future<void> switchPluginVariant(
    String pluginId,
    PluginVariant variant,
  ) async {
    final index = _plugins.indexWhere((p) => p.id == pluginId);
    if (index >= 0) {
      _plugins[index] = _plugins[index].copyWith(
        path: variant.path,
        interpreter: variant.interpreter,
        enabled: variant.enabled,
      );
    }
  }

  void clear() {
    _plugins.clear();
    _emptyDiscoveryStreak = 0;
  }
}
