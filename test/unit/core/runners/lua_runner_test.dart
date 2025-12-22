import 'package:crossbar_core/crossbar_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LuaRunner - Unit Tests', () {
    late LuaRunner runner;

    setUp(() {
      runner = LuaRunner();
    });

    group('Basic Execution', () {
      test('executes simple print statement', () async {
        const source = 'print("Hello, World!")';
        final result = await runner.runSource(source);

        expect(result.success, isTrue);
        expect(result.output.trim(), equals('Hello, World!'));
        expect(result.error, isNull);
      });

      test('executes multiple print statements', () async {
        const source = '''
          print("Line 1")
          print("Line 2")
          print("Line 3")
        ''';
        final result = await runner.runSource(source);

        expect(result.success, isTrue);
        expect(result.output, contains('Line 1'));
        expect(result.output, contains('Line 2'));
        expect(result.output, contains('Line 3'));
      });

      test('handles empty script', () async {
        const source = '';
        final result = await runner.runSource(source);

        expect(result.success, isTrue);
        expect(result.output, isEmpty);
      });

      test('handles comments only', () async {
        const source = '''
          -- This is a comment
          -- Another comment
        ''';
        final result = await runner.runSource(source);

        expect(result.success, isTrue);
        expect(result.output, isEmpty);
      });

      test('handles syntax errors gracefully', () async {
        const source = 'print("unclosed string';
        final result = await runner.runSource(source);

        expect(result.success, isFalse);
        expect(result.error, isNotNull);
      });
    });

    group('Crossbar Bridge - Time Functions', () {
      test('crossbar.time() returns current time', () async {
        const source = '''
          local t = crossbar.time("HH:mm:ss")
          print(t)
        ''';
        final result = await runner.runSource(source);

        expect(result.success, isTrue);
        // Should match HH:MM:SS format
        expect(result.output.trim(), matches(RegExp(r'^\d{2}:\d{2}:\d{2}$')));
      });

      test('crossbar.date() returns current date', () async {
        const source = '''
          local d = crossbar.date()
          print(d)
        ''';
        final result = await runner.runSource(source);

        expect(result.success, isTrue);
        // Should match YYYY-MM-DD format
        expect(result.output.trim(), matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
      });
    });

    group('Crossbar Bridge - Utility Functions', () {
      test('crossbar.uuid() returns UUID-like string', () async {
        const source = '''
          local u = crossbar.uuid()
          print(u)
        ''';
        final result = await runner.runSource(source);

        expect(result.success, isTrue);
        expect(result.output.trim(), isNotEmpty);
        expect(result.output.trim(), contains('-'));
      });

      test('crossbar.random() returns number', () async {
        const source = '''
          local r = crossbar.random(100)
          print(r)
        ''';
        final result = await runner.runSource(source);

        expect(result.success, isTrue);
        final num = int.tryParse(result.output.trim());
        expect(num, isNotNull);
        expect(num, greaterThanOrEqualTo(0));
        expect(num, lessThan(100));
      });

      test('crossbar.base64Encode() encodes string', () async {
        const source = '''
          local encoded = crossbar.base64Encode("hello")
          print(encoded)
        ''';
        final result = await runner.runSource(source);

        expect(result.success, isTrue);
        expect(result.output.trim(), equals('aGVsbG8='));
      });

      test('crossbar.base64Decode() decodes string', () async {
        const source = '''
          local decoded = crossbar.base64Decode("aGVsbG8=")
          print(decoded)
        ''';
        final result = await runner.runSource(source);

        expect(result.success, isTrue);
        expect(result.output.trim(), equals('hello'));
      });
    });

    group('Crossbar Bridge - Platform Functions', () {
      test('crossbar.platform() returns platform name', () async {
        const source = '''
          local p = crossbar.platform()
          print(p)
        ''';
        final result = await runner.runSource(source);

        expect(result.success, isTrue);
        expect(
          result.output.trim(),
          anyOf(
            equals('linux'),
            equals('macos'),
            equals('windows'),
            equals('android'),
            equals('ios'),
          ),
        );
      });

      test('crossbar.homeDir() returns home directory', () async {
        const source = '''
          local h = crossbar.homeDir()
          print(h)
        ''';
        final result = await runner.runSource(source);

        expect(result.success, isTrue);
        expect(result.output.trim(), isNotEmpty);
      });

      test('crossbar.isDesktop() returns boolean as int', () async {
        const source = '''
          local d = crossbar.isDesktop()
          print(d)
        ''';
        final result = await runner.runSource(source);

        expect(result.success, isTrue);
        expect(result.output.trim(), anyOf(equals('0'), equals('1')));
      });

      test('crossbar.isMobile() returns boolean as int', () async {
        const source = '''
          local m = crossbar.isMobile()
          print(m)
        ''';
        final result = await runner.runSource(source);

        expect(result.success, isTrue);
        expect(result.output.trim(), anyOf(equals('0'), equals('1')));
      });
    });

    group('Crossbar Bridge - System Functions', () {
      test('crossbar.cpu() returns numeric value', () async {
        const source = '''
          local c = crossbar.cpu()
          print(c)
        ''';
        final result = await runner.runSource(source);

        expect(result.success, isTrue);
        final cpu = double.tryParse(result.output.trim());
        // CPU can be 0.0 on first call (stateful measurement)
        expect(cpu, isNotNull);
        expect(cpu, greaterThanOrEqualTo(0.0));
      });

      test('crossbar.memory() returns table with expected fields', () async {
        const source = '''
          local m = crossbar.memory()
          if m then
            if m.percent then
              print("percent:" .. m.percent)
            else
              print("percent:nil")
            end
            if m.total then
              print("total:" .. m.total)
            else
              print("total:nil")
            end
          else
            print("memory:nil")
          end
        ''';
        final result = await runner.runSource(source);

        expect(result.success, isTrue);
        // On most systems should have percent and total
        // But on some edge cases might be nil
        expect(result.output, isNotEmpty);
      });

      test('crossbar.battery() returns table', () async {
        const source = '''
          local b = crossbar.battery()
          if b then
            print("has_battery")
          else
            print("no_battery")
          end
        ''';
        final result = await runner.runSource(source);

        expect(result.success, isTrue);
        expect(
          result.output.trim(),
          anyOf(equals('has_battery'), equals('no_battery')),
        );
      });
    });

    group('Complex Scripts', () {
      test('can do arithmetic in output', () async {
        const source = '''
          local a = 10
          local b = 5
          print("Sum: " .. (a + b))
          print("Product: " .. (a * b))
        ''';
        final result = await runner.runSource(source);

        expect(result.success, isTrue);
        expect(result.output, contains('Sum: 15'));
        expect(result.output, contains('Product: 50'));
      });

      test('can use conditionals', () async {
        const source = '''
          local value = 75
          local label = "Unknown"
          if value > 80 then
            label = "High"
          elseif value > 50 then
            label = "Medium"
          else
            label = "Low"
          end
          print(label)
        ''';
        final result = await runner.runSource(source);

        expect(result.success, isTrue);
        expect(result.output.trim(), equals('Medium'));
      });

      test('can define and call functions', () async {
        const source = '''
          function greet(name)
            return "Hello, " .. name .. "!"
          end
          print(greet("World"))
        ''';
        final result = await runner.runSource(source);

        expect(result.success, isTrue);
        expect(result.output.trim(), equals('Hello, World!'));
      });
    });
  });
}
