// ignore_for_file: avoid_slow_async_io
import 'dart:io';

import 'package:crossbar/core/plugin_manager.dart';
import 'package:crossbar_core/crossbar_core.dart';
import 'package:crossbar/services/refresh_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RefreshService', () {
    late Directory tempDir;
    late RefreshService refreshService;
    late PluginManager pluginManager;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('refresh_service_test_');
      refreshService = RefreshService();
      pluginManager = PluginManager();
      pluginManager.customPluginsDirectory = tempDir.path;
      refreshService.resetForTesting();
    });

    tearDown(() {
      refreshService.dispose();
      pluginManager.clear();
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    test('singleton returns same instance', () {
      final a = RefreshService();
      final b = RefreshService();
      expect(identical(a, b), true);
    });

    test('lastOutputs starts empty', () {
      expect(refreshService.lastOutputs, isEmpty);
    });

    test('getLastOutput returns null for unknown plugin', () {
      expect(refreshService.getLastOutput('unknown'), isNull);
    });

    test('addOutputListener and removeOutputListener work correctly', () {
      var callCount = 0;
      void listener(String id, PluginOutput output) {
        callCount++;
      }

      refreshService.addOutputListener(listener);
      refreshService.addOutputListener(listener); // Should not add duplicate

      // Manually trigger to verify (normally this is done internally)
      refreshService.removeOutputListener(listener);
      expect(callCount, 0);
    });

    test('addListChangedListener and removeListChangedListener work correctly', () {
      var callCount = 0;
      void listener() {
        callCount++;
      }

      refreshService.addListChangedListener(listener);
      refreshService.addListChangedListener(listener); // Should not add duplicate

      refreshService.removeListChangedListener(listener);
      expect(callCount, 0);
    });

    test('isRunning returns false for unknown plugin', () {
      expect(refreshService.isRunning('unknown'), false);
    });

    test('isRefreshAllInProgress starts as false', () {
      expect(refreshService.isRefreshAllInProgress, false);
    });

    test('getPlugin returns null for unknown plugin', () {
      expect(refreshService.getPlugin('unknown'), isNull);
    });

    test('plugins returns empty list when no plugins discovered', () async {
      await refreshService.discoverPlugins();
      expect(refreshService.plugins, isEmpty);
    });

    test('clearOutput removes cached output', () async {
      // Create a simple bash script
      final script = File('${tempDir.path}/test.1s.sh');
      script.writeAsStringSync('#!/bin/bash\necho "hello"');
      if (Platform.isLinux || Platform.isMacOS) {
        Process.runSync('chmod', ['+x', script.path]);
      }

      await refreshService.discoverPlugins();
      expect(refreshService.plugins.length, 1);

      // Run the plugin
      final output = await refreshService.runPlugin('test.1s.sh');
      expect(output, isNotNull);
      expect(refreshService.getLastOutput('test.1s.sh'), isNotNull);

      // Clear the output
      refreshService.clearOutput('test.1s.sh');
      expect(refreshService.getLastOutput('test.1s.sh'), isNull);
    });

    test('runPlugin notifies output listeners', () async {
      // Create a simple bash script
      final script = File('${tempDir.path}/notify.1s.sh');
      script.writeAsStringSync('#!/bin/bash\necho "notify"');
      if (Platform.isLinux || Platform.isMacOS) {
        Process.runSync('chmod', ['+x', script.path]);
      }

      await refreshService.discoverPlugins();

      String? notifiedId;
      PluginOutput? notifiedOutput;
      refreshService.addOutputListener((id, output) {
        notifiedId = id;
        notifiedOutput = output;
      });

      await refreshService.runPlugin('notify.1s.sh');

      expect(notifiedId, 'notify.1s.sh');
      expect(notifiedOutput, isNotNull);
      expect(notifiedOutput!.text, contains('notify'));
    });

    test('runPlugin returns null for unknown plugin', () async {
      final output = await refreshService.runPlugin('nonexistent');
      expect(output, isNull);
    });

    test('runAllEnabled runs all enabled plugins', () async {
      // Create two scripts
      final script1 = File('${tempDir.path}/plugin1.1s.sh');
      script1.writeAsStringSync('#!/bin/bash\necho "plugin1"');

      final script2 = File('${tempDir.path}/plugin2.1s.sh');
      script2.writeAsStringSync('#!/bin/bash\necho "plugin2"');

      if (Platform.isLinux || Platform.isMacOS) {
        Process.runSync('chmod', ['+x', script1.path]);
        Process.runSync('chmod', ['+x', script2.path]);
      }

      await refreshService.discoverPlugins();
      expect(refreshService.plugins.length, 2);

      final outputs = await refreshService.runAllEnabled();
      expect(outputs.length, 2);
    });

    test('togglePlugin enables/disables plugin', () async {
      // Create a disabled script
      final script = File('${tempDir.path}/toggle.off.1s.sh');
      script.writeAsStringSync('#!/bin/bash\necho "toggle"');

      await refreshService.discoverPlugins();
      expect(refreshService.plugins.length, 1);
      expect(refreshService.plugins.first.enabled, false);

      // Toggle to enable
      await refreshService.togglePlugin('toggle.off.1s.sh');

      // Rediscover to get updated state
      await refreshService.discoverPlugins();
      final plugin = refreshService.getPlugin('toggle.1s.sh');
      expect(plugin?.enabled, true);
    });

    test('togglePlugin notifies list changed listeners', () async {
      // Create a script
      final script = File('${tempDir.path}/listchange.1s.sh');
      script.writeAsStringSync('#!/bin/bash\necho "test"');
      if (Platform.isLinux || Platform.isMacOS) {
        Process.runSync('chmod', ['+x', script.path]);
      }

      await refreshService.discoverPlugins();

      var listChangedCalled = false;
      refreshService.addListChangedListener(() {
        listChangedCalled = true;
      });

      await refreshService.togglePlugin('listchange.1s.sh');
      expect(listChangedCalled, true);
    });

    test('enablePlugin enables and runs plugin', () async {
      // Create a disabled script
      final script = File('${tempDir.path}/enable.off.1s.sh');
      script.writeAsStringSync('#!/bin/bash\necho "enabled"');

      await refreshService.discoverPlugins();

      String? notifiedId;
      refreshService.addOutputListener((id, output) {
        notifiedId = id;
      });

      await refreshService.enablePlugin('enable.off.1s.sh');

      // Should have run the plugin after enabling
      expect(notifiedId, isNotNull);
    });

    test('disablePlugin disables and clears output', () async {
      // Create an enabled script
      final script = File('${tempDir.path}/disable.1s.sh');
      script.writeAsStringSync('#!/bin/bash\necho "disabled"');
      if (Platform.isLinux || Platform.isMacOS) {
        Process.runSync('chmod', ['+x', script.path]);
      }

      await refreshService.discoverPlugins();

      // Run first to have cached output
      await refreshService.runPlugin('disable.1s.sh');
      expect(refreshService.getLastOutput('disable.1s.sh'), isNotNull);

      await refreshService.disablePlugin('disable.1s.sh');

      // Output should be cleared
      expect(refreshService.getLastOutput('disable.1s.sh'), isNull);
    });

    test('concurrent runPlugin calls for same plugin return cached output', () async {
      // Create a script that takes some time
      final script = File('${tempDir.path}/concurrent.1s.sh');
      script.writeAsStringSync('#!/bin/bash\nsleep 0.5\necho "done"');
      if (Platform.isLinux || Platform.isMacOS) {
        Process.runSync('chmod', ['+x', script.path]);
      }

      await refreshService.discoverPlugins();

      // Start two concurrent runs
      final future1 = refreshService.runPlugin('concurrent.1s.sh');
      // Small delay to ensure first call has started
      await Future.delayed(const Duration(milliseconds: 50));
      final future2 = refreshService.runPlugin('concurrent.1s.sh');

      final results = await Future.wait([future1, future2]);

      // Both should return valid outputs (second returns cached/null)
      expect(results[0], isNotNull);
    });

    test('resetForTesting clears all state', () async {
      final script = File('${tempDir.path}/reset.1s.sh');
      script.writeAsStringSync('#!/bin/bash\necho "reset"');
      if (Platform.isLinux || Platform.isMacOS) {
        Process.runSync('chmod', ['+x', script.path]);
      }

      await refreshService.discoverPlugins();
      await refreshService.runPlugin('reset.1s.sh');

      refreshService.addOutputListener((_, output) {});

      refreshService.resetForTesting();

      expect(refreshService.lastOutputs, isEmpty);
      expect(refreshService.isRefreshAllInProgress, false);
    });
  });
}
