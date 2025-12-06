#!/usr/bin/env dart
/// CPU Monitor Plugin - Uses Crossbar API for portability
import 'dart:io';

String? crossbar(String args) {
  try {
    final result = Process.runSync('crossbar', args.split(' '));
    return result.exitCode == 0 ? (result.stdout as String).trim() : null;
  } catch (_) {
    return null;
  }
}

void main() {
  // Get CPU from Crossbar API
  var cpuStr = crossbar('--cpu') ?? 'N/A';
  
  double cpu = double.tryParse(cpuStr) ?? 0;
  String color;
  if (cpu > 80) {
    color = 'red';
  } else if (cpu > 50) {
    color = 'yellow';
  } else {
    color = 'green';
  }

  print('⚡ $cpuStr% | color=$color');
  print('---');
  print('CPU Usage: $cpuStr%');
  print('---');
  print('Refresh | refresh=true');
}
