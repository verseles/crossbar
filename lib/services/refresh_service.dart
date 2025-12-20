import 'dart:async';

import 'package:meta/meta.dart';

import '../core/plugin_manager.dart';
import '../models/plugin.dart';
import '../models/plugin_output.dart';

/// A centralized service to manage plugin state and refresh operations.
///
/// This service acts as the single source of truth for plugin outputs.
/// It uses a stream to broadcast updates to all listeners (UI, tray, widgets).
class RefreshService {
  factory RefreshService() => _instance;
  RefreshService._internal();
  static final RefreshService _instance = RefreshService._internal();

  PluginManager _pluginManager = PluginManager();

  @visibleForTesting
  set pluginManager(PluginManager manager) {
    _pluginManager = manager;
  }

  /// A map holding the latest output for each plugin.
  final _outputs = <String, PluginOutput>{};

  /// A stream controller that broadcasts a map of all plugin outputs.
  /// Using a BehaviorSubject-like stream by replaying the last event.
  final _outputsController =
      StreamController<Map<String, PluginOutput>>.broadcast();
  Stream<Map<String, PluginOutput>> get outputsStream =>
      _outputsController.stream;

  /// A stream that emits a single [PluginOutput] whenever a plugin is updated.
  final _pluginOutputEventController = StreamController<PluginOutput>.broadcast();
  Stream<PluginOutput> get pluginOutputEventStream =>
      _pluginOutputEventController.stream;

  /// A stream controller to indicate when a refresh is in progress.
  final _isRefreshingController = StreamController<bool>.broadcast();
  Stream<bool> get isRefreshingStream => _isRefreshingController.stream;

  /// A stream controller for individual plugin refresh status.
  final _pluginRefreshingController = StreamController<String?>.broadcast();
  Stream<String?> get pluginRefreshingStream => _pluginRefreshingController.stream;

  /// Returns the latest output for a given plugin ID.
  PluginOutput? getOutput(String pluginId) => _outputs[pluginId];

  /// Returns a map of all latest outputs.
  Map<String, PluginOutput> getAllOutputs() => Map.unmodifiable(_outputs);

  /// Runs all enabled plugins and updates the stream.
  Future<void> refreshAll() async {
    _isRefreshingController.add(true);
    final enabledPlugins = _pluginManager.plugins.where((p) => p.enabled);

    for (final plugin in enabledPlugins) {
      await _runAndBroadcast(plugin);
    }

    _isRefreshingController.add(false);
  }

  /// Runs a single plugin and updates the stream.
  Future<void> refreshPlugin(String pluginId) async {
    final plugin = _pluginManager.getPlugin(pluginId);
    if (plugin == null || !plugin.enabled) return;

    _pluginRefreshingController.add(pluginId);
    await _runAndBroadcast(plugin);
    _pluginRefreshingController.add(null);
  }

  /// Internal method to execute a plugin and broadcast its output.
  Future<void> _runAndBroadcast(Plugin plugin) async {
    final output = await _pluginManager.runPlugin(plugin.id);
    if (output != null) {
      _outputs[plugin.id] = output;
      _outputsController.add(Map.unmodifiable(_outputs));
      _pluginOutputEventController.add(output);
    }
  }

  /// Clears a specific plugin's output from the cache.
  void clearOutput(String pluginId) {
    _outputs.remove(pluginId);
    _outputsController.add(Map.unmodifiable(_outputs));
  }

  void dispose() {
    _outputsController.close();
    _pluginOutputEventController.close();
    _isRefreshingController.close();
    _pluginRefreshingController.close();
  }
}
