import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crossbar/models/plugin_output.dart';

void main() {
  group('PluginOutput', () {
    test('creates plugin output with required parameters', () {
      const output = PluginOutput(
        pluginId: 'test.sh',
        icon: '',
      );

      expect(output.pluginId, 'test.sh');
      expect(output.icon, '');
      expect(output.text, isNull);
      expect(output.menu, isEmpty);
      expect(output.hasError, false);
    });

    test('creates plugin output with all parameters', () {
      const output = PluginOutput(
        pluginId: 'test.sh',
        icon: '',
        text: '45%',
        color: Colors.orange,
        trayTooltip: 'CPU: 45%',
        menu: [MenuItem(text: 'Details')],
        hasError: false,
      );

      expect(output.pluginId, 'test.sh');
      expect(output.icon, '');
      expect(output.text, '45%');
      expect(output.color, Colors.orange);
      expect(output.trayTooltip, 'CPU: 45%');
      expect(output.menu.length, 1);
      expect(output.hasError, false);
    });

    test('creates error output', () {
      final output = PluginOutput.error('test.sh', 'Something went wrong');

      expect(output.pluginId, 'test.sh');
      expect(output.icon, '');
      expect(output.text, 'Error');
      expect(output.hasError, true);
      expect(output.errorMessage, 'Something went wrong');
    });

    test('creates empty output', () {
      final output = PluginOutput.empty('test.sh');

      expect(output.pluginId, 'test.sh');
      expect(output.icon, '');
      expect(output.text, '');
      expect(output.hasError, false);
    });

    test('copyWith creates new instance', () {
      const output = PluginOutput(
        pluginId: 'test.sh',
        icon: '',
        text: '45%',
      );

      final updated = output.copyWith(text: '50%');

      expect(updated.pluginId, 'test.sh');
      expect(updated.icon, '');
      expect(updated.text, '50%');
      expect(output.text, '45%');
    });

    test('toJson serializes correctly', () {
      const output = PluginOutput(
        pluginId: 'test.sh',
        icon: '',
        text: '45%',
        hasError: false,
      );

      final json = output.toJson();

      expect(json['pluginId'], 'test.sh');
      expect(json['icon'], '');
      expect(json['text'], '45%');
      expect(json['hasError'], false);
    });

    test('toString returns readable representation', () {
      const output = PluginOutput(
        pluginId: 'test.sh',
        icon: '',
        text: '45%',
      );

      expect(output.toString(), contains('test.sh'));
      expect(output.toString(), contains('45%'));
    });
  });

  group('MenuItem', () {
    test('creates menu item with text', () {
      const item = MenuItem(text: 'Details');

      expect(item.text, 'Details');
      expect(item.separator, false);
      expect(item.bash, isNull);
      expect(item.href, isNull);
    });

    test('creates separator', () {
      final item = MenuItem.separator();

      expect(item.separator, true);
      expect(item.text, isNull);
    });

    test('creates menu item with bash command', () {
      const item = MenuItem(
        text: 'Run Script',
        bash: '/usr/bin/script.sh',
      );

      expect(item.text, 'Run Script');
      expect(item.bash, '/usr/bin/script.sh');
    });

    test('creates menu item with href', () {
      const item = MenuItem(
        text: 'Open Website',
        href: 'https://example.com',
      );

      expect(item.text, 'Open Website');
      expect(item.href, 'https://example.com');
    });

    test('creates menu item with submenu', () {
      const item = MenuItem(
        text: 'More',
        submenu: [
          MenuItem(text: 'Option 1'),
          MenuItem(text: 'Option 2'),
        ],
      );

      expect(item.text, 'More');
      expect(item.submenu, isNotNull);
      expect(item.submenu!.length, 2);
    });

    test('toJson serializes correctly', () {
      const item = MenuItem(
        text: 'Details',
        bash: '/usr/bin/top',
        color: 'red',
      );

      final json = item.toJson();

      expect(json['text'], 'Details');
      expect(json['bash'], '/usr/bin/top');
      expect(json['color'], 'red');
      expect(json['separator'], false);
    });

    test('toJson includes submenu', () {
      const item = MenuItem(
        text: 'Parent',
        submenu: [
          MenuItem(text: 'Child'),
        ],
      );

      final json = item.toJson();

      expect(json['submenu'], isA<List>());
      expect((json['submenu'] as List).length, 1);
    });

    test('fromJson deserializes correctly', () {
      final json = {
        'text': 'Details',
        'bash': '/usr/bin/top',
        'separator': false,
      };

      final item = MenuItem.fromJson(json);

      expect(item.text, 'Details');
      expect(item.bash, '/usr/bin/top');
      expect(item.separator, false);
    });

    test('fromJson deserializes submenu', () {
      final json = {
        'text': 'Parent',
        'submenu': [
          {'text': 'Child 1'},
          {'text': 'Child 2'},
        ],
      };

      final item = MenuItem.fromJson(json);

      expect(item.text, 'Parent');
      expect(item.submenu, isNotNull);
      expect(item.submenu!.length, 2);
      expect(item.submenu![0].text, 'Child 1');
    });

    test('copyWith creates new instance', () {
      const item = MenuItem(
        text: 'Original',
        bash: '/bin/bash',
      );

      final updated = item.copyWith(text: 'Updated');

      expect(updated.text, 'Updated');
      expect(updated.bash, '/bin/bash');
      expect(item.text, 'Original');
    });

    test('toString returns readable representation', () {
      const item = MenuItem(text: 'Details');
      final separator = MenuItem.separator();

      expect(item.toString(), contains('Details'));
      expect(separator.toString(), contains('separator'));
    });
  });
}
