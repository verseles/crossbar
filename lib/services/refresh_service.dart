import 'dart:async';

import 'package:meta/meta.dart';

import 'package:crossbar_core/crossbar_core.dart';
import '../core/plugin_manager.dart';

/// Callback type for plugin output updates
typedef PluginOutputCallback = void Function(String pluginId, PluginOutput output);

/// Callback type for plugin list changes (enable/disable/add/remove)
typedef PluginListChangedCallback = void Function();

/// RefreshService - Single source of truth for all plugin refresh operations.
///
/// This service centralizes all plugin execution and output management,
/// ensuring consistent behavior across:
/// - Manual refresh (UI button click)
/// - Auto refresh (scheduled timer)
/// - IPC refresh (API calls)
/// - Background refresh (Android WorkManager)
/// - Widget refresh (mobile home screen widgets)
///
/// All components should use this service instead of calling PluginManager directly.
class RefreshService {
  factory RefreshService() => _instance;

  RefreshService._internal();

  static final RefreshService _instance = RefreshService._internal();

  final PluginManager _pluginManager = PluginManager();

  /// Cached outputs - single source of truth
  final Map<String, PluginOutput> _lastOutputs = {};

  /// Listeners notified when a plugin output is updated
  final List<PluginOutputCallback> _outputListeners = [];

  /// Listeners notified when plugin list changes (enable/disable/add/remove)
  final List<PluginListChangedCallback> _listChangedListeners = [];

  /// Currently running plugins (for preventing concurrent execution)
  final Set<String> _runningPlugins = {};

  /// Mutex for preventing race conditions during refreshAll
  bool _refreshAllInProgress = false;

  /// Get all cached outputs (read-only)
  Map<String, PluginOutput> get lastOutputs => Map.unmodifiable(_lastOutputs);

  /// Get cached output for a specific plugin
  PluginOutput? getLastOutput(String pluginId) => _lastOutputs[pluginId];

  /// Check if a plugin is currently running
  bool isRunning(String pluginId) => _runningPlugins.contains(pluginId);

  /// Check if refreshAll is in progress
  bool get isRefreshAllInProgress => _refreshAllInProgress;

  /// Add listener for output updates
  void addOutputListener(PluginOutputCallback callback) {
    if (!_outputListeners.contains(callback)) {
      _outputListeners.add(callback);
    }
  }

  /// Remove listener for output updates
  void removeOutputListener(PluginOutputCallback callback) {
    _outputListeners.remove(callback);
  }

  /// Add listener for plugin list changes
  void addListChangedListener(PluginListChangedCallback callback) {
    if (!_listChangedListeners.contains(callback)) {
      _listChangedListeners.add(callback);
    }
  }

  /// Remove listener for plugin list changes
  void removeListChangedListener(PluginListChangedCallback callback) {
    _listChangedListeners.remove(callback);
  }

  /// Run a single plugin and notify all listeners.
  ///
  /// This is the core method that should be used by ALL components
  /// that need to execute a plugin (UI, scheduler, IPC, etc.).
  ///
  /// Returns the plugin output, or null if plugin not found or already running.
  Future<PluginOutput?> runPlugin(String pluginId) async {
    // Prevent concurrent execution of the same plugin
    if (_runningPlugins.contains(pluginId)) {
      return _lastOutputs[pluginId];
    }

    final plugin = _pluginManager.getPlugin(pluginId);
    if (plugin == null) return null;

    _runningPlugins.add(pluginId);

    try {
      final output = await _pluginManager.runPlugin(pluginId);
      if (output != null) {
        _lastOutputs[pluginId] = output;
        _notifyOutputListeners(pluginId, output);
      }
      return output;
    } finally {
      _runningPlugins.remove(pluginId);
    }
  }

  /// Run all enabled plugins and notify listeners for each.
  ///
  /// Uses batching to prevent overload.
  Future<List<PluginOutput>> runAllEnabled() async {
    if (_refreshAllInProgress) {
      // Return cached outputs if refresh already in progress
      return _lastOutputs.values.toList();
    }

    _refreshAllInProgress = true;
    final outputs = <PluginOutput>[];

    try {
      final enabledPlugins = _pluginManager.plugins.where((p) => p.enabled).toList();

      // Run in batches of 5 to prevent overload
      const batchSize = 5;
      for (var i = 0; i < enabledPlugins.length; i += batchSize) {
        final batch = enabledPlugins.skip(i).take(batchSize);
        final batchOutputs = await Future.wait(
          batch.map((plugin) => runPlugin(plugin.id)),
        );
        outputs.addAll(batchOutputs.whereType<PluginOutput>());
      }
    } finally {
      _refreshAllInProgress = false;
    }

    return outputs;
  }

