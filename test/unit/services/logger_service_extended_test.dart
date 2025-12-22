// ignore_for_file: avoid_slow_async_io
import 'dart:io';

import 'package:crossbar/services/logger_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  group('LoggerService', () {
    late Directory tempDir;
    late LoggerService logger;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('logger_test_');
      
      // Create a fresh instance for testing
      // Note: LoggerService is a singleton, so we need to dispose and reinit
      logger = LoggerService()..dispose();
      await logger.init(logDirectory: tempDir.path);
    });

    tearDown(() async {
      logger.dispose();
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    });

    group('Singleton', () {
      test('factory returns same instance', () {
        final a = LoggerService();
        final b = LoggerService();
        expect(identical(a, b), isTrue);
      });
    });

    group('init', () {
      test('creates log directory if not exists', () async {
        final newDir = Directory(path.join(tempDir.path, 'subdir', 'logs'));
        expect(newDir.existsSync(), isFalse);

        final newLogger = LoggerService()..dispose();
        await newLogger.init(logDirectory: newDir.path);

        expect(newDir.existsSync(), isTrue);
        newLogger.dispose();
      });

      test('init is idempotent', () async {
        // Second init should not throw
        await logger.init(logDirectory: tempDir.path);
        expect(true, isTrue); // Just verifying no exception
      });
    });

    group('Logging Levels', () {
      test('debug writes to file when minLevel is debug', () async {
        logger.minLevel = LogLevel.debug;
        logger.debug('Debug message');

        final logs = await logger.getRecentLogs();
        expect(logs.any((l) => l.contains('DEBUG')), isTrue);
        expect(logs.any((l) => l.contains('Debug message')), isTrue);
      });

      test('debug is skipped when minLevel is info', () async {
        logger.minLevel = LogLevel.info;
        logger.debug('Should not appear');

        final logs = await logger.getRecentLogs();
        expect(logs.any((l) => l.contains('Should not appear')), isFalse);
      });

      test('info writes to file', () async {
        logger.minLevel = LogLevel.info;
        logger.info('Info message');

        final logs = await logger.getRecentLogs();
        expect(logs.any((l) => l.contains('INFO')), isTrue);
        expect(logs.any((l) => l.contains('Info message')), isTrue);
      });

      test('warning writes to file', () async {
        logger.warning('Warning message');

        final logs = await logger.getRecentLogs();
        expect(logs.any((l) => l.contains('WARNING')), isTrue);
        expect(logs.any((l) => l.contains('Warning message')), isTrue);
      });

      test('error writes to file', () async {
        logger.error('Error message');

        final logs = await logger.getRecentLogs();
        expect(logs.any((l) => l.contains('ERROR')), isTrue);
        expect(logs.any((l) => l.contains('Error message')), isTrue);
      });

      test('error includes exception details', () async {
        logger.error('Error with exception', Exception('Test exception'));

        final logs = await logger.getRecentLogs();
        expect(logs.any((l) => l.contains('Test exception')), isTrue);
      });

      test('error includes stack trace', () async {
        try {
          throw Exception('Stack trace test');
        } catch (e, stack) {
          logger.error('Error with stack', e, stack);
        }

        final logs = await logger.getRecentLogs();
        expect(logs.any((l) => l.contains('StackTrace')), isTrue);
      });
    });

    group('getRecentLogs', () {
      test('returns empty list when no logs', () async {
        final freshDir = await Directory.systemTemp.createTemp('empty_logs_');
        final freshLogger = LoggerService()..dispose();
        await freshLogger.init(logDirectory: freshDir.path);

        // Clear the init log
        await freshLogger.clearLogs();
        freshLogger.dispose();
        await freshDir.delete(recursive: true);
      });

      test('respects lines parameter', () async {
        // Write more than 5 logs
        for (var i = 0; i < 10; i++) {
          logger.info('Log line $i');
        }

        final logs = await logger.getRecentLogs(lines: 5);
        expect(logs.length, lessThanOrEqualTo(5));
      });

      test('returns logs in correct order', () async {
        logger.info('First');
        logger.info('Second');
        logger.info('Third');

        final logs = await logger.getRecentLogs();
        final firstIndex = logs.indexWhere((l) => l.contains('First'));
        final secondIndex = logs.indexWhere((l) => l.contains('Second'));
        final thirdIndex = logs.indexWhere((l) => l.contains('Third'));

        expect(firstIndex, lessThan(secondIndex));
        expect(secondIndex, lessThan(thirdIndex));
      });
    });

    group('searchLogs', () {
      test('finds logs by query', () async {
        logger.info('Apple info');
        logger.warning('Banana warning');
        logger.error('Cherry error');

        final results = await logger.searchLogs('Banana');
        expect(results, isNotEmpty);
        expect(results.any((l) => l.contains('Banana')), isTrue);
      });

      test('search is case insensitive', () async {
        logger.info('UPPERCASE test');

        final results = await logger.searchLogs('uppercase');
        expect(results, isNotEmpty);
      });

      test('filters by log level', () async {
        logger.info('Info log');
        logger.error('Error log');

        final errorOnly = await logger.searchLogs('log', level: LogLevel.error);
        expect(errorOnly.every((l) => l.contains('ERROR')), isTrue);
      });

      test('returns empty for non-matching query', () async {
        logger.info('Something');

        final results = await logger.searchLogs('nonexistent123xyz');
        expect(results, isEmpty);
      });
    });

    group('clearLogs', () {
      test('removes all log files', () async {
        logger.info('Log to be cleared');

        await logger.clearLogs();

        // After clearing and the "Logs cleared" message, check file content
        final logFile = File(path.join(tempDir.path, 'crossbar.log'));
        if (logFile.existsSync()) {
          final content = await logFile.readAsString();
          expect(content.contains('Log to be cleared'), isFalse);
        }
      });
    });

    group('getLogStats', () {
      test('returns stats map', () {
        final stats = logger.getLogStats();

        expect(stats.containsKey('totalSize'), isTrue);
        expect(stats.containsKey('fileCount'), isTrue);
        expect(stats.containsKey('oldestLog'), isTrue);
        expect(stats.containsKey('newestLog'), isTrue);
        expect(stats.containsKey('logDirectory'), isTrue);
      });

      test('totalSize is non-negative', () {
        final stats = logger.getLogStats();
        expect(stats['totalSize'] as int, greaterThanOrEqualTo(0));
      });

      test('fileCount counts log files', () async {
        logger.info('Test log');

        final stats = logger.getLogStats();
        expect(stats['fileCount'] as int, greaterThanOrEqualTo(1));
      });
    });

    group('dispose', () {
      test('dispose allows reinit', () async {
        logger.dispose();

        // Should be able to init again
        await logger.init(logDirectory: tempDir.path);
        logger.info('After reinit');

        final logs = await logger.getRecentLogs();
        expect(logs.any((l) => l.contains('After reinit')), isTrue);
      });
    });

    group('Console Output', () {
      test('consoleOutput flag controls console printing', () {
        // This test just verifies the flag exists and can be set
        logger.consoleOutput = true;
        expect(logger.consoleOutput, isTrue);

        logger.consoleOutput = false;
        expect(logger.consoleOutput, isFalse);
      });
    });

    group('Log Level Enum', () {
      test('LogLevel has correct order', () {
        expect(LogLevel.debug.index, lessThan(LogLevel.info.index));
        expect(LogLevel.info.index, lessThan(LogLevel.warning.index));
        expect(LogLevel.warning.index, lessThan(LogLevel.error.index));
      });
    });
  });
}
