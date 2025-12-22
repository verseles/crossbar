// ignore_for_file: avoid_slow_async_io
import 'dart:convert';
import 'dart:io';

import 'package:crossbar_core/crossbar_core.dart';
import 'package:path/path.dart' as path;

/// CLI-only PluginManager - No Flutter dependencies
/// 
/// Simplified version that:
/// - Only works on desktop (Linux, macOS, Windows)
/// - Reads config from JSON files (not secure storage)
/// - Uses external interpreters for all plugins
class PluginManagerCli {
  factory PluginManagerCli() => _instance;
  PluginManagerCli._internal();
  
  static final PluginManagerCli _instance = PluginManagerCli._internal();

  final List<Plugin> _plugins = [];

  static const List<String> allowedExtensions = [
    '.sh', '.py', '.js', '.dart', '.go', '.rs', '.lua', '.yaml', '.yml',
  ];

  static const Map<String, String> extensionToInterpreter = {
    '.sh': 'bash',
    '.py': 'python3',
    '.js': 'node',
    '.dart': 'dart',
    '.go': 'go',
    '.rs': 'rust',
    '.lua': 'lua',
    '.yaml': 'yaml',
    '.yml': 'yaml',
  };

  List<Plugin> get plugins => List.unmodifiable(_plugins);

  String get pluginsDirectory {
    final homeDir = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '';
    return path.join(homeDir, '.crossbar', 'plugins');
  }

  Future<void> discoverPlugins() async {
    _plugins.clear();

    final pluginsDir = Directory(pluginsDirectory);
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

    var isEnabled = true;
    if (fileName.contains('.off.')) {
      isEnabled = false;
    } else if (Platform.isLinux || Platform.isMacOS) {
      try {
        final stat = await file.stat();
        if ((stat.mode & 0x49) == 0) {
          isEnabled = false;
        }
      } catch (_) {}
    }

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

  Plugin? getPlugin(String pluginId) {
    return _plugins.where((p) => p.id == pluginId).firstOrNull;
  }

  /// Run a plugin and return its output
  Future<PluginOutput?> runPlugin(String pluginId) async {
    final plugin = getPlugin(pluginId);
    if (plugin == null) return null;

    try {
      // Load config values from JSON file
      final configEnv = await _loadConfigValues(pluginId);

      // Build environment
      final env = <String, String>{
        ...Platform.environment,
        ...configEnv,
        'CROSSBAR_PLUGIN_ID': pluginId,
        'CROSSBAR_PLUGIN_PATH': plugin.path,
      };

      // Run the plugin
      final result = await _executePlugin(plugin, env);
      
      if (result.exitCode != 0 && result.stderr.toString().isNotEmpty) {
        return PluginOutput.error(pluginId, result.stderr.toString());
      }

      final output = result.stdout.toString();
      return OutputParser.parse(output, pluginId);
    } catch (e) {
      return PluginOutput.error(pluginId, e.toString());
    }
  }

  Future<ProcessResult> _executePlugin(Plugin plugin, Map<String, String> env) async {
    final ext = path.extension(plugin.path).toLowerCase();
    
    switch (ext) {
      case '.sh':
        return Process.run('bash', [plugin.path], environment: env);
      case '.py':
        return Process.run('python3', [plugin.path], environment: env);
      case '.js':
        return Process.run('node', [plugin.path], environment: env);
      case '.dart':
        return Process.run('dart', ['run', plugin.path], environment: env);
      case '.go':
        return Process.run('go', ['run', plugin.path], environment: env);
      case '.lua':
        return Process.run('lua', [plugin.path], environment: env);
      default:
        return Process.run(plugin.path, [], environment: env);
    }
  }

  /// Load config values from JSON file
  Future<Map<String, String>> _loadConfigValues(String pluginId) async {
    final homeDir = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '';
    final configPath = path.join(homeDir, '.crossbar', 'config', '$pluginId.json');
    final configFile = File(configPath);

    if (!await configFile.exists()) {
      return {};
    }

    try {
      final content = await configFile.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return json.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return {};
    }
  }
}
