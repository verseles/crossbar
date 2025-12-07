import 'package:crossbar_api/crossbar_api.dart';

/// Example compiled plugin showing crossbar_api usage
///
/// Compile with: dart compile exe example.dart -o cpu_monitor.5s.dart.exe
void main() async {
  // Get system info
  final cpu = await Crossbar.cpu();
  final mem = await Crossbar.memory();
  final time = Crossbar.time('HH:mm');

  // Output in Crossbar format
  if (cpu > 80) {
    print('🔥 CPU: ${cpu.toStringAsFixed(0)}%');
  } else if (cpu > 50) {
    print('⚡ CPU: ${cpu.toStringAsFixed(0)}%');
  } else {
    print('💻 CPU: ${cpu.toStringAsFixed(0)}%');
  }

  // Tooltip
  print('---');
  print('RAM: ${mem.percent.toStringAsFixed(0)}%');
  print('Time: $time');
  print('---');
  print('Refresh | refresh=true');
}
