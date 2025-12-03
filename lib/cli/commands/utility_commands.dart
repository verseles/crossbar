import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import '../../core/api/utils_api.dart';
import 'base_command.dart';

class ExecCommand extends CliCommand {
  @override
  String get name => 'exec';

  @override
  String get description => 'Execute shell command';

  @override
  Future<int> execute(List<String> args) async {
    final values = args.where((a) => !a.startsWith('--')).toList();
    if (values.isEmpty) {
      stderr.writeln('Error: exec requires command');
      return 1;
    }

    final cmd = values.join(' ');
    final jsonOutput = args.contains('--json');
    final xmlOutput = args.contains('--xml');

    final result = await Process.run(
      Platform.isWindows ? 'cmd' : 'sh',
      Platform.isWindows ? ['/c', cmd] : ['-c', cmd],
    );

    if (jsonOutput || xmlOutput) {
        printFormatted(
            {
                'stdout': result.stdout.toString(),
                'stderr': result.stderr.toString(),
                'exitCode': result.exitCode
            },
            json: jsonOutput,
            xml: xmlOutput,
            plain: (_) => '' // Should not be reached logic-wise if I used separate check, but here we want to suppress standard output if json/xml
        );
    } else {
        stdout.write(result.stdout);
        stderr.write(result.stderr);
    }
    return result.exitCode;
  }
}

class NotifyCommand extends CliCommand {
  @override
  String get name => 'notify';

  @override
  String get description => 'Send desktop notification';

  @override
  Future<int> execute(List<String> args) async {
    String? title;
    String? message;

    final values = args.where((a) => !a.startsWith('--')).toList();
    if (values.length >= 2) {
      title = values[0];
      message = values[1];
    } else {
      stderr.writeln('Error: notify requires title and message');
      return 1;
    }

    String? icon;
    var priority = 'normal';

    for (var i = 0; i < args.length; i++) {
      if (args[i] == '--icon' && i + 1 < args.length) icon = args[i + 1];
      if (args[i] == '--priority' && i + 1 < args.length) priority = args[i + 1];
    }

    final jsonOutput = args.contains('--json');
    final xmlOutput = args.contains('--xml');

    const api = UtilsApi();
    final result = await api.sendNotification(
      title: title,
      message: message,
      icon: icon,
      priority: priority,
    );

    printFormatted(
        {'success': result, 'action': 'notify'},
        json: jsonOutput,
        xml: xmlOutput,
        plain: (_) => result ? 'Notification sent' : 'Failed to send notification'
    );
    return result ? 0 : 1;
  }
}

class OpenCommand extends CliCommand {
  @override
  String get name => 'open';

  @override
  String get description => 'Open URL, file, or application';

  @override
  Future<int> execute(List<String> args) async {
    if (args.isEmpty) {
      stderr.writeln('Error: open requires subcommand (url, file, app)');
      return 1;
    }

    final subcommand = args[0];
    final values = args.sublist(1).where((a) => !a.startsWith('--')).toList();
    final jsonOutput = args.contains('--json');
    final xmlOutput = args.contains('--xml');

    if (values.isEmpty) {
      stderr.writeln('Error: open $subcommand requires a value');
      return 1;
    }
    final target = values[0];
    const api = UtilsApi();

    switch (subcommand) {
      case 'url':
        final result = await api.openUrl(target);
        printFormatted(
            {'success': result, 'action': 'open-url', 'target': target},
            json: jsonOutput, xml: xmlOutput,
            plain: (_) => result ? 'Opened: $target' : 'Failed to open URL'
        );
        return result ? 0 : 1;
      case 'file':
        final result = await api.openFile(target);
        printFormatted(
            {'success': result, 'action': 'open-file', 'target': target},
            json: jsonOutput, xml: xmlOutput,
            plain: (_) => result ? 'Opened: $target' : 'Failed to open file'
        );
        return result ? 0 : 1;
      case 'app':
        final result = await api.openApp(target);
        printFormatted(
            {'success': result, 'action': 'open-app', 'target': target},
            json: jsonOutput, xml: xmlOutput,
            plain: (_) => result ? 'Launched: $target' : 'Failed to launch app'
        );
        return result ? 0 : 1;
      default:
        stderr.writeln('Error: Unknown open subcommand: $subcommand');
        return 1;
    }
  }
}

class TimeCommand extends CliCommand {
  @override
  String get name => 'time';

  @override
  String get description => 'Current time';

  @override
  Future<int> execute(List<String> args) async {
    var fmt = '24h';
    for (var i = 0; i < args.length; i++) {
      if (args[i] == '--fmt' && i + 1 < args.length) fmt = args[i + 1];
    }
    final jsonOutput = args.contains('--json');
    final xmlOutput = args.contains('--xml');

    final now = DateTime.now();
    String result;

    if (fmt == '12h') {
      final hour = now.hour > 12 ? now.hour - 12 : now.hour;
      final period = now.hour >= 12 ? 'PM' : 'AM';
      result = '${hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} $period';
    } else {
      result = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    }

    printFormatted(
        {'time': result, 'fmt': fmt},
        json: jsonOutput, xml: xmlOutput,
        plain: (_) => result
    );
    return 0;
  }
}

class DateCommand extends CliCommand {
  @override
  String get name => 'date';

  @override
  String get description => 'Current date';

