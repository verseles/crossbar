#!/usr/bin/env dart
/// Clock Plugin - Shows current time using Crossbar API
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
  final now = DateTime.now();
  final timeStr = crossbar(['time']) ?? 
      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  final dateStr = crossbar(['date']) ?? 
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  print('🕐 $timeStr');
  print('---');
  print('Time: $timeStr');
  print('Date: $dateStr');
  print('---');
  print('Refresh | refresh=true');
}
