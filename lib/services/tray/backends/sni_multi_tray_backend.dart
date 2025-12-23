import 'dart:io';

import 'package:dbus/dbus.dart';
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

    // On Linux, assume SNI is available - createIcon will fail gracefully
    // if the D-Bus service is not running.
    LoggerService().info('$name: Assuming SNI available on Linux');

    _initialized = true;
    LoggerService().info('$name: Initialized successfully');
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
      
      // Create initial DBus menu
      final menu = DBusMenuItem(children: [
        DBusMenuItem(label: tooltip, enabled: false),
        DBusMenuItem.separator(),
        DBusMenuItem(label: 'Refresh', onClicked: () async {
          // Callback will be handled by TrayService
        }),
      ]);

      // WORKAROUND: Each icon needs its own DBus bus connection
      // because the package uses a fixed suffix '-1' for all icons.
      // By providing a separate bus, each icon gets registered independently.
      final bus = DBusClient.session();

      final client = StatusNotifierItemClient(
        id: 'crossbar-$pluginId-$id',
        title: tooltip,
        iconName: _resolveIconName(iconPath),
        menu: menu,
        bus: bus,
      );

      await client.connect();

      _icons[id] = _SniIcon(
        pluginId: pluginId,
        client: client,
        tooltip: tooltip,
      );

      LoggerService().info('$name: Created icon $id for plugin $pluginId');
      return id;
    } catch (e, stack) {
      LoggerService().error('$name: Failed to create icon: $e', e, stack);
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

  /// Converts TrayMenuItem list to DBusMenuItem for SNI.
  DBusMenuItem _convertToDbusMenu(List<TrayMenuItem> items, String title) {
    final children = <DBusMenuItem>[];
    
    // Add title as first disabled item
    children.add(DBusMenuItem(label: title, enabled: false));
    children.add(DBusMenuItem.separator());
    
    // Convert each menu item
    for (final item in items) {
      children.add(_convertMenuItem(item));
    }
    
    // Add standard actions at the end
    if (items.isNotEmpty) {
      children.add(DBusMenuItem.separator());
    }
    children.add(DBusMenuItem(label: 'Refresh', onClicked: () async {
      // Will be handled by callback system
    }));
    
    return DBusMenuItem(children: children);
  }
  
  /// Converts a single TrayMenuItem to DBusMenuItem recursively.
  DBusMenuItem _convertMenuItem(TrayMenuItem item) {
    if (item.isSeparator) {
      return DBusMenuItem.separator();
    }
    
    if (item.submenu != null && item.submenu!.isNotEmpty) {
      return DBusMenuItem(
        label: item.label,
        children: item.submenu!.map(_convertMenuItem).toList(),
      );
    }
    
    return DBusMenuItem(
      label: item.label,
      enabled: !item.disabled,
      onClicked: item.key != null ? () async {
        // Callback will be handled by TrayService
        LoggerService().debug('$name: Menu item clicked: ${item.key}');
      } : null,
    );
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
      // Update stored tooltip
      if (tooltip != null || title != null) {
        icon.tooltip = tooltip ?? title ?? icon.tooltip;
      }
      
      // Update menu if provided
      if (menu != null) {
        icon.menuItems = menu;
        
        // Convert and update the menu using the package's updateMenu method
        final dbusMenu = _convertToDbusMenu(menu, icon.tooltip);
        await icon.client.updateMenu(dbusMenu);
        LoggerService().debug('$name: Updated menu for icon $iconId');
      }
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
