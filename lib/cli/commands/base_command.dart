// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import '../cli_utils.dart';

/// Abstract base class for CLI commands
abstract class CliCommand {
  /// The command name (e.g., 'audio', 'cpu')
  String get name;

  /// Short description for help output
  String get description;

  /// Executes the command with the given arguments
  /// Returns the exit code (0 for success)
  Future<int> execute(List<String> args);

  /// Helper to print formatted output (JSON, XML, or Plain)
  void printFormatted(
    dynamic data, {
    required bool json,
    required bool xml,
    String Function(dynamic)? plain,
    String xmlRoot = 'crossbar',
  }) {
    if (json) {
      print(jsonEncode(data));
    } else if (xml) {
      Map<String, dynamic> mapData;
      if (data is Map<String, dynamic>) {
        mapData = data;
      } else if (data is List) {
        mapData = {'item': data};
      } else {
        mapData = {'value': data};
      }
      print(mapToXml(mapData, root: xmlRoot));
    } else {
      if (plain != null) {
        print(plain(data));
      } else {
        print(data.toString());
      }
    }
  }
}
