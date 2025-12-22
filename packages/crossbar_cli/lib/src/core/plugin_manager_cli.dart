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
    final customDir = Platform.environment['CROSSBAR_PLUGINS_DIR'];
    if (customDir != null && customDir.isNotEmpty) {
      return customDir;
    }

    final homeDir = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '';
    return path.join(homeDir, '.crossbar', 'plugins');
  }

  bool _isValidPluginFile(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    return allowedExtensions.contains(ext);
  }

  Future<void> discoverPlugins() async {
    _plugins.clear();

    final pluginsDir = Directory(pluginsDirectory);
    if (!await pluginsDir.exists()) {
      return;
    }

    // Map to group plugins by their directory and base name
    final Map<String, List<File>> groups = {};

    await for (final entity in pluginsDir.list(recursive: true)) {
      if (entity is File && _isValidPluginFile(entity.path)) {
        final dir = path.dirname(entity.path);
        final fileName = path.basename(entity.path);
        final baseName = _extractPluginBaseName(fileName);
        
        final key = '$dir:$baseName';
        groups.putIfAbsent(key, () => []).add(entity);
      }
    }

    for (final entry in groups.entries) {
      final files = entry.value;
      if (files.isEmpty) continue;

      final plugin = await _createPluginFromGroup(files);
      if (plugin != null) {
        _plugins.add(plugin);
      }
    }
  }

  String _extractPluginBaseName(String fileName) {
    final match = RegExp(r'^(.+?)\.(?:\d+(?:\.\d+)?)[smh]\.').firstMatch(fileName);
    if (match != null) {
      return match.group(1)!;
    }
    final firstDot = fileName.indexOf('.');
    if (firstDot > 0) {
      return fileName.substring(0, firstDot);
    }
    return path.withoutExtension(fileName);
  }

  Future<Plugin?> _createPluginFromGroup(List<File> files) async {
    files.sort((a, b) {
      final extA = path.extension(a.path).toLowerCase();
      final extB = path.extension(b.path).toLowerCase();
      const priority = {'.lua': 0, '.sh': 1, '.py': 2, '.js': 3, '.dart': 4, '.go': 5, '.rs': 6};
      final pA = priority[extA] ?? 100;
      final pB = priority[extB] ?? 100;
      return pA.compareTo(pB);
    });

    final variants = <PluginVariant>[];
    for (final file in files) {
      final interpreter = _detectInterpreter(file);
      if (interpreter == null) continue;

      final isEnabled = await _checkIfEnabled(file);
      variants.add(PluginVariant(
        path: file.path,
        interpreter: interpreter,
        enabled: isEnabled,
      ));
    }

    if (variants.isEmpty) return null;

    final primaryVariant = variants.first;
    final fileName = path.basename(primaryVariant.path);
    final refreshInterval = _parseRefreshInterval(fileName);
    
    final dir = path.dirname(primaryVariant.path);
    final isRoot = path.equals(dir, pluginsDirectory);
    final id = isRoot ? fileName : path.basename(dir);

    final config = await _loadPluginConfig(primaryVariant.path);

    return Plugin(
      id: id,
      path: primaryVariant.path,
      interpreter: primaryVariant.interpreter,
      refreshInterval: refreshInterval,
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
      } catch (_) { return true; }
    }
    return true;
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
