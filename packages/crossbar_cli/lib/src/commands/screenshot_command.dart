// ignore_for_file: avoid_print
import 'dart:io';

import 'package:crossbar_core/crossbar_core.dart';
import 'base_command.dart';

class ScreenshotCommand extends CliCommand {
  ScreenshotCommand({this.api = const UtilsApi()});

  final UtilsApi api;

  @override
  String get name => 'screenshot';

  @override
  String get description => 'Take a screenshot';

  @override
  Future<int> execute(List<String> args) async {
    String? path;
    var toClipboard = false;

    // Parse args
    if (args.contains('--clipboard') || args.contains('-c')) {
      toClipboard = true;
    }

    final values = args.where((a) => !a.startsWith('-')).toList();
    if (values.isNotEmpty) {
      path = values[0];
    }

    final jsonOutput = args.contains('--json');
    final xmlOutput = args.contains('--xml');

    final result = await api.takeScreenshot(path: path, toClipboard: toClipboard);

    if (result != null) {
       printFormatted(
            {'success': true, 'path': result, 'clipboard': toClipboard},
            json: jsonOutput,
            xml: xmlOutput,
            plain: (_) => toClipboard ? 'Screenshot copied to clipboard' : 'Screenshot saved to $result'
        );
        return 0;
    } else {
        stderr.writeln('Failed to take screenshot');
        return 1;
    }
  }
}
