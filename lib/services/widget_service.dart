import 'dart:convert';
import 'dart:io';

import 'package:home_widget/home_widget.dart';

import 'package:crossbar_core/crossbar_core.dart';
import 'logger_service.dart';
import 'refresh_service.dart';

/// WidgetService - Manages mobile home screen widgets (Android/iOS).
///
/// This service handles:
/// - Storing widget data in UserDefaults/SharedPreferences
/// - Triggering native widget updates
/// - Handling widget click events
///
/// Widget updates are triggered by RefreshService through listeners,
/// ensuring consistent data across UI, Tray, and Widgets.
class WidgetService {
  factory WidgetService() => _instance;

  WidgetService._internal();

  static final WidgetService _instance = WidgetService._internal();

  static const String appGroupId = 'group.crossbar.widgets';
  static const String iOSWidgetName = 'CrossbarWidget';

  // Android has 3 separate widget classes - we must update ALL of them
  // The old 'CrossbarWidgetProvider' name was WRONG and caused widgets to never update
  static const List<String> androidWidgetNames = [
    'CrossbarWidgetSmall',
    'CrossbarWidgetMedium',
    'CrossbarWidgetLarge',
  ];

  final RefreshService _refreshService = RefreshService();
  final Map<String, PluginOutput> _widgetData = {};

  bool _initialized = false;

  /// Check if service has been initialized
  bool get isInitialized => _initialized;

  Future<void> init() async {
    if (_initialized) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;

    if (Platform.isIOS) {
      await HomeWidget.setAppGroupId(appGroupId);
    }

    // Register callback for when widget is clicked
    HomeWidget.widgetClicked.listen(_handleWidgetClick);

    // Note: Widget refresh handler is registered early in main.dart
    // to catch requests before WidgetService is initialized

    _initialized = true;
  }

  void _handleWidgetClick(Uri? uri) {
    if (uri == null) return;

    final pluginId = uri.queryParameters['pluginId'];
    if (pluginId != null) {
      // Handle plugin click - could open app to plugin details
      // or execute a specific action
    }
  }

  /// Update widget data for a plugin.
  ///
  /// This method is typically called by SchedulerService (via RefreshService listener)
  /// to keep widgets in sync with plugin outputs.
  Future<void> updateWidget(String pluginId, PluginOutput output) async {
    if (!_initialized) return;

    _widgetData[pluginId] = output;

    LoggerService().info(
      'WidgetService: update widget',
      details: 'pluginId=$pluginId',
      category: LogCategory.widgets,
    );

    // Store data for the widget
    await _saveWidgetOutput(pluginId, output);

    // Update all widgets
    await _triggerWidgetUpdate();
  }

  /// Trigger update for all Android widgets or iOS widget
  Future<void> _triggerWidgetUpdate() async {
    if (Platform.isAndroid) {
      // Must update ALL 3 widget types - each is a separate receiver
      for (final widgetName in androidWidgetNames) {
        try {
          LoggerService().debug(
            'WidgetService: trigger update',
            details: 'widgetName=$widgetName',
            category: LogCategory.widgets,
          );
          await HomeWidget.updateWidget(
            name: widgetName,
            androidName: widgetName,
          );
        } catch (e) {
          // Log but continue - some widgets might not be on screen
          // ignore: avoid_print
          print('WidgetService: Failed to update $widgetName: $e');
        }
      }
    } else if (Platform.isIOS) {
      await HomeWidget.updateWidget(
        name: iOSWidgetName,
        iOSName: iOSWidgetName,
      );
    }
  }

  /// Update all widgets by running all enabled plugins.
  ///
  /// Uses RefreshService to ensure consistent behavior and proper
  /// notification of all listeners.
  Future<void> updateAllWidgets() async {
    if (!_initialized) return;

    LoggerService().info(
      'WidgetService: update all widgets',
      category: LogCategory.widgets,
    );

    // Use RefreshService - this will notify listeners including SchedulerService
    // which will call updateWidget() for each plugin output
    final outputs = await _refreshService.runAllEnabled();

    // Also directly update widgets for outputs (belt and suspenders approach)
    for (final output in outputs) {
      await updateWidget(output.pluginId, output);
    }
  }

