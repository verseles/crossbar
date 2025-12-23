import 'dart:io';
import 'tray_backend.dart';
import 'tray/utils/dbus_detector.dart';
import 'tray/backends/legacy_tray_backend.dart';
import 'tray/backends/sni_tray_backend.dart';
import 'tray/backends/hybrid_tray_backend.dart';

/// Factory for creating appropriate tray backend based on system capabilities
/// and user preferences
class TrayBackendFactory {
  /// Create a tray backend based on the current system and preferences
  ///
  /// [mode] specifies the desired backend mode:
  /// - auto: Auto-detect best backend (default)
  /// - sni: Force StatusNotifierItem backend
  /// - legacy: Force legacy tray_manager backend
  /// - hybrid: Auto-detect with fallback (same as auto)
  static Future<TrayBackend> create({
    TrayBackendMode mode = TrayBackendMode.auto,
  }) async {
    switch (mode) {
      case TrayBackendMode.auto:
      case TrayBackendMode.hybrid:
        return _createAutoWithFallback();

      case TrayBackendMode.sni:
        return _createSni();

      case TrayBackendMode.legacy:
        return _createLegacy();
    }
  }

  /// Create backend with automatic detection and fallback
  static Future<TrayBackend> _createAutoWithFallback() async {
    // Try SNI first (more modern, better Wayland support)
    try {
      final sniBackend = SniTrayBackend();
      final initialized = await sniBackend.init();

      if (initialized) {
        return HybridTrayBackend(
          primaryBackend: sniBackend,
          fallbackBackend: LegacyTrayBackend(),
          mode: TrayBackendMode.sni,
        );
      }
    } catch (e) {
      // SNI failed, will fallback to legacy
    }

    // Fallback to legacy tray_manager
    final legacyBackend = LegacyTrayBackend();
    await legacyBackend.init();

    return HybridTrayBackend(
      primaryBackend: legacyBackend,
      fallbackBackend: legacyBackend,
      mode: TrayBackendMode.legacy,
    );
  }

  /// Create SNI backend explicitly
  static Future<TrayBackend> _createSni() async {
    final backend = SniTrayBackend();
    final initialized = await backend.init();

    if (!initialized) {
      throw StateError(
        'SNI backend initialization failed. '
        'Please ensure AppIndicator support is available.',
      );
    }

    return backend;
  }

  /// Create legacy backend explicitly
  static Future<TrayBackend> _createLegacy() async {
    final backend = LegacyTrayBackend();
    await backend.init();
    return backend;
  }

  /// Auto-detect the best backend without creating it
  /// Returns the recommended mode
  static Future<TrayBackendMode> detectBestMode() async {
    // Check if we're on Linux
    if (!Platform.isLinux) {
      return TrayBackendMode.legacy; // tray_manager works on all platforms
    }

    // Try to detect SNI support
    final sniSupported = await SniDetector.isSupported();
    if (sniSupported) {
      return TrayBackendMode.sni;
    }

    return TrayBackendMode.legacy;
  }

  /// Get information about the recommended backend
  static Future<BackendInfo> getBackendInfo() async {
    final mode = await detectBestMode();
    final sniSupported = await SniDetector.isSupported();
    final reason = await SniDetector.getSupportReason();

    return BackendInfo(
      recommendedMode: mode,
      sniSupported: sniSupported,
      reason: reason,
    );
  }
}

/// Backend selection modes
enum TrayBackendMode {
  auto, // Auto-detect (hybrid)
  sni, // Force StatusNotifierItem
  legacy, // Force tray_manager
  hybrid, // Same as auto
}

/// Information about detected backend capabilities
class BackendInfo {
  final TrayBackendMode recommendedMode;
  final bool sniSupported;
  final String reason;

  BackendInfo({
    required this.recommendedMode,
    required this.sniSupported,
    required this.reason,
  });

  bool get willUseSni =>
      recommendedMode == TrayBackendMode.sni ||
      recommendedMode == TrayBackendMode.auto;

  @override
  String toString() {
    return 'BackendInfo(recommended: $recommendedMode, '
           'SNI: $sniSupported, reason: $reason)';
  }
}
