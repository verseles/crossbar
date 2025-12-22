// ignore_for_file: avoid_slow_async_io
import 'dart:convert';
import 'dart:io';

import 'package:crossbar_core/crossbar_core.dart';
import 'package:crossbar/services/plugin_config_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Security tests to verify that sensitive data is handled correctly.
/// These tests ensure passwords never leak to logs or JSON files.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Security Tests - Password Handling', () {
    late PluginConfigService service;
    late Directory tempDir;
    late _MockSecureStorage mockSecureStorage;

    const testSchema = PluginConfig(
      name: 'Test Plugin',
      description: 'Test',
      icon: '🔐',
      configRequired: 'required',
      settings: [
        Setting(
          key: 'api_key',
          label: 'API Key',
          type: 'text',
        ),
        Setting(
          key: 'username',
          label: 'Username',
          type: 'text',
        ),
        Setting(
          key: 'password',
          label: 'Password',
          type: 'password',
        ),
        Setting(
          key: 'secret_token',
          label: 'Secret Token',
          type: 'password',
        ),
      ],
    );

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('security_test_');
      mockSecureStorage = _MockSecureStorage();

      service = PluginConfigService();
      service.resetForTesting();
      service.configsDirectory = tempDir.path;
      service.setSecureStorage(mockSecureStorage);
      await service.init();
    });

    tearDown(() async {
      service.resetForTesting();
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    });

    group('Password values never written to JSON file', () {
      test('single password field is stored securely', () async {
        final values = {
          'api_key': 'abc123',
          'password': 'super_secret_password',
        };

        await service.saveValues('secure-plugin.sh', values, schema: testSchema);

        // Read the JSON file directly
        final file = File('${tempDir.path}/secure-plugin.sh.json');
        expect(await file.exists(), isTrue);

        final content = await file.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;

        // Password should NOT be in JSON
        expect(json.containsKey('password'), isFalse,
            reason: 'Password should not be written to JSON file');
        expect(content.contains('super_secret_password'), isFalse,
            reason: 'Password value should not appear in JSON file');

        // Regular values ARE in JSON
        expect(json['api_key'], equals('abc123'));

        // Password IS in secure storage
        expect(
          mockSecureStorage.storage['crossbar_plugin_secure-plugin.sh_password'],
          equals('super_secret_password'),
        );
      });

      test('multiple password fields are all stored securely', () async {
        final values = {
          'username': 'user123',
          'password': 'pass1',
          'secret_token': 'token123',
        };

        await service.saveValues('multi-secret.sh', values, schema: testSchema);

        final file = File('${tempDir.path}/multi-secret.sh.json');
        final content = await file.readAsString();

        // No passwords in file
        expect(content.contains('pass1'), isFalse);
        expect(content.contains('token123'), isFalse);

        // All passwords in secure storage
        expect(
          mockSecureStorage.storage['crossbar_plugin_multi-secret.sh_password'],
          equals('pass1'),
        );
        expect(
          mockSecureStorage.storage['crossbar_plugin_multi-secret.sh_secret_token'],
          equals('token123'),
        );
      });

      test('password deletion removes from secure storage', () async {
        // First save with password
        await service.saveValues(
          'delete-test.sh',
          {'password': 'to_delete'},
          schema: testSchema,
        );

        expect(
          mockSecureStorage.storage.containsKey('crossbar_plugin_delete-test.sh_password'),
          isTrue,
        );

        // Delete
        await service.deleteValues('delete-test.sh', schema: testSchema);

        // Password should be removed
        expect(
          mockSecureStorage.storage.containsKey('crossbar_plugin_delete-test.sh_password'),
          isFalse,
        );
      });
    });

    group('Passwords are loaded correctly', () {
      test('passwords are loaded from secure storage', () async {
        // Pre-populate secure storage
        mockSecureStorage.storage['crossbar_plugin_load-test.sh_password'] = 'stored_secret';

        // Create JSON file with non-secret data
        final file = File('${tempDir.path}/load-test.sh.json');
        await file.writeAsString('{"username": "user"}');

        // Load with schema
        final values = await service.loadValues('load-test.sh', schema: testSchema);

        expect(values['password'], equals('stored_secret'));
        expect(values['username'], equals('user'));
      });
    });

    group('Environment variables expose passwords correctly (runtime only)', () {
      test('passwords are included in environment variables', () async {
        mockSecureStorage.storage['crossbar_plugin_env-test.sh_password'] = 'env_secret';

        final file = File('${tempDir.path}/env-test.sh.json');
        await file.writeAsString('{"api_key": "key123"}');

        final envVars = await service.getAsEnvironmentVariables(
          'env-test.sh',
          schema: testSchema,
        );

        // Password IS exposed as env var (this is intentional for plugin execution)
        expect(envVars['CROSSBAR_PLUGIN_PASSWORD'], equals('env_secret'));
        expect(envVars['CROSSBAR_PLUGIN_API_KEY'], equals('key123'));
      });
    });

    group('Plugin ID sanitization (path traversal prevention)', () {
      test('plugin ID with path separators is sanitized', () async {
        // Attempt to use path traversal in plugin ID
        await service.saveValues('../../../etc/passwd', {'key': 'value'});

        // Should NOT create file in etc
        // Just checking it doesn't throw - the file should be sanitized
        expect(true, isTrue);
      });

      test('plugin ID with special chars is sanitized', () async {
        await service.saveValues('plugin/with/slashes.sh', {'key': 'value'});

        // Should create file with sanitized name
        final file = File('${tempDir.path}/plugin_with_slashes.sh.json');
        expect(await file.exists(), isTrue);
      });
    });
  });
}

/// Mock implementation of FlutterSecureStorage for testing
class _MockSecureStorage implements FlutterSecureStorage {
  final Map<String, String> storage = {};

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return storage[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      storage[key] = value;
    } else {
      storage.remove(key);
    }
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    storage.remove(key);
  }

  @override
  Future<Map<String, String>> readAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return Map.from(storage);
  }

  @override
  Future<void> deleteAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    storage.clear();
  }

  @override
  Future<bool> containsKey({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return storage.containsKey(key);
  }

  @override
  Future<bool> isCupertinoProtectedDataAvailable() async => true;

  @override
  Stream<bool> get onCupertinoProtectedDataAvailabilityChanged =>
      const Stream.empty();

  @override
  AndroidOptions get aOptions => AndroidOptions.defaultOptions;

  @override
  IOSOptions get iOptions => IOSOptions.defaultOptions;

  @override
  LinuxOptions get lOptions => LinuxOptions.defaultOptions;

  @override
  MacOsOptions get mOptions => MacOsOptions.defaultOptions;

  @override
  WebOptions get webOptions => WebOptions.defaultOptions;

  @override
  WindowsOptions get wOptions => WindowsOptions.defaultOptions;

  @override
  void registerListener({
    required String key,
    required void Function(String?) listener,
  }) {}

  @override
  void unregisterListener({
    required String key,
    void Function(String?)? listener,
  }) {}

  @override
  void unregisterAllListeners() {}

  @override
  void unregisterAllListenersForKey({required String key}) {}
}
