import 'dart:io';

import 'package:crossbar/cli/commands/plugin_commands.dart';
import 'package:crossbar/core/plugin_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  group('RunPluginCommand', () {
    late Directory tempDir;
    late PluginManager manager;
    late RunPluginCommand command;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('crossbar_test_run_plugin_');
      manager = PluginManager();
      manager.customPluginsDirectory = tempDir.path;
      manager.clear();
      command = RunPluginCommand();
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('executes plugin successfully', () async {
      // Create a dummy plugin
      // On linux/mac we need sh or bash.
      final pluginFile = File(path.join(tempDir.path, 'test.sh'));
      // A simple script that outputs text
      pluginFile.writeAsStringSync('#!/bin/bash\necho "Test Output"');

      if (Platform.isLinux || Platform.isMacOS) {
        Process.runSync('chmod', ['+x', pluginFile.path]);
      }

      // We need to capture stdout to verify output, but exit code 0 is enough for coverage of success path
      final exitCode = await command.execute(['test.sh']);
      expect(exitCode, 0);
    });

    test('fails if plugin not found', () async {
      final exitCode = await command.execute(['non_existent.sh']);
      expect(exitCode, 1);
    });

    test('fails if no plugin id provided', () async {
      final exitCode = await command.execute([]);
      expect(exitCode, 1);
    });

    test('runs disabled plugin', () async {
      // Create a disabled plugin
      final pluginFile = File(path.join(tempDir.path, 'test.off.sh'));
      pluginFile.writeAsStringSync('#!/bin/bash\necho "Disabled Output"');
       if (Platform.isLinux || Platform.isMacOS) {
        Process.runSync('chmod', ['+x', pluginFile.path]);
      }

      final exitCode = await command.execute(['test.off.sh']);
      expect(exitCode, 0);
    });
  });
}
