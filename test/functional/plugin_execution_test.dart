import 'dart:io';

import 'package:crossbar/core/output_parser.dart';
import 'package:crossbar/core/script_runner.dart';
import 'package:crossbar/models/plugin.dart';
import 'package:flutter_test/flutter_test.dart';

/// Functional tests for plugin execution.
/// These tests execute real plugins and validate their output.
/// They run in CI since they only require bash, python3, and node.
void main() {
  late ScriptRunner runner;
  late String fixturesPath;

  setUpAll(() {
    runner = const ScriptRunner();
    // Get the path to test fixtures
    fixturesPath = '${Directory.current.path}/test/functional/fixtures';
  });

  group('Plugin Execution', () {
    group('Bash plugins', () {
      test('executes simple bash plugin and returns BitBar output', () async {
        final plugin = Plugin(
          id: 'test-simple-bash',
          path: '$fixturesPath/simple.1s.sh',
          interpreter: 'bash',
          refreshInterval: const Duration(seconds: 1),
        );

        final output = await runner.run(plugin);

        expect(output.hasError, isFalse);
        expect(output.text, equals('Test: OK'));
        expect(output.menu, hasLength(2));
        expect(output.menu[0].text, equals('Menu Item 1'));
        expect(output.menu[1].text, equals('Menu Item 2'));
      });

      test('executes bash plugin with JSON output', () async {
        final plugin = Plugin(
          id: 'test-json-bash',
          path: '$fixturesPath/json_output.1s.sh',
          interpreter: 'bash',
          refreshInterval: const Duration(seconds: 1),
        );

        final output = await runner.run(plugin);

        expect(output.hasError, isFalse);
        expect(output.text, equals('JSON Test'));
        expect(output.icon, equals('🧪'));
        expect(output.menu, hasLength(2));
      });

      test('injects environment variables into bash plugin', () async {
        final plugin = Plugin(
          id: 'test-env-bash',
          path: '$fixturesPath/env_check.1s.sh',
          interpreter: 'bash',
          refreshInterval: const Duration(seconds: 1),
        );

        final output = await runner.run(plugin);

        expect(output.hasError, isFalse);
        expect(output.text, contains('OS:'));
        expect(output.text, contains(Platform.operatingSystem));
      });
    });

    group('Python plugins', () {
      test('executes simple python plugin', () async {
        final plugin = Plugin(
          id: 'test-simple-python',
          path: '$fixturesPath/simple.1s.py',
          interpreter: 'python3',
          refreshInterval: const Duration(seconds: 1),
        );

        final output = await runner.run(plugin);

        expect(output.hasError, isFalse);
        expect(output.text, equals('Python: OK'));
        expect(output.menu, hasLength(1));
        expect(output.menu[0].text, equals('Python Menu Item'));
      });
    });

    group('Node.js plugins', () {
      test('executes simple node plugin', () async {
        final plugin = Plugin(
          id: 'test-simple-node',
          path: '$fixturesPath/simple.1s.js',
          interpreter: 'node',
          refreshInterval: const Duration(seconds: 1),
        );

        final output = await runner.run(plugin);

        expect(output.hasError, isFalse);
        expect(output.text, equals('Node: OK'));
        expect(output.menu, hasLength(1));
        expect(output.menu[0].text, equals('Node Menu Item'));
      });
    });

    group('Timeout handling', () {
      test('handles plugin timeout gracefully', () async {
        final plugin = Plugin(
          id: 'test-timeout',
          path: '$fixturesPath/timeout.1s.sh',
          interpreter: 'bash',
          refreshInterval: const Duration(seconds: 1),
        );

        // Use a custom runner with short timeout for testing
        final shortTimeoutRunner = ScriptRunner(
          processRunner: _ShortTimeoutRunner(),
        );

        final output = await shortTimeoutRunner.run(plugin);

        expect(output.hasError, isTrue);
        expect(output.errorMessage, contains('timed out'));
      }, timeout: const Timeout(Duration(seconds: 10)));
    });

    group('Error handling', () {
      test('handles non-existent plugin gracefully', () async {
        final plugin = Plugin(
          id: 'test-nonexistent',
          path: '$fixturesPath/does_not_exist.sh',
          interpreter: 'bash',
          refreshInterval: const Duration(seconds: 1),
        );

        final output = await runner.run(plugin);

        expect(output.hasError, isTrue);
      });

      test('handles invalid interpreter gracefully', () async {
        final plugin = Plugin(
          id: 'test-invalid-interpreter',
          path: '$fixturesPath/simple.1s.sh',
          interpreter: 'nonexistent_interpreter_xyz',
          refreshInterval: const Duration(seconds: 1),
        );

        final output = await runner.run(plugin);

        expect(output.hasError, isTrue);
      });
    });
  });

  group('Output Parser', () {
    test('correctly identifies JSON output', () {
      const jsonOutput = '{"text": "Hello", "icon": "🔥"}';
      expect(OutputParser.isJson(jsonOutput), isTrue);
    });

    test('correctly identifies non-JSON output', () {
      const textOutput = 'Hello World\n---\nMenu Item';
      expect(OutputParser.isJson(textOutput), isFalse);
    });

    test('parses BitBar text format correctly', () {
      const output = '''Title Text
---
Menu Item 1
Menu Item 2 | color=red
Submenu Parent
--Submenu Child''';

      final parsed = OutputParser.parse(output, 'test-plugin');

      expect(parsed.text, equals('Title Text'));
      expect(parsed.menu.length, greaterThanOrEqualTo(2));
    });

    test('parses JSON format correctly', () {
      const output = '{"text": "JSON Title", "icon": "🚀", "menu": [{"text": "Item 1"}]}';

      final parsed = OutputParser.parse(output, 'test-plugin');

      expect(parsed.text, equals('JSON Title'));
      expect(parsed.icon, equals('🚀'));
      expect(parsed.menu, hasLength(1));
    });
  });
}

/// Custom process runner with short timeout for testing
class _ShortTimeoutRunner implements IProcessRunner {
  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    Map<String, String>? environment,
    required Duration timeout,
  }) async {
    // Use 2 second timeout instead of default 30s
    final process = await Process.start(
      executable,
      arguments,
      environment: environment,
      runInShell: true,
    );

    try {
      final results = await Future.wait([
        process.stdout.transform(const SystemEncoding().decoder).join(),
        process.stderr.transform(const SystemEncoding().decoder).join(),
        process.exitCode,
      ]).timeout(const Duration(seconds: 2));

      return ProcessResult(
        process.pid,
        results[2] as int,
        results[0],
        results[1],
      );
    } catch (_) {
      process.kill(ProcessSignal.sigterm);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      process.kill(ProcessSignal.sigkill);
      rethrow;
    }
  }
}
