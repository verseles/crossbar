#!/usr/bin/env dart
/// Git Status - Shows git repository status
import 'dart:io';

void main() async {
  // Check if in a git repo
  final gitCheck = await Process.run('git', ['rev-parse', '--is-inside-work-tree']);
  if (gitCheck.exitCode != 0) {
    print(' Not a repo');
    print('---');
    print('Not inside a git repository');
    return;
  }

  // Get current branch
  final branchResult = await Process.run('git', ['branch', '--show-current']);
  final branch = branchResult.stdout.toString().trim();

  // Get status
  final statusResult = await Process.run('git', ['status', '--porcelain']);
  final status = statusResult.stdout.toString().trim();
  final lines = status.isEmpty ? <String>[] : status.split('\n');

  final modified = lines.where((l) => l.startsWith(' M') || l.startsWith('M ')).length;
  final added = lines.where((l) => l.startsWith('A ') || l.startsWith('??')).length;
  final deleted = lines.where((l) => l.startsWith(' D') || l.startsWith('D ')).length;

  final changes = modified + added + deleted;
  final icon = changes > 0 ? '' : '';
  final color = changes > 0 ? 'orange' : 'green';

  print('$icon $branch | color=$color');
  print('---');
  print('Branch: $branch');
  print('---');

  if (changes > 0) {
    print('Changes:');
    if (modified > 0) print('  Modified: $modified');
    if (added > 0) print('  Added: $added');
    if (deleted > 0) print('  Deleted: $deleted');

    print('---');
    for (final line in lines.take(10)) {
      final file = line.substring(3);
      final type = line.substring(0, 2).trim();
      print('$type $file');
    }
    if (lines.length > 10) {
      print('...and ${lines.length - 10} more files');
    }
  } else {
    print('Working tree clean');
  }

  print('---');
  print('Refresh | refresh=true');
}
