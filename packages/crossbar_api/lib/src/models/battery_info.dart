/// Battery status information
class BatteryInfo {
  const BatteryInfo({
    required this.level,
    required this.charging,
    required this.status,
  });

  /// Battery level (0-100)
  final int level;

  /// Whether battery is charging
  final bool charging;

  /// Status string (Charging, Discharging, Full, Unknown)
  final String status;

  Map<String, dynamic> toJson() => {
        'level': level,
        'charging': charging,
        'status': status,
      };

  @override
  String toString() => '$level% ($status)';
}
