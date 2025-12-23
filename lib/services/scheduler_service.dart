import 'dart:async';

import 'package:crossbar_core/crossbar_core.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:meta/meta.dart';

import '../core/plugin_manager.dart';
import 'notification_service.dart';
import 'refresh_service.dart';
import 'settings_service.dart';
import 'widget_service.dart';

/// Callback type for plugin output updates (legacy - use RefreshService.addOutputListener)
typedef PluginOutputCallback = void Function(String pluginId, PluginOutput output);

/// SchedulerService - Manages plugin refresh timers.
///
/// This service is responsible for:
/// - Scheduling periodic plugin executions
/// - Managing timer lifecycle (start/stop/reschedule)
///
/// All actual plugin execution is delegated to RefreshService,
/// which is the single source of truth for plugin outputs.
class SchedulerService {
  factory SchedulerService() => _instance;

  SchedulerService._internal();

  static final SchedulerService _instance = SchedulerService._internal();

  final PluginManager _pluginManager = PluginManager();
  final RefreshService _refreshService = RefreshService();
  final NotificationService _notificationService = NotificationService();
  final WidgetService _widgetService = WidgetService();

  final Map<String, Timer> _timers = {};

  bool _running = false;

  bool get isRunning => _running;

  /// Get last outputs from RefreshService (single source of truth)
  Map<String, PluginOutput> get lastOutputs => _refreshService.lastOutputs;

  /// Add listener for output updates (delegates to RefreshService)
  void addListener(PluginOutputCallback callback) {
    _refreshService.addOutputListener(callback);
  }

  /// Remove listener for output updates (delegates to RefreshService)
  void removeListener(PluginOutputCallback callback) {
    _refreshService.removeOutputListener(callback);
  }

  Future<void> start() async {
    if (_running) return;

    _running = true;

    // Initialize services for mobile platforms
    await _widgetService.init();
    await _notificationService.init();

    await _pluginManager.discoverPlugins();

    // Show persistent notification on Android if enabled
    SettingsService().addListener(_onSettingsChanged);
    await _updatePersistentNotification();

    // Register widget update listener
    _refreshService.addOutputListener(_onPluginOutput);

    for (final plugin in _pluginManager.plugins) {
      if (plugin.enabled) {
        _schedulePlugin(plugin);
      }
    }
  }

  Future<void> stop() async {
    _running = false;
    SettingsService().removeListener(_onSettingsChanged);
    _refreshService.removeOutputListener(_onPluginOutput);

    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();

    // Hide persistent notification
    await _notificationService.hidePersistentNotification();
  }

  void _onSettingsChanged() {
    _updatePersistentNotification();
  }

  Future<void> _updatePersistentNotification() async {
    if (SettingsService().showInTray) {
      final enabledCount = _pluginManager.plugins.where((p) => p.enabled).length;
      await _notificationService.showPersistentNotification(
        enabledPlugins: enabledCount,
      );
    } else {
      await _notificationService.hidePersistentNotification();
    }
  }

  /// Callback when a plugin output is updated (from RefreshService)
  Future<void> _onPluginOutput(String pluginId, PluginOutput output) async {
    // Update widget
    await _widgetService.updateWidget(pluginId, output);

    // Update persistent notification with latest time
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    await _notificationService.updatePersistentNotification(
      enabledPlugins: _pluginManager.plugins.where((p) => p.enabled).length,
      lastUpdate: timeStr,
    );

    // Handle error notifications
    if (output.hasError) {
      await _notificationService.showErrorNotification(
        pluginId: pluginId,
        error: output.errorMessage ?? 'Unknown error',
      );
    }
  }

  void _schedulePlugin(Plugin plugin) {
    _timers[plugin.id]?.cancel();

    // Run immediately first via RefreshService
    _refreshService.runPlugin(plugin.id);

    // Then schedule periodic runs
    _timers[plugin.id] = Timer.periodic(
      plugin.refreshInterval,
      (_) => _runScheduledPlugin(plugin),
    );
  }

  Future<void> _runScheduledPlugin(Plugin plugin) async {
    if (!_running) return;
    if (!plugin.enabled) return;

    await _refreshService.runPlugin(plugin.id);
  }

  /// Reschedule a plugin (e.g., after enable/disable or interval change)
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

  /// Run a plugin immediately (delegates to RefreshService)
  Future<PluginOutput?> runPluginNow(String pluginId) async {
    return _refreshService.runPlugin(pluginId);
  }

  /// Refresh all enabled plugins (delegates to RefreshService)
  Future<void> refreshAll() async {
    await _refreshService.runAllEnabled();
  }

  /// Get last output for a plugin (delegates to RefreshService)
  PluginOutput? getLastOutput(String pluginId) {
    return _refreshService.getLastOutput(pluginId);
  }

  /// Clear last output for a plugin (delegates to RefreshService)
  void clearLastOutput(String pluginId) {
    _refreshService.clearOutput(pluginId);
  }

  void dispose() {
    stop();
  }

  @visibleForTesting
  void resetForTesting() {
    stop();
    // ignore: invalid_use_of_visible_for_testing_member
    _refreshService.resetForTesting();
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
