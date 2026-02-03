import 'dart:convert';
import 'dart:io';

import 'package:lua_dardo/lua.dart';
import 'package:path/path.dart' as path;

import 'bridge/crossbar_bridge.dart';

class LuaRunResult {
  final bool success;
  final String output;
  final String? error;

  LuaRunResult({required this.success, this.output = '', this.error});
  factory LuaRunResult.error(String message) =>
      LuaRunResult(success: false, error: message);
}

class LuaRunner {
  factory LuaRunner() => instance;
  LuaRunner._();
  static final LuaRunner instance = LuaRunner._();
  final CrossbarBridge _bridge = CrossbarBridge();

  Future<LuaRunResult> run(
    String pluginPath, {
    String pluginId = 'unknown',
    Map<String, String> configEnv = const {},
  }) async {
    final file = File(pluginPath);
    if (!file.existsSync()) return LuaRunResult.error('Plugin file not found');
    return runSource(
      await file.readAsString(),
      pluginId: pluginId,
      configEnv: configEnv,
    );
  }

  Future<LuaRunResult> runSource(
    String source, {
    String pluginId = 'unknown',
    Map<String, String> configEnv = const {},
  }) async {
    final outputBuffer = StringBuffer();
    try {
      final lua = LuaState.newState();
      lua.openLibs();
      _registerPrint(lua, outputBuffer);
      final configValues = _extractConfigValues(configEnv);
      _registerCrossbarBridge(lua, pluginId, configValues);
      lua.doString(source);
      return LuaRunResult(success: true, output: outputBuffer.toString());
    } catch (e) {
      return LuaRunResult.error('Lua execution failed: $e');
    }
  }

  void _registerPrint(LuaState lua, StringBuffer buffer) {
    lua.pushDartFunction((LuaState ls) {
      final nargs = ls.getTop();
      final parts = <String>[];
      for (var i = 1; i <= nargs; i++) {
        final value = _luaValueToDart(ls, i);
        if (value == null) {
          parts.add('nil');
        } else if (value is bool) {
          parts.add(value ? 'true' : 'false');
        } else if (value is Map || value is List) {
          parts.add(jsonEncode(value));
        } else {
          parts.add(value.toString());
        }
      }
      buffer.writeln(parts.join('\t'));
      return 0;
    });
    lua.setGlobal('print');
  }

  void _registerCrossbarBridge(
    LuaState lua,
    String pluginId,
    Map<String, String> configValues,
  ) {
    lua.newTable();
    _registerSyncStringFunc(lua, 'time', (s) => _bridge.time(s ?? ''));
    _registerSyncStringFunc(lua, 'date', (s) => _bridge.date(s ?? ''));
    _registerSyncStringFunc(lua, 'hash', (s) => _bridge.hash(s ?? ''));
    _registerSyncStringFunc(
        lua, 'exec', (s) => _runCommand(s ?? '').stdoutTrimmed);
    _registerExecResult(lua);
    _registerSyncNoArgFunc(lua, 'uuid', _bridge.uuid);
    _registerSyncIntFunc(lua, 'random', (i) => _bridge.random(i ?? 100));
    _registerSyncStringFunc(
        lua, 'base64Encode', (s) => _bridge.base64Encode(s ?? ''));
    _registerSyncStringFunc(
        lua, 'base64Decode', (s) => _bridge.base64Decode(s ?? ''));
    _registerJsonDecode(lua);
    _registerJsonEncode(lua);
    _registerEnv(lua, configValues);
    _registerConfigTable(lua, configValues);
    _registerConfigGet(lua, configValues);
    _registerStorage(lua, pluginId);
    _registerWeb(lua);
    _registerSyncNoArgFunc(lua, 'platform', () => _bridge.platform);
    _registerSyncNoArgFunc(lua, 'homeDir', () => _bridge.homeDir);
    _registerSyncNoArgBool(lua, 'isMobile', () => _bridge.isMobile);
    _registerSyncNoArgBool(lua, 'isDesktop', () => _bridge.isDesktop);
    _registerSyncDoubleFunc(lua, 'cpu', _bridge.cpuSync);
    _registerSyncMapFunc(lua, 'memory', _bridge.memorySync);
    _registerSyncMapFunc(lua, 'battery', _bridge.batterySync);
    _registerSyncNoArgFunc(lua, 'uptime', _bridge.uptimeSync);
    lua.setGlobal('crossbar');
  }

  void _registerSyncStringFunc(
    LuaState lua,
    String name,
    String Function(String?) fn,
  ) {
    lua.pushDartFunction((ls) {
      final arg = ls.getTop() >= 1 ? ls.toStr(1) : null;
      ls.pushString(fn(arg));
      return 1;
    });
    lua.setField(-2, name);
  }

