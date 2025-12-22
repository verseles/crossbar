import 'android_bridge_interface.dart';

class AndroidNativeBridge implements AndroidBridgeInterface {
  @override
  Future<Map<String, dynamic>?> getBatteryStatus() async => null;
  @override
  Map<String, dynamic>? getBatteryStatusSync() => null;
  @override
  Future<Map<String, dynamic>?> getMemoryInfo() async => null;
  @override
  Future<double?> getCpuUsage() async => null;
  @override
  double? getCpuUsageSync() => null;
  @override
  Future<String?> getUptime() async => null;
  @override
  String? getUptimeSync() => null;
}
