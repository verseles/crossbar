import 'package:crossbar/services/window_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WindowService', () {
    late WindowService windowService;
    final List<MethodCall> log = <MethodCall>[];

    setUp(() async {
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
              return null;
            case 'isMinimized':
            case 'isVisible':
            case 'isFocused':
            case 'isPreventClose':
            case 'isSkipTaskbar':
              return false;
            default:
              return null;
          }
        },
      );

      log.clear();
      windowService = WindowService();
    });

    tearDown(() {
      log.clear();
    });

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