  void _registerSyncNoArgFunc(LuaState lua, String name, String Function() fn) {
    lua.pushDartFunction((ls) {
      ls.pushString(fn());
      return 1;
    });
    lua.setField(-2, name);
  }

  void _registerSyncNoArgBool(LuaState lua, String name, bool Function() fn) {
    lua.pushDartFunction((ls) {
      ls.pushBoolean(fn());
      return 1;
    });
    lua.setField(-2, name);
  }

  void _registerSyncIntFunc(LuaState lua, String name, int Function(int?) fn) {
    lua.pushDartFunction((ls) {
      final arg = ls.getTop() >= 1 ? ls.toIntegerX(1) : null;
      ls.pushInteger(fn(arg));
      return 1;
    });
    lua.setField(-2, name);
  }

  void _registerSyncMapFunc(
    LuaState lua,
    String name,
    Map<String, dynamic> Function() fn,
  ) {
    lua.pushDartFunction((ls) {
      final res = fn();
      ls.newTable();
      res.forEach((k, v) {
        ls.pushString(k);
        if (v is String) {
          ls.pushString(v);
        } else if (v is int) {
          ls.pushInteger(v);
        } else if (v is double) {
          ls.pushNumber(v);
        } else if (v is bool) {
          ls.pushBoolean(v);
        } else {
          ls.pushString(v.toString());
        }
        ls.setTable(-3);
      });
      return 1;
    });
    lua.setField(-2, name);
  }

  void _registerSyncDoubleFunc(
    LuaState lua,
    String name,
    double Function() fn,
  ) {
    lua.pushDartFunction((ls) {
      ls.pushNumber(fn());
      return 1;
    });
    lua.setField(-2, name);
  }

  Map<String, String> _extractConfigValues(Map<String, String> configEnv) {
    final values = <String, String>{};
    for (final entry in configEnv.entries) {
      if (entry.key.startsWith('CROSSBAR_PLUGIN_')) {
        values[entry.key.substring('CROSSBAR_PLUGIN_'.length)] = entry.value;
      } else {
        values[entry.key] = entry.value;
      }
    }
    return values;
  }

  String? _resolveConfigValue(String name, Map<String, String> configValues) {
    return configValues[name] ??
        configValues[name.toUpperCase()] ??
        configValues[name.toLowerCase()];
  }

  String? _resolveEnv(String name, Map<String, String> configValues) {
    if (name.startsWith('CROSSBAR_PLUGIN_')) {
      final key = name.substring('CROSSBAR_PLUGIN_'.length);
      return _resolveConfigValue(key, configValues) ??
          Platform.environment[name];
    }
    return _resolveConfigValue(name, configValues) ??
        Platform.environment['CROSSBAR_PLUGIN_$name'] ??
        Platform.environment[name];
  }

  void _registerEnv(LuaState lua, Map<String, String> configValues) {
    lua.pushDartFunction((ls) {
      final name = ls.getTop() >= 1 ? ls.toStr(1) : null;
      final defaultValue = ls.getTop() >= 2 ? ls.toStr(2) : null;

      if (name == null || name.isEmpty) {
        ls.pushNil();
        return 1;
      }

      final value = _resolveEnv(name, configValues);
      if (value == null || value.isEmpty) {
        if (defaultValue == null) {
          ls.pushNil();
        } else {
          ls.pushString(defaultValue);
        }
        return 1;
      }

      ls.pushString(value);
      return 1;
    });
    lua.setField(-2, 'env');
  }

  void _registerConfigGet(LuaState lua, Map<String, String> configValues) {
    lua.pushDartFunction((ls) {
      final name = ls.getTop() >= 1 ? ls.toStr(1) : null;
      final defaultValue = ls.getTop() >= 2 ? ls.toStr(2) : null;

      if (name == null || name.isEmpty) {
        ls.pushNil();
        return 1;
      }

      final value = _resolveConfigValue(name, configValues);
      if (value == null || value.isEmpty) {
        if (defaultValue == null) {
          ls.pushNil();
        } else {
          ls.pushString(defaultValue);
        }
        return 1;
      }

      ls.pushString(value);
      return 1;
    });
    lua.setField(-2, 'configGet');
  }

  void _registerConfigTable(LuaState lua, Map<String, String> configValues) {
    lua.newTable();
    for (final entry in configValues.entries) {
      lua.pushString(entry.value);
      lua.setField(-2, entry.key);
    }
    lua.setField(-2, 'config');
  }

