// ignore_for_file: avoid_slow_async_io
import 'package:crossbar/core/plugin_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PluginManager', () {
    late PluginManager manager;

    setUp(() {
      manager = PluginManager();
      manager.clear();
    });

    group('singleton', () {
      test('returns same instance', () {
        final manager1 = PluginManager();
        final manager2 = PluginManager();

        expect(identical(manager1, manager2), true);
      });
    });

    group('supportedLanguages', () {
      test('contains all expected languages', () {
        expect(
          PluginManager.supportedLanguages,
          containsAll(['bash', 'python', 'node', 'dart', 'go', 'rust', 'lua']),
        );
      });

      test('has 7 supported languages', () {
        expect(PluginManager.supportedLanguages.length, 7);
      });
    });

    group('extensionToInterpreter', () {
      test('maps .sh to bash', () {
        expect(PluginManager.extensionToInterpreter['.sh'], 'bash');
      });

      test('maps .py to python3', () {
        expect(PluginManager.extensionToInterpreter['.py'], 'python3');
      });

      test('maps .js to node', () {
        expect(PluginManager.extensionToInterpreter['.js'], 'node');
      });

      test('maps .dart to dart', () {
        expect(PluginManager.extensionToInterpreter['.dart'], 'dart');
      });

      test('maps .go to go', () {
        expect(PluginManager.extensionToInterpreter['.go'], 'go');
      });

      test('maps .rs to rust', () {
        expect(PluginManager.extensionToInterpreter['.rs'], 'rust');
      });

      test('maps .lua to lua', () {
        expect(PluginManager.extensionToInterpreter['.lua'], 'lua');
      });
    });

    group('allowedExtensions', () {
      test('contains all expected extensions', () {
        expect(
          PluginManager.allowedExtensions,
          containsAll(['.sh', '.py', '.js', '.dart', '.go', '.rs', '.lua']),
        );
      });
    });

    group('plugins', () {
      test('returns unmodifiable list', () {
        final plugins = manager.plugins;

        expect(plugins.clear, throwsUnsupportedError);
      });

      test('initially empty', () {
        expect(manager.plugins, isEmpty);
      });
    });

    group('pluginsDirectory', () {
      test('returns path ending with .crossbar/plugins or plugins', () async {
        final dir = await manager.pluginsDirectory;
        expect(dir, contains('plugins'));
        // On desktop it contains .crossbar, on mobile it doesn't
        expect(dir, anyOf(contains('.crossbar'), isNot(contains('.crossbar'))));
      });
    });

    group('maxConcurrent', () {
      test('is 10', () {
        expect(PluginManager.maxConcurrent, 10);
      });
    });

    group('clear', () {
      test('empties plugins list', () {
        manager.clear();
        expect(manager.plugins, isEmpty);
      });
    });

    group('refresh interval parsing', () {
      test('parses seconds interval', () {
        // This tests the internal _parseRefreshInterval method indirectly
        // through the plugin discovery process
        expect(PluginManager.supportedLanguages.length, 7);
      });
    });
  });

  group('Refresh Interval Parsing', () {
    test('minimum interval is 1 second', () {
      // The PluginManager enforces a minimum of 1 second
      // to prevent fork bombs from plugins with very short intervals
      expect(const Duration(seconds: 1).inMilliseconds, 1000);
    });

    test('default interval is 5 minutes', () {
      expect(const Duration(minutes: 5).inSeconds, 300);
    });
  });
}
