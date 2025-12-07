#!/usr/bin/env dart
import 'dart:io';

void main() async {
  try {
    final result = await Process.run('crossbar', ['uptime']);
    final uptime = result.stdout.toString().trim();
    print('⬆️ $uptime | size=12');
    print('---');
    print('Refresh | refresh=true');
  } catch (e) {
    print('⬆️ Error');
  }
}
