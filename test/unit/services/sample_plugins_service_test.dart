// ignore_for_file: avoid_slow_async_io
import 'dart:io';

import 'package:crossbar/services/sample_plugins_service.dart';
import 'package:flutter_test/flutter_test.dart';

// Mock PluginManager
class MockPluginManager {
  String? mockPluginsDirectory;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockPluginManager pluginManager;
  late Directory tempPluginsDir;

  setUpAll(() async {
    tempPluginsDir = await Directory.systemTemp.createTemp('crossbar_test_sample_plugins');
    pluginManager = MockPluginManager();
    pluginManager.mockPluginsDirectory = tempPluginsDir.path;
  });

  tearDownAll(() async {
    if (await tempPluginsDir.exists()) {
      await tempPluginsDir.delete(recursive: true);
    }
  });

  group('SamplePluginsService', () {
    test('singleton instance', () {
      final service1 = SamplePluginsService();
      final service2 = SamplePluginsService();
      expect(identical(service1, service2), isTrue);
    });

    test('universalPlugins list is not empty', () {
      expect(SamplePluginsService.universalPlugins, isNotEmpty);
    });

    test('allPlugins combines universal plugins', () {
      final all = SamplePluginsService.allPlugins;
      expect(all.length, equals(SamplePluginsService.universalPlugins.length));
    });

    group('search', () {
      test('finds plugin by name', () {
        final service = SamplePluginsService();
        final results = service.search('CPU');
        expect(results, isNotEmpty);
        expect(results.first.name, contains('CPU'));
      });

      test('finds plugin by description', () {
        final service = SamplePluginsService();
        final results = service.search('battery level');
        expect(results, isNotEmpty);
        expect(results.any((p) => p.id == 'battery'), isTrue);
      });

      test('finds plugin by tag', () {
        final service = SamplePluginsService();
        final results = service.search('monitor');
        expect(results, isNotEmpty);
        expect(results.any((p) => p.tags.contains('monitor')), isTrue);
      });

      test('is case insensitive', () {
        final service = SamplePluginsService();
        final results = service.search('cpu');
        expect(results, isNotEmpty);
      });

      test('returns empty list for no match', () {
        final service = SamplePluginsService();
        final results = service.search('nonexistentpluginxyz');
        expect(results, isEmpty);
      });
    });

    group('categories', () {
      test('returns list of categories', () {
        final service = SamplePluginsService();
        final categories = service.categories;
        expect(categories, isNotEmpty);
        expect(categories, contains(PluginCategory.system));
      });

      test('pluginsByCategory groups correctly', () {
        final service = SamplePluginsService();
        final grouped = service.pluginsByCategory;
        
        expect(grouped[PluginCategory.system], isNotEmpty);
        final cpuPlugin = grouped[PluginCategory.system]!.firstWhere((p) => p.id == 'cpu');
        expect(cpuPlugin, isNotNull);
      });
    });

    group('Installation', () {
      // We need to mock rootBundle for this to work in unit tests
      // or use integration tests.
      // For unit testing logic, we can verify paths.
      
      test('isInstalled checks correct path', () async {
        final service = SamplePluginsService();
        final isInstalled = await service.isInstalled('non_existent.sh');
        expect(isInstalled, isFalse);
      });
    });
  });
}