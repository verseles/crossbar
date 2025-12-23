// ignore_for_file: avoid_slow_async_io
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as path;

import '../core/plugin_manager.dart';
import '../models/plugin_metadata.dart';

// Re-export for backward compatibility
export '../models/plugin_metadata.dart';

/// Service for managing sample/example plugins bundled with the app.
class SamplePluginsService {
  factory SamplePluginsService() => _instance;

  SamplePluginsService._internal();

  static final SamplePluginsService _instance = SamplePluginsService._internal();

  final PluginManager _pluginManager = PluginManager();

  /// Universal plugins with multi-language support
  static const List<PluginMetadata> universalPlugins = [
    // ─────────────────────────────────────────────────────────────
    // SYSTEM MONITORING
    // ─────────────────────────────────────────────────────────────
    PluginMetadata(
      id: 'cpu',
      name: 'CPU Monitor',
      description: 'Shows current CPU usage percentage',
      category: PluginCategory.system,
      mobileCompatible: true,
      tags: ['cpu', 'monitor', 'usage', 'hardware'],
      variants: [
        PluginMetadataVariant(language: PluginLanguage.bash, filename: 'cpu.10s.sh', assetPath: 'plugins/cpu/cpu.10s.sh'),
        PluginMetadataVariant(language: PluginLanguage.python, filename: 'cpu.10s.py', assetPath: 'plugins/cpu/cpu.10s.py'),
        PluginMetadataVariant(language: PluginLanguage.node, filename: 'cpu.10s.js', assetPath: 'plugins/cpu/cpu.10s.js'),
        PluginMetadataVariant(language: PluginLanguage.dart, filename: 'cpu.10s.dart', assetPath: 'plugins/cpu/cpu.10s.dart'),
        PluginMetadataVariant(language: PluginLanguage.go, filename: 'cpu.10s.go', assetPath: 'plugins/cpu/cpu.10s.go'),
        PluginMetadataVariant(language: PluginLanguage.rust, filename: 'cpu.10s.rs', assetPath: 'plugins/cpu/cpu.10s.rs'),
        PluginMetadataVariant(language: PluginLanguage.lua, filename: 'cpu.10s.lua', assetPath: 'plugins/cpu/cpu.10s.lua'),
        PluginMetadataVariant(language: PluginLanguage.yaml, filename: 'cpu.5s.yaml', assetPath: 'plugins/yaml/cpu.5s.yaml'),
      ],
    ),
    PluginMetadata(
      id: 'memory',
      name: 'Memory Monitor',
      description: 'Shows RAM usage',
      category: PluginCategory.system,
      mobileCompatible: true,
      tags: ['memory', 'ram', 'monitor', 'usage'],
      variants: [
        PluginMetadataVariant(language: PluginLanguage.bash, filename: 'memory.10s.sh', assetPath: 'plugins/memory/memory.10s.sh'),
        PluginMetadataVariant(language: PluginLanguage.lua, filename: 'memory.10s.lua', assetPath: 'plugins/memory/memory.10s.lua'),
      ],
    ),
    PluginMetadata(
      id: 'battery',
      name: 'Battery Status',
      description: 'Shows battery level and charging status with dynamic icons',
      category: PluginCategory.system,
      mobileCompatible: true,
      tags: ['battery', 'power', 'charging'],
      variants: [
        PluginMetadataVariant(language: PluginLanguage.bash, filename: 'battery.2s.sh', assetPath: 'plugins/battery/battery.2s.sh'),
        PluginMetadataVariant(language: PluginLanguage.lua, filename: 'battery.2s.lua', assetPath: 'plugins/battery/battery.2s.lua'),
      ],
    ),
    PluginMetadata(
      id: 'uptime',
      name: 'System Uptime',
      description: 'Shows how long the system has been running',
      category: PluginCategory.system,
      mobileCompatible: true,
      tags: ['uptime', 'boot', 'system'],
      variants: [
        PluginMetadataVariant(language: PluginLanguage.bash, filename: 'uptime.1m.sh', assetPath: 'plugins/uptime/uptime.1m.sh'),
        PluginMetadataVariant(language: PluginLanguage.python, filename: 'uptime.1m.py', assetPath: 'plugins/uptime/uptime.1m.py'),
        PluginMetadataVariant(language: PluginLanguage.node, filename: 'uptime.1m.js', assetPath: 'plugins/uptime/uptime.1m.js'),
        PluginMetadataVariant(language: PluginLanguage.dart, filename: 'uptime.1m.dart', assetPath: 'plugins/uptime/uptime.1m.dart'),
        PluginMetadataVariant(language: PluginLanguage.go, filename: 'uptime.1m.go', assetPath: 'plugins/uptime/uptime.1m.go'),
        PluginMetadataVariant(language: PluginLanguage.rust, filename: 'uptime.1m.rs', assetPath: 'plugins/uptime/uptime.1m.rs'),
        PluginMetadataVariant(language: PluginLanguage.lua, filename: 'uptime.1m.lua', assetPath: 'plugins/uptime/uptime.1m.lua'),
      ],
    ),
    PluginMetadata(
      id: 'system-info',
      name: 'System Info',
      description: 'Comprehensive system information',
      category: PluginCategory.system,
      tags: ['system', 'os', 'kernel'],
      variants: [
        PluginMetadataVariant(language: PluginLanguage.bash, filename: 'system-info.1m.sh', assetPath: 'plugins/system-info/system-info.1m.sh'),
        PluginMetadataVariant(language: PluginLanguage.lua, filename: 'system-info.1m.lua', assetPath: 'plugins/system-info/system-info.1m.lua'),
      ],
    ),

    // ─────────────────────────────────────────────────────────────
    // TIME & CLOCKS
    // ─────────────────────────────────────────────────────────────
    PluginMetadata(
      id: 'clock',
      name: 'Clock',
      description: 'Shows current time',
      category: PluginCategory.time,
      mobileCompatible: true,
      tags: ['time', 'clock', 'date'],
      variants: [
        PluginMetadataVariant(language: PluginLanguage.bash, filename: 'clock.1s.sh', assetPath: 'plugins/clock/clock.1s.sh'),
        PluginMetadataVariant(language: PluginLanguage.lua, filename: 'clock.1s.lua', assetPath: 'plugins/clock/clock.1s.lua'),
      ],
    ),
    PluginMetadata(
      id: 'time',
      name: 'Simple Clock',
      description: 'Shows current time with day phase icon',
      category: PluginCategory.time,
      tags: ['time', 'clock'],
      variants: [
        PluginMetadataVariant(language: PluginLanguage.bash, filename: 'time.1s.sh', assetPath: 'plugins/time/time.1s.sh'),
        PluginMetadataVariant(language: PluginLanguage.lua, filename: 'time.1s.lua', assetPath: 'plugins/time/time.1s.lua'),
      ],
    ),
    PluginMetadata(
      id: 'emoji-clock',
      name: 'Emoji Clock',
      description: 'Shows time with emoji clock faces',
      category: PluginCategory.time,
      tags: ['time', 'clock', 'emoji'],
      variants: [
        PluginMetadataVariant(language: PluginLanguage.bash, filename: 'emoji-clock.1m.sh', assetPath: 'plugins/emoji-clock/emoji-clock.1m.sh'),
        PluginMetadataVariant(language: PluginLanguage.lua, filename: 'emoji-clock.1m.lua', assetPath: 'plugins/emoji-clock/emoji-clock.1m.lua'),
      ],
    ),
    PluginMetadata(
      id: 'world-clock',
      name: 'World Clock',
      description: 'Shows time in multiple timezones',
      category: PluginCategory.time,
      tags: ['time', 'timezone', 'world'],
      variants: [
        PluginMetadataVariant(language: PluginLanguage.bash, filename: 'world-clock.1m.sh', assetPath: 'plugins/world-clock/world-clock.1m.sh'),
        PluginMetadataVariant(language: PluginLanguage.lua, filename: 'world-clock.1m.lua', assetPath: 'plugins/world-clock/world-clock.1m.lua'),
      ],
    ),
    PluginMetadata(
      id: 'countdown',
      name: 'Countdown Timer',
      description: 'Countdown timer to a target date',
      category: PluginCategory.time,
      tags: ['countdown', 'timer'],
      variants: [
        PluginMetadataVariant(language: PluginLanguage.bash, filename: 'countdown.1s.sh', assetPath: 'plugins/countdown/countdown.1s.sh'),
        PluginMetadataVariant(language: PluginLanguage.lua, filename: 'countdown.1s.lua', assetPath: 'plugins/countdown/countdown.1s.lua'),
      ],
    ),
    PluginMetadata(
      id: 'pomodoro',
      name: 'Pomodoro Timer',
      description: 'Pomodoro technique timer',
      category: PluginCategory.productivity,
      tags: ['pomodoro', 'timer', 'focus'],
      variants: [
        PluginMetadataVariant(language: PluginLanguage.bash, filename: 'pomodoro.1s.sh', assetPath: 'plugins/pomodoro/pomodoro.1s.sh'),
        PluginMetadataVariant(language: PluginLanguage.lua, filename: 'pomodoro.1s.lua', assetPath: 'plugins/pomodoro/pomodoro.1s.lua'),
      ],
    ),

    // ─────────────────────────────────────────────────────────────
    // NETWORK & WEB
    // ─────────────────────────────────────────────────────────────
    PluginMetadata(
      id: 'weather',
      name: 'Weather',
      description: 'Shows current weather (requires API key)',
      category: PluginCategory.network,
      mobileCompatible: true,
      configRequired: true,
      tags: ['weather', 'temperature', 'forecast', 'api'],
      variants: [
        PluginMetadataVariant(
          language: PluginLanguage.bash, 
          filename: 'weather.30m.sh', 
          assetPath: 'plugins/weather/weather.30m.sh',
          schemaAssetPath: 'plugins/weather/weather.schema.json',
        ),
        PluginMetadataVariant(
          language: PluginLanguage.lua,
          filename: 'weather.30m.lua',
          assetPath: 'plugins/weather/weather.30m.lua',
          schemaAssetPath: 'plugins/weather/weather.schema.json',
        ),
      ],
    ),
    PluginMetadata(
      id: 'ip-info',
      name: 'IP Info',
      description: 'Shows your public IP and location',
      category: PluginCategory.network,
      tags: ['ip', 'location', 'public'],
      variants: [
        PluginMetadataVariant(language: PluginLanguage.bash, filename: 'ip-info.1h.sh', assetPath: 'plugins/ip-info/ip-info.1h.sh'),
        PluginMetadataVariant(language: PluginLanguage.lua, filename: 'ip-info.1h.lua', assetPath: 'plugins/ip-info/ip-info.1h.lua'),
      ],
    ),
    PluginMetadata(
      id: 'site-check',
      name: 'Site Check',
      description: 'Checks if a website is up',
      category: PluginCategory.network,
      tags: ['network', 'status', 'ping'],
      variants: [
        PluginMetadataVariant(language: PluginLanguage.bash, filename: 'site-check.1m.sh', assetPath: 'plugins/site-check/site-check.1m.sh'),
        PluginMetadataVariant(language: PluginLanguage.lua, filename: 'site-check.1m.lua', assetPath: 'plugins/site-check/site-check.1m.lua'),
      ],
    ),

    // ─────────────────────────────────────────────────────────────
    // FINANCE
    // ─────────────────────────────────────────────────────────────
    PluginMetadata(
      id: 'bitcoin',
      name: 'Bitcoin Price',
      description: 'Shows current Bitcoin price',
      category: PluginCategory.finance,
      mobileCompatible: true,
      tags: ['bitcoin', 'crypto', 'price', 'finance', 'btc'],
      variants: [
        PluginMetadataVariant(language: PluginLanguage.bash, filename: 'bitcoin.5m.sh', assetPath: 'plugins/bitcoin/bitcoin.5m.sh'),
        PluginMetadataVariant(language: PluginLanguage.lua, filename: 'bitcoin.5m.lua', assetPath: 'plugins/bitcoin/bitcoin.5m.lua'),
      ],
    ),

    // ─────────────────────────────────────────────────────────────
    // DEVELOPMENT
    // ─────────────────────────────────────────────────────────────
    PluginMetadata(
      id: 'git-status',
      name: 'Git Status',
      description: 'Shows current git repository status',
      category: PluginCategory.development,
      tags: ['git', 'vcs', 'repo'],
      variants: [
        PluginMetadataVariant(language: PluginLanguage.bash, filename: 'git-status.30s.sh', assetPath: 'plugins/git-status/git-status.30s.sh'),
        PluginMetadataVariant(language: PluginLanguage.lua, filename: 'git-status.30s.lua', assetPath: 'plugins/git-status/git-status.30s.lua'),
      ],
    ),
    PluginMetadata(
      id: 'npm-downloads',
      name: 'NPM Downloads',
      description: 'Shows download count for a package',
      category: PluginCategory.development,
      tags: ['npm', 'package', 'downloads'],
      variants: [
        PluginMetadataVariant(language: PluginLanguage.bash, filename: 'npm-downloads.1h.sh', assetPath: 'plugins/npm-downloads/npm-downloads.1h.sh'),
        PluginMetadataVariant(language: PluginLanguage.lua, filename: 'npm-downloads.1h.lua', assetPath: 'plugins/npm-downloads/npm-downloads.1h.lua'),
      ],
    ),
    PluginMetadata(
      id: 'github-notifications',
      name: 'GitHub Notifications',
      description: 'Shows GitHub notification count',
      category: PluginCategory.development,
      configRequired: true,
      tags: ['github', 'notifications', 'api'],
      variants: [
        PluginMetadataVariant(
          language: PluginLanguage.bash,
          filename: 'github-notifications.5m.sh',
          assetPath: 'plugins/github-notifications/github-notifications.5m.sh',
          schemaAssetPath: 'plugins/github-notifications/github-notifications.5m.py.schema.json', // Reuse existing schema
        ),
        PluginMetadataVariant(
          language: PluginLanguage.lua, 
          filename: 'github-notifications.5m.lua', 
          assetPath: 'plugins/github-notifications/github-notifications.5m.lua',
          schemaAssetPath: 'plugins/github-notifications/github-notifications.5m.py.schema.json',
        ),
      ],
    ),
    PluginMetadata(
      id: 'process-monitor',
      name: 'Process Monitor',
      description: 'Shows top CPU processes',
      category: PluginCategory.development,
      tags: ['process', 'cpu', 'monitor'],
      variants: [
        PluginMetadataVariant(language: PluginLanguage.bash, filename: 'process-monitor.10s.sh', assetPath: 'plugins/process-monitor/process-monitor.10s.sh'),
        PluginMetadataVariant(language: PluginLanguage.lua, filename: 'process-monitor.10s.lua', assetPath: 'plugins/process-monitor/process-monitor.10s.lua'),
      ],
    ),

    // ─────────────────────────────────────────────────────────────
    // PRODUCTIVITY & FUN
    // ─────────────────────────────────────────────────────────────
    PluginMetadata(
      id: 'todo',
      name: 'Todo List',
      description: 'Simple todo list manager',
      category: PluginCategory.productivity,
      tags: ['todo', 'tasks', 'list'],
      variants: [
        PluginMetadataVariant(language: PluginLanguage.bash, filename: 'todo.1m.sh', assetPath: 'plugins/todo/todo.1m.sh'),
        PluginMetadataVariant(language: PluginLanguage.lua, filename: 'todo.1m.lua', assetPath: 'plugins/todo/todo.1m.lua'),
      ],
    ),
    PluginMetadata(
      id: 'quotes',
      name: 'Inspirational Quotes',
      description: 'Shows random inspirational quotes',
      category: PluginCategory.fun,
      tags: ['quotes', 'inspiration', 'motivation'],
      variants: [
        PluginMetadataVariant(language: PluginLanguage.bash, filename: 'quotes.1h.sh', assetPath: 'plugins/quotes/quotes.1h.sh'),
        PluginMetadataVariant(language: PluginLanguage.lua, filename: 'quotes.1h.lua', assetPath: 'plugins/quotes/quotes.1h.lua'),
      ],
    ),
  ];

