import 'dart:convert';
import 'dart:io';

import 'package:home_widget/home_widget.dart';

import '../models/plugin_output.dart';
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
  static const String androidWidgetName = 'CrossbarWidgetProvider';

  final RefreshService _refreshService = RefreshService();
  final Map<String, PluginOutput> _widgetData = {};

  bool _initialized = false;

  /// Check if service has been initialized
  bool get isInitialized => _initialized;

  Future<void> init() async {
    if (_initialized) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;

    await HomeWidget.setAppGroupId(appGroupId);

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

    // Store data for the widget
    await HomeWidget.saveWidgetData<String>(
      'plugin_$pluginId',
      jsonEncode(output.toJson()),
    );

    // Store list of all plugin IDs
    await HomeWidget.saveWidgetData<String>(
      'plugin_ids',
      jsonEncode(_widgetData.keys.toList()),
    );

    // Update the widget
    if (Platform.isAndroid) {
      await HomeWidget.updateWidget(
        name: androidWidgetName,
        androidName: androidWidgetName,
      );
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

    // Use RefreshService - this will notify listeners including SchedulerService
    // which will call updateWidget() for each plugin output
    final outputs = await _refreshService.runAllEnabled();

    // Also directly update widgets for outputs (belt and suspenders approach)
    for (final output in outputs) {
      await updateWidget(output.pluginId, output);
    }
  }

  Future<void> clearWidget(String pluginId) async {
    if (!_initialized) return;

    _widgetData.remove(pluginId);

    await HomeWidget.saveWidgetData<String?>(
      'plugin_$pluginId',
      null,
    );

    await HomeWidget.saveWidgetData<String>(
      'plugin_ids',
      jsonEncode(_widgetData.keys.toList()),
    );

    if (Platform.isAndroid) {
      await HomeWidget.updateWidget(
        name: androidWidgetName,
        androidName: androidWidgetName,
      );
    } else if (Platform.isIOS) {
      await HomeWidget.updateWidget(
        name: iOSWidgetName,
        iOSName: iOSWidgetName,
      );
    }
  }

  Future<void> requestWidgetPin(String pluginId) async {
    if (!Platform.isAndroid) return;

    // Request Android to pin the widget to home screen
    await HomeWidget.requestPinWidget(
      name: androidWidgetName,
      androidName: androidWidgetName,
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
