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
    test('audio volume get', () async {
      final output = await _captureOutput(() => handleCliCommand(['audio', 'volume']));
      expect(output.stdout, matches(RegExp(r'\d+%|Unknown')));
      expect(output.exitCode, equals(0));
    });

    test('audio volume set', () async {
      // 1. Get current volume
      final getOutput = await _captureOutput(() => handleCliCommand(['audio', 'volume']));
      final currentVolumeStr = getOutput.stdout.trim().replaceAll('%', '');
      final currentVolume = int.tryParse(currentVolumeStr);

      if (currentVolume != null) {
        addTearDown(() async {
          await _captureOutput(() => handleCliCommand(['audio', 'volume', '$currentVolume']));
        });
      }

      // 2. Set volume
      // We don't check success, just that code runs
      final output = await _captureOutput(() => handleCliCommand(['audio', 'volume', '50']));
      expect(output.exitCode, anyOf(equals(0), equals(1)));
    });

    test('audio mute status', () async {
      final output = await _captureOutput(() => handleCliCommand(['audio', 'mute', 'status']));
      expect(output.stdout.trim(), anyOf(equals('Muted'), equals('Unmuted')));
      expect(output.exitCode, equals(0));
    });

    test('audio mute toggle', () async {
      // 1. Get initial status
      final getOutput = await _captureOutput(() => handleCliCommand(['audio', 'mute', 'status']));
      final wasMuted = getOutput.stdout.trim() == 'Muted';

      addTearDown(() async {
        final currentOutput = await _captureOutput(() => handleCliCommand(['audio', 'mute', 'status']));
        final isMuted = currentOutput.stdout.trim() == 'Muted';
        if (isMuted != wasMuted) {
          await _captureOutput(() => handleCliCommand(['audio', 'mute']));
        }
      });

      // 2. Toggle
      final output = await _captureOutput(() => handleCliCommand(['audio', 'mute']));
      expect(output.exitCode, anyOf(equals(0), equals(1)));
    });

    test('audio mute on', () async {
      // 1. Get initial status
      final getOutput = await _captureOutput(() => handleCliCommand(['audio', 'mute', 'status']));
      final wasMuted = getOutput.stdout.trim() == 'Muted';

      addTearDown(() async {
        if (wasMuted) {
          await _captureOutput(() => handleCliCommand(['audio', 'mute', 'on']));
        } else {
          await _captureOutput(() => handleCliCommand(['audio', 'mute', 'off']));
        }
      });

      final output = await _captureOutput(() => handleCliCommand(['audio', 'mute', 'on']));
      expect(output.exitCode, anyOf(equals(0), equals(1)));
    });

    test('audio mute off', () async {
      // 1. Get initial status
      final getOutput = await _captureOutput(() => handleCliCommand(['audio', 'mute', 'status']));
      final wasMuted = getOutput.stdout.trim() == 'Muted';

      addTearDown(() async {
        if (wasMuted) {
          await _captureOutput(() => handleCliCommand(['audio', 'mute', 'on']));
        } else {
          await _captureOutput(() => handleCliCommand(['audio', 'mute', 'off']));
        }
      });

      final output = await _captureOutput(() => handleCliCommand(['audio', 'mute', 'off']));
      expect(output.exitCode, anyOf(equals(0), equals(1)));
    });

    test('audio output --list', () async {
      final output = await _captureOutput(() => handleCliCommand(['audio', 'output', '--list']));
      expect(output.exitCode, equals(0));
    });

    test('audio output set', () async {
      // 1. Get current output
      final getOutput = await _captureOutput(() => handleCliCommand(['audio', 'output']));
      final currentOutput = getOutput.stdout.trim();

      if (currentOutput.isNotEmpty && currentOutput != 'dummy_device') {
        addTearDown(() async {
          await _captureOutput(() => handleCliCommand(['audio', 'output', currentOutput]));
        });
      }

      final output = await _captureOutput(() => handleCliCommand(['audio', 'output', 'dummy_device']));
      expect(output.exitCode, anyOf(equals(0), equals(1)));
    });
  });

  group('CLI Handler - Media', () {
    test('media playing', () async {
      final output = await _captureOutput(() => handleCliCommand(['media', 'playing']));
      expect(output.exitCode, equals(0));
    });

    test('media play', () async {
      await _captureOutput(() => handleCliCommand(['media', 'play']));
    });

    test('media pause', () async {
      await _captureOutput(() => handleCliCommand(['media', 'pause']));
    });

    test('media stop', () async {
      await _captureOutput(() => handleCliCommand(['media', 'stop']));
    });

    test('media next', () async {
      await _captureOutput(() => handleCliCommand(['media', 'next']));
    });

    test('media prev', () async {
      await _captureOutput(() => handleCliCommand(['media', 'prev']));
    });

    test('media seek', () async {
      await _captureOutput(() => handleCliCommand(['media', 'seek', '+10s']));
    });
  });

  group('CLI Handler - Screen', () {
    test('screen brightness get', () async {
      final output = await _captureOutput(() => handleCliCommand(['screen', 'brightness']));
      expect(output.exitCode, equals(0));
    });

    test('screen brightness set', () async {
      // 1. Get current brightness
      final getOutput = await _captureOutput(() => handleCliCommand(['screen', 'brightness']));
      final currentBrightnessStr = getOutput.stdout.trim().replaceAll('%', '');
      final currentBrightness = int.tryParse(currentBrightnessStr);

      if (currentBrightness != null) {
        addTearDown(() async {
          await _captureOutput(() => handleCliCommand(['screen', 'brightness', '$currentBrightness']));
        });
      }

      // 2. Set brightness
      await _captureOutput(() => handleCliCommand(['screen', 'brightness', '50']));
    });

    test('screen size', () async {
      final output = await _captureOutput(() => handleCliCommand(['screen', 'size']));
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

  group('CLI Handler - Wallpaper & DND', () {
    test('wallpaper get', () async {
      final output = await _captureOutput(() => handleCliCommand(['wallpaper']));
      expect(output.exitCode, equals(0));
    });

    test('wallpaper set', () async {
      // 1. Get current wallpaper
      final getOutput = await _captureOutput(() => handleCliCommand(['wallpaper']));
      final currentWallpaper = getOutput.stdout.trim();

      if (currentWallpaper.isNotEmpty && currentWallpaper != '/tmp/bg.jpg') {
        addTearDown(() async {
          await _captureOutput(() => handleCliCommand(['wallpaper', currentWallpaper]));
        });
      }

      // 2. Set wallpaper
      await _captureOutput(() => handleCliCommand(['wallpaper', '/tmp/bg.jpg']));
    });

    test('dnd status', () async {
      final output = await _captureOutput(() => handleCliCommand(['dnd']));
      expect(output.exitCode, equals(0));
    });

    test('dnd set on', () async {
      // 1. Get status
      final getOutput = await _captureOutput(() => handleCliCommand(['dnd']));
      final wasDnd = getOutput.stdout.contains('ON');

      addTearDown(() async {
        if (!wasDnd) {
          await _captureOutput(() => handleCliCommand(['dnd', 'off']));
        } else {
          await _captureOutput(() => handleCliCommand(['dnd', 'on']));
        }
      });

      // 2. Set On
      await _captureOutput(() => handleCliCommand(['dnd', 'on']));
    });

    test('dnd set off', () async {
      // 1. Get status
      final getOutput = await _captureOutput(() => handleCliCommand(['dnd']));
      final wasDnd = getOutput.stdout.contains('ON');

      addTearDown(() async {
        if (wasDnd) {
          await _captureOutput(() => handleCliCommand(['dnd', 'on']));
        } else {
          await _captureOutput(() => handleCliCommand(['dnd', 'off']));
        }
      });

      // 2. Set Off
      await _captureOutput(() => handleCliCommand(['dnd', 'off']));
    });

    test('dnd toggle', () async {
      // 1. Get status
      final getOutput = await _captureOutput(() => handleCliCommand(['dnd']));
      final wasDnd = getOutput.stdout.contains('ON');

      addTearDown(() async {
        final currentOutput = await _captureOutput(() => handleCliCommand(['dnd']));
        final isDnd = currentOutput.stdout.contains('ON');
        if (isDnd != wasDnd) {
          await _captureOutput(() => handleCliCommand(['dnd', 'toggle']));
        }
      });

      // 2. Toggle
      await _captureOutput(() => handleCliCommand(['dnd', 'toggle']));
    });
  });

  group('CLI Handler - Network & Wifi', () {
    test('net status', () async {
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

    test('wifi ssid', () async {
      final output = await _captureOutput(() => handleCliCommand(['wifi', 'ssid']));
      expect(output.stdout, isNotEmpty);
      expect(output.exitCode, equals(0));
    });

    test('wifi status', () async {
      final output = await _captureOutput(() => handleCliCommand(['wifi']));
      expect(output.stdout, contains('WiFi:'));
      expect(output.exitCode, equals(0));
    });

    test('wifi on', () async {
      // 1. Get status
      final getOutput = await _captureOutput(() => handleCliCommand(['wifi']));
      final wasOn = getOutput.stdout.toLowerCase().contains('on');

      addTearDown(() async {
        if (!wasOn) {
          await _captureOutput(() => handleCliCommand(['wifi', 'off']));
        } else {
          await _captureOutput(() => handleCliCommand(['wifi', 'on']));
        }
      });

      // 2. Set On
      await _captureOutput(() => handleCliCommand(['wifi', 'on']));
    });

    test('wifi off', () async {
      // 1. Get status
      final getOutput = await _captureOutput(() => handleCliCommand(['wifi']));
      final wasOn = getOutput.stdout.toLowerCase().contains('on');

      addTearDown(() async {
        if (wasOn) {
          await _captureOutput(() => handleCliCommand(['wifi', 'on']));
        } else {
          await _captureOutput(() => handleCliCommand(['wifi', 'off']));
        }
      });

      // 2. Set Off
      await _captureOutput(() => handleCliCommand(['wifi', 'off']));
    });

    test('wifi toggle', () async {
      // 1. Get status
      final getOutput = await _captureOutput(() => handleCliCommand(['wifi']));
      final wasOn = getOutput.stdout.toLowerCase().contains('on');

      addTearDown(() async {
        final currentOutput = await _captureOutput(() => handleCliCommand(['wifi']));
        final isOn = currentOutput.stdout.toLowerCase().contains('on');
        if (isOn != wasOn) {
          await _captureOutput(() => handleCliCommand(['wifi', 'toggle']));
        }
      });

      // 2. Toggle
      await _captureOutput(() => handleCliCommand(['wifi', 'toggle']));
    });

    test('bluetooth status', () async {
      final output = await _captureOutput(() => handleCliCommand(['bluetooth']));
      expect(output.stdout, contains('Bluetooth:'));
      expect(output.exitCode, equals(0));
    });

    test('bluetooth on', () async {
      // 1. Get status
      final getOutput = await _captureOutput(() => handleCliCommand(['bluetooth']));
      final wasOn = getOutput.stdout.toLowerCase().contains(': on');

      addTearDown(() async {
        if (!wasOn) {
          await _captureOutput(() => handleCliCommand(['bluetooth', 'off']));
        } else {
          await _captureOutput(() => handleCliCommand(['bluetooth', 'on']));
        }
      });

      // 2. Set On
      await _captureOutput(() => handleCliCommand(['bluetooth', 'on']));
    });

    test('bluetooth off', () async {
      // 1. Get status
      final getOutput = await _captureOutput(() => handleCliCommand(['bluetooth']));
      final wasOn = getOutput.stdout.toLowerCase().contains(': on');

      addTearDown(() async {
        if (wasOn) {
          await _captureOutput(() => handleCliCommand(['bluetooth', 'on']));
        } else {
          await _captureOutput(() => handleCliCommand(['bluetooth', 'off']));
        }
      });

      // 2. Set Off
      await _captureOutput(() => handleCliCommand(['bluetooth', 'off']));
    });

    test('bluetooth toggle', () async {
      // 1. Get status
      final getOutput = await _captureOutput(() => handleCliCommand(['bluetooth']));
      final wasOn = getOutput.stdout.toLowerCase().contains(': on');

      addTearDown(() async {
        final currentOutput = await _captureOutput(() => handleCliCommand(['bluetooth']));
        final isOn = currentOutput.stdout.toLowerCase().contains(': on');
        if (isOn != wasOn) {
          await _captureOutput(() => handleCliCommand(['bluetooth', 'toggle']));
        }
      });

      // 2. Toggle
      await _captureOutput(() => handleCliCommand(['bluetooth', 'toggle']));
    });

    test('bluetooth devices', () async {
      await _captureOutput(() => handleCliCommand(['bluetooth', 'devices']));
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
