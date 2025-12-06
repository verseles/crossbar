import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as path;

import '../core/plugin_manager.dart';

/// Represents a sample plugin that comes bundled with the app.
class SamplePlugin {
  const SamplePlugin({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.language,
    required this.assetPath,
    this.schemaAssetPath,
  });

  final String id;
  final String name;
  final String description;
  final String category;
  final String language;
  final String assetPath;
  final String? schemaAssetPath;

  /// Get the language icon/emoji
  String get languageIcon {
    switch (language) {
      case 'bash':
        return '🐚';
      case 'python':
        return '🐍';
      case 'node':
        return '📦';
      case 'dart':
        return '🎯';
      case 'go':
        return '🐹';
      case 'rust':
        return '🦀';
      default:
        return '📄';
    }
  }

  /// Get the category icon
  String get categoryIcon {
    switch (category) {
      case 'system':
        return '🖥️';
      case 'time':
        return '⏰';
      case 'network':
        return '🌐';
      case 'productivity':
        return '📋';
      case 'fun':
        return '🎮';
      case 'development':
        return '💻';
      default:
        return '📦';
    }
  }
}

/// Service for managing sample/example plugins bundled with the app.
class SamplePluginsService {
  SamplePluginsService._();

  static final SamplePluginsService _instance = SamplePluginsService._();
  factory SamplePluginsService() => _instance;

  final PluginManager _pluginManager = PluginManager();

  /// All available sample plugins
  static const List<SamplePlugin> samplePlugins = [
    // System Monitoring
    SamplePlugin(
      id: 'cpu.10s.sh',
      name: 'CPU Monitor',
      description: 'Shows current CPU usage percentage',
      category: 'system',
      language: 'bash',
      assetPath: 'plugins/cpu.10s.sh',
    ),
    SamplePlugin(
      id: 'memory.10s.sh',
      name: 'Memory Monitor',
      description: 'Shows RAM usage',
      category: 'system',
      language: 'bash',
      assetPath: 'plugins/memory.10s.sh',
    ),
    SamplePlugin(
      id: 'battery.30s.sh',
      name: 'Battery Status',
      description: 'Shows battery level and charging status',
      category: 'system',
      language: 'bash',
      assetPath: 'plugins/battery.30s.sh',
    ),
    SamplePlugin(
      id: 'disk.5m.sh',
      name: 'Disk Usage',
      description: 'Shows disk space usage',
      category: 'system',
      language: 'bash',
      assetPath: 'plugins/disk.5m.sh',
    ),
    SamplePlugin(
      id: 'uptime.1m.sh',
      name: 'Uptime',
      description: 'Shows system uptime',
      category: 'system',
      language: 'bash',
      assetPath: 'plugins/uptime.1m.sh',
    ),

    // Time & Clocks
    SamplePlugin(
      id: 'time.1s.py',
      name: 'Simple Clock',
      description: 'Shows current time (Python)',
      category: 'time',
      language: 'python',
      assetPath: 'plugins/time.1s.py',
    ),
    SamplePlugin(
      id: 'emoji-clock.1m.js',
      name: 'Emoji Clock',
      description: 'Shows time with emoji clock faces',
      category: 'time',
      language: 'node',
      assetPath: 'plugins/emoji-clock.1m.js',
    ),
    SamplePlugin(
      id: 'world-clock.1m.js',
      name: 'World Clock',
      description: 'Shows time in multiple timezones',
      category: 'time',
      language: 'node',
      assetPath: 'plugins/world-clock.1m.js',
    ),
    SamplePlugin(
      id: 'countdown.1s.py',
      name: 'Countdown Timer',
      description: 'Countdown timer to a target date',
      category: 'time',
      language: 'python',
      assetPath: 'plugins/countdown.1s.py',
    ),
    SamplePlugin(
      id: 'pomodoro.1s.js',
      name: 'Pomodoro Timer',
      description: 'Pomodoro technique timer',
      category: 'productivity',
      language: 'node',
      assetPath: 'plugins/pomodoro.1s.js',
    ),

    // Network & Web
    SamplePlugin(
      id: 'network.30s.sh',
      name: 'Network Status',
      description: 'Shows network interface info',
      category: 'network',
      language: 'bash',
      assetPath: 'plugins/network.30s.sh',
    ),
    SamplePlugin(
      id: 'ip-info.1h.js',
      name: 'IP Info',
      description: 'Shows your public IP and location',
      category: 'network',
      language: 'node',
      assetPath: 'plugins/ip-info.1h.js',
    ),
    SamplePlugin(
      id: 'weather.30m.py',
      name: 'Weather',
      description: 'Shows current weather (requires API key)',
      category: 'network',
      language: 'python',
      assetPath: 'plugins/weather.30m.py',
      schemaAssetPath: 'plugins/weather.30m.py.schema.json',
    ),
    SamplePlugin(
      id: 'bitcoin.5m.py',
      name: 'Bitcoin Price',
      description: 'Shows current Bitcoin price',
      category: 'network',
      language: 'python',
      assetPath: 'plugins/bitcoin.5m.py',
      schemaAssetPath: 'plugins/bitcoin.5m.py.schema.json',
    ),

    // Development
    SamplePlugin(
      id: 'git-status.30s.dart',
      name: 'Git Status',
      description: 'Shows current git repository status',
      category: 'development',
      language: 'dart',
      assetPath: 'plugins/git-status.30s.dart',
    ),
    SamplePlugin(
      id: 'docker-status.1m.sh',
      name: 'Docker Status',
      description: 'Shows running Docker containers',
      category: 'development',
      language: 'bash',
      assetPath: 'plugins/docker-status.1m.sh',
    ),
    SamplePlugin(
      id: 'github-notifications.5m.py',
      name: 'GitHub Notifications',
      description: 'Shows GitHub notification count',
      category: 'development',
      language: 'python',
      assetPath: 'plugins/github-notifications.5m.py',
      schemaAssetPath: 'plugins/github-notifications.5m.py.schema.json',
    ),
    SamplePlugin(
      id: 'ssh-connections.30s.sh',
      name: 'SSH Connections',
      description: 'Shows active SSH connections',
      category: 'development',
      language: 'bash',
      assetPath: 'plugins/ssh-connections.30s.sh',
    ),

    // Productivity
    SamplePlugin(
      id: 'todo.1m.py',
      name: 'Todo List',
      description: 'Simple todo list manager',
      category: 'productivity',
      language: 'python',
      assetPath: 'plugins/todo.1m.py',
    ),
    SamplePlugin(
      id: 'quotes.1h.py',
      name: 'Inspirational Quotes',
      description: 'Shows random inspirational quotes',
      category: 'fun',
      language: 'python',
      assetPath: 'plugins/quotes.1h.py',
    ),

    // Other languages examples
    SamplePlugin(
      id: 'cpu.10s.go',
      name: 'CPU Monitor (Go)',
      description: 'Shows CPU usage - Go version',
      category: 'system',
      language: 'go',
      assetPath: 'plugins/cpu.10s.go',
    ),
    SamplePlugin(
      id: 'battery.30s.rs',
      name: 'Battery Status (Rust)',
      description: 'Shows battery level - Rust version',
      category: 'system',
      language: 'rust',
      assetPath: 'plugins/battery.30s.rs',
    ),
    SamplePlugin(
      id: 'system-info.1m.dart',
      name: 'System Info (Dart)',
      description: 'Shows system information - Dart version',
      category: 'system',
      language: 'dart',
      assetPath: 'plugins/system-info.1m.dart',
    ),
  ];

