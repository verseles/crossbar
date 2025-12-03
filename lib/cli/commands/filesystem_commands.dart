import 'dart:convert';
import 'dart:io';

import 'base_command.dart';

class FileCommand extends CliCommand {
  @override
  String get name => 'file';

  @override
  String get description => 'File operations (exists, read, size)';

  @override
  Future<int> execute(List<String> args) async {
    if (args.isEmpty) {
      stderr.writeln('Error: file command requires a subcommand (exists, read, size)');
      return 1;
    }

    final subcommand = args[0];
    final commandArgs = args.sublist(1);
    final jsonOutput = args.contains('--json');
    final values = commandArgs.where((a) => !a.startsWith('--')).toList();

    if (values.isEmpty) {
      stderr.writeln('Error: file $subcommand requires a path');
      return 1;
    }
    final path = values[0];

    switch (subcommand) {
      case 'exists':
        final exists = File(path).existsSync() || Directory(path).existsSync();
        if (jsonOutput) {
          print(jsonEncode({'exists': exists, 'path': path}));
        } else {
          print(exists ? 'true' : 'false');
        }
        return 0;

      case 'read':
        final file = File(path);
        if (!file.existsSync()) {
          stderr.writeln('Error: File not found: $path');
          return 1;
        }
        print(file.readAsStringSync());
        return 0;

      case 'size':
        final file = File(path);
        if (!file.existsSync()) {
          stderr.writeln('Error: File not found: $path');
          return 1;
        }
        final size = file.lengthSync();
        if (jsonOutput) {
          print(jsonEncode({'size': size, 'path': path}));
        } else {
          if (size < 1024) {
            print('$size B');
          } else if (size < 1024 * 1024) {
            print('${(size / 1024).toStringAsFixed(2)} KB');
          } else if (size < 1024 * 1024 * 1024) {
            print('${(size / (1024 * 1024)).toStringAsFixed(2)} MB');
          } else {
            print('${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB');
          }
        }
        return 0;

      default:
        stderr.writeln('Error: Unknown file subcommand: $subcommand');
        return 1;
    }
  }
}

class DirCommand extends CliCommand {
  @override
  String get name => 'dir';

  @override
  String get description => 'Directory operations (list)';

  @override
  Future<int> execute(List<String> args) async {
    if (args.isEmpty) {
      stderr.writeln('Error: dir command requires a subcommand (list)');
      return 1;
    }

    final subcommand = args[0];
    final commandArgs = args.sublist(1);
    final jsonOutput = args.contains('--json');
    final values = commandArgs.where((a) => !a.startsWith('--')).toList();
    final path = values.isNotEmpty ? values[0] : '.';

    if (subcommand == 'list') {
      final dir = Directory(path);
      if (!dir.existsSync()) {
        stderr.writeln('Error: Directory not found: $path');
        return 1;
      }
      final entries = dir.listSync();
      if (jsonOutput) {
        final files = entries.map((e) {
          final stat = e.statSync();
          return {
            'name': e.path.split(Platform.pathSeparator).last,
            'path': e.path,
            'type': e is File ? 'file' : 'directory',
            'size': stat.size,
            'modified': stat.modified.toIso8601String(),
          };
        }).toList();
        print(jsonEncode(files));
      } else {
        for (final entry in entries) {
          final name = entry.path.split(Platform.pathSeparator).last;
          final prefix = entry is Directory ? 'd' : '-';
          print('$prefix $name');
        }
      }
      return 0;
    } else {
      stderr.writeln('Error: Unknown dir subcommand: $subcommand');
      return 1;
    }
  }
}
