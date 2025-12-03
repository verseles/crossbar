import 'dart:io';

import '../../core/api/network_api.dart';
import 'base_command.dart';

class WifiCommand extends CliCommand {
  @override
  String get name => 'wifi';

  @override
  String get description => 'WiFi control (on, off, ssid)';

  @override
  Future<int> execute(List<String> args) async {
    const api = NetworkApi();
    final values = args.where((a) => !a.startsWith('--')).toList();
    final jsonOutput = args.contains('--json');
    final xmlOutput = args.contains('--xml');

    if (values.isEmpty) {
      // Get Status
      final status = await _getWifiStatus();
      printFormatted(
          {'wifi': status},
          json: jsonOutput,
          xml: xmlOutput,
          plain: (_) => status ? 'WiFi: On' : 'WiFi: Off'
      );
    } else {
      final val = values[0].toLowerCase();

      if (val == 'ssid') {
        final ssid = await api.getWifiSsid();
        printFormatted(
            {'ssid': ssid},
            json: jsonOutput,
            xml: xmlOutput,
            plain: (_) => ssid
        );
        return 0;
      }

      bool newState;
      if (val == 'on' || val == 'true') {
        newState = true;
      } else if (val == 'off' || val == 'false') {
        newState = false;
      } else if (val == 'toggle') {
        final current = await _getWifiStatus();
        newState = !current;
      } else {
        stderr.writeln('Error: wifi requires on|off|toggle|ssid');
        return 1;
      }

      final result = await api.setWifi(newState);
      if (result) {
        printFormatted(
            {'success': true, 'wifi': newState},
            json: jsonOutput,
            xml: xmlOutput,
            plain: (_) => 'WiFi set to ${newState ? 'on' : 'off'}'
        );
      } else {
        stderr.writeln('Failed to set WiFi');
        return 1;
      }
    }
    return 0;
  }

  Future<bool> _getWifiStatus() async {
    try {
      if (Platform.isLinux) {
        final result = await Process.run('nmcli', ['radio', 'wifi']);
        if (result.exitCode == 0) {
          return (result.stdout as String).trim() == 'enabled';
        }
      } else if (Platform.isMacOS) {
        final result = await Process.run('networksetup', ['-getairportpower', 'en0']);
        if (result.exitCode == 0) {
          return (result.stdout as String).contains(': On');
        }
      } else if (Platform.isWindows) {
         final result = await Process.run('netsh', ['interface', 'show', 'interface', 'Wi-Fi']);
         if (result.exitCode == 0) {
            return (result.stdout as String).contains('Enabled');
         }
      }
    } catch (_) {}
    // Fallback or unknown
    return false;
  }
}
