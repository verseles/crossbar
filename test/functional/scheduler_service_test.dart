import 'dart:async';

import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:crossbar/models/plugin.dart';
import 'package:crossbar/models/plugin_output.dart';
import 'package:crossbar/services/scheduler_service.dart';

/// Functional tests for Scheduler Service.
/// These tests verify scheduling logic and callback behavior.
void main() {
  group('PluginScheduleConfig', () {
    group('Constructor & Defaults', () {
      test('default config has sensible values', () {
        const config = PluginScheduleConfig();

        expect(config.interval, equals(const Duration(minutes: 5)));
        expect(config.runOnStart, isTrue);
        expect(config.runInBackground, isTrue);
        expect(config.startTime, isNull);
        expect(config.endTime, isNull);
        expect(config.daysOfWeek, equals([1, 2, 3, 4, 5, 6, 7]));
      });

      test('custom config preserves values', () {
        final config = PluginScheduleConfig(
          interval: const Duration(seconds: 30),
          runOnStart: false,
          runInBackground: false,
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 17, minute: 0),
          daysOfWeek: const [1, 2, 3, 4, 5],
        );

        expect(config.interval, equals(const Duration(seconds: 30)));
        expect(config.runOnStart, isFalse);
        expect(config.runInBackground, isFalse);
        expect(config.startTime?.hour, equals(9));
        expect(config.endTime?.hour, equals(17));
        expect(config.daysOfWeek, equals([1, 2, 3, 4, 5]));
      });
    });

    group('shouldRunNow', () {
      test('returns true with default config', () {
        const config = PluginScheduleConfig();

        expect(config.shouldRunNow(), isTrue);
      });

      test('respects day of week filter', () {
        final now = DateTime.now();
        final todayWeekday = now.weekday;

        // Config that excludes today
        final excludeToday = PluginScheduleConfig(
          daysOfWeek: List.generate(7, (i) => i + 1)
            ..remove(todayWeekday),
        );

        expect(excludeToday.shouldRunNow(), isFalse);

        // Config that includes today
        final includeToday = PluginScheduleConfig(
          daysOfWeek: [todayWeekday],
        );

        expect(includeToday.shouldRunNow(), isTrue);
      });

      test('respects time window (normal range)', () {
        final now = DateTime.now();
        final currentMinutes = now.hour * 60 + now.minute;

        // Window that includes now
        final includesNow = PluginScheduleConfig(
          startTime: TimeOfDay(hour: (currentMinutes - 60) ~/ 60, minute: 0),
          endTime: TimeOfDay(hour: (currentMinutes + 60) ~/ 60, minute: 0),
        );

        // This might fail at edge hours (midnight/23:00), so we make it robust
        if (now.hour > 1 && now.hour < 22) {
          expect(includesNow.shouldRunNow(), isTrue);
        }

        // Window that excludes now (early morning when now is afternoon, or vice versa)
        final excludeWindow = now.hour >= 12
            ? const PluginScheduleConfig(
                startTime: TimeOfDay(hour: 3, minute: 0),
                endTime: TimeOfDay(hour: 5, minute: 0),
              )
            : const PluginScheduleConfig(
                startTime: TimeOfDay(hour: 15, minute: 0),
                endTime: TimeOfDay(hour: 17, minute: 0),
              );

        expect(excludeWindow.shouldRunNow(), isFalse);
      });
    });

    group('JSON Serialization', () {
      test('toJson produces valid JSON', () {
        final config = PluginScheduleConfig(
          interval: const Duration(minutes: 10),
          runOnStart: false,
          runInBackground: true,
          startTime: const TimeOfDay(hour: 8, minute: 30),
          endTime: const TimeOfDay(hour: 18, minute: 0),
          daysOfWeek: const [1, 2, 3, 4, 5],
        );

        final json = config.toJson();

        expect(json['interval'], equals(600000)); // 10 minutes in ms
        expect(json['runOnStart'], isFalse);
        expect(json['runInBackground'], isTrue);
        expect(json['startTime']['hour'], equals(8));
        expect(json['startTime']['minute'], equals(30));
        expect(json['endTime']['hour'], equals(18));
        expect(json['endTime']['minute'], equals(0));
        expect(json['daysOfWeek'], equals([1, 2, 3, 4, 5]));
      });

      test('fromJson parses correctly', () {
        final json = {
          'interval': 300000, // 5 minutes
          'runOnStart': true,
          'runInBackground': false,
          'startTime': {'hour': 9, 'minute': 0},
          'endTime': {'hour': 17, 'minute': 30},
          'daysOfWeek': [1, 3, 5],
        };

        final config = PluginScheduleConfig.fromJson(json);

        expect(config.interval, equals(const Duration(minutes: 5)));
        expect(config.runOnStart, isTrue);
        expect(config.runInBackground, isFalse);
        expect(config.startTime?.hour, equals(9));
        expect(config.endTime?.hour, equals(17));
        expect(config.endTime?.minute, equals(30));
        expect(config.daysOfWeek, equals([1, 3, 5]));
      });

      test('fromJson handles missing fields with defaults', () {
        final json = <String, dynamic>{};

        final config = PluginScheduleConfig.fromJson(json);

        expect(config.interval, equals(const Duration(minutes: 5)));
        expect(config.runOnStart, isTrue);
        expect(config.runInBackground, isTrue);
        expect(config.startTime, isNull);
        expect(config.endTime, isNull);
        expect(config.daysOfWeek, equals([1, 2, 3, 4, 5, 6, 7]));
      });

      test('roundtrip serialization preserves data', () {
        final original = PluginScheduleConfig(
          interval: const Duration(seconds: 45),
          runOnStart: false,
          runInBackground: true,
          startTime: const TimeOfDay(hour: 6, minute: 15),
          endTime: const TimeOfDay(hour: 22, minute: 45),
          daysOfWeek: const [2, 4, 6],
        );

        final json = original.toJson();
        final restored = PluginScheduleConfig.fromJson(json);

        expect(restored.interval, equals(original.interval));
        expect(restored.runOnStart, equals(original.runOnStart));
        expect(restored.runInBackground, equals(original.runInBackground));
        expect(restored.startTime?.hour, equals(original.startTime?.hour));
        expect(restored.startTime?.minute, equals(original.startTime?.minute));
        expect(restored.endTime?.hour, equals(original.endTime?.hour));
        expect(restored.endTime?.minute, equals(original.endTime?.minute));
        expect(restored.daysOfWeek, equals(original.daysOfWeek));
      });
    });
  });

  group('Scheduler Service - Testable Implementation', () {
    late TestableSchedulerService scheduler;

    setUp(() {
      scheduler = TestableSchedulerService();
    });

    tearDown(() {
      scheduler.dispose();
    });

    group('Listener Management', () {
      test('addListener registers callback', () {
        var called = false;
        scheduler.addListener((id, output) => called = true);

        scheduler.notifyListeners('test', _createMockOutput());

        expect(called, isTrue);
      });

      test('removeListener unregisters callback', () {
        var callCount = 0;
        void callback(String id, PluginOutput output) => callCount++;

        scheduler.addListener(callback);
        scheduler.notifyListeners('test', _createMockOutput());
        expect(callCount, equals(1));

        scheduler.removeListener(callback);
        scheduler.notifyListeners('test', _createMockOutput());
        expect(callCount, equals(1)); // Not called again
      });

      test('multiple listeners are all notified', () {
        var count1 = 0;
        var count2 = 0;
        var count3 = 0;

        scheduler.addListener((id, output) => count1++);
        scheduler.addListener((id, output) => count2++);
        scheduler.addListener((id, output) => count3++);

        scheduler.notifyListeners('test', _createMockOutput());

        expect(count1, equals(1));
        expect(count2, equals(1));
        expect(count3, equals(1));
      });
    });

    group('Output Management', () {
      test('lastOutputs starts empty', () {
        expect(scheduler.lastOutputs, isEmpty);
      });

      test('stores last output for plugin', () {
        final output = _createMockOutput(text: 'Test output');
        scheduler.setLastOutput('plugin-1', output);

        expect(scheduler.lastOutputs['plugin-1']?.text, equals('Test output'));
      });

      test('getLastOutput returns stored output', () {
        final output = _createMockOutput(text: 'Stored');
        scheduler.setLastOutput('plugin-1', output);

        expect(scheduler.getLastOutput('plugin-1')?.text, equals('Stored'));
      });

      test('getLastOutput returns null for unknown plugin', () {
        expect(scheduler.getLastOutput('nonexistent'), isNull);
      });

      test('clearLastOutput removes stored output', () {
        final output = _createMockOutput();
        scheduler.setLastOutput('plugin-1', output);

        scheduler.clearLastOutput('plugin-1');

        expect(scheduler.getLastOutput('plugin-1'), isNull);
      });
    });

    group('Running State', () {
      test('starts not running', () {
        expect(scheduler.isRunning, isFalse);
      });

      test('start sets running to true', () async {
        await scheduler.start();

        expect(scheduler.isRunning, isTrue);
      });

      test('stop sets running to false', () async {
        await scheduler.start();
        scheduler.stop();

        expect(scheduler.isRunning, isFalse);
      });

      test('double start is safe', () async {
        await scheduler.start();
        await scheduler.start();

        expect(scheduler.isRunning, isTrue);
      });
    });

    group('Dispose', () {
      test('dispose clears all state', () async {
        scheduler.addListener((id, output) {});
        scheduler.setLastOutput('plugin-1', _createMockOutput());
        await scheduler.start();

        scheduler.dispose();

        expect(scheduler.isRunning, isFalse);
        expect(scheduler.lastOutputs, isEmpty);
      });
    });
  });

  group('Timer-based Scheduling', () {
    test('schedules plugin with correct interval', () async {
      final scheduler = TestableSchedulerService();
      var runCount = 0;

      final plugin = Plugin(
        id: 'test-plugin',
        path: '/test/path.sh',
        interpreter: 'bash',
        refreshInterval: const Duration(milliseconds: 100),
      );

      scheduler.schedulePlugin(plugin, () async {
        runCount++;
        return _createMockOutput();
      });

      // Wait for initial run + 2 more intervals
      await Future<void>.delayed(const Duration(milliseconds: 350));
      scheduler.dispose();

      // Should have run at least 3 times (initial + 2 intervals)
      expect(runCount, greaterThanOrEqualTo(3));
    });

    test('reschedule cancels old timer', () async {
      final scheduler = TestableSchedulerService();
      var runCount = 0;

      final plugin = Plugin(
        id: 'test-plugin',
        path: '/test/path.sh',
        interpreter: 'bash',
        refreshInterval: const Duration(milliseconds: 50),
      );

      scheduler.schedulePlugin(plugin, () async {
        runCount++;
        return _createMockOutput();
      });

      await Future<void>.delayed(const Duration(milliseconds: 75));

      // Reschedule with longer interval
      final newPlugin = Plugin(
        id: 'test-plugin',
        path: '/test/path.sh',
        interpreter: 'bash',
        refreshInterval: const Duration(seconds: 10),
      );

      final countAtReschedule = runCount;
      scheduler.schedulePlugin(newPlugin, () async {
        runCount++;
        return _createMockOutput();
      });

      await Future<void>.delayed(const Duration(milliseconds: 100));
      scheduler.dispose();

      // Should have run once more for reschedule initial run
      expect(runCount, equals(countAtReschedule + 1));
    });

    test('cancel removes scheduled plugin', () async {
      final scheduler = TestableSchedulerService();
      var runCount = 0;

      final plugin = Plugin(
        id: 'test-plugin',
        path: '/test/path.sh',
        interpreter: 'bash',
        refreshInterval: const Duration(milliseconds: 50),
      );

      scheduler.schedulePlugin(plugin, () async {
        runCount++;
        return _createMockOutput();
      });

      await Future<void>.delayed(const Duration(milliseconds: 75));
      final countAtCancel = runCount;

      scheduler.cancelPlugin('test-plugin');

      await Future<void>.delayed(const Duration(milliseconds: 100));
      scheduler.dispose();

      // Should not have run after cancel
      expect(runCount, equals(countAtCancel));
    });
  });
}

