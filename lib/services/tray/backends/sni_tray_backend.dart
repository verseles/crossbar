import 'dart:io';
import '../../tray_backend.dart';
import '../utils/dbus_detector.dart';
import '../../logger_service.dart';

/// StatusNotifierItem (SNI) backend
/// Note: This is a placeholder implementation
/// The xdg_status_notifier_item package API may differ
class SniTrayBackend implements TrayBackend {
  bool _initialized = false;

  @override
  Future<bool> init() async {
    if (_initialized) return true;
    if (!Platform.isLinux) {
      _log('SNI is Linux-only', isError: true);
      return false;
    }

    try {
      final sniSupported = await SniDetector.isSupported();
      if (!sniSupported) {
        final reason = await SniDetector.getSupportReason();
        _log('SNI not supported: $reason', isError: true);
        return false;
      }

      _initialized = true;
      _log('SNI tray backend initialized');
      return true;
    } catch (e) {
      _log('Failed to initialize SNI backend: $e', isError: true);
      return false;
    }
  }

  @override
  Future<void> updateMenu(List<TrayMenuItem> items) async {
    if (!_initialized) return;
    _log('SNI tray: menu update requested (${items.length} items)');
    // TODO: Implement actual SNI menu update
  }

  @override
  Future<void> updateIcon(String iconPath) async {
    if (!_initialized) return;
    _log('SNI tray: icon update requested');
    // TODO: Implement actual SNI icon update
  }

  @override
  Future<void> updateTitle(String title) async {
    if (!_initialized) return;
    _log('SNI tray: title update requested');
    // TODO: Implement actual SNI title update
  }

  @override
  Future<void> setTooltip(String tooltip) async {
    if (!_initialized) return;
    _log('SNI tray: tooltip update requested');
    // TODO: Implement actual SNI tooltip update
  }

  @override
  Future<void> dispose() async {
    if (!_initialized) return;
    try {
      _initialized = false;
      _log('SNI tray backend disposed');
    } catch (e) {
      _log('Error disposing SNI tray: $e', isError: true);
    }
  }

  @override
  bool get supportsMultipleIcons => true;

  @override
  bool get supportsTitle => true;

  @override
  bool get supportsTooltip => true;

  @override
  String get backendName => 'StatusNotifierItem (SNI)';

  void _log(String message, {bool isError = false}) {
    final logger = LoggerService();
    if (isError) {
      logger.warning('[SniTrayBackend] $message');
    } else {
      logger.info('[SniTrayBackend] $message');
    }
  }
}
