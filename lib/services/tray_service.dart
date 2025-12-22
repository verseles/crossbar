// ignore_for_file: avoid_slow_async_io
import 'dart:io';
import 'dart:ui';

import 'package:flutter/scheduler.dart';
import 'package:path/path.dart' as p;
import 'package:tray_manager/tray_manager.dart';

import '../core/plugin_manager.dart';
import '../models/plugin_output.dart' as plugin_model;
import 'logger_service.dart';
import 'scheduler_service.dart';
import 'window_service.dart';

/// TrayService - Manages a single system tray icon using tray_manager.
///
/// Uses tray_manager for all desktop platforms (Linux, Windows, macOS).
/// Shows plugin outputs in a unified menu under a single tray icon.
/// On Linux, automatically switches between light/dark icons based on system theme.
class TrayService with TrayListener {
  factory TrayService() => _instance;

  TrayService._internal();

  static final TrayService _instance = TrayService._internal();

  final PluginManager _pluginManager = PluginManager();
  final Map<String, plugin_model.PluginOutput> _pluginOutputs = {};

  bool _initialized = false;
  String? _iconPath;
  Brightness? _lastBrightness;

  Future<void> init() async {
    if (_initialized) return;
    if (!Platform.isLinux && !Platform.isMacOS && !Platform.isWindows) {
      return;
    }

    trayManager.addListener(this);

    await _resolveAndSetIcon();
    await _updateMenu();
    
    // Set initial tooltip (title isn't supported on Linux)
    if (!Platform.isLinux) {
      try {
        await trayManager.setToolTip('Crossbar');
      } catch (_) {}
    }
    
    // Set initial title
    try {
      await trayManager.setTitle('Crossbar');
    } catch (_) {}

    // Listen for theme changes on Linux
    if (Platform.isLinux) {
      _setupThemeListener();
    }

    _initialized = true;
    LoggerService().info('Tray service initialized');
  }

  void _setupThemeListener() {
    // Check for theme changes periodically since platformDispatcher
    // callbacks may not work reliably for tray services
    final dispatcher = SchedulerBinding.instance.platformDispatcher;
    dispatcher.onPlatformBrightnessChanged = _onThemeChanged;
  }

  void _onThemeChanged() {
    if (!Platform.isLinux) return;

    final currentBrightness =
        SchedulerBinding.instance.platformDispatcher.platformBrightness;

    if (_lastBrightness != currentBrightness) {
      _lastBrightness = currentBrightness;
      LoggerService().info('Theme changed to: $currentBrightness');
      _resolveAndSetIcon();
    }
  }

  Future<void> _resolveAndSetIcon() async {
    String candidate;

    if (Platform.isLinux) {
      // Detect system theme and use appropriate icon
      final brightness =
          SchedulerBinding.instance.platformDispatcher.platformBrightness;
      _lastBrightness = brightness;

      if (brightness == Brightness.dark) {
        // Dark theme: use light (white) icon for visibility
        candidate = 'assets/icons/tray_icon_light.png';
      } else {
        // Light theme: use dark (black) icon for visibility
        candidate = 'assets/icons/tray_icon_dark.png';
      }
      LoggerService().info('Linux theme: $brightness, using icon: $candidate');
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

    // Plugin outputs - show enabled plugins with their menus
    for (final plugin in _pluginManager.plugins.where((p) => p.enabled)) {
      final output = _pluginOutputs[plugin.id];
      if (output != null && output.text != null && output.text!.isNotEmpty) {
        // Check if plugin has menu items to create submenu
        if (output.menu.isNotEmpty) {
          // Create submenu with plugin menu items
          final submenuItems = _convertPluginMenuItems(output.menu, plugin.id);
          menuItems.add(MenuItem.submenu(
            label: '${output.icon} ${output.text}',
            submenu: Menu(items: submenuItems),
          ));
        } else {
          // No submenu, just show the label
          menuItems.add(MenuItem(
            label: '${output.icon} ${output.text}',
            disabled: true,
          ));
        }
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

  /// Converts plugin MenuItem list to tray_manager MenuItem list recursively.
  /// Supports nested submenus up to 10 levels deep (to prevent infinite loops).
  List<MenuItem> _convertPluginMenuItems(
    List<plugin_model.MenuItem> items,
    String pluginId, [
    int depth = 0,
  ]) {
    // Limit depth to prevent issues (GNOME has submenu rendering limitations)
    const maxDepth = 10;
    if (depth >= maxDepth) {
      LoggerService().warning(
        'Max submenu depth ($maxDepth) reached for plugin $pluginId',
      );
      return [];
    }

    final result = <MenuItem>[];
    var itemIndex = 0;

    for (final item in items) {
      if (item.separator) {
        result.add(MenuItem.separator());
      } else if (item.submenu != null && item.submenu!.isNotEmpty) {
        // Recursive submenu
        final submenuItems = _convertPluginMenuItems(
          item.submenu!,
          pluginId,
          depth + 1,
        );
        result.add(MenuItem.submenu(
          label: item.text ?? '',
          submenu: Menu(items: submenuItems),
        ));
      } else {
        // Regular menu item with optional action
        final key = 'plugin_${pluginId}_${depth}_$itemIndex';
        result.add(MenuItem(
          key: key,
          label: item.text ?? '',
        ));
        // Store action for later execution
        _registerMenuItemAction(key, item);
      }
      itemIndex++;
    }

    return result;
  }

  // Map to store menu item actions for execution
  final Map<String, plugin_model.MenuItem> _menuItemActions = {};

  /// Registers a menu item action for later execution when clicked.
  void _registerMenuItemAction(String key, plugin_model.MenuItem item) {
    _menuItemActions[key] = item;
  }

  /// Executes the action associated with a plugin menu item.
  Future<void> _executeMenuItemAction(String key) async {
    final item = _menuItemActions[key];
    if (item == null) return;

    if (item.href != null && item.href!.isNotEmpty) {
      // Open URL
      try {
        await Process.run('xdg-open', [item.href!]);
      } catch (e) {
        LoggerService().warning('Failed to open URL: ${item.href} - $e');
      }
    } else if (item.bash != null && item.bash!.isNotEmpty) {
      // Execute bash command
      try {
        await Process.run('bash', ['-c', item.bash!]);
      } catch (e) {
        LoggerService().warning('Failed to execute bash: ${item.bash} - $e');
      }
    }
  }

  void updatePluginOutput(String pluginId, plugin_model.PluginOutput output) {
    _pluginOutputs[pluginId] = output;
    _updateMenu();
    _updateTitle(pluginId, output);
    _updateTooltip();
  }

  /// Public method to refresh the tray menu (e.g., after plugin toggle/delete)
  Future<void> refreshMenu() async {
    await _updateMenu();
  }

  void _updateTooltip() {
    // setToolTip is not supported on Linux by tray_manager
    if (Platform.isLinux) return;
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

  Future<void> _updateTitle(String pluginId, plugin_model.PluginOutput output) async {
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
    final key = menuItem.key;
    if (key == null) return;

    switch (key) {
      case 'show':
        WindowService().show();
      case 'refresh':
        SchedulerService().refreshAll();
      case 'quit':
        WindowService().quit();
      default:
        // Check if it's a plugin menu item action
        if (key.startsWith('plugin_')) {
          _executeMenuItemAction(key);
        }
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
