import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:tray_manager/tray_manager.dart';

import '../core/plugin_manager.dart';
import '../models/plugin_output.dart' hide MenuItem;
import 'logger_service.dart';
import 'scheduler_service.dart';
import 'window_service.dart';

/// TrayService - Manages a single system tray icon using tray_manager.
///
/// Uses tray_manager for all desktop platforms (Linux, Windows, macOS).
/// Shows plugin outputs in a unified menu under a single tray icon.
class TrayService with TrayListener {
  factory TrayService() => _instance;

  TrayService._internal();

  static final TrayService _instance = TrayService._internal();

  final PluginManager _pluginManager = PluginManager();
  final Map<String, PluginOutput> _pluginOutputs = {};

  bool _initialized = false;
  String? _iconPath;

  Future<void> init() async {
    if (_initialized) return;
    if (!Platform.isLinux && !Platform.isMacOS && !Platform.isWindows) {
      return;
    }

    trayManager.addListener(this);

    await _resolveAndSetIcon();
    await _updateMenu();

    _initialized = true;
    LoggerService().info('Tray service initialized');
  }

  Future<void> _resolveAndSetIcon() async {
    String candidate;

    if (Platform.isLinux) {
      candidate = 'assets/icons/tray_icon.png';
    } else if (Platform.isMacOS) {
      candidate = 'assets/icons/tray_icon_macos.png';
    } else {
      candidate = 'assets/icons/tray_icon.ico';
    }

    // Check if icon exists at relative path (dev mode)
    if (await File(candidate).exists()) {
      _iconPath = candidate;
    } else {
      // Try to find in bundle (release mode)
      if (Platform.isLinux || Platform.isWindows) {
        try {
          final exeDir = p.dirname(Platform.resolvedExecutable);
          final bundlePath =
              p.join(exeDir, 'data', 'flutter_assets', candidate);
          if (await File(bundlePath).exists()) {
            _iconPath = bundlePath;
          }
        } catch (_) {
          // Ignore resolution errors
        }
      }
    }

    if (_iconPath == null) {
      LoggerService().warning(
          'Tray icon not found at $candidate. Tray icon may not display.');
      _iconPath = candidate; // Use anyway as fallback
    } else {
      LoggerService().info('Tray icon resolved to: $_iconPath');
    }

    try {
      await trayManager.setIcon(_iconPath!);
    } catch (e) {
      LoggerService().warning('Failed to set tray icon: $e');
    }
  }

  Future<void> _updateMenu() async {
    final menuItems = <MenuItem>[];

    // Plugin outputs - show enabled plugins
    for (final plugin in _pluginManager.plugins.where((p) => p.enabled)) {
      final output = _pluginOutputs[plugin.id];
      if (output != null && output.text != null && output.text!.isNotEmpty) {
        menuItems.add(MenuItem(
          label: '${output.icon} ${output.text}',
          disabled: true,
        ));
      }
    }

    if (menuItems.isNotEmpty) {
      menuItems.add(MenuItem.separator());
    }

    // Standard menu items
    menuItems.addAll([
      MenuItem(
        key: 'show',
        label: 'Show Crossbar',
      ),
      MenuItem(
        key: 'refresh',
        label: 'Refresh All Plugins',
      ),
      MenuItem.separator(),
      MenuItem(
        key: 'quit',
        label: 'Quit',
      ),
    ]);

    try {
      await trayManager.setContextMenu(Menu(items: menuItems));
    } catch (e) {
      LoggerService().warning('Failed to set tray context menu: $e');
    }
  }

  void updatePluginOutput(String pluginId, PluginOutput output) {
    _pluginOutputs[pluginId] = output;
    _updateMenu();
    _updateTitle(pluginId, output);
    _updateTooltip();
  }

  void _updateTooltip() {
    if (_pluginOutputs.isEmpty) return;

    final tooltipParts = <String>[];
    for (final entry in _pluginOutputs.entries.take(3)) {
      final output = entry.value;
      if (output.text != null) {
        tooltipParts.add('${output.icon} ${output.text}');
      }
    }

    try {
      trayManager.setToolTip(tooltipParts.join(' | '));
    } catch (e) {
      LoggerService().warning('Failed to set tray tooltip: $e');
    }
  }

  Future<void> _updateTitle(String pluginId, PluginOutput output) async {
    // Find the first enabled plugin to use as the main tray title
    final firstEnabled =
        _pluginManager.plugins.where((p) => p.enabled).firstOrNull;

    if (firstEnabled?.id == pluginId) {
      var title = '';
      // Use emoji icon from plugin output if available
      if (output.icon.isNotEmpty && output.icon != '⚙️') {
        title += '${output.icon} ';
      }
      if (output.text != null) {
        title += output.text!;
      }

      try {
        await trayManager.setTitle(title);
      } catch (e) {
        LoggerService().warning('Failed to set tray title: $e');
      }
    }
  }

  void clearPluginOutput(String pluginId) {
    _pluginOutputs.remove(pluginId);
    _updateMenu();
  }

  @override
  void onTrayIconMouseDown() {
    WindowService().show();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show':
        WindowService().show();
      case 'refresh':
        SchedulerService().refreshAll();
      case 'quit':
        WindowService().quit();
    }
  }

  Future<void> dispose() async {
    if (!_initialized) return;

    trayManager.removeListener(this);
    try {
      await trayManager.destroy();
    } catch (e) {
      LoggerService().warning('Failed to destroy tray: $e');
    }
    _initialized = false;
  }
}
