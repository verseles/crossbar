// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:path/path.dart' as path;

enum LogLevel { debug, info, warning, error }

enum LogCategory {
  all('All'),
  api('API'),
  debug('Debug'),
  errors('Errors'),
  state('State'),
  widgets('Widgets');

  const LogCategory(this.label);

  final String label;
}

class LogEntry {
  LogEntry({
    required this.level,
    required this.message,
    this.details,
    this.category = LogCategory.debug,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? details;
  final LogCategory category;

  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
  }

  String get formattedTimestamp => timestamp.toIso8601String();

  String toDisplayString() {
    final buffer = StringBuffer();
    buffer.write('[${formattedTime}] [${level.name.toUpperCase()}] $message');
    if (details != null && details!.isNotEmpty) {
      buffer.write('\n  -> ${details!}');
    }
    return buffer.toString();
  }

  String toExportString() {
    final buffer = StringBuffer();
    buffer.write(
      '[${formattedTimestamp}] [${level.name.toUpperCase()}] $message',
    );
    if (details != null && details!.isNotEmpty) {
      final indented = details!.split('\n').join('\n  ');
      buffer.write('\n  -> $indented');
    }
    return buffer.toString();
  }

  @override
  String toString() => toDisplayString();
}

class LoggerService {
  factory LoggerService() => _instance;

  LoggerService._internal();
  static final LoggerService _instance = LoggerService._internal();

  static const int _maxFileSize = 5 * 1024 * 1024; // 5MB
  static const int _maxFiles = 5;
  static const String _logFileName = 'crossbar.log';
  static const int _maxLogsInMemory = 1000;

  String? _logDirectory;
  File? _currentLogFile;
  LogLevel minLevel = LogLevel.info;
  bool consoleOutput = false;
  bool _initialized = false;
  DateTime? _sessionStartTime;

  final Queue<LogEntry> _logs = Queue<LogEntry>();
  final StreamController<LogEntry> _logController =
      StreamController<LogEntry>.broadcast();

  Stream<LogEntry> get logStream => _logController.stream;
  List<LogEntry> get logs => List.unmodifiable(_logs.toList());
  DateTime get sessionStartTime => _sessionStartTime ?? DateTime.now();

  Future<void> init({String? logDirectory}) async {
    if (_initialized) return;

    _logDirectory = logDirectory ?? _getDefaultLogDirectory();
    _sessionStartTime = DateTime.now();

    final dir = Directory(_logDirectory!);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    _currentLogFile = File(path.join(_logDirectory!, _logFileName));
    _initialized = true;

    info('Logger initialized', category: LogCategory.debug);
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

  void debug(
    String message, {
    String? details,
    LogCategory category = LogCategory.debug,
  }) {
    _log(LogLevel.debug, message, details: details, category: category);
  }

  void info(
    String message, {
    String? details,
    LogCategory category = LogCategory.state,
  }) {
    _log(LogLevel.info, message, details: details, category: category);
  }

  void warning(
    String message, {
    String? details,
    LogCategory category = LogCategory.state,
  }) {
    _log(LogLevel.warning, message, details: details, category: category);
  }

  void error(
    String message, [
    Object? error,
    StackTrace? stackTrace,
    String? details,
    LogCategory category = LogCategory.errors,
  ]) {
    _log(
      LogLevel.error,
      message,
      error: error,
      stackTrace: stackTrace,
      details: details,
      category: category,
    );
  }

  void _log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? details,
    LogCategory category = LogCategory.debug,
  }) {
    if (level.index < minLevel.index) return;

    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.name.toUpperCase().padRight(7);
    var logLine = '[$timestamp] $levelStr $message';

    if (details != null && details.isNotEmpty) {
      logLine += '\n  Details: ${_indentDetails(details)}';
    }
    if (error != null) {
      logLine += '\n  Error: $error';
    }
    if (stackTrace != null) {
      logLine += '\n  StackTrace:\n${_indentStackTrace(stackTrace)}';
    }

    _addEntry(
      LogEntry(
        level: level,
        message: message,
        details: _combineDetails(details, error, stackTrace),
        category: category,
      ),
    );

    if (consoleOutput) {
      _printToConsole(level, logLine);
    }

    _writeToFile(logLine);
  }

