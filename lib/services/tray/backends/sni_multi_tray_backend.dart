import 'dart:io';

import 'package:xdg_status_notifier_item/xdg_status_notifier_item.dart';

import '../tray_backend.dart';
import '../tray_menu_item.dart';
import '../../logger_service.dart';

/// SNI-based tray backend supporting multiple icons.
///
/// Uses the xdg_status_notifier_item package to create multiple
/// StatusNotifierItem icons on Linux desktops that support SNI.
class SniMultiTrayBackend implements TrayBackend {
  bool _initialized = false;
  final Map<int, _SniIcon> _icons = {};
  int _nextId = 0;

  @override
  String get name => 'SniMultiTrayBackend (StatusNotifierItem)';

  @override
  bool get supportsMultipleIcons => true;

  @override
  int get maxIcons => 10;

  @override
  bool get isInitialized => _initialized;

  @override
  Future<bool> init() async {
    if (_initialized) return true;

    // SNI only works on Linux
    if (!Platform.isLinux) {
      LoggerService().info('$name: Not supported on non-Linux platforms');
      return false;
    }

    // Check if SNI is available by trying to detect the SNI watcher
    final sniAvailable = await _checkSniAvailable();
    if (!sniAvailable) {
      LoggerService().warning('$name: StatusNotifierItem not available on this system');
      return false;
    }

    _initialized = true;
    LoggerService().info('$name: Initialized successfully');
    return true;
  }

  /// Checks if SNI is available on the system.
  /// 
  /// Note: We assume SNI is available on Linux since most modern desktop
  /// environments support it (GNOME with AppIndicator, KDE, etc.).
  /// The actual connection will fail gracefully if SNI is not available.
  Future<bool> _checkSniAvailable() async {
    // On Linux, assume SNI is available - the createIcon will fail gracefully
    // if the D-Bus service is not running.
    // This avoids creating a visible test icon that causes a "flash".
    LoggerService().info('$name: Assuming SNI available on Linux');
    return true;
  }

  @override
  Future<int?> createIcon({
    required String pluginId,
    required String iconPath,
    required String tooltip,
  }) async {
    if (!_initialized) {
      LoggerService().warning('$name: Cannot create icon - not initialized');
      return null;
    }

    if (_icons.length >= maxIcons) {
      LoggerService().warning('$name: Maximum icon limit ($maxIcons) reached');
      return null;
    }

    try {
      final id = _nextId++;
      
      // Create DBus menu with default items
      final menu = DBusMenuItem(children: [
        DBusMenuItem(label: tooltip, enabled: false),
        DBusMenuItem.separator(),
        DBusMenuItem(label: 'Refresh', onClicked: () async {
          // Callback will be handled by TrayService
        }),
      ]);

      final client = StatusNotifierItemClient(
        id: 'crossbar-$pluginId-$id',
        title: tooltip,
        iconName: _resolveIconName(iconPath),
        menu: menu,
      );

      await client.connect();

      _icons[id] = _SniIcon(
        pluginId: pluginId,
        client: client,
        tooltip: tooltip,
      );

      LoggerService().info('$name: Created icon $id for plugin $pluginId');
      return id;
    } catch (e) {
      LoggerService().error('$name: Failed to create icon: $e');
      return null;
    }
  }

  /// Resolves icon path to an icon name for SNI.
  ///
  /// SNI uses icon names (from icon theme) rather than file paths.
  String _resolveIconName(String iconPath) {
    // If it's already an icon name (no path separators), use it directly
    if (!iconPath.contains('/') && !iconPath.contains(r'\\')) {
      return iconPath;
    }

    // Try to extract a meaningful icon name from the path
    // For now, use a generic icon as fallback
    // In the future, we could register the actual icon with the theme
    return 'applications-utilities';
  }

  @override
  Future<void> updateIcon({
    required int iconId,
    String? iconPath,
    String? title,
    String? tooltip,
    List<TrayMenuItem>? menu,
  }) async {
    if (!_initialized) return;

    final icon = _icons[iconId];
    if (icon == null) {
      LoggerService().warning('$name: Icon $iconId not found');
      return;
    }

    try {
      // Note: xdg_status_notifier_item doesn't support updating icon/menu
      // after creation. We need to recreate the icon for updates.
      // This is a limitation of the package version 0.0.1
      
      if (tooltip != null || title != null) {
        icon.tooltip = tooltip ?? title ?? icon.tooltip;
      }
      
      if (menu != null) {
        // Store for reference, but actual update requires recreate
        icon.menuItems = menu;
      }

      // For now, log the update request
      // Full implementation would recreate the icon
      LoggerService().debug('$name: Update requested for icon $iconId');
    } catch (e) {
      LoggerService().warning('$name: Failed to update icon: $e');
    }
  }

  @override
  Future<void> destroyIcon(int iconId) async {
    if (!_initialized) return;

    final icon = _icons.remove(iconId);
    if (icon == null) {
      return;
    }

    try {
      await icon.client.close();
      LoggerService().info('$name: Destroyed icon $iconId');
    } catch (e) {
      LoggerService().warning('$name: Failed to destroy icon: $e');
    }
  }

  @override
  Future<void> dispose() async {
    // Close all icon clients
    for (final icon in _icons.values) {
      try {
        await icon.client.close();
      } catch (_) {}
    }
    _icons.clear();
    _nextId = 0;
    _initialized = false;
    LoggerService().info('$name: Disposed');
  }
}

/// Internal class to track SNI icon state.
class _SniIcon {
  _SniIcon({
    required this.pluginId,
    required this.client,
    required this.tooltip,
  });

  final String pluginId;
  final StatusNotifierItemClient client;
  String tooltip;
  List<TrayMenuItem>? menuItems;
}
