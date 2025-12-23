import 'dart:io';
import 'package:tray_manager/tray_manager.dart';
import '../../tray_backend.dart';
import '../../logger_service.dart';
import '../../scheduler_service.dart';
import '../../window_service.dart';

/// Legacy tray backend using tray_manager package
class LegacyTrayBackend implements TrayBackend {
  bool _initialized = false;

  @override
  Future<bool> init() async {
    if (_initialized) return true;
    if (!Platform.isLinux && !Platform.isMacOS && !Platform.isWindows) {
      return false;
    }

    try {
      trayManager.addListener(_TrayListener());
      _initialized = true;
      _log('Legacy tray backend initialized');
      return true;
    } catch (e) {
      _log('Failed to initialize legacy tray: $e', isError: true);
      return false;
    }
  }

  @override
  Future<void> updateMenu(List<TrayMenuItem> items) async {
    if (!_initialized) return;

    try {
      final trayItems = <MenuItem>[];
      for (final item in items) {
        if (item.separator) {
          trayItems.add(MenuItem.separator());
        } else if (item.submenu != null && item.submenu!.isNotEmpty) {
          final submenuItems = _convertSubmenu(item.submenu!);
          trayItems.add(MenuItem.submenu(
            label: item.label,
            submenu: Menu(items: submenuItems),
          ));
        } else {
          trayItems.add(MenuItem(
            key: item.key ?? item.label,
            label: item.label,
            disabled: item.disabled,
          ));
        }
      }
      await trayManager.setContextMenu(Menu(items: trayItems));
    } catch (e) {
      _log('Failed to update legacy tray menu: $e', isError: true);
    }
  }

  @override
  Future<void> updateIcon(String iconPath) async {
    if (!_initialized) return;
    try {
      await trayManager.setIcon(iconPath);
    } catch (e) {
      _log('Failed to set legacy tray icon: $e', isError: true);
    }
  }

  @override
  Future<void> updateTitle(String title) async {
    if (!_initialized) return;
    try {
      await trayManager.setTitle(title);
    } catch (e) {
      _log('Failed to set legacy tray title: $e');
    }
  }

  @override
  Future<void> setTooltip(String tooltip) async {
    if (!_initialized || Platform.isLinux) return;
    try {
      await trayManager.setToolTip(tooltip);
    } catch (e) {
      _log('Failed to set legacy tray tooltip: $e');
    }
  }

  @override
  Future<void> dispose() async {
    if (!_initialized) return;
    try {
      trayManager.removeListener(_TrayListener.instance);
      await trayManager.destroy();
      _initialized = false;
    } catch (e) {
      _log('Error disposing legacy tray: $e', isError: true);
    }
  }

  @override
  bool get supportsMultipleIcons => false;

  @override
  bool get supportsTitle => true;

  @override
  bool get supportsTooltip => !Platform.isLinux;

  @override
  String get backendName => 'Legacy Tray (tray_manager)';

  List<MenuItem> _convertSubmenu(List<TrayMenuItem> items) {
    final result = <MenuItem>[];
    for (final item in items) {
      if (item.separator) {
        result.add(MenuItem.separator());
      } else if (item.submenu != null && item.submenu!.isNotEmpty) {
        result.add(MenuItem.submenu(
          label: item.label,
          submenu: Menu(items: _convertSubmenu(item.submenu!)),
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

  void _log(String message, {bool isError = false}) {
    final logger = LoggerService();
    if (isError) {
      logger.warning('[LegacyTrayBackend] $message');
    } else {
      logger.info('[LegacyTrayBackend] $message');
    }
  }
}

class _TrayListener implements TrayListener {
  static _TrayListener? _instance;
  static _TrayListener get instance => _instance!;

  _TrayListener() {
    _instance = this;
  }

  @override
  void onTrayIconMouseDown() {
    WindowService().show();
  }

  @override
  void onTrayIconMouseUp() {
    // Optional: handle mouse up event
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseUp() {
    // Optional: handle right mouse up event
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show':
        WindowService().show();
        break;
      case 'refresh':
        SchedulerService().refreshAll();
        break;
      case 'quit':
        WindowService().quit();
        break;
    }
  }
}
