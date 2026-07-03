// ignore_for_file: avoid_slow_async_io
import 'dart:io';
import 'package:crossbar/core/plugin_manager.dart';
import 'package:crossbar/services/scheduler_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PluginScheduleConfig', () {
    test('defaults', () {
      const config = PluginScheduleConfig();
      expect(config.interval, const Duration(minutes: 5));
      expect(config.runOnStart, true);
      expect(config.runInBackground, true);
      expect(config.startTime, null);
      expect(config.endTime, null);
      expect(config.daysOfWeek, [1, 2, 3, 4, 5, 6, 7]);
    });

    test('toJson and fromJson', () {
      const config = PluginScheduleConfig(
        interval: Duration(seconds: 10),
        runOnStart: false,
        startTime: TimeOfDay(hour: 9, minute: 0),
        endTime: TimeOfDay(hour: 17, minute: 0),
        daysOfWeek: [1, 2, 3, 4, 5],
      );

      final json = config.toJson();
      final fromJson = PluginScheduleConfig.fromJson(json);

      expect(fromJson.interval, config.interval);
      expect(fromJson.runOnStart, config.runOnStart);
      expect(fromJson.startTime?.hour, 9);
      expect(fromJson.endTime?.hour, 17);
      expect(fromJson.daysOfWeek, [1, 2, 3, 4, 5]);
    });

    test('shouldRunNow validates day of week', () {
      final now = DateTime.now();
      final config = PluginScheduleConfig(daysOfWeek: [now.weekday]);
      expect(config.shouldRunNow(), true);

      final otherDay = now.weekday == 1 ? 2 : 1;
      final configBadDay = PluginScheduleConfig(daysOfWeek: [otherDay]);
      expect(configBadDay.shouldRunNow(), false);
    });

    test('shouldRunNow validates time range (always true on valid day)', () {
      final now = DateTime.now();

      final config = PluginScheduleConfig(
        startTime: const TimeOfDay(hour: 0, minute: 0),
        endTime: const TimeOfDay(hour: 23, minute: 59),
        daysOfWeek: [now.weekday],
      );

      expect(config.shouldRunNow(), true);
    });

    test('shouldRunNow validates time range (always false on empty days)', () {
      final config = PluginScheduleConfig(
        startTime: const TimeOfDay(hour: 0, minute: 0),
        endTime: const TimeOfDay(hour: 23, minute: 59),
        daysOfWeek: [],
      );

      expect(config.shouldRunNow(), false);
    });
  });

  group('SchedulerService', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync();
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    test('lifecycle', () {
      final scheduler = SchedulerService();
      expect(scheduler.isRunning, false);

      scheduler.resetForTesting();
      expect(scheduler.isRunning, false);
    });

    test('start runs enabled plugins', () async {
      final p1 = File('${tempDir.path}/test_sched.sh');
      p1.writeAsStringSync('#!/bin/bash\necho "test"');
      if (Platform.isLinux || Platform.isMacOS) {
        Process.runSync('chmod', ['+x', p1.path]);
      }

      final pm = PluginManager();
      pm.customPluginsDirectory = tempDir.path;
      // Ensure we clear previous state
      pm.clear();
      await pm.discoverPlugins();

      final scheduler = SchedulerService();
      scheduler.resetForTesting();

      var called = false;
      scheduler.addListener((id, out) {
        if (id == 'test_sched.sh') called = true;
      });

      await scheduler.start();
      // Wait for script execution
      await Future.delayed(const Duration(seconds: 1));

      expect(called, true);
      expect(scheduler.isRunning, true);

      await scheduler.stop();
      expect(scheduler.isRunning, false);
    });

    test('canonicalId normalizes off suffixes', () {
      final scheduler = SchedulerService();

      expect(scheduler.canonicalIdForTesting('cpu.off.sh'), 'cpu.sh');
      expect(scheduler.canonicalIdForTesting('plugin.off'), 'plugin');
      expect(scheduler.canonicalIdForTesting('disk.10s.lua'), 'disk.10s.lua');
    });

    test('runPluginNow executes a plugin manually', () async {
      final p1 = File('${tempDir.path}/test_manual.sh');
      p1.writeAsStringSync('#!/bin/bash\necho "manual_run"');
      if (Platform.isLinux || Platform.isMacOS) {
        Process.runSync('chmod', ['+x', p1.path]);
      }

      final pm = PluginManager();
      pm.customPluginsDirectory = tempDir.path;
      pm.clear();
      await pm.discoverPlugins();

      final scheduler = SchedulerService();
      scheduler.resetForTesting();

      bool called = false;
      String outputText = '';
      scheduler.addListener((id, out) {
        if (id == 'test_manual.sh') {
          called = true;
          outputText = out.text ?? '';
        }
      });

      await scheduler.runPluginNow('test_manual.sh');

      expect(called, true);
      expect(outputText, 'manual_run');
    });

    test('refreshAll runs all enabled plugins', () async {
      final p1 = File('${tempDir.path}/plugin1.1s.sh');
      p1.writeAsStringSync('#!/bin/bash\necho "one"');
      final p2 = File('${tempDir.path}/plugin2.1s.sh');
      p2.writeAsStringSync('#!/bin/bash\necho "two"');

      if (Platform.isLinux || Platform.isMacOS) {
        Process.runSync('chmod', ['+x', p1.path]);
        Process.runSync('chmod', ['+x', p2.path]);
      }

      final pm = PluginManager();
      pm.customPluginsDirectory = tempDir.path;
      pm.clear();
      await pm.discoverPlugins();

      final scheduler = SchedulerService();
      scheduler.resetForTesting();

      int calledCount = 0;
      scheduler.addListener((id, out) {
        if (id == 'plugin1.1s.sh' || id == 'plugin2.1s.sh') {
          calledCount++;
        }
      });

      await scheduler.refreshAll();

      // Wait for execution completion
      await Future.delayed(const Duration(milliseconds: 500));

      expect(calledCount, greaterThanOrEqualTo(2));
    });

    test('getLastOutput and clearLastOutput manipulates output state', () async {
      final p1 = File('${tempDir.path}/test_state.sh');
      p1.writeAsStringSync('#!/bin/bash\necho "stateful"');
      if (Platform.isLinux || Platform.isMacOS) {
        Process.runSync('chmod', ['+x', p1.path]);
      }

      final pm = PluginManager();
      pm.customPluginsDirectory = tempDir.path;
      pm.clear();
      await pm.discoverPlugins();

      final scheduler = SchedulerService();
      scheduler.resetForTesting();

      await scheduler.runPluginNow('test_state.sh');

      final output = scheduler.getLastOutput('test_state.sh');
      expect(output, isNotNull);
      expect(output?.text, 'stateful');

      scheduler.clearLastOutput('test_state.sh');
      expect(scheduler.getLastOutput('test_state.sh'), isNull);
    });

    test('reschedulePlugin updates plugin scheduling', () async {
      final p1 = File('${tempDir.path}/resched.10s.sh');
      p1.writeAsStringSync('#!/bin/bash\necho "rescheduled"');
      if (Platform.isLinux || Platform.isMacOS) {
        Process.runSync('chmod', ['+x', p1.path]);
      }

      final pm = PluginManager();
      pm.customPluginsDirectory = tempDir.path;
      pm.clear();
      await pm.discoverPlugins();

      final scheduler = SchedulerService();
      scheduler.resetForTesting();

      await scheduler.start();
      expect(scheduler.isRunning, true);

      // Rename or modify to affect scheduling
      expect(() => scheduler.reschedulePlugin('resched.10s.sh'), returnsNormally);

      await scheduler.stop();
    });
  });
}
