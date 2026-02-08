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
      SharedPreferences.setMockInitialValues({});

      // Mock HotKeyManager channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('dev.leanflutter.plugins/hotkey_manager'),
        (MethodCall methodCall) async {
          log.add(methodCall);
          return null;
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
            case 'setBounds':
              return null;
            case 'getBounds':
              return {
                'x': 100.0,
                'y': 200.0,
                'width': 800.0,
                'height': 600.0,
              };
            case 'isMinimized':
            case 'isVisible':
            case 'isFocused':
            case 'isPreventClose':
            case 'isSkipTaskbar':
            case 'isFullScreen':
            case 'isMaximized':
              return false;
            default:
              if (methodCall.method.startsWith('is')) {
                return false;
              }
              return null;
          }
        },
      );

      log.clear();
      windowService = WindowService();
      windowService.resetForTesting();
    });

    tearDown(log.clear);

    test('show calls show and focus', () async {
      await windowService.show();
      expect(log.any((c) => c.method == 'show'), isTrue);
      expect(log.any((c) => c.method == 'focus'), isTrue);
    });

    test('hide calls hide and saves state', () async {
      await windowService.hide();
      expect(log.any((c) => c.method == 'hide'), isTrue);
      expect(log.any((c) => c.method == 'getBounds'), isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('window_x'), 100.0);
      expect(prefs.getDouble('window_y'), 200.0);
      expect(prefs.getDouble('window_width'), 800.0);
      expect(prefs.getDouble('window_height'), 600.0);
    });

    test('quit calls destroy and saves state', () async {
      await windowService.quit();
      expect(log.any((c) => c.method == 'destroy'), isTrue);
      expect(log.any((c) => c.method == 'getBounds'), isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('window_x'), 100.0);
      expect(prefs.getDouble('window_y'), 200.0);
      expect(prefs.getDouble('window_width'), 800.0);
      expect(prefs.getDouble('window_height'), 600.0);
    });

    test('init restores window bounds from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'window_x': 50.0,
        'window_y': 60.0,
        'window_width': 700.0,
        'window_height': 450.0,
      });

      await windowService.init();
      // Wait for async callback in waitUntilReadyToShow (which is typed as VoidCallback and thus not awaited by the library)
      await Future.delayed(const Duration(milliseconds: 50));

      // Verify setBounds is called
      final setBoundsCalls = log.where((c) => c.method == 'setBounds');
      expect(setBoundsCalls.isNotEmpty, isTrue);

      // Check if any call has the correct values
      // window_manager implementation details might vary, so we look for our values

      // If we didn't find exact match, let's see what we found
      // Since window_manager seems to map setPosition to setBounds channel call
      // We should verify at least one call sets position correctly.

      // Actually, let's just assert that we saw the values we expected in some calls.
      final hasSize = setBoundsCalls.any((c) {
        final args = c.arguments as Map;
        return args['width'] == 700.0 && args['height'] == 450.0;
      });

      final hasPosition = setBoundsCalls.any((c) {
        final args = c.arguments as Map;
        return args['x'] == 50.0 && args['y'] == 60.0;
      });

      expect(hasSize, isTrue, reason: 'Should have set size to 700x450');

      // If setPosition maps to setBounds, it should have x and y
      if (!hasPosition) {
         // Maybe setPosition uses 'position' key?
         final hasPositionKey = setBoundsCalls.any((c) {
            final args = c.arguments as Map;
            final pos = args['position'];
            if (pos is Map) {
                return pos['x'] == 50.0 && pos['y'] == 60.0;
            }
            return false;
         });

         if (hasPositionKey) {
             // Great
         } else {
             // Fail if strict, or maybe pass if we trust the logic but verification fails due to mock implementation limits
             // But we want to verify.
             expect(hasPosition, isTrue, reason: 'Should have set position to 50,60');
         }
      }
    });
  });
}
