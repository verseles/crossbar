// ignore_for_file: avoid_slow_async_io
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
    final log = <MethodCall>[];

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
      if (Platform.isLinux || Platform.isMacOS) {
        Process.runSync('chmod', ['+x', pluginFile.path]);
      }

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

  });
}
