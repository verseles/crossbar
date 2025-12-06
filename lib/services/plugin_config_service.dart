import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as path;

import '../models/plugin_config.dart';
import 'logger_service.dart';

/// Service responsible for loading, saving, and securely storing plugin configuration values.
///
/// Configuration values are stored in `~/.crossbar/configs/<pluginId>.json`.
/// Sensitive values (type: password) are stored separately using flutter_secure_storage.
class PluginConfigService extends ChangeNotifier {
  factory PluginConfigService() => _instance;

  PluginConfigService._internal();
  static final PluginConfigService _instance = PluginConfigService._internal();

  FlutterSecureStorage? _secureStorage;
  bool _initialized = false;
  String? _configsDirectory;
  bool _secureStorageInjected = false;

  /// In-memory cache of loaded values per plugin
  final Map<String, Map<String, String>> _cache = {};

  bool get isInitialized => _initialized;

  @visibleForTesting
  set configsDirectory(String? path) => _configsDirectory = path;

  @visibleForTesting
  void setSecureStorage(FlutterSecureStorage storage) {
    _secureStorage = storage;
    _secureStorageInjected = true;
  }

  /// Gets the configs directory path.
  /// Desktop: `~/.crossbar/configs/`
  Future<String> get configsDirectory async {
    if (_configsDirectory != null) return _configsDirectory!;

    final homeDir = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '';
    return path.join(homeDir, '.crossbar', 'configs');
  }

  /// Initializes the service.
  Future<void> init() async {
    if (_initialized) return;

    try {
      // Only create secure storage if not already injected (for testing)
      if (!_secureStorageInjected) {
        _secureStorage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
        );
      }

      // Ensure configs directory exists
      final configsDir = Directory(await configsDirectory);
      if (!await configsDir.exists()) {
        await configsDir.create(recursive: true);
      }

      _initialized = true;
      LoggerService().info('PluginConfigService initialized');
    } catch (e, stackTrace) {
      LoggerService()
          .error('Failed to initialize PluginConfigService', e, stackTrace);
    }
  }

  /// Loads configuration values for a plugin.
  ///
  /// Returns a map of key -> value. Password fields are loaded from secure storage.
  /// If no config file exists, returns an empty map.
  Future<Map<String, String>> loadValues(
    String pluginId, {
    PluginConfig? schema,
  }) async {
    if (!_initialized) await init();

    // Check cache first
    if (_cache.containsKey(pluginId)) {
      return Map.from(_cache[pluginId]!);
    }

    final values = <String, String>{};

    try {
      final configFile = await _getConfigFile(pluginId);

      if (await configFile.exists()) {
        final content = await configFile.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;

        for (final entry in json.entries) {
          values[entry.key] = entry.value.toString();
        }
      }

      // Load secure values (passwords) from secure storage
      if (schema != null) {
        for (final setting in schema.settings) {
          if (setting.type == 'password') {
            final secureKey = _getSecureKey(pluginId, setting.key);
            final secureValue = await _secureStorage!.read(key: secureKey);
            if (secureValue != null) {
              values[setting.key] = secureValue;
            }
          }
        }
      }

      // Cache the loaded values
      _cache[pluginId] = Map.from(values);
    } catch (e, stackTrace) {
      LoggerService()
          .error('Failed to load config for plugin: $pluginId', e, stackTrace);
    }

    return values;
  }

  /// Saves configuration values for a plugin.
  ///
  /// Password fields are stored in secure storage, not in the JSON file.
  Future<void> saveValues(
    String pluginId,
    Map<String, String> values, {
    PluginConfig? schema,
  }) async {
    if (!_initialized) await init();

    try {
      final regularValues = <String, String>{};
      final secureKeys = <String>[];

      // Separate regular values from secure values
      if (schema != null) {
        for (final setting in schema.settings) {
          if (setting.type == 'password') {
            secureKeys.add(setting.key);
          }
        }
      }

      for (final entry in values.entries) {
        if (secureKeys.contains(entry.key)) {
          // Store in secure storage
          final secureKey = _getSecureKey(pluginId, entry.key);
          if (entry.value.isNotEmpty) {
            await _secureStorage!.write(key: secureKey, value: entry.value);
          } else {
            await _secureStorage!.delete(key: secureKey);
          }
        } else {
          regularValues[entry.key] = entry.value;
        }
      }

      // Save regular values to JSON file
      final configFile = await _getConfigFile(pluginId);
      final json = jsonEncode(regularValues);
      await configFile.writeAsString(json);

      // Update cache
      _cache[pluginId] = Map.from(values);

      LoggerService().info('Saved config for plugin: $pluginId');
      notifyListeners();
    } catch (e, stackTrace) {
      LoggerService()
          .error('Failed to save config for plugin: $pluginId', e, stackTrace);
      rethrow;
    }
  }

  /// Deletes all configuration values for a plugin.
  Future<void> deleteValues(String pluginId, {PluginConfig? schema}) async {
    if (!_initialized) await init();

    try {
      // Delete config file
      final configFile = await _getConfigFile(pluginId);
      if (await configFile.exists()) {
        await configFile.delete();
      }

      // Delete secure values
      if (schema != null) {
        for (final setting in schema.settings) {
          if (setting.type == 'password') {
            final secureKey = _getSecureKey(pluginId, setting.key);
            await _secureStorage!.delete(key: secureKey);
          }
        }
      }

      // Clear cache
      _cache.remove(pluginId);

      LoggerService().info('Deleted config for plugin: $pluginId');
      notifyListeners();
    } catch (e, stackTrace) {
      LoggerService().error(
          'Failed to delete config for plugin: $pluginId', e, stackTrace);
    }
  }

  /// Checks if a plugin has any saved configuration values.
  Future<bool> hasValues(String pluginId) async {
    if (!_initialized) await init();

    final configFile = await _getConfigFile(pluginId);
    return configFile.exists();
  }

  /// Gets configuration values as environment variables.
  ///
  /// Keys are converted to UPPER_CASE with CROSSBAR_PLUGIN_ prefix.
  /// Example: `api_key` becomes `CROSSBAR_PLUGIN_API_KEY`
  Future<Map<String, String>> getAsEnvironmentVariables(
    String pluginId, {
    PluginConfig? schema,
  }) async {
    final values = await loadValues(pluginId, schema: schema);
    final envVars = <String, String>{};

    for (final entry in values.entries) {
      final envKey = 'CROSSBAR_PLUGIN_${entry.key.toUpperCase()}';
      envVars[envKey] = entry.value;
    }

    return envVars;
  }

  /// Clears the in-memory cache.
  void clearCache() {
    _cache.clear();
  }

  /// Gets the config file for a plugin.
  Future<File> _getConfigFile(String pluginId) async {
    final dir = await configsDirectory;
    // Sanitize pluginId for filename (remove path separators, etc.)
    final safeId = pluginId.replaceAll(RegExp(r'[/\\:*?"<>|]'), '_');
    return File(path.join(dir, '$safeId.json'));
  }

  /// Generates a unique key for secure storage.
  String _getSecureKey(String pluginId, String key) {
    return 'crossbar_plugin_${pluginId}_$key';
  }

  @visibleForTesting
  void resetForTesting() {
    _initialized = false;
    _configsDirectory = null;
    _secureStorageInjected = false;
    _secureStorage = null;
    _cache.clear();
  }
}
