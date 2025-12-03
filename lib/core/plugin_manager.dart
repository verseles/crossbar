import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../models/plugin.dart';
import '../models/plugin_output.dart';
import 'script_runner.dart';

class PluginManager {
  static final PluginManager _instance = PluginManager._internal();

  factory PluginManager() => _instance;

  PluginManager._internal();

  final List<Plugin> _plugins = [];
  final ScriptRunner _scriptRunner = const ScriptRunner();
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
      final appDir = await getApplicationDocumentsDirectory();
      return path.join(appDir.path, 'plugins');
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
      if (entity is File && _isExecutableFile(entity.path)) {
        final plugin = await _createPluginFromFile(entity);
        if (plugin != null) {
          _plugins.add(plugin);
        }
      } else if (entity is Directory) {
        // Check subdirectories (git repos) but only 1 level deep
        await for (final subEntity in entity.list()) {
          if (subEntity is File && _isExecutableFile(subEntity.path)) {
            final plugin = await _createPluginFromFile(subEntity);
            if (plugin != null) {
              _plugins.add(plugin);
            }
          }
        }
      }
    }
  }

  bool _isExecutableFile(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    return allowedExtensions.contains(ext);
  }

  Future<Plugin?> _createPluginFromFile(File file) async {
    final fileName = path.basename(file.path);

    final interpreter = _detectInterpreter(file);
    if (interpreter == null) return null;

    final refreshInterval = _parseRefreshInterval(fileName);

    return Plugin(
      id: fileName,
      path: file.path,
      interpreter: interpreter,
      refreshInterval: refreshInterval,
      enabled: true,
    );
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
        batch.map((plugin) => _runPlugin(plugin)),
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
      final output = await _scriptRunner.run(plugin);

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

  void togglePlugin(String pluginId) {
    final index = _plugins.indexWhere((p) => p.id == pluginId);
    if (index >= 0) {
      _plugins[index] = _plugins[index].copyWith(
        enabled: !_plugins[index].enabled,
      );
    }
  }

  void enablePlugin(String pluginId) {
    final index = _plugins.indexWhere((p) => p.id == pluginId);
    if (index >= 0) {
      _plugins[index] = _plugins[index].copyWith(enabled: true);
    }
  }

  void disablePlugin(String pluginId) {
    final index = _plugins.indexWhere((p) => p.id == pluginId);
    if (index >= 0) {
      _plugins[index] = _plugins[index].copyWith(enabled: false);
    }
  }

  Plugin? getPlugin(String pluginId) {
    return _plugins.where((p) => p.id == pluginId).firstOrNull;
  }

  void clear() {
    _plugins.clear();
  }
}
