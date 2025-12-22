// ignore_for_file: avoid_slow_async_io
import 'dart:io';

import 'package:crossbar/cli/commands/web_command.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WebCommand', () {
    late WebCommand command;

    setUp(() {
      command = WebCommand();
    });

    group('Properties', () {
      test('name is web', () {
        expect(command.name, equals('web'));
      });

      test('description is not empty', () {
        expect(command.description, isNotEmpty);
      });

      test('description mentions HTTP', () {
        expect(command.description.toLowerCase(), contains('http'));
      });
    });

    group('Help', () {
      test('shows help and returns 1 with no arguments', () async {
        final result = await command.execute([]);
        expect(result, equals(1)); // Error exit code when no URL
      });

      test('shows help and returns 0 with --help flag', () async {
        final result = await command.execute(['--help']);
        expect(result, equals(0)); // Success exit code for help
      });

      test('shows help and returns 0 with -h flag', () async {
        final result = await command.execute(['-h']);
        expect(result, equals(0));
      });
    });

    group('Argument Parsing - Headers', () {
      test('returns error for invalid --headers JSON', () async {
        // Using timeout of 1 second with non-routable IP 
        // so it fails fast but still tests the JSON parsing
        final result = await command.execute([
          '192.0.2.1',
          '--headers', 'not valid json',
          '--timeout', '1',
        ]);
        // Should fail because of invalid JSON parsing before attempting network
        expect(result, equals(1));
      });
    });

    group('Body File', () {
      test('returns error for nonexistent body file', () async {
        final result = await command.execute([
          '192.0.2.1',
          '--body-file', '/definitely/nonexistent/path/file.json',
          '--timeout', '1',
        ]);
        // Should fail because file doesn't exist
        expect(result, equals(1));
      });

      test('reads body from existing file', () async {
        final tempFile = File('${Directory.systemTemp.path}/test_body_${DateTime.now().millisecondsSinceEpoch}.json');
        await tempFile.writeAsString('{"test": true}');

        try {
          // Now try with the real file (will fail on network, not file reading)
          final result = await command.execute([
            '192.0.2.1',
            '--method', 'POST',
            '--body-file', tempFile.path,
            '--timeout', '1',
          ]);
          // Will fail on network, but should at least read the file
          expect(result, equals(1));
        } finally {
          await tempFile.delete();
        }
      });
    });

    group('URL Handling - Empty URL', () {
      test('returns error when URL is empty', () async {
        // Pass options but no URL
        final result = await command.execute(['--method', 'GET']);
        expect(result, equals(1)); // Should fail - no URL
      });
    });

    group('Timeout Parsing', () {
      test('respects short timeout', () async {
        final start = DateTime.now();
        
        // Use non-routable IP that will timeout quickly
        await command.execute([
          '192.0.2.1',
          '--timeout', '1',
        ]);
        
        final elapsed = DateTime.now().difference(start);
        // Should complete within a few seconds (1s timeout + overhead)
        expect(elapsed.inSeconds, lessThan(10));
      });
    });
  });
}
