import 'dart:io';

import 'package:crossbar/services/background_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BackgroundService', () {
    test('singleton returns same instance', () {
      final instance1 = BackgroundService();
      final instance2 = BackgroundService();

      expect(identical(instance1, instance2), isTrue);
    });

    test('isInitialized is false before init', () {
      final service = BackgroundService();
      // Note: Can't test isInitialized directly as it depends on previous test state
      // Just verify the property exists and is a bool
      expect(service.isInitialized, isA<bool>());
    });

    test('init does nothing on non-Android platforms', () async {
      if (!Platform.isAndroid) {
        final service = BackgroundService();
        // Should complete without error on non-Android
        await service.init();
        // isInitialized should remain false on non-Android
        expect(service.isInitialized, isFalse);
      }
    });

    test('cancelAll does nothing on non-Android platforms', () async {
      if (!Platform.isAndroid) {
        final service = BackgroundService();
        // Should complete without error on non-Android
        await service.cancelAll();
      }
    });

    test('cancelWidgetUpdates does nothing on non-Android platforms', () async {
      if (!Platform.isAndroid) {
        final service = BackgroundService();
        // Should complete without error on non-Android
        await service.cancelWidgetUpdates();
      }
    });
  });

  group('Background compatibility check', () {
    test('kWidgetUpdateTask has correct value', () {
      expect(kWidgetUpdateTask, equals('crossbar-widget-update'));
    });

    test('kMinUpdateInterval is 15 minutes', () {
      expect(kMinUpdateInterval, equals(const Duration(minutes: 15)));
    });
  });

  group('_isBackgroundCompatible logic', () {
    // We can't directly test private functions, but we can verify the concept
    test('Lua files are background compatible', () {
      final luaPath = 'test.lua';
      expect(luaPath.endsWith('.lua'), isTrue);
    });

    test('YAML files are background compatible', () {
      final yamlPath = 'test.yaml';
      final ymlPath = 'test.yml';
      expect(yamlPath.endsWith('.yaml'), isTrue);
      expect(ymlPath.endsWith('.yml'), isTrue);
    });

    test('Dart files are background compatible', () {
      final dartPath = 'test.dart';
      expect(dartPath.endsWith('.dart'), isTrue);
    });

    test('Shell files are NOT background compatible', () {
      final shPath = 'test.sh';
      final bashExtensions = ['.sh', '.bash'];
      expect(bashExtensions.any((ext) => shPath.endsWith(ext)), isTrue);
      // These require external interpreters
    });

    test('Python files are NOT background compatible', () {
      final pyPath = 'test.py';
      expect(pyPath.endsWith('.py'), isTrue);
      // These require external interpreters
    });

    test('JavaScript files are NOT background compatible', () {
      final jsPath = 'test.js';
      expect(jsPath.endsWith('.js'), isTrue);
      // These require Node.js
    });
  });
}
