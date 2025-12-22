// ignore_for_file: avoid_slow_async_io
import 'package:crossbar/core/plugin_executor.dart';
import 'package:crossbar_core/crossbar_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PluginExecutor', () {
    late PluginExecutor executor;

    setUp(() {
      executor = PluginExecutor();
    });

    group('Singleton', () {
      test('factory returns same instance', () {
        final a = PluginExecutor();
        final b = PluginExecutor();
        expect(identical(a, b), isTrue);
      });
    });

    group('getRunnerType', () {
      test('returns declarative for YAML files', () {
        expect(executor.getRunnerType('/path/plugin.yaml'), RunnerType.declarative);
        expect(executor.getRunnerType('/path/plugin.yml'), RunnerType.declarative);
        expect(executor.getRunnerType('/path/plugin.10s.yaml'), RunnerType.declarative);
      });

      test('returns lua for Lua files', () {
        expect(executor.getRunnerType('/path/plugin.lua'), RunnerType.lua);
        expect(executor.getRunnerType('/path/plugin.1s.lua'), RunnerType.lua);
      });

      test('returns script for shell files', () {
        expect(executor.getRunnerType('/path/plugin.sh'), RunnerType.script);
        expect(executor.getRunnerType('/path/plugin.bash'), RunnerType.script);
        expect(executor.getRunnerType('/path/plugin.zsh'), RunnerType.script);
      });

      test('returns script for Python files', () {
        expect(executor.getRunnerType('/path/plugin.py'), RunnerType.script);
        expect(executor.getRunnerType('/path/plugin.python'), RunnerType.script);
      });

      test('returns script for JavaScript files', () {
        expect(executor.getRunnerType('/path/plugin.js'), RunnerType.script);
      });

      test('returns script for Go files', () {
        expect(executor.getRunnerType('/path/plugin.go'), RunnerType.script);
      });

      test('returns script for Rust files', () {
        expect(executor.getRunnerType('/path/plugin.rs'), RunnerType.script);
      });

      test('returns script for Dart files', () {
        // Dart runs via dart run, not interpretation
        expect(executor.getRunnerType('/path/plugin.dart'), RunnerType.script);
      });

      test('returns script for compiled Dart executables', () {
        expect(executor.getRunnerType('/path/plugin.dart.exe'), RunnerType.script);
      });

      test('returns unknown for unsupported extensions', () {
        expect(executor.getRunnerType('/path/plugin.xyz'), RunnerType.unknown);
        expect(executor.getRunnerType('/path/plugin.txt'), RunnerType.unknown);
        expect(executor.getRunnerType('/path/plugin.json'), RunnerType.unknown);
      });

      test('handles special interval format correctly', () {
        // e.g., plugin.1s.lua should still be recognized as lua
        expect(executor.getRunnerType('/path/cpu.10s.lua'), RunnerType.lua);
        expect(executor.getRunnerType('/path/memory.5m.yaml'), RunnerType.declarative);
        expect(executor.getRunnerType('/path/clock.1s.sh'), RunnerType.script);
      });

      test('extension detection is case insensitive', () {
        expect(executor.getRunnerType('/path/plugin.LUA'), RunnerType.lua);
        expect(executor.getRunnerType('/path/plugin.YAML'), RunnerType.declarative);
        expect(executor.getRunnerType('/path/plugin.SH'), RunnerType.script);
      });
    });

    group('canRunOnPlatform', () {
      test('declarative can run on any platform', () {
        expect(executor.canRunOnPlatform('/path/plugin.yaml'), isTrue);
        expect(executor.canRunOnPlatform('/path/plugin.yml'), isTrue);
      });

      test('lua can run on any platform', () {
        expect(executor.canRunOnPlatform('/path/plugin.lua'), isTrue);
      });

      test('scripts can run on desktop', () {
        // On Linux test environment, this should be true
        expect(executor.canRunOnPlatform('/path/plugin.sh'), isTrue);
        expect(executor.canRunOnPlatform('/path/plugin.py'), isTrue);
      });

      test('unknown extensions cannot run', () {
        expect(executor.canRunOnPlatform('/path/plugin.unknown'), isFalse);
      });
    });

    group('supportedExtensions', () {
      test('contains common extensions', () {
        final exts = executor.supportedExtensions;

        expect(exts, contains('lua'));
        expect(exts, contains('yaml'));
        expect(exts, contains('yml'));
        expect(exts, contains('sh'));
        expect(exts, contains('py'));
        expect(exts, contains('js'));
        expect(exts, contains('go'));
        expect(exts, contains('rs'));
        expect(exts, contains('dart'));
      });

      test('supportedExtensions is not empty', () {
        expect(executor.supportedExtensions, isNotEmpty);
      });
    });

    group('run (integration)', () {
      test('returns error for unknown plugin type', () async {
        const plugin = Plugin(
          id: 'unknown.xyz',
          path: '/nonexistent/plugin.xyz',
          interpreter: 'unknown',
          refreshInterval: Duration(seconds: 10),
        );

        final output = await executor.run(plugin);
        expect(output.hasError, isTrue);
        expect(output.errorMessage, contains('Unknown plugin type'));
      });

      test('returns error for nonexistent lua plugin', () async {
        const plugin = Plugin(
          id: 'nonexistent.lua',
          path: '/definitely/not/a/real/path.lua',
          interpreter: 'lua',
          refreshInterval: Duration(seconds: 10),
        );

        final output = await executor.run(plugin);
        // Either error for file not found, or error from lua runner
        expect(
          output.hasError || (output.text?.contains('error') ?? false),
          isTrue,
          reason: 'Expected error for nonexistent file',
        );
      });
    });

    group('RunnerType enum', () {
      test('all runner types are defined', () {
        expect(RunnerType.values.length, equals(5));
        expect(RunnerType.declarative, isNotNull);
        expect(RunnerType.dart, isNotNull);
        expect(RunnerType.lua, isNotNull);
        expect(RunnerType.script, isNotNull);
        expect(RunnerType.unknown, isNotNull);
      });
    });
  });
}
