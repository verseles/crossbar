import 'dart:io';

import '../../core/api/utils_api.dart';
import 'base_command.dart';

class BluetoothCommand extends CliCommand {
  @override
  String get name => 'bluetooth';

  @override
  String get description => 'Bluetooth control (on, off, devices)';

  @override
  Future<int> execute(List<String> args) async {
    const api = UtilsApi();
    final jsonOutput = args.contains('--json');
    final xmlOutput = args.contains('--xml');
    final values = args.where((a) => !a.startsWith('--')).toList();

    if (values.isEmpty || values[0] == 'status') {
      // Get Status
      final status = await api.getBluetoothStatus();
      printFormatted(
          {'bluetooth': status},
          json: jsonOutput,
          xml: xmlOutput,
          plain: (_) => 'Bluetooth: $status'
      );
      return 0;
    }

    final val = values[0].toLowerCase();

    if (val == 'devices') {
      final devices = await api.listBluetoothDevices();
      printFormatted(
          devices,
          json: jsonOutput,
          xml: xmlOutput,
          plain: (_) {
              if (devices.isEmpty) return 'No paired devices found';
              final buffer = StringBuffer();
              for (final device in devices) {
                  buffer.writeln('${device['mac']}: ${device['name']}');
              }
              return buffer.toString().trimRight();
          }
      );
      return 0;
    }

    bool newState;
    if (val == 'on' || val == 'true') {
      newState = true;
    } else if (val == 'off' || val == 'false') {
      newState = false;
    } else if (val == 'toggle') {
      final current = await api.getBluetoothStatus();
      newState = !current.startsWith('on'); // if 'on' or 'on:X' -> true
    } else {
      stderr.writeln('Error: bluetooth requires on|off|toggle|status|devices');
      return 1;
    }

    final result = newState
        ? await api.enableBluetooth()
        : await api.disableBluetooth();

    printFormatted(
        {'success': result, 'bluetooth': newState},
        json: jsonOutput,
        xml: xmlOutput,
        plain: (_) => result ? 'Bluetooth set to ${newState ? 'on' : 'off'}' : 'Failed to set Bluetooth'
    );
    return result ? 0 : 1;
  }
}
