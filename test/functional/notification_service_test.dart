import 'package:crossbar/services/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PluginNotificationConfig', () {
    test('defaults to disabled with error notifications only', () {
      const config = PluginNotificationConfig();

      expect(config.enabled, isFalse);
      expect(config.onError, isTrue);
      expect(config.onOutput, isFalse);
      expect(config.onThreshold, isFalse);
      expect(config.threshold, isNull);
      expect(config.priority, equals(NotificationPriority.normal));
    });

    test('fromJson creates config with defaults for missing fields', () {
      final config = PluginNotificationConfig.fromJson({});

      expect(config.enabled, isFalse);
      expect(config.onError, isTrue);
      expect(config.onOutput, isFalse);
      expect(config.onThreshold, isFalse);
      expect(config.threshold, isNull);
      expect(config.priority, equals(NotificationPriority.normal));
    });

    test('fromJson parses all fields correctly', () {
      final config = PluginNotificationConfig.fromJson({
        'enabled': true,
        'onError': false,
        'onOutput': true,
        'onThreshold': true,
        'threshold': 80.5,
        'priority': 'high',
      });

      expect(config.enabled, isTrue);
      expect(config.onError, isFalse);
      expect(config.onOutput, isTrue);
      expect(config.onThreshold, isTrue);
      expect(config.threshold, equals(80.5));
      expect(config.priority, equals(NotificationPriority.high));
    });

    test('fromJson handles invalid priority gracefully', () {
      final config = PluginNotificationConfig.fromJson({
        'priority': 'invalid',
      });

      expect(config.priority, equals(NotificationPriority.normal));
    });

    test('toJson creates correct JSON structure', () {
      const config = PluginNotificationConfig(
        enabled: true,
        onError: false,
        onOutput: true,
        onThreshold: true,
        threshold: 90.0,
        priority: NotificationPriority.high,
      );

      final json = config.toJson();

      expect(json['enabled'], isTrue);
      expect(json['onError'], isFalse);
      expect(json['onOutput'], isTrue);
      expect(json['onThreshold'], isTrue);
      expect(json['threshold'], equals(90.0));
      expect(json['priority'], equals('high'));
    });

    test('toJson roundtrip preserves data', () {
      const original = PluginNotificationConfig(
        enabled: true,
        onOutput: true,
        threshold: 75.0,
        priority: NotificationPriority.low,
      );

      final json = original.toJson();
      final restored = PluginNotificationConfig.fromJson(json);

      expect(restored.enabled, equals(original.enabled));
      expect(restored.onError, equals(original.onError));
      expect(restored.onOutput, equals(original.onOutput));
      expect(restored.onThreshold, equals(original.onThreshold));
      expect(restored.threshold, equals(original.threshold));
      expect(restored.priority, equals(original.priority));
    });

    test('copyWith creates new instance with updated fields', () {
      const original = PluginNotificationConfig(
        enabled: false,
        onError: true,
        priority: NotificationPriority.normal,
      );

      final updated = original.copyWith(
        enabled: true,
        priority: NotificationPriority.high,
      );

      expect(updated.enabled, isTrue);
      expect(updated.onError, isTrue); // Unchanged
      expect(updated.priority, equals(NotificationPriority.high));
    });

    test('copyWith with no arguments returns equal config', () {
      const original = PluginNotificationConfig(
        enabled: true,
        threshold: 50.0,
      );

      final copied = original.copyWith();

      expect(copied.enabled, equals(original.enabled));
      expect(copied.onError, equals(original.onError));
      expect(copied.onOutput, equals(original.onOutput));
      expect(copied.onThreshold, equals(original.onThreshold));
      expect(copied.threshold, equals(original.threshold));
      expect(copied.priority, equals(original.priority));
    });

    test('copyWith can update threshold value', () {
      const original = PluginNotificationConfig(threshold: 80.0);
      final updated = original.copyWith(threshold: 95.5);

      expect(updated.threshold, equals(95.5));
    });
  });

  group('NotificationPriority', () {
    test('has correct values', () {
      expect(NotificationPriority.values.length, equals(3));
      expect(NotificationPriority.values, contains(NotificationPriority.low));
      expect(NotificationPriority.values, contains(NotificationPriority.normal));
      expect(NotificationPriority.values, contains(NotificationPriority.high));
    });

    test('enum names match expected strings', () {
      expect(NotificationPriority.low.name, equals('low'));
      expect(NotificationPriority.normal.name, equals('normal'));
      expect(NotificationPriority.high.name, equals('high'));
    });
  });

  group('NotificationService - Constants', () {
    test('has correct channel constants', () {
      expect(NotificationService.channelId, equals('crossbar_plugins'));
      expect(NotificationService.channelName, equals('Plugin Notifications'));
      expect(NotificationService.channelDescription, equals('Notifications from Crossbar plugins'));
    });
  });

  // Note: We cannot fully test NotificationService methods without mocking
  // FlutterLocalNotificationsPlugin, which would require extensive setup.
  // The config and priority classes have been thoroughly tested above.
  // For integration testing of the actual notification service, we would need:
  // 1. A mock for FlutterLocalNotificationsPlugin
  // 2. Platform-specific testing environment
  // 3. Permission handling mocks
  //
  // The current tests ensure that:
  // - Configuration serialization works correctly
  // - Priority enum is properly defined
  // - Constants are correct
  // - Business logic in config handling is sound
}
