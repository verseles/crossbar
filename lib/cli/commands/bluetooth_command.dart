import 'dart:convert';
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
    final values = args.where((a) => !a.startsWith('--')).toList();

    if (values.isEmpty || values[0] == 'status') {
      // Get Status
      final status = await api.getBluetoothStatus();
      if (jsonOutput) {
        print(jsonEncode({'bluetooth': status}));
      } else {
        print('Bluetooth: $status');
      }
      return 0;
    }

    final val = values[0].toLowerCase();

    if (val == 'devices') {
      final devices = await api.listBluetoothDevices();
      if (jsonOutput) {
        print(jsonEncode(devices));
      } else {
        if (devices.isEmpty) {
          print('No paired devices found');
        } else {
          for (final device in devices) {
            print('${device['mac']}: ${device['name']}');
          }
        }
      }
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

    print(result ? 'Bluetooth set to ${newState ? 'on' : 'off'}' : 'Failed to set Bluetooth');
    return result ? 0 : 1;
  }
}
