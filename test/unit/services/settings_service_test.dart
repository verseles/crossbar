// ignore_for_file: avoid_slow_async_io
import 'package:crossbar/services/settings_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsService', () {
    late SettingsService settingsService;

    setUp(() async {
      // Mock HotKeyManager channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('hotkey_manager'),
        (MethodCall methodCall) async {
          return null;
        },
      );

      // Mock WindowManager channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('window_manager'),
        (MethodCall methodCall) async {
          return null;
        },
      );

      SharedPreferences.setMockInitialValues({});
      settingsService = SettingsService();
      settingsService.resetForTesting();
    });

    test('Initial values are correct (defaults)', () async {
      // We need to ensure init is called.
      // If a previous test called init, it returns early.
      await settingsService.init();

      expect(settingsService.themeMode, ThemeModeOption.system);
      expect(settingsService.startWithSystem, false);
      expect(settingsService.showInTray, true);
      expect(settingsService.language, 'system');
    });

    test('Values are persisted', () async {
      await settingsService.init();

      settingsService.themeMode = ThemeModeOption.dark;
      expect(settingsService.themeMode, ThemeModeOption.dark);

      // Verify persistence
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'dark');

      settingsService.language = 'pt_BR';
      expect(settingsService.language, 'pt_BR');
      expect(prefs.getString('language'), 'pt_BR');
    });

     test('Listeners are notified', () async {
      await settingsService.init();

      var notified = false;
      settingsService.addListener(() {
        notified = true;
      });

      settingsService.showInTray = false;

      expect(notified, true);
      expect(settingsService.showInTray, false);
    });

    test('Tray settings are persisted', () async {
      await settingsService.init();

      expect(settingsService.trayDisplayMode, TrayDisplayMode.unified); // default
      expect(settingsService.trayClusterThreshold, 3); // default

      settingsService.trayDisplayMode = TrayDisplayMode.separate;
      expect(settingsService.trayDisplayMode, TrayDisplayMode.separate);

      settingsService.trayClusterThreshold = 5;
      expect(settingsService.trayClusterThreshold, 5);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('tray_display_mode'), 'separate');
      expect(prefs.getInt('tray_cluster_threshold'), 5);
    });

    test('Global hotkey settings are persisted', () async {
      await settingsService.init();

      expect(settingsService.globalHotkeyEnabled, true); // default

      settingsService.globalHotkeyEnabled = false;
      expect(settingsService.globalHotkeyEnabled, false);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('global_hotkey_enabled'), false);
    });

    test('Window rect is persisted', () async {
      await settingsService.init();

      expect(settingsService.windowRect, isNull);

      const rect = Rect.fromLTWH(100, 200, 800, 600);
      await settingsService.saveWindowRect(rect);

      expect(settingsService.windowRect, rect);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('window_x'), 100);
      expect(prefs.getDouble('window_y'), 200);
      expect(prefs.getDouble('window_width'), 800);
      expect(prefs.getDouble('window_height'), 600);
    });
  });
}
