import 'dart:io';

import '../../core/api/utils_api.dart';
import 'base_command.dart';

class PowerCommand extends CliCommand {
  @override
  String get name => 'power';

  @override
  String get description => 'Power management (sleep, restart, shutdown)';

  @override
  Future<int> execute(List<String> args) async {
    if (args.isEmpty) {
      stderr.writeln('Error: power command requires a subcommand (sleep, restart, shutdown)');
      return 1;
    }

    final subcommand = args[0];
    final commandArgs = args.sublist(1); // Keep flags like --confirm

    const api = UtilsApi();

    switch (subcommand) {
      case 'sleep':
        final result = await api.sleep();
        print(result ? 'System going to sleep...' : 'Failed to sleep');
        return result ? 0 : 1;

      case 'restart':
        if (!commandArgs.contains('--confirm')) {
          stderr.writeln('Error: restart requires --confirm flag for safety');
          return 1;
        }
        final result = await api.restart(confirmed: true);
        print(result ? 'System restarting...' : 'Failed to restart');
        return result ? 0 : 1;

      case 'shutdown':
        if (!commandArgs.contains('--confirm')) {
          stderr.writeln('Error: shutdown requires --confirm flag for safety');
          return 1;
        }
        final result = await api.shutdown(confirmed: true);
        print(result ? 'System shutting down...' : 'Failed to shutdown');
        return result ? 0 : 1;

      default:
        stderr.writeln('Error: Unknown power subcommand: $subcommand');
        return 1;
    }
  }
}
