import 'dart:io';

import '../../core/api/media_api.dart';
import 'base_command.dart';

class AudioCommand extends CliCommand {
  @override
  String get name => 'audio';

  @override
  String get description => 'Audio volume, mute, and output control';

  @override
  Future<int> execute(List<String> args) async {
    if (args.isEmpty) {
      stderr.writeln('Error: audio command requires a subcommand (volume, mute, output)');
      return 1;
    }

    final subcommand = args[0];
    final commandArgs = args.sublist(1);
    final jsonOutput = args.contains('--json');
    final xmlOutput = args.contains('--xml');

    const api = MediaApi();

    switch (subcommand) {
      case 'volume':
        return _handleVolume(api, commandArgs, jsonOutput, xmlOutput);
      case 'mute':
        return _handleMute(api, commandArgs, jsonOutput, xmlOutput);
      case 'output':
        return _handleOutput(api, commandArgs, jsonOutput, xmlOutput);
      default:
        stderr.writeln('Error: Unknown audio subcommand: $subcommand');
        return 1;
    }
  }

  Future<int> _handleVolume(MediaApi api, List<String> args, bool json, bool xml) async {
    final values = args.where((a) => !a.startsWith('--')).toList();

    if (values.isEmpty) {
      // Get
      final result = await api.getVolume();
      printFormatted(
        {'volume': result},
        json: json,
        xml: xml,
        plain: (_) => '$result%',
      );
    } else {
      // Set
      final level = int.tryParse(values[0]);
      if (level == null) {
        stderr.writeln('Error: volume requires a number (0-100)');
        return 1;
      }
      final result = await api.setVolume(level);
      if (result) {
        printFormatted(
          {'success': true, 'volume': level},
          json: json,
          xml: xml,
          plain: (_) => 'Volume set to $level%',
        );
      } else {
        stderr.writeln('Failed to set volume');
        return 1;
      }
    }
    return 0;
  }

  Future<int> _handleMute(MediaApi api, List<String> args, bool json, bool xml) async {
    final values = args.where((a) => !a.startsWith('--')).toList();

    if (values.isNotEmpty) {
       final val = values[0].toLowerCase();
       if (val == 'on' || val == 'true') {
           final isMuted = await api.isMuted();
           if (!isMuted) await api.toggleMute();
           printFormatted(
               {'muted': true},
               json: json, xml: xml,
               plain: (_) => 'Muted'
           );
           return 0;
       } else if (val == 'off' || val == 'false') {
           final isMuted = await api.isMuted();
           if (isMuted) await api.toggleMute();
           printFormatted(
               {'muted': false},
               json: json, xml: xml,
               plain: (_) => 'Unmuted'
           );
           return 0;
       }
    }

    // Default: Toggle
    final result = await api.toggleMute();
    if (result) {
      final isMuted = await api.isMuted();
      printFormatted(
          {'muted': isMuted},
          json: json, xml: xml,
          plain: (_) => isMuted ? 'Muted' : 'Unmuted'
      );
    } else {
      stderr.writeln('Failed to toggle mute');
      return 1;
    }
    return 0;
  }

  Future<int> _handleOutput(MediaApi api, List<String> args, bool json, bool xml) async {
    if (args.contains('--list') || args.contains('list')) {
      final devices = await api.listAudioOutputs();
      printFormatted(
          devices,
          json: json, xml: xml,
          plain: (_) {
              final buffer = StringBuffer();
              for (final device in devices) {
                  buffer.writeln('${device['id']}: ${device['name']}');
              }
              return buffer.toString().trimRight();
          }
      );
      return 0;
    }

    final values = args.where((a) => !a.startsWith('--')).toList();

    if (values.isEmpty) {
      // Get
      final result = await api.getAudioOutput();
      printFormatted(
        {'output': result},
        json: json,
        xml: xml,
        plain: (_) => result,
      );
    } else {
      // Set
      final device = values[0];
      final result = await api.setAudioOutput(device);
      if (result) {
        printFormatted(
            {'success': true, 'output': device},
            json: json, xml: xml,
            plain: (_) => 'Output set to $device'
        );
      } else {
        stderr.writeln('Failed to set output');
        return 1;
      }
    }
    return 0;
  }
}
