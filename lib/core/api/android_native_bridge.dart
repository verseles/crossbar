import 'dart:io';

import 'package:flutter/services.dart';

/// AndroidNativeBridge - Provides access to Android-specific APIs via Method Channel
///
/// This bridge is only used on Android to access system information that requires
/// native Android APIs (BatteryManager, ActivityManager, etc.) due to SELinux restrictions.
///
/// DO NOT import this in code that needs to compile with `dart compile exe` (CLI).
class AndroidNativeBridge {
  factory AndroidNativeBridge() => _instance;
  AndroidNativeBridge._();

  static final AndroidNativeBridge _instance = AndroidNativeBridge._();

  static const _channel = MethodChannel('com.verseles.crossbar/system');

  /// Get battery status from native Android BatteryManager
  /// Returns null if not available or not on Android
  Future<Map<String, dynamic>?> getBatteryStatus() async {
    if (!Platform.isAndroid) return null;

    try {
      final result = await _channel.invokeMethod<Map>('getBatteryStatus');
      if (result == null) return null;

      // Convert to Map<String, dynamic>
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return null;
    }
  }

  /// Get battery status synchronously (BLOCKING - use with caution)
  /// This will block the Dart isolate while waiting for the platform channel
  ///
  /// Note: Platform channels are inherently async, but we use a timeout to make it "sync"
  Map<String, dynamic>? getBatteryStatusSync() {
    if (!Platform.isAndroid) return null;

    try {
      // This is a workaround - platform channels are async
      // We can't truly make them sync, so we'll handle this differently
      // The caller should use the async version when possible
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get memory info from native Android ActivityManager
  Future<Map<String, dynamic>?> getMemoryInfo() async {
    if (!Platform.isAndroid) return null;

    try {
      final result = await _channel.invokeMethod<Map>('getMemoryInfo');
      if (result == null) return null;

      return Map<String, dynamic>.from(result);
    } catch (e) {
      return null;
    }
  }

  /// Get CPU usage (always returns 0.0 on Android due to SELinux restrictions)
  ///
  /// Note: On Android 8+, /proc/stat is blocked by SELinux.
  /// System-wide CPU monitoring is unavailable.
  ///
  /// Returns:
  /// - 0.0: CPU monitoring unavailable on Android
  /// - null: Not on Android platform
  Future<double?> getCpuUsage() async {
    if (!Platform.isAndroid) return null;

    try {
      final result = await _channel.invokeMethod<double>('getCpuUsage');
      return result ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  /// Get CPU usage synchronously (always returns 0.0 on Android)
  double? getCpuUsageSync() {
    if (!Platform.isAndroid) return null;
    return 0.0;
  }
}
