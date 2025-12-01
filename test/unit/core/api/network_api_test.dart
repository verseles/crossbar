import 'package:flutter_test/flutter_test.dart';
import 'package:crossbar/core/api/network_api.dart';

void main() {
  group('NetworkApi', () {
    const api = NetworkApi();

    group('getNetStatus', () {
      test('returns online or offline', () async {
        final result = await api.getNetStatus();

        expect(['online', 'offline'], contains(result));
      });
    });

    group('getLocalIp', () {
      test('returns an IP address', () async {
        final result = await api.getLocalIp();

        expect(result, isA<String>());
        expect(result.isNotEmpty, true);
      });

      test('returns valid IPv4 format or localhost', () async {
        final result = await api.getLocalIp();

        final ipv4Pattern = RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$');
        expect(ipv4Pattern.hasMatch(result), true);
      });
    });

    group('getPublicIp', () {
      test('returns a string', () async {
        final result = await api.getPublicIp();

        expect(result, isA<String>());
      });
    }, skip: 'Requires network access');

    group('getWifiSsid', () {
      test('returns a string', () async {
        final result = await api.getWifiSsid();

        expect(result, isA<String>());
      });
    });

    group('ping', () {
      test('returns result string', () async {
        final result = await api.ping('localhost');

        expect(result, isA<String>());
      });

      test('returns ms value, timeout, or error', () async {
        final result = await api.ping('localhost');

        expect(
          result.contains('ms') ||
              result == 'timeout' ||
              result == 'error',
          true,
        );
      });
    });

    group('makeRequest', () {
      test('throws on invalid URL', () async {
        expect(
          () => api.makeRequest('not-a-url'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('setWifi', () {
      test('returns boolean', () async {
        // This test just verifies the method exists and returns properly
        // Actual WiFi control requires elevated permissions
        final result = await api.setWifi(true);
        expect(result, isA<bool>());
      });
    }, skip: 'Requires system permissions');

    group('getBluetoothStatus', () {
      test('returns a string', () async {
        final result = await api.getBluetoothStatus();

        expect(result, isA<String>());
      });

      test('returns on, off, or unknown', () async {
        final result = await api.getBluetoothStatus();

        expect(
          result.startsWith('on') ||
              result == 'off' ||
              result == 'unknown',
          true,
        );
      });
    });
  });
}