  @override
  Future<int> execute(List<String> args) async {
    var fmt = 'iso';
    for (var i = 0; i < args.length; i++) {
      if (args[i] == '--fmt' && i + 1 < args.length) fmt = args[i + 1];
    }
    final jsonOutput = args.contains('--json');
    final xmlOutput = args.contains('--xml');

    final now = DateTime.now();
    dynamic result;

    switch (fmt) {
      case 'iso':
        result = now.toIso8601String().split('T')[0];
      case 'us':
        result = '${now.month}/${now.day}/${now.year}';
      case 'eu':
        result = '${now.day}/${now.month}/${now.year}';
      case 'unix':
        result = now.millisecondsSinceEpoch ~/ 1000;
      default:
        result = now.toIso8601String().split('T')[0];
    }

    printFormatted(
        {'date': result, 'fmt': fmt},
        json: jsonOutput, xml: xmlOutput,
        plain: (_) => result.toString()
    );
    return 0;
  }
}

class HashCommand extends CliCommand {
  @override
  String get name => 'hash';

  @override
  String get description => 'Hash text';

  @override
  Future<int> execute(List<String> args) async {
    final values = args.where((a) => !a.startsWith('--')).toList();
    if (values.isEmpty) {
      stderr.writeln('Error: hash requires text');
      return 1;
    }

    var algo = 'sha256';
    for (var i = 0; i < args.length; i++) {
      if (args[i] == '--algo' && i + 1 < args.length) algo = args[i + 1];
    }
    final jsonOutput = args.contains('--json');
    final xmlOutput = args.contains('--xml');

    final text = values[0];
    final bytes = utf8.encode(text);
    String result;

    switch (algo.toLowerCase()) {
      case 'md5':
        result = crypto.md5.convert(bytes).toString();
      case 'sha1':
        result = crypto.sha1.convert(bytes).toString();
      case 'sha384':
        result = crypto.sha384.convert(bytes).toString();
      case 'sha512':
        result = crypto.sha512.convert(bytes).toString();
      case 'sha256':
      default:
        result = crypto.sha256.convert(bytes).toString();
    }

    printFormatted(
        {'hash': result, 'algo': algo},
        json: jsonOutput, xml: xmlOutput,
        plain: (_) => result
    );
    return 0;
  }
}

class UuidCommand extends CliCommand {
  @override
  String get name => 'uuid';

  @override
  String get description => 'Generate UUID';

  @override
  Future<int> execute(List<String> args) async {
    final jsonOutput = args.contains('--json');
    final xmlOutput = args.contains('--xml');

    final now = DateTime.now().microsecondsSinceEpoch;
    final random = now.hashCode;

    final hex = StringBuffer();
    for (var i = 0; i < 32; i++) {
      final value = ((now >> (i * 2)) ^ (random >> i)) & 0xF;
      hex.write(value.toRadixString(16));
    }

    final uuidRaw = hex.toString();
    final result = '${uuidRaw.substring(0, 8)}-${uuidRaw.substring(8, 12)}-4${uuidRaw.substring(13, 16)}-${uuidRaw.substring(16, 20)}-${uuidRaw.substring(20, 32)}';

    printFormatted(
        {'uuid': result},
        json: jsonOutput, xml: xmlOutput,
        plain: (_) => result
    );
    return 0;
  }
}

class RandomCommand extends CliCommand {
  @override
  String get name => 'random';

  @override
  String get description => 'Generate random number';

  @override
  Future<int> execute(List<String> args) async {
    final values = args.where((a) => !a.startsWith('--')).toList();
    final min = values.isNotEmpty ? int.tryParse(values[0]) ?? 0 : 0;
    final max = values.length > 1 ? int.tryParse(values[1]) ?? 100 : 100;
    final jsonOutput = args.contains('--json');
    final xmlOutput = args.contains('--xml');

    final result = min + (DateTime.now().microsecond % (max - min + 1));

    printFormatted(
        {'random': result, 'min': min, 'max': max},
        json: jsonOutput, xml: xmlOutput,
        plain: (_) => result.toString()
    );
    return 0;
  }
}

class Base64Command extends CliCommand {
  @override
  String get name => 'base64';

  @override
  String get description => 'Base64 encode/decode';

  @override
  Future<int> execute(List<String> args) async {
    if (args.isEmpty) {
      stderr.writeln('Error: base64 requires subcommand (encode, decode)');
      return 1;
    }
    final subcommand = args[0];
    final values = args.sublist(1).where((a) => !a.startsWith('--')).toList();
    final jsonOutput = args.contains('--json');
    final xmlOutput = args.contains('--xml');

    if (values.isEmpty) {
      stderr.writeln('Error: base64 requires text');
      return 1;
    }
    final text = values[0];

    if (subcommand == 'encode') {
      final result = base64Encode(utf8.encode(text));
      printFormatted(
          {'encoded': result},
          json: jsonOutput, xml: xmlOutput,
          plain: (_) => result
      );
    } else if (subcommand == 'decode') {
      try {
        final result = utf8.decode(base64Decode(text));
        printFormatted(
            {'decoded': result},
            json: jsonOutput, xml: xmlOutput,
            plain: (_) => result
        );
      } catch (e) {
        stderr.writeln('Error decoding base64: $e');
        return 1;
      }
    } else {
       stderr.writeln('Error: Unknown base64 subcommand: $subcommand');
       return 1;
    }
    return 0;
  }
}
