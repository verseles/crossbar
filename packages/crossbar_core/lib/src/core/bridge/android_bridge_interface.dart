abstract class AndroidBridgeInterface {
  Future<Map<String, dynamic>?> getBatteryStatus();
  Map<String, dynamic>? getBatteryStatusSync();
  Future<Map<String, dynamic>?> getMemoryInfo();
  Future<double?> getCpuUsage();
  double? getCpuUsageSync();
  Future<String?> getUptime();
  String? getUptimeSync();
}
