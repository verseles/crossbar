import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

import 'paths/platform_paths.dart'
    if (dart.library.ui) 'paths/platform_paths_flutter.dart';

import '../models/plugin.dart';
import '../models/plugin_config.dart';
import '../models/plugin_output.dart';
import '../services/plugin_config_service.dart';
import 'script_runner.dart';

class PluginManager {

  factory PluginManager() => _instance;

  PluginManager._internal();
  static final PluginManager _instance = PluginManager._internal();

  final List<Plugin> _plugins = [];
  final ScriptRunner _scriptRunner = const ScriptRunner();
  final PluginConfigService _configService = PluginConfigService();
  static const int maxConcurrent = 10;

  static const List<String> supportedLanguages = [
    'bash',
    'python',
    'node',
    'dart',
    'go',
    'rust',
  ];

  static const Map<String, String> extensionToInterpreter = {
    '.sh': 'bash',
    '.py': 'python3',
    '.js': 'node',
    '.dart': 'dart',
    '.go': 'go',
    '.rs': 'rust',
  };

  static const List<String> allowedExtensions = [
    '.sh',
    '.py',
    '.js',
    '.dart',
    '.go',
    '.rs',
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
      final homeDir = Platform.environment['HOME'] ??
          Platform.environment['USERPROFILE'] ??
          '';
      return path.join(homeDir, '.crossbar', 'plugins');
    }
  }

  Future<void> discoverPlugins() async {
    _plugins.clear();

    final pluginsDirPath = await pluginsDirectory;
    final pluginsDir = Directory(pluginsDirPath);

    if (!await pluginsDir.exists()) {
      return;
    }

    await for (final entity in pluginsDir.list()) {
      if (entity is File && _isValidPluginFile(entity.path)) {
        final plugin = await _createPluginFromFile(entity);
        if (plugin != null) {
          _plugins.add(plugin);
        }
      } else if (entity is Directory) {
        // Check subdirectories (git repos) but only 1 level deep
        await for (final subEntity in entity.list()) {
          if (subEntity is File && _isValidPluginFile(subEntity.path)) {
            final plugin = await _createPluginFromFile(subEntity);
            if (plugin != null) {
              _plugins.add(plugin);
            }
          }
        }
      }
    }
  }

  bool _isValidPluginFile(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    return allowedExtensions.contains(ext);
  }

  Future<Plugin?> _createPluginFromFile(File file) async {
    final fileName = path.basename(file.path);

    final interpreter = _detectInterpreter(file);
    if (interpreter == null) return null;

    final refreshInterval = _parseRefreshInterval(fileName);

    // Determine enabled state
    bool isEnabled = true;

    // 1. Check filename for .off.
    if (fileName.contains('.off.')) {
      isEnabled = false;
    }
    // 2. Check permissions on Unix
    else if (Platform.isLinux || Platform.isMacOS) {
      try {
        final stat = await file.stat();
        // Check if executable bit is set for user (00100 -> 0x40)
        // 0x49 = 0111 octal (user, group, other exec)
        if ((stat.mode & 0x49) == 0) {
          isEnabled = false;
        }
      } catch (_) {
        // Ignore errors, default to true
      }
    }

    // Load config schema if exists
    // Config file naming: <pluginName>.config.json
    // e.g., weather.10m.py -> weather.10m.py.config.json
    final config = await _loadPluginConfig(file.path);

    return Plugin(
      id: fileName,
      path: file.path,
      interpreter: interpreter,
      refreshInterval: refreshInterval,
      enabled: isEnabled,
      config: config,
    );
  }

  /// Loads plugin configuration schema from a .config.json file.
  ///
  /// Looks for a file named `<pluginPath>.config.json`.
  /// Returns null if no config file exists.
  Future<PluginConfig?> _loadPluginConfig(String pluginPath) async {
    final configPath = '$pluginPath.config.json';
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
      final batchOutputs = await Future.wait(
        batch.map(_runPlugin),
      );
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
      Map<String, String> configEnv = {};
      if (plugin.config != null) {
        configEnv = await _configService.getAsEnvironmentVariables(
          plugin.id,
          schema: plugin.config,
        );
      }

      final output = await _scriptRunner.run(
        plugin,
        additionalEnv: configEnv,
      );

      final index = _plugins.indexWhere((p) => p.id == plugin.id);
      if (index >= 0) {
        _plugins[index] = plugin.copyWith(
          lastRun: DateTime.now(),
          lastError: output.hasError ? output.errorMessage : null,
        );
      }

      return output;
    } catch (e) {
      final index = _plugins.indexWhere((p) => p.id == plugin.id);
      if (index >= 0) {
        _plugins[index] = plugin.copyWith(
          lastRun: DateTime.now(),
          lastError: e.toString(),
        );
      }
      return PluginOutput.error(plugin.id, e.toString());
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

    var newPath = plugin.path;
    var newId = plugin.id;

    // 1. Rename if contains .off.
    if (plugin.id.contains('.off.')) {
      newId = plugin.id.replaceFirst('.off.', '.');
      final dir = path.dirname(plugin.path);
      newPath = path.join(dir, newId);

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

    var newPath = plugin.path;
    var newId = plugin.id;

    // 1. Rename to add .off. if not present
    if (!plugin.id.contains('.off.')) {
      final ext = path.extension(plugin.id);
      final base = path.withoutExtension(plugin.id);
      newId = '$base.off$ext';
      final dir = path.dirname(plugin.path);
      newPath = path.join(dir, newId);

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

  void _updatePluginInList(String oldId, String newId, String newPath, bool enabled) {
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

  void clear() {
    _plugins.clear();
  }
}
