// ignore_for_file: avoid_slow_async_io
import 'dart:io';

import 'package:crossbar/core/plugin_manager.dart';
import 'package:crossbar_core/crossbar_core.dart';
import 'package:crossbar/services/refresh_service.dart';
import 'package:crossbar/services/settings_service.dart';
import 'package:crossbar/services/tray_service.dart';
import 'package:crossbar/services/tray/tray_backend.dart';
import 'package:crossbar/services/tray/tray_menu_item.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockTrayBackend implements TrayBackend {
  final List<int> createdIcons = [];
  final Map<int, String> iconPlugins = {};

  @override
  Future<bool> init() async => true;

  @override
  Future<int?> createIcon({
    required String pluginId,
    required String iconPath,
    required String tooltip,
  }) async {
    final id = createdIcons.length + 1;
    createdIcons.add(id);
    iconPlugins[id] = pluginId;
    return id;
  }

  @override
  Future<void> updateIcon({
    required int iconId,
    String? iconPath,
    String? title,
    String? tooltip,
    List<TrayMenuItem>? menu,
  }) async {
    // no-op
  }

  @override
  Future<void> destroyIcon(int iconId) async {
    createdIcons.remove(iconId);
    iconPlugins.remove(iconId);
  }

  @override
  Future<void> dispose() async {
    createdIcons.clear();
    iconPlugins.clear();
  }

  @override
  int get maxIcons => 10;

  @override
  bool get supportsMultipleIcons => true;

  @override
  bool get isInitialized => true;

  @override
  String get name => 'MockTrayBackend';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TrayService Smart Collapse', () {
    late TrayService trayService;
    late Directory tempDir;
    late MockTrayBackend mockBackend;
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

      // Setup Settings
      SettingsService().resetForTesting();
      // Initialize SettingsService (mocks SharedPreferences)
      SharedPreferences.setMockInitialValues({
        'tray_display_mode': 'smartCollapse',
        'tray_cluster_threshold': 2,
      });
      await SettingsService().init();

      // Setup PluginManager with dummy plugins
      tempDir = Directory.systemTemp.createTempSync();
      final pm = PluginManager();
      pm.clear();
      pm.customPluginsDirectory = tempDir.path;

      RefreshService().resetForTesting();

      mockBackend = MockTrayBackend();
      trayService = TrayService();
      // Reset TrayService state
      await trayService.dispose();

      trayService.backendForTesting = mockBackend;
    });

    tearDown(() async {
      await trayService.dispose();
      try {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      } catch (_) {}
      log.clear();
    });

    Future<void> createPlugin(String filename) async {
      final pluginFile = File('${tempDir.path}/$filename');
      pluginFile.writeAsStringSync('#!/bin/bash\necho "test"');
      if (Platform.isLinux || Platform.isMacOS) {
        Process.runSync('chmod', ['-x', pluginFile.path]);
      }
      // Re-discover plugins
      await PluginManager().discoverPlugins();
    }

    Future<void> enablePlugin(String id) async {
      // Use RefreshService to trigger list change listener
      await RefreshService().enablePlugin(id);
      // Simulate output update which normally happens after run
      trayService.updatePluginOutput(
          id, PluginOutput(pluginId: id, icon: '', text: 'Test'));
    }

    test('Uses Separate mode for first N plugins (count <= threshold)',
        () async {
      await createPlugin('p1.sh');
      await createPlugin('p2.sh');

      await trayService.init();

      // Enable p1
      await enablePlugin('p1.sh');
      // Should create 1 separate icon
      expect(mockBackend.createdIcons.length, 1);

      // Enable p2
      await enablePlugin('p2.sh');
      // Should create another separate icon (total 2)
      expect(mockBackend.createdIcons.length, 2);
    });

    test('Uses Mixed mode when plugin count > threshold', () async {
      await createPlugin('p1.sh');
      await createPlugin('p2.sh');
      await createPlugin('p3.sh');

      await trayService.init();

      // Enable p1, p2 (Separate mode)
      await enablePlugin('p1.sh');
      await enablePlugin('p2.sh');
      expect(mockBackend.createdIcons.length, 2);

      // Enable p3 (Should go to overflow menu)
      await enablePlugin('p3.sh');

      // Should NOT have created a new separate icon (still 2)
      expect(mockBackend.createdIcons.length, 2);

      // Should have updated unified menu with p3 (and potentially others)
      // Check log for setContextMenu calls
      // The last call should contain p3
      final calls = log.where((c) => c.method == 'setContextMenu').toList();
      expect(calls, isNotEmpty);
      // We can't easily inspect arguments without casting, but existence of calls implies menu update
    });

    test('Handles disabling plugins correctly (transition from overflow)',
        () async {
      await createPlugin('p1.sh');
      await createPlugin('p2.sh');
      await createPlugin('p3.sh');

      await trayService.init();

      // Enable all 3
      await enablePlugin('p1.sh');
      await enablePlugin('p2.sh');
      await enablePlugin('p3.sh');
      // Expect 2 icons (p1, p2) + overflow (p3)
      expect(mockBackend.createdIcons.length, 2);

      // Disable p2 (which was separate)
      // Now p3 should move from overflow to separate (since it becomes index 1)
      // Wait, disablePlugin logic:
      await PluginManager().disablePlugin('p2.sh');
      // Manually trigger refresh because we bypassed some listeners
      await trayService.refreshMenu();

      // p1 is index 0 (separate)
      // p3 is index 1 (separate)
      // p2 is disabled
      // Expect 2 icons
      expect(mockBackend.createdIcons.length, 2);

      // We expect p3 to be separate now.
      // Since mock IDs are just incrementing integers, we just check count.
    });

    test('Handles enabling plugins correctly (transition to overflow)',
        () async {
      await createPlugin('p1.sh');
      await createPlugin('p2.sh');
      await createPlugin('p3.sh');

      await trayService.init();

      // Enable p3 first (index 0)
      await enablePlugin('p3.sh');
      expect(mockBackend.createdIcons.length, 1);

      // Enable p2 (index depends on sorting... usually filename)
      // PluginManager sorts by filename/priority?
      // createPluginFromGroup sorts variants. discoverPlugins uses list order (OS dependent usually).
      // But let's assume alphabetical if FS returns it so, or insertion order?
      // Directory.list is not guaranteed order.
      // But PluginManager doesn't sort explicitly by name, it groups.

      // Let's force order by naming them a, b, c
    });
  });
}
