import 'package:flutter_test/flutter_test.dart';
import 'package:crossbar/models/plugin_config.dart';

void main() {
  group('PluginConfig', () {
    test('creates plugin config with required parameters', () {
      final config = PluginConfig(
        name: 'Weather Widget',
        description: 'Shows weather for your location',
        icon: '',
        configRequired: 'first_run',
        settings: [],
      );

      expect(config.name, 'Weather Widget');
      expect(config.description, 'Shows weather for your location');
      expect(config.icon, '');
      expect(config.configRequired, 'first_run');
      expect(config.settings, isEmpty);
    });

    test('creates plugin config with settings', () {
      final config = PluginConfig(
        name: 'Weather Widget',
        description: 'Shows weather',
        icon: '',
        configRequired: 'optional',
        settings: [
          const Setting(
            key: 'API_KEY',
            label: 'API Key',
            type: 'password',
            required: true,
          ),
          const Setting(
            key: 'LOCATION',
            label: 'Location',
            type: 'text',
            defaultValue: 'Auto',
          ),
        ],
      );

      expect(config.settings.length, 2);
      expect(config.settings[0].key, 'API_KEY');
      expect(config.settings[1].key, 'LOCATION');
    });

    test('serializes to JSON', () {
      final config = PluginConfig(
        name: 'Test Plugin',
        description: 'Test description',
        icon: '',
        configRequired: 'optional',
        settings: [
          const Setting(
            key: 'TEST_KEY',
            label: 'Test',
            type: 'text',
          ),
        ],
      );

      final json = config.toJson();

      expect(json['name'], 'Test Plugin');
      expect(json['description'], 'Test description');
      expect(json['config_required'], 'optional');
      expect(json['settings'], isA<List>());
      expect((json['settings'] as List).length, 1);
    });

    test('deserializes from JSON', () {
      final json = {
        'name': 'Test Plugin',
        'description': 'Test description',
        'icon': '',
        'config_required': 'first_run',
        'settings': [
          {
            'key': 'API_KEY',
            'label': 'API Key',
            'type': 'password',
            'required': true,
          },
        ],
      };

      final config = PluginConfig.fromJson(json);

      expect(config.name, 'Test Plugin');
      expect(config.description, 'Test description');
      expect(config.configRequired, 'first_run');
      expect(config.settings.length, 1);
      expect(config.settings[0].key, 'API_KEY');
      expect(config.settings[0].required, true);
    });

    test('deserializes from JSON with missing optional fields', () {
      final json = <String, dynamic>{};

      final config = PluginConfig.fromJson(json);

      expect(config.name, '');
      expect(config.description, '');
      expect(config.configRequired, 'optional');
      expect(config.settings, isEmpty);
    });

    test('copyWith creates new instance', () {
      final config = PluginConfig(
        name: 'Original',
        description: 'Original description',
        icon: '',
        configRequired: 'optional',
        settings: [],
      );

      final updated = config.copyWith(name: 'Updated');

      expect(updated.name, 'Updated');
      expect(updated.description, 'Original description');
      expect(config.name, 'Original');
    });

    test('toString returns readable representation', () {
      final config = PluginConfig(
        name: 'Test Plugin',
        description: 'Test',
        icon: '',
        configRequired: 'optional',
        settings: [
          const Setting(key: 'KEY', label: 'Label', type: 'text'),
        ],
      );

      expect(config.toString(), contains('Test Plugin'));
      expect(config.toString(), contains('1'));
    });
  });

  group('Setting', () {
    test('creates setting with required parameters', () {
      const setting = Setting(
        key: 'API_KEY',
        label: 'API Key',
        type: 'password',
      );

      expect(setting.key, 'API_KEY');
      expect(setting.label, 'API Key');
      expect(setting.type, 'password');
      expect(setting.required, false);
      expect(setting.defaultValue, isNull);
    });

    test('creates setting with all parameters', () {
      const setting = Setting(
        key: 'UNITS',
        label: 'Units',
        type: 'select',
        defaultValue: 'metric',
        required: true,
        options: {'metric': 'Celsius', 'imperial': 'Fahrenheit'},
        width: 50,
        placeholder: 'Select units',
        help: 'Choose temperature units',
      );

      expect(setting.key, 'UNITS');
      expect(setting.defaultValue, 'metric');
      expect(setting.required, true);
      expect(setting.options, isNotNull);
      expect(setting.width, 50);
      expect(setting.placeholder, 'Select units');
      expect(setting.help, 'Choose temperature units');
    });

    test('serializes to JSON', () {
      const setting = Setting(
        key: 'API_KEY',
        label: 'API Key',
        type: 'password',
        required: true,
        width: 100,
      );

      final json = setting.toJson();

      expect(json['key'], 'API_KEY');
      expect(json['label'], 'API Key');
      expect(json['type'], 'password');
      expect(json['required'], true);
      expect(json['width'], 100);
    });

    test('serializes to JSON omits null values', () {
      const setting = Setting(
        key: 'TEST',
        label: 'Test',
        type: 'text',
      );

      final json = setting.toJson();

      expect(json.containsKey('default'), false);
      expect(json.containsKey('options'), false);
      expect(json.containsKey('width'), false);
      expect(json.containsKey('placeholder'), false);
      expect(json.containsKey('help'), false);
    });

    test('deserializes from JSON', () {
      final json = {
        'key': 'API_KEY',
        'label': 'API Key',
        'type': 'password',
        'required': true,
        'default': 'default_value',
        'width': 75,
      };

      final setting = Setting.fromJson(json);

      expect(setting.key, 'API_KEY');
      expect(setting.label, 'API Key');
      expect(setting.type, 'password');
      expect(setting.required, true);
      expect(setting.defaultValue, 'default_value');
      expect(setting.width, 75);
    });

    test('copyWith creates new instance', () {
      const setting = Setting(
        key: 'TEST',
        label: 'Test',
        type: 'text',
        required: false,
      );

      final updated = setting.copyWith(required: true);

      expect(updated.key, 'TEST');
      expect(updated.required, true);
      expect(setting.required, false);
    });

    test('toString returns readable representation', () {
      const setting = Setting(
        key: 'API_KEY',
        label: 'API Key',
        type: 'password',
        required: true,
      );

      expect(setting.toString(), contains('API_KEY'));
      expect(setting.toString(), contains('password'));
      expect(setting.toString(), contains('true'));
    });
  });
}
