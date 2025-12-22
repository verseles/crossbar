import 'dart:convert';
import 'dart:io';

import 'package:home_widget/home_widget.dart';
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
  // Initialize HomeWidget
  await HomeWidget.setAppGroupId('group.crossbar.widgets');

  // Discover plugins
  final pluginManager = PluginManager();
  await pluginManager.discoverPlugins();

  // Get enabled plugins
  final enabledPlugins =
      pluginManager.plugins.where((p) => p.enabled).toList();

  if (enabledPlugins.isEmpty) return;

  // Execute compatible plugins and save data
  final executor = PluginExecutor();
  final pluginIds = <String>[];

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
      pluginIds.add(plugin.id);
    } catch (e) {
      // Skip failing plugins in background
      continue;
    }
  }

  // Update plugin IDs list
  if (pluginIds.isNotEmpty) {
    await HomeWidget.saveWidgetData<String>(
      'plugin_ids',
      jsonEncode(pluginIds),
    );

    // Trigger widget update for ALL widget types
    // Each widget class is a separate receiver and must be updated individually
    const widgetNames = [
      'CrossbarWidgetSmall',
      'CrossbarWidgetMedium',
      'CrossbarWidgetLarge',
    ];

    for (final widgetName in widgetNames) {
      try {
        await HomeWidget.updateWidget(
          name: widgetName,
          androidName: widgetName,
        );
      } catch (_) {
        // Ignore - widget might not be on screen
      }
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

  /// Check if service has been initialized
  bool get isInitialized => _initialized;

  /// Initialize the background service (Android only).
  /// Should be called early in main() after WidgetsFlutterBinding.
  Future<void> init() async {
    if (_initialized) return;
    if (!Platform.isAndroid) return;

    await Workmanager().initialize(
      callbackDispatcher,
    );

    // Register periodic task
    await Workmanager().registerPeriodicTask(
      kWidgetUpdateTask,
      kWidgetUpdateTask,
      frequency: kMinUpdateInterval,
      constraints: Constraints(
        networkType: NetworkType.notRequired,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );

    _initialized = true;
  }

  /// Cancel all background tasks
  Future<void> cancelAll() async {
    if (!Platform.isAndroid) return;
    await Workmanager().cancelAll();
    _initialized = false;
  }

  /// Cancel specific widget update task
  Future<void> cancelWidgetUpdates() async {
    if (!Platform.isAndroid) return;
    await Workmanager().cancelByUniqueName(kWidgetUpdateTask);
  }
}
