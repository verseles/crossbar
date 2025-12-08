import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Native Android system information via Method Channels.
/// This provides direct access to Android APIs for battery, memory, and CPU.
class AndroidSystemChannel {
  factory AndroidSystemChannel() => _instance;
  AndroidSystemChannel._();
  static final AndroidSystemChannel _instance = AndroidSystemChannel._();

  static const MethodChannel _channel =
      MethodChannel('com.verseles.crossbar/system');

  /// Check if we're on Android
  bool get isAvailable => Platform.isAndroid;

  /// Get battery level percentage (0-100)
  Future<int> getBatteryLevel() async {
    if (!isAvailable) return -1;
    try {
      final level = await _channel.invokeMethod<int>('getBatteryLevel');
      return level ?? -1;
    } on PlatformException catch (e) {
      debugPrint('Failed to get battery level: ${e.message}');
      return -1;
    }
  }

  /// Get detailed battery status
  Future<Map<String, dynamic>> getBatteryStatus() async {
    if (!isAvailable) {
      return {'level': -1, 'isCharging': false, 'status': 'unavailable'};
    }
    try {
      final result =
          await _channel.invokeMethod<Map<dynamic, dynamic>>('getBatteryStatus');
      if (result == null) {
        return {'level': -1, 'isCharging': false, 'status': 'unavailable'};
      }
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      debugPrint('Failed to get battery status: ${e.message}');
      return {'level': -1, 'isCharging': false, 'status': 'error'};
    }
  }

  /// Get CPU usage percentage (0-100, or -1 if unavailable on Android 8+)
  Future<double> getCpuUsage() async {
    if (!isAvailable) return -1;
    try {
      final cpu = await _channel.invokeMethod<double>('getCpuUsage');
      return cpu ?? -1;
    } on PlatformException catch (e) {
      debugPrint('Failed to get CPU usage: ${e.message}');
      return -1;
    }
  }

  /// Get memory information
  Future<Map<String, dynamic>> getMemoryInfo() async {
    if (!isAvailable) {
      return {
        'totalMem': 0,
        'availMem': 0,
        'usedMem': 0,
        'usedPercent': 0.0,
      };
    }
    try {
      final result =
          await _channel.invokeMethod<Map<dynamic, dynamic>>('getMemoryInfo');
      if (result == null) {
        return {
          'totalMem': 0,
          'availMem': 0,
          'usedMem': 0,
          'usedPercent': 0.0,
        };
      }

      final info = Map<String, dynamic>.from(result);
      final totalMem = (info['totalMem'] as int?) ?? 0;
      final usedMem = (info['usedMem'] as int?) ?? 0;

      // Add percentage
      if (totalMem > 0) {
        info['usedPercent'] = (usedMem / totalMem) * 100;
      } else {
        info['usedPercent'] = 0.0;
      }

      return info;
    } on PlatformException catch (e) {
      debugPrint('Failed to get memory info: ${e.message}');
      return {
        'totalMem': 0,
        'availMem': 0,
        'usedMem': 0,
        'usedPercent': 0.0,
      };
    }
  }

  /// Format bytes to human readable string (e.g., "4.5 GB")
  String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(1)} GB';
  }
}
