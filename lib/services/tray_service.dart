// ignore_for_file: avoid_slow_async_io
import 'dart:io';
import 'dart:ui';

import 'package:flutter/scheduler.dart';
import 'package:path/path.dart' as p;
import 'package:tray_manager/tray_manager.dart';

import '../core/plugin_manager.dart';
import 'package:crossbar_core/crossbar_core.dart' as plugin_model;
import 'logger_service.dart';
import 'scheduler_service.dart';
import 'settings_service.dart';
import 'tray/tray_backend.dart';
import 'tray/tray_menu_item.dart';
import 'tray/backends/hybrid_tray_backend.dart';
import 'window_service.dart';

/// TrayService - Manages system tray icons using pluggable backends.
///
/// Supports two modes:
/// - **Unified**: Single tray icon with menu for all plugins (default, all platforms)
/// - **Separate**: Multiple tray icons, one per plugin (Linux with SNI support)
///
/// On Linux, automatically tries SNI (StatusNotifierItem) first for multi-icon
/// support, falling back to tray_manager if SNI is not available.
class TrayService with TrayListener {
  factory TrayService() => _instance;

  TrayService._internal();

  static final TrayService _instance = TrayService._internal();

  final PluginManager _pluginManager = PluginManager();
  final Map<String, plugin_model.PluginOutput> _pluginOutputs = {};

  // Backend for multi-icon support
  TrayBackend? _backend;
  final Map<String, int> _pluginIconIds = {}; // pluginId -> iconId

  bool _initialized = false;
  String? _iconPath;
  Brightness? _lastBrightness;

  /// Returns the current tray display mode from settings.
  TrayDisplayMode get _displayMode => SettingsService().trayDisplayMode;

  /// Returns true if separate mode is active and supported.
  bool get _useSeparateMode =>
      _displayMode == TrayDisplayMode.separate &&
      _backend != null &&
      _backend!.supportsMultipleIcons;

  Future<void> init() async {
    if (_initialized) return;
    if (!Platform.isLinux && !Platform.isMacOS && !Platform.isWindows) {
      return;
    }

    // Initialize the hybrid backend for potential multi-icon support
    _backend = HybridTrayBackend();
    final backendInitialized = await _backend!.init();
    
    if (backendInitialized) {
      LoggerService().info(
        'TrayService: Backend initialized - ${(_backend as HybridTrayBackend).activeBackendName}'
      );
      LoggerService().info(
        'TrayService: Multi-icon support: ${_backend!.supportsMultipleIcons}'
      );
    }

    // Always set up tray_manager listener for unified mode and click handling
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
        // Check if plugin has menu items
        if (output.menu.isNotEmpty) {
          // Create submenu with plugin output items
          final submenuItems = _convertMenuItems(output.menu);
          menuItems.add(MenuItem.submenu(
            label: '${output.icon} ${output.text}',
            submenu: Menu(items: submenuItems),
          ));
        } else {
          // No submenu, just show the output
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

  /// Converts plugin model MenuItems to tray_manager MenuItems recursively
  List<MenuItem> _convertMenuItems(List<plugin_model.MenuItem> items) {
    final result = <MenuItem>[];
    for (final item in items) {
      if (item.separator) {
        result.add(MenuItem.separator());
      } else if (item.submenu != null && item.submenu!.isNotEmpty) {
        // Item has submenu - create a submenu
        result.add(MenuItem.submenu(
          label: item.text ?? '',
          submenu: Menu(items: _convertMenuItems(item.submenu!)),
        ));
      } else {
        // Regular menu item
        result.add(MenuItem(
          key: item.href ?? item.bash ?? item.text,
          label: item.text ?? '',
        ));
      }
    }
    return result;
  }

  /// Converts plugin model MenuItems to TrayMenuItem for backend
  List<TrayMenuItem> _convertToTrayMenuItems(List<plugin_model.MenuItem> items) {
    final result = <TrayMenuItem>[];
    for (final item in items) {
      if (item.separator) {
        result.add(const TrayMenuItem.separator());
      } else if (item.submenu != null && item.submenu!.isNotEmpty) {
        result.add(TrayMenuItem(
          label: item.text ?? '',
          submenu: _convertToTrayMenuItems(item.submenu!),
        ));
      } else {
        result.add(TrayMenuItem(
          label: item.text ?? '',
          key: item.href ?? item.bash ?? item.text,
        ));
      }
    }
    return result;
  }

  void updatePluginOutput(String pluginId, plugin_model.PluginOutput output) {
    _pluginOutputs[pluginId] = output;

    if (_useSeparateMode) {
      _updateSeparateIcon(pluginId, output);
    } else {
      _updateMenu();
      _updateTitle(pluginId, output);
    }
    
    _updateTooltip();
  }

  /// Updates or creates a separate icon for a plugin in separate mode.
  Future<void> _updateSeparateIcon(
    String pluginId,
    plugin_model.PluginOutput output,
  ) async {
    if (_backend == null) return;

    final existingIconId = _pluginIconIds[pluginId];
    
    if (existingIconId != null) {
      // Update existing icon
      await _backend!.updateIcon(
        iconId: existingIconId,
        title: '${output.icon} ${output.text ?? ''}',
        tooltip: output.text ?? pluginId,
        menu: output.menu.isNotEmpty 
            ? _convertToTrayMenuItems(output.menu)
            : null,
      );
    } else {
      // Create new icon
      final iconPath = _iconPath ?? 'applications-utilities';
      final iconId = await _backend!.createIcon(
        pluginId: pluginId,
        iconPath: iconPath,
        tooltip: '${output.icon} ${output.text ?? pluginId}',
      );
      
      if (iconId != null) {
        _pluginIconIds[pluginId] = iconId;
        LoggerService().info('Created separate tray icon for plugin $pluginId');
      }
    }
  }

  /// Public method to refresh the tray menu (e.g., after plugin toggle/delete)
  Future<void> refreshMenu() async {
    await _updateMenu();
    
    // In separate mode, remove icons for disabled/deleted plugins
    if (_useSeparateMode) {
      await _cleanupSeparateIcons();
    }
  }

  /// Removes separate icons for plugins that are no longer enabled.
  Future<void> _cleanupSeparateIcons() async {
    if (_backend == null) return;

    final enabledPluginIds = _pluginManager.plugins
        .where((p) => p.enabled)
        .map((p) => p.id)
        .toSet();

    final iconsToRemove = <String>[];
    for (final pluginId in _pluginIconIds.keys) {
      if (!enabledPluginIds.contains(pluginId)) {
        iconsToRemove.add(pluginId);
      }
    }

    for (final pluginId in iconsToRemove) {
      final iconId = _pluginIconIds.remove(pluginId);
      if (iconId != null) {
        await _backend!.destroyIcon(iconId);
        LoggerService().info('Removed separate tray icon for plugin $pluginId');
      }
    }
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
    
    // In separate mode, remove the icon for this plugin
    if (_useSeparateMode) {
      final iconId = _pluginIconIds.remove(pluginId);
      if (iconId != null) {
        _backend?.destroyIcon(iconId);
      }
    }
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

    // Dispose backend and all separate icons
    if (_backend != null) {
      await _backend!.dispose();
      _backend = null;
    }
    _pluginIconIds.clear();

    trayManager.removeListener(this);
    try {
      await trayManager.destroy();
    } catch (e) {
      LoggerService().warning('Failed to destroy tray: $e');
    }
    _initialized = false;
  }
}
