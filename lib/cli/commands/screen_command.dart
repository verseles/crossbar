import 'dart:convert';
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

    switch (subcommand) {
      case 'brightness':
        return _handleBrightness(commandArgs, jsonOutput);
      case 'size':
        return _handleSize(jsonOutput);
      default:
        stderr.writeln('Error: Unknown screen subcommand: $subcommand');
        return 1;
    }
  }

  Future<int> _handleBrightness(List<String> args, bool jsonOutput) async {
    const api = MediaApi();
    final values = args.where((a) => !a.startsWith('--')).toList();

    if (values.isEmpty) {
      // Get
      final result = await api.getBrightness();
      if (jsonOutput) {
        print(jsonEncode({'brightness': result}));
      } else {
        print('$result%');
      }
    } else {
      // Set
      final level = int.tryParse(values[0]);
      if (level == null) {
        stderr.writeln('Error: brightness requires a number (0-100)');
        return 1;
      }
      final result = await api.setBrightness(level);
      if (result) {
        print('Brightness set to $level%');
      } else {
        stderr.writeln('Failed to set brightness');
        return 1;
      }
    }
    return 0;
  }

  Future<int> _handleSize(bool jsonOutput) async {
    String resultStr = 'unknown';

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

    if (jsonOutput) {
      final parts = resultStr.split('x');
      if (parts.length == 2) {
        print(jsonEncode({
          'width': int.tryParse(parts[0]),
          'height': int.tryParse(parts[1]),
          'resolution': resultStr
        }));
      } else {
        print(jsonEncode({'resolution': resultStr}));
      }
    } else {
      print(resultStr);
    }
    return 0;
  }
}
