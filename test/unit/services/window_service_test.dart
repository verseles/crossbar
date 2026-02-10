// ignore_for_file: avoid_slow_async_io
import 'package:crossbar/services/window_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WindowService', () {
    late WindowService windowService;
    final log = <MethodCall>[];

    setUp(() async {
      // Mock HotKeyManager channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('hotkey_manager'),
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
            case 'setPosition':
              return null;
            case 'isMinimized':
            case 'isVisible':
            case 'isFocused':
            case 'isPreventClose':
            case 'isSkipTaskbar':
              return false;
            case 'getBounds':
              return {
                'x': 100.0,
                'y': 100.0,
                'width': 800.0,
                'height': 600.0,
              };
            default:
              return null;
          }
        },
      );

      log.clear();
      windowService = WindowService();
    });

    tearDown(log.clear);

    test('show calls show and focus', () async {
      await windowService.show();
      expect(log.any((c) => c.method == 'show'), isTrue);
      expect(log.any((c) => c.method == 'focus'), isTrue);
    });

    test('hide calls hide', () async {
      await windowService.hide();
      expect(log.any((c) => c.method == 'hide'), isTrue);
    });

    test('quit calls destroy', () async {
      await windowService.quit();
      expect(log.any((c) => c.method == 'destroy'), isTrue);
    });
  });
}
