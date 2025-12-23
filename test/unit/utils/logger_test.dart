// ignore_for_file: avoid_slow_async_io
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

  group('Logger logging methods', () {
    late Logger logger;

    setUp(() {
      logger = Logger();
      // Reset to default level
      logger.minLevel = LogLevel.info;
    });

    test('debug method does not throw', () {
      logger.minLevel = LogLevel.debug;
      expect(() => logger.debug('debug message'), returnsNormally);
    });

    test('info method does not throw', () {
      expect(() => logger.info('info message'), returnsNormally);
    });

    test('warning method does not throw', () {
      expect(() => logger.warning('warning message'), returnsNormally);
    });

    test('error method does not throw', () {
      expect(() => logger.error('error message'), returnsNormally);
    });

    test('error method with error object does not throw', () {
      expect(
        () => logger.error('error message', Exception('test error')),
        returnsNormally,
      );
    });

    test('error method with error and stackTrace does not throw', () {
      expect(
        () => logger.error(
          'error message',
          Exception('test error'),
          StackTrace.current,
        ),
        returnsNormally,
      );
    });

    test('logs below minLevel are filtered', () {
      logger.minLevel = LogLevel.error;
      // These should not throw and should be silently filtered
      expect(() => logger.debug('debug'), returnsNormally);
      expect(() => logger.info('info'), returnsNormally);
      expect(() => logger.warning('warning'), returnsNormally);
      // This should still log
      expect(() => logger.error('error'), returnsNormally);
    });
  });
}
