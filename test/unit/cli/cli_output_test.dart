import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crossbar/cli/commands/filesystem_commands.dart';
import 'package:crossbar/cli/commands/utility_commands.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CLI Output Formatting', () {

    Future<String> capturePrint(Future Function() action) async {
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

    test('TimeCommand returns JSON', () async {
      final cmd = TimeCommand();
      final output = await capturePrint(() => cmd.execute(['--json']));
      final json = jsonDecode(output);
      expect(json, contains('time'));
      expect(json, contains('fmt'));
    });

    test('TimeCommand returns XML', () async {
      final cmd = TimeCommand();
      final output = await capturePrint(() => cmd.execute(['--xml']));
      expect(output, contains('<crossbar>'));
      expect(output, contains('<time>'));
      expect(output, contains('</crossbar>'));
    });

    test('UuidCommand returns JSON', () async {
      final cmd = UuidCommand();
      final output = await capturePrint(() => cmd.execute(['--json']));
      final json = jsonDecode(output);
      expect(json, contains('uuid'));
    });

    test('FileCommand exists returns JSON', () async {
        final tempDir = Directory.systemTemp.createTempSync('crossbar_test');
        final file = File('${tempDir.path}/test.txt')..createSync();
        try {
            final cmd = FileCommand();
            final output = await capturePrint(() => cmd.execute(['exists', file.path, '--json']));
            final json = jsonDecode(output);
            expect(json['exists'], isTrue);
            expect(json['path'], equals(file.path));
        } finally {
            tempDir.deleteSync(recursive: true);
        }
    });

    test('FileCommand exists returns XML', () async {
        final tempDir = Directory.systemTemp.createTempSync('crossbar_test');
        final file = File('${tempDir.path}/test.txt')..createSync();
        try {
            final cmd = FileCommand();
            final output = await capturePrint(() => cmd.execute(['exists', file.path, '--xml']));
            expect(output, contains('<exists>true</exists>'));
        } finally {
            tempDir.deleteSync(recursive: true);
        }
    });
  });
}
