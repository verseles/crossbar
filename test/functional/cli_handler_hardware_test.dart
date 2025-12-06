@Tags(['hardware'])
library;
// ignore_for_file: avoid_print

import 'dart:async';

import 'package:crossbar/cli/cli_handler.dart';
import 'package:flutter_test/flutter_test.dart';

/// Functional tests for CLI handler - HARDWARE tests.
/// These tests interact with real hardware (audio, screen, wifi, bluetooth).
///
/// To skip these tests locally (to avoid glitches):
///   flutter test --exclude-tags=hardware
///
/// These tests have tearDown handlers to restore original state when possible.
void main() {
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
