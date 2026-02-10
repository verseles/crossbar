// ignore_for_file: avoid_print
import 'dart:io';

import 'package:crossbar_core/crossbar_core.dart';
import 'base_command.dart';

/// CLI command to take screenshots.
///
/// Supports saving to file or copying to clipboard.
/// Uses platform-specific tools: gnome-screenshot/scrot/spectacle (Linux),
/// screencapture (macOS), PowerShell (Windows).
class ScreenshotCommand extends CliCommand {
  ScreenshotCommand({UtilsApi? api}) : _api = api ?? const UtilsApi();

  final UtilsApi _api;

  @override
  String get name => 'screenshot';

  @override
  String get description => 'Take a screenshot';

  @override
  Future<int> execute(List<String> args) async {
    if (args.contains('--help') || args.contains('-h')) {
      _printUsage();
      return 0;
    }

    final toClipboard =
        args.contains('--clipboard') || args.contains('-c');
    final jsonOutput = args.contains('--json');
    final xmlOutput = args.contains('--xml');

    // First non-flag argument is the file path
    final positional = args.where((a) => !a.startsWith('-')).toList();
    final path = positional.isNotEmpty ? positional[0] : null;

    try {
      final result =
          await _api.takeScreenshot(path: path, toClipboard: toClipboard);

      if (result == null) {
        stderr.writeln('Error: No screenshot tool available on this platform');
        return 1;
      }

      printFormatted(
        {'success': true, 'path': result, 'clipboard': toClipboard},
        json: jsonOutput,
        xml: xmlOutput,
        xmlRoot: 'screenshot',
        plain: (_) => toClipboard
            ? 'Screenshot copied to clipboard'
            : 'Screenshot saved to $result',
      );
      return 0;
    } catch (e) {
      stderr.writeln('Error: Failed to take screenshot: $e');
      return 1;
    }
  }

  void _printUsage() {
    print('''
Usage: crossbar screenshot [path] [options]

Take a screenshot and save to file or copy to clipboard.

Options:
  [path]              Save screenshot to specific path (default: ~/screenshot_<timestamp>.png)
  --clipboard, -c     Copy screenshot to clipboard instead of saving
  --json              Output in JSON format
  --xml               Output in XML format

Examples:
  crossbar screenshot
  crossbar screenshot /tmp/my-screenshot.png
  crossbar screenshot --clipboard
  crossbar screenshot --json
''');
  }
}
