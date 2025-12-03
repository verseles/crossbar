import 'dart:io';

import '../../core/api/utils_api.dart';
import 'base_command.dart';

class DndCommand extends CliCommand {
  @override
  String get name => 'dnd';

  @override
  String get description => 'Do Not Disturb control';

  @override
  Future<int> execute(List<String> args) async {
    const api = UtilsApi();
    final jsonOutput = args.contains('--json');
    final xmlOutput = args.contains('--xml');
    final values = args.where((a) => !a.startsWith('--')).toList();

    if (values.isEmpty) {
      // Get
      final result = await api.getDndStatus();
      printFormatted(
          {'dnd': result},
          json: jsonOutput,
          xml: xmlOutput,
          plain: (_) => result ? 'Do Not Disturb: ON' : 'Do Not Disturb: OFF'
      );
    } else {
      // Set or Toggle
      final val = values[0].toLowerCase();
      bool newState;

      if (val == 'toggle') {
        final current = await api.getDndStatus();
        newState = !current;
      } else if (val == 'on' || val == 'true') {
        newState = true;
      } else if (val == 'off' || val == 'false') {
        newState = false;
      } else {
        stderr.writeln('Error: dnd requires on|off|toggle');
        return 1;
      }

      final result = await api.setDnd(newState);
      printFormatted(
          {'success': result, 'dnd': newState},
          json: jsonOutput,
          xml: xmlOutput,
          plain: (_) => result ? 'DND set to ${newState ? 'on' : 'off'}' : 'Failed to set DND'
      );
      return result ? 0 : 1;
    }
    return 0;
  }
}
