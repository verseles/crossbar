import 'package:crossbar/models/plugin_metadata.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PluginLanguage', () {
    group('fromId', () {
      test('returns correct language for valid ids', () {
        expect(PluginLanguage.fromId('lua'), PluginLanguage.lua);
        expect(PluginLanguage.fromId('bash'), PluginLanguage.bash);
        expect(PluginLanguage.fromId('python'), PluginLanguage.python);
        expect(PluginLanguage.fromId('node'), PluginLanguage.node);
        expect(PluginLanguage.fromId('dart'), PluginLanguage.dart);
        expect(PluginLanguage.fromId('go'), PluginLanguage.go);
        expect(PluginLanguage.fromId('rust'), PluginLanguage.rust);
        expect(PluginLanguage.fromId('yaml'), PluginLanguage.yaml);
      });

      test('returns null for invalid id', () {
        expect(PluginLanguage.fromId('invalid'), isNull);
        expect(PluginLanguage.fromId(''), isNull);
        expect(PluginLanguage.fromId('PHP'), isNull);
      });
    });

    group('fromExtension', () {
      test('returns correct language for valid extensions', () {
        expect(PluginLanguage.fromExtension('lua'), PluginLanguage.lua);
        expect(PluginLanguage.fromExtension('sh'), PluginLanguage.bash);
        expect(PluginLanguage.fromExtension('py'), PluginLanguage.python);
        expect(PluginLanguage.fromExtension('js'), PluginLanguage.node);
        expect(PluginLanguage.fromExtension('dart'), PluginLanguage.dart);
        expect(PluginLanguage.fromExtension('go'), PluginLanguage.go);
        expect(PluginLanguage.fromExtension('rs'), PluginLanguage.rust);
        expect(PluginLanguage.fromExtension('yaml'), PluginLanguage.yaml);
        expect(PluginLanguage.fromExtension('yml'), PluginLanguage.yaml);
      });

      test('returns null for invalid extension', () {
        expect(PluginLanguage.fromExtension('invalid'), isNull);
        expect(PluginLanguage.fromExtension(''), isNull);
        expect(PluginLanguage.fromExtension('php'), isNull);
      });
    });

    test('has correct properties', () {
      expect(PluginLanguage.lua.id, 'lua');
      expect(PluginLanguage.lua.icon, '🌙');
      expect(PluginLanguage.lua.displayName, 'Lua');

      expect(PluginLanguage.yaml.id, 'yaml');
      expect(PluginLanguage.yaml.icon, '📄');
      expect(PluginLanguage.yaml.displayName, 'YAML (No-Code)');
    });
  });

  group('PluginCategory', () {
    group('fromId', () {
      test('returns correct category for valid ids', () {
        expect(PluginCategory.fromId('system'), PluginCategory.system);
        expect(PluginCategory.fromId('time'), PluginCategory.time);
        expect(PluginCategory.fromId('network'), PluginCategory.network);
        expect(PluginCategory.fromId('development'), PluginCategory.development);
        expect(PluginCategory.fromId('productivity'), PluginCategory.productivity);
        expect(PluginCategory.fromId('finance'), PluginCategory.finance);
        expect(PluginCategory.fromId('fun'), PluginCategory.fun);
        expect(PluginCategory.fromId('other'), PluginCategory.other);
      });

      test('returns other for invalid id', () {
        expect(PluginCategory.fromId('invalid'), PluginCategory.other);
        expect(PluginCategory.fromId(''), PluginCategory.other);
      });
    });

    test('has correct properties', () {
      expect(PluginCategory.system.id, 'system');
      expect(PluginCategory.system.icon, '🖥️');
      expect(PluginCategory.system.displayName, 'System');
    });
  });

  group('PluginMetadataVariant', () {
    test('stores properties correctly', () {
      const variant = PluginMetadataVariant(
        language: PluginLanguage.lua,
        filename: 'cpu.lua',
        assetPath: 'plugins/cpu.lua',
        schemaAssetPath: 'plugins/cpu.lua.schema.json',
      );

      expect(variant.language, PluginLanguage.lua);
      expect(variant.filename, 'cpu.lua');
      expect(variant.assetPath, 'plugins/cpu.lua');
      expect(variant.schemaAssetPath, 'plugins/cpu.lua.schema.json');
    });

    test('schemaAssetPath is optional', () {
      const variant = PluginMetadataVariant(
        language: PluginLanguage.bash,
        filename: 'cpu.sh',
        assetPath: 'plugins/cpu.sh',
      );

      expect(variant.schemaAssetPath, isNull);
    });
  });

  group('PluginMetadata', () {
    late PluginMetadata pluginWithMultipleVariants;
    late PluginMetadata pluginWithSingleVariant;

    setUp(() {
      pluginWithMultipleVariants = const PluginMetadata(
        id: 'cpu',
        name: 'CPU Monitor',
        description: 'Shows CPU usage',
        category: PluginCategory.system,
        variants: [
          PluginMetadataVariant(
            language: PluginLanguage.bash,
            filename: 'cpu.sh',
            assetPath: 'plugins/cpu.sh',
          ),
          PluginMetadataVariant(
            language: PluginLanguage.lua,
            filename: 'cpu.lua',
            assetPath: 'plugins/cpu.lua',
          ),
          PluginMetadataVariant(
            language: PluginLanguage.python,
            filename: 'cpu.py',
            assetPath: 'plugins/cpu.py',
          ),
        ],
        tags: ['system', 'monitoring'],
        configRequired: false,
        mobileCompatible: true,
      );

      pluginWithSingleVariant = const PluginMetadata(
        id: 'weather',
        name: 'Weather',
        description: 'Shows weather info',
        category: PluginCategory.other,
        variants: [
          PluginMetadataVariant(
            language: PluginLanguage.node,
            filename: 'weather.js',
            assetPath: 'plugins/weather.js',
          ),
        ],
      );
    });

    test('stores properties correctly', () {
      expect(pluginWithMultipleVariants.id, 'cpu');
      expect(pluginWithMultipleVariants.name, 'CPU Monitor');
      expect(pluginWithMultipleVariants.description, 'Shows CPU usage');
      expect(pluginWithMultipleVariants.category, PluginCategory.system);
      expect(pluginWithMultipleVariants.tags, ['system', 'monitoring']);
      expect(pluginWithMultipleVariants.configRequired, false);
      expect(pluginWithMultipleVariants.mobileCompatible, true);
    });

    test('default values are correct', () {
      expect(pluginWithSingleVariant.tags, isEmpty);
      expect(pluginWithSingleVariant.configRequired, false);
      expect(pluginWithSingleVariant.mobileCompatible, false);
    });

    group('availableLanguages', () {
      test('returns list of all variant languages', () {
        final languages = pluginWithMultipleVariants.availableLanguages;

        expect(languages, hasLength(3));
        expect(languages, contains(PluginLanguage.bash));
        expect(languages, contains(PluginLanguage.lua));
        expect(languages, contains(PluginLanguage.python));
      });
    });

    group('getVariant', () {
      test('returns variant for existing language', () {
        final variant = pluginWithMultipleVariants.getVariant(PluginLanguage.lua);

        expect(variant, isNotNull);
        expect(variant!.language, PluginLanguage.lua);
        expect(variant.filename, 'cpu.lua');
      });

      test('returns null for non-existing language', () {
        final variant = pluginWithMultipleVariants.getVariant(PluginLanguage.rust);

        expect(variant, isNull);
      });
    });

    group('defaultVariant', () {
      test('prefers Lua when available', () {
        final variant = pluginWithMultipleVariants.defaultVariant;

        expect(variant.language, PluginLanguage.lua);
      });

      test('falls back to first variant if no preferred language', () {
        final variant = pluginWithSingleVariant.defaultVariant;

        expect(variant.language, PluginLanguage.node);
      });
    });

    group('categoryIcon', () {
      test('returns category icon', () {
        expect(pluginWithMultipleVariants.categoryIcon, '🖥️');
        expect(pluginWithSingleVariant.categoryIcon, '📦');
      });
    });

    group('hasLanguage', () {
      test('returns true for existing language', () {
        expect(pluginWithMultipleVariants.hasLanguage(PluginLanguage.lua), true);
        expect(pluginWithMultipleVariants.hasLanguage(PluginLanguage.bash), true);
      });

      test('returns false for non-existing language', () {
        expect(pluginWithMultipleVariants.hasLanguage(PluginLanguage.rust), false);
        expect(pluginWithMultipleVariants.hasLanguage(PluginLanguage.yaml), false);
      });
    });
  });
}
