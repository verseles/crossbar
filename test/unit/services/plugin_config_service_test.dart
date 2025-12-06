import 'dart:convert';
import 'dart:io';

import 'package:crossbar/models/plugin_config.dart';
import 'package:crossbar/services/plugin_config_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PluginConfigService service;
  late Directory tempDir;
  late _MockSecureStorage mockSecureStorage;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('crossbar_config_test_');
    mockSecureStorage = _MockSecureStorage();

    service = PluginConfigService();
    service.resetForTesting();
    service.configsDirectory = tempDir.path;
    service.setSecureStorage(mockSecureStorage);
    await service.init();
  });

  tearDown(() async {
    service.resetForTesting();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('PluginConfigService', () {
    group('init', () {
      test('initializes successfully', () {
        expect(service.isInitialized, isTrue);
      });

      test('creates configs directory if not exists', () async {
        final newTempDir = await Directory.systemTemp.createTemp('crossbar_new_');
        final configsPath = '${newTempDir.path}/configs';

        final newService = PluginConfigService();
        newService.resetForTesting();
        newService.configsDirectory = configsPath;
        newService.setSecureStorage(mockSecureStorage);
        await newService.init();

        expect(Directory(configsPath).existsSync(), isTrue);

        await newTempDir.delete(recursive: true);
      });
    });

    group('saveValues and loadValues', () {
      test('saves and loads regular values', () async {
        final values = {'api_url': 'https://api.example.com', 'timeout': '30'};

        await service.saveValues('test-plugin.10s.sh', values);
        final loaded = await service.loadValues('test-plugin.10s.sh');

        expect(loaded, equals(values));
      });

      test('saves regular values to JSON file', () async {
        final values = {'key1': 'value1', 'key2': 'value2'};

        await service.saveValues('json-test.sh', values);

        final file = File('${tempDir.path}/json-test.sh.json');
        expect(await file.exists(), isTrue);

        final content = await file.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        expect(json['key1'], equals('value1'));
        expect(json['key2'], equals('value2'));
      });

      test('saves password values to secure storage', () async {
        final schema = PluginConfig(
          name: 'Test Plugin',
          description: 'Test',
          icon: '🔐',
          configRequired: 'optional',
          settings: [
            const Setting(
              key: 'api_key',
              label: 'API Key',
              type: 'text',
            ),
            const Setting(
              key: 'password',
              label: 'Password',
              type: 'password',
            ),
          ],
        );

        final values = {
          'api_key': 'abc123',
          'password': 'secret123',
        };

        await service.saveValues('secure-test.sh', values, schema: schema);

        // Check regular values are in JSON
        final file = File('${tempDir.path}/secure-test.sh.json');
        final content = await file.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        expect(json['api_key'], equals('abc123'));
        expect(json.containsKey('password'), isFalse);

        // Check password is in secure storage
        expect(
          mockSecureStorage.storage['crossbar_plugin_secure-test.sh_password'],
          equals('secret123'),
        );
      });

      test('loads password values from secure storage', () async {
        final schema = PluginConfig(
          name: 'Test',
          description: 'Test',
          icon: '',
          configRequired: 'optional',
          settings: [
            const Setting(key: 'secret', label: 'Secret', type: 'password'),
          ],
        );

        // Pre-populate secure storage
        mockSecureStorage.storage['crossbar_plugin_load-test.sh_secret'] =
            'my-secret';

        // Create regular config file directly (without going through saveValues)
        // to avoid cache interference
        final configFile = File('${tempDir.path}/load-test.sh.json');
        await configFile.writeAsString('{"other": "value"}');

        // Load with schema - should read from secure storage
        final loaded =
            await service.loadValues('load-test.sh', schema: schema);

        expect(loaded['secret'], equals('my-secret'));
        expect(loaded['other'], equals('value'));
      });

      test('returns empty map for non-existent plugin', () async {
        final loaded = await service.loadValues('non-existent.sh');
        expect(loaded, isEmpty);
      });

      test('caches loaded values', () async {
        final values = {'cached': 'value'};
        await service.saveValues('cached-plugin.sh', values);

        // First load
        final loaded1 = await service.loadValues('cached-plugin.sh');
        expect(loaded1, equals(values));

        // Delete file
        final file = File('${tempDir.path}/cached-plugin.sh.json');
        await file.delete();

        // Second load should return cached values
        final loaded2 = await service.loadValues('cached-plugin.sh');
        expect(loaded2, equals(values));
      });
    });

    group('deleteValues', () {
      test('deletes config file', () async {
        await service.saveValues('delete-test.sh', {'key': 'value'});

        final file = File('${tempDir.path}/delete-test.sh.json');
        expect(await file.exists(), isTrue);

        await service.deleteValues('delete-test.sh');

        expect(await file.exists(), isFalse);
      });

      test('deletes secure values', () async {
        final schema = PluginConfig(
          name: 'Test',
          description: 'Test',
          icon: '',
          configRequired: 'optional',
          settings: [
            const Setting(key: 'pass', label: 'Pass', type: 'password'),
          ],
        );

        await service.saveValues('delete-secure.sh', {'pass': 'secret'},
            schema: schema);

        expect(
          mockSecureStorage.storage
              .containsKey('crossbar_plugin_delete-secure.sh_pass'),
          isTrue,
        );

        await service.deleteValues('delete-secure.sh', schema: schema);

        expect(
          mockSecureStorage.storage
              .containsKey('crossbar_plugin_delete-secure.sh_pass'),
          isFalse,
        );
      });

      test('clears cache for deleted plugin', () async {
        await service.saveValues('cache-delete.sh', {'key': 'value'});

        // Load to cache
        await service.loadValues('cache-delete.sh');

        // Delete
        await service.deleteValues('cache-delete.sh');

        // Load should return empty (cache cleared)
        final loaded = await service.loadValues('cache-delete.sh');
        expect(loaded, isEmpty);
      });
    });

    group('hasValues', () {
      test('returns true if config file exists', () async {
        await service.saveValues('exists.sh', {'key': 'value'});
        expect(await service.hasValues('exists.sh'), isTrue);
      });

      test('returns false if config file does not exist', () async {
        expect(await service.hasValues('not-exists.sh'), isFalse);
      });
    });

    group('getAsEnvironmentVariables', () {
      test('converts keys to CROSSBAR_PLUGIN_ prefix', () async {
        await service.saveValues('env-test.sh', {
          'api_key': 'abc123',
          'timeout': '30',
        });

        final envVars =
            await service.getAsEnvironmentVariables('env-test.sh');

        expect(envVars['CROSSBAR_PLUGIN_API_KEY'], equals('abc123'));
        expect(envVars['CROSSBAR_PLUGIN_TIMEOUT'], equals('30'));
      });

      test('converts keys to uppercase', () async {
        await service.saveValues('upper-test.sh', {
          'myKey': 'value1',
          'some_other_key': 'value2',
        });

        final envVars =
            await service.getAsEnvironmentVariables('upper-test.sh');

        expect(envVars['CROSSBAR_PLUGIN_MYKEY'], equals('value1'));
        expect(envVars['CROSSBAR_PLUGIN_SOME_OTHER_KEY'], equals('value2'));
      });

      test('includes password values', () async {
        final schema = PluginConfig(
          name: 'Test',
          description: 'Test',
          icon: '',
          configRequired: 'optional',
          settings: [
            const Setting(key: 'token', label: 'Token', type: 'password'),
          ],
        );

        // Pre-populate secure storage
        mockSecureStorage.storage['crossbar_plugin_env-secure.sh_token'] =
            'secret-token';

        // Create regular config file directly (without going through saveValues)
        final configFile = File('${tempDir.path}/env-secure.sh.json');
        await configFile.writeAsString('{"other": "value"}');

        final envVars = await service.getAsEnvironmentVariables(
          'env-secure.sh',
          schema: schema,
        );

        expect(envVars['CROSSBAR_PLUGIN_TOKEN'], equals('secret-token'));
        expect(envVars['CROSSBAR_PLUGIN_OTHER'], equals('value'));
      });
    });

    group('clearCache', () {
      test('clears all cached values', () async {
        await service.saveValues('cache1.sh', {'key': 'value1'});
        await service.saveValues('cache2.sh', {'key': 'value2'});

        // Load to cache
        await service.loadValues('cache1.sh');
        await service.loadValues('cache2.sh');

        // Clear cache
        service.clearCache();

        // Delete files
        await File('${tempDir.path}/cache1.sh.json').delete();
        await File('${tempDir.path}/cache2.sh.json').delete();

        // Should return empty since cache is cleared and files are gone
        final loaded1 = await service.loadValues('cache1.sh');
        final loaded2 = await service.loadValues('cache2.sh');

        expect(loaded1, isEmpty);
        expect(loaded2, isEmpty);
      });
    });

    group('file sanitization', () {
      test('sanitizes plugin id for filename', () async {
        await service.saveValues('path/to/plugin.sh', {'key': 'value'});

        // Should not create nested directories
        final file = File('${tempDir.path}/path_to_plugin.sh.json');
        expect(await file.exists(), isTrue);
      });
    });
  });
}

/// Mock implementation of FlutterSecureStorage for testing.
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
  AndroidOptions get aOptions => const AndroidOptions();

  @override
  IOSOptions get iOptions => const IOSOptions();

  @override
  LinuxOptions get lOptions => const LinuxOptions();

  @override
  MacOsOptions get mOptions => const MacOsOptions();

  @override
  WebOptions get webOptions => const WebOptions();

  @override
  WindowsOptions get wOptions => const WindowsOptions();

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
