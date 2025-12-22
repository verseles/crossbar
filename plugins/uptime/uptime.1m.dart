#!/usr/bin/env dart
// uptime.1m.dart
import 'dart:io';

void main() {
  String? uptime;
  try {
    final res = Process.runSync('crossbar', ['uptime']);
    if (res.exitCode == 0) {
      uptime = (res.stdout as String).trim();
    }
  } catch (_) {}

  if (uptime != null && uptime.isNotEmpty) {
    print("⬆️ $uptime");
    print("---");
    print("System Uptime: $uptime");
    print("Refresh | refresh=true");
  } else {
    print("⬆️ --");
    print("---");
    print("Unable to get uptime");
  }
}