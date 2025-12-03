import 'dart:io';

import 'base_command.dart';

class ClipboardCommand extends CliCommand {
  @override
  String get name => 'clipboard';

  @override
  String get description => 'Get or set clipboard content';

  @override
  Future<int> execute(List<String> args) async {
    final values = args.where((a) => !a.startsWith('--')).toList();
    final jsonOutput = args.contains('--json');
    final xmlOutput = args.contains('--xml');

    if (values.isEmpty) {
      // Get
      String content = '';
      if (Platform.isLinux) {
        final result = await Process.run('xclip', ['-selection', 'clipboard', '-o']);
        content = result.stdout as String;
      } else if (Platform.isMacOS) {
        final result = await Process.run('pbpaste', []);
        content = result.stdout as String;
      } else if (Platform.isWindows) {
        final result = await Process.run('powershell', ['-command', 'Get-Clipboard']);
        content = result.stdout as String;
      }

      printFormatted(
          {'content': content},
          json: jsonOutput,
          xml: xmlOutput,
          plain: (_) => content
      );

    } else {
      // Set
      final content = values[0];

      if (Platform.isLinux) {
        final process = await Process.start('xclip', ['-selection', 'clipboard']);
        process.stdin.write(content);
        await process.stdin.close();
      } else if (Platform.isMacOS) {
        final process = await Process.start('pbcopy', []);
        process.stdin.write(content);
        await process.stdin.close();
      } else if (Platform.isWindows) {
        await Process.run('powershell', ['-command', 'Set-Clipboard -Value "$content"']);
      }

      printFormatted(
          {'success': true, 'action': 'copy'},
          json: jsonOutput,
          xml: xmlOutput,
          plain: (_) => 'Copied to clipboard'
      );
    }
    return 0;
  }
}
