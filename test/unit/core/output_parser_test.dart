// ignore_for_file: avoid_slow_async_io
import 'package:crossbar_core/crossbar_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OutputParser', () {
    group('isJson', () {
      test('returns true for valid JSON object', () {
        expect(OutputParser.isJson('{"key":"value"}'), true);
        expect(OutputParser.isJson('{ "key": "value" }'), true);
        expect(OutputParser.isJson('  {"key":"value"}  '), true);
      });

      test('returns false for non-JSON text', () {
        expect(OutputParser.isJson('Hello World'), false);
        expect(OutputParser.isJson('45% | color=red'), false);
        expect(OutputParser.isJson(''), false);
      });

      test('returns false for JSON arrays', () {
        expect(OutputParser.isJson('[1, 2, 3]'), false);
      });
    });

    group('parse - BitBar text format', () {
      test('parses simple text output', () {
        final output = OutputParser.parse('Hello World', 'test.sh');

        expect(output.pluginId, 'test.sh');
        expect(output.text, 'Hello World');
        expect(output.hasError, false);
      });

      test('parses text with emoji icon', () {
        final output = OutputParser.parse(' 45%', 'cpu.sh');

        expect(output.icon, '');
        expect(output.text, '45%');
      });

      test('parses text with color attribute', () {
        final output = OutputParser.parse('45% | color=red', 'test.sh');

        expect(output.text, '45%');
      });

      test('parses color with multiple attributes', () {
        final output = OutputParser.parse(
          '45% | iconName=utilities-system-monitor-symbolic color=green',
          'test.sh',
        );

        expect(output.text, '45%');
        expect(output.color, 0xFF00FF00);
      });

      test('parses menu items after separator', () {
        const input = '''
45%
---
Details | bash=/usr/bin/top
Settings | href=https://example.com
''';

        final output = OutputParser.parse(input, 'test.sh');

        expect(output.text, '45%');
        expect(output.menu.length, 2);
        expect(output.menu[0].text, 'Details');
        expect(output.menu[0].bash, '/usr/bin/top');
        expect(output.menu[1].text, 'Settings');
        expect(output.menu[1].href, 'https://example.com');
      });

      test('parses menu item with color', () {
        const input = '''
Test
---
Error | color=red
''';

        final output = OutputParser.parse(input, 'test.sh');

        expect(output.menu.length, 1);
        expect(output.menu[0].text, 'Error');
        expect(output.menu[0].color, 'red');
      });

      test('parses menu item with quoted bash', () {
        const input = '''
Test
---
Open File | bash="xdg-open /home/helio/My File" color=blue
''';

        final output = OutputParser.parse(input, 'test.sh');

        expect(output.menu.length, 1);
        expect(output.menu[0].text, 'Open File');
        expect(output.menu[0].bash, 'xdg-open /home/helio/My File');
        expect(output.menu[0].color, 'blue');
      });

      test('handles empty output', () {
        final output = OutputParser.parse('', 'test.sh');

        expect(output.pluginId, 'test.sh');
        expect(output.text, '');
        expect(output.icon, '');
        expect(output.hasError, false);
      });

      test('handles whitespace-only output', () {
        final output = OutputParser.parse('   \n\n   ', 'test.sh');

        expect(output.text, '');
      });

      test('ignores content before separator', () {
        const input = '''
Title
Some description
---
Menu Item
''';

        final output = OutputParser.parse(input, 'test.sh');

        expect(output.text, 'Title');
        expect(output.menu.length, 1);
        expect(output.menu[0].text, 'Menu Item');
      });

      test('parses single level submenu (-- prefix)', () {
        const input = '''
System Info
---
CPU
--CPU Core 1: 45%
--CPU Core 2: 52%
Memory
--Used: 8GB
--Free: 24GB
''';

        final output = OutputParser.parse(input, 'test.sh');

        expect(output.text, 'System Info');
        expect(output.menu.length, 2); // CPU and Memory
        expect(output.menu[0].text, 'CPU');
        expect(output.menu[0].submenu, isNotNull);
        expect(output.menu[0].submenu!.length, 2);
        expect(output.menu[0].submenu![0].text, 'CPU Core 1: 45%');
        expect(output.menu[0].submenu![1].text, 'CPU Core 2: 52%');
        expect(output.menu[1].text, 'Memory');
        expect(output.menu[1].submenu!.length, 2);
        expect(output.menu[1].submenu![0].text, 'Used: 8GB');
        expect(output.menu[1].submenu![1].text, 'Free: 24GB');
      });

      test('parses two level submenu (---- prefix)', () {
        const input = '''
System
---
Hardware
--CPU
----Intel i9
----12 Cores
--GPU
----NVIDIA RTX 4090
''';

        final output = OutputParser.parse(input, 'test.sh');

        expect(output.menu.length, 1); // Hardware
        expect(output.menu[0].text, 'Hardware');
        expect(output.menu[0].submenu!.length, 2); // CPU and GPU

        final cpu = output.menu[0].submenu![0];
        expect(cpu.text, 'CPU');
        expect(cpu.submenu!.length, 2);
        expect(cpu.submenu![0].text, 'Intel i9');
        expect(cpu.submenu![1].text, '12 Cores');

        final gpu = output.menu[0].submenu![1];
        expect(gpu.text, 'GPU');
        expect(gpu.submenu!.length, 1);
        expect(gpu.submenu![0].text, 'NVIDIA RTX 4090');
      });

      test('parses submenu with attributes', () {
        const input = '''
Actions
---
Open Files
--Open Home | bash=xdg-open ~
--Open Documents | href=file://~/Documents | color=blue
''';

        final output = OutputParser.parse(input, 'test.sh');

        expect(output.menu[0].text, 'Open Files');
        final submenu = output.menu[0].submenu!;
        expect(submenu.length, 2);
        expect(submenu[0].text, 'Open Home');
        expect(submenu[0].bash, 'xdg-open ~');
        expect(submenu[1].text, 'Open Documents');
        expect(submenu[1].href, 'file://~/Documents');
        expect(submenu[1].color, 'blue');
      });

      test('handles mixed depth levels correctly', () {
        const input = '''
Mixed
---
Level 0 Item A
--Level 1 Item
----Level 2 Item
Level 0 Item B
--Another Level 1
''';

        final output = OutputParser.parse(input, 'test.sh');

        expect(output.menu.length, 2); // Level 0 Item A and B
        expect(output.menu[0].text, 'Level 0 Item A');
        expect(output.menu[0].submenu!.length, 1);
        expect(output.menu[0].submenu![0].text, 'Level 1 Item');
        expect(output.menu[0].submenu![0].submenu!.length, 1);
        expect(output.menu[0].submenu![0].submenu![0].text, 'Level 2 Item');

        expect(output.menu[1].text, 'Level 0 Item B');
        expect(output.menu[1].submenu!.length, 1);
        expect(output.menu[1].submenu![0].text, 'Another Level 1');
      });

      test('handles separator correctly within menu and submenus', () {
        const input = '''
Test
---
Item 1
---
Item 2
--Sub 1
---
--Sub 2
''';

        final output = OutputParser.parse(input, 'test.sh');

        // After first ---, separator creates a graphical separator
        // The structure should have separators in the right places
        expect(output.menu.length, greaterThanOrEqualTo(2));
      });

      test('parses 5 levels of nesting', () {
        const input = '''
Deep Nesting
---
L0
--L1
----L2
------L3
--------L4
----------L5
''';

        final output = OutputParser.parse(input, 'test.sh');

        var current = output.menu[0];
        expect(current.text, 'L0');

        current = current.submenu![0];
        expect(current.text, 'L1');

        current = current.submenu![0];
        expect(current.text, 'L2');

        current = current.submenu![0];
        expect(current.text, 'L3');

        current = current.submenu![0];
        expect(current.text, 'L4');

        current = current.submenu![0];
        expect(current.text, 'L5');
      });
    });

    group('parse - JSON format', () {
      test('parses simple JSON output', () {
        const json = '{"icon":"","text":"45%"}';
        final output = OutputParser.parse(json, 'test.sh');

        expect(output.pluginId, 'test.sh');
        expect(output.icon, '');
        expect(output.text, '45%');
        expect(output.hasError, false);
      });

      test('parses JSON with tray tooltip', () {
        const json = '{"icon":"","text":"45%","tray_tooltip":"CPU: 45%"}';
        final output = OutputParser.parse(json, 'test.sh');

        expect(output.trayTooltip, 'CPU: 45%');
      });

      test('parses JSON with menu', () {
        const json = '''
{
  "icon": "",
  "text": "45%",
  "menu": [
    {"text": "Details", "bash": "/usr/bin/top"},
    {"separator": true},
    {"text": "Settings", "href": "https://example.com"}
  ]
}
''';

        final output = OutputParser.parse(json, 'test.sh');

        expect(output.menu.length, 3);
        expect(output.menu[0].text, 'Details');
        expect(output.menu[0].bash, '/usr/bin/top');
        expect(output.menu[1].separator, true);
        expect(output.menu[2].text, 'Settings');
        expect(output.menu[2].href, 'https://example.com');
      });

      test('parses JSON with nested submenu', () {
        const json = '''
{
  "icon": "",
  "text": "Test",
  "menu": [
    {
      "text": "Parent",
      "submenu": [
        {"text": "Child 1"},
        {"text": "Child 2"}
      ]
    }
  ]
}
''';

        final output = OutputParser.parse(json, 'test.sh');

        expect(output.menu.length, 1);
        expect(output.menu[0].submenu, isNotNull);
        expect(output.menu[0].submenu!.length, 2);
        expect(output.menu[0].submenu![0].text, 'Child 1');
      });

      test('parses JSON with color', () {
        const json = '{"icon":"","text":"45%","color":"#FF5733"}';
        final output = OutputParser.parse(json, 'test.sh');

        expect(output.color, isNotNull);
      });

      test('handles missing optional fields', () {
        const json = '{}';
        final output = OutputParser.parse(json, 'test.sh');

        expect(output.icon, '');
        expect(output.text, isNull);
        expect(output.menu, isEmpty);
      });
    });

    group('parse - error handling', () {
      test('returns error for invalid JSON', () {
        final output = OutputParser.parse('{invalid json}', 'test.sh');

        expect(output.hasError, true);
        expect(output.errorMessage, contains('Failed to parse'));
      });
    });

    group('color parsing', () {
      test('parses named colors', () {
        const json = '{"icon":"","text":"Test","color":"red"}';
        final output = OutputParser.parse(json, 'test.sh');

        expect(output.color, isNotNull);
      });

      test('parses hex colors', () {
        const json = '{"icon":"","text":"Test","color":"#FF0000"}';
        final output = OutputParser.parse(json, 'test.sh');

        expect(output.color, isNotNull);
      });

      test('parses short hex colors', () {
        const json = '{"icon":"","text":"Test","color":"#F00"}';
        final output = OutputParser.parse(json, 'test.sh');

        expect(output.color, isNotNull);
      });

      test('returns null for invalid color', () {
        const json = '{"icon":"","text":"Test","color":"invalidcolor"}';
        final output = OutputParser.parse(json, 'test.sh');

        expect(output.color, isNull);
      });
    });
  });
}
