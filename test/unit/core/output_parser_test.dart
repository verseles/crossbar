import 'package:flutter_test/flutter_test.dart';
import 'package:crossbar/core/output_parser.dart';

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
