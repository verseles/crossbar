import 'package:crossbar/core/runners/lua_runner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LuaRunner', () {
    late LuaRunner runner;

    setUp(() {
      runner = LuaRunner();
    });

    group('runSource', () {
      test('executes simple print', () async {
        final result = await runner.runSource('print("Hello Lua")');
        expect(result.success, true);
        expect(result.output.trim(), 'Hello Lua');
      });

      test('executes arithmetic', () async {
        final result = await runner.runSource('print(2 + 2)');
        expect(result.success, true);
        expect(result.output.trim(), '4');
      });

      test('can access crossbar.time()', () async {
        final result = await runner.runSource('local t = crossbar.time(); print(t)');
        expect(result.success, true);
        expect(result.output.trim(), isNotEmpty);
      });

      test('can access crossbar.date()', () async {
        final result = await runner.runSource('local d = crossbar.date(); print(d)');
        expect(result.success, true);
        expect(result.output.trim(), isNotEmpty);
      });

      test('can access crossbar.platform()', () async {
        final result = await runner.runSource('local p = crossbar.platform(); print(p)');
        expect(result.success, true);
        expect(result.output.trim(), anyOf('linux', 'macos', 'windows', 'android', 'ios'));
      });

      test('can access crossbar.uuid()', () async {
        final result = await runner.runSource('local u = crossbar.uuid(); print(u)');
        expect(result.success, true);
        expect(
          result.output.trim(),
          matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[0-9a-f]{4}-[0-9a-f]{12}$')),
        );
      });

      test('can access crossbar.hash()', () async {
        final result = await runner.runSource('local h = crossbar.hash("test"); print(h)');
        expect(result.success, true);
        expect(result.output.trim(), isNotEmpty);
      });

      test('can access crossbar.random()', () async {
        final result = await runner.runSource('local r = crossbar.random(100); print(r)');
        expect(result.success, true);
        final value = int.tryParse(result.output.trim());
        expect(value, isNotNull);
        expect(value! >= 0 && value <= 100, true);
      });

      test('can access crossbar.memory() table', () async {
        final result = await runner.runSource('''
          local m = crossbar.memory()
          if m then print(m.raw) else print("nil") end
        ''');
        expect(result.success, true);
        expect(result.output, isNotNull);
      });

      test('can access crossbar.battery() table', () async {
        final result = await runner.runSource('''
          local b = crossbar.battery()
          if b then print(b.status) else print("nil") end
        ''');
        expect(result.success, true);
        expect(result.output, isNotNull);
      });

      test('can access crossbar.cpu() number', () async {
        final result = await runner.runSource('print(crossbar.cpu())');
        expect(result.success, true);
        // Should return a number (0.0 or actual usage)
        expect(double.tryParse(result.output.trim()), isNotNull);
      });

      test('can use string concatenation', () async {
        final result = await runner.runSource('print("Hello " .. "World")');
        expect(result.success, true);
        expect(result.output.trim(), 'Hello World');
      });

      test('can use conditionals', () async {
        final result = await runner.runSource('''
          local x = 5
          if x > 3 then
            print("greater")
          else
            print("smaller")
          end
        ''');
        expect(result.success, true);
        expect(result.output.trim(), 'greater');
      });

      test('can use loops', () async {
        final result = await runner.runSource('''
          local sum = 0
          for i = 1, 5 do
            sum = sum + i
          end
          print(sum)
        ''');
        expect(result.success, true);
        expect(result.output.trim(), '15');
      });

      test('reports syntax errors', () async {
        final result = await runner.runSource('print(');
        expect(result.success, false);
        expect(result.error, contains('error'));
      });
    });

    group('run', () {
      test('returns error for non-existent file', () async {
        final result = await runner.run('/nonexistent/path.lua');
        expect(result.success, false);
        expect(result.error, contains('not found'));
      });
    });
  });
}
