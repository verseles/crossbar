import 'dart:io';

import 'package:path/path.dart' as path;

/// Reads fixture files from test/fixtures/ directory.
///
/// Usage:
///   final json = fixture('sample_output.json');
///   final yaml = fixture('plugin_config.yaml');
String fixture(String name) {
  final dir = _findFixtureDir();
  final file = File(path.join(dir, name));
  if (!file.existsSync()) {
    throw FileSystemException('Fixture not found: $name', file.path);
  }
  return file.readAsStringSync();
}

/// Returns the fixture directory path.
String _findFixtureDir() {
  // Try common locations relative to test runner working directory
  for (final candidate in [
    'test/fixtures',
    'test/functional/fixtures',
    '../test/fixtures',
  ]) {
    if (Directory(candidate).existsSync()) {
      return candidate;
    }
  }
  // Fallback: search upward from current directory
  var dir = Directory.current;
  while (dir.parent.path != dir.path) {
    final fixtures = Directory(path.join(dir.path, 'test', 'fixtures'));
    if (fixtures.existsSync()) {
      return fixtures.path;
    }
    dir = dir.parent;
  }
  return 'test/fixtures';
}
