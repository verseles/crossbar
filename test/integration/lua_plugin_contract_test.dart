@Tags(['hardware'])
library;

import 'dart:io';

import 'package:crossbar/core/runners/lua_runner.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contract tests for Lua sample plugins.
/// These tests validate that each plugin produces output conforming to expected schema.
void main() {
  group('Lua Plugin - Contract Tests', () {
    late LuaRunner runner;
    late String pluginsDir;

    setUp(() {
      runner = LuaRunner();
      pluginsDir = '${Directory.current.path}/plugins';
    });

    group('clock.1s.lua', () {
      test('produces output with clock icon and time', () async {
        final result = await runner.run('$pluginsDir/clock/clock.1s.lua');

        expect(result.success, isTrue, reason: 'Script should execute successfully');
        expect(result.error, isNull, reason: 'Should have no errors');
        expect(result.output, isNotEmpty, reason: 'Should produce output');

        // Should start with clock emoji
        expect(result.output, startsWith('🕐'), reason: 'Should have clock icon');

        // Should contain time in HH:MM:SS format
        expect(
          result.output,
          matches(RegExp(r'\d{2}:\d{2}:\d{2}')),
          reason: 'Should contain time in HH:MM:SS format',
        );
      });
    });

    group('time.1s.lua', () {
      test('produces output with a time emoji and formatted time', () async {
        final result = await runner.run('$pluginsDir/time.1s.lua');

        expect(result.success, isTrue, reason: 'Script should execute successfully');
        expect(result.error, isNull, reason: 'Should have no errors: ${result.error}');
        expect(result.output, isNotEmpty, reason: 'Should produce output');

        // Should contain a time-related emoji
        expect(
          result.output,
          matches(RegExp(r'[☀️🏙️🌆🌙]')),
          reason: 'Should start with a time-of-day emoji',
        );

        // Should contain time in HH:MM:SS format
        expect(
          result.output,
          matches(RegExp(r'\d{2}:\d{2}:\d{2}')),
          reason: 'Should contain time in HH:MM:SS format',
        );

        // Should have a menu
        expect(result.output, contains('---'), reason: 'Should have a menu separator');
        expect(result.output, contains('Time:'), reason: 'Should contain "Time:" in the menu');
      });
    });

    group('cpu.10s.lua', () {
      test('produces output with CPU icon and percentage', () async {
        final result = await runner.run('$pluginsDir/cpu/cpu.10s.lua');

        expect(result.success, isTrue, reason: 'Script should execute successfully');
        expect(result.error, isNull, reason: 'Should have no errors: ${result.error}');
        expect(result.output, isNotEmpty, reason: 'Should produce output');

        // Should start with laptop emoji
        expect(result.output, startsWith('💻'), reason: 'Should have CPU icon');

        // Should contain percentage
        expect(
          result.output,
          matches(RegExp(r'\d+%')),
          reason: 'Should contain percentage value',
        );

        // Should have color indicator (BitBar format)
        expect(
          result.output,
          contains('color='),
          reason: 'Should have color indicator',
        );
      });

      test('has platform info in menu', () async {
        final result = await runner.run('$pluginsDir/cpu/cpu.10s.lua');

        expect(result.success, isTrue);
        expect(result.output, contains('Platform:'), reason: 'Should show platform info');
        expect(result.output, contains('---'), reason: 'Should have menu separator');
      });
    });

    group('memory.10s.lua', () {
      test('produces output with memory icon and percentage', () async {
        final result = await runner.run('$pluginsDir/memory/memory.10s.lua');

        expect(result.success, isTrue, reason: 'Script should execute successfully');
        expect(result.error, isNull, reason: 'Should have no errors: ${result.error}');
        expect(result.output, isNotEmpty, reason: 'Should produce output');

        // Should start with brain emoji
        expect(result.output, startsWith('🧠'), reason: 'Should have memory icon');

        // Check it's not showing the error fallback
        if (result.output.contains('??')) {
          // Plugin returned fallback - memory data unavailable
          expect(result.output, contains('Memory data unavailable'));
        } else {
          // Normal output - should have percentage and color
          expect(
            result.output,
            matches(RegExp(r'\d+')),
            reason: 'Should contain numeric value',
          );
          expect(result.output, contains('color='), reason: 'Should have color indicator');
          expect(result.output, contains('Used:'), reason: 'Should show used memory');
          expect(result.output, contains('Total:'), reason: 'Should show total memory');
        }
      });
    });

    group('battery.1m.lua', () {
      test(
        'produces output with battery icon',
        () async {
          final batteryPluginPath = '$pluginsDir/battery/battery.1m.lua';
          if (!File(batteryPluginPath).existsSync()) {
            // Skip if file doesn't exist
            return;
          }

          final result = await runner.run(batteryPluginPath);

          expect(result.success, isTrue, reason: 'Script should execute successfully');
          expect(result.error, isNull, reason: 'Should have no errors: ${result.error}');
          expect(result.output, isNotEmpty, reason: 'Should produce output');

          // Should start with battery emoji
          expect(
            result.output,
            anyOf(
              startsWith('🔋'),
              startsWith('🪫'),
              startsWith('⚡'),
              contains('N/A'),
            ),
            reason: 'Should have battery icon or N/A indicator',
          );
        },
        skip: 'Requires hardware access (battery) which is unavailable in CI.',
      );
    });

    group('Output Format Validation', () {
      // Exclude plugins that require external dependencies (network, specific binaries)
      // or hardware access from the generic contract tests.
      // They should be tested individually with mocked dependencies if possible.
      final excludedPlugins = [
        'github-notifications.5m.lua',
        'weather.30m.lua',
        'spotify.5s.lua',
        'battery.1m.lua',
        'network.30s.lua',
        'ssh-connections.30s.lua',
        'docker-status.1m.lua',
        'time.1s.lua',
        'countdown.1s.lua',
        'pomodoro.1s.lua',
      ];

      test('all Lua plugins produce non-empty output', () async {
        final luaPlugins = Directory(pluginsDir)
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.lua') && !excludedPlugins.any((name) => f.path.endsWith(name)))
            .toList();

        expect(luaPlugins, isNotEmpty, reason: 'Should have Lua plugins');

        for (final plugin in luaPlugins) {
          final result = await runner.run(plugin.path);

          expect(
            result.success,
            isTrue,
            reason: '${plugin.path} should execute successfully: ${result.error}',
          );
          expect(
            result.output,
            isNotEmpty,
            reason: '${plugin.path} should produce output',
          );
        }
      });

      test('all Lua plugins have valid BitBar format', () async {
        final luaPlugins = Directory(pluginsDir)
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.lua') && !excludedPlugins.any((name) => f.path.endsWith(name)))
            .toList();

        for (final plugin in luaPlugins) {
          final result = await runner.run(plugin.path);

          if (result.success) {
            // First line should be the main display
            final lines = result.output.trim().split('\n');
            expect(
              lines.first,
              isNotEmpty,
              reason: '${plugin.path} should have non-empty first line',
            );

            // First line should not start with error
            expect(
              lines.first.toLowerCase(),
              isNot(startsWith('error')),
              reason: '${plugin.path} first line should not be an error',
            );
          }
        }
      });
    });
  });
}
