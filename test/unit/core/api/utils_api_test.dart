@Tags(['hardware'])
library;

import 'dart:io';

import 'package:crossbar/core/api/utils_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UtilsApi', () {
    const api = UtilsApi();

    group('Bluetooth', () {
      test('getBluetoothStatus returns string', () async {
        final result = await api.getBluetoothStatus();
        expect(result, isA<String>());
      });

      test('getBluetoothStatus returns valid status', () async {
        final result = await api.getBluetoothStatus();
        expect(['on', 'off', 'unavailable'].contains(result), true);
      });

      test('enableBluetooth returns boolean', () async {
        final result = await api.enableBluetooth();
        expect(result, isA<bool>());
      });

      test('disableBluetooth returns boolean', () async {
        final result = await api.disableBluetooth();
        expect(result, isA<bool>());
      });

      test('listBluetoothDevices returns list', () async {
        final result = await api.listBluetoothDevices();
        expect(result, isA<List<Map<String, String>>>());
      });
    });

    group('VPN', () {
      test('getVpnStatus returns map', () async {
        final result = await api.getVpnStatus();
        expect(result, isA<Map<String, dynamic>>());
      });

      test('getVpnStatus contains connected key', () async {
        final result = await api.getVpnStatus();
        expect(result.containsKey('connected'), true);
        expect(result['connected'], isA<bool>());
      });
    });

    group('Screenshot', () {
      test('takeScreenshot returns String or null', () async {
        final result = await api.takeScreenshot();
        expect(result, anyOf(isNull, isA<String>()));
      });

      test('takeScreenshot with clipboard option returns String or null',
          () async {
        final result = await api.takeScreenshot(toClipboard: true);
        expect(result, anyOf(isNull, isA<String>()));
      });

      test('takeScreenshot with custom path returns String or null', () async {
        final tempPath = '/tmp/test_screenshot_${DateTime.now().millisecondsSinceEpoch}.png';
        final result = await api.takeScreenshot(path: tempPath);
        expect(result, anyOf(isNull, isA<String>()));
        // Clean up if file was created
        final file = File(tempPath);
        if (await file.exists()) {
          await file.delete();
        }
      });
    });

    group('Wallpaper', () {
      test('getWallpaper returns a string', () async {
        final result = await api.getWallpaper();
        expect(result, isA<String>());
      });

      test('getWallpaper returns path or unknown', () async {
        final result = await api.getWallpaper();
        expect(result.isNotEmpty, true);
      });

      test('setWallpaper returns boolean', () async {
        // Test with non-existent file should return false
        final result = await api.setWallpaper('/nonexistent/path.png');
        expect(result, isA<bool>());
        expect(result, false); // Should fail for non-existent file
      });

      test('setWallpaper validates file exists', () async {
        final result = await api.setWallpaper('/this/file/does/not/exist.jpg');
        expect(result, false);
      });
    });

    group('Power Management', () {
      test('sleep returns boolean', () async {
        // Note: We don't actually want to sleep during tests
        // This test just verifies the method exists and returns boolean
        // The actual sleep won't work in CI/test environments
        final result = await api.sleep();
        expect(result, isA<bool>());
      });

      test('restart without confirmation returns false', () async {
        // Safety check: should not restart without confirmed=true
        final result = await api.restart();
        expect(result, false);
      });

      test('restart with confirmed=false returns false', () async {
        final result = await api.restart(confirmed: false);
        expect(result, false);
      });

      test('shutdown without confirmation returns false', () async {
        // Safety check: should not shutdown without confirmed=true
        final result = await api.shutdown();
        expect(result, false);
      });

      test('shutdown with confirmed=false returns false', () async {
        final result = await api.shutdown(confirmed: false);
        expect(result, false);
      });

      // NOTE: We do NOT test restart/shutdown with confirmed=true
      // as that would actually restart/shutdown the system!
    });

    group('Notifications', () {
      test('sendNotification returns boolean', () async {
        final result = await api.sendNotification(
          title: 'Test',
          message: 'Test notification from unit tests',
        );
        expect(result, isA<bool>());
      });

      test('sendNotification with all options returns boolean', () async {
        final result = await api.sendNotification(
          title: 'Test Title',
          message: 'Test message',
          icon: 'dialog-information',
          priority: 'normal',
        );
        expect(result, isA<bool>());
      });

      test('sendNotification with low priority returns boolean', () async {
        final result = await api.sendNotification(
          title: 'Low Priority',
          message: 'Low priority notification',
          priority: 'low',
        );
        expect(result, isA<bool>());
      });

      test('sendNotification with critical priority returns boolean', () async {
        final result = await api.sendNotification(
          title: 'Critical',
          message: 'Critical notification',
          priority: 'critical',
        );
        expect(result, isA<bool>());
      });
    });

    group('Do Not Disturb', () {
      test('getDndStatus returns boolean', () async {
        final result = await api.getDndStatus();
        expect(result, isA<bool>());
      });

      test('setDnd returns boolean', () async {
        // Get current status first
        final currentStatus = await api.getDndStatus();
        // Try to set to same value (less disruptive)
        final result = await api.setDnd(currentStatus);
        expect(result, isA<bool>());
      });
    });

    group('Open/Launch Utilities', () {
      test('openUrl returns boolean', () async {
        // Use a safe URL that won't cause issues
        // Note: This may open a browser in local tests
        final result = await api.openUrl('https://example.com');
        expect(result, isA<bool>());
      }, skip: 'May open browser window');

      test('openFile returns false for non-existent file', () async {
        final result = await api.openFile('/nonexistent/file.txt');
        expect(result, false);
      });

      test('openFile validates file exists', () async {
        final result = await api.openFile('/this/path/does/not/exist');
        expect(result, false);
      });

      test('openApp returns boolean', () async {
        // Test with a common app that may or may not exist
        final result = await api.openApp('nonexistent_app_12345');
        expect(result, isA<bool>());
        expect(result, false); // Should fail for non-existent app
      });
    });
  });
}