  void _registerJsonDecode(LuaState lua) {
    lua.pushDartFunction((ls) {
      final input = ls.getTop() >= 1 ? ls.toStr(1) : null;
      if (input == null || input.isEmpty) {
        ls.pushNil();
        return 1;
      }
      try {
        final decoded = jsonDecode(input);
        _pushLuaValue(ls, decoded);
        return 1;
      } catch (e) {
        ls.pushNil();
        ls.pushString(e.toString());
        return 2;
      }
    });
    lua.setField(-2, 'jsonDecode');
  }

  void _registerJsonEncode(LuaState lua) {
    lua.pushDartFunction((ls) {
      if (ls.getTop() < 1) {
        ls.pushString('null');
        return 1;
      }
      final value = _luaValueToDart(ls, 1);
      ls.pushString(jsonEncode(value));
      return 1;
    });
    lua.setField(-2, 'jsonEncode');
  }

  void _registerExecResult(LuaState lua) {
    lua.pushDartFunction((ls) {
      final command = ls.getTop() >= 1 ? ls.toStr(1) : null;
      if (command == null || command.isEmpty) {
        ls.pushNil();
        return 1;
      }
      final result = _runCommand(command);
      final data = <String, dynamic>{
        'stdout': result.stdoutTrimmed,
        'stderr': result.stderrTrimmed,
        'exitCode': result.exitCode,
        'success': result.exitCode == 0,
      };
      _pushLuaValue(ls, data);
      return 1;
    });
    lua.setField(-2, 'execResult');
  }

  void _registerWeb(LuaState lua) {
    lua.pushDartFunction((ls) {
      final url = ls.getTop() >= 1 ? ls.toStr(1) : null;
      if (url == null || url.isEmpty) {
        ls.pushNil();
        return 1;
      }

      if (_bridge.isMobile) {
        _pushLuaValue(ls, {
          'error': true,
          'message': 'crossbar.web is desktop-only in Lua',
        });
        return 1;
      }

      String? method;
      Map<String, String>? headers;
      dynamic body;
      int? timeout;
      var raw = false;

      if (ls.getTop() >= 2 && ls.isTable(2)) {
        method = _getStringField(ls, 2, 'method');
        timeout = _getNumberField(ls, 2, 'timeout')?.round();
        raw = _getBoolField(ls, 2, 'raw') ?? false;
        headers = _getStringMapField(ls, 2, 'headers');
        if (_hasField(ls, 2, 'body')) {
          body = _getDynamicField(ls, 2, 'body');
        }
      }

      final command = _buildWebCommand(
        url,
        method: method,
        headers: headers,
        body: body,
        timeout: timeout,
        raw: raw,
      );

      final result = _runCommand(command);
      if (result.exitCode != 0) {
        _pushLuaValue(ls, {
          'error': true,
          'exitCode': result.exitCode,
          'message': result.stderrTrimmed.isEmpty
              ? 'crossbar web failed'
              : result.stderrTrimmed,
        });
        return 1;
      }

      if (raw) {
        ls.pushString(result.stdoutTrimmed);
        return 1;
      }

      if (result.stdoutTrimmed.isEmpty) {
        ls.pushNil();
        return 1;
      }

      try {
        final decoded = jsonDecode(result.stdoutTrimmed);
        _pushLuaValue(ls, decoded);
        return 1;
      } catch (e) {
        ls.pushNil();
        ls.pushString('Invalid JSON response');
        return 2;
      }
    });
    lua.setField(-2, 'web');
  }

  void _registerStorage(LuaState lua, String pluginId) {
    lua.pushDartFunction((ls) {
      final key = ls.getTop() >= 1 ? ls.toStr(1) : null;
      if (key == null || key.isEmpty) {
        ls.pushNil();
        return 1;
      }
      final value = _readStorageValue(pluginId, key);
      if (value == null) {
        ls.pushNil();
      } else {
        ls.pushString(value);
      }
      return 1;
    });
    lua.setField(-2, 'storageGet');

    lua.pushDartFunction((ls) {
      final key = ls.getTop() >= 1 ? ls.toStr(1) : null;
      final value = ls.getTop() >= 2 ? ls.toStr(2) : null;
      if (key == null || key.isEmpty || value == null) {
        ls.pushBoolean(false);
        return 1;
      }
      ls.pushBoolean(_writeStorageValue(pluginId, key, value));
      return 1;
    });
    lua.setField(-2, 'storageSet');

    lua.pushDartFunction((ls) {
      final key = ls.getTop() >= 1 ? ls.toStr(1) : null;
      if (key == null || key.isEmpty) {
        ls.pushBoolean(false);
        return 1;
      }
      ls.pushBoolean(_deleteStorageValue(pluginId, key));
      return 1;
    });
    lua.setField(-2, 'storageDelete');

    lua.pushDartFunction((ls) {
      final all = _readStorageAll(pluginId);
      _pushLuaValue(ls, all);
      return 1;
    });
    lua.setField(-2, 'storageAll');
  }

