import '../../tray_backend.dart';
import '../../logger_service.dart';
import '../../tray_backend_factory.dart';

/// Hybrid tray backend that uses a primary backend with automatic fallback
/// This ensures maximum compatibility across different desktop environments
class HybridTrayBackend implements TrayBackend {
  final TrayBackend primaryBackend;
  final TrayBackend fallbackBackend;
  final TrayBackendMode mode;

  bool _initialized = false;
  bool _usingFallback = false;
  TrayBackend? _activeBackend;

  HybridTrayBackend({
    required this.primaryBackend,
    required this.fallbackBackend,
    required this.mode,
  });

  @override
  Future<bool> init() async {
    if (_initialized) return true;

    // Try primary backend first
    try {
      final primaryInitialized = await primaryBackend.init();
      if (primaryInitialized) {
        _activeBackend = primaryBackend;
        _initialized = true;
        _log('Hybrid tray: using primary backend (${primaryBackend.backendName})');
        return true;
      }
    } catch (e) {
      _log('Primary backend failed: $e', isError: true);
    }

    // Fallback to secondary backend
    try {
      final fallbackInitialized = await fallbackBackend.init();
      if (fallbackInitialized) {
        _activeBackend = fallbackBackend;
        _usingFallback = true;
        _initialized = true;
        _log('Hybrid tray: using fallback backend (${fallbackBackend.backendName})',
            isError: true);
        return true;
      }
    } catch (e) {
      _log('Fallback backend also failed: $e', isError: true);
    }

    _log('Hybrid tray: both backends failed to initialize', isError: true);
    return false;
  }

  @override
  Future<void> updateMenu(List<TrayMenuItem> items) async {
    if (!_initialized || _activeBackend == null) return;

    try {
      await _activeBackend!.updateMenu(items);
      _log('Hybrid tray: menu updated via ${_activeBackend!.backendName}');
    } catch (e) {
      _log('Failed to update menu via ${_activeBackend!.backendName}: $e',
          isError: true);

      // Try to switch to fallback if primary failed
      if (!_usingFallback && fallbackBackend != primaryBackend) {
        _log('Hybrid tray: attempting to switch to fallback backend');
        try {
          await fallbackBackend.init();
          _activeBackend = fallbackBackend;
          _usingFallback = true;
          await fallbackBackend.updateMenu(items);
          _log('Hybrid tray: switched to fallback backend');
        } catch (switchError) {
          _log('Failed to switch to fallback: $switchError', isError: true);
        }
      }
    }
  }

  @override
  Future<void> updateIcon(String iconPath) async {
    if (!_initialized || _activeBackend == null) return;

    try {
      await _activeBackend!.updateIcon(iconPath);
      _log('Hybrid tray: icon updated via ${_activeBackend!.backendName}');
    } catch (e) {
      _log('Failed to update icon via ${_activeBackend!.backendName}: $e',
          isError: true);
    }
  }

  @override
  Future<void> updateTitle(String title) async {
    if (!_initialized || _activeBackend == null) return;

    try {
      await _activeBackend!.updateTitle(title);
      _log('Hybrid tray: title updated via ${_activeBackend!.backendName}');
    } catch (e) {
      _log('Failed to update title via ${_activeBackend!.backendName}: $e',
          isError: true);
    }
  }

  @override
  Future<void> setTooltip(String tooltip) async {
    if (!_initialized || _activeBackend == null) return;

    try {
      await _activeBackend!.setTooltip(tooltip);
      _log('Hybrid tray: tooltip updated via ${_activeBackend!.backendName}');
    } catch (e) {
      _log('Failed to update tooltip via ${_activeBackend!.backendName}: $e',
          isError: true);
    }
  }

  @override
  Future<void> dispose() async {
    if (!_initialized) return;

    try {
      await primaryBackend.dispose();
      if (fallbackBackend != primaryBackend) {
        await fallbackBackend.dispose();
      }
      _initialized = false;
      _usingFallback = false;
      _activeBackend = null;
      _log('Hybrid tray: disposed');
    } catch (e) {
      _log('Error disposing hybrid tray: $e', isError: true);
    }
  }

  @override
  bool get supportsMultipleIcons => _activeBackend?.supportsMultipleIcons ?? false;

  @override
  bool get supportsTitle => _activeBackend?.supportsTitle ?? false;

  @override
  bool get supportsTooltip => _activeBackend?.supportsTooltip ?? false;

  @override
  String get backendName {
    if (!_initialized) {
      return 'Hybrid Tray (uninitialized)';
    }
    return 'Hybrid Tray (${_activeBackend?.backendName})';
  }

  /// Get which backend is currently active
  String get activeBackendName => _activeBackend?.backendName ?? 'none';

  /// Check if we're using the fallback backend
  bool get isUsingFallback => _usingFallback;

  /// Get the mode this hybrid was created with
  TrayBackendMode get hybridMode => mode;

  void _log(String message, {bool isError = false}) {
    final logger = LoggerService();
    if (isError) {
      logger.warning('[HybridTrayBackend] $message');
    } else {
      logger.info('[HybridTrayBackend] $message');
    }
  }
}
