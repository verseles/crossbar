import 'package:crossbar/core/script_runner.dart';
import 'package:crossbar/models/plugin.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScriptRunner', () {
    group('with MockProcessRunner', () {
      test('runs plugin and returns parsed output', () async {
        const mockRunner = MockProcessRunner(
          mockOutputs: {'/path/to/test.sh': '{"icon":"","text":"45%"}'},
        );

        const scriptRunner = ScriptRunner(processRunner: mockRunner);
        const plugin = Plugin(
          id: 'test.sh',
          path: '/path/to/test.sh',
          interpreter: 'bash',
          refreshInterval: Duration(seconds: 10),
        );

        final output = await scriptRunner.run(plugin);

        expect(output.pluginId, 'test.sh');
        expect(output.icon, '');
        expect(output.text, '45%');
        expect(output.hasError, false);
      });

      test('handles non-zero exit code', () async {
        const mockRunner = MockProcessRunner(
          mockOutputs: {'/path/to/test.sh': 'error output'},
          mockExitCodes: {'/path/to/test.sh': 1},
        );

        const scriptRunner = ScriptRunner(processRunner: mockRunner);
        const plugin = Plugin(
          id: 'test.sh',
          path: '/path/to/test.sh',
          interpreter: 'bash',
          refreshInterval: Duration(seconds: 10),
        );

        final output = await scriptRunner.run(plugin);

        expect(output.hasError, true);
        expect(output.errorMessage, contains('exit'));
      });

      test('returns empty output for empty script result', () async {
        const mockRunner = MockProcessRunner(
          mockOutputs: {'/path/to/test.sh': ''},
        );

        const scriptRunner = ScriptRunner(processRunner: mockRunner);
        const plugin = Plugin(
          id: 'test.sh',
          path: '/path/to/test.sh',
          interpreter: 'bash',
          refreshInterval: Duration(seconds: 10),
        );

        final output = await scriptRunner.run(plugin);

        expect(output.text, '');
        expect(output.hasError, false);
      });

      test('parses BitBar text format', () async {
        const mockRunner = MockProcessRunner(
          mockOutputs: {
            '/path/to/test.sh': ''' 45% | color=orange
---
Details | bash=/usr/bin/top
''',
          },
        );

        const scriptRunner = ScriptRunner(processRunner: mockRunner);
        const plugin = Plugin(
          id: 'test.sh',
          path: '/path/to/test.sh',
          interpreter: 'bash',
          refreshInterval: Duration(seconds: 10),
        );

        final output = await scriptRunner.run(plugin);

        expect(output.icon, '');
        expect(output.text, '45%');
        expect(output.menu.length, 1);
        expect(output.menu[0].text, 'Details');
      });
    });

    group('environment variables', () {
      test('default timeout is 30 seconds', () {
        expect(ScriptRunner.defaultTimeout, const Duration(seconds: 30));
      });

      test('version is set', () {
        expect(ScriptRunner.crossbarVersion, '1.0.0');
      });
    });
  });

  group('MockProcessRunner', () {
    test('returns configured output', () async {
      const runner = MockProcessRunner(
        mockOutputs: {'/test': 'output'},
        mockExitCodes: {'/test': 0},
      );

      final result = await runner.run(
        'bash',
        ['/test'],
        timeout: const Duration(seconds: 5),
      );

      expect(result.stdout, 'output');
      expect(result.exitCode, 0);
    });

    test('returns empty output for unknown path', () async {
      const runner = MockProcessRunner();

      final result = await runner.run(
        'bash',
        ['/unknown'],
        timeout: const Duration(seconds: 5),
      );

      expect(result.stdout, '');
      expect(result.exitCode, 0);
    });
  });

  group('SystemProcessRunner', () {
    test('exists and is const constructible', () {
      const runner = SystemProcessRunner();
      expect(runner, isNotNull);
    });
  });
}
