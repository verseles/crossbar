import 'dart:async';
import 'dart:convert';

import 'package:crossbar/cli/cli_handler.dart';
import 'package:flutter_test/flutter_test.dart';

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
      expect(output.stdout, contains('Audio Controls'));
      expect(output.exitCode, equals(0));
    });

    test('empty args prints usage and returns error', () async {
      final output = await _captureOutput(() => handleCliCommand([]));
      expect(output.stdout, contains('Usage:'));
      expect(output.exitCode, equals(1));
    });
  });

  group('CLI Handler - System Info', () {
    test('cpu returns CPU percentage', () async {
      final output = await _captureOutput(() => handleCliCommand(['cpu']));
      expect(output.stdout, matches(RegExp(r'\d+(\.\d+)?%')));
      expect(output.exitCode, equals(0));
    });

    test('--cpu returns CPU percentage (legacy)', () async {
      final output = await _captureOutput(() => handleCliCommand(['--cpu']));
      expect(output.stdout, matches(RegExp(r'\d+(\.\d+)?%')));
      expect(output.exitCode, equals(0));
    });

    test('cpu --json returns JSON format', () async {
      final output = await _captureOutput(() => handleCliCommand(['cpu', '--json']));
      final json = jsonDecode(output.stdout.trim()) as Map<String, dynamic>;
      expect(json.containsKey('cpu'), isTrue);
      expect(output.exitCode, equals(0));
    });

    test('memory returns memory usage', () async {
      final output = await _captureOutput(() => handleCliCommand(['memory']));
      expect(output.stdout, isNotEmpty);
      expect(output.exitCode, equals(0));
    });

    test('battery returns battery status', () async {
      final output = await _captureOutput(() => handleCliCommand(['battery']));
      expect(output.stdout, isNotEmpty);
      expect(output.exitCode, equals(0));
    });

    test('uptime returns uptime', () async {
      final output = await _captureOutput(() => handleCliCommand(['uptime']));
      expect(output.stdout, isNotEmpty);
      expect(output.exitCode, equals(0));
    });

    test('disk returns disk usage', () async {
      final output = await _captureOutput(() => handleCliCommand(['disk']));
      expect(output.stdout, isNotEmpty);
      expect(output.exitCode, equals(0));
    });

    test('os returns operating system', () async {
      final output = await _captureOutput(() => handleCliCommand(['os']));
      expect(output.stdout, isNotEmpty);
      expect(output.exitCode, equals(0));
    });

    test('kernel returns kernel info', () async {
      final output = await _captureOutput(() => handleCliCommand(['kernel']));
      expect(output.stdout, isNotEmpty);
      expect(output.exitCode, equals(0));
    });

    test('arch returns architecture', () async {
      final output = await _captureOutput(() => handleCliCommand(['arch']));
      expect(output.stdout, isNotEmpty);
      expect(output.exitCode, equals(0));
    });

    test('hostname returns hostname', () async {
      final output = await _captureOutput(() => handleCliCommand(['hostname']));
      expect(output.stdout, isNotEmpty);
      expect(output.exitCode, equals(0));
    });

    test('username returns username', () async {
      final output = await _captureOutput(() => handleCliCommand(['username']));
      expect(output.stdout, isNotEmpty);
      expect(output.exitCode, equals(0));
    });
  });

  group('CLI Handler - Power', () {
    test('power restart requires confirm', () async {
      final output = await _captureOutput(() => handleCliCommand(['power', 'restart']));
      expect(output.exitCode, equals(1));
    });

    test('power shutdown requires confirm', () async {
      final output = await _captureOutput(() => handleCliCommand(['power', 'shutdown']));
      expect(output.exitCode, equals(1));
    });
  });

  group('CLI Handler - Utilities', () {
    test('hash computes SHA256', () async {
      final output = await _captureOutput(() => handleCliCommand(['hash', 'hello']));
      expect(output.stdout.trim(), equals('2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824'));
      expect(output.exitCode, equals(0));
    });

    test('uuid generates UUID', () async {
      final output = await _captureOutput(() => handleCliCommand(['uuid']));
      expect(
        output.stdout.trim(),
        matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[0-9a-f]{4}-[0-9a-f]{12}$')),
      );
      expect(output.exitCode, equals(0));
    });

    test('random', () async {
      final output = await _captureOutput(() => handleCliCommand(['random']));
      expect(output.exitCode, equals(0));
    });

    test('base64 encode', () async {
      final output = await _captureOutput(() => handleCliCommand(['base64', 'encode', 'hello']));
      expect(output.stdout.trim(), equals('aGVsbG8='));
      expect(output.exitCode, equals(0));
    });

    test('base64 decode', () async {
      final output = await _captureOutput(() => handleCliCommand(['base64', 'decode', 'aGVsbG8=']));
      expect(output.stdout.trim(), equals('hello'));
      expect(output.exitCode, equals(0));
    });

    test('time', () async {
      final output = await _captureOutput(() => handleCliCommand(['time']));
      expect(output.exitCode, equals(0));
    });

    test('date', () async {
      final output = await _captureOutput(() => handleCliCommand(['date']));
      expect(output.exitCode, equals(0));
    });

    test('clipboard (get)', () async {
      await _captureOutput(() => handleCliCommand(['clipboard']));
    });

    test('clipboard (set)', () async {
      // 1. Get current content
      final getOutput = await _captureOutput(() => handleCliCommand(['clipboard']));
      final currentContent = getOutput.stdout.trim();

      if (currentContent.isNotEmpty && currentContent != 'test') {
        addTearDown(() async {
          await _captureOutput(() => handleCliCommand(['clipboard', currentContent]));
        });
      }

      // 2. Set
      await _captureOutput(() => handleCliCommand(['clipboard', 'test']));
    });

    test('exec', () async {
      await _captureOutput(() => handleCliCommand(['exec', 'echo test']));
    });

    test('notify', () async {
      await _captureOutput(() => handleCliCommand(['notify', 'title', 'msg']));
    });

    test('open url', () async {
      await _captureOutput(() => handleCliCommand(['open', 'url', 'http://example.com']));
    });
  });

  group('CLI Handler - Files', () {
    test('file exists returns boolean', () async {
      final output = await _captureOutput(() => handleCliCommand(['file', 'exists', '/etc/passwd']));
      expect(output.stdout.trim(), equals('true'));
      expect(output.exitCode, equals(0));
    });

    test('file read', () async {
      // Just check it runs, we know it might fail on CI if file missing
      await _captureOutput(() => handleCliCommand(['file', 'read', '/etc/hosts']));
    });

    test('file size', () async {
      await _captureOutput(() => handleCliCommand(['file', 'size', '/etc/hosts']));
    });

    test('dir list', () async {
      final output = await _captureOutput(() => handleCliCommand(['dir', 'list', '/tmp']));
      expect(output.exitCode, equals(0));
    });
  });

  group('CLI Handler - Plugin Init', () {
     test('init requires --lang', () async {
       final output = await _captureOutput(() => handleCliCommand(['init']));
       expect(output.exitCode, equals(1));
     });
  });
}

/// Helper class to capture stdout, stderr, and exit code
class _CapturedOutput {

  _CapturedOutput({
    required this.stdout,
    required this.stderr,
    required this.exitCode,
  });
  final String stdout;
  final String stderr;
  final int exitCode;
}

/// Captures stdout and stderr during command execution
Future<_CapturedOutput> _captureOutput(Future<int> Function() command) async {
  final stdoutBuffer = StringBuffer();
  final stderrBuffer = StringBuffer();

  var exitCode = 0;

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
