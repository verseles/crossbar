import 'dart:io';
import 'package:crossbar/core/plugin_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  late PluginManager manager;
  late Directory tempDir;

  setUp(() async {
    manager = PluginManager();
    manager.clear();
    tempDir = await Directory.systemTemp.createTemp('crossbar_test_plugins');
    manager.customPluginsDirectory = tempDir.path;
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('PluginManager Discovery', () {
    test('discovers plugins in root directory', () async {
      final file = File(path.join(tempDir.path, 'test.10s.sh'));
      await file.writeAsString('#!/bin/bash\necho "Hello"');
      if (!Platform.isWindows) {
        await Process.run('chmod', ['+x', file.path]);
      }

      await manager.discoverPlugins();

      expect(manager.plugins.length, 1);
      expect(manager.plugins.first.id, 'test.10s.sh');
      expect(manager.plugins.first.interpreter, 'bash');
    });

    test('discovers plugins in subdirectories and groups them', () async {
      final subDir = Directory(path.join(tempDir.path, 'cpu'));
      await subDir.create();

      final file1 = File(path.join(subDir.path, 'cpu.10s.sh'));
      await file1.writeAsString('#!/bin/bash\necho "CPU"');
      
      final file2 = File(path.join(subDir.path, 'cpu.10s.lua'));
      await file2.writeAsString('print("CPU")');

      await manager.discoverPlugins();

      expect(manager.plugins.length, 1);
      final plugin = manager.plugins.first;
      expect(plugin.id, 'cpu');
      expect(plugin.variants.length, 2);
      
      // Primary should be Lua because of our priority sorting (.lua < .sh)
      expect(path.extension(plugin.path), '.lua');
      expect(plugin.interpreter, 'lua');
    });

    test('discovers recursive subdirectories', () async {
      final deepDir = Directory(path.join(tempDir.path, 'a', 'b', 'c'));
      await deepDir.create(recursive: true);

      final file = File(path.join(deepDir.path, 'deep.10s.sh'));
      await file.writeAsString('#!/bin/bash\necho "Deep"');

      await manager.discoverPlugins();

      expect(manager.plugins.length, 1);
      expect(manager.plugins.first.id, 'c'); // ID is the parent directory name
    });
    
    test('groups by base name within the same directory', () async {
      final subDir = Directory(path.join(tempDir.path, 'multi'));
      await subDir.create();

      // Group 1: cpu
      await File(path.join(subDir.path, 'cpu.10s.sh')).writeAsString('');
      await File(path.join(subDir.path, 'cpu.10s.lua')).writeAsString('');
      
      // Group 2: memory
      await File(path.join(subDir.path, 'mem.5s.sh')).writeAsString('');

      await manager.discoverPlugins();

      expect(manager.plugins.length, 2);
      
      final cpuPlugin = manager.plugins.firstWhere((p) => p.id == 'multi' && p.path.contains('cpu'));
      final memPlugin = manager.plugins.firstWhere((p) => p.id == 'multi' && p.path.contains('mem'));
      
      expect(cpuPlugin.variants.length, 2);
      expect(memPlugin.variants.length, 1);
      
      // Wait, if they are in the same folder 'multi', they both get ID 'multi'?
      // This might be a problem if we have different plugins in the same folder.
      // But the spec says "The subdirectory name should match the base name of the plugin."
    });
  });
}
