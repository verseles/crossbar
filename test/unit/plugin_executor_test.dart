// ignore_for_file: avoid_slow_async_io
import 'package:crossbar/core/plugin_executor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final executor = PluginExecutor();

  group('PluginExecutor - Runner Type Detection', () {
    test('detects YAML plugins', () {
      expect(executor.getRunnerType('weather.30m.yaml'), RunnerType.declarative);
      expect(executor.getRunnerType('clock.1s.yml'), RunnerType.declarative);
      expect(executor.getRunnerType('/path/to/plugin.yaml'), RunnerType.declarative);
    });

    test('detects Dart plugins as script (runs via dart run)', () {
      expect(executor.getRunnerType('clock.1s.dart'), RunnerType.script);
      expect(executor.getRunnerType('/path/to/plugin.dart'), RunnerType.script);
    });

    test('detects compiled Dart as script', () {
      expect(executor.getRunnerType('plugin.dart.exe'), RunnerType.script);
    });

    test('detects Bash plugins', () {
      expect(executor.getRunnerType('cpu.5s.sh'), RunnerType.script);
      expect(executor.getRunnerType('plugin.bash'), RunnerType.script);
      expect(executor.getRunnerType('plugin.zsh'), RunnerType.script);
    });

    test('detects Python plugins', () {
      expect(executor.getRunnerType('weather.30m.py'), RunnerType.script);
      expect(executor.getRunnerType('plugin.python'), RunnerType.script);
    });

    test('detects Node.js plugins', () {
      // .js files return script if Node is available, javascript otherwise
      final result = executor.getRunnerType('bitcoin.5m.js');
      expect(result, anyOf(RunnerType.script, RunnerType.javascript));
    });

    test('detects Go plugins', () {
      expect(executor.getRunnerType('memory.10s.go'), RunnerType.script);
    });

    test('detects Rust plugins', () {
      expect(executor.getRunnerType('uptime.1h.rs'), RunnerType.script);
    });

    test('detects Lua plugins', () {
      expect(executor.getRunnerType('clock.1s.lua'), RunnerType.lua);
      expect(executor.getRunnerType('/path/to/plugin.lua'), RunnerType.lua);
    });

    test('unknown extensions return unknown', () {
      expect(executor.getRunnerType('file.txt'), RunnerType.unknown);
      expect(executor.getRunnerType('file.exe'), RunnerType.unknown);
      expect(executor.getRunnerType('noextension'), RunnerType.unknown);
    });
  });

  group('PluginExecutor - Platform Compatibility', () {
    test('declarative plugins run everywhere', () {
      expect(executor.canRunOnPlatform('plugin.yaml'), isTrue);
    });

    test('lua plugins run everywhere', () {
      expect(executor.canRunOnPlatform('plugin.lua'), isTrue);
    });

    test('javascript plugins run everywhere', () {
      expect(executor.canRunOnPlatform('plugin.js'), isTrue);
    });

    test('dart plugins run on desktop (via dart run)', () {
      // Dart scripts run via dart run, so require desktop platform
      final result = executor.canRunOnPlatform('plugin.dart');
      // On desktop, expect true
      expect(result, isTrue);
    });

    // Script testing depends on platform
    test('scripts run on desktop', () {
      // This test will pass on Linux/macOS/Windows, fail on mobile
      final result = executor.canRunOnPlatform('plugin.sh');
      // On desktop, expect true
      expect(result, isTrue);
    });
  });

  group('PluginExecutor - Supported Extensions', () {
    test('includes all expected extensions', () {
      final extensions = executor.supportedExtensions;
      
      // Declarative
      expect(extensions, contains('yaml'));
      expect(extensions, contains('yml'));
      
      // Dart
      expect(extensions, contains('dart'));
      
      // Scripts
      expect(extensions, contains('sh'));
      expect(extensions, contains('py'));
      expect(extensions, contains('js'));
      expect(extensions, contains('go'));
      expect(extensions, contains('rs'));
      
      // Embedded (work everywhere)
      expect(extensions, contains('lua'));
    });
  });
}
