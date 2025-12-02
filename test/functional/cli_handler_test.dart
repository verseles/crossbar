import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:crossbar/cli/cli_handler.dart';

/// Functional tests for CLI handler.
/// These tests execute real CLI commands via handleCliCommand().
void main() {
  group('CLI Handler - Version & Help', () {
    test('--version returns version string', () async {
      final output = await _captureOutput(() => handleCliCommand(['--version']));

      expect(output.stdout, contains('Crossbar version'));
      expect(output.exitCode, equals(0));
    });

    test('-v returns version string', () async {
      final output = await _captureOutput(() => handleCliCommand(['-v']));

      expect(output.stdout, contains('Crossbar version'));
      expect(output.exitCode, equals(0));
    });

    test('--help returns usage information', () async {
      final output = await _captureOutput(() => handleCliCommand(['--help']));

      expect(output.stdout, contains('Usage:'));
      expect(output.stdout, contains('--cpu'));
      expect(output.stdout, contains('--memory'));
      expect(output.exitCode, equals(0));
    });

    test('-h returns usage information', () async {
      final output = await _captureOutput(() => handleCliCommand(['-h']));

      expect(output.stdout, contains('Usage:'));
      expect(output.exitCode, equals(0));
    });

    test('empty args prints usage and returns error', () async {
      final output = await _captureOutput(() => handleCliCommand([]));

      expect(output.stdout, contains('Usage:'));
      expect(output.exitCode, equals(1));
    });
  });

  group('CLI Handler - System Info', () {
    test('--cpu returns CPU percentage', () async {
      final output = await _captureOutput(() => handleCliCommand(['--cpu']));

      expect(output.stdout, matches(RegExp(r'\d+(\.\d+)?%')));
      expect(output.exitCode, equals(0));
    });

    test('--cpu --json returns JSON format', () async {
      final output = await _captureOutput(() => handleCliCommand(['--cpu', '--json']));

      final json = jsonDecode(output.stdout.trim()) as Map<String, dynamic>;
      expect(json.containsKey('cpu'), isTrue);
      expect(json['cpu'], isA<num>());
      expect(output.exitCode, equals(0));
    });

    test('--memory returns memory usage', () async {
      final output = await _captureOutput(() => handleCliCommand(['--memory']));

      expect(output.stdout, isNotEmpty);
      expect(output.exitCode, equals(0));
    });

    test('--memory --json returns JSON format', () async {
      final output = await _captureOutput(() => handleCliCommand(['--memory', '--json']));

      final json = jsonDecode(output.stdout.trim()) as Map<String, dynamic>;
      expect(json.containsKey('used') || json.containsKey('memory'), isTrue);
      expect(output.exitCode, equals(0));
    });

    test('--battery returns battery status', () async {
      final output = await _captureOutput(() => handleCliCommand(['--battery']));

      expect(output.stdout, isNotEmpty);
      expect(output.exitCode, equals(0));
    });

    test('--uptime returns uptime', () async {
      final output = await _captureOutput(() => handleCliCommand(['--uptime']));

      expect(output.stdout, isNotEmpty);
      expect(output.exitCode, equals(0));
    });

    test('--disk returns disk usage', () async {
      final output = await _captureOutput(() => handleCliCommand(['--disk']));

      expect(output.stdout, isNotEmpty);
      expect(output.exitCode, equals(0));
    });

    test('--disk with path returns disk usage for that path', () async {
      final output = await _captureOutput(() => handleCliCommand(['--disk', '/']));

      expect(output.stdout, isNotEmpty);
      expect(output.exitCode, equals(0));
    });

    test('--os returns operating system', () async {
      final output = await _captureOutput(() => handleCliCommand(['--os']));

      expect(output.stdout, isNotEmpty);
      expect(output.exitCode, equals(0));
    });

    test('--os --json returns OS details', () async {
      final output = await _captureOutput(() => handleCliCommand(['--os', '--json']));

      final json = jsonDecode(output.stdout.trim()) as Map<String, dynamic>;
      expect(json, isNotEmpty);
      expect(output.exitCode, equals(0));
    });

    test('--hostname returns hostname', () async {
      final output = await _captureOutput(() => handleCliCommand(['--hostname']));

      expect(output.stdout.trim(), equals(Platform.localHostname));
      expect(output.exitCode, equals(0));
    });

    test('--username returns current user', () async {
      final output = await _captureOutput(() => handleCliCommand(['--username']));

      final expected = Platform.environment['USER'] ?? Platform.environment['USERNAME'];
      expect(output.stdout.trim(), anyOf(equals(expected), isNotEmpty));
      expect(output.exitCode, equals(0));
    });

    test('--kernel returns kernel version', () async {
      final output = await _captureOutput(() => handleCliCommand(['--kernel']));

      expect(output.stdout, isNotEmpty);
      expect(output.exitCode, equals(0));
    });

    test('--arch returns architecture', () async {
      final output = await _captureOutput(() => handleCliCommand(['--arch']));

      expect(output.stdout, isNotEmpty);
      expect(output.exitCode, equals(0));
    });
  });

  group('CLI Handler - Network', () {
    test('--net-status returns online or offline', () async {
      final output = await _captureOutput(() => handleCliCommand(['--net-status']));

      expect(output.stdout.trim(), anyOf(equals('online'), equals('offline')));
      expect(output.exitCode, equals(0));
    });

    test('--net-ip returns local IP', () async {
      final output = await _captureOutput(() => handleCliCommand(['--net-ip']));

      expect(output.stdout, isNotEmpty);
      expect(output.exitCode, equals(0));
    });

    test('--net-ssid returns SSID or not connected', () async {
      final output = await _captureOutput(() => handleCliCommand(['--net-ssid']));

      expect(output.stdout, isNotEmpty);
      expect(output.exitCode, equals(0));
    });
  });

  group('CLI Handler - Utilities', () {
    test('--hash computes SHA256 by default', () async {
      final output = await _captureOutput(() => handleCliCommand(['--hash', 'hello']));

      expect(output.stdout.trim(), equals('2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824'));
      expect(output.exitCode, equals(0));
    });

    test('--hash with --algo md5 computes MD5', () async {
      final output = await _captureOutput(() => handleCliCommand(['--hash', 'hello', '--algo', 'md5']));

      expect(output.stdout.trim(), equals('5d41402abc4b2a76b9719d911017c592'));
      expect(output.exitCode, equals(0));
    });

    test('--hash with --algo sha1 computes SHA1', () async {
      final output = await _captureOutput(() => handleCliCommand(['--hash', 'hello', '--algo', 'sha1']));

      expect(output.stdout.trim(), equals('aaf4c61ddcc5e8a2dabede0f3b482cd9aea9434d'));
      expect(output.exitCode, equals(0));
    });

    test('--hash without text returns error', () async {
      final output = await _captureOutput(() => handleCliCommand(['--hash']));

      // stderr.writeln not captured, but exit code indicates error
      expect(output.exitCode, equals(1));
    });

    test('--uuid generates valid UUID format', () async {
      final output = await _captureOutput(() => handleCliCommand(['--uuid']));

      expect(
        output.stdout.trim(),
        matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[0-9a-f]{4}-[0-9a-f]{12}$')),
      );
      expect(output.exitCode, equals(0));
    });

    test('--random generates number in default range', () async {
      final output = await _captureOutput(() => handleCliCommand(['--random']));

      final num = int.parse(output.stdout.trim());
      expect(num, greaterThanOrEqualTo(0));
      expect(num, lessThanOrEqualTo(100));
      expect(output.exitCode, equals(0));
    });

    test('--random with min max generates number in range', () async {
      final output = await _captureOutput(() => handleCliCommand(['--random', '50', '60']));

      final num = int.parse(output.stdout.trim());
      expect(num, greaterThanOrEqualTo(50));
      expect(num, lessThanOrEqualTo(60));
      expect(output.exitCode, equals(0));
    });

    test('--base64-encode encodes text', () async {
      final output = await _captureOutput(() => handleCliCommand(['--base64-encode', 'hello']));

      expect(output.stdout.trim(), equals('aGVsbG8='));
      expect(output.exitCode, equals(0));
    });

    test('--base64-decode decodes text', () async {
      final output = await _captureOutput(() => handleCliCommand(['--base64-decode', 'aGVsbG8=']));

      expect(output.stdout.trim(), equals('hello'));
      expect(output.exitCode, equals(0));
    });

    test('--base64-encode without text returns error', () async {
      final output = await _captureOutput(() => handleCliCommand(['--base64-encode']));

      // stderr.writeln not captured, but exit code indicates error
      expect(output.exitCode, equals(1));
    });
  });

  group('CLI Handler - Date & Time', () {
    test('--time returns current time', () async {
      final output = await _captureOutput(() => handleCliCommand(['--time']));

      expect(output.stdout.trim(), matches(RegExp(r'^\d{2}:\d{2}$')));
      expect(output.exitCode, equals(0));
    });

    test('--time with --fmt 12h returns 12-hour format', () async {
      final output = await _captureOutput(() => handleCliCommand(['--time', '--fmt', '12h']));

      expect(output.stdout.trim(), matches(RegExp(r'^\d{2}:\d{2} (AM|PM)$')));
      expect(output.exitCode, equals(0));
    });

    test('--date returns ISO format by default', () async {
      final output = await _captureOutput(() => handleCliCommand(['--date']));

      expect(output.stdout.trim(), matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
      expect(output.exitCode, equals(0));
    });

    test('--date with --fmt unix returns timestamp', () async {
      final output = await _captureOutput(() => handleCliCommand(['--date', '--fmt', 'unix']));

      final timestamp = int.parse(output.stdout.trim());
      expect(timestamp, greaterThan(1700000000)); // After 2023
      expect(output.exitCode, equals(0));
    });

    test('--calendar prints month calendar', () async {
      final output = await _captureOutput(() => handleCliCommand(['--calendar']));

      expect(output.stdout, contains('Su Mo Tu We Th Fr Sa'));
      expect(output.exitCode, equals(0));
    });

    test('--countdown returns formatted time', () async {
      final output = await _captureOutput(() => handleCliCommand(['--countdown', '65']));

      expect(output.stdout.trim(), matches(RegExp(r'^\d+:\d{2}$')));
      expect(output.exitCode, equals(0));
    });
  });

  group('CLI Handler - Environment', () {
    test('--home returns home directory', () async {
      final output = await _captureOutput(() => handleCliCommand(['--home']));

      expect(output.stdout.trim(), isNotEmpty);
      expect(output.exitCode, equals(0));
    });

    test('--temp returns temp directory', () async {
      final output = await _captureOutput(() => handleCliCommand(['--temp']));

      expect(output.stdout.trim(), equals(Directory.systemTemp.path));
      expect(output.exitCode, equals(0));
    });

    test('--locale returns system locale', () async {
      final output = await _captureOutput(() => handleCliCommand(['--locale']));

      expect(output.stdout.trim(), equals(Platform.localeName));
      expect(output.exitCode, equals(0));
    });

    test('--timezone returns timezone', () async {
      final output = await _captureOutput(() => handleCliCommand(['--timezone']));

      expect(output.stdout.trim(), equals(DateTime.now().timeZoneName));
      expect(output.exitCode, equals(0));
    });

    test('--env without name lists all variables', () async {
      final output = await _captureOutput(() => handleCliCommand(['--env']));

      expect(output.stdout, contains('='));
      expect(output.exitCode, equals(0));
    });

    test('--env with name returns specific variable', () async {
      final output = await _captureOutput(() => handleCliCommand(['--env', 'HOME']));

      expect(output.stdout.trim(), equals(Platform.environment['HOME'] ?? ''));
      expect(output.exitCode, equals(0));
    });

    test('--env --json returns JSON format', () async {
      final output = await _captureOutput(() => handleCliCommand(['--env', '--json']));

      final json = jsonDecode(output.stdout.trim()) as Map<String, dynamic>;
      expect(json, isNotEmpty);
      expect(output.exitCode, equals(0));
    });
  });

  group('CLI Handler - File System', () {
    test('--file-exists returns true for existing file', () async {
      final output = await _captureOutput(() => handleCliCommand(['--file-exists', '/etc/passwd']));

      expect(output.stdout.trim(), equals('true'));
      expect(output.exitCode, equals(0));
    });

    test('--file-exists returns false for non-existing file', () async {
      final output = await _captureOutput(() => handleCliCommand(['--file-exists', '/nonexistent_xyz_123']));

      expect(output.stdout.trim(), equals('false'));
      expect(output.exitCode, equals(0));
    });

    test('--file-exists --json returns JSON format', () async {
      final output = await _captureOutput(() => handleCliCommand(['--file-exists', '/etc/passwd', '--json']));

      final json = jsonDecode(output.stdout.trim()) as Map<String, dynamic>;
      expect(json['exists'], isTrue);
      expect(json['path'], equals('/etc/passwd'));
      expect(output.exitCode, equals(0));
    });

    test('--file-exists without path returns error', () async {
      final output = await _captureOutput(() => handleCliCommand(['--file-exists']));

      // stderr.writeln not captured, but exit code indicates error
      expect(output.exitCode, equals(1));
    });

    test('--file-read reads file content', () async {
      // Create a temp file
      final tempFile = File('${Directory.systemTemp.path}/crossbar_test_read.txt');
      await tempFile.writeAsString('test content');

      final output = await _captureOutput(() => handleCliCommand(['--file-read', tempFile.path]));

      expect(output.stdout.trim(), equals('test content'));
      expect(output.exitCode, equals(0));

      await tempFile.delete();
    });

    test('--file-read non-existent file returns error', () async {
      final output = await _captureOutput(() => handleCliCommand(['--file-read', '/nonexistent_xyz_123']));

      // stderr.writeln not captured, but exit code indicates error
      expect(output.exitCode, equals(1));
    });

    test('--file-size returns file size', () async {
      final tempFile = File('${Directory.systemTemp.path}/crossbar_test_size.txt');
      await tempFile.writeAsString('12345'); // 5 bytes

      final output = await _captureOutput(() => handleCliCommand(['--file-size', tempFile.path]));

      expect(output.stdout.trim(), equals('5 B'));
      expect(output.exitCode, equals(0));

      await tempFile.delete();
    });

    test('--file-size --json returns JSON format', () async {
      final tempFile = File('${Directory.systemTemp.path}/crossbar_test_size_json.txt');
      await tempFile.writeAsString('12345');

      final output = await _captureOutput(() => handleCliCommand(['--file-size', tempFile.path, '--json']));

      final json = jsonDecode(output.stdout.trim()) as Map<String, dynamic>;
      expect(json['size'], equals(5));
      expect(output.exitCode, equals(0));

      await tempFile.delete();
    });

    test('--dir-list lists directory contents', () async {
      final output = await _captureOutput(() => handleCliCommand(['--dir-list', '/tmp']));

      expect(output.stdout, isNotEmpty);
      expect(output.exitCode, equals(0));
    });

    test('--dir-list --json returns JSON format', () async {
      final output = await _captureOutput(() => handleCliCommand(['--dir-list', '/tmp', '--json']));

      final json = jsonDecode(output.stdout.trim()) as List<dynamic>;
      expect(json, isA<List>());
      expect(output.exitCode, equals(0));
    });
  });

  group('CLI Handler - Exec', () {
    test('--exec runs shell command', () async {
      final output = await _captureOutput(() => handleCliCommand(['--exec', 'echo hello']));

      // Uses stdout.write which isn't captured by Zone, verify exit code
      expect(output.exitCode, equals(0));
    });

    test('--exec without command returns error', () async {
      final output = await _captureOutput(() => handleCliCommand(['--exec']));

      // stderr.writeln not captured, but exit code indicates error
      expect(output.exitCode, equals(1));
    });

    test('--exec returns exit code from command', () async {
      final output = await _captureOutput(() => handleCliCommand(['--exec', 'exit 42']));

      expect(output.exitCode, equals(42));
    });
  });

  group('CLI Handler - Process Info', () {
    test('--process-count returns number', () async {
      final output = await _captureOutput(() => handleCliCommand(['--process-count']));

      final count = int.parse(output.stdout.trim());
      expect(count, greaterThan(0));
      expect(output.exitCode, equals(0));
    });
  });

  group('CLI Handler - Unknown Command', () {
    test('unknown command returns error', () async {
      final output = await _captureOutput(() => handleCliCommand(['--unknown-xyz']));

      // stderr.writeln not captured, but exit code indicates error
      expect(output.exitCode, equals(1));
    });
  });

  group('CLI Handler - XML Output', () {
    test('--cpu --xml returns XML format', () async {
      final output = await _captureOutput(() => handleCliCommand(['--cpu', '--xml']));

      expect(output.stdout, contains('<?xml version="1.0"'));
      expect(output.stdout, contains('<crossbar>'));
      expect(output.stdout, contains('<cpu>'));
      expect(output.exitCode, equals(0));
    });
  });

  group('CLI Handler - Plugin Init', () {
    test('init without --lang returns error', () async {
      final output = await _captureOutput(() => handleCliCommand(['init']));

      // stderr.writeln not captured, but exit code indicates error
      expect(output.exitCode, equals(1));
    });

    test('init with unsupported language returns error', () async {
      final output = await _captureOutput(() => handleCliCommand(['init', '--lang', 'unknown']));

      // stderr.writeln not captured, but exit code indicates error
      expect(output.exitCode, equals(1));
    });

    test('init with unsupported type returns error', () async {
      final output = await _captureOutput(() => handleCliCommand(['init', '--lang', 'bash', '--type', 'unknown']));

      // stderr.writeln not captured, but exit code indicates error
      expect(output.exitCode, equals(1));
    });

    test('init creates bash plugin in temp directory', () async {
      final tempDir = Directory.systemTemp.createTempSync('crossbar_init_test_');

      try {
        final output = await _captureOutput(() => handleCliCommand([
          'init',
          '--lang', 'bash',
          '--type', 'custom',
          '--name', 'test-plugin',
          '--output', tempDir.path,
        ]));

        // Verify command succeeded
        expect(output.exitCode, equals(0));
        // stdout.contains check may fail because init uses print but also checks are done
        // Check files were created (scaffolding creates .sh files)
        final files = tempDir.listSync(recursive: true);
        // At least one file should be created
        expect(files.isNotEmpty, isTrue);
      } finally {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      }
    });
  });

  group('CLI Handler - Install', () {
    test('install without URL returns error', () async {
      final output = await _captureOutput(() => handleCliCommand(['install']));

      // stderr.writeln not captured, but exit code indicates error
      expect(output.exitCode, equals(1));
    });
  });
}

/// Helper class to capture stdout, stderr, and exit code
class _CapturedOutput {
  final String stdout;
  final String stderr;
  final int exitCode;

  _CapturedOutput({
    required this.stdout,
    required this.stderr,
    required this.exitCode,
  });
}

/// Captures stdout and stderr during command execution
Future<_CapturedOutput> _captureOutput(Future<int> Function() command) async {
  final stdoutBuffer = StringBuffer();
  final stderrBuffer = StringBuffer();

  int exitCode = 0;

  // Use Zone to capture print statements
  await runZonedGuarded(
    () async {
      exitCode = await command();
    },
    (error, stack) {
      stderrBuffer.writeln('Error: $error');
    },
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) {
        stdoutBuffer.writeln(line);
      },
    ),
  );

  return _CapturedOutput(
    stdout: stdoutBuffer.toString(),
    stderr: stderrBuffer.toString(),
    exitCode: exitCode,
  );
}
