import 'package:crossbar/services/marketplace_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MarketplacePlugin', () {
    test('creates plugin with all required fields', () {
      const plugin = MarketplacePlugin(
        id: 'cpu-monitor.sh',
        name: 'CPU Monitor',
        description: 'Monitor CPU usage',
        author: 'verseles',
        language: 'bash',
        category: 'System',
        version: '1.0.0',
        downloadUrl: 'https://example.com/plugin.sh',
      );

      expect(plugin.id, equals('cpu-monitor.sh'));
      expect(plugin.name, equals('CPU Monitor'));
      expect(plugin.description, equals('Monitor CPU usage'));
      expect(plugin.author, equals('verseles'));
      expect(plugin.language, equals('bash'));
      expect(plugin.category, equals('System'));
      expect(plugin.version, equals('1.0.0'));
      expect(plugin.downloadUrl, equals('https://example.com/plugin.sh'));
      expect(plugin.stars, equals(0));
      expect(plugin.downloads, equals(0));
      expect(plugin.readme, isNull);
      expect(plugin.screenshot, isNull);
      expect(plugin.tags, isEmpty);
    });

    test('creates plugin with optional fields', () {
      const plugin = MarketplacePlugin(
        id: 'weather',
        name: 'Weather',
        description: 'Show weather',
        author: 'test',
        language: 'python',
        category: 'Weather',
        version: '2.0.0',
        downloadUrl: 'https://example.com/weather.py',
        stars: 150,
        downloads: 5000,
        readme: '# Weather Plugin',
        screenshot: 'https://example.com/screenshot.png',
        tags: ['weather', 'api'],
      );

      expect(plugin.stars, equals(150));
      expect(plugin.downloads, equals(5000));
      expect(plugin.readme, equals('# Weather Plugin'));
      expect(plugin.screenshot, equals('https://example.com/screenshot.png'));
      expect(plugin.tags, equals(['weather', 'api']));
    });

    test('fromJson creates plugin with all fields', () {
      final json = {
        'id': 'disk.sh',
        'name': 'Disk Space',
        'description': 'Check disk space',
        'author': 'user',
        'language': 'bash',
        'category': 'System',
        'version': '1.2.0',
        'downloadUrl': 'https://example.com/disk.sh',
        'stars': 42,
        'downloads': 1337,
        'readme': '# Disk Plugin',
        'screenshot': 'https://img.example.com/disk.png',
        'tags': ['system', 'disk', 'monitoring'],
      };

      final plugin = MarketplacePlugin.fromJson(json);

      expect(plugin.id, equals('disk.sh'));
      expect(plugin.name, equals('Disk Space'));
      expect(plugin.description, equals('Check disk space'));
      expect(plugin.author, equals('user'));
      expect(plugin.language, equals('bash'));
      expect(plugin.category, equals('System'));
      expect(plugin.version, equals('1.2.0'));
      expect(plugin.downloadUrl, equals('https://example.com/disk.sh'));
      expect(plugin.stars, equals(42));
      expect(plugin.downloads, equals(1337));
      expect(plugin.readme, equals('# Disk Plugin'));
      expect(plugin.screenshot, equals('https://img.example.com/disk.png'));
      expect(plugin.tags, equals(['system', 'disk', 'monitoring']));
    });

    test('fromJson provides defaults for missing fields', () {
      final json = <String, dynamic>{};
      final plugin = MarketplacePlugin.fromJson(json);

      expect(plugin.id, equals(''));
      expect(plugin.name, equals(''));
      expect(plugin.description, equals(''));
      expect(plugin.author, equals(''));
      expect(plugin.language, equals(''));
      expect(plugin.category, equals('General'));
      expect(plugin.version, equals('1.0.0'));
      expect(plugin.downloadUrl, equals(''));
      expect(plugin.stars, equals(0));
      expect(plugin.downloads, equals(0));
      expect(plugin.readme, isNull);
      expect(plugin.screenshot, isNull);
      expect(plugin.tags, isEmpty);
    });

    test('fromJson handles download_url fallback', () {
      final json = {
        'id': 'test',
        'download_url': 'https://example.com/fallback.sh',
      };

      final plugin = MarketplacePlugin.fromJson(json);

      expect(plugin.downloadUrl, equals('https://example.com/fallback.sh'));
    });

    test('fromJson prefers downloadUrl over download_url', () {
      final json = {
        'id': 'test',
        'downloadUrl': 'https://example.com/preferred.sh',
        'download_url': 'https://example.com/fallback.sh',
      };

      final plugin = MarketplacePlugin.fromJson(json);

      expect(plugin.downloadUrl, equals('https://example.com/preferred.sh'));
    });

    test('fromJson handles missing tags gracefully', () {
      final json = {'id': 'test'};
      final plugin = MarketplacePlugin.fromJson(json);

      expect(plugin.tags, isEmpty);
    });

    test('fromJson converts tags from dynamic list', () {
      final json = {
        'id': 'test',
        'tags': [123, 'string', true],
      };

      final plugin = MarketplacePlugin.fromJson(json);

      expect(plugin.tags, equals(['123', 'string', 'true']));
    });

    test('toJson creates complete JSON structure', () {
      const plugin = MarketplacePlugin(
        id: 'network.py',
        name: 'Network Monitor',
        description: 'Monitor network',
        author: 'dev',
        language: 'python',
        category: 'Network',
        version: '3.0.0',
        downloadUrl: 'https://example.com/network.py',
        stars: 99,
        downloads: 2500,
        readme: '# Network',
        screenshot: 'https://img.example.com/net.png',
        tags: ['network', 'monitoring'],
      );

      final json = plugin.toJson();

      expect(json['id'], equals('network.py'));
      expect(json['name'], equals('Network Monitor'));
      expect(json['description'], equals('Monitor network'));
      expect(json['author'], equals('dev'));
      expect(json['language'], equals('python'));
      expect(json['category'], equals('Network'));
      expect(json['version'], equals('3.0.0'));
      expect(json['downloadUrl'], equals('https://example.com/network.py'));
      expect(json['stars'], equals(99));
      expect(json['downloads'], equals(2500));
      expect(json['readme'], equals('# Network'));
      expect(json['screenshot'], equals('https://img.example.com/net.png'));
      expect(json['tags'], equals(['network', 'monitoring']));
    });

    test('toJson/fromJson roundtrip preserves data', () {
      const original = MarketplacePlugin(
        id: 'test.sh',
        name: 'Test Plugin',
        description: 'A test',
        author: 'tester',
        language: 'bash',
        category: 'Utilities',
        version: '1.5.0',
        downloadUrl: 'https://test.com/test.sh',
        stars: 10,
        downloads: 100,
        tags: ['test', 'example'],
      );

      final json = original.toJson();
      final restored = MarketplacePlugin.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.name, equals(original.name));
      expect(restored.description, equals(original.description));
      expect(restored.author, equals(original.author));
      expect(restored.language, equals(original.language));
      expect(restored.category, equals(original.category));
      expect(restored.version, equals(original.version));
      expect(restored.downloadUrl, equals(original.downloadUrl));
      expect(restored.stars, equals(original.stars));
      expect(restored.downloads, equals(original.downloads));
      expect(restored.tags, equals(original.tags));
    });
  });

  group('PluginCategory', () {
    test('has all expected categories', () {
      expect(PluginCategory.system, equals('System'));
      expect(PluginCategory.network, equals('Network'));
      expect(PluginCategory.dev, equals('Development'));
      expect(PluginCategory.productivity, equals('Productivity'));
      expect(PluginCategory.finance, equals('Finance'));
      expect(PluginCategory.weather, equals('Weather'));
      expect(PluginCategory.media, equals('Media'));
      expect(PluginCategory.social, equals('Social'));
      expect(PluginCategory.utilities, equals('Utilities'));
      expect(PluginCategory.other, equals('Other'));
    });

    test('all list contains all categories', () {
      expect(PluginCategory.all.length, equals(10));
      expect(PluginCategory.all, contains(PluginCategory.system));
      expect(PluginCategory.all, contains(PluginCategory.network));
      expect(PluginCategory.all, contains(PluginCategory.dev));
      expect(PluginCategory.all, contains(PluginCategory.productivity));
      expect(PluginCategory.all, contains(PluginCategory.finance));
      expect(PluginCategory.all, contains(PluginCategory.weather));
      expect(PluginCategory.all, contains(PluginCategory.media));
      expect(PluginCategory.all, contains(PluginCategory.social));
      expect(PluginCategory.all, contains(PluginCategory.utilities));
      expect(PluginCategory.all, contains(PluginCategory.other));
    });

    test('all list has no duplicates', () {
      final uniqueCategories = PluginCategory.all.toSet();
      expect(uniqueCategories.length, equals(PluginCategory.all.length));
    });
  });

  // Note: Full testing of MarketplaceService methods requires mocking Dio
  // and PluginManager, which is complex. The tests above ensure:
  // - MarketplacePlugin model works correctly
  // - JSON serialization is robust
  // - Category constants are properly defined
  // - Edge cases (missing fields, fallbacks) are handled
  //
  // For integration tests of actual marketplace operations, we would need:
  // 1. Mock for Dio HTTP client
  // 2. Mock for PluginManager
  // 3. Test fixtures for GitHub API responses
  // 4. Network error handling tests
}
