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
  SamplePluginsService._();

  static final SamplePluginsService _instance = SamplePluginsService._();

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
        PluginVariant(language: PluginLanguage.bash, filename: 'cpu.10s.sh', assetPath: 'plugins/cpu/cpu.10s.sh'),
        PluginVariant(language: PluginLanguage.python, filename: 'cpu.10s.py', assetPath: 'plugins/cpu/cpu.10s.py'),
        PluginVariant(language: PluginLanguage.node, filename: 'cpu.10s.js', assetPath: 'plugins/cpu/cpu.10s.js'),
        PluginVariant(language: PluginLanguage.dart, filename: 'cpu.10s.dart', assetPath: 'plugins/cpu/cpu.10s.dart'),
        PluginVariant(language: PluginLanguage.go, filename: 'cpu.10s.go', assetPath: 'plugins/cpu/cpu.10s.go'),
        PluginVariant(language: PluginLanguage.rust, filename: 'cpu.10s.rs', assetPath: 'plugins/cpu/cpu.10s.rs'),
        PluginVariant(language: PluginLanguage.lua, filename: 'cpu.10s.lua', assetPath: 'plugins/cpu/cpu.10s.lua'),
        PluginVariant(language: PluginLanguage.yaml, filename: 'cpu.5s.yaml', assetPath: 'plugins/yaml/cpu.5s.yaml'),
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
        PluginVariant(language: PluginLanguage.bash, filename: 'memory.10s.sh', assetPath: 'plugins/memory/memory.10s.sh'),
        PluginVariant(language: PluginLanguage.python, filename: 'memory.10s.py', assetPath: 'plugins/memory/memory.10s.py'),
        PluginVariant(language: PluginLanguage.node, filename: 'memory.10s.js', assetPath: 'plugins/memory/memory.10s.js'),
        PluginVariant(language: PluginLanguage.dart, filename: 'memory.10s.dart', assetPath: 'plugins/memory/memory.10s.dart'),
        PluginVariant(language: PluginLanguage.go, filename: 'memory.10s.go', assetPath: 'plugins/memory/memory.10s.go'),
        PluginVariant(language: PluginLanguage.rust, filename: 'memory.10s.rs', assetPath: 'plugins/memory/memory.10s.rs'),
        PluginVariant(language: PluginLanguage.lua, filename: 'memory.10s.lua', assetPath: 'plugins/memory/memory.10s.lua'),
        PluginVariant(language: PluginLanguage.yaml, filename: 'memory.10s.yaml', assetPath: 'plugins/yaml/memory.10s.yaml'),
      ],
    ),
    PluginMetadata(
      id: 'battery',
      name: 'Battery Status',
      description: 'Shows battery level and charging status',
      category: PluginCategory.system,
      mobileCompatible: true,
      tags: ['battery', 'power', 'charging'],
      variants: [
        PluginVariant(language: PluginLanguage.bash, filename: 'battery.30s.sh', assetPath: 'plugins/battery/battery.30s.sh'),
        PluginVariant(language: PluginLanguage.python, filename: 'battery.30s.py', assetPath: 'plugins/battery/battery.30s.py'),
        PluginVariant(language: PluginLanguage.node, filename: 'battery.30s.js', assetPath: 'plugins/battery/battery.30s.js'),
        PluginVariant(language: PluginLanguage.dart, filename: 'battery.30s.dart', assetPath: 'plugins/battery/battery.30s.dart'),
        PluginVariant(language: PluginLanguage.go, filename: 'battery.30s.go', assetPath: 'plugins/battery/battery.30s.go'),
        PluginVariant(language: PluginLanguage.rust, filename: 'battery.30s.rs', assetPath: 'plugins/battery/battery.30s.rs'),
        PluginVariant(language: PluginLanguage.lua, filename: 'battery.1m.lua', assetPath: 'plugins/battery/battery.1m.lua'),
        PluginVariant(language: PluginLanguage.yaml, filename: 'battery.1m.yaml', assetPath: 'plugins/yaml/battery.1m.yaml'),
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
        PluginVariant(language: PluginLanguage.bash, filename: 'clock.1s.sh', assetPath: 'plugins/clock/clock.1s.sh'),
        PluginVariant(language: PluginLanguage.python, filename: 'clock.1s.py', assetPath: 'plugins/clock/clock.1s.py'),
        PluginVariant(language: PluginLanguage.node, filename: 'clock.1s.js', assetPath: 'plugins/clock/clock.1s.js'),
        PluginVariant(language: PluginLanguage.dart, filename: 'clock.1s.dart', assetPath: 'plugins/clock/clock.1s.dart'),
        PluginVariant(language: PluginLanguage.go, filename: 'clock.1s.go', assetPath: 'plugins/clock/clock.1s.go'),
        PluginVariant(language: PluginLanguage.rust, filename: 'clock.1s.rs', assetPath: 'plugins/clock/clock.1s.rs'),
        PluginVariant(language: PluginLanguage.lua, filename: 'clock.1s.lua', assetPath: 'plugins/clock/clock.1s.lua'),
        PluginVariant(language: PluginLanguage.yaml, filename: 'clock.1s.yaml', assetPath: 'plugins/yaml/clock.1s.yaml'),
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
        PluginVariant(
          language: PluginLanguage.bash, 
          filename: 'weather.30m.sh', 
          assetPath: 'plugins/weather/weather.30m.sh',
          schemaAssetPath: 'plugins/weather/weather.schema.json',
        ),
        PluginVariant(
          language: PluginLanguage.python, 
          filename: 'weather.30m.py', 
          assetPath: 'plugins/weather/weather.30m.py',
          schemaAssetPath: 'plugins/weather/weather.schema.json',
        ),
        PluginVariant(
          language: PluginLanguage.node, 
          filename: 'weather.30m.js', 
          assetPath: 'plugins/weather/weather.30m.js',
          schemaAssetPath: 'plugins/weather/weather.schema.json',
        ),
        PluginVariant(
          language: PluginLanguage.dart, 
          filename: 'weather.30m.dart', 
          assetPath: 'plugins/weather/weather.30m.dart',
          schemaAssetPath: 'plugins/weather/weather.schema.json',
        ),
        PluginVariant(
          language: PluginLanguage.go, 
          filename: 'weather.30m.go', 
          assetPath: 'plugins/weather/weather.30m.go',
          schemaAssetPath: 'plugins/weather/weather.schema.json',
        ),
        PluginVariant(
          language: PluginLanguage.rust, 
          filename: 'weather.30m.rs', 
          assetPath: 'plugins/weather/weather.30m.rs',
          schemaAssetPath: 'plugins/weather/weather.schema.json',
        ),
        PluginVariant(
          language: PluginLanguage.lua,
          filename: 'weather.30m.lua',
          assetPath: 'plugins/weather/weather.30m.lua',
          schemaAssetPath: 'plugins/weather/weather.schema.json',
        ),
      ],
    ),

    // ─────────────────────────────────────────────────────────────
    // FINANCE
    // ─────────────────────────────────────────────────────────────
    PluginMetadata(
      id: 'bitcoin',
      name: 'Bitcoin Price',
      description: 'Shows current Bitcoin price from Coinbase',
      category: PluginCategory.finance,
      mobileCompatible: true,
      tags: ['bitcoin', 'crypto', 'price', 'finance', 'btc'],
      variants: [
        PluginVariant(language: PluginLanguage.bash, filename: 'bitcoin.5m.sh', assetPath: 'plugins/bitcoin/bitcoin.5m.sh'),
        PluginVariant(language: PluginLanguage.python, filename: 'bitcoin.5m.py', assetPath: 'plugins/bitcoin/bitcoin.5m.py'),
        PluginVariant(language: PluginLanguage.node, filename: 'bitcoin.5m.js', assetPath: 'plugins/bitcoin/bitcoin.5m.js'),
        PluginVariant(language: PluginLanguage.dart, filename: 'bitcoin.5m.dart', assetPath: 'plugins/bitcoin/bitcoin.5m.dart'),
        PluginVariant(language: PluginLanguage.go, filename: 'bitcoin.5m.go', assetPath: 'plugins/bitcoin/bitcoin.5m.go'),
        PluginVariant(language: PluginLanguage.rust, filename: 'bitcoin.5m.rs', assetPath: 'plugins/bitcoin/bitcoin.5m.rs'),
        PluginVariant(language: PluginLanguage.lua, filename: 'bitcoin.5m.lua', assetPath: 'plugins/bitcoin/bitcoin.5m.lua'),
        PluginVariant(language: PluginLanguage.yaml, filename: 'bitcoin.5m.yaml', assetPath: 'plugins/yaml/bitcoin.5m.yaml'),
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
        PluginVariant(language: PluginLanguage.bash, filename: 'uptime.1m.sh', assetPath: 'plugins/uptime/uptime.1m.sh'),
        PluginVariant(language: PluginLanguage.python, filename: 'uptime.1m.py', assetPath: 'plugins/uptime/uptime.1m.py'),
        PluginVariant(language: PluginLanguage.node, filename: 'uptime.1m.js', assetPath: 'plugins/uptime/uptime.1m.js'),
        PluginVariant(language: PluginLanguage.dart, filename: 'uptime.1m.dart', assetPath: 'plugins/uptime/uptime.1m.dart'),
        PluginVariant(language: PluginLanguage.go, filename: 'uptime.1m.go', assetPath: 'plugins/uptime/uptime.1m.go'),
        PluginVariant(language: PluginLanguage.rust, filename: 'uptime.1m.rs', assetPath: 'plugins/uptime/uptime.1m.rs'),
        PluginVariant(language: PluginLanguage.lua, filename: 'uptime.1m.lua', assetPath: 'plugins/uptime/uptime.1m.lua'),
        PluginVariant(language: PluginLanguage.yaml, filename: 'uptime.1m.yaml', assetPath: 'plugins/yaml/uptime.1m.yaml'),
      ],
    ),
    PluginMetadata(
      id: 'network-status',
      name: 'Network Status',
      description: 'Shows network interface status (YAML no-code)',
      category: PluginCategory.network,
      mobileCompatible: true,
      tags: ['network', 'status', 'ip', 'connection'],
      variants: [
        PluginVariant(language: PluginLanguage.yaml, filename: 'network.30s.yaml', assetPath: 'plugins/yaml/network.30s.yaml'),
      ],
    ),
  ];

  /// Legacy plugins (single language, for backward compatibility)
  static const List<PluginMetadata> legacyPlugins = [
    // System
    PluginMetadata(
      id: 'disk',
      name: 'Disk Usage',
      description: 'Shows disk space usage',
      category: PluginCategory.system,
      tags: ['disk', 'storage', 'space'],
      variants: [
        PluginVariant(language: PluginLanguage.bash, filename: 'disk.5m.sh', assetPath: 'plugins/disk.5m.sh'),
      ],
    ),

    // Time
    PluginMetadata(
      id: 'time',
      name: 'Simple Clock (Python)',
      description: 'Shows current time',
      category: PluginCategory.time,
      tags: ['time', 'clock'],
      variants: [
        PluginVariant(language: PluginLanguage.python, filename: 'time.1s.py', assetPath: 'plugins/time.1s.py'),
      ],
    ),
    PluginMetadata(
      id: 'emoji-clock',
      name: 'Emoji Clock',
      description: 'Shows time with emoji clock faces',
      category: PluginCategory.time,
      tags: ['time', 'clock', 'emoji'],
      variants: [
        PluginVariant(language: PluginLanguage.node, filename: 'emoji-clock.1m.js', assetPath: 'plugins/emoji-clock.1m.js'),
      ],
    ),
    PluginMetadata(
      id: 'world-clock',
      name: 'World Clock',
      description: 'Shows time in multiple timezones',
      category: PluginCategory.time,
      tags: ['time', 'timezone', 'world'],
      variants: [
        PluginVariant(language: PluginLanguage.node, filename: 'world-clock.1m.js', assetPath: 'plugins/world-clock.1m.js'),
      ],
    ),
    PluginMetadata(
      id: 'countdown',
      name: 'Countdown Timer',
      description: 'Countdown timer to a target date',
      category: PluginCategory.time,
      tags: ['countdown', 'timer'],
      variants: [
        PluginVariant(language: PluginLanguage.python, filename: 'countdown.1s.py', assetPath: 'plugins/countdown.1s.py'),
      ],
    ),
    PluginMetadata(
      id: 'pomodoro',
      name: 'Pomodoro Timer',
      description: 'Pomodoro technique timer',
      category: PluginCategory.productivity,
      tags: ['pomodoro', 'timer', 'focus'],
      variants: [
        PluginVariant(language: PluginLanguage.node, filename: 'pomodoro.1s.js', assetPath: 'plugins/pomodoro.1s.js'),
      ],
    ),

    // Network
    PluginMetadata(
      id: 'network',
      name: 'Network Status',
      description: 'Shows network interface info',
      category: PluginCategory.network,
      tags: ['network', 'ip', 'interface'],
      variants: [
        PluginVariant(language: PluginLanguage.bash, filename: 'network.30s.sh', assetPath: 'plugins/network.30s.sh'),
      ],
    ),
    PluginMetadata(
      id: 'ip-info',
      name: 'IP Info',
      description: 'Shows your public IP and location',
      category: PluginCategory.network,
      tags: ['ip', 'location', 'public'],
      variants: [
        PluginVariant(language: PluginLanguage.node, filename: 'ip-info.1h.js', assetPath: 'plugins/ip-info.1h.js'),
      ],
    ),

    // Development
    PluginMetadata(
      id: 'git-status',
      name: 'Git Status',
      description: 'Shows current git repository status',
      category: PluginCategory.development,
      tags: ['git', 'vcs', 'repo'],
      variants: [
        PluginVariant(language: PluginLanguage.dart, filename: 'git-status.30s.dart', assetPath: 'plugins/git-status.30s.dart'),
      ],
    ),
    PluginMetadata(
      id: 'docker-status',
      name: 'Docker Status',
      description: 'Shows running Docker containers',
      category: PluginCategory.development,
      tags: ['docker', 'containers', 'devops'],
      variants: [
        PluginVariant(language: PluginLanguage.bash, filename: 'docker-status.1m.sh', assetPath: 'plugins/docker-status.1m.sh'),
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
        PluginVariant(
          language: PluginLanguage.python, 
          filename: 'github-notifications.5m.py', 
          assetPath: 'plugins/github-notifications.5m.py',
          schemaAssetPath: 'plugins/github-notifications.5m.py.schema.json',
        ),
      ],
    ),
    PluginMetadata(
      id: 'ssh-connections',
      name: 'SSH Connections',
      description: 'Shows active SSH connections',
      category: PluginCategory.development,
      tags: ['ssh', 'connections', 'server'],
      variants: [
        PluginVariant(language: PluginLanguage.bash, filename: 'ssh-connections.30s.sh', assetPath: 'plugins/ssh-connections.30s.sh'),
      ],
    ),

    // Productivity
    PluginMetadata(
      id: 'todo',
      name: 'Todo List',
      description: 'Simple todo list manager',
      category: PluginCategory.productivity,
      tags: ['todo', 'tasks', 'list'],
      variants: [
        PluginVariant(language: PluginLanguage.python, filename: 'todo.1m.py', assetPath: 'plugins/todo.1m.py'),
      ],
    ),

    // Fun
    PluginMetadata(
      id: 'quotes',
      name: 'Inspirational Quotes',
      description: 'Shows random inspirational quotes',
      category: PluginCategory.fun,
      tags: ['quotes', 'inspiration', 'motivation'],
      variants: [
        PluginVariant(language: PluginLanguage.python, filename: 'quotes.1h.py', assetPath: 'plugins/quotes.1h.py'),
      ],
    ),
  ];

  /// All available plugins (universal + legacy)
  static List<PluginMetadata> get allPlugins => [...universalPlugins, ...legacyPlugins];

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
    final pluginPath = path.join(pluginsDir, filename);
    final pluginPathOff = path.join(
      pluginsDir, 
      filename.replaceFirst(RegExp(r'\.([^.]+)$'), r'.off.$1'),
    );
    
    return File(pluginPath).existsSync() || File(pluginPathOff).existsSync();
  }

  /// Install a specific variant of a plugin
  Future<void> installVariant(PluginVariant variant) async {
    final pluginsDir = await _pluginManager.pluginsDirectory;
    
    // Ensure plugins directory exists
    final dir = Directory(pluginsDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    // Read plugin content from assets
    final content = await rootBundle.loadString(variant.assetPath);
    
    // Write to plugins directory
    final targetPath = path.join(pluginsDir, variant.filename);
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
    
    // Try both enabled and disabled versions
    final paths = [
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
  }

  // ═══════════════════════════════════════════════════════════════
  // BACKWARD COMPATIBILITY (deprecated, will be removed in v2.0)
  // ═══════════════════════════════════════════════════════════════
  
  /// @deprecated Use [allPlugins] instead
  @Deprecated('Use allPlugins instead')
  static List<LegacySamplePlugin> get samplePlugins {
    return allPlugins.expand((p) => p.variants.map((v) => LegacySamplePlugin(
      id: v.filename,
      name: '${p.name} (${v.language.displayName})',
      description: p.description,
      category: p.category.id,
      language: v.language.id,
      assetPath: v.assetPath,
      schemaAssetPath: v.schemaAssetPath,
    ))).toList();
  }
}

/// @deprecated Legacy class for backward compatibility
@Deprecated('Use PluginMetadata instead')
class LegacySamplePlugin {
  const LegacySamplePlugin({
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
}
