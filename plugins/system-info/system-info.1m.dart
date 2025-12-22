#!/usr/bin/env dart
// System Info - Comprehensive system information
import 'dart:io';
import 'dart:convert'; // For JSON parsing

void main() async {
  final List<String> output = [];

  output.add('System Information');
  output.add('---');

  // OS Info
  final osResult = await Process.run('crossbar', ['os', '--json']);
  if (osResult.exitCode == 0) {
    try {
      final osInfo = jsonDecode(osResult.stdout.toString());
      output.add('OS: ${osInfo['name']} (${osInfo['short']})');
      output.add('Version: ${osInfo['version']}');
      output.add('Kernel: ${osInfo['kernel']}');
      output.add('Architecture: ${osInfo['arch']}');
    } catch (e) {
      output.add('OS: Error parsing crossbar os --json');
    }
  } else {
    output.add('OS: Error getting info from crossbar os');
  }

  // CPU Cores (derived from cpu --json)
  final cpuResult = await Process.run('crossbar', ['cpu', '--json']);
  if (cpuResult.exitCode == 0) {
    try {
      final cpuInfo = jsonDecode(cpuResult.stdout.toString());
      output.add('Processors: ${cpuInfo['cores']}');
    } catch (e) {
      output.add('Processors: Error parsing crossbar cpu --json');
    }
  } else {
    output.add('Processors: Error getting info from crossbar cpu');
  }

  // Locale
  final localeResult = await Process.run('crossbar', ['locale']);
  if (localeResult.exitCode == 0) {
    output.add('Locale: ${localeResult.stdout.toString().trim()}');
  } else {
    output.add('Locale: Error getting info from crossbar locale');
  }

  // Environment variables (keep as is, as crossbar env is meant for plugin's perspective)
  output.add('---');
  output.add('Environment:');
  Platform.environment.forEach((key, value) {
    if (key.startsWith('CROSSBAR_')) {
      output.add('  $key: $value');
    }
  });

  output.add('---');
  output.add('Refresh | refresh=true');

  for (final line in output) {
    print(line);
  }
}
