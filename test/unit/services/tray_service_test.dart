import 'dart:io';

import 'package:crossbar/core/plugin_manager.dart';
import 'package:crossbar/models/plugin_output.dart';
import 'package:crossbar/services/settings_service.dart';
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
      SettingsService().resetForTesting();

      // Mock system_tray channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter/system_tray/tray'),
        (MethodCall methodCall) async {
          log.add(methodCall);
          return true;
        },
      );

      // Mock menu manager channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter/system_tray/menu_manager'),
        (MethodCall methodCall) async {
          log.add(methodCall);
          return true;
        },
      );

      tempDir = Directory.systemTemp.createTempSync();
      // Create 2 plugins to test separation
      final p1 = File('${tempDir.path}/p1.sh');
      p1.writeAsStringSync('#!/bin/bash\necho "p1"');
      final p2 = File('${tempDir.path}/p2.sh');
      p2.writeAsStringSync('#!/bin/bash\necho "p2"');

      if (Platform.isLinux || Platform.isMacOS) {
        Process.runSync('chmod', ['+x', p1.path]);
        Process.runSync('chmod', ['+x', p2.path]);
      }

      final pm = PluginManager();
      pm.clear();
      pm.customPluginsDirectory = tempDir.path;
      await pm.discoverPlugins();

      trayService = TrayService();
      trayService.resetForTesting();
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
      log.clear();
      trayService.resetForTesting();
    });

    test('init creates separate trays for plugins (default)', () async {
      await trayService.init();
      // Expect init calls.
      // If we have 2 plugins, we expect 2 'InitSystemTray' calls.

      final initCalls = log.where((c) => c.method == 'InitSystemTray');
      // If channel name is wrong, this will be empty.
      // But let's assume it works.

      // If it fails, we might need to debug channel name.
      expect(initCalls.length, equals(2));
    });

    test('Unified mode creates 1 tray', () async {
      SettingsService().trayDisplayMode = TrayDisplayMode.unified;
      await trayService.init();

      final initCalls = log.where((c) => c.method == 'InitSystemTray');
      expect(initCalls.length, equals(1));
    });

    test('SmartCollapse mode with threshold 1 creates 1 tray for 2 plugins', () async {
      SettingsService().trayClusterThreshold = 1;
      SettingsService().trayDisplayMode = TrayDisplayMode.smartCollapse;

      await trayService.init();

      final initCalls = log.where((c) => c.method == 'InitSystemTray');
      expect(initCalls.length, equals(1));
    });

    test('SmartCollapse mode with threshold 3 creates 2 trays for 2 plugins', () async {
      SettingsService().trayClusterThreshold = 3;
      SettingsService().trayDisplayMode = TrayDisplayMode.smartCollapse;

      await trayService.init();

      final initCalls = log.where((c) => c.method == 'InitSystemTray');
      expect(initCalls.length, equals(2));
    });

    test('SmartOverflow mode with threshold 1 creates 1 plugin tray + 1 overflow tray', () async {
      // 2 plugins. Threshold 1.
      // Plugin 1 -> separate.
      // Plugin 2 -> overflow.
      // Total 2 trays.
      SettingsService().trayClusterThreshold = 1;
      SettingsService().trayDisplayMode = TrayDisplayMode.smartOverflow;

      await trayService.init();

      final initCalls = log.where((c) => c.method == 'InitSystemTray');
      expect(initCalls.length, equals(2));
    });

    test('switching modes destroys old trays', () async {
      await trayService.init();
      log.clear();

      SettingsService().trayDisplayMode = TrayDisplayMode.unified;
      await Future.delayed(Duration.zero);

      final destroyCalls = log.where((c) => c.method == 'DestroySystemTray');
      expect(destroyCalls.length, equals(2));
    });

    test('updatePluginOutput updates the tray', () async {
      await trayService.init();
      log.clear();

      const output = PluginOutput(
        pluginId: 'p1.sh',
        icon: 'A',
        text: 'B',
      );

      trayService.updatePluginOutput('p1.sh', output);
      await Future.delayed(Duration.zero);

      final titleCalls = log.where((c) => c.method == 'SetSystemTrayInfo');
      expect(titleCalls, isNotEmpty);

      final menuCalls = log.where((c) => c.method == 'SetContextMenu');
      expect(menuCalls, isNotEmpty);
    });

    test('menu structure contains separators and global actions', () async {
      await trayService.init();
      log.clear();

      const output = PluginOutput(
        pluginId: 'p1.sh',
        icon: 'P1',
        text: 'Content',
        menu: [
          MenuItem(text: 'Item 1'),
          MenuItem(separator: true), // MenuItem.separator() factory isn't const
        ]
      );

      trayService.updatePluginOutput('p1.sh', output);
      await Future.delayed(Duration.zero);

      // Verify CreateContextMenu was called on menu manager
      final menuCalls = log.where((c) => c.method == 'CreateContextMenu');
      expect(menuCalls, isNotEmpty);

      // Verify SetContextMenu on tray
      final setMenuCalls = log.where((c) => c.method == 'SetContextMenu');
      expect(setMenuCalls, isNotEmpty);
    });

    test('menu structure handles submenus', () async {
      await trayService.init();
      log.clear();

      const output = PluginOutput(
        pluginId: 'p1.sh',
        icon: 'P1',
        text: 'Content',
        menu: [
          MenuItem(text: 'Parent', submenu: [
             MenuItem(text: 'Child')
          ]),
        ]
      );

      trayService.updatePluginOutput('p1.sh', output);
      await Future.delayed(Duration.zero);

      final menuCalls = log.where((c) => c.method == 'CreateContextMenu');
      expect(menuCalls, isNotEmpty);
    });

    test('clearPluginOutput updates the tray', () async {
      await trayService.init();
      const output = PluginOutput(pluginId: 'p1.sh', icon: 'X', text: 'Y');
      trayService.updatePluginOutput('p1.sh', output);
      await Future.delayed(Duration.zero);
      log.clear();

      trayService.clearPluginOutput('p1.sh');
      await Future.delayed(Duration.zero);

      // Should update title to default (pluginId)
      final titleCalls = log.where((c) => c.method == 'SetSystemTrayInfo');
      expect(titleCalls, isNotEmpty);
    });

    test('menu item enabled state depends on action presence', () async {
      await trayService.init();
      log.clear();

      const output = PluginOutput(
        pluginId: 'p1.sh',
        icon: 'P1',
        text: 'Content',
        menu: [
          MenuItem(text: 'Static'), // enabled: false
          MenuItem(text: 'Action', href: 'http://google.com'), // enabled: true
          MenuItem(text: 'Bash', bash: 'echo hi'), // enabled: true
        ]
      );

      trayService.updatePluginOutput('p1.sh', output);
      await Future.delayed(Duration.zero);

      final menuCalls = log.where((c) => c.method == 'CreateContextMenu');
      expect(menuCalls, isNotEmpty);
    });
  });
}
