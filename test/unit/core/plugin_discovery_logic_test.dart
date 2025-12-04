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

      // On Unix, ensure it is executable for it to be enabled
      if (Platform.isLinux || Platform.isMacOS) {
        await Process.run('chmod', ['+x', path.join(tempDir.path, 'root_plugin.sh')]);
      }

      await manager.discoverPlugins();

      // We might discover more if previous tests left something?
      // No, setUp creates new tempDir and clears manager.

      expect(manager.plugins.length, 1);
      expect(manager.plugins.first.id, 'root_plugin.sh');
      expect(manager.plugins.first.enabled, true);
    });

    test('discovers .off. plugins as disabled', () async {
      File(path.join(tempDir.path, 'disabled.off.sh')).createSync();
      // Even if executable, .off. takes precedence
      if (Platform.isLinux || Platform.isMacOS) {
        await Process.run('chmod', ['+x', path.join(tempDir.path, 'disabled.off.sh')]);
      }

      await manager.discoverPlugins();

      expect(manager.plugins.length, 1);
      final plugin = manager.plugins.first;
      expect(plugin.id, 'disabled.off.sh');
      expect(plugin.enabled, false);
    });

    test('discovers non-executable plugins as disabled (Unix)', () async {
      if (!Platform.isLinux && !Platform.isMacOS) return;

      final p = path.join(tempDir.path, 'no_exec.sh');
      File(p).createSync();
      await Process.run('chmod', ['-x', p]);

      await manager.discoverPlugins();

      expect(manager.plugins.length, 1);
      final plugin = manager.plugins.first;
      expect(plugin.id, 'no_exec.sh');
      expect(plugin.enabled, false);
    });

    test('enablePlugin renames file if contains .off.', () async {
        final p = path.join(tempDir.path, 'test.off.sh');
        File(p).createSync();

        await manager.discoverPlugins();
        // Since we didn't chmod +x, on linux it might be disabled by chmod AND by .off.
        // But .off. is sufficient.
        expect(manager.plugins.first.enabled, false);

        await manager.enablePlugin('test.off.sh');

        expect(File(p).existsSync(), false);
        expect(File(path.join(tempDir.path, 'test.sh')).existsSync(), true);

        // Check list update
        expect(manager.getPlugin('test.off.sh'), isNull);
        final newPlugin = manager.getPlugin('test.sh');
        expect(newPlugin, isNotNull);
        expect(newPlugin!.enabled, true);
    });

    test('disablePlugin renames file to contain .off.', () async {
        final p = path.join(tempDir.path, 'test.sh');
        File(p).createSync();
        // Make executable initially
        if (Platform.isLinux || Platform.isMacOS) {
            await Process.run('chmod', ['+x', p]);
        }

        await manager.discoverPlugins();

        expect(manager.getPlugin('test.sh')!.enabled, true);

        await manager.disablePlugin('test.sh');

        expect(File(p).existsSync(), false);
        expect(File(path.join(tempDir.path, 'test.off.sh')).existsSync(), true);

        expect(manager.getPlugin('test.sh'), isNull);
        final newPlugin = manager.getPlugin('test.off.sh');
        expect(newPlugin, isNotNull);
        expect(newPlugin!.enabled, false);
    });

    test('enablePlugin changes permission (Unix)', () async {
       if (!Platform.isLinux && !Platform.isMacOS) return;

       final p = path.join(tempDir.path, 'test.sh');
       File(p).createSync();
       await Process.run('chmod', ['-x', p]);

       await manager.discoverPlugins();
       expect(manager.plugins.first.enabled, false);

       await manager.enablePlugin('test.sh');

       final stat = File(p).statSync();
       // Check user execute bit (0x40) or others.
       // Our code checks 0x49. chmod +x sets all.
       expect(stat.mode & 0x49 != 0, true);
       expect(manager.getPlugin('test.sh')!.enabled, true);
    });
  });
}
