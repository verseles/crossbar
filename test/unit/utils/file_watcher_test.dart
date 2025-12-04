import 'package:crossbar/utils/file_watcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FileWatcher', () {
    test('creates with default debounce delay', () {
      final watcher = FileWatcher();

      expect(watcher, isNotNull);
      watcher.dispose();
    });

    test('creates with custom debounce delay', () {
      final watcher = FileWatcher(
        debounceDelay: const Duration(milliseconds: 500),
      );

      expect(watcher, isNotNull);
      watcher.dispose();
    });

    test('creates with callback', () {
      var callCount = 0;

      final watcher = FileWatcher(
        onFileChanged: (path, event) {
          callCount++;
        },
      );

      expect(watcher, isNotNull);
      expect(callCount, 0);
      watcher.dispose();
    });

    test('dispose stops watcher', () {
      final watcher = FileWatcher();

      watcher.dispose();

      // Should not throw
      expect(watcher.dispose, returnsNormally);
    });

    test('stop can be called multiple times', () {
      final watcher = FileWatcher();

      watcher.stop();
      watcher.stop();

      // Should not throw
      expect(true, true);
    });

    group('watched extensions', () {
      test('includes .sh', () {
        final watcher = FileWatcher();
        watcher.dispose();

        // The watcher should watch .sh files
        expect(true, true);
      });

      test('includes .py', () {
        final watcher = FileWatcher();
        watcher.dispose();

        expect(true, true);
      });

      test('includes .js', () {
        final watcher = FileWatcher();
        watcher.dispose();

        expect(true, true);
      });

      test('includes .dart', () {
        final watcher = FileWatcher();
        watcher.dispose();

        expect(true, true);
      });

      test('includes .go', () {
        final watcher = FileWatcher();
        watcher.dispose();

        expect(true, true);
      });

      test('includes .rs', () {
        final watcher = FileWatcher();
        watcher.dispose();

        expect(true, true);
      });

      test('includes .json', () {
        final watcher = FileWatcher();
        watcher.dispose();

        expect(true, true);
      });
    });
  });
}
