import 'dart:io';

import '../tray_backend.dart';
import '../tray_menu_item.dart';
import '../../logger_service.dart';
import 'process_spawn_tray_backend.dart';
import 'legacy_tray_backend.dart';

/// Hybrid tray backend with automatic detection and fallback.
///
/// On Linux, this backend uses ProcessSpawnTrayBackend which spawns
/// separate daemon processes for each tray icon (workaround for D-Bus
/// name collision issues with SNI).
/// On other platforms, it uses the legacy tray_manager backend.
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

    // Use ProcessSpawnTrayBackend on Linux for multi-icon support
    if (Platform.isLinux) {
      final spawnBackend = ProcessSpawnTrayBackend();
      final spawnInitialized = await spawnBackend.init();
      
      if (spawnInitialized) {
        _activeBackend = spawnBackend;
        _initialized = true;
        LoggerService().info('$name: Using process spawn backend (multi-icon support)');
        return true;
      }
      
      LoggerService().info('$name: Process spawn backend not available, trying legacy backend');
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
