import 'dart:convert';
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
    final values = args.where((a) => !a.startsWith('--')).toList();

    if (values.isEmpty) {
      // Get
      final result = await api.getDndStatus();
      if (jsonOutput) {
        print(jsonEncode({'dnd': result}));
      } else {
        print(result ? 'Do Not Disturb: ON' : 'Do Not Disturb: OFF');
      }
    } else {
      // Set or Toggle
      final val = values[0].toLowerCase();

      if (val == 'toggle') {
        final current = await api.getDndStatus();
        final newState = !current;
        final result = await api.setDnd(newState);
        print(result ? 'DND set to ${newState ? 'on' : 'off'}' : 'Failed to toggle DND');
        return result ? 0 : 1;
      }

      if (val != 'on' && val != 'off' && val != 'true' && val != 'false') {
        stderr.writeln('Error: dnd requires on|off|toggle');
        return 1;
      }

      final enable = (val == 'on' || val == 'true');
      final result = await api.setDnd(enable);
      print(result ? 'DND set to $val' : 'Failed to set DND');
      return result ? 0 : 1;
    }
    return 0;
  }
}
