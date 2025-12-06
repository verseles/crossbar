import 'dart:convert';
import 'dart:io';

import 'package:crossbar/core/plugin_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('crossbar_plugin_config_');
  });

  tearDown(() async {
    PluginManager().clear();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Plugin Configuration Loading', () {
    test('discovers plugin without config', () async {
      // Create a simple plugin
      final pluginFile = File('${tempDir.path}/simple.10s.sh');
      await pluginFile.writeAsString('#!/bin/bash\necho "Hello"');
      await Process.run('chmod', ['+x', pluginFile.path]);

      // Set custom directory and discover
      PluginManager().customPluginsDirectory = tempDir.path;
      await PluginManager().discoverPlugins();

      final plugins = PluginManager().plugins;
      expect(plugins.length, equals(1));
      expect(plugins.first.id, equals('simple.10s.sh'));
      expect(plugins.first.config, isNull);
      expect(plugins.first.hasConfig, isFalse);
    });

    test('loads config from .config.json file', () async {
      // Create a plugin with config
      final pluginFile = File('${tempDir.path}/configurable.10s.sh');
      await pluginFile.writeAsString('#!/bin/bash\necho "With Config"');
      await Process.run('chmod', ['+x', pluginFile.path]);

      // Create config file
      final configFile = File('${tempDir.path}/configurable.10s.sh.config.json');
      await configFile.writeAsString(jsonEncode({
        'name': 'Configurable Plugin',
        'description': 'A plugin with configuration',
        'icon': '⚙️',
        'config_required': 'required',
        'settings': [
          {
            'key': 'api_key',
            'label': 'API Key',
            'type': 'text',
            'required': true,
          },
          {
            'key': 'token',
            'label': 'Token',
            'type': 'password',
            'required': false,
          },
        ],
      }));

      // Set custom directory and discover
      PluginManager().customPluginsDirectory = tempDir.path;
      await PluginManager().discoverPlugins();

      final plugins = PluginManager().plugins;
      expect(plugins.length, equals(1));

      final plugin = plugins.first;
      expect(plugin.id, equals('configurable.10s.sh'));
      expect(plugin.config, isNotNull);
      expect(plugin.hasConfig, isTrue);
      expect(plugin.requiresConfig, isTrue);
      expect(plugin.config!.name, equals('Configurable Plugin'));
      expect(plugin.config!.settings.length, equals(2));
      expect(plugin.config!.settings[0].key, equals('api_key'));
      expect(plugin.config!.settings[0].type, equals('text'));
      expect(plugin.config!.settings[1].key, equals('token'));
      expect(plugin.config!.settings[1].type, equals('password'));
    });

    test('handles invalid config file gracefully', () async {
      // Create a plugin with invalid config
      final pluginFile = File('${tempDir.path}/broken.10s.sh');
      await pluginFile.writeAsString('#!/bin/bash\necho "Broken"');
      await Process.run('chmod', ['+x', pluginFile.path]);

      // Create invalid config file
      final configFile = File('${tempDir.path}/broken.10s.sh.config.json');
      await configFile.writeAsString('not valid json {');

      // Set custom directory and discover
      PluginManager().customPluginsDirectory = tempDir.path;
      await PluginManager().discoverPlugins();

      // Should still discover plugin, just without config
      final plugins = PluginManager().plugins;
      expect(plugins.length, equals(1));
      expect(plugins.first.config, isNull);
    });

    test('Plugin.hasConfig and requiresConfig work correctly', () async {
      // Create plugin with optional config
      final pluginFile1 = File('${tempDir.path}/optional.10s.sh');
      await pluginFile1.writeAsString('#!/bin/bash\necho "Optional"');
      await Process.run('chmod', ['+x', pluginFile1.path]);

      final configFile1 = File('${tempDir.path}/optional.10s.sh.config.json');
      await configFile1.writeAsString(jsonEncode({
        'name': 'Optional',
        'description': 'Optional config',
        'icon': '',
        'config_required': 'optional',
        'settings': [
          {'key': 'setting', 'label': 'Setting', 'type': 'text'},
        ],
      }));

      // Create plugin with required config
      final pluginFile2 = File('${tempDir.path}/required.10s.sh');
      await pluginFile2.writeAsString('#!/bin/bash\necho "Required"');
      await Process.run('chmod', ['+x', pluginFile2.path]);

      final configFile2 = File('${tempDir.path}/required.10s.sh.config.json');
      await configFile2.writeAsString(jsonEncode({
        'name': 'Required',
        'description': 'Required config',
        'icon': '',
        'config_required': 'required',
        'settings': [
          {'key': 'setting', 'label': 'Setting', 'type': 'text'},
        ],
      }));

      // Create plugin with no settings
      final pluginFile3 = File('${tempDir.path}/empty.10s.sh');
      await pluginFile3.writeAsString('#!/bin/bash\necho "Empty"');
      await Process.run('chmod', ['+x', pluginFile3.path]);

      final configFile3 = File('${tempDir.path}/empty.10s.sh.config.json');
      await configFile3.writeAsString(jsonEncode({
        'name': 'Empty',
        'description': 'No settings',
        'icon': '',
        'config_required': 'optional',
        'settings': [],
      }));

      PluginManager().customPluginsDirectory = tempDir.path;
      await PluginManager().discoverPlugins();

      final plugins = PluginManager().plugins;
      expect(plugins.length, equals(3));

      final optional = plugins.firstWhere((p) => p.id == 'optional.10s.sh');
      expect(optional.hasConfig, isTrue);
      expect(optional.requiresConfig, isFalse);

      final required = plugins.firstWhere((p) => p.id == 'required.10s.sh');
      expect(required.hasConfig, isTrue);
      expect(required.requiresConfig, isTrue);

      final empty = plugins.firstWhere((p) => p.id == 'empty.10s.sh');
      expect(empty.hasConfig, isFalse); // No settings = no config needed
      expect(empty.requiresConfig, isFalse);
    });
  });
}