  bool _isStorageAvailable() => !_bridge.isMobile;

  String _sanitizePluginId(String pluginId) {
    return pluginId.replaceAll(RegExp(r'[/\\:*?"<>|]'), '_');
  }

  File _storageFile(String pluginId) {
    final safeId = _sanitizePluginId(pluginId.isEmpty ? 'unknown' : pluginId);
    final dir = Directory(path.join(_bridge.homeDir, '.crossbar', 'storage'));
    return File(path.join(dir.path, '$safeId.json'));
  }

  Map<String, String> _readStorageAll(String pluginId) {
    if (!_isStorageAvailable()) return {};
    final file = _storageFile(pluginId);
    if (!file.existsSync()) return {};
    try {
      final raw = jsonDecode(file.readAsStringSync());
      if (raw is Map) {
        return raw
            .map((key, value) => MapEntry(key.toString(), value.toString()));
      }
    } catch (_) {}
    return {};
  }

  String? _readStorageValue(String pluginId, String key) {
    if (!_isStorageAvailable()) return null;
    final data = _readStorageAll(pluginId);
    return data[key];
  }

  bool _writeStorageValue(String pluginId, String key, String value) {
    if (!_isStorageAvailable()) return false;
    final file = _storageFile(pluginId);
    final dir = file.parent;
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    final data = _readStorageAll(pluginId);
    data[key] = value;
    try {
      file.writeAsStringSync(jsonEncode(data));
      return true;
    } catch (_) {
      return false;
    }
  }

  bool _deleteStorageValue(String pluginId, String key) {
    if (!_isStorageAvailable()) return false;
    final file = _storageFile(pluginId);
    if (!file.existsSync()) return false;
    final data = _readStorageAll(pluginId);
    data.remove(key);
    try {
      file.writeAsStringSync(jsonEncode(data));
      return true;
    } catch (_) {
      return false;
    }
  }

  bool _hasField(LuaState ls, int index, String key) {
    if (!ls.isTable(index)) return false;
    ls.getField(index, key);
    final exists = !ls.isNil(-1);
    ls.pop(1);
    return exists;
  }

  String? _getStringField(LuaState ls, int index, String key) {
    if (!ls.isTable(index)) return null;
    ls.getField(index, key);
    final value = ls.toStr(-1);
    ls.pop(1);
    return value;
  }

  double? _getNumberField(LuaState ls, int index, String key) {
    if (!ls.isTable(index)) return null;
    ls.getField(index, key);
    final value = ls.toNumberX(-1);
    ls.pop(1);
    return value;
  }

  bool? _getBoolField(LuaState ls, int index, String key) {
    if (!ls.isTable(index)) return null;
    ls.getField(index, key);
    final value = ls.isBoolean(-1) ? ls.toBoolean(-1) : null;
    ls.pop(1);
    return value;
  }

  Map<String, String>? _getStringMapField(
    LuaState ls,
    int index,
    String key,
  ) {
    if (!ls.isTable(index)) return null;
    ls.getField(index, key);
    if (!ls.isTable(-1)) {
      ls.pop(1);
      return null;
    }
    final map = _luaValueToDart(ls, -1);
    ls.pop(1);
    if (map is Map) {
      return map.map((k, v) => MapEntry(k.toString(), v.toString()));
    }
    return null;
  }

  dynamic _getDynamicField(LuaState ls, int index, String key) {
    if (!ls.isTable(index)) return null;
    ls.getField(index, key);
    final value = _luaValueToDart(ls, -1);
    ls.pop(1);
    return value;
  }

  String _buildWebCommand(
    String url, {
    String? method,
    Map<String, String>? headers,
    dynamic body,
    int? timeout,
    bool raw = false,
  }) {
    final args = <String>['crossbar', 'web', _quoteShell(url)];
    if (method != null && method.isNotEmpty) {
      args.addAll(['--method', method.toUpperCase()]);
    }
    if (headers != null && headers.isNotEmpty) {
      final encoded = jsonEncode(headers);
      args.addAll(['--headers', _quoteShell(encoded)]);
    }
    if (body != null) {
      final encodedBody = body is String ? body : jsonEncode(body);
      args.addAll(['--body', _quoteShell(encodedBody)]);
    }
    if (timeout != null && timeout > 0) {
      args.addAll(['--timeout', timeout.toString()]);
    }
    if (!raw) {
      args.add('--json');
    }
    return args.join(' ');
  }

