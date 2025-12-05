import 'dart:async';

import 'package:flutter/material.dart' show TimeOfDay;
import 'package:meta/meta.dart';

import '../core/plugin_manager.dart';
import '../models/plugin.dart';
import '../models/plugin_output.dart';
import 'notification_service.dart';
import 'widget_service.dart';

typedef PluginOutputCallback = void Function(String pluginId, PluginOutput output);

class SchedulerService {

  factory SchedulerService() => _instance;

  SchedulerService._internal();
  static final SchedulerService _instance = SchedulerService._internal();

  final PluginManager _pluginManager = PluginManager();
  final NotificationService _notificationService = NotificationService();
  final WidgetService _widgetService = WidgetService();

  final Map<String, Timer> _timers = {};
  final Map<String, PluginOutput> _lastOutputs = {};
  final List<PluginOutputCallback> _listeners = [];

  bool _running = false;

  bool get isRunning => _running;

  Map<String, PluginOutput> get lastOutputs => Map.unmodifiable(_lastOutputs);

  void addListener(PluginOutputCallback callback) {
    _listeners.add(callback);
  }

  void removeListener(PluginOutputCallback callback) {
    _listeners.remove(callback);
  }

  Future<void> start() async {
    if (_running) return;

    _running = true;

    await _pluginManager.discoverPlugins();

    for (final plugin in _pluginManager.plugins) {
      if (plugin.enabled) {
        _schedulePlugin(plugin);
      }
    }
  }

  void stop() {
    _running = false;

    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }

  void _schedulePlugin(Plugin plugin) {
    _timers[plugin.id]?.cancel();

    // Run immediately first
    _runPlugin(plugin);

    // Then schedule periodic runs
    _timers[plugin.id] = Timer.periodic(
      plugin.refreshInterval,
      (_) => _runPlugin(plugin),
    );
  }

  Future<void> _runPlugin(Plugin plugin) async {
    if (!_running) return;
    if (!plugin.enabled) return;

    final output = await _pluginManager.runPlugin(plugin.id);
    if (output == null) return;

    _lastOutputs[plugin.id] = output;

    // Notify listeners
    for (final listener in _listeners) {
      listener(plugin.id, output);
    }

    // Update widget
    await _widgetService.updateWidget(plugin.id, output);

    // Handle notifications
    if (output.hasError) {
      await _notificationService.showErrorNotification(
        pluginId: plugin.id,
        error: output.errorMessage ?? 'Unknown error',
      );
    }
  }

  void reschedulePlugin(String pluginId) {
    final plugin = _pluginManager.getPlugin(pluginId);
    if (plugin == null) return;

    if (plugin.enabled) {
      _schedulePlugin(plugin);
    } else {
      _timers[pluginId]?.cancel();
      _timers.remove(pluginId);
    }
  }

  Future<PluginOutput?> runPluginNow(String pluginId) async {
    final plugin = _pluginManager.getPlugin(pluginId);
    if (plugin == null) return null;

    final output = await _pluginManager.runPlugin(pluginId);
    if (output != null) {
      _lastOutputs[pluginId] = output;

      for (final listener in _listeners) {
        listener(pluginId, output);
      }

      await _widgetService.updateWidget(pluginId, output);
    }

    return output;
  }

  Future<void> refreshAll() async {
    for (final plugin in _pluginManager.plugins) {
      if (plugin.enabled) {
        await _runPlugin(plugin);
      }
    }
  }

  PluginOutput? getLastOutput(String pluginId) {
    return _lastOutputs[pluginId];
  }

  void clearLastOutput(String pluginId) {
    _lastOutputs.remove(pluginId);
  }

  void dispose() {
    stop();
    _listeners.clear();
    _lastOutputs.clear();
  }

  @visibleForTesting
  void resetForTesting() {
    stop();
    _listeners.clear();
    _lastOutputs.clear();
  }
}

class PluginScheduleConfig {

  const PluginScheduleConfig({
    this.interval = const Duration(minutes: 5),
    this.runOnStart = true,
    this.runInBackground = true,
    this.startTime,
    this.endTime,
    this.daysOfWeek = const [1, 2, 3, 4, 5, 6, 7],
  });

  factory PluginScheduleConfig.fromJson(Map<String, dynamic> json) {
    return PluginScheduleConfig(
      interval: Duration(milliseconds: json['interval'] as int? ?? 300000),
      runOnStart: json['runOnStart'] as bool? ?? true,
      runInBackground: json['runInBackground'] as bool? ?? true,
      startTime: json['startTime'] != null
          ? TimeOfDay(
              hour: json['startTime']['hour'] as int,
              minute: json['startTime']['minute'] as int,
            )
          : null,
      endTime: json['endTime'] != null
          ? TimeOfDay(
              hour: json['endTime']['hour'] as int,
              minute: json['endTime']['minute'] as int,
            )
          : null,
      daysOfWeek: (json['daysOfWeek'] as List<dynamic>?)
              ?.map((d) => d as int)
              .toList() ??
          [1, 2, 3, 4, 5, 6, 7],
    );
  }
  final Duration interval;
  final bool runOnStart;
  final bool runInBackground;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final List<int> daysOfWeek;

  bool shouldRunNow() {
    final now = DateTime.now();

    // Check day of week
    if (!daysOfWeek.contains(now.weekday)) {
      return false;
    }

    // Check time window
    if (startTime != null && endTime != null) {
      final currentMinutes = now.hour * 60 + now.minute;
      final startMinutes = startTime!.hour * 60 + startTime!.minute;
      final endMinutes = endTime!.hour * 60 + endTime!.minute;

      if (startMinutes < endMinutes) {
        // Normal time range (e.g., 9:00 - 17:00)
        if (currentMinutes < startMinutes || currentMinutes > endMinutes) {
          return false;
        }
      } else {
        // Overnight range (e.g., 22:00 - 6:00)
        if (currentMinutes < startMinutes && currentMinutes > endMinutes) {
          return false;
        }
      }
    }

    return true;
  }

  Map<String, dynamic> toJson() {
    return {
      'interval': interval.inMilliseconds,
      'runOnStart': runOnStart,
      'runInBackground': runInBackground,
      'startTime': startTime != null
          ? {'hour': startTime!.hour, 'minute': startTime!.minute}
          : null,
      'endTime': endTime != null
          ? {'hour': endTime!.hour, 'minute': endTime!.minute}
          : null,
      'daysOfWeek': daysOfWeek,
    };
  }
}
