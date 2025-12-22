// ignore_for_file: avoid_slow_async_io
// import 'package:crossbar/models/plugin_metadata.dart'; // Exported by sample_plugins_service
import 'package:crossbar/services/sample_plugins_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SamplePluginsService', () {
    late SamplePluginsService service;

    setUp(() {
      service = SamplePluginsService();
    });

    group('Static Data', () {
      test('universalPlugins is not empty', () {
        expect(SamplePluginsService.universalPlugins, isNotEmpty);
      });

      test('legacyPlugins is not empty', () {
        expect(SamplePluginsService.legacyPlugins, isNotEmpty);
      });

      test('allPlugins combines universal and legacy', () {
        final all = SamplePluginsService.allPlugins;
        final expectedCount = SamplePluginsService.universalPlugins.length +
            SamplePluginsService.legacyPlugins.length;

        expect(all.length, equals(expectedCount));
      });

      test('all plugins have valid IDs', () {
        for (final plugin in SamplePluginsService.allPlugins) {
          expect(plugin.id, isNotEmpty);
          expect(plugin.id, isNot(contains(' ')));
        }
      });

      test('all plugins have at least one variant', () {
        for (final plugin in SamplePluginsService.allPlugins) {
          expect(plugin.variants, isNotEmpty,
              reason: 'Plugin ${plugin.id} has no variants');
        }
      });

      test('all variants have valid asset paths', () {
        for (final plugin in SamplePluginsService.allPlugins) {
          for (final variant in plugin.variants) {
            expect(variant.assetPath, isNotEmpty);
            expect(variant.assetPath, startsWith('plugins/'));
          }
        }
      });

      test('most universal plugins have multiple language variants', () {
        // Most universal plugins should have multiple variants
        // network-status is an exception (YAML only)
        final multiVariantPlugins = SamplePluginsService.universalPlugins
            .where((p) => p.variants.length > 1);
        expect(multiVariantPlugins.length, greaterThan(5),
            reason: 'Most universal plugins should have multiple variants');
      });
    });

    group('pluginsByCategory', () {
      test('returns non-empty map', () {
        final grouped = service.pluginsByCategory;
        expect(grouped, isNotEmpty);
      });

      test('all plugins are categorized', () {
        final grouped = service.pluginsByCategory;
        var totalCount = 0;
        for (final list in grouped.values) {
          totalCount += list.length;
        }
        expect(totalCount, equals(SamplePluginsService.allPlugins.length));
      });

      test('system category has plugins', () {
        final grouped = service.pluginsByCategory;
        expect(grouped[PluginCategory.system], isNotNull);
        expect(grouped[PluginCategory.system], isNotEmpty);
      });
    });

    group('categories', () {
      test('returns sorted categories', () {
        final cats = service.categories;
        expect(cats, isNotEmpty);

        // Check if sorted alphabetically by displayName
        for (var i = 0; i < cats.length - 1; i++) {
          expect(
            cats[i].displayName.compareTo(cats[i + 1].displayName),
            lessThanOrEqualTo(0),
          );
        }
      });
    });

    group('getPluginsForLanguage', () {
      test('returns plugins for bash', () {
        final bashPlugins = service.getPluginsForLanguage(PluginLanguage.bash);
        expect(bashPlugins, isNotEmpty);
      });

      test('returns plugins for lua', () {
        final luaPlugins = service.getPluginsForLanguage(PluginLanguage.lua);
        expect(luaPlugins, isNotEmpty);
      });

      test('returns plugins for python', () {
        final pythonPlugins = service.getPluginsForLanguage(PluginLanguage.python);
        expect(pythonPlugins, isNotEmpty);
      });

      test('all returned plugins have the requested language', () {
        final luaPlugins = service.getPluginsForLanguage(PluginLanguage.lua);

        for (final plugin in luaPlugins) {
          expect(plugin.hasLanguage(PluginLanguage.lua), isTrue,
              reason: 'Plugin ${plugin.id} should have Lua variant');
        }
      });
    });

    group('mobileCompatiblePlugins', () {
      test('returns only mobile compatible plugins', () {
        final mobilePlugins = service.mobileCompatiblePlugins;

        for (final plugin in mobilePlugins) {
          expect(plugin.mobileCompatible, isTrue,
              reason: 'Plugin ${plugin.id} should be mobile compatible');
        }
      });

      test('universal plugins marked as mobile compatible', () {
        // CPU, Memory, Battery should be mobile compatible
        final cpuPlugin = SamplePluginsService.universalPlugins
            .firstWhere((p) => p.id == 'cpu');
        expect(cpuPlugin.mobileCompatible, isTrue);
      });
    });

    group('search', () {
      test('finds plugins by name', () {
        final results = service.search('cpu');
        expect(results, isNotEmpty);
        expect(
          results.any((p) => p.name.toLowerCase().contains('cpu')),
          isTrue,
        );
      });

      test('finds plugins by description', () {
        final results = service.search('percentage');
        expect(results, isNotEmpty);
      });

      test('finds plugins by tag', () {
        final results = service.search('bitcoin');
        expect(results, isNotEmpty);
      });

      test('search is case insensitive', () {
        final lowerResults = service.search('memory');
        final upperResults = service.search('MEMORY');
        final mixedResults = service.search('MeMoRy');

        expect(lowerResults.length, equals(upperResults.length));
        expect(lowerResults.length, equals(mixedResults.length));
      });

      test('returns empty for non-matching query', () {
        final results = service.search('xyznonexistent123');
        expect(results, isEmpty);
      });
    });

    group('Singleton', () {
      test('factory returns same instance', () {
        final a = SamplePluginsService();
        final b = SamplePluginsService();
        expect(identical(a, b), isTrue);
      });
    });

    group('PluginMetadata', () {
      test('hasLanguage returns true for existing language', () {
        final cpuPlugin = SamplePluginsService.universalPlugins
            .firstWhere((p) => p.id == 'cpu');

        expect(cpuPlugin.hasLanguage(PluginLanguage.lua), isTrue);
        expect(cpuPlugin.hasLanguage(PluginLanguage.bash), isTrue);
      });

      test('getVariant returns correct variant', () {
        final cpuPlugin = SamplePluginsService.universalPlugins
            .firstWhere((p) => p.id == 'cpu');

        final luaVariant = cpuPlugin.getVariant(PluginLanguage.lua);
        expect(luaVariant, isNotNull);
        expect(luaVariant!.language, equals(PluginLanguage.lua));
        expect(luaVariant.filename, contains('.lua'));
      });

      test('getVariant returns null for missing language', () {
        // Find a legacy plugin with only one variant
        final legacyPlugin = SamplePluginsService.legacyPlugins
            .firstWhere((p) => p.variants.length == 1);

        // Try to get a language it doesn't have
        final missingLang = legacyPlugin.variants.first.language == PluginLanguage.bash
            ? PluginLanguage.rust
            : PluginLanguage.bash;

        expect(legacyPlugin.getVariant(missingLang), isNull);
      });

      test('defaultVariant returns a valid variant', () {
        final cpuPlugin = SamplePluginsService.universalPlugins
            .firstWhere((p) => p.id == 'cpu');

        // defaultVariant should prefer Lua or be a valid variant
        expect(cpuPlugin.defaultVariant, isNotNull);
        expect(cpuPlugin.defaultVariant.assetPath, isNotEmpty);
      });
    });

    group('PluginCategory', () {
      test('all categories have displayName', () {
        for (final cat in PluginCategory.values) {
          expect(cat.displayName, isNotEmpty);
        }
      });

      test('all categories have id', () {
        for (final cat in PluginCategory.values) {
          expect(cat.id, isNotEmpty);
        }
      });
    });

    group('PluginLanguage', () {
      test('all languages have displayName', () {
        for (final lang in PluginLanguage.values) {
          expect(lang.displayName, isNotEmpty);
        }
      });

      test('all languages have icon', () {
        for (final lang in PluginLanguage.values) {
          expect(lang.icon, isNotEmpty);
        }
      });

      test('all languages have id', () {
        for (final lang in PluginLanguage.values) {
          expect(lang.id, isNotEmpty);
        }
      });
    });

    group('Backward Compatibility', () {
      // ignore: deprecated_member_use_from_same_package
      test('samplePlugins returns legacy format', () {
        // ignore: deprecated_member_use_from_same_package
        final legacy = SamplePluginsService.samplePlugins;
        expect(legacy, isNotEmpty);

        for (final plugin in legacy) {
          expect(plugin.id, isNotEmpty);
          expect(plugin.assetPath, isNotEmpty);
        }
      });
    });
  });
}
