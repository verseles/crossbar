import 'dart:async';

import 'package:crossbar/cli/commands/location_command.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocationCommand', () {
    late LocationCommand command;

    setUp(() {
      command = LocationCommand();
    });

    test('name is location', () {
      expect(command.name, 'location');
    });

    test('description is not empty', () {
      expect(command.description, isNotEmpty);
    });

    test('shows help with --help flag', () async {
      final output = await _capturePrint(() => command.execute(['--help']));
      expect(output, contains('Usage:'));
      expect(output, contains('crossbar location'));
      expect(output, contains('geocode'));
      expect(output, contains('reverse'));
      expect(output, contains('--json'));
      expect(output, contains('--xml'));
    });

    test('shows help with -h flag', () async {
      final output = await _capturePrint(() => command.execute(['-h']));
      expect(output, contains('Usage:'));
    });

    test('geocode without address returns error', () async {
      final exitCode = await command.execute(['geocode']);
      expect(exitCode, 1);
    });

    test('reverse without coordinates returns error', () async {
      final exitCode = await command.execute(['reverse']);
      expect(exitCode, 1);
    });

    test('reverse with only lat returns error', () async {
      final exitCode = await command.execute(['reverse', '-23.55']);
      expect(exitCode, 1);
    });

    test('reverse with invalid coordinates returns error', () async {
      final exitCode = await command.execute(['reverse', 'abc', 'def']);
      expect(exitCode, 1);
    });
  });
}

Future<String> _capturePrint(Future Function() action) async {
  final buffer = StringBuffer();
  await runZoned(
    () async {
      await action();
    },
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) {
        buffer.writeln(line);
      },
    ),
  );
  return buffer.toString().trim();
}
