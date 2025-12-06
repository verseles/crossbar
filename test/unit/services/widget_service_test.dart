import 'package:crossbar/models/plugin_output.dart';
import 'package:crossbar/services/widget_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WidgetDataBuilder', () {
    test('serializes PluginOutput correctly', () {
      const output = PluginOutput(
        pluginId: 'test_plugin',
        text: 'Hello World',
        color: 0xFFF44336,
        icon: 'test_icon',
      );

      final builder = WidgetDataBuilder.fromPluginOutput(output);
      final json = builder.toJson();

      expect(json['pluginId'], 'test_plugin');
      expect(json['value'], 'Hello World');
      expect(json['color'], 'fff44336'); // toRadixString(16) of int value
      expect(json['icon'], 'test_icon');
      expect(json['deepLink'], 'crossbar://plugin/test_plugin');
    });

    test('handles null values correctly', () {
      const output = PluginOutput(
        pluginId: 'test_plugin',
        text: 'Value',
        icon: '',
        color: null,
      );

      final builder = WidgetDataBuilder.fromPluginOutput(output);
      final json = builder.toJson();

      expect(json['pluginId'], 'test_plugin');
      expect(json['value'], 'Value');
      expect(json['color'], null);
      expect(json['icon'], '');
    });
  });
}
