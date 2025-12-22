// ignore_for_file: avoid_slow_async_io
import 'package:crossbar/core/output_parser.dart';
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

      test('parses single-level submenu with -- prefix', () {
        const input = '''
Main
---
Parent Item
--Child 1
--Child 2
''';

        final output = OutputParser.parse(input, 'test.sh');

        expect(output.text, 'Main');
        expect(output.menu.length, 1);
        expect(output.menu[0].text, 'Parent Item');
        expect(output.menu[0].submenu, isNotNull);
        expect(output.menu[0].submenu!.length, 2);
        expect(output.menu[0].submenu![0].text, 'Child 1');
        expect(output.menu[0].submenu![1].text, 'Child 2');
      });

      test('parses multi-level nested submenus', () {
        const input = '''
Test
---
Level 0
--Level 1
----Level 2
------Level 3
''';

        final output = OutputParser.parse(input, 'test.sh');

        expect(output.menu.length, 1);
        expect(output.menu[0].text, 'Level 0');

        final level1 = output.menu[0].submenu;
        expect(level1, isNotNull);
        expect(level1!.length, 1);
        expect(level1[0].text, 'Level 1');

        final level2 = level1[0].submenu;
        expect(level2, isNotNull);
        expect(level2!.length, 1);
        expect(level2[0].text, 'Level 2');

        final level3 = level2[0].submenu;
        expect(level3, isNotNull);
        expect(level3!.length, 1);
        expect(level3[0].text, 'Level 3');
      });

      test('parses submenu items with attributes', () {
        const input = '''
Menu
---
Actions
--Open | bash=/usr/bin/open
--Visit | href=https://example.com
--Error | color=red
''';

        final output = OutputParser.parse(input, 'test.sh');

        expect(output.menu.length, 1);
        expect(output.menu[0].text, 'Actions');

        final submenu = output.menu[0].submenu;
        expect(submenu, isNotNull);
        expect(submenu!.length, 3);
        expect(submenu[0].text, 'Open');
        expect(submenu[0].bash, '/usr/bin/open');
        expect(submenu[1].text, 'Visit');
        expect(submenu[1].href, 'https://example.com');
        expect(submenu[2].text, 'Error');
        expect(submenu[2].color, 'red');
      });

      test('parses multiple parent items with submenus', () {
        const input = '''
Test
---
Parent A
--Child A1
--Child A2
Parent B
--Child B1
''';

        final output = OutputParser.parse(input, 'test.sh');

        expect(output.menu.length, 2);

        expect(output.menu[0].text, 'Parent A');
        expect(output.menu[0].submenu!.length, 2);
        expect(output.menu[0].submenu![0].text, 'Child A1');
        expect(output.menu[0].submenu![1].text, 'Child A2');

        expect(output.menu[1].text, 'Parent B');
        expect(output.menu[1].submenu!.length, 1);
        expect(output.menu[1].submenu![0].text, 'Child B1');
      });

      test('handles mixed flat and nested items', () {
        const input = '''
App
---
Flat Item 1
Parent
--Nested Item
Flat Item 2
''';

        final output = OutputParser.parse(input, 'test.sh');

        expect(output.menu.length, 3);
        expect(output.menu[0].text, 'Flat Item 1');
        expect(output.menu[0].submenu, isNull);

        expect(output.menu[1].text, 'Parent');
        expect(output.menu[1].submenu, isNotNull);
        expect(output.menu[1].submenu!.length, 1);

        expect(output.menu[2].text, 'Flat Item 2');
        expect(output.menu[2].submenu, isNull);
      });

      test('handles submenu with 5 nesting levels', () {
        const input = '''
Deep
---
L0
--L1
----L2
------L3
--------L4
----------L5
''';

        final output = OutputParser.parse(input, 'test.sh');

        expect(output.menu.length, 1);

        var current = output.menu[0];
        expect(current.text, 'L0');

        for (var i = 1; i <= 5; i++) {
          expect(current.submenu, isNotNull, reason: 'Level $i should exist');
          expect(current.submenu!.length, 1);
          current = current.submenu![0];
          expect(current.text, 'L$i');
        }
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
