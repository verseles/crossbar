#!/usr/bin/env dart
// battery.30s.dart
import 'dart:convert';
import 'dart:io';

void main() {
  Map<String, dynamic>? data;
  try {
    final res = Process.runSync('crossbar', ['battery', '--json']);
    if (res.exitCode == 0) {
      data = jsonDecode(res.stdout as String);
    }
  } catch (_) {}

  if (data == null || data['level'] == null) {
    print("🔋 --");
    print("---");
    print("No battery detected");
    return;
  }

  final int level = data['level'];
  final bool charging = data['charging'] ?? false;

  String icon = "🔋", color = "green";
  if (charging) {
    icon = "⚡"; color = "blue";
  } else if (level <= 20) {
    icon = "🪫"; color = "red";
  } else if (level <= 50) {
    color = "yellow";
  }

  print("$icon $level% | color=$color");
  print("---");
  print("Battery Level: $level%");
  print("Status: ${charging ? 'Charging' : 'Discharging'}");
  print("---");
  print("Refresh | refresh=true");
}