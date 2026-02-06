import 'dart:io';

import 'package:crossbar_core/crossbar_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Web cache persistence', () {
    late Directory tempDir;
    late LuaRunner runner;

    setUp(() async {
      runner = LuaRunner();
      tempDir = await Directory.systemTemp.createTemp('crossbar_web_cache_');
      CrossbarBridge.instance.appDataDir = tempDir.path;
      runner.forceWebCacheForTesting(true);
      runner.resetWebCacheForTesting(clearDisk: true);
    });

    tearDown(() {
      runner.setWebFetcherForTesting(null);
      runner.forceWebCacheForTesting(false);
      runner.resetWebCacheForTesting(clearDisk: true);
      CrossbarBridge.instance.appDataDir = null;
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('persists cache across memory resets', () async {
      runner.setWebFetcherForTesting((
        url, {
        method = 'GET',
        headers,
        body,
        timeout = 30,
      }) async {
        return {
          'status': 200,
          'statusMessage': 'OK',
          'data': {'ok': true},
          'headers': <String, dynamic>{},
        };
      });

      final response = runner.debugWebCacheRequest(
        pluginId: 'cache_test',
        url: 'https://example.com',
      );

      expect(response, isA<Map<String, dynamic>>());
      expect((response as Map<String, dynamic>)['message'], 'Fetching...');

      await Future<void>.delayed(const Duration(milliseconds: 10));

      final cached = runner.debugWebCacheRequest(
        pluginId: 'cache_test',
        url: 'https://example.com',
      );

      expect(cached, isA<Map<String, dynamic>>());
      expect((cached as Map<String, dynamic>)['status'], 200);

      runner.resetWebCacheForTesting(clearDisk: false);

      final cachedAfterReset = runner.debugWebCacheRequest(
        pluginId: 'cache_test',
        url: 'https://example.com',
      );

      expect(cachedAfterReset, isA<Map<String, dynamic>>());
      expect((cachedAfterReset as Map<String, dynamic>)['status'], 200);
    });

    test('keeps cached data when refresh fails', () async {
      runner.setWebFetcherForTesting((
        url, {
        method = 'GET',
        headers,
        body,
        timeout = 30,
      }) async {
        return {
          'status': 200,
          'statusMessage': 'OK',
          'data': {'ok': true},
          'headers': <String, dynamic>{},
        };
      });

      runner.debugWebCacheRequest(
        pluginId: 'cache_test',
        url: 'https://example.com',
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));

      runner.setWebFetcherForTesting((
        url, {
        method = 'GET',
        headers,
        body,
        timeout = 30,
      }) async {
        throw Exception('network down');
      });

      final cached = runner.debugWebCacheRequest(
        pluginId: 'cache_test',
        url: 'https://example.com',
      );

      expect(cached, isA<Map<String, dynamic>>());
      expect((cached as Map<String, dynamic>)['status'], 200);

      await Future<void>.delayed(const Duration(milliseconds: 10));

      final cachedAfterError = runner.debugWebCacheRequest(
        pluginId: 'cache_test',
        url: 'https://example.com',
      );

      expect(cachedAfterError, isA<Map<String, dynamic>>());
      expect((cachedAfterError as Map<String, dynamic>)['status'], 200);
    });

    test('purges stale cache entries older than max age', () async {
      runner.setWebFetcherForTesting((
        url, {
        method = 'GET',
        headers,
        body,
        timeout = 30,
      }) async {
        return {
          'status': 200,
          'statusMessage': 'OK',
          'data': {'ok': true},
          'headers': <String, dynamic>{},
        };
      });

      runner.debugWebCacheRequest(
        pluginId: 'cache_test',
        url: 'https://example.com',
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));

      final cacheKey = runner.buildWebCacheKeyWithPluginForTesting(
        pluginId: 'cache_test',
        url: 'https://example.com',
      );
      final file = runner.findWebCacheFileForTesting('cache_test', cacheKey);
      expect(file, isNotNull);
      file!.setLastModifiedSync(
        DateTime.now().subtract(const Duration(days: 8)),
      );

      runner.resetWebCacheForTesting(clearDisk: false);

      runner.setWebFetcherForTesting((
        url, {
        method = 'GET',
        headers,
        body,
        timeout = 30,
      }) async {
        throw Exception('network down');
      });

      final cached = runner.debugWebCacheRequest(
        pluginId: 'cache_test',
        url: 'https://example.com',
      );

      expect(cached, isA<Map<String, dynamic>>());
      expect((cached as Map<String, dynamic>)['message'], 'Fetching...');
    });
  });
}
