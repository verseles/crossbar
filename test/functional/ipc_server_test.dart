import 'dart:convert';
import 'dart:io';

import 'package:crossbar/services/ipc_server.dart';
import 'package:flutter_test/flutter_test.dart';

/// Functional tests for IPC Server.
/// These tests start a real HTTP server and make real HTTP requests.
/// They run in CI since they only require binding to a localhost port.
void main() {
  group('IPC Server - Real HTTP', () {
    late IpcServer server;
    late HttpClient client;
    const testPort = 48999; // Use different port to avoid conflicts

    setUpAll(() async {
      server = IpcServer(port: testPort);
      final started = await server.start();
      expect(started, isTrue, reason: 'Server should start successfully');

      client = HttpClient();
    });

    tearDownAll(() async {
      client.close();
      await server.stop();
    });

    Future<Map<String, dynamic>> getJson(String path) async {
      final request = await client.get('localhost', testPort, path);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      return jsonDecode(body) as Map<String, dynamic>;
    }

    Future<HttpClientResponse> makeRequest(
      String method,
      String path, {
      Map<String, dynamic>? body,
    }) async {
      final request = await (switch (method) {
        'GET' => client.get('localhost', testPort, path),
        'POST' => client.post('localhost', testPort, path),
        'PUT' => client.put('localhost', testPort, path),
        'DELETE' => client.delete('localhost', testPort, path),
        _ => throw ArgumentError('Unknown method: $method'),
      });

      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(body));
      }

      return request.close();
    }

    test('GET /health returns healthy status', () async {
      final data = await getJson('/health');

      expect(data['status'], equals('healthy'));
      expect(data['timestamp'], isNotNull);
      // Timestamp should be valid ISO8601
      expect(() => DateTime.parse(data['timestamp']), returnsNormally);
    });

    test('GET /status returns server status', () async {
      final data = await getJson('/status');

      expect(data['status'], equals('running'));
      expect(data['port'], equals(testPort));
      expect(data['version'], equals('1.0.0'));
      expect(data['plugins'], isA<Map>());
      expect(data['plugins']['total'], isA<int>());
      expect(data['plugins']['enabled'], isA<int>());
    });

    test('GET /plugins returns plugin list', () async {
      final data = await getJson('/plugins');

      expect(data['plugins'], isA<List>());
      // Each plugin should have required fields
      for (final plugin in data['plugins']) {
        expect(plugin['id'], isNotNull);
        expect(plugin['path'], isNotNull);
        expect(plugin['interpreter'], isNotNull);
        expect(plugin['enabled'], isA<bool>());
      }
    });

    test('OPTIONS request returns CORS headers', () async {
      final request = await client.open('OPTIONS', 'localhost', testPort, '/health');
      final response = await request.close();

      expect(response.statusCode, equals(HttpStatus.ok));
      expect(response.headers['access-control-allow-origin'], isNotNull);
      expect(response.headers['access-control-allow-methods'], isNotNull);
    });

    test('Invalid path returns 404', () async {
      final response = await makeRequest('GET', '/nonexistent');

      expect(response.statusCode, equals(HttpStatus.notFound));

      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;
      expect(data['error'], contains('Not found'));
    });

    test('Wrong method returns 405', () async {
      final response = await makeRequest('POST', '/health');

      expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
    });

    test('GET /plugins/:id returns 404 for unknown plugin', () async {
      final response = await makeRequest('GET', '/plugins/nonexistent-plugin-xyz');

      expect(response.statusCode, equals(HttpStatus.notFound));

      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;
      expect(data['error'], contains('Plugin not found'));
    });

    test('Response has correct Content-Type header', () async {
      final request = await client.get('localhost', testPort, '/health');
      final response = await request.close();

      expect(response.headers.contentType?.mimeType, equals('application/json'));
    });

    test('Server responds to multiple concurrent requests', () async {
      final futures = List.generate(10, (_) => getJson('/health'));
      final results = await Future.wait(futures);

      for (final result in results) {
        expect(result['status'], equals('healthy'));
      }
    });
  });

  group('IPC Server - Lifecycle', () {
    test('Server can start and stop multiple times', () async {
      final server = IpcServer(port: 48998);

      // Start
      expect(await server.start(), isTrue);
      expect(server.isRunning, isTrue);

      // Stop
      await server.stop();
      expect(server.isRunning, isFalse);

      // Start again
      expect(await server.start(), isTrue);
      expect(server.isRunning, isTrue);

      // Stop again
      await server.stop();
      expect(server.isRunning, isFalse);
    });

    test('Starting already running server returns true', () async {
      final server = IpcServer(port: 48997);

      expect(await server.start(), isTrue);
      expect(await server.start(), isTrue); // Second start should return true

      await server.stop();
    });

    test('Server fails to start on already bound port', () async {
      final server1 = IpcServer(port: 48996);
      final server2 = IpcServer(port: 48996);

      expect(await server1.start(), isTrue);
      expect(await server2.start(), isFalse); // Should fail - port in use

      await server1.stop();
    });
  });

  group('IPC Server - JSON Response Format', () {
    late IpcServer server;
    late HttpClient client;
    const testPort = 48995;

    setUpAll(() async {
      server = IpcServer(port: testPort);
      await server.start();
      client = HttpClient();
    });

    tearDownAll(() async {
      client.close();
      await server.stop();
    });

    test('All responses are valid JSON', () async {
      final endpoints = ['/health', '/status', '/plugins'];

      for (final endpoint in endpoints) {
        final request = await client.get('localhost', testPort, endpoint);
        final response = await request.close();
        final body = await response.transform(utf8.decoder).join();

        expect(() => jsonDecode(body), returnsNormally, reason: 'Response from $endpoint should be valid JSON');
      }
    });

    test('Error responses include error field', () async {
      final request = await client.get('localhost', testPort, '/nonexistent');
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;

      expect(data.containsKey('error'), isTrue);
      expect(data['error'], isA<String>());
    });
  });
}
