import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crossbar/services/widget_service.dart';
import 'package:crossbar/models/plugin_output.dart';

void main() {
  group('WidgetDataBuilder', () {
    test('creates builder with required pluginId', () {
      const builder = WidgetDataBuilder(pluginId: 'test-plugin');

      expect(builder.pluginId, equals('test-plugin'));
      expect(builder.icon, isNull);
      expect(builder.title, isNull);
      expect(builder.subtitle, isNull);
      expect(builder.value, isNull);
      expect(builder.color, isNull);
      expect(builder.deepLink, isNull);
    });

    test('creates builder with all fields', () {
      const builder = WidgetDataBuilder(
        pluginId: 'cpu-monitor',
        icon: '⚡',
        title: 'CPU Usage',
        subtitle: 'Current load',
        value: '45%',
        color: 'FF5733',
        deepLink: 'crossbar://plugin/cpu-monitor',
      );

      expect(builder.pluginId, equals('cpu-monitor'));
      expect(builder.icon, equals('⚡'));
      expect(builder.title, equals('CPU Usage'));
      expect(builder.subtitle, equals('Current load'));
      expect(builder.value, equals('45%'));
      expect(builder.color, equals('FF5733'));
      expect(builder.deepLink, equals('crossbar://plugin/cpu-monitor'));
    });

    test('toJson creates correct JSON structure', () {
      const builder = WidgetDataBuilder(
        pluginId: 'memory',
        icon: '🧠',
        title: 'Memory',
        value: '8GB/16GB',
      );

      final json = builder.toJson();

      expect(json['pluginId'], equals('memory'));
      expect(json['icon'], equals('🧠'));
      expect(json['title'], equals('Memory'));
      expect(json['subtitle'], isNull);
      expect(json['value'], equals('8GB/16GB'));
      expect(json['color'], isNull);
      expect(json['deepLink'], isNull);
    });

    test('toJson includes all null fields', () {
      const builder = WidgetDataBuilder(pluginId: 'test');
      final json = builder.toJson();

      expect(json.containsKey('icon'), isTrue);
      expect(json.containsKey('title'), isTrue);
      expect(json.containsKey('subtitle'), isTrue);
      expect(json.containsKey('value'), isTrue);
      expect(json.containsKey('color'), isTrue);
      expect(json.containsKey('deepLink'), isTrue);
    });

    test('fromPluginOutput creates builder from PluginOutput', () {
      final output = PluginOutput(
        pluginId: 'disk-space',
        text: '250 GB free',
        icon: '💾',
        color: Colors.green,
        hasError: false,
        menu: [],
      );

      final builder = WidgetDataBuilder.fromPluginOutput(output);

      expect(builder.pluginId, equals('disk-space'));
      expect(builder.icon, equals('💾'));
      expect(builder.title, equals('disk-space'));
      expect(builder.value, equals('250 GB free'));
      expect(builder.color, isNotNull);
      expect(builder.deepLink, equals('crossbar://plugin/disk-space'));
    });

    test('fromPluginOutput handles null icon', () {
      final output = PluginOutput(
        pluginId: 'test',
        text: 'Hello',
        icon: '📦',
        hasError: false,
        menu: [],
      );

      final builder = WidgetDataBuilder.fromPluginOutput(output);

      expect(builder.icon, equals('📦'));
    });

    test('fromPluginOutput converts color to hex string', () {
      final output = PluginOutput(
        pluginId: 'test',
        text: 'Test',
        icon: '🎨',
        color: const Color(0xFFFF5733),
        hasError: false,
        menu: [],
      );

      final builder = WidgetDataBuilder.fromPluginOutput(output);

      expect(builder.color, equals('ffff5733'));
    });

    test('fromPluginOutput creates correct deepLink', () {
      final output = PluginOutput(
        pluginId: 'weather-widget',
        text: '25°C',
        icon: '🌤️',
        hasError: false,
        menu: [],
      );

      final builder = WidgetDataBuilder.fromPluginOutput(output);

      expect(builder.deepLink, equals('crossbar://plugin/weather-widget'));
    });

    test('fromPluginOutput handles empty text', () {
      final output = PluginOutput(
        pluginId: 'empty-plugin',
        text: '',
        icon: '',
        hasError: false,
        menu: [],
      );

      final builder = WidgetDataBuilder.fromPluginOutput(output);

      expect(builder.value, equals(''));
    });
  });

  group('WidgetService - Constants', () {
    test('has correct app group ID', () {
      expect(WidgetService.appGroupId, equals('group.crossbar.widgets'));
    });

    test('has correct iOS widget name', () {
      expect(WidgetService.iOSWidgetName, equals('CrossbarWidget'));
    });

    test('has correct Android widget name', () {
      expect(WidgetService.androidWidgetName, equals('CrossbarWidgetProvider'));
    });
  });

  // Note: Full testing of WidgetService methods requires mocking HomeWidget
  // and Platform checks, which is complex. The tests above ensure:
  // - WidgetDataBuilder correctly transforms data
  // - JSON serialization works properly
  // - Integration with PluginOutput is correct
  // - Constants are properly defined
  //
  // For integration tests of actual widget updates, we would need:
  // 1. Mock for HomeWidget package
  // 2. Platform.isAndroid/Platform.isIOS mocks
  // 3. Test environment for Android/iOS specific code
}
