import 'dart:io';

import 'package:crossbar/cli/cli_handler.dart';

/// CLI entry point for Crossbar
/// This file is kept for backwards compatibility with `dart run bin/crossbar.dart`.
/// The main executable now supports both GUI and CLI modes natively.
void main(List<String> args) async {
  final exitCode = await handleCliCommand(args);
  exit(exitCode);
}
