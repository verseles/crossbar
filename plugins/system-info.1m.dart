#!/usr/bin/env dart
/// System Info - Comprehensive system information
import 'dart:io';

void main() async {
  final hostname = Platform.localHostname;
  final os = Platform.operatingSystem;
  final version = Platform.operatingSystemVersion;
  final processors = Platform.numberOfProcessors;
  final locale = Platform.localeName;

  print(' $hostname');
  print('---');
  print('System Information');
  print('---');
  print('Hostname: $hostname');
  print('OS: $os');
  print('Version: $version');
  print('Processors: $processors cores');
  print('Locale: $locale');
  print('Dart: ${Platform.version.split(' ').first}');

  // Get uptime on Unix systems
  if (Platform.isLinux || Platform.isMacOS) {
    final result = await Process.run('uptime', []);
    final output = result.stdout.toString().trim();
    final uptimeMatch = RegExp(r'up\s+(.+?),').firstMatch(output);
    if (uptimeMatch != null) {
      print('Uptime: ${uptimeMatch.group(1)}');
    }
  }

  print('---');
  print('Refresh | refresh=true');
}
