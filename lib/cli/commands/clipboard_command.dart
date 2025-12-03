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

    if (values.isEmpty) {
      // Get
      if (Platform.isLinux) {
        final result = await Process.run('xclip', ['-selection', 'clipboard', '-o']);
        print(result.stdout);
      } else if (Platform.isMacOS) {
        final result = await Process.run('pbpaste', []);
        print(result.stdout);
      } else if (Platform.isWindows) {
        final result = await Process.run('powershell', ['-command', 'Get-Clipboard']);
        print(result.stdout);
      }
    } else {
      // Set
      final content = values[0];

      if (Platform.isLinux) {
        final process = await Process.start('xclip', ['-selection', 'clipboard']);
        process.stdin.write(content);
        await process.stdin.close();
        print('Copied to clipboard');
      } else if (Platform.isMacOS) {
        final process = await Process.start('pbcopy', []);
        process.stdin.write(content);
        await process.stdin.close();
        print('Copied to clipboard');
      } else if (Platform.isWindows) {
        await Process.run('powershell', ['-command', 'Set-Clipboard -Value "$content"']);
        print('Copied to clipboard');
      }
    }
    return 0;
  }
}
