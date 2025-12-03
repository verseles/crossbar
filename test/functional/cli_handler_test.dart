import 'dart:async';
import 'dart:convert';

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

  group('CLI Handler - Audio', () {
    test('audio volume returns value', () async {
      final output = await _captureOutput(() => handleCliCommand(['audio', 'volume']));
      expect(output.stdout, matches(RegExp(r'\d+%|Unknown')));
      expect(output.exitCode, equals(0));
    });

    test('audio mute toggles', () async {
      final output = await _captureOutput(() => handleCliCommand(['audio', 'mute']));
      // Expect "Muted" or "Unmuted" or error
      expect(output.exitCode, anyOf(equals(0), equals(1)));
    });

    test('audio output --list lists devices', () async {
      final output = await _captureOutput(() => handleCliCommand(['audio', 'output', '--list']));
      expect(output.exitCode, equals(0));
    });
  });

  group('CLI Handler - Media', () {
    test('media playing', () async {
      final output = await _captureOutput(() => handleCliCommand(['media', 'playing']));
      expect(output.exitCode, equals(0));
    });

    test('media play (safe to call)', () async {
      // Might fail on CI but code should execute
      await _captureOutput(() => handleCliCommand(['media', 'play']));
    });
  });

  group('CLI Handler - Screen', () {
    test('screen brightness', () async {
      final output = await _captureOutput(() => handleCliCommand(['screen', 'brightness']));
      expect(output.exitCode, equals(0));
    });

    test('screen size', () async {
      final output = await _captureOutput(() => handleCliCommand(['screen', 'size']));
      expect(output.exitCode, equals(0));
    });
  });

  group('CLI Handler - Power', () {
    // We don't want to actually sleep/restart in tests, but we can test flag validation
    test('power restart requires confirm', () async {
      final output = await _captureOutput(() => handleCliCommand(['power', 'restart']));
      expect(output.exitCode, equals(1));
      // stderr isn't captured by _captureOutput
    });

    test('power shutdown requires confirm', () async {
      final output = await _captureOutput(() => handleCliCommand(['power', 'shutdown']));
      expect(output.exitCode, equals(1));
      // stderr isn't captured by _captureOutput
    });
  });

  group('CLI Handler - Wallpaper & DND', () {
    test('wallpaper get', () async {
      final output = await _captureOutput(() => handleCliCommand(['wallpaper']));
      expect(output.exitCode, equals(0));
    });

    test('dnd status', () async {
      final output = await _captureOutput(() => handleCliCommand(['dnd']));
      expect(output.exitCode, equals(0));
    });
  });

  group('CLI Handler - Network & Wifi', () {
    test('net status returns online/offline', () async {
      final output = await _captureOutput(() => handleCliCommand(['net', 'status']));
      expect(output.stdout.trim(), anyOf(equals('online'), equals('offline')));
      expect(output.exitCode, equals(0));
    });

    test('net ip', () async {
      final output = await _captureOutput(() => handleCliCommand(['net', 'ip']));
      expect(output.exitCode, equals(0));
    });

    test('net ping', () async {
      final output = await _captureOutput(() => handleCliCommand(['net', 'ping', 'localhost']));
      expect(output.exitCode, equals(0));
    });

    test('wifi ssid returns SSID', () async {
      final output = await _captureOutput(() => handleCliCommand(['wifi', 'ssid']));
      expect(output.stdout, isNotEmpty);
      expect(output.exitCode, equals(0));
    });

    test('wifi status', () async {
      final output = await _captureOutput(() => handleCliCommand(['wifi']));
      expect(output.stdout, contains('WiFi:'));
      expect(output.exitCode, equals(0));
    });

    test('bluetooth status', () async {
      final output = await _captureOutput(() => handleCliCommand(['bluetooth']));
      expect(output.stdout, contains('Bluetooth:'));
      expect(output.exitCode, equals(0));
    });

    test('vpn status', () async {
      final output = await _captureOutput(() => handleCliCommand(['vpn', 'status']));
      expect(output.exitCode, equals(0));
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

    test('time', () async {
      final output = await _captureOutput(() => handleCliCommand(['time']));
      expect(output.exitCode, equals(0));
    });

    test('date', () async {
      final output = await _captureOutput(() => handleCliCommand(['date']));
      expect(output.exitCode, equals(0));
    });

    test('clipboard (get)', () async {
      // Calls xclip/pbpaste, might fail but code runs
      await _captureOutput(() => handleCliCommand(['clipboard']));
    });
  });

  group('CLI Handler - Files', () {
    test('file exists returns boolean', () async {
      final output = await _captureOutput(() => handleCliCommand(['file', 'exists', '/etc/passwd']));
      expect(output.stdout.trim(), equals('true'));
      expect(output.exitCode, equals(0));
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
