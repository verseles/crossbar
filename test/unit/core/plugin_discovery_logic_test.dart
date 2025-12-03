import 'dart:io';

import 'package:crossbar/core/plugin_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  group('PluginManager Discovery Logic', () {
    late Directory tempDir;
    late PluginManager manager;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('crossbar_test_plugins_');
      manager = PluginManager();
      manager.customPluginsDirectory = tempDir.path;
      manager.clear();
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('discovers plugins in root and first-level subdirectories', () async {
      // Create root plugins
      File(path.join(tempDir.path, 'root_plugin.sh')).createSync();
      File(path.join(tempDir.path, 'root_plugin.py')).createSync();

      // Create first-level subdirectory plugins
      final subDir = Directory(path.join(tempDir.path, 'my_repo'));
      subDir.createSync();
      File(path.join(subDir.path, 'sub_plugin.js')).createSync();

      // Create second-level subdirectory plugin (should be IGNORED)
      final deepDir = Directory(path.join(subDir.path, 'src'));
      deepDir.createSync();
      File(path.join(deepDir.path, 'deep_plugin.dart')).createSync();

      // Create non-executable file (should be IGNORED)
      // Actually _isExecutableFile checks extensions, and .txt is not allowed.
      File(path.join(tempDir.path, 'readme.txt')).createSync();

      await manager.discoverPlugins();

      final pluginIds = manager.plugins.map((p) => p.id).toList();

      expect(pluginIds, contains('root_plugin.sh'));
      expect(pluginIds, contains('root_plugin.py'));
      expect(pluginIds, contains('sub_plugin.js'));

      // Should NOT contain deep_plugin.dart
      expect(pluginIds, isNot(contains('deep_plugin.dart')));

      // Should NOT contain readme.txt
      expect(pluginIds, isNot(contains('readme.txt')));

      expect(manager.plugins.length, 3);
    });

    test('ignores non-language folders if they contain no valid plugins', () async {
       final subDir = Directory(path.join(tempDir.path, 'empty_repo'));
       subDir.createSync();
       File(path.join(subDir.path, 'readme.md')).createSync();

       await manager.discoverPlugins();

       expect(manager.plugins, isEmpty);
    });
  });
}
