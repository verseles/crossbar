import 'dart:convert';
import 'dart:io';

import '../../core/api/utils_api.dart'; // Vpn logic is in UtilsApi? Yes, I checked.
import '../cli_utils.dart'; // for mapToXml if needed
import 'base_command.dart';

class VpnCommand extends CliCommand {
  @override
  String get name => 'vpn';

  @override
  String get description => 'VPN status';

  @override
  Future<int> execute(List<String> args) async {
    // Command: crossbar vpn status
    // Old CLI had --vpn-status

    if (args.isEmpty) {
       // Default to status?
       return _status(args);
    }

    final subcommand = args[0];
    if (subcommand == 'status') {
      return _status(args);
    } else {
      stderr.writeln('Error: Unknown vpn subcommand: $subcommand');
      return 1;
    }
  }

  Future<int> _status(List<String> args) async {
    const api = UtilsApi();
    final jsonOutput = args.contains('--json');
    final xmlOutput = args.contains('--xml');

    final result = await api.getVpnStatus();
    if (jsonOutput) {
      print(jsonEncode(result));
    } else if (xmlOutput) {
      print(mapToXml(result, root: 'vpn'));
    } else {
      if (result['connected'] == true) {
        final name = result['name'] ?? result['type'] ?? 'VPN';
        print('VPN: Connected ($name)');
      } else {
        print('VPN: Disconnected');
      }
    }
    return 0;
  }
}
