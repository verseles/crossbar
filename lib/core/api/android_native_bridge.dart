import 'dart:io';

import 'package:crossbar_core/crossbar_core.dart';
import 'package:flutter/services.dart';

/// AndroidNativeBridge - Provides access to Android-specific APIs via Method Channel
class AndroidNativeBridge implements AndroidBridgeInterface {
  static const _channel = MethodChannel('com.verseles.crossbar/system');

  @override
  Future<Map<String, dynamic>?> getBatteryStatus() async {
    if (!Platform.isAndroid) return null;
    try {
      final result = await _channel.invokeMethod<Map>('getBatteryStatus');
      return result != null ? Map<String, dynamic>.from(result) : null;
    } catch (e) {
      return null;
    }
  }

  @override
  Map<String, dynamic>? getBatteryStatusSync() {
    // Platform channels are async, so sync isn't supported directly
    return null;
  }

  @override
  Future<Map<String, dynamic>?> getMemoryInfo() async {
    if (!Platform.isAndroid) return null;
    try {
      final result = await _channel.invokeMethod<Map>('getMemoryInfo');
      return result != null ? Map<String, dynamic>.from(result) : null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<double?> getCpuUsage() async {
    if (!Platform.isAndroid) return null;
    try {
      return await _channel.invokeMethod<double>('getCpuUsage') ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  @override
  double? getCpuUsageSync() => 0.0;

  @override
  Future<String?> getUptime() async {
    if (!Platform.isAndroid) return null;
    try {
      final seconds = await _channel.invokeMethod<int>('getUptime');
      if (seconds == null) return null;
      return _formatUptime(Duration(seconds: seconds));
    } catch (e) {
      return null;
    }
  }

  @override
  String? getUptimeSync() {
    // Rely on caching in CrossbarBridge
    return null; 
  }

  String _formatUptime(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final parts = <String>[];
    if (days > 0) parts.add('${days}d');
    if (hours > 0) parts.add('${hours}h');
    if (minutes > 0 || parts.isEmpty) parts.add('${minutes}m');
    return parts.join(' ');
  }
}
