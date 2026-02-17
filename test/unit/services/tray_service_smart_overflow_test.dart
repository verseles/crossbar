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

  group('TrayService Smart Overflow', () {
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
        'tray_display_mode': 'smartOverflow',
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

    test('Uses Separate mode when plugin count <= threshold', () async {
      await createPlugin('p1.sh');
      await createPlugin('p2.sh');

      await trayService.init();

      // Enable p1
      await enablePlugin('p1.sh');
      // Should be in separate mode (count 1 <= 2)
      // Check if backend createIcon was called
      expect(mockBackend.createdIcons.length, 1);

      // Enable p2
      await enablePlugin('p2.sh');
      // Should still be in separate mode (count 2 <= 2)
      expect(mockBackend.createdIcons.length, 2);
    });

    test('Switches to Unified mode when plugin count > threshold', () async {
      await createPlugin('p1.sh');
      await createPlugin('p2.sh');
      await createPlugin('p3.sh');

      await trayService.init();

      // Enable p1, p2 (Separate mode)
      await enablePlugin('p1.sh');
      await enablePlugin('p2.sh');
      expect(mockBackend.createdIcons.length, 2);

      // Enable p3 (Unified mode, count 3 > 2)
      await enablePlugin('p3.sh');

      // Should have destroyed separate icons
      expect(mockBackend.createdIcons.length, 0);

      // Should have updated unified menu with plugins
      // Check log for setContextMenu
      final setContextMenuCalls =
          log.where((c) => c.method == 'setContextMenu');
      expect(setContextMenuCalls, isNotEmpty);
    });

    test('Switches back to Separate mode when plugin count drops <= threshold',
        () async {
      await createPlugin('p1.sh');
      await createPlugin('p2.sh');
      await createPlugin('p3.sh');

      await trayService.init();

      // Enable p1, p2, p3 (Unified mode)
      await enablePlugin('p1.sh');
      await enablePlugin('p2.sh');
      await enablePlugin('p3.sh');
      expect(mockBackend.createdIcons.length, 0);

      // Disable p3 (Separate mode, count 2 <= 2)
      await PluginManager().disablePlugin('p3.sh');
      // Need to manually trigger refresh because we are bypassing RefreshService listener
      await trayService.refreshMenu();

      // Should have created 2 separate icons (for p1 and p2)
      expect(mockBackend.createdIcons.length, 2);
    });
  });
}
