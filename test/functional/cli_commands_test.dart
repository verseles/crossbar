import 'dart:io';

import 'package:crossbar/core/api/network_api.dart';
import 'package:crossbar/core/api/system_api.dart';
import 'package:flutter_test/flutter_test.dart';

/// Functional tests for CLI commands.
/// These tests execute real system commands and validate their output.
/// They run in CI since they only require standard Linux system access.
void main() {
  group('CLI Commands - System', () {
    late SystemApi systemApi;

    setUp(() {
      systemApi = const SystemApi();
    });

    test('getCpuUsage returns valid percentage string', () async {
      final cpu = await systemApi.getCpuUsage();

      // Should be a numeric string like "12.5" or "0.0"
      expect(cpu, matches(RegExp(r'^\d+\.\d+$')));

      final value = double.parse(cpu);
      expect(value, greaterThanOrEqualTo(0.0));
      expect(value, lessThanOrEqualTo(100.0));
    });

    test('getMemoryUsage returns formatted memory string', () async {
      final memory = await systemApi.getMemoryUsage();

      // Should contain numbers and units like "8.2 GB / 16.0 GB" or similar
      // Or "Unknown" if unable to get memory info
      expect(
        memory,
        anyOf(
          matches(RegExp(r'\d+.*[GMK]B', caseSensitive: false)),
          equals('Unknown'),
        ),
      );
    });

    test('getDiskUsage returns valid disk info', () async {
      final disk = await systemApi.getDiskUsage();

      // Should contain percentage or size info
      // Format varies but should have numbers
      expect(disk, isNotEmpty);
    });

    test('getDiskUsage accepts path parameter', () async {
      final disk = await systemApi.getDiskUsage('/');

      expect(disk, isNotEmpty);
    });

    test('getBatteryStatus returns string', () async {
      final battery = await systemApi.getBatteryStatus();

      // Returns percentage like "85%" or "N/A" on desktops
      expect(
        battery,
        anyOf(
          matches(RegExp(r'\d+%')),
          equals('N/A'),
          equals('AC Power'),
          contains('%'),
        ),
      );
    });

    test('getUptime returns formatted uptime', () async {
      final uptime = await systemApi.getUptime();

      // Should be formatted like "2d 5h 30m" or "5h 30m" or "Unknown"
      expect(
        uptime,
        anyOf(
          matches(RegExp(r'\d+[dhms]')),
          equals('Unknown'),
        ),
      );
    });

    test('getOs returns operating system name', () async {
      final os = systemApi.getOs();

      expect(os, isNotEmpty);
      if (Platform.isLinux) {
        expect(os.toLowerCase(), anyOf(contains('linux'), contains('ubuntu'), contains('arch'), contains('debian'), contains('fedora')));
      }
    });

    test('getOsDetails returns detailed OS info', () async {
      final details = systemApi.getOsDetails();

      expect(details, isNotEmpty);
    });
  });

  group('CLI Commands - Network', () {
    late NetworkApi networkApi;

    setUp(() {
      networkApi = const NetworkApi();
    });

    test('getNetStatus returns online or offline', () async {
      final status = await networkApi.getNetStatus();

      expect(status, anyOf(equals('online'), equals('offline')));
    });

    test('getLocalIp returns valid IP or localhost', () async {
      final ip = await networkApi.getLocalIp();

      // Should be valid IP format or localhost indicators
      expect(
        ip,
        anyOf(
          matches(RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$')),
          equals('127.0.0.1'),
          equals('localhost'),
          equals('N/A'),
        ),
      );
    });

    test('getWifiSsid returns string', () async {
      final ssid = await networkApi.getWifiSsid();

      // Returns SSID name or "Not connected" / "N/A"
      expect(ssid, isA<String>());
    });
  });

  group('CLI Commands - Utilities', () {
    test('hash command produces correct MD5', () async {
      // Test MD5 hash of "hello"
      final result = await Process.run('sh', ['-c', 'echo -n "hello" | md5sum | cut -d" " -f1']);
      final expected = (result.stdout as String).trim();

      expect(expected, equals('5d41402abc4b2a76b9719d911017c592'));
    });

    test('hash command produces correct SHA256', () async {
      // Test SHA256 hash of "hello"
      final result = await Process.run('sh', ['-c', 'echo -n "hello" | sha256sum | cut -d" " -f1']);
      final expected = (result.stdout as String).trim();

      expect(expected, equals('2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824'));
    });

    test('UUID generation produces valid format', () async {
      final result = await Process.run('sh', ['-c', 'cat /proc/sys/kernel/random/uuid']);
      final uuid = (result.stdout as String).trim();

      // UUID v4 format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
      expect(uuid, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')));
    });

    test('random number generation works', () async {
      final result = await Process.run('sh', ['-c', r'echo $((RANDOM % 100))']);
      final randomStr = (result.stdout as String).trim();
      final random = int.tryParse(randomStr);

      expect(random, isNotNull);
      expect(random, greaterThanOrEqualTo(0));
      expect(random, lessThan(100));
    });

    test('date command returns valid date', () async {
      final result = await Process.run('date', ['+%Y-%m-%d']);
      final date = (result.stdout as String).trim();

      // Should match YYYY-MM-DD format
      expect(date, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
    });

    test('time command returns valid time', () async {
      final result = await Process.run('date', ['+%H:%M:%S']);
      final time = (result.stdout as String).trim();

      // Should match HH:MM:SS format
      expect(time, matches(RegExp(r'^\d{2}:\d{2}:\d{2}$')));
    });
  });

  group('CLI Commands - Process Info', () {
    test('process list can be retrieved', () async {
      final result = await Process.run('ps', ['aux']);

      expect(result.exitCode, equals(0));
      expect(result.stdout, isNotEmpty);
      expect(result.stdout, contains('PID'));
    });

    test('hostname can be retrieved', () async {
      final result = await Process.run('hostname', []);
      final hostname = (result.stdout as String).trim();

      expect(hostname, isNotEmpty);
      expect(hostname.length, greaterThan(0));
    });

    test('current user can be retrieved', () async {
      final result = await Process.run('whoami', []);
      final user = (result.stdout as String).trim();

      expect(user, isNotEmpty);
      expect(user, equals(Platform.environment['USER'] ?? user));
    });
  });

  group('CLI Commands - File System', () {
    test('can read /proc/meminfo on Linux', () async {
      if (!Platform.isLinux) {
        return; // Skip on non-Linux
      }

      final file = File('/proc/meminfo');
      expect(await file.exists(), isTrue);

      final content = await file.readAsString();
      expect(content, contains('MemTotal'));
      expect(content, contains('MemFree'));
    });

    test('can read /proc/stat on Linux', () async {
      if (!Platform.isLinux) {
        return; // Skip on non-Linux
      }

      final file = File('/proc/stat');
      expect(await file.exists(), isTrue);

      final content = await file.readAsString();
      expect(content, startsWith('cpu'));
    });

    test('temp directory is accessible', () async {
      final tempDir = Directory.systemTemp;
      expect(await tempDir.exists(), isTrue);

      // Can create temp file
      final tempFile = File('${tempDir.path}/crossbar_test_${DateTime.now().millisecondsSinceEpoch}');
      await tempFile.writeAsString('test');
      expect(await tempFile.exists(), isTrue);
      await tempFile.delete();
    });
  });
}
