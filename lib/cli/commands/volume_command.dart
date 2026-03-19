// ignore_for_file: avoid_print
import 'dart:io';

import '../../core/api/media_api.dart';
import 'base_command.dart';

class VolumeCommand extends CliCommand {
  @override
  String get name => 'volume';

  @override
  String get description => 'Control volume (alias for audio volume)';

  @override
  Future<int> execute(List<String> args) async {
    const api = MediaApi();
    final jsonOutput = args.contains('--json');
    final xmlOutput = args.contains('--xml');
    final values = args.where((a) => !a.startsWith('--')).toList();

    if (values.isEmpty) {
      final result = await api.getVolume();
      printFormatted(
        {'volume': result},
        json: jsonOutput,
        xml: xmlOutput,
        plain: (_) => '$result%',
      );
      return 0;
    }

    final level = int.tryParse(values[0]);
    if (level == null) {
      stderr.writeln('Error: volume requires a number (0-100)');
      return 1;
    }

    final result = await api.setVolume(level);
    if (!result) {
      stderr.writeln('Failed to set volume');
      return 1;
    }

    printFormatted(
      {'success': true, 'volume': level},
      json: jsonOutput,
      xml: xmlOutput,
      plain: (_) => 'Volume set to $level%',
    );
    return 0;
  }
}
