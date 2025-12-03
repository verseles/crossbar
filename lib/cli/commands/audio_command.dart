import 'dart:convert';
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
    final jsonOutput = args.contains('--json'); // check full args for flag

    const api = MediaApi();

    switch (subcommand) {
      case 'volume':
        return _handleVolume(api, commandArgs, jsonOutput);
      case 'mute':
        return _handleMute(api, commandArgs, jsonOutput);
      case 'output':
        return _handleOutput(api, commandArgs, jsonOutput);
      default:
        stderr.writeln('Error: Unknown audio subcommand: $subcommand');
        return 1;
    }
  }

  Future<int> _handleVolume(MediaApi api, List<String> args, bool jsonOutput) async {
    final values = args.where((a) => !a.startsWith('--')).toList();

    if (values.isEmpty) {
      // Get
      final result = await api.getVolume();
      if (jsonOutput) {
        print(jsonEncode({'volume': result}));
      } else {
        print('$result%');
      }
    } else {
      // Set
      final level = int.tryParse(values[0]);
      if (level == null) {
        stderr.writeln('Error: volume requires a number (0-100)');
        return 1;
      }
      final result = await api.setVolume(level);
      if (result) {
        print('Volume set to $level%');
      } else {
        stderr.writeln('Failed to set volume');
        return 1;
      }
    }
    return 0;
  }

  Future<int> _handleMute(MediaApi api, List<String> args, bool jsonOutput) async {
    final values = args.where((a) => !a.startsWith('--')).toList();

    if (values.isNotEmpty) {
       final val = values[0].toLowerCase();
       if (val == 'on' || val == 'true') {
           final isMuted = await api.isMuted();
           if (!isMuted) await api.toggleMute();
           print('Muted');
           return 0;
       } else if (val == 'off' || val == 'false') {
           final isMuted = await api.isMuted();
           if (isMuted) await api.toggleMute();
           print('Unmuted');
           return 0;
       }
    }

    // Default: Toggle
    final result = await api.toggleMute();
    if (result) {
      final isMuted = await api.isMuted();
      print(isMuted ? 'Muted' : 'Unmuted');
    } else {
      stderr.writeln('Failed to toggle mute');
      return 1;
    }
    return 0;
  }

  Future<int> _handleOutput(MediaApi api, List<String> args, bool jsonOutput) async {
    if (args.contains('--list') || args.contains('list')) {
      final devices = await api.listAudioOutputs();
      if (jsonOutput) {
        print(jsonEncode(devices));
      } else {
        for (final device in devices) {
          print('${device['id']}: ${device['name']}');
        }
      }
      return 0;
    }

    final values = args.where((a) => !a.startsWith('--')).toList();

    if (values.isEmpty) {
      // Get
      final result = await api.getAudioOutput();
      if (jsonOutput) {
        print(jsonEncode({'output': result}));
      } else {
        print(result);
      }
    } else {
      // Set
      final device = values[0];
      final result = await api.setAudioOutput(device);
      if (result) {
        print('Output set to $device');
      } else {
        stderr.writeln('Failed to set output');
        return 1;
      }
    }
    return 0;
  }
}
