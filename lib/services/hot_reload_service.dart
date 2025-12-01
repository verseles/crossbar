import 'dart:io';

import '../core/plugin_manager.dart';
import '../utils/file_watcher.dart';
import 'logger_service.dart';
import 'scheduler_service.dart';

typedef HotReloadCallback = void Function(String pluginId, HotReloadEvent event);

enum HotReloadEvent {
  pluginAdded,
  pluginModified,
  pluginDeleted,
  configChanged,
}

class HotReloadService {
  static final HotReloadService _instance = HotReloadService._internal();

  factory HotReloadService() => _instance;

  HotReloadService._internal();

  final PluginManager _pluginManager = PluginManager();
  final SchedulerService _schedulerService = SchedulerService();
  final LoggerService _logger = LoggerService();

  FileWatcher? _watcher;
  final List<HotReloadCallback> _listeners = [];
  bool _enabled = true;
  bool _initialized = false;

  bool get isEnabled => _enabled;
  set enabled(bool value) => _enabled = value;

  bool get isInitialized => _initialized;

  void addListener(HotReloadCallback callback) {
    _listeners.add(callback);
  }

  void removeListener(HotReloadCallback callback) {
    _listeners.remove(callback);
  }

  Future<void> init() async {
    if (_initialized) return;

    final pluginsDir = Directory(_pluginManager.pluginsDirectory);

    // Create plugins directory if it doesn't exist
    if (!pluginsDir.existsSync()) {
      pluginsDir.createSync(recursive: true);
    }

    _watcher = FileWatcher(
      debounceDelay: const Duration(milliseconds: 500),
      onFileChanged: _onFileChanged,
    );

    _watcher!.watch(pluginsDir);
    _initialized = true;

    _logger.info('HotReloadService initialized, watching: ${pluginsDir.path}');
  }

  void _onFileChanged(String path, FileSystemEvent event) {
    if (!_enabled) return;

    final pluginId = _extractPluginId(path);
    if (pluginId == null) return;

    _logger.debug('File changed: $path (${event.type})');

    HotReloadEvent reloadEvent;

    if (event is FileSystemCreateEvent) {
      reloadEvent = path.endsWith('.json')
          ? HotReloadEvent.configChanged
          : HotReloadEvent.pluginAdded;
      _handlePluginAdded(pluginId);
    } else if (event is FileSystemModifyEvent) {
      reloadEvent = path.endsWith('.json')
          ? HotReloadEvent.configChanged
          : HotReloadEvent.pluginModified;
      _handlePluginModified(pluginId);
    } else if (event is FileSystemDeleteEvent) {
      reloadEvent = HotReloadEvent.pluginDeleted;
      _handlePluginDeleted(pluginId);
    } else {
      return;
    }

    // Notify listeners
    for (final listener in _listeners) {
      listener(pluginId, reloadEvent);
    }
  }

  String? _extractPluginId(String path) {
    final file = File(path);
    final name = file.uri.pathSegments.last;

    // Remove .json extension for config files
    if (name.endsWith('.json')) {
      return name.substring(0, name.length - 5);
    }

    // Check if it's a valid plugin file
    final extensions = ['.sh', '.py', '.js', '.dart', '.go', '.rs'];
    for (final ext in extensions) {
      if (name.endsWith(ext)) {
        return name;
      }
    }

    return null;
  }

  Future<void> _handlePluginAdded(String pluginId) async {
    _logger.info('Plugin added: $pluginId');

    // Rediscover plugins
    await _pluginManager.discoverPlugins();

    // Schedule the new plugin
    _schedulerService.reschedulePlugin(pluginId);
  }

  Future<void> _handlePluginModified(String pluginId) async {
    _logger.info('Plugin modified: $pluginId');

    // Run the plugin immediately to show updated output
    await _schedulerService.runPluginNow(pluginId);
  }

  Future<void> _handlePluginDeleted(String pluginId) async {
    _logger.info('Plugin deleted: $pluginId');

    // Stop scheduling this plugin
    _schedulerService.reschedulePlugin(pluginId);

    // Clear its last output
    _schedulerService.clearLastOutput(pluginId);

    // Rediscover to update plugin list
    await _pluginManager.discoverPlugins();
  }

  Future<void> reloadAll() async {
    _logger.info('Reloading all plugins');

    await _pluginManager.discoverPlugins();
    await _schedulerService.refreshAll();

    for (final listener in _listeners) {
      listener('*', HotReloadEvent.pluginModified);
    }
  }

  void pause() {
    _enabled = false;
    _logger.debug('HotReload paused');
  }

  void resume() {
    _enabled = true;
    _logger.debug('HotReload resumed');
  }

  void dispose() {
    _watcher?.dispose();
    _watcher = null;
    _listeners.clear();
    _initialized = false;
  }
}
