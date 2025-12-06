#!/usr/bin/env dart
/// Battery Monitor Plugin - Uses Crossbar API for portability
import 'dart:io';
import 'dart:convert';

String? crossbar(String args) {
  try {
    final result = Process.runSync('crossbar', args.split(' '));
    return result.exitCode == 0 ? (result.stdout as String).trim() : null;
  } catch (_) {
    return null;
  }
}

void main() {
  var batteryStr = crossbar('--battery') ?? 'N/A';
  var charging = false;

  final jsonStr = crossbar('--battery --json');
  if (jsonStr != null) {
    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      charging = data['charging'] as bool? ?? false;
    } catch (_) {}
  }

  final battery = int.tryParse(batteryStr) ?? 0;
  String icon, color;

  if (charging) {
    icon = '🔌'; color = 'blue';
  } else if (battery < 20) {
    icon = '🪫'; color = 'red';
  } else if (battery < 50) {
    icon = '🔋'; color = 'yellow';
  } else {
    icon = '🔋'; color = 'green';
  }

  print('$icon $batteryStr% | color=$color');
  print('---');
  print('Battery: $batteryStr%');
  if (charging) print('Status: Charging ⚡');
  print('---');
  print('Refresh | refresh=true');
}
