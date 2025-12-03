import 'dart:io';

import '../../core/api/network_api.dart';
import 'base_command.dart';

class NetworkCommand extends CliCommand {
  @override
  String get name => 'net';

  @override
  String get description => 'Network diagnostics (status, ip, ping)';

  @override
  Future<int> execute(List<String> args) async {
    if (args.isEmpty) {
      stderr.writeln('Error: net command requires a subcommand (status, ip, ping)');
      return 1;
    }

    final subcommand = args[0];
    final commandArgs = args.sublist(1);
    final jsonOutput = args.contains('--json');
    final xmlOutput = args.contains('--xml');

    const api = NetworkApi();

    switch (subcommand) {
      case 'status':
        final result = await api.getNetStatus();
        printFormatted(
            {'status': result},
            json: jsonOutput,
            xml: xmlOutput,
            plain: (_) => result
        );
        return 0;

      case 'ip':
        final isPublic = commandArgs.contains('--public');
        final result = isPublic ? await api.getPublicIp() : await api.getLocalIp();
        printFormatted(
            {'ip': result, 'type': isPublic ? 'public' : 'local'},
            json: jsonOutput,
            xml: xmlOutput,
            plain: (_) => result
        );
        return 0;

      case 'ping':
        final values = commandArgs.where((a) => !a.startsWith('--')).toList();
        if (values.isEmpty) {
          stderr.writeln('Error: ping requires a host');
          return 1;
        }
        final host = values[0];
        final result = await api.ping(host);
        printFormatted(
            {'ping': result, 'host': host},
            json: jsonOutput,
            xml: xmlOutput,
            plain: (_) => result
        );
        return 0;

      default:
        stderr.writeln('Error: Unknown net subcommand: $subcommand');
        return 1;
    }
  }
}
