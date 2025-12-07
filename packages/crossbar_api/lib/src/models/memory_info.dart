/// Memory usage information
class MemoryInfo {
  const MemoryInfo({
    required this.total,
    required this.used,
    required this.free,
    required this.unit,
  });

  /// Total memory
  final int total;

  /// Used memory
  final int used;

  /// Free memory
  final int free;

  /// Unit (MB, GB)
  final String unit;

  /// Usage percentage (0-100)
  double get percent => total > 0 ? (used / total) * 100 : 0;

  Map<String, dynamic> toJson() => {
        'total': total,
        'used': used,
        'free': free,
        'unit': unit,
        'percent': percent.toStringAsFixed(1),
      };

  @override
  String toString() => '$used/$total $unit (${percent.toStringAsFixed(1)}%)';
}
