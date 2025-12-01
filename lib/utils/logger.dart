import 'dart:io';

import 'package:path/path.dart' as path;

enum LogLevel {
  debug,
  info,
  warning,
  error,
}

class Logger {
  static final Logger _instance = Logger._internal();

  factory Logger() => _instance;

  Logger._internal();

  static const int _maxFileSize = 5 * 1024 * 1024;
  static const int _maxBackupFiles = 7;

  File? _logFile;
  LogLevel _minLevel = LogLevel.info;

  LogLevel get minLevel => _minLevel;
  set minLevel(LogLevel level) => _minLevel = level;

  Future<void> init() async {
    final homeDir = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '';

    final logDir = Directory(path.join(homeDir, '.crossbar', 'logs'));
    if (!await logDir.exists()) {
      await logDir.create(recursive: true);
    }

    _logFile = File(path.join(logDir.path, 'crossbar.log'));
  }

  void debug(String message) => _log(LogLevel.debug, message);
  void info(String message) => _log(LogLevel.info, message);
  void warning(String message) => _log(LogLevel.warning, message);
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    var fullMessage = message;
    if (error != null) {
      fullMessage += '\nError: $error';
    }
    if (stackTrace != null) {
      fullMessage += '\nStackTrace: $stackTrace';
    }
    _log(LogLevel.error, fullMessage);
  }

  void _log(LogLevel level, String message) {
    if (level.index < _minLevel.index) return;

    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.name.toUpperCase().padRight(7);
    final logMessage = '[$timestamp] $levelStr $message\n';

    _writeToFile(logMessage);
  }

  Future<void> _writeToFile(String message) async {
    if (_logFile == null) return;

    try {
      await _rotateIfNeeded();

      await _logFile!.writeAsString(
        message,
        mode: FileMode.append,
      );
    } catch (_) {}
  }

  Future<void> _rotateIfNeeded() async {
    if (_logFile == null || !await _logFile!.exists()) return;

    final size = await _logFile!.length();
    if (size < _maxFileSize) return;

    final logDir = _logFile!.parent;
    final baseName = path.basenameWithoutExtension(_logFile!.path);
    final ext = path.extension(_logFile!.path);

    for (var i = _maxBackupFiles - 1; i >= 1; i--) {
      final oldFile = File(path.join(logDir.path, '$baseName.$i$ext'));
      final newFile = File(path.join(logDir.path, '$baseName.${i + 1}$ext'));

      if (await oldFile.exists()) {
        if (i == _maxBackupFiles - 1) {
          await oldFile.delete();
        } else {
          await oldFile.rename(newFile.path);
        }
      }
    }

    final backupFile = File(path.join(logDir.path, '$baseName.1$ext'));
    await _logFile!.rename(backupFile.path);

    _logFile = File(path.join(logDir.path, '$baseName$ext'));
  }

  Future<List<String>> getRecentLogs({int lines = 100}) async {
    if (_logFile == null || !await _logFile!.exists()) {
      return [];
    }

    final content = await _logFile!.readAsString();
    final allLines = content.split('\n').where((l) => l.isNotEmpty).toList();

    if (allLines.length <= lines) {
      return allLines;
    }

    return allLines.sublist(allLines.length - lines);
  }

  Future<void> clearLogs() async {
    if (_logFile == null) return;

    final logDir = _logFile!.parent;
    final baseName = path.basenameWithoutExtension(_logFile!.path);
    final ext = path.extension(_logFile!.path);

    for (var i = 1; i <= _maxBackupFiles; i++) {
      final backupFile = File(path.join(logDir.path, '$baseName.$i$ext'));
      if (await backupFile.exists()) {
        await backupFile.delete();
      }
    }

    if (await _logFile!.exists()) {
      await _logFile!.writeAsString('');
    }
  }
}
