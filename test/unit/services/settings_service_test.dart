import 'package:crossbar/services/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsService', () {
    late SettingsService settingsService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      settingsService = SettingsService();
      settingsService.resetForTesting();
    });

    test('Initial values are correct (defaults)', () async {
      // We need to ensure init is called.
      // If a previous test called init, it returns early.
      await settingsService.init();

      expect(settingsService.darkMode, false);
      expect(settingsService.startWithSystem, false);
      expect(settingsService.showInTray, true);
      expect(settingsService.language, 'system');
    });

    test('Values are persisted', () async {
      await settingsService.init();

      settingsService.darkMode = true;
      expect(settingsService.darkMode, true);

      // Verify persistence
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('dark_mode'), true);

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

      expect(settingsService.trayDisplayMode, TrayDisplayMode.separate); // default
      expect(settingsService.trayClusterThreshold, 3); // default

      settingsService.trayDisplayMode = TrayDisplayMode.unified;
      expect(settingsService.trayDisplayMode, TrayDisplayMode.unified);

      settingsService.trayClusterThreshold = 5;
      expect(settingsService.trayClusterThreshold, 5);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('tray_display_mode'), 'unified');
      expect(prefs.getInt('tray_cluster_threshold'), 5);
    });
  });
}
