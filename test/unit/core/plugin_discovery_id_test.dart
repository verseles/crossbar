// ignore_for_file: avoid_slow_async_io
import 'dart:io';

import 'package:crossbar/core/plugin_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  group('PluginManager ID Generation', () {
    late Directory tempDir;
    late PluginManager manager;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('crossbar_test_id_');
      manager = PluginManager();
      manager.customPluginsDirectory = tempDir.path;
      manager.clear();
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('generates unique IDs for plugins with same name in different directories', () async {
      // Create root/plugin.sh
      final rootPlugin = File(path.join(tempDir.path, 'plugin.sh'));
      rootPlugin.createSync();

      // Create root/subdir/plugin.sh
      final subDir = Directory(path.join(tempDir.path, 'subdir'));
      subDir.createSync();
      final subPlugin = File(path.join(subDir.path, 'plugin.sh'));
      subPlugin.createSync();

      // Make executable on Unix
      if (Platform.isLinux || Platform.isMacOS) {
        await Process.run('chmod', ['+x', rootPlugin.path]);
        await Process.run('chmod', ['+x', subPlugin.path]);
      }

      await manager.discoverPlugins();

      expect(manager.plugins.length, 2);

      final ids = manager.plugins.map((p) => p.id).toList();
      expect(ids, contains('plugin.sh'));
      expect(ids, contains(path.join('subdir', 'plugin.sh')));
    });
  });
}
