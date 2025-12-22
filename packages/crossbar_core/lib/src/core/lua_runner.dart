import 'dart:io';
import 'package:lua_dardo/lua.dart';
import 'bridge/crossbar_bridge.dart';

class LuaRunResult {
  final bool success;
  final String output;
  final String? error;

  LuaRunResult({required this.success, this.output = '', this.error});
  factory LuaRunResult.error(String message) => LuaRunResult(success: false, error: message);
}

class LuaRunner {
  factory LuaRunner() => instance;
  LuaRunner._();
  static final LuaRunner instance = LuaRunner._();
  final CrossbarBridge _bridge = CrossbarBridge();

  Future<LuaRunResult> run(String pluginPath) async {
    final file = File(pluginPath);
    if (!file.existsSync()) return LuaRunResult.error('Plugin file not found');
    return runSource(await file.readAsString());
  }

  Future<LuaRunResult> runSource(String source) async {
    final outputBuffer = StringBuffer();
    try {
      final lua = LuaState.newState();
      lua.openLibs();
      _registerPrint(lua, outputBuffer);
      _registerCrossbarBridge(lua);
      lua.doString(source);
      return LuaRunResult(success: true, output: outputBuffer.toString());
    } catch (e) { return LuaRunResult.error('Lua execution failed: $e'); }
  }

  void _registerPrint(LuaState lua, StringBuffer buffer) {
    lua.pushDartFunction((LuaState ls) {
      final nargs = ls.getTop();
      final parts = <String>[];
      for (var i = 1; i <= nargs; i++) parts.add(ls.toStr(i) ?? 'nil');
      buffer.writeln(parts.join('\t'));
      return 0;
    });
    lua.setGlobal('print');
  }

  void _registerCrossbarBridge(LuaState lua) {
    lua.newTable();
    _registerSyncStringFunc(lua, 'time', (s) => _bridge.time(s ?? ''));
    _registerSyncStringFunc(lua, 'date', (s) => _bridge.date(s ?? ''));
    _registerSyncStringFunc(lua, 'hash', (s) => _bridge.hash(s ?? ''));
    _registerSyncStringFunc(lua, 'exec', (s) => _bridge.execSync(s ?? ''));
    _registerSyncNoArgFunc(lua, 'uuid', _bridge.uuid);
    _registerSyncIntFunc(lua, 'random', (i) => _bridge.random(i ?? 100));
    _registerSyncStringFunc(lua, 'base64Encode', (s) => _bridge.base64Encode(s ?? ''));
    _registerSyncStringFunc(lua, 'base64Decode', (s) => _bridge.base64Decode(s ?? ''));
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

  void _registerSyncStringFunc(LuaState lua, String name, String Function(String?) fn) {
    lua.pushDartFunction((ls) {
      final arg = ls.getTop() >= 1 ? ls.toStr(1) : null;
      ls.pushString(fn(arg));
      return 1;
    });
    lua.setField(-2, name);
  }

  void _registerSyncNoArgFunc(LuaState lua, String name, String Function() fn) {
    lua.pushDartFunction((ls) { ls.pushString(fn()); return 1; });
    lua.setField(-2, name);
  }

  void _registerSyncNoArgBool(LuaState lua, String name, bool Function() fn) {
    lua.pushDartFunction((ls) { ls.pushInteger(fn() ? 1 : 0); return 1; });
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

  void _registerSyncMapFunc(LuaState lua, String name, Map<String, dynamic> Function() fn) {
    lua.pushDartFunction((ls) {
      final res = fn();
      ls.newTable();
      res.forEach((k, v) {
        ls.pushString(k);
        if (v is String) ls.pushString(v);
        else if (v is int) ls.pushInteger(v);
        else if (v is double) ls.pushNumber(v);
        else if (v is bool) ls.pushBoolean(v);
        else ls.pushString(v.toString());
        ls.setTable(-3);
      });
      return 1;
    });
    lua.setField(-2, name);
  }

  void _registerSyncDoubleFunc(LuaState lua, String name, double Function() fn) {
    lua.pushDartFunction((ls) { ls.pushNumber(fn()); return 1; });
    lua.setField(-2, name);
  }
}