  /// Toggle plugin enabled state and reschedule.
  ///
  /// This method ensures proper synchronization between:
  /// - PluginManager state
  /// - Scheduler timers
  /// - Tray menu
  /// - Widget updates
  Future<void> togglePlugin(String pluginId) async {
    await _pluginManager.togglePlugin(pluginId);
    _notifyListChangedListeners();

    // Check if plugin exists with original ID
    var plugin = _pluginManager.getPlugin(pluginId);
    
    // If not found, it might have been renamed (e.g. .off removed)
    if (plugin == null && pluginId.contains('.off.')) {
      final newId = pluginId.replaceFirst('.off.', '.');
      plugin = _pluginManager.getPlugin(newId);
    } else if (plugin == null) {
      // Plugin disabled and renamed to .off
      _lastOutputs.remove(pluginId);
      return;
    }

    // If now enabled (and found), run immediately and cache output
    if (plugin != null && plugin.enabled) {
      await runPlugin(plugin.id);
    } else if (plugin != null && !plugin.enabled) {
      // If disabled (but ID stayed same for some reason), clear cached output
      _lastOutputs.remove(plugin.id);
    }
  }

  /// Enable a plugin and run it immediately
  Future<void> enablePlugin(String pluginId) async {
    await _pluginManager.enablePlugin(pluginId);
    _notifyListChangedListeners();

    // Try to find the plugin with the new ID (without .off.)
    var plugin = _pluginManager.getPlugin(pluginId);
    if (plugin == null && pluginId.contains('.off.')) {
      final newId = pluginId.replaceFirst('.off.', '.');
      plugin = _pluginManager.getPlugin(newId);
    }

    if (plugin != null) {
      await runPlugin(plugin.id);
    }
  }

  /// Disable a plugin and clear its output
  Future<void> disablePlugin(String pluginId) async {
    await _pluginManager.disablePlugin(pluginId);
    _lastOutputs.remove(pluginId);
    _notifyListChangedListeners();
  }

  /// Switch active language variant for a plugin
  Future<void> switchPluginVariant(String pluginId, PluginVariant variant) async {
    await _pluginManager.switchPluginVariant(pluginId, variant);
    _notifyListChangedListeners();
    
    // Clear old output and run new variant
    _lastOutputs.remove(pluginId);
    await runPlugin(pluginId);
  }

  /// Discover plugins and refresh the list
  Future<void> discoverPlugins() async {
    await _pluginManager.discoverPlugins();
    _notifyListChangedListeners();
  }

  /// Clear cached output for a plugin
  void clearOutput(String pluginId) {
    _lastOutputs.remove(pluginId);
  }

  /// Get plugin by ID (delegates to PluginManager)
  Plugin? getPlugin(String pluginId) => _pluginManager.getPlugin(pluginId);

  /// Get all plugins (delegates to PluginManager)
  List<Plugin> get plugins => _pluginManager.plugins;

  /// Notify all output listeners
  void _notifyOutputListeners(String pluginId, PluginOutput output) {
    for (final listener in List.of(_outputListeners)) {
      try {
        listener(pluginId, output);
      } catch (_) {
        // Ignore listener errors to prevent cascade failures
      }
    }
  }

  /// Notify all list changed listeners
  void _notifyListChangedListeners() {
    for (final listener in List.of(_listChangedListeners)) {
      try {
        listener();
      } catch (_) {
        // Ignore listener errors to prevent cascade failures
      }
    }
  }

  /// Clear all state (for testing)
  @visibleForTesting
  void resetForTesting() {
    _lastOutputs.clear();
    _runningPlugins.clear();
    _outputListeners.clear();
    _listChangedListeners.clear();
    _refreshAllInProgress = false;
  }

  /// Dispose and clean up
  void dispose() {
    _outputListeners.clear();
    _listChangedListeners.clear();
    _lastOutputs.clear();
    _runningPlugins.clear();
  }
}
