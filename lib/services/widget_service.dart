import 'dart:convert';
import 'dart:io';

import 'package:home_widget/home_widget.dart';
import 'package:workmanager/workmanager.dart';

import '../core/plugin_manager.dart';
import '../models/plugin_output.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Re-initialize necessary components for background execution
    // Note: We cannot use the Singleton instance state here as it is a new isolate

    // We create a temporary PluginManager
    final pluginManager = PluginManager();
    // In background, we might not have all context, but we try to run plugins
    await pluginManager.discoverPlugins();

    final outputs = await pluginManager.runAllEnabled();

    final List<String> pluginIds = [];

    for (final output in outputs) {
      pluginIds.add(output.pluginId);
      final widgetData = WidgetDataBuilder.fromPluginOutput(output).toJson();
      await HomeWidget.saveWidgetData<String>(
        'plugin_${output.pluginId}',
        jsonEncode(widgetData),
      );
    }

    await HomeWidget.saveWidgetData<String>(
      'plugin_ids',
      jsonEncode(pluginIds),
    );

    // Update all widget providers
    for (final name in WidgetService.androidWidgetNames) {
      await HomeWidget.updateWidget(
        name: name,
        androidName: name,
      );
    }

    return Future.value(true);
  });
}

class WidgetService {

  factory WidgetService() => _instance;

  WidgetService._internal();
  static final WidgetService _instance = WidgetService._internal();

  static const String appGroupId = 'group.crossbar.widgets';
  static const String iOSWidgetName = 'CrossbarWidget';

  static const List<String> androidWidgetNames = [
    'CrossbarWidgetProvider',
    'CrossbarWidgetSmallProvider',
    'CrossbarWidgetLargeProvider'
  ];

  // For backward compatibility or direct access
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

    if (Platform.isAndroid) {
       await Workmanager().initialize(callbackDispatcher);
       // Register periodic task (every 15 min)
       await Workmanager().registerPeriodicTask(
         "crossbar_widget_update_task",
         "crossbar_widget_update_task",
         frequency: const Duration(minutes: 15),
         constraints: Constraints(
           networkType: NetworkType.connected,
         ),
       );
    }

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
    final widgetData = WidgetDataBuilder.fromPluginOutput(output).toJson();
    await HomeWidget.saveWidgetData<String>(
      'plugin_$pluginId',
      jsonEncode(widgetData),
    );

    // Store list of all plugin IDs
    await HomeWidget.saveWidgetData<String>(
      'plugin_ids',
      jsonEncode(_widgetData.keys.toList()),
    );

    // Update the widget
    if (Platform.isAndroid) {
      for (final name in androidWidgetNames) {
        await HomeWidget.updateWidget(
          name: name,
          androidName: name,
        );
      }
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
      for (final name in androidWidgetNames) {
        await HomeWidget.updateWidget(
          name: name,
          androidName: name,
        );
      }
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
