import 'package:crossbar/core/runners/declarative_runner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final runner = DeclarativeRunner();

  group('DeclarativeRunner - Basic Parsing', () {
    test('parses simple output plugin', () async {
      const yaml = '''
name: Simple Plugin
output:
  text: "Hello World"
''';
      final result = await runner.runSource(yaml);
      expect(result.success, isTrue);
      expect(result.output, equals('Hello World'));
    });

    test('parses plugin with static data', () async {
      const yaml = r'''
name: Static Data
source:
  type: static
  data:
    value: 42
output:
  text: "The answer is ${response.value}"
''';
      final result = await runner.runSource(yaml);
      expect(result.success, isTrue);
      expect(result.output, contains('42'));
    });

    test('handles missing required fields gracefully', () async {
      const yaml = '''
name: Minimal
''';
      final result = await runner.runSource(yaml);
      expect(result.success, isTrue);
      expect(result.output, isEmpty);
    });

    test('handles invalid YAML', () async {
      const yaml = 'not: valid: yaml: [[[';
      final result = await runner.runSource(yaml);
      expect(result.success, isFalse);
      expect(result.error, isNotNull);
    });
  });

  group('DeclarativeRunner - System Source', () {
    test('fetches time from system', () async {
      const yaml = r'''
name: Clock
source:
  type: system
  command: time
output:
  text: "⏰ ${response.value}"
''';
      final result = await runner.runSource(yaml);
      expect(result.success, isTrue);
      expect(result.output, matches(RegExp(r'⏰ \d{2}:\d{2}:\d{2}')));
    });

    test('fetches date from system', () async {
      const yaml = r'''
name: Calendar
source:
  type: system
  command: date
output:
  text: "📅 ${response.value}"
''';
      final result = await runner.runSource(yaml);
      expect(result.success, isTrue);
      expect(result.output, matches(RegExp(r'📅 \d{4}-\d{2}-\d{2}')));
    });

    test('fetches CPU usage from system', () async {
      const yaml = r'''
name: CPU Monitor
source:
  type: system
  command: cpu
output:
  text: "💻 ${response.percent}%"
''';
      final result = await runner.runSource(yaml);
      expect(result.success, isTrue);
      expect(result.output, matches(RegExp(r'💻 \d+\.?\d*%')));
    });
  });

  group('DeclarativeRunner - Template Rendering', () {
    test('renders nested object paths', () async {
      const yaml = r'''
name: Nested Data
source:
  type: static
  data:
    user:
      name: John
      age: 30
output:
  text: "${response.user.name} is ${response.user.age} years old"
''';
      final result = await runner.runSource(yaml);
      expect(result.success, isTrue);
      expect(result.output, equals('John is 30 years old'));
    });

    test('handles missing paths gracefully', () async {
      const yaml = r'''
name: Missing Path
source:
  type: static
  data:
    foo: bar
output:
  text: "Value: ${response.missing.path}"
''';
      final result = await runner.runSource(yaml);
      expect(result.success, isTrue);
      expect(result.output, equals('Value: '));
    });
  });

  group('DeclarativeRunner - Menu Support', () {
    test('parses menu items', () async {
      const yaml = r'''
name: With Menu
source:
  type: static
  data:
    value: 100
output:
  text: "Value: ${response.value}"
menu:
  - title: "Option 1"
  - title: "Option 2"
    action: open_settings
  - separator
  - title: "Refresh"
    action: refresh
''';
      final result = await runner.runSource(yaml);
      expect(result.success, isTrue);
      expect(result.hasMenu, isTrue);
      expect(result.menu.length, equals(4));
      expect(result.menu[0].title, equals('Option 1'));
      expect(result.menu[1].action, equals('open_settings'));
      expect(result.menu[2].isSeparator, isTrue);
    });
  });

  group('DeclarativeRunner - HTTP Source', () {
    test('fetches data from HTTP API', () async {
      const yaml = r'''
name: Bitcoin Price
source:
  type: http
  url: "https://api.coinbase.com/v2/prices/BTC-USD/spot"
output:
  text: "₿ $${response.data.amount}"
''';
      final result = await runner.runSource(yaml);
      expect(result.success, isTrue);
      expect(result.output, matches(RegExp(r'₿ \$\d+')));
    }, timeout: const Timeout(Duration(seconds: 30)));
  });

  group('DeclarativeRunner - canRun', () {
    test('accepts .yaml files', () {
      expect(runner.canRun('plugin.30m.yaml'), isTrue);
      expect(runner.canRun('/path/to/plugin.1h.yaml'), isTrue);
    });

    test('accepts .yml files', () {
      expect(runner.canRun('plugin.30m.yml'), isTrue);
    });

    test('rejects non-yaml files', () {
      expect(runner.canRun('plugin.1s.dart'), isFalse);
      expect(runner.canRun('plugin.1s.sh'), isFalse);
    });
  });
}
