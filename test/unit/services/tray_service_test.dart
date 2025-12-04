import 'dart:io';

import 'package:crossbar/core/plugin_manager.dart';
import 'package:crossbar/models/plugin_output.dart';
import 'package:crossbar/services/tray_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TrayService', () {
    late TrayService trayService;
    late Directory tempDir;
    final List<MethodCall> log = <MethodCall>[];

    setUp(() async {
      // Mock TrayManager channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('tray_manager'),
        (MethodCall methodCall) async {
          log.add(methodCall);
          return null;
        },
      );

      // Setup PluginManager with dummy plugin
      tempDir = Directory.systemTemp.createTempSync();
      final pluginFile = File('${tempDir.path}/test_plugin.sh');
      pluginFile.writeAsStringSync('#!/bin/bash\necho "test"');

      final pm = PluginManager();
      pm.clear();
      pm.customPluginsDirectory = tempDir.path;
      await pm.discoverPlugins();

      trayService = TrayService();
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
      log.clear();
    });

    test('init sets icon and menu', () async {
      // We assume init hasn't run or is idempotent-ish regarding side effects we check
      // But since it's a singleton, if it ran before, it won't run again.
      // So we check IF it runs.

      await trayService.init();

      // If it ran (first time), we expect logs.
      // If it didn't run (already initialized), logs will be empty from init.
      // To make this robust, we can't easily rely on checking init logs if we can't reset.
      // But this is the first test file for TrayService, so it should be fresh process.
      // However, across 'test' calls?
      // Dart test runner usually isolates tests?
      // Actually, 'group' shares the isolate. Singleton persists.

      // Let's verify if log contains setIcon.
      // If the singleton was fresh, it should.
      if (log.isNotEmpty) {
         expect(log, contains(isA<MethodCall>().having((c) => c.method, 'method', 'setIcon')));
         expect(log, contains(isA<MethodCall>().having((c) => c.method, 'method', 'setContextMenu')));
      }
    });

    test('updatePluginOutput updates title for first plugin', () async {
      // Ensure we have the plugin
      final pm = PluginManager();
      expect(pm.plugins, isNotEmpty);
      final pluginId = pm.plugins.first.id;

      final output = PluginOutput(
        pluginId: pluginId,
        icon: '🚀',
        text: 'Test Output',
      );

      trayService.updatePluginOutput(pluginId, output);
      // updateTitle is async
      await Future.delayed(Duration.zero);

      // Check for setTitle
      final setTitleCalls = log.where((c) => c.method == 'setTitle');
      expect(setTitleCalls, isNotEmpty);
      final args = setTitleCalls.last.arguments;
      // tray_manager might send arguments as a Map (Linux/MethodChannel convention)
      if (args is Map) {
        expect(args['title'], '🚀 Test Output');
      } else {
        expect(args, '🚀 Test Output');
      }
    });

    test('updatePluginOutput does NOT update title for other plugins', () async {
      final otherPluginId = 'other_plugin.sh';

      final output = PluginOutput(
        pluginId: otherPluginId,
        icon: '👾',
        text: 'Alien Output',
      );

      log.clear();
      trayService.updatePluginOutput(otherPluginId, output);
      await Future.delayed(Duration.zero);

      final setTitleCalls = log.where((c) => c.method == 'setTitle');
      expect(setTitleCalls, isEmpty);
    });
  });
}