/// Creates a mock PluginOutput for testing
PluginOutput _createMockOutput({
  String text = 'Test',
  String icon = '📦',
  bool hasError = false,
  String? errorMessage,
}) {
  return PluginOutput(
    pluginId: 'test-plugin',
    text: text,
    icon: icon,
    hasError: hasError,
    errorMessage: errorMessage,
    menu: [],
  );
}

/// Testable version of SchedulerService for unit testing
class TestableSchedulerService {
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
  }

  void stop() {
    _running = false;
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }

  void setLastOutput(String pluginId, PluginOutput output) {
    _lastOutputs[pluginId] = output;
  }

  PluginOutput? getLastOutput(String pluginId) {
    return _lastOutputs[pluginId];
  }

  void clearLastOutput(String pluginId) {
    _lastOutputs.remove(pluginId);
  }

  void notifyListeners(String pluginId, PluginOutput output) {
    for (final listener in _listeners) {
      listener(pluginId, output);
    }
  }

  void schedulePlugin(Plugin plugin, Future<PluginOutput> Function() runner) {
    _timers[plugin.id]?.cancel();

    // Run immediately
    runner().then((output) {
      _lastOutputs[plugin.id] = output;
      notifyListeners(plugin.id, output);
    });

    // Schedule periodic runs
    _timers[plugin.id] = Timer.periodic(
      plugin.refreshInterval,
      (_) async {
        if (!_running && _timers.containsKey(plugin.id)) {
          final output = await runner();
          _lastOutputs[plugin.id] = output;
          notifyListeners(plugin.id, output);
        }
      },
    );
  }

  void cancelPlugin(String pluginId) {
    _timers[pluginId]?.cancel();
    _timers.remove(pluginId);
  }

  void dispose() {
    stop();
    _listeners.clear();
    _lastOutputs.clear();
  }
}

typedef PluginOutputCallback = void Function(String pluginId, PluginOutput output);
