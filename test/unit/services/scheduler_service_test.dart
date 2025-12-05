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
      final config = PluginScheduleConfig(
        daysOfWeek: [now.weekday],
      );
      expect(config.shouldRunNow(), true);

      final otherDay = now.weekday == 1 ? 2 : 1;
      final configBadDay = PluginScheduleConfig(
        daysOfWeek: [otherDay],
      );
      expect(configBadDay.shouldRunNow(), false);
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

      scheduler.stop();
      expect(scheduler.isRunning, false);
    });
  });
}
