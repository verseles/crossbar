import 'dart:io';

import '../../core/api/media_api.dart';
import 'base_command.dart';

class ScreenCommand extends CliCommand {
  @override
  String get name => 'screen';

  @override
  String get description => 'Screen brightness and resolution';

  @override
  Future<int> execute(List<String> args) async {
    if (args.isEmpty) {
      stderr.writeln('Error: screen command requires a subcommand (brightness, size)');
      return 1;
    }

    final subcommand = args[0];
    final commandArgs = args.sublist(1);
    final jsonOutput = args.contains('--json');
    final xmlOutput = args.contains('--xml');

    switch (subcommand) {
      case 'brightness':
        return _handleBrightness(commandArgs, jsonOutput, xmlOutput);
      case 'size':
        return _handleSize(jsonOutput, xmlOutput);
      default:
        stderr.writeln('Error: Unknown screen subcommand: $subcommand');
        return 1;
    }
  }

  Future<int> _handleBrightness(List<String> args, bool json, bool xml) async {
    const api = MediaApi();
    final values = args.where((a) => !a.startsWith('--')).toList();

    if (values.isEmpty) {
      // Get
      final result = await api.getBrightness();
      printFormatted(
          {'brightness': result},
          json: json,
          xml: xml,
          plain: (_) => '$result%'
      );
    } else {
      // Set
      final level = int.tryParse(values[0]);
      if (level == null) {
        stderr.writeln('Error: brightness requires a number (0-100)');
        return 1;
      }
      final result = await api.setBrightness(level);
      if (result) {
        printFormatted(
            {'success': true, 'brightness': level},
            json: json,
            xml: xml,
            plain: (_) => 'Brightness set to $level%'
        );
      } else {
        stderr.writeln('Failed to set brightness');
        return 1;
      }
    }
    return 0;
  }

  Future<int> _handleSize(bool json, bool xml) async {
    var resultStr = 'unknown';

    try {
      if (Platform.isLinux) {
        final result = await Process.run('xdpyinfo', []);
        final output = result.stdout as String;
        final match = RegExp(r'dimensions:\s+(\d+x\d+)').firstMatch(output);
        resultStr = match?.group(1) ?? 'unknown';
      } else if (Platform.isMacOS) {
        final result = await Process.run('system_profiler', ['SPDisplaysDataType']);
        final output = result.stdout as String;
        final match = RegExp(r'Resolution:\s+(\d+ x \d+)').firstMatch(output);
        resultStr = match?.group(1)?.replaceAll(' ', '') ?? 'unknown';
      } else if (Platform.isWindows) {
        final result = await Process.run('wmic', [
          'path', 'Win32_VideoController', 'get',
          'CurrentHorizontalResolution,CurrentVerticalResolution', '/format:list'
        ]);
        final output = result.stdout as String;
        final h = RegExp(r'CurrentHorizontalResolution=(\d+)').firstMatch(output);
        final v = RegExp(r'CurrentVerticalResolution=(\d+)').firstMatch(output);
        if (h != null && v != null) {
          resultStr = '${h.group(1)}x${v.group(1)}';
        }
      }
    } catch (e) {
      // ignore
    }

    Map<String, dynamic> data;
    final parts = resultStr.split('x');
    if (parts.length == 2) {
        data = {
          'width': int.tryParse(parts[0]),
          'height': int.tryParse(parts[1]),
          'resolution': resultStr
        };
    } else {
        data = {'resolution': resultStr};
    }

    printFormatted(
        data,
        json: json,
        xml: xml,
        plain: (_) => resultStr
    );
    return 0;
  }
}
