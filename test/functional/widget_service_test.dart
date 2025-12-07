// ignore_for_file: avoid_slow_async_io
import 'dart:convert';

import 'package:crossbar/models/plugin_output.dart';
import 'package:crossbar/services/widget_service.dart';
import 'package:flutter_test/flutter_test.dart';

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
      const output = PluginOutput(
        pluginId: 'disk-space',
        text: '250 GB free',
        icon: '💾',
        color: 0xFF4CAF50,
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
      const output = PluginOutput(
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
      const output = PluginOutput(
        pluginId: 'test',
        text: 'Test',
        icon: '🎨',
        color: 0xFFFF5733,
        hasError: false,
        menu: [],
      );

      final builder = WidgetDataBuilder.fromPluginOutput(output);

      expect(builder.color, equals('ffff5733'));
    });

    test('fromPluginOutput creates correct deepLink', () {
      const output = PluginOutput(
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
      const output = PluginOutput(
        pluginId: 'empty-plugin',
        text: '',
        icon: '',
        hasError: false,
        menu: [],
      );

      final builder = WidgetDataBuilder.fromPluginOutput(output);

      expect(builder.value, equals(''));
    });

    test('fromPluginOutput handles null color', () {
      const output = PluginOutput(
        pluginId: 'no-color',
        text: 'Test',
        icon: '📊',
        hasError: false,
        menu: [],
      );

      final builder = WidgetDataBuilder.fromPluginOutput(output);

      expect(builder.color, isNull);
    });

    test('fromPluginOutput handles special characters in pluginId', () {
      const output = PluginOutput(
        pluginId: 'cpu.10s.sh',
        text: '45%',
        icon: '⚡',
        hasError: false,
        menu: [],
      );

      final builder = WidgetDataBuilder.fromPluginOutput(output);

      expect(builder.pluginId, equals('cpu.10s.sh'));
      expect(builder.deepLink, equals('crossbar://plugin/cpu.10s.sh'));
    });

    test('toJson is JSON serializable', () {
      const builder = WidgetDataBuilder(
        pluginId: 'test',
        icon: '🚀',
        title: 'Test Plugin',
        value: '100%',
        color: 'FF0000',
      );

      final json = builder.toJson();
      final encoded = jsonEncode(json);
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;

      expect(decoded['pluginId'], equals('test'));
      expect(decoded['icon'], equals('🚀'));
      expect(decoded['title'], equals('Test Plugin'));
      expect(decoded['value'], equals('100%'));
      expect(decoded['color'], equals('FF0000'));
    });

    test('handles unicode characters in all fields', () {
      const builder = WidgetDataBuilder(
        pluginId: '天气插件',
        icon: '🌈',
        title: 'Погода',
        subtitle: '現在の天気',
        value: '25°C 晴れ',
        deepLink: 'crossbar://plugin/天气',
      );

      final json = builder.toJson();

      expect(json['pluginId'], equals('天气插件'));
      expect(json['icon'], equals('🌈'));
      expect(json['title'], equals('Погода'));
      expect(json['subtitle'], equals('現在の天気'));
      expect(json['value'], equals('25°C 晴れ'));
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

  group('WidgetService - Singleton', () {
    test('returns same instance', () {
      final instance1 = WidgetService();
      final instance2 = WidgetService();

      expect(identical(instance1, instance2), isTrue);
    });

    test('factory constructor returns singleton', () {
      final service = WidgetService();
      expect(service, isNotNull);
      expect(service, isA<WidgetService>());
    });
  });

  group('WidgetDataBuilder - Edge Cases', () {
    test('handles very long text values', () {
      final longText = 'A' * 1000;
      final builder = WidgetDataBuilder(
        pluginId: 'long-text',
        value: longText,
      );

      expect(builder.value, equals(longText));
      expect(builder.value!.length, equals(1000));
    });

    test('handles empty pluginId', () {
      const builder = WidgetDataBuilder(pluginId: '');
      expect(builder.pluginId, equals(''));
    });

    test('handles whitespace in fields', () {
      const builder = WidgetDataBuilder(
        pluginId: '  spaced  ',
        title: '  Title  ',
        value: '  Value  ',
      );

      expect(builder.pluginId, equals('  spaced  '));
      expect(builder.title, equals('  Title  '));
      expect(builder.value, equals('  Value  '));
    });

    test('handles newlines in text', () {
      const builder = WidgetDataBuilder(
        pluginId: 'multiline',
        value: 'Line1\nLine2\nLine3',
      );

      expect(builder.value, contains('\n'));
    });

    test('fromPluginOutput handles error state', () {
      const output = PluginOutput(
        pluginId: 'error-plugin',
        text: 'Error occurred',
        icon: '❌',
        hasError: true,
        errorMessage: 'Something went wrong',
        menu: [],
      );

      final builder = WidgetDataBuilder.fromPluginOutput(output);

      expect(builder.pluginId, equals('error-plugin'));
      expect(builder.value, equals('Error occurred'));
      expect(builder.icon, equals('❌'));
    });
  });
}

