import 'dart:async';

import '../models/plugin_config.dart';

/// Stub implementation of config service for pure Dart CLI.
/// Does not support secure storage or persistent configs.
/// Used when Flutter is not available.
class PluginConfigService {
  factory PluginConfigService() => _instance;
  PluginConfigService._internal();
  static final PluginConfigService _instance = PluginConfigService._internal();

  bool get isInitialized => true;

  Future<void> init() async {}

  Future<Map<String, String>> loadValues(
    String pluginId, {
    PluginConfig? schema,
  }) async {
    return {};
  }

  Future<void> saveValues(
    String pluginId,
    Map<String, String> values, {
    PluginConfig? schema,
  }) async {}

  Future<void> deleteValues(String pluginId, {PluginConfig? schema}) async {}

  Future<bool> hasValues(String pluginId) async => false;

  Future<Map<String, String>> getAsEnvironmentVariables(
    String pluginId, {
    PluginConfig? schema,
  }) async {
    return {};
  }

  void clearCache() {}
}