  String _quoteShell(String value) {
    final escaped = value.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
    return '"$escaped"';
  }

  _CommandResult _runCommand(String command) {
    if (command.trim().isEmpty) {
      return _CommandResult(exitCode: 0, stdout: '', stderr: '');
    }
    final isWindows = Platform.isWindows;
    final result = Process.runSync(
      isWindows ? 'cmd' : 'sh',
      [isWindows ? '/c' : '-c', command],
      environment: _buildShellEnvironment(),
    );
    return _CommandResult.fromProcess(result);
  }

  Map<String, String> _buildShellEnvironment() {
    final env = Map<String, String>.from(Platform.environment);
    final currentPath = env['PATH'] ?? '';
    final crossbarDir = _getCrossbarBinDir();
    if (crossbarDir == null || crossbarDir.isEmpty) {
      return env;
    }
    final separator = Platform.isWindows ? ';' : ':';
    if (!currentPath.split(separator).contains(crossbarDir)) {
      env['PATH'] = '$crossbarDir$separator$currentPath';
    }
    return env;
  }

  String? _getCrossbarBinDir() {
    final execPath = Platform.resolvedExecutable;
    if (execPath.isEmpty) return null;
    return File(execPath).parent.path;
  }

  dynamic _luaValueToDart(LuaState ls, int index, {int depth = 0}) {
    if (depth > 6) {
      return ls.toStr(index);
    }

    if (ls.isNil(index)) return null;
    if (ls.isBoolean(index)) return ls.toBoolean(index);
    if (ls.isInteger(index)) return ls.toInteger(index);
    if (ls.isNumber(index)) return ls.toNumber(index);
    if (ls.isString(index)) return ls.toStr(index);
    if (ls.isTable(index)) {
      return _luaTableToDart(ls, index, depth: depth);
    }
    return ls.toStr(index);
  }

  dynamic _luaTableToDart(LuaState ls, int index, {int depth = 0}) {
    final tableIndex = ls.absIndex(index);
    final map = <String, dynamic>{};
    final list = <int, dynamic>{};
    var isArray = true;
    var maxIndex = 0;

    ls.pushNil();
    while (ls.next(tableIndex)) {
      final keyIndex = ls.absIndex(-2);
      final value = _luaValueToDart(ls, -1, depth: depth + 1);

      if (ls.isInteger(keyIndex)) {
        final key = ls.toInteger(keyIndex);
        if (key >= 1) {
          list[key] = value;
          if (key > maxIndex) maxIndex = key;
        } else {
          isArray = false;
          map[key.toString()] = value;
        }
      } else {
        isArray = false;
        map[ls.toStr(keyIndex) ?? ''] = value;
      }
      ls.pop(1);
    }

    if (isArray) {
      final result = List<dynamic>.filled(maxIndex, null);
      for (final entry in list.entries) {
        result[entry.key - 1] = entry.value;
      }
      return result;
    }

    return map;
  }

  void _pushLuaValue(LuaState ls, dynamic value) {
    if (value == null) {
      ls.pushNil();
    } else if (value is bool) {
      ls.pushBoolean(value);
    } else if (value is int) {
      ls.pushInteger(value);
    } else if (value is double) {
      ls.pushNumber(value);
    } else if (value is num) {
      ls.pushNumber(value.toDouble());
    } else if (value is String) {
      ls.pushString(value);
    } else if (value is Map) {
      ls.newTable();
      for (final entry in value.entries) {
        ls.pushString(entry.key.toString());
        _pushLuaValue(ls, entry.value);
        ls.setTable(-3);
      }
    } else if (value is List) {
      ls.newTable();
      for (var i = 0; i < value.length; i++) {
        ls.pushInteger(i + 1);
        _pushLuaValue(ls, value[i]);
        ls.setTable(-3);
      }
    } else {
      ls.pushString(value.toString());
    }
  }
}

class _CommandResult {
  _CommandResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  factory _CommandResult.fromProcess(ProcessResult result) {
    return _CommandResult(
      exitCode: result.exitCode,
      stdout: (result.stdout as String?) ?? '',
      stderr: (result.stderr as String?) ?? '',
    );
  }

  final int exitCode;
  final String stdout;
  final String stderr;

  String get stdoutTrimmed => stdout.trim();
  String get stderrTrimmed => stderr.trim();
}
