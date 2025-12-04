import 'package:crossbar/utils/logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Logger', () {
    test('is singleton', () {
      final logger1 = Logger();
      final logger2 = Logger();

      expect(identical(logger1, logger2), true);
    });

    test('has default minLevel of info', () {
      final logger = Logger();

      expect(logger.minLevel, LogLevel.info);
    });

    test('can set minLevel', () {
      final logger = Logger();

      logger.minLevel = LogLevel.debug;
      expect(logger.minLevel, LogLevel.debug);

      logger.minLevel = LogLevel.error;
      expect(logger.minLevel, LogLevel.error);

      // Reset to default
      logger.minLevel = LogLevel.info;
    });
  });

  group('LogLevel', () {
    test('has correct order', () {
      expect(LogLevel.debug.index, lessThan(LogLevel.info.index));
      expect(LogLevel.info.index, lessThan(LogLevel.warning.index));
      expect(LogLevel.warning.index, lessThan(LogLevel.error.index));
    });

    test('has all expected values', () {
      expect(LogLevel.values, contains(LogLevel.debug));
      expect(LogLevel.values, contains(LogLevel.info));
      expect(LogLevel.values, contains(LogLevel.warning));
      expect(LogLevel.values, contains(LogLevel.error));
    });

    test('has 4 levels', () {
      expect(LogLevel.values.length, 4);
    });
  });
}
