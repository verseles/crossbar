import 'dart:io';

import '../tray_backend.dart';
import '../tray_menu_item.dart';
import '../../logger_service.dart';
import 'sni_multi_tray_backend.dart';
import 'legacy_tray_backend.dart';

/// Hybrid tray backend with automatic detection and fallback.
///
/// This backend tries to use SNI (StatusNotifierItem) first on Linux,
/// and falls back to the legacy tray_manager backend if SNI is not available.
class HybridTrayBackend implements TrayBackend {
  TrayBackend? _activeBackend;
  bool _initialized = false;

  @override
  String get name => 'HybridTrayBackend';

  @override
  bool get supportsMultipleIcons => _activeBackend?.supportsMultipleIcons ?? false;

  @override
  int get maxIcons => _activeBackend?.maxIcons ?? 1;

  @override
  bool get isInitialized => _initialized;

  /// Returns the name of the currently active backend.
  String get activeBackendName => _activeBackend?.name ?? 'none';

  @override
  Future<bool> init() async {
    if (_initialized) return true;

    LoggerService().info('$name: Initializing with automatic backend detection');

    // Try SNI first on Linux
    if (Platform.isLinux) {
      final sniBackend = SniMultiTrayBackend();
      final sniInitialized = await sniBackend.init();
      
      if (sniInitialized) {
        _activeBackend = sniBackend;
        _initialized = true;
        LoggerService().info('$name: Using SNI backend (multi-icon support)');
        return true;
      }
      
      LoggerService().info('$name: SNI not available, trying legacy backend');
    }

    // Fall back to legacy backend
    final legacyBackend = LegacyTrayBackend();
    final legacyInitialized = await legacyBackend.init();
    
    if (legacyInitialized) {
      _activeBackend = legacyBackend;
      _initialized = true;
      LoggerService().info('$name: Using legacy backend (single icon)');
      return true;
    }

    LoggerService().error('$name: No tray backend available');
    return false;
  }

  @override
  Future<int?> createIcon({
    required String pluginId,
    required String iconPath,
    required String tooltip,
  }) async {
    if (!_initialized || _activeBackend == null) {
      LoggerService().warning('$name: Cannot create icon - not initialized');
      return null;
    }

    return _activeBackend!.createIcon(
      pluginId: pluginId,
      iconPath: iconPath,
      tooltip: tooltip,
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
    if (!_initialized || _activeBackend == null) {
      return;
    }

    await _activeBackend!.updateIcon(
      iconId: iconId,
      iconPath: iconPath,
      title: title,
      tooltip: tooltip,
      menu: menu,
    );
  }

  @override
  Future<void> destroyIcon(int iconId) async {
    if (!_initialized || _activeBackend == null) {
      return;
    }

    await _activeBackend!.destroyIcon(iconId);
  }

  @override
  Future<void> dispose() async {
    if (_activeBackend != null) {
      await _activeBackend!.dispose();
      _activeBackend = null;
    }
    _initialized = false;
    LoggerService().info('$name: Disposed');
  }
}
