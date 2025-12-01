import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:crossbar/core/api/system_api.dart';

void main() {
  group('SystemApi', () {
    const api = SystemApi();

    group('getCpuUsage', () {
      test('returns a string', () async {
        final result = await api.getCpuUsage();

        expect(result, isA<String>());
      });

      test('returns numeric value or 0.0', () async {
        final result = await api.getCpuUsage();

        final parsed = double.tryParse(result);
        expect(parsed, isNotNull);
        expect(parsed, greaterThanOrEqualTo(0));
      });
    });

    group('getMemoryUsage', () {
      test('returns a string', () async {
        final result = await api.getMemoryUsage();

        expect(result, isA<String>());
      });

      test('returns formatted memory or Unknown', () async {
        final result = await api.getMemoryUsage();

        expect(
          result.contains('GB') || result == 'Unknown',
          true,
        );
      });
    });

    group('getBatteryStatus', () {
      test('returns a string', () async {
        final result = await api.getBatteryStatus();

        expect(result, isA<String>());
      });

      test('returns percentage or N/A', () async {
        final result = await api.getBatteryStatus();

        expect(
          result.contains('%') || result == 'N/A',
          true,
        );
      });
    });

    group('getUptime', () {
      test('returns a string', () async {
        final result = await api.getUptime();

        expect(result, isA<String>());
      });

      test('returns formatted uptime or Unknown', () async {
        final result = await api.getUptime();

        expect(
          result.contains('m') ||
              result.contains('h') ||
              result.contains('d') ||
              result == 'Unknown',
          true,
        );
      });
    });

    group('getDiskUsage', () {
      test('returns a string', () async {
        final result = await api.getDiskUsage();

        expect(result, isA<String>());
      });

      test('accepts path parameter', () async {
        final result = await api.getDiskUsage('/');

        expect(result, isA<String>());
      });
    });

    group('getOs', () {
      test('returns operating system', () {
        final result = api.getOs();

        expect(result, Platform.operatingSystem);
      });

      test('returns one of known values', () {
        final result = api.getOs();

        expect(
          ['linux', 'macos', 'windows', 'android', 'ios', 'fuchsia'],
          contains(result),
        );
      });
    });

    group('getOsDetails', () {
      test('returns map with short and version', () {
        final result = api.getOsDetails();

        expect(result, contains('short'));
        expect(result, contains('version'));
      });

      test('short matches getOs', () {
        final details = api.getOsDetails();

        expect(details['short'], api.getOs());
      });

      test('version is not empty', () {
        final details = api.getOsDetails();

        expect(details['version'], isNotEmpty);
      });
    });
  });
}
