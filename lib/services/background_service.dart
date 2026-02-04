import 'dart:convert';
import 'dart:io';

import 'package:crossbar_core/crossbar_core.dart';
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';

import '../core/plugin_executor.dart';
import '../core/plugin_manager.dart';

/// Task identifier for widget updates
const String kWidgetUpdateTask = 'crossbar-widget-update';

/// Minimum interval for periodic tasks (Android WorkManager minimum is 15 min)
const Duration kMinUpdateInterval = Duration(minutes: 15);

/// Top-level callback dispatcher required by WorkManager.
/// This function runs in a separate isolate when the app is in background.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == kWidgetUpdateTask || task == Workmanager.iOSBackgroundTask) {
        await _updateWidgetsInBackground();
      }
      return true;
    } catch (e) {
      // Log error but don't crash the background task
      // ignore: avoid_print
      print('Background task error: $e');
      return false;
    }
  });
}

/// Updates widgets in background without full app initialization
Future<void> _updateWidgetsInBackground() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appDir = await getApplicationDocumentsDirectory();
  CrossbarBridge.instance.appDataDir = appDir.path;

  // Initialize HomeWidget
  await HomeWidget.setAppGroupId('group.crossbar.widgets');

  // Discover plugins
  final pluginManager = PluginManager();
  await pluginManager.discoverPlugins();

  // Get enabled plugins
  final enabledPlugins = pluginManager.plugins.where((p) => p.enabled).toList();

  if (enabledPlugins.isEmpty) return;

  final enabledPluginIds = enabledPlugins.map((p) => p.id).toList();
  await HomeWidget.saveWidgetData<String>(
    'plugin_ids',
    jsonEncode(enabledPluginIds),
  );

  // Execute compatible plugins and save data
  final executor = PluginExecutor();

  for (final plugin in enabledPlugins) {
    // Only run plugins compatible with background execution
    // (Lua, YAML, Dart - not external scripts that need interpreters)
    if (!_isBackgroundCompatible(plugin.path)) continue;

    try {
      final output = await executor.run(plugin);
      // Save plugin data for widget
      await HomeWidget.saveWidgetData<String>(
        'plugin_${plugin.id}',
        jsonEncode(output.toJson()),
      );
    } catch (e) {
      // Skip failing plugins in background
      continue;
    }
  }

  // Trigger widget update for ALL widget types
  // Each widget class is a separate receiver and must be updated individually
  const widgetNames = [
    'CrossbarWidgetSmall',
    'CrossbarWidgetMedium',
    'CrossbarWidgetLarge',
  ];

  for (final widgetName in widgetNames) {
    try {
      await HomeWidget.updateWidget(name: widgetName, androidName: widgetName);
    } catch (_) {
      // Ignore - widget might not be on screen
    }
  }
}

/// Check if plugin can run in background (without external interpreters)
bool _isBackgroundCompatible(String path) {
  final ext = path.toLowerCase();
  // Lua, YAML, and interpreted Dart run in-process
  // External scripts (sh, py, js, go, rs) need system interpreters
  return ext.endsWith('.lua') ||
      ext.endsWith('.yaml') ||
      ext.endsWith('.yml') ||
      ext.endsWith('.dart');
}

/// Background service for managing widget updates when app is closed.
class BackgroundService {
  factory BackgroundService() => _instance;

  BackgroundService._internal();
  static final BackgroundService _instance = BackgroundService._internal();

  bool _initialized = false;
  Duration? _scheduledInterval;

  /// Check if service has been initialized
  bool get isInitialized => _initialized;

  /// Initialize the background service (Android only).
  /// Should be called early in main() after WidgetsFlutterBinding.
  Future<void> init() async {
    if (_initialized) return;
    if (!Platform.isAndroid) return;

    await Workmanager().initialize(callbackDispatcher);

    _initialized = true;
    await syncScheduleWithPlugins();
  }

  Future<void> syncScheduleWithPlugins() async {
    if (!Platform.isAndroid) return;
    if (!_initialized) return;

    final interval = await _resolveWidgetUpdateInterval();
    if (_scheduledInterval == interval) return;

    await Workmanager().registerPeriodicTask(
      kWidgetUpdateTask,
      kWidgetUpdateTask,
      frequency: interval,
      constraints: Constraints(networkType: NetworkType.notRequired),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );

    _scheduledInterval = interval;
  }

  Future<Duration> _resolveWidgetUpdateInterval() async {
    final pluginManager = PluginManager();
    await pluginManager.discoverPlugins();

    final enabledPlugins = pluginManager.plugins
        .where((p) => p.enabled)
        .toList();
    if (enabledPlugins.isEmpty) return kMinUpdateInterval;

    var minInterval = enabledPlugins.first.refreshInterval;
    for (final plugin in enabledPlugins.skip(1)) {
      if (plugin.refreshInterval < minInterval) {
        minInterval = plugin.refreshInterval;
      }
    }

    if (minInterval < kMinUpdateInterval) {
      return kMinUpdateInterval;
    }

    return minInterval;
  }

  /// Cancel all background tasks
  Future<void> cancelAll() async {
    if (!Platform.isAndroid) return;
    await Workmanager().cancelAll();
    _initialized = false;
    _scheduledInterval = null;
  }

  /// Cancel specific widget update task
  Future<void> cancelWidgetUpdates() async {
    if (!Platform.isAndroid) return;
    await Workmanager().cancelByUniqueName(kWidgetUpdateTask);
    _scheduledInterval = null;
  }
}
