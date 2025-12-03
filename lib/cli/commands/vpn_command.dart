import 'dart:io';

import '../../core/api/utils_api.dart';
import 'base_command.dart';

class VpnCommand extends CliCommand {
  @override
  String get name => 'vpn';

  @override
  String get description => 'VPN status';

  @override
  Future<int> execute(List<String> args) async {
    final subcommand = args.isNotEmpty ? args[0] : 'status';

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
    printFormatted(
        result,
        json: jsonOutput,
        xml: xmlOutput,
        xmlRoot: 'vpn',
        plain: (_) {
           if (result['connected'] == true) {
             final name = result['name'] ?? result['type'] ?? 'VPN';
             return 'VPN: Connected ($name)';
           } else {
             return 'VPN: Disconnected';
           }
        }
    );
    return 0;
  }
}