  /// Get sample plugins grouped by category
  Map<String, List<SamplePlugin>> get pluginsByCategory {
    final grouped = <String, List<SamplePlugin>>{};
    for (final plugin in samplePlugins) {
      grouped.putIfAbsent(plugin.category, () => []).add(plugin);
    }
    return grouped;
  }

  /// Get all unique categories
  List<String> get categories {
    return pluginsByCategory.keys.toList()..sort();
  }

  /// Check if a sample plugin is already installed
  Future<bool> isInstalled(String pluginId) async {
    final pluginsDir = await _pluginManager.pluginsDirectory;
    final pluginPath = path.join(pluginsDir, pluginId);
    final pluginPathOff = path.join(
      pluginsDir, 
      pluginId.replaceFirst(RegExp(r'\.([^.]+)$'), '.off.\$1'),
    );
    
    return File(pluginPath).existsSync() || File(pluginPathOff).existsSync();
  }

  /// Install a sample plugin by copying it to the plugins directory
  Future<void> install(SamplePlugin plugin) async {
    final pluginsDir = await _pluginManager.pluginsDirectory;
    
    // Ensure plugins directory exists
    final dir = Directory(pluginsDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    // Read plugin content from assets
    final content = await rootBundle.loadString(plugin.assetPath);
    
    // Write to plugins directory
    final targetPath = path.join(pluginsDir, plugin.id);
    final targetFile = File(targetPath);
    await targetFile.writeAsString(content);

    // Make executable on Unix
    if (Platform.isLinux || Platform.isMacOS) {
      await Process.run('chmod', ['+x', targetPath]);
    }

    // Copy schema file if exists
    if (plugin.schemaAssetPath != null) {
      try {
        final schemaContent = await rootBundle.loadString(plugin.schemaAssetPath!);
        final schemaPath = '$targetPath.schema.json';
        await File(schemaPath).writeAsString(schemaContent);
      } catch (_) {
        // Schema file is optional
      }
    }
  }

  /// Install multiple plugins at once
  Future<void> installMultiple(List<SamplePlugin> plugins) async {
    for (final plugin in plugins) {
      await install(plugin);
    }
  }

  /// Uninstall a sample plugin
  Future<void> uninstall(String pluginId) async {
    final pluginsDir = await _pluginManager.pluginsDirectory;
    
    // Try both enabled and disabled versions
    final paths = [
      path.join(pluginsDir, pluginId),
      path.join(pluginsDir, pluginId.replaceFirst(RegExp(r'\.([^.]+)$'), '.off.\$1')),
    ];

    for (final p in paths) {
      final file = File(p);
      if (await file.exists()) {
        await file.delete();
      }
      
      // Also delete schema file if exists
      final schemaFile = File('$p.schema.json');
      if (await schemaFile.exists()) {
        await schemaFile.delete();
      }
    }
  }
}