  /// Sync widget data with the current plugin list and cached outputs.
  ///
  /// This is used to keep widgets consistent after enable/disable or
  /// plugin discovery without waiting for the next scheduled run.
  Future<void> syncWithOutputs(
    List<Plugin> plugins,
    Map<String, PluginOutput> outputs,
  ) async {
    if (!_initialized) return;

    LoggerService().info(
      'WidgetService: sync outputs',
      details: 'plugins=${plugins.length} outputs=${outputs.length}',
      category: LogCategory.widgets,
    );

    final enabledIds = plugins
        .where((p) => p.enabled)
        .map((p) => p.id)
        .toList();
    final removedIds = _widgetData.keys
        .where((id) => !enabledIds.contains(id))
        .toList();

    for (final removedId in removedIds) {
      _widgetData.remove(removedId);
      await _removeWidgetOutput(removedId);
    }

    for (final pluginId in enabledIds) {
      final output = outputs[pluginId];
      if (output == null) continue;

      _widgetData[pluginId] = output;
      await _saveWidgetOutput(pluginId, output);
    }

    await HomeWidget.saveWidgetData<String>(
      'plugin_ids',
      jsonEncode(enabledIds),
    );

    await _triggerWidgetUpdate();
  }

  Future<void> clearWidget(String pluginId) async {
    if (!_initialized) return;

    LoggerService().info(
      'WidgetService: clear widget',
      details: 'pluginId=$pluginId',
      category: LogCategory.widgets,
    );

    _widgetData.remove(pluginId);

    await _removeWidgetOutput(pluginId);

    await _triggerWidgetUpdate();
  }

  Future<void> requestWidgetPin(String pluginId) async {
    if (!Platform.isAndroid) return;

    // Request Android to pin the small widget (most common)
    await HomeWidget.requestPinWidget(
      name: androidWidgetNames.first,
      androidName: androidWidgetNames.first,
    );
  }

  Future<bool> isWidgetInstalled() async {
    if (!_initialized) return false;

    try {
      // Check if widget is available
      return await HomeWidget.getWidgetData<String>('plugin_ids') != null;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _initialized = false;
    _widgetData.clear();
  }

  Future<void> _saveWidgetOutput(String pluginId, PluginOutput output) async {
    final payload = jsonEncode(output.toJson());
    await HomeWidget.saveWidgetData<String>('plugin_$pluginId', payload);

    final aliasId = _canonicalPluginId(pluginId);
    if (aliasId != pluginId) {
      await HomeWidget.saveWidgetData<String>('plugin_$aliasId', payload);
    }
  }

  Future<void> _removeWidgetOutput(String pluginId) async {
    await HomeWidget.saveWidgetData<String?>('plugin_$pluginId', null);

    final aliasId = _canonicalPluginId(pluginId);
    if (aliasId != pluginId) {
      await HomeWidget.saveWidgetData<String?>('plugin_$aliasId', null);
    }
  }

  String _canonicalPluginId(String pluginId) {
    final withoutOff = pluginId.replaceFirst('.off.', '.');
    final match = RegExp(
      r'^(.+?)\.(?:\d+(?:\.\d+)?)[smh]\.',
    ).firstMatch(withoutOff);
    return match?.group(1) ?? withoutOff;
  }
}

class WidgetDataBuilder {
  const WidgetDataBuilder({
    required this.pluginId,
    this.icon,
    this.title,
    this.subtitle,
    this.value,
    this.color,
    this.deepLink,
  });

  factory WidgetDataBuilder.fromPluginOutput(PluginOutput output) {
    return WidgetDataBuilder(
      pluginId: output.pluginId,
      icon: output.icon,
      title: output.pluginId,
      value: output.text,
      color: output.color?.toRadixString(16),
      deepLink: 'crossbar://plugin/${output.pluginId}',
    );
  }
  final String pluginId;
  final String? icon;
  final String? title;
  final String? subtitle;
  final String? value;
  final String? color;
  final String? deepLink;

  Map<String, dynamic> toJson() {
    return {
      'pluginId': pluginId,
      'icon': icon,
      'title': title,
      'subtitle': subtitle,
      'value': value,
      'color': color,
      'deepLink': deepLink,
    };
  }
}
