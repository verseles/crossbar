import 'package:crossbar/core/runners/dart_runner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final runner = DartRunner();

  group('DartRunner - Basic Execution', () {
    test('runs simple print statement', () async {
      const code = '''
void main() {
  print('Hello from DartRunner!');
}
''';
      final result = await runner.runSource(code);
      expect(result.success, isTrue);
      expect(result.output, contains('Hello from DartRunner!'));
    });

    test('runs simple expression', () async {
      const code = r'''
void main() {
  final x = 2 + 2;
  print('Result: $x');
}
''';
      final result = await runner.runSource(code);
      expect(result.success, isTrue);
      expect(result.output, contains('Result: 4'));
    });

    test('handles syntax errors gracefully', () async {
      const code = '''
void main() {
  print('Missing parenthesis'
}
''';
      final result = await runner.runSource(code);
      expect(result.success, isFalse);
      expect(result.hasErrors, isTrue);
    });
  });

  group('DartRunner - CrossbarBridge Integration', () {
    test('accesses CrossbarBridge().time()', () async {
      const code = r'''
import 'package:crossbar_bridge/crossbar_bridge.dart';

void main() {
  final bridge = CrossbarBridge();
  final time = bridge.time();
  print('Time: $time');
}
''';
      final result = await runner.runSource(code);
      expect(result.success, isTrue, reason: result.errors);
      expect(result.output, matches(RegExp(r'Time: \d{2}:\d{2}:\d{2}')));
    });

    test('accesses CrossbarBridge().date()', () async {
      const code = r'''
import 'package:crossbar_bridge/crossbar_bridge.dart';

void main() {
  final bridge = CrossbarBridge();
  final date = bridge.date();
  print('Date: $date');
}
''';
      final result = await runner.runSource(code);
      expect(result.success, isTrue, reason: result.errors);
      expect(result.output, matches(RegExp(r'Date: \d{4}-\d{2}-\d{2}')));
    });

    test('accesses CrossbarBridge().platform', () async {
      const code = r'''
import 'package:crossbar_bridge/crossbar_bridge.dart';

void main() {
  final bridge = CrossbarBridge();
  print('Platform: ${bridge.platform}');
}
''';
      final result = await runner.runSource(code);
      expect(result.success, isTrue, reason: result.errors);
      expect(result.output.toLowerCase(), anyOf(
        contains('linux'),
        contains('macos'),
        contains('windows'),
      ));
    });

    test('accesses CrossbarBridge().isDesktop', () async {
      const code = r'''
import 'package:crossbar_bridge/crossbar_bridge.dart';

void main() {
  final bridge = CrossbarBridge();
  print('Is Desktop: ${bridge.isDesktop}');
}
''';
      final result = await runner.runSource(code);
      expect(result.success, isTrue, reason: result.errors);
      expect(result.output, contains('Is Desktop: true'));
    });
  });

  group('DartRunner - canRun', () {
    test('accepts .dart files', () {
      expect(runner.canRun('plugin.1s.dart'), isTrue);
      expect(runner.canRun('/path/to/plugin.10s.dart'), isTrue);
    });

    test('rejects non-dart files', () {
      expect(runner.canRun('plugin.1s.sh'), isFalse);
      expect(runner.canRun('plugin.1s.py'), isFalse);
      expect(runner.canRun('plugin.1s.js'), isFalse);
    });

    test('rejects compiled dart executables', () {
      expect(runner.canRun('plugin.1s.dart.exe'), isFalse);
    });
  });
}
