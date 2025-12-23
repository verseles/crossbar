import 'dart:io';

import 'package:tray_manager/tray_manager.dart';

import '../tray_backend.dart';
import '../tray_menu_item.dart';
import '../../logger_service.dart';

/// Legacy tray backend using tray_manager package.
///
/// This backend supports only a single tray icon and is used as fallback
/// when SNI is not available, or on platforms other than Linux.
class LegacyTrayBackend implements TrayBackend {
  bool _initialized = false;
  int _currentIconId = -1;

  @override
  String get name => 'LegacyTrayBackend (tray_manager)';

  @override
  bool get supportsMultipleIcons => false;

  @override
  int get maxIcons => 1;

  @override
  bool get isInitialized => _initialized;

  @override
  Future<bool> init() async {
    if (_initialized) return true;

    // tray_manager only works on desktop platforms
    if (!Platform.isLinux && !Platform.isMacOS && !Platform.isWindows) {
      LoggerService().warning('$name: Not supported on this platform');
      return false;
    }

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

    // Only one icon supported
    if (_currentIconId >= 0) {
      LoggerService().warning('$name: Only one icon supported, returning existing ID');
      return _currentIconId;
    }

    try {
      await trayManager.setIcon(iconPath);
      if (!Platform.isLinux) {
        await trayManager.setToolTip(tooltip);
      }
      _currentIconId = 0;
      LoggerService().info('$name: Created icon for plugin $pluginId');
      return _currentIconId;
    } catch (e) {
      LoggerService().error('$name: Failed to create icon: $e');
      return null;
    }
  }

  @override
  Future<void> updateIcon({
    required int iconId,
    String? iconPath,
    String? title,
    String? tooltip,
    List<TrayMenuItem>? menu,
  }) async {
    if (!_initialized || iconId != _currentIconId) {
      return;
    }

    try {
      if (iconPath != null) {
        await trayManager.setIcon(iconPath);
      }
      if (title != null) {
        await trayManager.setTitle(title);
      }
      if (tooltip != null && !Platform.isLinux) {
        await trayManager.setToolTip(tooltip);
      }
      if (menu != null) {
        final trayMenu = _convertMenu(menu);
        await trayManager.setContextMenu(trayMenu);
      }
    } catch (e) {
      LoggerService().warning('$name: Failed to update icon: $e');
    }
  }

  /// Converts TrayMenuItem list to tray_manager Menu
  Menu _convertMenu(List<TrayMenuItem> items) {
    return Menu(items: _convertMenuItems(items));
  }

  List<MenuItem> _convertMenuItems(List<TrayMenuItem> items) {
    final result = <MenuItem>[];
    for (final item in items) {
      if (item.isSeparator) {
        result.add(MenuItem.separator());
      } else if (item.hasSubmenu) {
        result.add(MenuItem.submenu(
          label: item.label,
          submenu: Menu(items: _convertMenuItems(item.submenu!)),
        ));
      } else {
        result.add(MenuItem(
          key: item.key ?? item.label,
          label: item.label,
          disabled: item.disabled,
        ));
      }
    }
    return result;
  }

  @override
  Future<void> destroyIcon(int iconId) async {
    if (!_initialized || iconId != _currentIconId) {
      return;
    }

    try {
      await trayManager.destroy();
      _currentIconId = -1;
      LoggerService().info('$name: Destroyed icon');
    } catch (e) {
      LoggerService().warning('$name: Failed to destroy icon: $e');
    }
  }

  @override
  Future<void> dispose() async {
    if (_currentIconId >= 0) {
      await destroyIcon(_currentIconId);
    }
    _initialized = false;
    LoggerService().info('$name: Disposed');
  }
}
