import 'dart:io';

import 'package:path/path.dart' as path;

enum LogLevel {
  debug,
  info,
  warning,
  error,
}

class LoggerService {

  factory LoggerService() => _instance;

  LoggerService._internal();
  static final LoggerService _instance = LoggerService._internal();

  static const int _maxFileSize = 5 * 1024 * 1024; // 5MB
  static const int _maxFiles = 5;
  static const String _logFileName = 'crossbar.log';

  String? _logDirectory;
  File? _currentLogFile;
  LogLevel _minLevel = LogLevel.info;
  bool _consoleOutput = false;
  bool _initialized = false;

  LogLevel get minLevel => _minLevel;
  set minLevel(LogLevel level) => _minLevel = level;

  bool get consoleOutput => _consoleOutput;
  set consoleOutput(bool value) => _consoleOutput = value;

  Future<void> init({String? logDirectory}) async {
    if (_initialized) return;

    _logDirectory = logDirectory ?? _getDefaultLogDirectory();

    final dir = Directory(_logDirectory!);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    _currentLogFile = File(path.join(_logDirectory!, _logFileName));
    _initialized = true;

    info('Logger initialized');
  }

  String _getDefaultLogDirectory() {
    if (Platform.isLinux) {
      final home = Platform.environment['HOME'] ?? '/tmp';
      return path.join(home, '.crossbar', 'logs');
    } else if (Platform.isMacOS) {
      final home = Platform.environment['HOME'] ?? '/tmp';
      return path.join(home, 'Library', 'Logs', 'Crossbar');
    } else if (Platform.isWindows) {
      final appData = Platform.environment['LOCALAPPDATA'] ?? r'C:\';
      return path.join(appData, 'Crossbar', 'logs');
    } else {
      return path.join(Directory.systemTemp.path, 'crossbar', 'logs');
    }
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
    if (level.index < _minLevel.index) return;

    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.name.toUpperCase().padRight(7);
    var logLine = '[$timestamp] $levelStr $message';

    if (error != null) {
      logLine += '\n  Error: $error';
    }
    if (stackTrace != null) {
      logLine += '\n  StackTrace:\n${_indentStackTrace(stackTrace)}';
    }

    if (_consoleOutput) {
      _printToConsole(level, logLine);
    }

    _writeToFile(logLine);
  }

  void _printToConsole(LogLevel level, String message) {
    switch (level) {
      case LogLevel.debug:
        print('\x1B[36m$message\x1B[0m'); // Cyan
      case LogLevel.info:
        print('\x1B[32m$message\x1B[0m'); // Green
      case LogLevel.warning:
        print('\x1B[33m$message\x1B[0m'); // Yellow
      case LogLevel.error:
        print('\x1B[31m$message\x1B[0m'); // Red
    }
  }

  String _indentStackTrace(StackTrace stackTrace) {
    return stackTrace
        .toString()
        .split('\n')
        .take(10) // Limit stack trace lines
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
      // Silently fail if logging fails
    }
  }

  void _rotateIfNeeded() {
    if (_currentLogFile == null || !_currentLogFile!.existsSync()) return;

    final size = _currentLogFile!.lengthSync();
    if (size < _maxFileSize) return;

    // Rotate logs
    for (var i = _maxFiles - 1; i >= 1; i--) {
      final oldFile =
          File(path.join(_logDirectory!, '$_logFileName.$i'));
      final newFile =
          File(path.join(_logDirectory!, '$_logFileName.${i + 1}'));

      if (oldFile.existsSync()) {
        if (i == _maxFiles - 1) {
          oldFile.deleteSync();
        } else {
          oldFile.renameSync(newFile.path);
        }
      }
    }

    // Rename current log to .1
    final rotatedFile =
        File(path.join(_logDirectory!, '$_logFileName.1'));
    _currentLogFile!.renameSync(rotatedFile.path);

    // Create new log file
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
      // Search in current and rotated log files
      for (var i = 0; i <= _maxFiles; i++) {
        final fileName = i == 0 ? _logFileName : '$_logFileName.$i';
        final file = File(path.join(_logDirectory!, fileName));

        if (!file.existsSync()) continue;

        final content = await file.readAsString();
        for (final line in content.split('\n')) {
          if (line.isEmpty) continue;

          final matchesQuery = line.toLowerCase().contains(queryLower);
          final matchesLevel = level == null ||
              line.contains(level.name.toUpperCase());

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

      // Create fresh log file
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

/// Extension to make logging easier from anywhere
extension LoggerExtension on Object {
  void logDebug(String message) => LoggerService().debug('[$runtimeType] $message');
  void logInfo(String message) => LoggerService().info('[$runtimeType] $message');
  void logWarning(String message) => LoggerService().warning('[$runtimeType] $message');
  void logError(String message, [Object? error, StackTrace? stackTrace]) =>
      LoggerService().error('[$runtimeType] $message', error, stackTrace);
}
