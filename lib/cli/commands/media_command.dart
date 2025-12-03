import 'dart:io';

import '../../core/api/media_api.dart';
import 'base_command.dart';

class MediaCommand extends CliCommand {
  @override
  String get name => 'media';

  @override
  String get description => 'Media playback controls (play, pause, next, etc.)';

  @override
  Future<int> execute(List<String> args) async {
    if (args.isEmpty) {
      stderr.writeln('Error: media command requires a subcommand');
      return 1;
    }

    final subcommand = args[0];
    final commandArgs = args.sublist(1);
    final jsonOutput = args.contains('--json');
    final xmlOutput = args.contains('--xml');

    const api = MediaApi();

    switch (subcommand) {
      case 'play':
        final result = await api.play();
        printFormatted(
            {'success': result, 'action': 'play'},
            json: jsonOutput, xml: xmlOutput,
            plain: (_) => result ? 'Playing' : 'Failed to play'
        );
        return result ? 0 : 1;

      case 'pause':
        final result = await api.pause();
        printFormatted(
            {'success': result, 'action': 'pause'},
            json: jsonOutput, xml: xmlOutput,
            plain: (_) => result ? 'Paused' : 'Failed to pause'
        );
        return result ? 0 : 1;

      case 'toggle':
      case 'play-pause': // Alias
        final result = await api.playPause();
        printFormatted(
            {'success': result, 'action': 'toggle'},
            json: jsonOutput, xml: xmlOutput,
            plain: (_) => result ? 'Toggled' : 'Failed to toggle'
        );
        return result ? 0 : 1;

      case 'stop':
        final result = await api.stop();
        printFormatted(
            {'success': result, 'action': 'stop'},
            json: jsonOutput, xml: xmlOutput,
            plain: (_) => result ? 'Stopped' : 'Failed to stop'
        );
        return result ? 0 : 1;

      case 'next':
        final result = await api.next();
        printFormatted(
            {'success': result, 'action': 'next'},
            json: jsonOutput, xml: xmlOutput,
            plain: (_) => result ? 'Next track' : 'Failed to skip'
        );
        return result ? 0 : 1;

      case 'prev':
      case 'previous':
        final result = await api.previous();
        printFormatted(
            {'success': result, 'action': 'previous'},
            json: jsonOutput, xml: xmlOutput,
            plain: (_) => result ? 'Previous track' : 'Failed to go back'
        );
        return result ? 0 : 1;

      case 'seek':
        final values = commandArgs.where((a) => !a.startsWith('--')).toList();
        if (values.isEmpty) {
          stderr.writeln('Error: seek requires offset (e.g., +30s, -10s)');
          return 1;
        }
        final offset = values[0];
        final result = await api.seek(offset);
        printFormatted(
            {'success': result, 'action': 'seek', 'offset': offset},
            json: jsonOutput, xml: xmlOutput,
            plain: (_) => result ? 'Seeked $offset' : 'Failed to seek'
        );
        return result ? 0 : 1;

      case 'playing':
        final result = await api.getPlaying();
        printFormatted(
            result,
            json: jsonOutput,
            xml: xmlOutput,
            xmlRoot: 'media',
            plain: (_) {
                if (result['playing'] == true) {
                    final buffer = StringBuffer();
                    buffer.writeln('${result['title']} - ${result['artist']}');
                    if (result['album']?.isNotEmpty == true) {
                        buffer.writeln('Album: ${result['album']}');
                    }
                    if (result['position']?.isNotEmpty == true) {
                        buffer.writeln('${result['position']} / ${result['duration']}');
                    }
                    return buffer.toString().trimRight();
                } else {
                    return 'Not playing';
                }
            }
        );
        return 0;

      default:
        stderr.writeln('Error: Unknown media subcommand: $subcommand');
        return 1;
    }
  }
}
