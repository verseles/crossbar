import 'dart:async';

import 'package:flutter/material.dart' show TimeOfDay;
import 'package:meta/meta.dart';

import '../core/plugin_manager.dart';
import '../models/plugin.dart';
import '../models/plugin_output.dart';
import 'notification_service.dart';
import 'refresh_service.dart';
import 'settings_service.dart';
import 'widget_service.dart';

class SchedulerService {
  factory SchedulerService() => _instance;
  SchedulerService._internal();
  static final SchedulerService _instance = SchedulerService._internal();

  final PluginManager _pluginManager = PluginManager();
  final NotificationService _notificationService = NotificationService();
  final WidgetService _widgetService = WidgetService();
  final RefreshService _refreshService = RefreshService();

  final Map<String, Timer> _timers = {};
  StreamSubscription? _pluginOutputSubscription;

  bool _running = false;
  bool get isRunning => _running;

  Future<void> start() async {
    if (_running) return;
    _running = true;

    await _widgetService.init();
    await _notificationService.init();
    await _pluginManager.discoverPlugins();

    _pluginOutputSubscription =
        _refreshService.pluginOutputEventStream.listen(_onPluginOutput);

    SettingsService().addListener(_onSettingsChanged);
    await _updatePersistentNotification();

    for (final plugin in _pluginManager.plugins) {
      if (plugin.enabled) {
        _schedulePlugin(plugin);
      }
    }
  }

  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    SettingsService().removeListener(_onSettingsChanged);
    _pluginOutputSubscription?.cancel();
    _timers.values.forEach((timer) => timer.cancel());
    _timers.clear();
    await _notificationService.hidePersistentNotification();
  }

  void _onSettingsChanged() {
    _updatePersistentNotification();
  }

  Future<void> _updatePersistentNotification() async {
    if (SettingsService().showInTray) {
      final enabledCount =
          _pluginManager.plugins.where((p) => p.enabled).length;
      await _notificationService.showPersistentNotification(
        enabledPlugins: enabledCount,
      );
    } else {
      await _notificationService.hidePersistentNotification();
    }
  }

  void _schedulePlugin(Plugin plugin) {
    _timers[plugin.id]?.cancel();
    _refreshService.refreshPlugin(plugin.id);
    _timers[plugin.id] = Timer.periodic(
      plugin.refreshInterval,
      (_) => _refreshService.refreshPlugin(plugin.id),
    );
  }

  void _onPluginOutput(PluginOutput output) {
    _widgetService.updateWidget(output.pluginId, output);

    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    _notificationService.updatePersistentNotification(
      enabledPlugins: _pluginManager.plugins.where((p) => p.enabled).length,
      lastUpdate: timeStr,
    );

    if (output.hasError) {
      _notificationService.showErrorNotification(
        pluginId: output.pluginId,
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

  Future<void> runPluginNow(String pluginId) async {
    await _refreshService.refreshPlugin(pluginId);
  }

  Future<void> refreshAll() async {
    await _refreshService.refreshAll();
  }

  PluginOutput? getLastOutput(String pluginId) {
    return _refreshService.getOutput(pluginId);
  }

  void clearLastOutput(String pluginId) {
    _refreshService.clearOutput(pluginId);
  }

  void dispose() {
    stop();
  }

  @visibleForTesting
  void resetForTesting() {
    stop();
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
