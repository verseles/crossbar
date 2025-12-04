import 'dart:convert';
import 'dart:io';

import 'package:crossbar/core/plugin_manager.dart';
import 'package:crossbar/services/ipc_server.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  group('IpcServer', () {
    late IpcServer server;
    const testPort = 48292; // Use different port for tests

    setUp(() {
      server = IpcServer(port: testPort);
    });

    tearDown(() async {
      await server.stop();
    });

    group('server lifecycle', () {
      test('starts on specified port', () async {
        final started = await server.start();
        expect(started, true);
        expect(server.isRunning, true);
      });

      test('stops cleanly', () async {
        await server.start();
        await server.stop();
        expect(server.isRunning, false);
      });

      test('start returns true if already running', () async {
        await server.start();
        final secondStart = await server.start();
        expect(secondStart, true);
      });

      test('default port is 48291', () {
        expect(IpcServer.defaultPort, 48291);
      });

      test('host is localhost', () {
        expect(IpcServer.host, 'localhost');
      });
    });

    group('health endpoint', () {
      test('GET /health returns healthy status', () async {
        await server.start();

        final client = HttpClient();
        final request = await client.get('localhost', testPort, '/health');
        final response = await request.close();
        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body);

        expect(response.statusCode, HttpStatus.ok);
        expect(data['status'], 'healthy');
        expect(data.containsKey('timestamp'), true);

        client.close();
      });
    });

    group('status endpoint', () {
      test('GET /status returns server status', () async {
        await server.start();

        final client = HttpClient();
        final request = await client.get('localhost', testPort, '/status');
        final response = await request.close();
        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body);

        expect(response.statusCode, HttpStatus.ok);
        expect(data['status'], 'running');
        expect(data['port'], testPort);
        expect(data['version'], '1.0.0');
        expect(data.containsKey('plugins'), true);

        client.close();
      });
    });

    group('plugins endpoint', () {
      test('GET /plugins returns plugin list', () async {
        await server.start();

        final client = HttpClient();
        final request = await client.get('localhost', testPort, '/plugins');
        final response = await request.close();
        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body);

        expect(response.statusCode, HttpStatus.ok);
        expect(data.containsKey('plugins'), true);
        expect(data['plugins'], isA<List>());

        client.close();
      });
    });

    group('not found endpoint', () {
      test('GET /unknown returns 404', () async {
        await server.start();

        final client = HttpClient();
        final request = await client.get('localhost', testPort, '/unknown');
        final response = await request.close();

        expect(response.statusCode, HttpStatus.notFound);

        client.close();
      });
    });

    group('method not allowed', () {
      test('POST /health returns 405', () async {
        await server.start();

        final client = HttpClient();
        final request = await client.post('localhost', testPort, '/health');
        final response = await request.close();

        expect(response.statusCode, HttpStatus.methodNotAllowed);

        client.close();
      });

      test('PUT /status returns 405', () async {
        await server.start();

        final client = HttpClient();
        final request = await client.put('localhost', testPort, '/status');
        final response = await request.close();

        expect(response.statusCode, HttpStatus.methodNotAllowed);

        client.close();
      });
    });

    group('CORS headers', () {
      test('includes CORS headers in response', () async {
        await server.start();

        final client = HttpClient();
        final request = await client.get('localhost', testPort, '/health');
        final response = await request.close();

        expect(response.headers.value('Access-Control-Allow-Origin'), '*');

        client.close();
      });
    });

    group('JSON content type', () {
      test('returns JSON content type', () async {
        await server.start();

        final client = HttpClient();
        final request = await client.get('localhost', testPort, '/health');
        final response = await request.close();

        expect(response.headers.contentType?.mimeType, 'application/json');

        client.close();
      });
    });

    group('plugin actions', () {
      late Directory tempDir;
      late PluginManager manager;

      setUp(() async {
        await server.stop(); // Stop the default server

        tempDir = Directory.systemTemp.createTempSync('ipc_test_plugins_');
        manager = PluginManager();
        manager.customPluginsDirectory = tempDir.path;
        manager.clear();

        // Create a test plugin
        final f = File(path.join(tempDir.path, 'test.sh'));
        f.writeAsStringSync('#!/bin/bash\necho "OK"');
        if (Platform.isLinux || Platform.isMacOS) {
          Process.runSync('chmod', ['+x', f.path]);
        }
        await manager.discoverPlugins();

        server = IpcServer(port: testPort, pluginManager: manager);
        await server.start();
      });

      tearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      test('PUT /plugins/:id/disable disables plugin', () async {
        final client = HttpClient();
        final request = await client.open('PUT', 'localhost', testPort, '/plugins/test.sh/disable');
        final response = await request.close();

        expect(response.statusCode, HttpStatus.ok);

        // Check if disabled in manager
        final p = manager.getPlugin('test.off.sh');
        expect(p, isNotNull);
        expect(p!.enabled, false);

        client.close();
      });

      test('PUT /plugins/:id/enable enables plugin', () async {
        // Disable first
        await manager.disablePlugin('test.sh');

        final client = HttpClient();
        final request = await client.open('PUT', 'localhost', testPort, '/plugins/test.off.sh/enable');
        final response = await request.close();

        expect(response.statusCode, HttpStatus.ok);

        final p = manager.getPlugin('test.sh');
        expect(p, isNotNull);
        expect(p!.enabled, true);

        client.close();
      });

      test('POST /plugins/:id/run runs plugin', () async {
        final client = HttpClient();
        final request = await client.open('POST', 'localhost', testPort, '/plugins/test.sh/run');
        final response = await request.close();

        expect(response.statusCode, HttpStatus.ok);

        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body);

        expect(data['status'], 'ok');
        expect(data['output']['text'], contains('OK'));

        client.close();
      });
    });
  });
}
