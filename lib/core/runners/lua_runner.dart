import 'dart:io';

import 'package:lua_dardo/lua.dart';

import '../bridge/crossbar_bridge.dart';

/// Result of a Lua script execution
class LuaRunResult {
  LuaRunResult({
    required this.success,
    this.output = '',
    this.error,
  });

  factory LuaRunResult.error(String message) => LuaRunResult(
        success: false,
        error: message,
      );

  final bool success;
  final String output;
  final String? error;
}

/// LuaRunner - Executes Lua plugins using lua_dardo (pure Dart)
///
/// This runner interprets .lua plugin files at runtime, injecting
/// the CrossbarBridge for system access. Works on ALL platforms
/// including Android and iOS without external dependencies.
///
/// Example plugin code:
/// ```lua
/// -- cpu.10s.lua
/// local time = crossbar.time()
/// print("🕐 " .. time)
/// ```
class LuaRunner {
  factory LuaRunner() => instance;
  LuaRunner._();

  static final LuaRunner instance = LuaRunner._();
  final CrossbarBridge _bridge = CrossbarBridge();

  /// Execute a Lua plugin file and capture its output
  Future<LuaRunResult> run(String pluginPath) async {
    final file = File(pluginPath);
    if (!file.existsSync()) {
      return LuaRunResult.error('Plugin file not found: $pluginPath');
    }

    final sourceCode = await file.readAsString();
    return runSource(sourceCode, pluginPath: pluginPath);
  }

  /// Execute Lua source code and return result
  Future<LuaRunResult> runSource(String source, {String? pluginPath}) async {
    final outputBuffer = StringBuffer();

    try {
      final lua = LuaState.newState();

      // Open standard libraries
      lua.openLibs();

      // Register custom print function to capture output
      _registerPrint(lua, outputBuffer);

      // Register crossbar bridge functions
      _registerCrossbarBridge(lua);

      // Execute the Lua code using doString (loadString + call)
      lua.doString(source);

      return LuaRunResult(
        success: true,
        output: outputBuffer.toString(),
      );
    } catch (e) {
      return LuaRunResult.error('Lua execution failed: $e');
    }
  }

  /// Register custom print function to capture output
  void _registerPrint(LuaState lua, StringBuffer buffer) {
    lua.pushDartFunction((LuaState ls) {
      final nargs = ls.getTop();
      final parts = <String>[];

      for (var i = 1; i <= nargs; i++) {
        parts.add(ls.toStr(i) ?? 'nil');
      }

      buffer.writeln(parts.join('\t'));
      return 0;
    });
    lua.setGlobal('print');
  }

  /// Register crossbar bridge as a Lua table
  void _registerCrossbarBridge(LuaState lua) {
    lua.newTable();

    // Time functions (sync)
    _registerSyncStringFunc(lua, 'time', (String? format) => _bridge.time(format ?? ''));
    _registerSyncStringFunc(lua, 'date', (String? format) => _bridge.date(format ?? ''));

    // Utility functions (sync)
    _registerSyncStringFunc(lua, 'hash', (String? text) => _bridge.hash(text ?? ''));
    _registerSyncStringFunc(lua, 'exec', (String? cmd) => _bridge.execSync(cmd ?? ''));
    _registerSyncNoArgFunc(lua, 'uuid', _bridge.uuid);
    _registerSyncIntFunc(lua, 'random', (int? max) => _bridge.random(max ?? 100));
    _registerSyncStringFunc(lua, 'base64Encode', (String? text) => _bridge.base64Encode(text ?? ''));
    _registerSyncStringFunc(lua, 'base64Decode', (String? text) => _bridge.base64Decode(text ?? ''));

    // Platform info (sync)
    _registerSyncNoArgFunc(lua, 'platform', () => _bridge.platform);
    _registerSyncNoArgFunc(lua, 'homeDir', () => _bridge.homeDir);
    _registerSyncNoArgBool(lua, 'isMobile', () => _bridge.isMobile);
    _registerSyncNoArgBool(lua, 'isDesktop', () => _bridge.isDesktop);

    // System info (sync)
    _registerSyncDoubleFunc(lua, 'cpu', _bridge.cpuSync);
    _registerSyncMapFunc(lua, 'memory', _bridge.memorySync);
    _registerSyncMapFunc(lua, 'battery', _bridge.batterySync);
    _registerSyncNoArgFunc(lua, 'uptime', _bridge.uptimeSync);

    lua.setGlobal('crossbar');
  }

  /// Register a sync function that takes optional string arg and returns string
  void _registerSyncStringFunc(LuaState lua, String name, String Function(String?) fn) {
    lua.pushDartFunction((LuaState ls) {
      try {
        String? arg;
        if (ls.getTop() >= 1 && !ls.isNil(1)) {
          arg = ls.toStr(1);
        }
        final result = fn(arg);
        ls.pushString(result);
        return 1;
      } catch (e) {
        ls.pushString('error: $e');
        return 1;
      }
    });
    lua.setField(-2, name);
  }

  /// Register a sync function with no args that returns string
  void _registerSyncNoArgFunc(LuaState lua, String name, String Function() fn) {
    lua.pushDartFunction((LuaState ls) {
      try {
        final result = fn();
        ls.pushString(result);
        return 1;
      } catch (e) {
        ls.pushString('error: $e');
        return 1;
      }
    });
    lua.setField(-2, name);
  }

  /// Register a sync function with no args that returns bool (as int for Lua)
  void _registerSyncNoArgBool(LuaState lua, String name, bool Function() fn) {
    lua.pushDartFunction((LuaState ls) {
      try {
        final result = fn();
        ls.pushInteger(result ? 1 : 0);
        return 1;
      } catch (e) {
        ls.pushInteger(0);
        return 1;
      }
    });
    lua.setField(-2, name);
  }

  /// Register a sync function with optional int arg that returns int
  void _registerSyncIntFunc(LuaState lua, String name, int Function(int?) fn) {
    lua.pushDartFunction((LuaState ls) {
      try {
        int? arg;
        if (ls.getTop() >= 1 && !ls.isNil(1)) {
          arg = ls.toIntegerX(1);
        }
        final result = fn(arg);
        ls.pushInteger(result);
        return 1;
      } catch (e) {
        ls.pushInteger(0);
        return 1;
      }
    });
    lua.setField(-2, name);
  }

  /// Register a sync function that returns a Map converted to Lua Table
  void _registerSyncMapFunc(LuaState lua, String name, Map<String, dynamic> Function() fn) {
    lua.pushDartFunction((LuaState ls) {
      try {
        final result = fn();
        ls.newTable();
        result.forEach((key, value) {
          ls.pushString(key);
          if (value is String) {
            ls.pushString(value);
          } else if (value is int) {
            ls.pushInteger(value);
          } else if (value is double) {
            ls.pushNumber(value);
          } else if (value is bool) {
            ls.pushBoolean(value);
          } else if (value == null) {
            ls.pushNil();
          } else {
            ls.pushString(value.toString());
          }
          ls.setTable(-3);
        });
        return 1;
      } catch (e) {
        ls.pushNil();
        return 1;
      }
    });
    lua.setField(-2, name);
  }

  /// Register a sync function that returns a double
  void _registerSyncDoubleFunc(LuaState lua, String name, double Function() fn) {
    lua.pushDartFunction((LuaState ls) {
      try {
        final result = fn();
        ls.pushNumber(result);
        return 1;
      } catch (e) {
        ls.pushNumber(0.0);
        return 1;
      }
    });
    lua.setField(-2, name);
  }
}
