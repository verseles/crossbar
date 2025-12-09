import 'dart:convert';
import 'dart:io';

import 'package:crossbar/core/plugin_manager.dart';
import 'package:crossbar/core/navigation.dart';
import 'package:crossbar/services/logger_service.dart';
import 'package:crossbar/ui/dialogs/widget_configuration_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages Android Home Screen Widgets.
class WidgetService {
  static const MethodChannel _channel = MethodChannel('com.verseles.crossbar/widget');

  // Singleton instance
  static final WidgetService _instance = WidgetService._internal();
  factory WidgetService() => _instance;
  WidgetService._internal();

  SharedPreferences? _prefs;
  static const String _activeWidgetsKey = 'crossbar_active_widgets';
  static const String _widgetConfigPrefix = 'crossbar_widget_config_';

  bool get isInitialized => _prefs != null;

  @visibleForTesting
  bool forcePlatformCheck = false;

  /// Initializes the service and sets up method call handlers.
  Future<void> init() async {
    if (!forcePlatformCheck && !Platform.isAndroid) return;

    _prefs = await SharedPreferences.getInstance();

    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'refresh':
          // Native side requested a refresh (e.g. widget tap or update period)
          await PluginManager().refreshAll();
          await updateWidgets();
          break;
        case 'configureWidget':
             final args = call.arguments as Map;
             final int widgetId = args['widgetId'];
             // widgetType sent from native: 'small', 'medium', 'large'
             final String size = args['type'] ?? 'small';
             _showConfigurationDialog(widgetId, size);
             break;
        case 'widgetDeleted':
             final args = call.arguments as Map;
             final int widgetId = args['widgetId'];
             await _removeWidgetConfig(widgetId);
             break;
        default:
          break;
      }
    });
  }

  void _showConfigurationDialog(int widgetId, String size) {
    // Ensure we have a navigator context
    final context = navigatorKey.currentContext;
    if (context != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => WidgetConfigurationDialog(
            widgetId: widgetId,
            widgetSize: size,
          ),
        ),
      );
    } else {
        print('WidgetService: No navigator context available to show dialog');
    }
  }

  Future<void> finishConfiguration(int widgetId, List<String> pluginIds) async {
    if (_prefs == null) return;

    // Save config
    await _prefs!.setStringList('$_widgetConfigPrefix$widgetId', pluginIds);

    // Add to active set
    final active = _prefs!.getStringList(_activeWidgetsKey) ?? [];
    if (!active.contains(widgetId.toString())) {
      active.add(widgetId.toString());
      await _prefs!.setStringList(_activeWidgetsKey, active);
    }

    // Notify native that config is done
    try {
        await _channel.invokeMethod('configurationFinished', {'widgetId': widgetId, 'success': true});
    } catch (e) {
        print('Error calling configurationFinished: $e');
    }

    // Force an update so the widget shows data immediately
    // We might want to run the selected plugins first if they haven't run
    for(final pid in pluginIds) {
        if (PluginManager().getLastOutput(pid) == null) {
            await PluginManager().runPlugin(pid);
        }
    }
    await updateWidgets();
  }

  // Alias for main.dart compatibility if needed
  Future<void> updateAllWidgets() => updateWidgets();

  Future<void> cancelConfiguration(int widgetId) async {
    try {
        await _channel.invokeMethod('configurationFinished', {'widgetId': widgetId, 'success': false});
    } catch (e) {
        print('Error calling configurationFinished (cancel): $e');
    }
  }

  Future<void> _removeWidgetConfig(int widgetId) async {
      if (_prefs == null) return;
      await _prefs!.remove('$_widgetConfigPrefix$widgetId');
       final active = _prefs!.getStringList(_activeWidgetsKey) ?? [];
       if (active.remove(widgetId.toString())) {
           await _prefs!.setStringList(_activeWidgetsKey, active);
       }
  }

  /// Updates all widgets with the latest data from [PluginManager].
  Future<void> updateWidgets() async {
    if (!Platform.isAndroid || _prefs == null) return;

    final activeWidgets = _prefs!.getStringList(_activeWidgetsKey) ?? [];

    // Payload: Map<String(WidgetID), List<Data>>
    final Map<String, dynamic> widgetsPayload = {};

    for (final idStr in activeWidgets) {
        final pluginIds = _prefs!.getStringList('$_widgetConfigPrefix$idStr') ?? [];
        final List<Map<String, dynamic>> widgetData = [];

        for (final pId in pluginIds) {
             final output = PluginManager().getLastOutput(pId);
             final plugin = PluginManager().getPlugin(pId);
             final title = plugin?.id ?? pId;

             if (output != null && (output.text?.isNotEmpty ?? false)) {
                // Use the output text
                String text = output.text!;
                text = text.replaceAll(RegExp(r'\x1B\[[0-?]*[ -/]*[@-~]'), '');

                widgetData.add({
                  'id': pId,
                  'title': title,
                  'text': text,
                });
             } else {
                 widgetData.add({
                     'id': pId,
                     'title': title,
                     'text': 'Loading...',
                 });
             }
        }
        widgetsPayload[idStr] = widgetData;
    }

    try {
      await _channel.invokeMethod('updateWidgets', {
        'data': jsonEncode(widgetsPayload),
      });
    } catch (e) {
      print('Failed to update widgets: $e');
    }
  }
}
