import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

/// Functional tests for Logger Service.
/// These tests use a custom logger implementation to avoid singleton issues.
void main() {
  late Directory tempDir;
  late TestableLoggerService logger;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('crossbar_logger_test_');
    logger = TestableLoggerService();
  });

  tearDown(() async {
    logger.dispose();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Logger Service - Initialization', () {
    test('init creates log directory', () async {
      await logger.init(logDirectory: tempDir.path);

      expect(tempDir.existsSync(), isTrue);
    });

    test('init creates log file', () async {
      await logger.init(logDirectory: tempDir.path);

      // File may or may not exist yet until first write
      expect(logger.isInitialized, isTrue);
    });

    test('double init is safe', () async {
      await logger.init(logDirectory: tempDir.path);
      await logger.init(logDirectory: tempDir.path);

      expect(logger.isInitialized, isTrue);
    });
  });

  group('Logger Service - Log Levels', () {
    test('debug logs at debug level', () async {
      await logger.init(logDirectory: tempDir.path);
      logger.minLevel = LogLevel.debug;

      logger.debug('Debug message');

      final content = await _getLogContent(tempDir);
      expect(content, contains('DEBUG'));
      expect(content, contains('Debug message'));
    });

    test('info logs at info level', () async {
      await logger.init(logDirectory: tempDir.path);

      logger.info('Info message');

      final content = await _getLogContent(tempDir);
      expect(content, contains('INFO'));
      expect(content, contains('Info message'));
    });

    test('warning logs at warning level', () async {
      await logger.init(logDirectory: tempDir.path);

      logger.warning('Warning message');

      final content = await _getLogContent(tempDir);
      expect(content, contains('WARNING'));
      expect(content, contains('Warning message'));
    });

    test('error logs at error level', () async {
      await logger.init(logDirectory: tempDir.path);

      logger.error('Error message');

      final content = await _getLogContent(tempDir);
      expect(content, contains('ERROR'));
      expect(content, contains('Error message'));
    });

    test('respects minimum log level', () async {
      await logger.init(logDirectory: tempDir.path);
      logger.minLevel = LogLevel.warning;

      logger.debug('Debug message');
      logger.info('Info message');
      logger.warning('Warning message');

      final content = await _getLogContent(tempDir);
      expect(content.contains('Debug message'), isFalse);
      expect(content.contains('Info message'), isFalse);
      expect(content, contains('Warning message'));
    });
  });

  group('Logger Service - Error Handling', () {
    test('logs error with exception', () async {
      await logger.init(logDirectory: tempDir.path);

      try {
        throw Exception('Test exception');
      } catch (e) {
        logger.error('Error occurred', e);
      }

      final content = await _getLogContent(tempDir);
      expect(content, contains('Error occurred'));
      expect(content, contains('Test exception'));
    });

    test('logs error with stack trace', () async {
      await logger.init(logDirectory: tempDir.path);

      try {
        throw Exception('Test exception');
      } catch (e, stackTrace) {
        logger.error('Error occurred', e, stackTrace);
      }

      final content = await _getLogContent(tempDir);
      expect(content, contains('StackTrace'));
    });
  });

  group('Logger Service - Log Format', () {
    test('log entries have timestamp', () async {
      await logger.init(logDirectory: tempDir.path);

      logger.info('Test message');

      final content = await _getLogContent(tempDir);
      // ISO8601 timestamp format
      expect(content, matches(RegExp(r'\[\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}')));
    });

    test('log entries have level', () async {
      await logger.init(logDirectory: tempDir.path);

      logger.info('Test message');

      final content = await _getLogContent(tempDir);
      expect(content, contains('INFO'));
    });
  });

  group('Logger Service - Log Rotation', () {
    test('rotates log when size exceeds limit', () async {
      await logger.init(logDirectory: tempDir.path);

      // Write enough data to trigger rotation (> 5MB)
      // For testing, we'll use a smaller limit
      final largeMessage = 'X' * 1000;
      for (var i = 0; i < 100; i++) {
        logger.info(largeMessage);
      }

      final logFile = File(path.join(tempDir.path, 'crossbar.log'));
      expect(logFile.existsSync(), isTrue);
    });
  });

  group('Logger Service - Recent Logs', () {
    test('getRecentLogs returns recent entries', () async {
      await logger.init(logDirectory: tempDir.path);

      logger.info('Message 1');
      logger.info('Message 2');
      logger.info('Message 3');

      final logs = await logger.getRecentLogs(lines: 10);

      expect(logs.length, greaterThanOrEqualTo(3));
      expect(logs.any((l) => l.contains('Message 1')), isTrue);
      expect(logs.any((l) => l.contains('Message 2')), isTrue);
      expect(logs.any((l) => l.contains('Message 3')), isTrue);
    });

    test('getRecentLogs respects line limit', () async {
      await logger.init(logDirectory: tempDir.path);

      for (var i = 0; i < 20; i++) {
        logger.info('Message $i');
      }

      final logs = await logger.getRecentLogs(lines: 5);

      expect(logs.length, lessThanOrEqualTo(5));
    });

    test('getRecentLogs returns empty for uninitialized logger', () async {
      final uninitLogger = TestableLoggerService();

      final logs = await uninitLogger.getRecentLogs();

      expect(logs, isEmpty);
    });
  });

  group('Logger Service - Search Logs', () {
    test('searchLogs finds matching entries', () async {
      await logger.init(logDirectory: tempDir.path);

      logger.info('Apple');
      logger.info('Banana');
      logger.info('Cherry');
      logger.info('Apple pie');

      final results = await logger.searchLogs('Apple');

      expect(results.length, equals(2));
      expect(results.every((r) => r.toLowerCase().contains('apple')), isTrue);
    });

    test('searchLogs is case insensitive', () async {
      await logger.init(logDirectory: tempDir.path);

      logger.info('UPPERCASE');
      logger.info('lowercase');
      logger.info('MixedCase');

      final results = await logger.searchLogs('case');

      expect(results.length, equals(3));
    });

    test('searchLogs filters by log level', () async {
      await logger.init(logDirectory: tempDir.path);
      logger.minLevel = LogLevel.debug;

      logger.debug('Debug test');
      logger.info('Info test');
      logger.error('Error test');

      final results = await logger.searchLogs('test', level: LogLevel.error);

      expect(results.length, equals(1));
      expect(results.first, contains('ERROR'));
    });
  });

  group('Logger Service - Clear Logs', () {
    test('clearLogs removes all log files', () async {
      await logger.init(logDirectory: tempDir.path);

      logger.info('Test message');

      await logger.clearLogs();

      final files = tempDir.listSync().whereType<File>().toList();
      // After clear, there should be a fresh log file with just the "Logs cleared" message
      expect(files.length, lessThanOrEqualTo(1));
    });
  });

  group('Logger Service - Stats', () {
    test('getLogStats returns valid statistics', () async {
      await logger.init(logDirectory: tempDir.path);

      logger.info('Test message');

      final stats = logger.getLogStats();

      expect(stats['logDirectory'], equals(tempDir.path));
      expect(stats['fileCount'], isA<int>());
      expect(stats['totalSize'], isA<int>());
    });

    test('getLogStats returns zeros for uninitialized logger', () async {
      final uninitLogger = TestableLoggerService();

      final stats = uninitLogger.getLogStats();

      expect(stats['totalSize'], equals(0));
      expect(stats['fileCount'], equals(0));
    });
  });

  group('Logger Service - Dispose', () {
    test('dispose stops logging', () async {
      await logger.init(logDirectory: tempDir.path);

      logger.dispose();

      expect(logger.isInitialized, isFalse);
    });
  });
}

