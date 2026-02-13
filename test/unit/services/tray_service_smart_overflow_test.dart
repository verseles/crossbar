// ignore_for_file: avoid_slow_async_io
import 'dart:io';

import 'package:crossbar/core/plugin_manager.dart';
import 'package:crossbar/services/settings_service.dart';
import 'package:crossbar/services/tray/tray_backend.dart';
import 'package:crossbar/services/tray/tray_menu_item.dart';
import 'package:crossbar/services/tray_service.dart';
import 'package:crossbar_core/crossbar_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Fake TrayBackend that records calls
class FakeTrayBackend implements TrayBackend {
  final List<String> calls = [];

  @override
  String get name => 'FakeTrayBackend';

  @override
  bool get supportsMultipleIcons => true;

  @override
  int get maxIcons => 10;

  @override
  bool get isInitialized => true;

  @override
  Future<bool> init() async {
    calls.add('init');
    return true;
  }

  @override
  Future<int?> createIcon({
    required String pluginId,
    required String iconPath,
    required String tooltip,
  }) async {
    calls.add('createIcon($pluginId)');
    return pluginId.hashCode;
  }

  @override
  Future<void> destroyIcon(int iconId) async {
    calls.add('destroyIcon($iconId)');
  }

  @override
  Future<void> updateIcon({
    required int iconId,
    String? iconPath,
    String? title,
    String? tooltip,
    List<TrayMenuItem>? menu,
  }) async {
    calls.add('updateIcon($iconId, $title)');
  }

  @override
  Future<void> dispose() async {
    calls.add('dispose');
  }

  // Not used but required by interface if any
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TrayService Smart Overflow', () {
    late TrayService trayService;
    late Directory tempDir;
    late FakeTrayBackend fakeBackend;
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

      // Reset SettingsService
      SettingsService().resetForTesting();
      SharedPreferences.setMockInitialValues({
        'tray_display_mode': 'smartOverflow',
        'tray_cluster_threshold': 2,
      });
      await SettingsService().init();

      // Setup PluginManager with dummy plugins directory
      tempDir = Directory.systemTemp.createTempSync();

      final pm = PluginManager();
      pm.customPluginsDirectory = tempDir.path;
      await pm.discoverPlugins(); // Should result in 0 plugins

      // Setup TrayService with FakeBackend
      trayService = TrayService();
      await trayService.dispose();

      fakeBackend = FakeTrayBackend();
      trayService.backendForTesting = fakeBackend;
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

    Future<void> createPluginFile(String name) async {
      final pluginFile = File('${tempDir.path}/$name');
      pluginFile.writeAsStringSync('#!/bin/bash\necho "test"');
      if (Platform.isLinux || Platform.isMacOS) {
        Process.runSync('chmod', ['+x', pluginFile.path]);
      }
    }

    test('should use separate mode when plugin count <= threshold', () async {
      if (!Platform.isLinux && !Platform.isMacOS && !Platform.isWindows) {
        return; // Skip on mobile
      }

      await createPluginFile('p1.sh');
      await PluginManager().discoverPlugins();

      // Initialize TrayService
      await trayService.init();

      // Add output for plugin
      final p1 = PluginManager().plugins.first;
      trayService.updatePluginOutput(
        p1.id,
        PluginOutput(pluginId: p1.id, text: 'P1', icon: '🚀'),
      );
      await Future.delayed(Duration.zero);

      // Expect: createIcon called (Separate Mode)
      // Because 1 plugin <= threshold 2
      expect(fakeBackend.calls, contains('createIcon(${p1.id})'));

      // Verify updateIcon called with title containing icon + text
      expect(fakeBackend.calls, contains(matches(r'updateIcon\(\d+, 🚀 P1\)')));
    });

    test('should switch to unified mode when plugin count > threshold', () async {
      if (!Platform.isLinux && !Platform.isMacOS && !Platform.isWindows) {
        return;
      }

      // Threshold is 2.
      await createPluginFile('p1.sh');
      await createPluginFile('p2.sh');
      await PluginManager().discoverPlugins();

      await trayService.init();

      // Should start in separate mode (2 <= 2)
      final p1 = PluginManager().plugins.firstWhere((p) => p.id == 'p1.sh');
      final p2 = PluginManager().plugins.firstWhere((p) => p.id == 'p2.sh');

      trayService.updatePluginOutput(
        p1.id,
        PluginOutput(pluginId: p1.id, text: 'P1', icon: '🚀'),
      );
      trayService.updatePluginOutput(
        p2.id,
        PluginOutput(pluginId: p2.id, text: 'P2', icon: '👾'),
      );
      await Future.delayed(Duration.zero);

      expect(fakeBackend.calls, contains('createIcon(${p1.id})'));
      expect(fakeBackend.calls, contains('createIcon(${p2.id})'));

      // Now add 3rd plugin
      await createPluginFile('p3.sh');
      await PluginManager().discoverPlugins(); // Rediscover

      await trayService.refreshMenu();

      // Now 3 plugins > threshold 2. Should switch to Unified.
      // Expect: destroyIcon called for p1 and p2
      expect(fakeBackend.calls, contains('destroyIcon(${p1.id.hashCode})'));
      expect(fakeBackend.calls, contains('destroyIcon(${p2.id.hashCode})'));

      // Also verify unified menu updated with plugins
      final contextMenuCalls = log.where((c) => c.method == 'setContextMenu');
      expect(contextMenuCalls, isNotEmpty);
    });

    test('should switch back to separate mode when plugin count decreases', () async {
      if (!Platform.isLinux && !Platform.isMacOS && !Platform.isWindows) {
        return;
      }

      // Threshold 2. Start with 3.
      await createPluginFile('p1.sh');
      await createPluginFile('p2.sh');
      await createPluginFile('p3.sh');
      await PluginManager().discoverPlugins();

      await trayService.init();

      // Trigger refresh to settle state (Unified)
      await trayService.refreshMenu();

      // Provide output for all
      final p1 = PluginManager().plugins.firstWhere((p) => p.id == 'p1.sh');
      trayService.updatePluginOutput(
        p1.id,
        PluginOutput(pluginId: p1.id, text: 'P1', icon: '🚀'),
      );
      await Future.delayed(Duration.zero);

      // Clear calls to focus on transition
      fakeBackend.calls.clear();

      // Remove P3
      final p3File = File('${tempDir.path}/p3.sh');
      p3File.deleteSync();
      await PluginManager().discoverPlugins();

      // Trigger refresh (simulate notification)
      await trayService.refreshMenu();

      // Now 2 plugins <= threshold 2. Should switch to Separate.
      // Expect: createIcon for p1
      expect(fakeBackend.calls, contains('createIcon(${p1.id})'));
    });
  });
}
