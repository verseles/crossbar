// ignore_for_file: avoid_slow_async_io
import 'package:crossbar_core/crossbar_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final bridge = CrossbarBridge();

  group('CrossbarBridge - System', () {
    test('cpu returns valid percentage', () async {
      final cpu = await bridge.cpu();
      expect(cpu, greaterThanOrEqualTo(0));
      expect(cpu, lessThanOrEqualTo(100));
    });

    test('memory returns map with expected keys', () async {
      final mem = await bridge.memory();
      expect(mem, isA<Map<String, dynamic>>());
      expect(mem.containsKey('raw'), isTrue);
    });

    test('battery returns map with expected keys', () async {
      final batt = await bridge.battery();
      expect(batt, isA<Map<String, dynamic>>());
      expect(batt.containsKey('available'), isTrue);
      expect(batt.containsKey('status'), isTrue);
    });

    test('uptime returns non-empty string', () async {
      final uptime = await bridge.uptime();
      expect(uptime, isNotEmpty);
    });

    test('os returns valid platform name', () async {
      final os = await bridge.os();
      expect(['linux', 'macos', 'windows'], contains(os.toLowerCase()));
    });
  });

  group('CrossbarBridge - Time & Date', () {
    test('time returns formatted time', () {
      final time = bridge.time();
      expect(RegExp(r'^\d{2}:\d{2}:\d{2}$').hasMatch(time), isTrue);
    });

    test('time with format HH:mm', () {
      final time = bridge.time('HH:mm');
      expect(RegExp(r'^\d{2}:\d{2}$').hasMatch(time), isTrue);
    });

    test('time with format h:mm a', () {
      final time = bridge.time('h:mm a');
      expect(time.contains('M'), isTrue); // AM or PM
    });

    test('date returns formatted date', () {
      final date = bridge.date();
      expect(RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date), isTrue);
    });
  });

  group('CrossbarBridge - Network', () {
    test('netStatus returns online or offline', () async {
      final status = await bridge.netStatus();
      expect(['online', 'offline'], contains(status));
    });

    test('localIp returns valid IP or localhost', () async {
      final ip = await bridge.localIp();
      expect(ip, isNotEmpty);
    });

    test('web makes HTTP request', () async {
      final result = await bridge.web('api.coinbase.com/v2/prices/BTC-USD/spot');
      expect(result, isA<Map>());
      expect((result as Map).containsKey('data'), isTrue);
    }, timeout: const Timeout(Duration(seconds: 30)), skip: 'Requires network access');

    test('ping returns latency or timeout', () async {
      final ping = await bridge.ping('127.0.0.1');
      expect(ping.contains('ms') || ping == 'timeout' || ping == 'error', isTrue);
    });
  });

  group('CrossbarBridge - Environment', () {
    test('env returns HOME', () {
      final home = bridge.env('HOME') ?? bridge.env('USERPROFILE');
      expect(home, isNotNull);
    });

    test('homeDir returns path', () {
      expect(bridge.homeDir, isNotEmpty);
      expect(bridge.homeDir, isNot('~'));
    });

    test('platform returns valid name', () {
      expect(['linux', 'macos', 'windows', 'android', 'ios'], contains(bridge.platform));
    });

    test('isDesktop or isMobile is true', () {
      expect(bridge.isDesktop || bridge.isMobile, isTrue);
    });
  });

  group('CrossbarBridge - Encoding', () {
    test('base64Encode and Decode roundtrip', () {
      const original = 'Hello, World!';
      final encoded = bridge.base64Encode(original);
      final decoded = bridge.base64Decode(encoded);
      expect(decoded, equals(original));
    });

    test('uuid generates valid format', () {
      final id = bridge.uuid();
      expect(id.contains('-'), isTrue);
    });

    test('random returns number in range', () {
      final num = bridge.random(100);
      expect(num, greaterThanOrEqualTo(0));
      expect(num, lessThan(100));
    });
  });
}
