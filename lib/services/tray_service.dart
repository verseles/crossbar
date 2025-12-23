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
import 'window_service.dart';
import 'tray_backend.dart';
import 'tray_backend_factory.dart';

/// TrayService - Manages system tray icons using a hybrid backend system.
///
/// Supports multiple tray implementations:
/// - StatusNotifierItem (SNI) for modern Linux desktop environments
/// - Legacy tray_manager for cross-platform compatibility
/// - Automatic fallback between implementations
///
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

  // Hybrid tray backend
  TrayBackend? _trayBackend;
  bool _useHybridBackend = true; // Can be disabled via env var for testing

  Future<void> init() async {
    if (_initialized) return;
    if (!Platform.isLinux && !Platform.isMacOS && !Platform.isWindows) {
      return;
    }

    // Check if hybrid backend should be used
    final forceLegacy = Platform.environment['CROSSBAR_TRAY_BACKEND'] == 'legacy';
    final forceSni = Platform.environment['CROSSBAR_TRAY_BACKEND'] == 'sni';
    final useHybrid = _useHybridBackend && !forceLegacy && !forceSni;

    if (useHybrid) {
      // Use hybrid backend with auto-detection
      try {
        final backendMode = forceSni
            ? TrayBackendMode.sni
            : TrayBackendMode.auto;

        _trayBackend = await TrayBackendFactory.create(mode: backendMode);
        await _trayBackend!.init();

        // Get backend info for logging
        final info = await TrayBackendFactory.getBackendInfo();
        LoggerService().info(
          'Tray service initialized with hybrid backend: ${info.recommendedMode} '
          '(${info.reason})'
        );
      } catch (e) {
        LoggerService().warning('Failed to initialize hybrid tray backend: $e');
        LoggerService().info('Falling back to legacy tray_manager');
        _trayBackend = null;
      }
    }

    // Fallback to legacy tray_manager if hybrid failed
    if (_trayBackend == null) {
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
    }

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

  void updatePluginOutput(String pluginId, plugin_model.PluginOutput output) {
    _pluginOutputs[pluginId] = output;

    // Use hybrid backend if available
    if (_trayBackend != null) {
      _updateMenuHybrid();
      _updateTitleHybrid(pluginId, output);
      _updateTooltipHybrid();
    } else {
      // Fallback to legacy tray_manager
      _updateMenu();
      _updateTitle(pluginId, output);
      _updateTooltip();
    }
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

  // Hybrid backend methods
  Future<void> _updateMenuHybrid() async {
    if (_trayBackend == null) return;

    final menuItems = <TrayMenuItem>[];

    // Plugin outputs - show enabled plugins with their menus
    for (final plugin in _pluginManager.plugins.where((p) => p.enabled)) {
      final output = _pluginOutputs[plugin.id];
      if (output != null && output.text != null && output.text!.isNotEmpty) {
        // Check if plugin has menu items
        if (output.menu.isNotEmpty) {
          // Create submenu with plugin output items
          final submenuItems = _convertToTrayBackendMenu(output.menu);
          menuItems.add(TrayMenuItem.submenu(
            label: '${output.icon} ${output.text}',
            submenu: submenuItems,
          ));
        } else {
          // No submenu, just show the output
          menuItems.add(TrayMenuItem(
            label: '${output.icon} ${output.text}',
            disabled: true,
          ));
        }
      }
    }

    if (menuItems.isNotEmpty) {
      menuItems.add(TrayMenuItem.separator());
    }

    // Standard menu items
    menuItems.addAll([
      TrayMenuItem(
        key: 'show',
        label: 'Show Crossbar',
      ),
      TrayMenuItem(
        key: 'refresh',
        label: 'Refresh All Plugins',
      ),
      TrayMenuItem.separator(),
      TrayMenuItem(
        key: 'quit',
        label: 'Quit',
      ),
    ]);

    try {
      await _trayBackend!.updateMenu(menuItems);
    } catch (e) {
      LoggerService().warning('Failed to set hybrid tray context menu: $e');
    }
  }

  Future<void> _updateTitleHybrid(String pluginId, plugin_model.PluginOutput output) async {
    if (_trayBackend == null) return;
    if (!_trayBackend!.supportsTitle) return;

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
        await _trayBackend!.updateTitle(title);
      } catch (e) {
        LoggerService().warning('Failed to set hybrid tray title: $e');
      }
    }
  }

  void _updateTooltipHybrid() {
    if (_trayBackend == null) return;
    if (!_trayBackend!.supportsTooltip) return;
    if (_pluginOutputs.isEmpty) return;

    final tooltipParts = <String>[];
    for (final entry in _pluginOutputs.entries.take(3)) {
      final output = entry.value;
      if (output.text != null) {
        tooltipParts.add('${output.icon} ${output.text}');
      }
    }

    _trayBackend!.setTooltip(tooltipParts.join(' | '));
  }

  /// Converts plugin model MenuItems to TrayBackend MenuItems recursively
  List<TrayMenuItem> _convertToTrayBackendMenu(List<plugin_model.MenuItem> items) {
    final result = <TrayMenuItem>[];
    for (final item in items) {
      if (item.separator) {
        result.add(TrayMenuItem.separator());
      } else if (item.submenu != null && item.submenu!.isNotEmpty) {
        // Item has submenu - create a submenu
        result.add(TrayMenuItem.submenu(
          label: item.text ?? '',
          submenu: _convertToTrayBackendMenu(item.submenu!),
        ));
      } else {
        // Regular menu item
        result.add(TrayMenuItem(
          key: item.href ?? item.bash ?? item.text,
          label: item.text ?? '',
        ));
      }
    }
    return result;
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

    // Dispose hybrid backend if being used
    if (_trayBackend != null) {
      try {
        await _trayBackend!.dispose();
        _trayBackend = null;
        LoggerService().info('Hybrid tray backend disposed');
      } catch (e) {
        LoggerService().warning('Failed to dispose hybrid tray backend: $e');
      }
    } else {
      // Fallback to legacy tray_manager
      trayManager.removeListener(this);
      try {
        await trayManager.destroy();
      } catch (e) {
        LoggerService().warning('Failed to destroy tray: $e');
      }
    }

    _initialized = false;
  }
}
