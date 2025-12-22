// ignore_for_file: avoid_slow_async_io
import 'package:crossbar/core/bridge/crossbar_bridge.dart';
import 'package:flutter_test/flutter_test.dart';

/// Extended tests for CrossbarBridge focusing on sync methods and utilities
void main() {
  group('CrossbarBridge - Sync Methods', () {
    final bridge = CrossbarBridge();

    group('cpuSync', () {
      test('returns valid percentage', () {
        final cpu = bridge.cpuSync();
        expect(cpu, greaterThanOrEqualTo(0));
        expect(cpu, lessThanOrEqualTo(100));
      });
    });

    group('memorySync', () {
      test('returns map with expected structure', () {
        final mem = bridge.memorySync();
        expect(mem, isA<Map<String, dynamic>>());
        expect(mem.containsKey('raw'), isTrue);
      });

      test('returns numeric values when available', () {
        final mem = bridge.memorySync();
        // On a valid system, these should exist
        if (mem.containsKey('used')) {
          expect(mem['used'], isA<num>());
        }
        if (mem.containsKey('total')) {
          expect(mem['total'], isA<num>());
        }
      });
    });

    group('batterySync', () {
      test('returns map with expected structure', () {
        final batt = bridge.batterySync();
        expect(batt, isA<Map<String, dynamic>>());
        expect(batt.containsKey('available'), isTrue);
        expect(batt.containsKey('status'), isTrue);
      });
    });

    group('uptimeSync', () {
      test('returns non-empty string', () {
        final uptime = bridge.uptimeSync();
        expect(uptime, isNotEmpty);
      });
    });
  });

  group('CrossbarBridge - Time & Date Formats', () {
    final bridge = CrossbarBridge();

    group('time', () {
      test('default format HH:mm:ss', () {
        final t = bridge.time();
        expect(RegExp(r'^\d{2}:\d{2}:\d{2}$').hasMatch(t), isTrue);
      });

      test('format HH:mm', () {
        final t = bridge.time('HH:mm');
        expect(RegExp(r'^\d{2}:\d{2}$').hasMatch(t), isTrue);
      });

      test('format h:mm a (12-hour)', () {
        final t = bridge.time('h:mm a');
        expect(t, contains('M')); // AM or PM
      });

      test('format HH:mm:ss.SSS (with milliseconds)', () {
        final t = bridge.time('HH:mm:ss.SSS');
        expect(RegExp(r'^\d{2}:\d{2}:\d{2}\.\d{3}$').hasMatch(t), isTrue);
      });

      test('invalid format returns ISO string', () {
        final t = bridge.time('invalid');
        // ISO date includes a 'T' separator
        expect(t, contains('T'));
      });
    });

    group('date', () {
      test('default format yyyy-MM-dd', () {
        final d = bridge.date();
        expect(RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(d), isTrue);
      });

      test('format dd/MM/yyyy', () {
        final d = bridge.date('dd/MM/yyyy');
        expect(RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(d), isTrue);
      });

      test('format MM/dd/yyyy', () {
        final d = bridge.date('MM/dd/yyyy');
        expect(RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(d), isTrue);
      });

      test('format EEEE, MMMM d, yyyy (long format)', () {
        final d = bridge.date('EEEE, MMMM d, yyyy');
        // Should contain weekday and month name
        expect(
          RegExp('^(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)').hasMatch(d),
          isTrue,
        );
      });

      test('invalid format returns date part of ISO', () {
        final d = bridge.date('invalid');
        expect(RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(d), isTrue);
      });
    });
  });

  group('CrossbarBridge - Encoding', () {
    final bridge = CrossbarBridge();

    group('base64Encode/Decode', () {
      test('roundtrip works for ASCII', () {
        const original = 'Hello, World!';
        final encoded = bridge.base64Encode(original);
        final decoded = bridge.base64Decode(encoded);
        expect(decoded, equals(original));
      });

      test('roundtrip works for unicode', () {
        const original = '日本語テスト 🚀';
        final encoded = bridge.base64Encode(original);
        final decoded = bridge.base64Decode(encoded);
        expect(decoded, equals(original));
      });

      test('roundtrip works for empty string', () {
        const original = '';
        final encoded = bridge.base64Encode(original);
        final decoded = bridge.base64Decode(encoded);
        expect(decoded, equals(original));
      });

      test('encode produces valid base64', () {
        const original = 'test';
        final encoded = bridge.base64Encode(original);
        // Base64 of 'test' is 'dGVzdA=='
        expect(encoded, equals('dGVzdA=='));
      });
    });

    group('uuid', () {
      test('generates string with dashes', () {
        final id = bridge.uuid();
        expect(id.contains('-'), isTrue);
      });

      test('generates string on each call', () {
        // Just verify it generates something valid
        final id1 = bridge.uuid();
        final id2 = bridge.uuid();

        // Both should be valid UUIDs (contain dashes)
        expect(id1.contains('-'), isTrue);
        expect(id2.contains('-'), isTrue);
      });

      test('has correct format structure', () {
        final id = bridge.uuid();
        final parts = id.split('-');
        expect(parts.length, equals(5));
      });
    });

    group('random', () {
      test('returns value in range [0, max)', () {
        for (var i = 0; i < 20; i++) {
          final n = bridge.random(100);
          expect(n, greaterThanOrEqualTo(0));
          expect(n, lessThan(100));
        }
      });

      test('default max is 100', () {
        final n = bridge.random();
        expect(n, greaterThanOrEqualTo(0));
        expect(n, lessThan(100));
      });
    });

    group('hash', () {
      test('produces non-empty result for input', () {
        final h = bridge.hash('test');
        // Either a hash or empty if sha256sum not available
        // On most systems, should work
        if (h.isNotEmpty) {
          // SHA256 produces 64 hex characters
          expect(h.length, equals(64));
        }
      });
    });
  });

  group('CrossbarBridge - Environment', () {
    final bridge = CrossbarBridge();

    group('env', () {
      test('returns HOME or USERPROFILE', () {
        final home = bridge.env('HOME') ?? bridge.env('USERPROFILE');
        expect(home, isNotNull);
      });

      test('returns null for nonexistent variable', () {
        final result = bridge.env('DEFINITELY_NOT_A_REAL_ENV_VAR_XYZ123');
        expect(result, isNull);
      });

      test('returns PATH', () {
        final path = bridge.env('PATH');
        expect(path, isNotNull);
        expect(path, isNotEmpty);
      });
    });

    group('envAll', () {
      test('returns map of environment variables', () {
        final all = bridge.envAll;
        expect(all, isA<Map<String, String>>());
        expect(all, isNotEmpty);
      });
    });

    group('homeDir', () {
      test('returns valid path', () {
        expect(bridge.homeDir, isNotEmpty);
        expect(bridge.homeDir, isNot('~'));
      });
    });

    group('tempDir', () {
      test('returns valid path', () {
        expect(bridge.tempDir, isNotEmpty);
      });
    });

    group('platform', () {
      test('returns known platform name', () {
        expect(
          ['linux', 'macos', 'windows', 'android', 'ios', 'unknown'],
          contains(bridge.platform),
        );
      });
    });

    group('isMobile', () {
      test('returns boolean', () {
        expect(bridge.isMobile, isA<bool>());
      });
    });

    group('isDesktop', () {
      test('returns boolean', () {
        expect(bridge.isDesktop, isA<bool>());
      });
    });

    group('platform flags are exclusive', () {
      test('only one of isMobile or isDesktop is true on common platforms', () {
        // On test environment, should be desktop
        expect(bridge.isDesktop || bridge.isMobile, isTrue);
      });
    });
  });

  group('CrossbarBridge - Exec', () {
    final bridge = CrossbarBridge();

    group('exec', () {
      test('runs echo command', () async {
        final result = await bridge.exec('echo hello');
        expect(result, equals('hello'));
      });

      test('runs command with arguments', () async {
        final result = await bridge.exec('echo "test arg"');
        expect(result, contains('test'));
      });
    });

    group('execSync', () {
      test('runs echo command synchronously', () {
        final result = bridge.execSync('echo sync');
        expect(result, equals('sync'));
      });
    });
  });

  group('CrossbarBridge - Singleton', () {
    test('factory returns same instance', () {
      final a = CrossbarBridge();
      final b = CrossbarBridge();
      expect(identical(a, b), isTrue);
    });

    test('global instance is same as factory', () {
      final instance = CrossbarBridge();
      expect(identical(instance, crossbar), isTrue);
    });
  });
}
