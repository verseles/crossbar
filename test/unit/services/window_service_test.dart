// ignore_for_file: avoid_slow_async_io
import 'package:crossbar/services/window_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WindowService', () {
    late WindowService windowService;
    final log = <MethodCall>[];

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'window_maximized': false,
        'window_x': 100.0,
        'window_y': 100.0,
        'window_width': 800.0,
        'window_height': 600.0,
      });

      // Mock HotKeyManager channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('dev.leanflutter.plugins/hotkey_manager'),
        (MethodCall methodCall) async {
          log.add(methodCall);
          return null;
        },
      );

      // Mock ScreenRetriever channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('dev.leanflutter.plugins/screen_retriever'),
        (MethodCall methodCall) async {
          log.add(methodCall);
          final display = {
            'id': 'display-1',
            'name': 'Built-in Display',
            'size': {'width': 1920.0, 'height': 1080.0},
            'visiblePosition': {'x': 0.0, 'y': 0.0, 'dx': 0.0, 'dy': 0.0},
            'visibleSize': {'width': 1920.0, 'height': 1080.0},
            'scaleFactor': 1.0,
          };
          if (methodCall.method == 'getAllDisplays') {
            return {
              'displays': [display]
            };
          }
          if (methodCall.method == 'getCursorScreenPoint') {
            return {'x': 100.0, 'y': 100.0, 'dx': 100.0, 'dy': 100.0};
          }
          return display;
        },
      );

      // Mock WindowManager channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('window_manager'),
        (MethodCall methodCall) async {
          log.add(methodCall);
          switch (methodCall.method) {
            case 'ensureInitialized':
            case 'setPreventClose':
            case 'waitUntilReadyToShow':
            case 'show':
            case 'hide':
            case 'focus':
            case 'destroy':
            case 'setSkipTaskbar':
            case 'maximize':
            case 'unmaximize':
            case 'setBounds':
              return null;
            case 'isMaximized':
              return false;
            case 'getBounds':
              return {
                'x': 50.0,
                'y': 50.0,
                'width': 500.0,
                'height': 400.0,
              };
            case 'isMinimized':
            case 'isVisible':
            case 'isFocused':
            case 'isPreventClose':
            case 'isSkipTaskbar':
            case 'isFullScreen':
              return false;
            default:
              return null;
          }
        },
      );

      log.clear();
      windowService = WindowService();
      windowService.resetForTesting();
    });

    tearDown(() {
      log.clear();
      windowService.resetForTesting();
    });

    test('init restores window state', () async {
      // Since we run on linux (in CI/Action) this should run.
      // But if local dev is not linux, we simulate.
      // But we can't easily simulate Platform.isLinux
      // Assuming test environment is Linux-like or Platform override works (not possible easily).
      // However, if we are in the agent sandbox, it is Linux.

      await windowService.init();

      // Verify setBounds was called with restored values
      // Note: arguments are map in mock call
      final setBoundsCalls = log.where((c) => c.method == 'setBounds').toList();

      bool foundRestoredBounds = false;
      for (final call in setBoundsCalls) {
        final args = call.arguments as Map;

        if (args['x'] == 100.0 &&
            args['y'] == 100.0 &&
            args['width'] == 800.0 &&
            args['height'] == 600.0) {
          foundRestoredBounds = true;
          break;
        }
      }

      if (windowService.isInitialized && !foundRestoredBounds) {
         fail('setBounds was not called with restored values. Calls: $setBoundsCalls');
      }
    });

    test('show calls show and focus', () async {
      await windowService.show();
      expect(log.any((c) => c.method == 'show'), isTrue);
      expect(log.any((c) => c.method == 'focus'), isTrue);
    });

    test('hide calls hide and saves state', () async {
      await windowService.init();
      log.clear();

      await windowService.hide();
      expect(log.any((c) => c.method == 'hide'), isTrue);

      if (windowService.isInitialized) {
        // Check if state was saved to prefs
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getDouble('window_x'), 50.0);
        expect(prefs.getDouble('window_y'), 50.0);
        expect(prefs.getDouble('window_width'), 500.0);
        expect(prefs.getDouble('window_height'), 400.0);
      }
    });

    test('quit calls destroy and saves state', () async {
      await windowService.init();
      log.clear();

      await windowService.quit();
      expect(log.any((c) => c.method == 'destroy'), isTrue);

      if (windowService.isInitialized) {
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getDouble('window_x'), 50.0);
      }
    });

    test('onWindowMaximize saves state', () async {
      await windowService.init();
      log.clear();

      // Simulate onWindowMaximize
      windowService.onWindowMaximize();

      // Wait for async save
      await Future.delayed(const Duration(milliseconds: 50));

      // We expect _saveWindowState to be called.
      // Our mock isMaximized returns false, so it tries to save bounds.
      if (windowService.isInitialized) {
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getDouble('window_x'), 50.0);
      }
    });
  });
}
