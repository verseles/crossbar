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

    final result = await Process.run(
      Platform.isWindows ? 'cmd' : 'sh',
      Platform.isWindows ? ['/c', cmd] : ['-c', cmd],
    );
    stdout.write(result.stdout);
    stderr.write(result.stderr);
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
    String priority = 'normal';

    for (var i = 0; i < args.length; i++) {
      if (args[i] == '--icon' && i + 1 < args.length) icon = args[i + 1];
      if (args[i] == '--priority' && i + 1 < args.length) priority = args[i + 1];
    }

    const api = UtilsApi();
    final result = await api.sendNotification(
      title: title,
      message: message,
      icon: icon,
      priority: priority,
    );
    print(result ? 'Notification sent' : 'Failed to send notification');
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

    if (values.isEmpty) {
      stderr.writeln('Error: open $subcommand requires a value');
      return 1;
    }
    final target = values[0];
    const api = UtilsApi();

    switch (subcommand) {
      case 'url':
        final result = await api.openUrl(target);
        print(result ? 'Opened: $target' : 'Failed to open URL');
        return result ? 0 : 1;
      case 'file':
        final result = await api.openFile(target);
        print(result ? 'Opened: $target' : 'Failed to open file');
        return result ? 0 : 1;
      case 'app':
        final result = await api.openApp(target);
        print(result ? 'Launched: $target' : 'Failed to launch app');
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
    String fmt = '24h';
    for (var i = 0; i < args.length; i++) {
      if (args[i] == '--fmt' && i + 1 < args.length) fmt = args[i + 1];
    }

    final now = DateTime.now();
    if (fmt == '12h') {
      final hour = now.hour > 12 ? now.hour - 12 : now.hour;
      final period = now.hour >= 12 ? 'PM' : 'AM';
      print('${hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} $period');
    } else {
      print('${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}');
    }
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
    String fmt = 'iso';
    for (var i = 0; i < args.length; i++) {
      if (args[i] == '--fmt' && i + 1 < args.length) fmt = args[i + 1];
    }

    final now = DateTime.now();
    switch (fmt) {
      case 'iso':
        print(now.toIso8601String().split('T')[0]);
      case 'us':
        print('${now.month}/${now.day}/${now.year}');
      case 'eu':
        print('${now.day}/${now.month}/${now.year}');
      case 'unix':
        print(now.millisecondsSinceEpoch ~/ 1000);
      default:
        print(now.toIso8601String().split('T')[0]);
    }
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

    String algo = 'sha256';
    for (var i = 0; i < args.length; i++) {
      if (args[i] == '--algo' && i + 1 < args.length) algo = args[i + 1];
    }

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
    print(result);
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
    final now = DateTime.now().microsecondsSinceEpoch;
    final random = now.hashCode;

    final hex = StringBuffer();
    for (var i = 0; i < 32; i++) {
      final value = ((now >> (i * 2)) ^ (random >> i)) & 0xF;
      hex.write(value.toRadixString(16));
    }

    final uuid = hex.toString();
    print('${uuid.substring(0, 8)}-${uuid.substring(8, 12)}-4${uuid.substring(13, 16)}-${uuid.substring(16, 20)}-${uuid.substring(20, 32)}');
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

    final random = min + (DateTime.now().microsecond % (max - min + 1));
    print(random);
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

    if (values.isEmpty) {
      stderr.writeln('Error: base64 requires text');
      return 1;
    }
    final text = values[0];

    if (subcommand == 'encode') {
      print(base64Encode(utf8.encode(text)));
    } else if (subcommand == 'decode') {
      try {
        print(utf8.decode(base64Decode(text)));
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
