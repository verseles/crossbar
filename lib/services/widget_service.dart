import 'dart:convert';
import 'dart:io';

import 'package:home_widget/home_widget.dart';

import '../core/plugin_manager.dart';
import '../models/plugin_output.dart';

class WidgetService {

  factory WidgetService() => _instance;

  WidgetService._internal();
  static final WidgetService _instance = WidgetService._internal();

  static const String appGroupId = 'group.crossbar.widgets';
  static const String iOSWidgetName = 'CrossbarWidget';
  static const String androidWidgetName = 'CrossbarWidgetProvider';

  final PluginManager _pluginManager = PluginManager();
  final Map<String, PluginOutput> _widgetData = {};

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;

    await HomeWidget.setAppGroupId(appGroupId);

    // Register callback for when widget is clicked
    HomeWidget.widgetClicked.listen(_handleWidgetClick);

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

  Future<void> updateAllWidgets() async {
    if (!_initialized) return;

    final outputs = await _pluginManager.runAllEnabled();
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