  void _addEntry(LogEntry entry) {
    _logs.addLast(entry);
    while (_logs.length > _maxLogsInMemory) {
      _logs.removeFirst();
    }
    _logController.add(entry);
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

  String _indentDetails(String details) {
    return details.split('\n').map((line) => '    $line').join('\n');
  }

  String? _combineDetails(
    String? details,
    Object? error,
    StackTrace? stackTrace,
  ) {
    final buffer = StringBuffer();
    if (details != null && details.isNotEmpty) {
      buffer.writeln(details);
    }
    if (error != null) {
      buffer.writeln('Error: $error');
    }
    if (stackTrace != null) {
      buffer.writeln('StackTrace:');
      buffer.writeln(_indentStackTrace(stackTrace));
    }

    final result = buffer.toString().trimRight();
    return result.isEmpty ? null : result;
  }

  void _writeToFile(String message) {
    if (!_initialized || _currentLogFile == null) return;

    try {
      _rotateIfNeeded();
      _currentLogFile!.writeAsStringSync('$message\n', mode: FileMode.append);
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

    // Rename current log to .1
    final rotatedFile = File(path.join(_logDirectory!, '$_logFileName.1'));
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

      // Create fresh log file
      _currentLogFile = File(path.join(_logDirectory!, _logFileName));
      _logs.clear();
      info('Logs cleared', category: LogCategory.debug);
    } catch (_) {
      // Ignore errors
    }
  }

  List<LogEntry> getFilteredLogs({
    Duration? timeRange,
    LogCategory category = LogCategory.all,
  }) {
    var filtered = _logs.toList();

    if (timeRange != null) {
      final cutoff = DateTime.now().subtract(timeRange);
      filtered = filtered
          .where((log) => log.timestamp.isAfter(cutoff))
          .toList();
    }

    if (category != LogCategory.all) {
      filtered = filtered.where((log) => log.category == category).toList();
    }

    return filtered;
  }

  String formatLogsForExport(List<LogEntry> entries, {String? timeRangeLabel}) {
    final buffer = StringBuffer();
    buffer.writeln(
      '=== Debug Logs${timeRangeLabel != null ? ' (last $timeRangeLabel)' : ''} ===',
    );
    buffer.writeln('Session: ${sessionStartTime.toIso8601String()}');
    buffer.writeln('Platform: ${_getPlatformName()}');
    buffer.writeln('Exported: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total entries: ${entries.length}');
    buffer.writeln('');

    for (final entry in entries) {
      buffer.writeln(entry.toExportString());
      buffer.writeln('');
    }

    return buffer.toString();
  }

  String _getPlatformName() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isLinux) return 'linux';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    return 'unknown';
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
    _logs.clear();
  }
}

/// Extension to make logging easier from anywhere
extension LoggerExtension on Object {
  void logDebug(String message, {String? details, LogCategory? category}) =>
      LoggerService().debug(
        '[$runtimeType] $message',
        details: details,
        category: category ?? LogCategory.debug,
      );
  void logInfo(String message, {String? details, LogCategory? category}) =>
      LoggerService().info(
        '[$runtimeType] $message',
        details: details,
        category: category ?? LogCategory.state,
      );
  void logWarning(String message, {String? details, LogCategory? category}) =>
      LoggerService().warning(
        '[$runtimeType] $message',
        details: details,
        category: category ?? LogCategory.state,
      );
  void logError(String message, [Object? error, StackTrace? stackTrace]) =>
      LoggerService().error('[$runtimeType] $message', error, stackTrace);
}