  /// All available plugins
  static List<PluginMetadata> get allPlugins => universalPlugins;

  /// Get plugins grouped by category
  Map<PluginCategory, List<PluginMetadata>> get pluginsByCategory {
    final grouped = <PluginCategory, List<PluginMetadata>>{};
    for (final plugin in allPlugins) {
      grouped.putIfAbsent(plugin.category, () => []).add(plugin);
    }
    return grouped;
  }

  /// Get all unique categories
  List<PluginCategory> get categories {
    return pluginsByCategory.keys.toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
  }

  /// Get plugins that support a specific language
  List<PluginMetadata> getPluginsForLanguage(PluginLanguage language) {
    return allPlugins.where((p) => p.hasLanguage(language)).toList();
  }

  /// Get mobile-compatible plugins
  List<PluginMetadata> get mobileCompatiblePlugins {
    return allPlugins.where((p) => p.mobileCompatible).toList();
  }

  /// Search plugins by name, description, or tags
  List<PluginMetadata> search(String query) {
    final q = query.toLowerCase();
    return allPlugins.where((p) {
      return p.name.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q) ||
          p.tags.any((t) => t.toLowerCase().contains(q));
    }).toList();
  }

  /// Check if a plugin variant is already installed
  Future<bool> isInstalled(String filename) async {
    final pluginsDir = await _pluginManager.pluginsDirectory;
    // Check in the subdirectory
    final baseName = filename.split('.').first;
    final pluginPath = path.join(pluginsDir, baseName, filename);
    
    // Also check root for legacy installations
    final legacyPath = path.join(pluginsDir, filename);
    
    // Check off versions
    final offName = filename.replaceFirst(RegExp(r'\.([^.]+)$'), r'.off.$1');
    final pluginPathOff = path.join(pluginsDir, baseName, offName);
    final legacyPathOff = path.join(pluginsDir, offName);
    
    return File(pluginPath).existsSync() || File(pluginPathOff).existsSync() ||
           File(legacyPath).existsSync() || File(legacyPathOff).existsSync();
  }

  /// Install a specific variant of a plugin
  Future<void> installVariant(PluginMetadataVariant variant) async {
    final pluginsDir = await _pluginManager.pluginsDirectory;
    
    // Determine subdirectory based on plugin ID/filename
    final baseName = variant.filename.split('.').first;
    final targetDir = path.join(pluginsDir, baseName);
    
    // Ensure plugins directory exists
    final dir = Directory(targetDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    // Read plugin content from assets
    final content = await rootBundle.loadString(variant.assetPath);
    
    // Write to plugins directory
    final targetPath = path.join(targetDir, variant.filename);
    final targetFile = File(targetPath);
    await targetFile.writeAsString(content);

    // Make executable on Unix
    if (Platform.isLinux || Platform.isMacOS) {
      await Process.run('chmod', ['+x', targetPath]);
    }

    // Copy schema file if exists
    if (variant.schemaAssetPath != null) {
      try {
        final schemaContent = await rootBundle.loadString(variant.schemaAssetPath!);
        // Schema goes next to the plugin file
        final schemaPath = '$targetPath.schema.json';
        await File(schemaPath).writeAsString(schemaContent);
      } catch (_) {
        // Schema file is optional
      }
    }
  }

  /// Install a plugin with the preferred language
  Future<void> install(PluginMetadata plugin, {PluginLanguage? preferredLanguage}) async {
    final variant = preferredLanguage != null 
        ? plugin.getVariant(preferredLanguage) ?? plugin.defaultVariant
        : plugin.defaultVariant;
    await installVariant(variant);
  }

  /// Install multiple plugins at once
  Future<void> installMultiple(List<PluginMetadata> plugins, {PluginLanguage? preferredLanguage}) async {
    for (final plugin in plugins) {
      await install(plugin, preferredLanguage: preferredLanguage);
    }
  }

  /// Uninstall a plugin variant
  Future<void> uninstallVariant(String filename) async {
    final pluginsDir = await _pluginManager.pluginsDirectory;
    final baseName = filename.split('.').first;
    final targetDir = path.join(pluginsDir, baseName);
    
    // Try both enabled and disabled versions in subdirectory
    final paths = [
      path.join(targetDir, filename),
      path.join(targetDir, filename.replaceFirst(RegExp(r'\.([^.]+)$'), r'.off.$1')),
      // Also legacy root paths
      path.join(pluginsDir, filename),
      path.join(pluginsDir, filename.replaceFirst(RegExp(r'\.([^.]+)$'), r'.off.$1')),
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
    
    // Clean up empty directory
    final dir = Directory(targetDir);
    if (await dir.exists() && await dir.list().isEmpty) {
      await dir.delete();
    }
  }
}
