import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:crossbar/cli/plugin_scaffolding.dart';

void main() {
  group('PluginScaffolding', () {
    const scaffolding = PluginScaffolding();
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('crossbar_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('supportedLanguages', () {
      test('contains all expected languages', () {
        expect(PluginScaffolding.supportedLanguages, contains('bash'));
        expect(PluginScaffolding.supportedLanguages, contains('python'));
        expect(PluginScaffolding.supportedLanguages, contains('node'));
        expect(PluginScaffolding.supportedLanguages, contains('dart'));
        expect(PluginScaffolding.supportedLanguages, contains('go'));
        expect(PluginScaffolding.supportedLanguages, contains('rust'));
      });

      test('has 6 languages', () {
        expect(PluginScaffolding.supportedLanguages.length, 6);
      });
    });

    group('supportedTypes', () {
      test('contains all expected types', () {
        expect(PluginScaffolding.supportedTypes, contains('clock'));
        expect(PluginScaffolding.supportedTypes, contains('monitor'));
        expect(PluginScaffolding.supportedTypes, contains('status'));
        expect(PluginScaffolding.supportedTypes, contains('api'));
        expect(PluginScaffolding.supportedTypes, contains('custom'));
      });

      test('has 5 types', () {
        expect(PluginScaffolding.supportedTypes.length, 5);
      });
    });

    group('typeIntervals', () {
      test('clock has 1s interval', () {
        expect(PluginScaffolding.typeIntervals['clock'], '1s');
      });

      test('monitor has 10s interval', () {
        expect(PluginScaffolding.typeIntervals['monitor'], '10s');
      });

      test('status has 30s interval', () {
        expect(PluginScaffolding.typeIntervals['status'], '30s');
      });

      test('api has 5m interval', () {
        expect(PluginScaffolding.typeIntervals['api'], '5m');
      });

      test('custom has 1m interval', () {
        expect(PluginScaffolding.typeIntervals['custom'], '1m');
      });
    });

    group('langExtensions', () {
      test('bash has sh extension', () {
        expect(PluginScaffolding.langExtensions['bash'], 'sh');
      });

      test('python has py extension', () {
        expect(PluginScaffolding.langExtensions['python'], 'py');
      });

      test('node has js extension', () {
        expect(PluginScaffolding.langExtensions['node'], 'js');
      });

      test('dart has dart extension', () {
        expect(PluginScaffolding.langExtensions['dart'], 'dart');
      });

      test('go has go extension', () {
        expect(PluginScaffolding.langExtensions['go'], 'go');
      });

      test('rust has rs extension', () {
        expect(PluginScaffolding.langExtensions['rust'], 'rs');
      });
    });

    group('createPlugin', () {
      test('creates bash plugin', () async {
        final path = await scaffolding.createPlugin(
          lang: 'bash',
          type: 'monitor',
          name: 'test',
          outputDir: tempDir.path,
        );

        expect(path, isNotNull);
        expect(path, endsWith('test.10s.sh'));
        expect(await File(path!).exists(), true);
      });

      test('creates config file alongside plugin', () async {
        final path = await scaffolding.createPlugin(
          lang: 'python',
          type: 'clock',
          name: 'test',
          outputDir: tempDir.path,
        );

        expect(path, isNotNull);
        expect(await File('$path.config.json').exists(), true);
      });

      test('creates plugin in root directory', () async {
        final path = await scaffolding.createPlugin(
          lang: 'dart',
          type: 'status',
          name: 'test',
          outputDir: tempDir.path,
        );

        // Should not be in language subdirectory anymore
        expect(path, isNot(contains('/dart/')));
        // Should be directly in output dir
        expect(path, startsWith(tempDir.path));
      });

      test('uses correct interval for type', () async {
        final path = await scaffolding.createPlugin(
          lang: 'node',
          type: 'api',
          name: 'test',
          outputDir: tempDir.path,
        );

        expect(path, contains('.5m.'));
      });

      test('returns null for unsupported language', () async {
        final path = await scaffolding.createPlugin(
          lang: 'invalid',
          type: 'monitor',
          outputDir: tempDir.path,
        );

        expect(path, isNull);
      });

      test('returns null for unsupported type', () async {
        final path = await scaffolding.createPlugin(
          lang: 'bash',
          type: 'invalid',
          outputDir: tempDir.path,
        );

        expect(path, isNull);
      });

      test('generates default name when not provided', () async {
        final path = await scaffolding.createPlugin(
          lang: 'bash',
          type: 'monitor',
          outputDir: tempDir.path,
        );

        expect(path, contains('my-monitor'));
      });

      test('generated bash plugin is executable', () async {
        final path = await scaffolding.createPlugin(
          lang: 'bash',
          type: 'monitor',
          name: 'test',
          outputDir: tempDir.path,
        );

        if (Platform.isLinux || Platform.isMacOS) {
          final result = await Process.run('bash', [path!]);
          expect(result.exitCode, 0);
          expect(result.stdout.toString(), contains('OK'));
        }
      });

      test('generated python plugin runs successfully', () async {
        final path = await scaffolding.createPlugin(
          lang: 'python',
          type: 'status',
          name: 'test',
          outputDir: tempDir.path,
        );

        final result = await Process.run('python3', [path!]);
        expect(result.exitCode, 0);
        expect(result.stdout.toString(), contains('OK'));
      });

      test('generated go plugin compiles and runs', () async {
        final path = await scaffolding.createPlugin(
          lang: 'go',
          type: 'clock',
          name: 'test',
          outputDir: tempDir.path,
        );

        final result = await Process.run('go', ['run', path!]);
        expect(result.exitCode, 0);
        expect(result.stdout.toString(), contains('OK'));
      });
    });
  });

  group('PluginInstaller', () {
    const installer = PluginInstaller();

    group('installFromGitHub', () {
      test('returns null for non-GitHub URL', () async {
        final path = await installer.installFromGitHub('https://gitlab.com/user/repo');
        expect(path, isNull);
      });

      test('returns null for invalid GitHub URL', () async {
        final path = await installer.installFromGitHub('https://github.com/');
        expect(path, isNull);
      });

      test('returns null for malformed URL', () async {
        final path = await installer.installFromGitHub('not-a-url');
        expect(path, isNull);
      });
    });
  });
}