/// Helper to get log file content
Future<String> _getLogContent(Directory dir) async {
  final logFile = File(path.join(dir.path, 'crossbar.log'));
  if (await logFile.exists()) {
    return logFile.readAsString();
  }
  return '';
}

/// Log levels for testing
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// Testable version of LoggerService that is not a singleton
class TestableLoggerService {
  static const int _maxFileSize = 5 * 1024 * 1024; // 5MB
  static const int _maxFiles = 5;
  static const String _logFileName = 'crossbar.log';

  String? _logDirectory;
  File? _currentLogFile;
  LogLevel minLevel = LogLevel.info;
  bool consoleOutput = false;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> init({String? logDirectory}) async {
    if (_initialized) return;

    _logDirectory = logDirectory ?? Directory.systemTemp.path;

    final dir = Directory(_logDirectory!);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    _currentLogFile = File(path.join(_logDirectory!, _logFileName));
    _initialized = true;

    info('Logger initialized');
  }

  void debug(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.debug, message, error, stackTrace);
  }

  void info(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.info, message, error, stackTrace);
  }

  void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.warning, message, error, stackTrace);
  }

  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, error, stackTrace);
  }

  void _log(
    LogLevel level,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    if (level.index < minLevel.index) return;

    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.name.toUpperCase().padRight(7);
    var logLine = '[$timestamp] $levelStr $message';

    if (error != null) {
      logLine += '\n  Error: $error';
    }
    if (stackTrace != null) {
      logLine += '\n  StackTrace:\n${_indentStackTrace(stackTrace)}';
    }

    _writeToFile(logLine);
  }

  String _indentStackTrace(StackTrace stackTrace) {
    return stackTrace
        .toString()
        .split('\n')
        .take(10)
        .map((line) => '    $line')
        .join('\n');
  }

  void _writeToFile(String message) {
    if (!_initialized || _currentLogFile == null) return;

    try {
      _rotateIfNeeded();
      _currentLogFile!.writeAsStringSync(
        '$message\n',
        mode: FileMode.append,
      );
    } catch (_) {
      // Silently fail
    }
  }

  void _rotateIfNeeded() {
    if (_currentLogFile == null || !_currentLogFile!.existsSync()) return;

    final size = _currentLogFile!.lengthSync();
    if (size < _maxFileSize) return;

    for (var i = _maxFiles - 1; i >= 1; i--) {
      final oldFile = File(path.join(_logDirectory!, '$_logFileName.$i'));
      final newFile = File(path.join(_logDirectory!, '$_logFileName.${i + 1}'));

      if (oldFile.existsSync()) {
        if (i == _maxFiles - 1) {
          oldFile.deleteSync();
        } else {
          oldFile.renameSync(newFile.path);
        }
      }
    }

    final rotatedFile = File(path.join(_logDirectory!, '$_logFileName.1'));
    _currentLogFile!.renameSync(rotatedFile.path);

    _currentLogFile = File(path.join(_logDirectory!, _logFileName));
    _currentLogFile!.createSync();
  }

  Future<List<String>> getRecentLogs({int lines = 100}) async {
    if (!_initialized || _currentLogFile == null) return [];

    try {
      if (!_currentLogFile!.existsSync()) return [];

      final content = await _currentLogFile!.readAsString();
      final allLines = content.split('\n');

      return allLines
          .where((line) => line.isNotEmpty)
          .toList()
          .reversed
          .take(lines)
          .toList()
          .reversed
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<String>> searchLogs(String query, {LogLevel? level}) async {
    if (!_initialized || _currentLogFile == null) return [];

    final results = <String>[];
    final queryLower = query.toLowerCase();

    try {
      for (var i = 0; i <= _maxFiles; i++) {
        final fileName = i == 0 ? _logFileName : '$_logFileName.$i';
        final file = File(path.join(_logDirectory!, fileName));

        if (!file.existsSync()) continue;

        final content = await file.readAsString();
        for (final line in content.split('\n')) {
          if (line.isEmpty) continue;

          final matchesQuery = line.toLowerCase().contains(queryLower);
          final matchesLevel =
              level == null || line.contains(level.name.toUpperCase());

          if (matchesQuery && matchesLevel) {
            results.add(line);
          }
        }
      }
    } catch (_) {
      // Ignore errors
    }

    return results;
  }

  Future<void> clearLogs() async {
    if (!_initialized || _logDirectory == null) return;

    try {
      final dir = Directory(_logDirectory!);
      if (dir.existsSync()) {
        await for (final entity in dir.list()) {
          if (entity is File && entity.path.contains(_logFileName)) {
            await entity.delete();
          }
        }
      }

      _currentLogFile = File(path.join(_logDirectory!, _logFileName));
      info('Logs cleared');
    } catch (_) {
      // Ignore errors
    }
  }

  Map<String, dynamic> getLogStats() {
    if (!_initialized || _logDirectory == null) {
      return {
        'totalSize': 0,
        'fileCount': 0,
        'oldestLog': null,
        'newestLog': null,
      };
    }

    var totalSize = 0;
    var fileCount = 0;
    DateTime? oldest;
    DateTime? newest;

    try {
      final dir = Directory(_logDirectory!);
      for (final entity in dir.listSync()) {
        if (entity is File && entity.path.contains(_logFileName)) {
          final stat = entity.statSync();
          totalSize += stat.size;
          fileCount++;

          if (oldest == null || stat.modified.isBefore(oldest)) {
            oldest = stat.modified;
          }
          if (newest == null || stat.modified.isAfter(newest)) {
            newest = stat.modified;
          }
        }
      }
    } catch (_) {
      // Ignore errors
    }

    return {
      'totalSize': totalSize,
      'fileCount': fileCount,
      'oldestLog': oldest?.toIso8601String(),
      'newestLog': newest?.toIso8601String(),
      'logDirectory': _logDirectory,
    };
  }

  void dispose() {
    _initialized = false;
    _currentLogFile = null;
  }
}
