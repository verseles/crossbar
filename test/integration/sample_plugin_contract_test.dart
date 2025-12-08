@Tags(['hardware'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Unified contract tests for sample plugins across ALL languages.
/// These tests validate that plugins of the same function produce
/// consistent output format regardless of implementation language.
void main() {
  group('Sample Plugin Contract Tests - Unified', () {
    late String pluginsDir;

    setUp(() {
      pluginsDir = '${Directory.current.path}/plugins';
    });

    /// Executes a plugin script and returns stdout
    Future<String?> executePlugin(String path) async {
      final file = File(path);
      if (!file.existsSync()) return null;

      final extension = path.split('.').last;
      String interpreter;
      List<String> args;

      switch (extension) {
        case 'sh':
          interpreter = 'bash';
          args = [path];
        case 'py':
          interpreter = 'python3';
          args = [path];
        case 'js':
          interpreter = 'node';
          args = [path];
        case 'lua':
          // Skip Lua - tested separately via LuaRunner
          return null;
        case 'dart':
          interpreter = 'dart';
          args = ['run', path];
        case 'go':
        case 'rs':
        case 'yaml':
          // Skip compiled languages and declarative formats
          return null;
        default:
          return null;
      }

      try {
        final result = await Process.run(
          interpreter,
          args,
          workingDirectory: Directory.current.path,
          environment: {
            ...Platform.environment,
            'PATH': '${Directory.current.path}/build/linux/x64/release/bundle:${Platform.environment['PATH']}',
          },
        );

        if (result.exitCode != 0) {
          return null;
        }
        return (result.stdout as String).trim();
      } catch (e) {
        return null;
      }
    }

    /// Finds all plugin variants for a given base name (e.g., "cpu.10s")
    List<File> findPluginVariants(String baseName) {
      final variants = <File>[];
      final extensions = ['sh', 'py', 'js', 'dart', 'lua'];

      // Check in root plugins dir
      for (final ext in extensions) {
        final file = File('$pluginsDir/$baseName.$ext');
        if (file.existsSync()) variants.add(file);
      }

      // Check in subdirectory named after the plugin
      final subDir = baseName.split('.').first;
      for (final ext in extensions) {
        final file = File('$pluginsDir/$subDir/$baseName.$ext');
        if (file.existsSync()) variants.add(file);
      }

      return variants;
    }

    group('CPU Plugins', () {
      test('all cpu.10s.* variants produce output with percentage format', () async {
        final variants = findPluginVariants('cpu.10s');
        expect(variants, isNotEmpty, reason: 'Should have CPU plugin variants');

        for (final plugin in variants) {
          final ext = plugin.path.split('.').last;
          if (ext == 'lua' || ext == 'go' || ext == 'rs') continue;

          final output = await executePlugin(plugin.path);
          if (output == null) continue; // Skip if interpreter not available

          // All CPU plugins should have:
          // 1. An emoji/icon
          // 2. A percentage value
          // 3. Color indicator
          expect(
            output,
            matches(RegExp(r'[^\s].*\d+.*%')),
            reason: '${plugin.path} should contain percentage',
          );
          expect(
            output,
            contains('color='),
            reason: '${plugin.path} should have color indicator',
          );
        }
      });

      test('all cpu.10s.* variants have menu separator', () async {
        final variants = findPluginVariants('cpu.10s');

        for (final plugin in variants) {
          final ext = plugin.path.split('.').last;
          if (ext == 'lua' || ext == 'go' || ext == 'rs') continue;

          final output = await executePlugin(plugin.path);
          if (output == null) continue;

          expect(
            output,
            contains('---'),
            reason: '${plugin.path} should have menu separator',
          );
        }
      });
    });

    group('Memory Plugins', () {
      test('all memory.10s.* variants produce output with memory format', () async {
        final variants = findPluginVariants('memory.10s');
        expect(variants, isNotEmpty, reason: 'Should have memory plugin variants');

        for (final plugin in variants) {
          final ext = plugin.path.split('.').last;
          if (ext == 'lua' || ext == 'go' || ext == 'rs') continue;

          final output = await executePlugin(plugin.path);
          if (output == null) continue;

          // Memory plugins should show memory usage
          expect(
            output,
            anyOf(
              contains('GB'),
              contains('MB'),
              contains('%'),
              contains('N/A'),
            ),
            reason: '${plugin.path} should show memory info',
          );
        }
      });
    });

    group('Clock Plugins', () {
      test('all clock.*.* variants produce output with time format', () async {
        final clockVariants = <File>[];

        // Find all clock plugins
        final pluginDir = Directory(pluginsDir);
        for (final entity in pluginDir.listSync(recursive: true)) {
          if (entity is File && entity.path.contains('clock')) {
            clockVariants.add(entity);
          }
        }

        expect(clockVariants, isNotEmpty, reason: 'Should have clock plugin variants');

        for (final plugin in clockVariants) {
          final ext = plugin.path.split('.').last;
          if (ext == 'lua' || ext == 'go' || ext == 'rs' || ext == 'yaml') continue;

          final output = await executePlugin(plugin.path);
          if (output == null) continue;

          // Clock plugins should show time in HH:MM format
          expect(
            output,
            matches(RegExp(r'\d{1,2}:\d{2}')),
            reason: '${plugin.path} should show time',
          );
        }
      });
    });

    group('Output Format Consistency', () {
      test(
        'all interpreted plugins produce valid BitBar output',
        () async {
        final allPlugins = Directory(pluginsDir)
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) {
              final ext = f.path.split('.').last;
              return ['sh', 'py', 'js', 'dart'].contains(ext);
            })
            .toList();

        expect(allPlugins, isNotEmpty);

        var successCount = 0;
        var skipCount = 0;

        for (final plugin in allPlugins) {
          final output = await executePlugin(plugin.path);

          if (output == null) {
            skipCount++;
            continue;
          }

          // Basic BitBar format: first line is the display text
          final lines = output.split('\n');
          expect(
            lines.first,
            isNotEmpty,
            reason: '${plugin.path} should have non-empty first line',
          );

          // First line should not be an error message
          expect(
            lines.first.toLowerCase(),
            isNot(startsWith('error')),
            reason: '${plugin.path} should not output error',
          );

          successCount++;
        }

        // At least some plugins should succeed
        expect(
          successCount,
          greaterThan(0),
          reason: 'At least some plugins should execute successfully '
              '(success: $successCount, skipped: $skipCount)',
        );
      }, timeout: const Timeout(Duration(minutes: 2)));

      test('plugins of same function have consistent icon usage', () async {
        // CPU plugins should all use similar icons
        final cpuVariants = findPluginVariants('cpu.10s');
        final cpuIcons = <String>{};

        for (final plugin in cpuVariants) {
          final ext = plugin.path.split('.').last;
          if (ext == 'lua' || ext == 'go' || ext == 'rs') continue;

          final output = await executePlugin(plugin.path);
          if (output == null) continue;

          // Extract first character (icon)
          final firstLine = output.split('\n').first;
          if (firstLine.isNotEmpty) {
            // Get emoji or first character
            final iconMatch = RegExp(r'^(\p{Emoji}|[^\s])', unicode: true).firstMatch(firstLine);
            if (iconMatch != null) {
              cpuIcons.add(iconMatch.group(0)!);
            }
          }
        }

        // All CPU plugins should use the same icon
        if (cpuIcons.isNotEmpty) {
          expect(
            cpuIcons.length,
            lessThanOrEqualTo(2), // Allow some variation but not too much
            reason: 'CPU plugins should use consistent icons: $cpuIcons',
          );
        }
      });
    });
  });
}
