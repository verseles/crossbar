// ignore_for_file: avoid_slow_async_io
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/scheduler.dart';
import 'package:path/path.dart' as p;
import 'package:tray_manager/tray_manager.dart';

import '../core/plugin_manager.dart';
import 'package:crossbar_core/crossbar_core.dart' as plugin_model;
import 'logger_service.dart';
import 'refresh_service.dart';
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

  // Backend for multi-icon support (SNI)
  TrayBackend? _backend;
  final Map<String, int> _pluginIconIds = {}; // pluginId -> iconId

  bool _initialized = false;
  bool _unifiedTrayActive = false; // Tracks if unified tray_manager is active
  String? _iconPath;
  Brightness? _lastBrightness;
  Process? _gsettingsProcess;

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

    // Resolve icon path first
    await _resolveIconPath();

    // Initialize the hybrid backend for potential multi-icon support
    _backend = HybridTrayBackend();
    final backendInitialized = await _backend!.init();

    if (backendInitialized) {
      LoggerService().info(
        'TrayService: Backend initialized - ${(_backend as HybridTrayBackend).activeBackendName}',
      );
      LoggerService().info(
        'TrayService: Multi-icon support: ${_backend!.supportsMultipleIcons}',
      );
    }

    // Set up tray based on mode
    if (_useSeparateMode) {
      // SEPARATE MODE: Use BOTH tray_manager (crossbar control) + SNI daemons (plugins)
      LoggerService().info('TrayService: Using separate mode (mixed)');
      // Initialize tray_manager for crossbar control icon (Show/Quit)
      await _initUnifiedTray();
      // Plugin icons will be created via daemons when plugins output is received
    } else {
      // UNIFIED MODE: Use tray_manager for single icon with all plugins
      LoggerService().info('TrayService: Using unified mode (tray_manager)');
      await _initUnifiedTray();
    }

    // Listen for theme changes on Linux
    if (Platform.isLinux) {
      _setupThemeListener();
    }

    RefreshService().addListChangedListener(_onPluginListChanged);

    _initialized = true;
    LoggerService().info('Tray service initialized');
  }

  /// Initializes the unified tray using tray_manager.
  Future<void> _initUnifiedTray() async {
    if (_unifiedTrayActive) return;

    trayManager.addListener(this);

    if (_iconPath != null) {
      try {
        await trayManager.setIcon(_iconPath!);
      } catch (e) {
        LoggerService().warning('Failed to set tray icon: $e');
      }
    }

    _unifiedTrayActive = true;
    await _updateUnifiedMenu();

    // Set initial tooltip and title
    if (!Platform.isLinux) {
      try {
        await trayManager.setToolTip('Crossbar');
      } catch (_) {}
    }

    try {
      await trayManager.setTitle('Crossbar');
    } catch (_) {}
  }

  /// Destroys the unified tray.
  Future<void> _destroyUnifiedTray() async {
    if (!_unifiedTrayActive) return;

    trayManager.removeListener(this);
    try {
      await trayManager.destroy();
    } catch (e) {
      LoggerService().warning('Failed to destroy unified tray: $e');
    }
    _unifiedTrayActive = false;
  }

  void _setupThemeListener() {
    // Fallback: Flutter dispatcher (works on some DEs)
    final dispatcher = SchedulerBinding.instance.platformDispatcher;
    dispatcher.onPlatformBrightnessChanged = _onThemeChanged;

    // Primary: gsettings monitor (reliable on GNOME/GTK)
    _startGsettingsMonitor();
  }

  void _startGsettingsMonitor() {
    Process.start(
      'gsettings',
      ['monitor', 'org.gnome.desktop.interface', 'color-scheme'],
    ).then((process) {
      _gsettingsProcess = process;
      process.stdout
          .transform(const SystemEncoding().decoder)
          .transform(const LineSplitter())
          .listen(_onGsettingsChanged);
      // Silently ignore stderr (non-GNOME environments)
      process.stderr.drain<void>();
      LoggerService().info('gsettings monitor started for theme detection');
    }).catchError((Object e) {
      LoggerService().info('gsettings monitor not available: $e');
    });
  }

  void _onGsettingsChanged(String line) {
    // line format: "color-scheme: 'prefer-dark'" or "'default'"
    final isDark = line.contains('prefer-dark');
    final newBrightness = isDark ? Brightness.dark : Brightness.light;
    if (_lastBrightness != newBrightness) {
      _lastBrightness = newBrightness;
      LoggerService().info('Theme changed via gsettings: $newBrightness');
      unawaited(_updateIconForTheme());
    }
  }

  void _onThemeChanged() {
    if (!Platform.isLinux) return;

    final currentBrightness =
        SchedulerBinding.instance.platformDispatcher.platformBrightness;

    if (_lastBrightness != currentBrightness) {
      _lastBrightness = currentBrightness;
      LoggerService().info('Theme changed to: $currentBrightness');
      unawaited(_updateIconForTheme());
    }
  }

  /// Recalculates the icon path and reapplies it to the tray.
  Future<void> _updateIconForTheme() async {
    await _resolveIconPath();
    if (_unifiedTrayActive && _iconPath != null) {
      try {
        await trayManager.setIcon(_iconPath!);
        LoggerService().info('Tray icon updated for theme change: $_iconPath');
      } catch (e) {
        LoggerService().warning('Failed to update tray icon on theme change: $e');
      }
    }
  }

  /// Resolves the icon path based on platform and theme.
  Future<void> _resolveIconPath() async {
    String candidate;

    if (Platform.isLinux) {
      // Use cached brightness from gsettings if available, otherwise read from dispatcher
      final brightness = _lastBrightness ??
          SchedulerBinding.instance.platformDispatcher.platformBrightness;
      _lastBrightness = brightness;

      if (brightness == Brightness.dark) {
        candidate = 'assets/icons/tray_icon_light.png';
      } else {
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
          final bundlePath = p.join(
            exeDir,
            'data',
            'flutter_assets',
            candidate,
          );
          if (await File(bundlePath).exists()) {
            _iconPath = bundlePath;
          }
        } catch (_) {}
      }
    }

    if (_iconPath == null) {
      LoggerService().warning(
        'Tray icon not found at $candidate. Tray icon may not display.',
      );
      _iconPath = candidate;
    } else {
      LoggerService().info('Tray icon resolved to: $_iconPath');
    }
  }

  /// Updates the unified menu (for tray_manager).
  Future<void> _updateUnifiedMenu() async {
    if (!_unifiedTrayActive) return;

    final menuItems = <MenuItem>[];

    // Plugin outputs - only show in unified mode (in separate mode they have their own icons)
    if (!_useSeparateMode) {
      for (final plugin in _pluginManager.plugins.where((p) => p.enabled)) {
        final output = _pluginOutputs[plugin.id];
        if (output != null && output.text != null && output.text!.isNotEmpty) {
          if (output.menu.isNotEmpty) {
            final submenuItems = _convertMenuItems(output.menu);
            menuItems.add(
              MenuItem.submenu(
                label: '${output.icon} ${output.text}',
                submenu: Menu(items: submenuItems),
              ),
            );
          } else {
            menuItems.add(
              MenuItem(label: '${output.icon} ${output.text}', disabled: true),
            );
          }
        }
      }

      if (menuItems.isNotEmpty) {
        menuItems.add(MenuItem.separator());
      }
    }

    // Standard menu items
    if (_useSeparateMode) {
      // In separate mode, only Show and Quit (no Refresh All since plugins have their own)
      menuItems.addAll([
        MenuItem(key: 'show', label: 'Show'),
        MenuItem.separator(),
        MenuItem(key: 'quit', label: 'Quit'),
      ]);
    } else {
      menuItems.addAll([
        MenuItem(key: 'show', label: 'Show Crossbar'),
        MenuItem(key: 'refresh', label: 'Refresh All Plugins'),
        MenuItem.separator(),
        MenuItem(key: 'quit', label: 'Quit'),
      ]);
    }

    LoggerService().info(
      'TrayService: Setting menu with ${menuItems.length} items, separateMode=$_useSeparateMode',
    );

    try {
      await trayManager.setContextMenu(Menu(items: menuItems));
      LoggerService().info('TrayService: Menu set successfully');
    } catch (e) {
      LoggerService().warning('Failed to set tray context menu: $e');
    }
  }

  /// Converts plugin model MenuItems to tray_manager MenuItems recursively.
  List<MenuItem> _convertMenuItems(List<plugin_model.MenuItem> items) {
    final result = <MenuItem>[];
    for (final item in items) {
      if (item.separator) {
        result.add(MenuItem.separator());
      } else if (item.submenu != null && item.submenu!.isNotEmpty) {
        result.add(
          MenuItem.submenu(
            label: item.text ?? '',
            submenu: Menu(items: _convertMenuItems(item.submenu!)),
          ),
        );
      } else {
        result.add(
          MenuItem(
            key: item.href ?? item.bash ?? item.text,
            label: item.text ?? '',
          ),
        );
      }
    }
    return result;
  }

  /// Converts plugin model MenuItems to TrayMenuItem for backend.
  List<TrayMenuItem> _convertToTrayMenuItems(
    List<plugin_model.MenuItem> items,
  ) {
    final result = <TrayMenuItem>[];
    for (final item in items) {
      if (item.separator) {
        result.add(const TrayMenuItem.separator());
      } else if (item.submenu != null && item.submenu!.isNotEmpty) {
        result.add(
          TrayMenuItem(
            label: item.text ?? '',
            submenu: _convertToTrayMenuItems(item.submenu!),
          ),
        );
      } else {
        result.add(
          TrayMenuItem(
            label: item.text ?? '',
            key: item.href ?? item.bash ?? item.text,
          ),
        );
      }
    }
    return result;
  }

  void updatePluginOutput(String pluginId, plugin_model.PluginOutput output) {
    _pluginOutputs[pluginId] = output;

    LoggerService().info(
      'TrayService: updatePluginOutput for $pluginId, mode separate: $_useSeparateMode',
    );

    if (_useSeparateMode) {
      _updateSeparateIcon(pluginId, output);
    } else {
      _updateUnifiedMenu();
      _updateUnifiedTitle(pluginId, output);
    }

    _updateTooltip();
  }

  void _onPluginListChanged() {
    if (!_initialized) return;
    unawaited(refreshMenu());
  }

  /// Updates or creates a separate icon for a plugin (SNI mode).
  Future<void> _updateSeparateIcon(
    String pluginId,
    plugin_model.PluginOutput output,
  ) async {
    if (_backend == null) {
      LoggerService().warning(
        'TrayService._updateSeparateIcon: backend is null',
      );
      return;
    }

    final existingIconId = _pluginIconIds[pluginId];
    final title = '${output.icon} ${output.text ?? ''}';
    // Use plugin's trayIcon if provided, otherwise null (daemon will use mapping)
    final iconName = output.trayIcon;

    LoggerService().info(
      'TrayService._updateSeparateIcon: pluginId=$pluginId, existingIconId=$existingIconId, trayIcon=$iconName',
    );

    if (existingIconId != null) {
      // Update existing icon
      LoggerService().info(
        'TrayService._updateSeparateIcon: updating existing icon $existingIconId',
      );
      await _backend!.updateIcon(
        iconId: existingIconId,
        iconPath: iconName,
        title: title,
        tooltip: output.text ?? pluginId,
        menu: _buildPluginMenu(pluginId, output),
      );
    } else {
      // Create new icon for this plugin
      LoggerService().info(
        'TrayService._updateSeparateIcon: creating new icon for $pluginId',
      );
      final iconId = await _backend!.createIcon(
        pluginId: pluginId,
        iconPath: iconName ?? 'applications-utilities',
        tooltip: title,
      );

      if (iconId != null) {
        _pluginIconIds[pluginId] = iconId;
        LoggerService().info(
          'TrayService._updateSeparateIcon: created icon $iconId for $pluginId, totalIcons now=${_pluginIconIds.length}',
        );

        // Update with full menu immediately
        await _backend!.updateIcon(
          iconId: iconId,
          iconPath: iconName,
          title: title,
          menu: _buildPluginMenu(pluginId, output),
        );
      }
    }
  }

  /// Builds a complete menu for a plugin icon.
  List<TrayMenuItem> _buildPluginMenu(
    String pluginId,
    plugin_model.PluginOutput output,
  ) {
    final items = <TrayMenuItem>[];

    // Plugin menu items from output
    if (output.menu.isNotEmpty) {
      items.addAll(_convertToTrayMenuItems(output.menu));
      items.add(const TrayMenuItem.separator());
    }

    // Standard actions
    items.addAll([
      TrayMenuItem(label: 'Refresh', key: 'refresh_$pluginId'),
      TrayMenuItem(label: 'Disable', key: 'disable_$pluginId'),
      const TrayMenuItem.separator(),
      const TrayMenuItem(label: 'Show Crossbar', key: 'show'),
    ]);

    return items;
  }

  /// Public method to refresh the tray menu.
  Future<void> refreshMenu() async {
    if (_useSeparateMode) {
      await _cleanupSeparateIcons();
      // Recreate icons for all enabled plugins with output
      for (final plugin in _pluginManager.plugins.where((p) => p.enabled)) {
        final output = _pluginOutputs[plugin.id];
        if (output != null) {
          await _updateSeparateIcon(plugin.id, output);
        }
      }
    } else {
      await _updateUnifiedMenu();
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
    if (Platform.isLinux) return;
    if (_pluginOutputs.isEmpty) return;
    if (!_unifiedTrayActive) return;

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

  Future<void> _updateUnifiedTitle(
    String pluginId,
    plugin_model.PluginOutput output,
  ) async {
    if (!_unifiedTrayActive) return;

    final firstEnabled = _pluginManager.plugins
        .where((p) => p.enabled)
        .firstOrNull;

    if (firstEnabled?.id == pluginId) {
      var title = '';
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

    if (_useSeparateMode) {
      final iconId = _pluginIconIds.remove(pluginId);
      if (iconId != null) {
        _backend?.destroyIcon(iconId);
      }
    } else {
      _updateUnifiedMenu();
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
    final key = menuItem.key ?? '';

    // Handle disable_pluginId actions
    if (key.startsWith('disable_')) {
      final pluginId = key.substring(8);
      _disablePlugin(pluginId);
      return;
    }

    // Handle refresh_pluginId actions
    if (key.startsWith('refresh_')) {
      final pluginId = key.substring(8);
      SchedulerService().runPluginNow(pluginId);
      return;
    }

    switch (key) {
      case 'show':
        WindowService().show();
      case 'refresh':
        SchedulerService().refreshAll();
      case 'quit':
        WindowService().quit();
    }
  }

  /// Disables a plugin and removes its tray icon.
  Future<void> _disablePlugin(String pluginId) async {
    // Disable the plugin via RefreshService (handles outputs and notifications)
    await RefreshService().disablePlugin(pluginId);

    // Remove the tray icon
    final iconId = _pluginIconIds.remove(pluginId);
    if (iconId != null && _backend != null) {
      await _backend!.destroyIcon(iconId);
    }

    // Clear output
    _pluginOutputs.remove(pluginId);

    LoggerService().info('TrayService: Disabled plugin $pluginId');
  }

  Future<void> dispose() async {
    if (!_initialized) return;

    RefreshService().removeListChangedListener(_onPluginListChanged);

    // Kill gsettings monitor process
    _gsettingsProcess?.kill();
    _gsettingsProcess = null;

    // Dispose SNI backend and all separate icons
    if (_backend != null) {
      await _backend!.dispose();
      _backend = null;
    }
    _pluginIconIds.clear();

    // Dispose unified tray
    await _destroyUnifiedTray();

    _initialized = false;
  }
}
