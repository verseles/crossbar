#!/usr/bin/env dart
/// Memory Monitor Plugin - Uses Crossbar API for portability
import 'dart:io';

String? crossbar(List<String> args) {
  try {
    final result = Process.runSync('crossbar', args);
    return result.exitCode == 0 ? (result.stdout as String).trim() : null;
  } catch (_) {
    return null;
  }
}

void main() {
  final memoryStr = crossbar(['memory']) ?? 'N/A';
  
  final memory = int.tryParse(memoryStr.replaceAll('%', '')) ?? 0;
  String color;
  if (memory > 80) {
    color = 'red';
  } else if (memory > 60) {
    color = 'yellow';
  } else {
    color = 'green';
  }

  print('🧠 $memoryStr% | color=$color');
  print('---');
  print('Memory Usage: $memoryStr%');
  print('---');
  print('Refresh | refresh=true');
}
