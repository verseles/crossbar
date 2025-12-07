import 'dart:io';

import '../models/plugin.dart';
import '../models/plugin_output.dart';
import 'runners/dart_runner.dart';
import 'runners/declarative_runner.dart';
import 'runners/lua_runner.dart';
import 'script_runner.dart';

/// Unified Plugin Executor - Routes plugin execution to the appropriate runner
///
/// This executor determines the best runner for each plugin based on:
/// 1. File extension (.dart, .yaml, .sh, .py, .lua, .js, etc.)
/// 2. Platform compatibility (mobile vs desktop)
/// 3. Fallback chain if primary runner fails
///
/// Supported runners:
/// - ScriptRunner: Bash, Python, Node.js, Go, Rust (desktop only)
/// - DartRunner: Interpreted Dart plugins (all platforms)
/// - DeclarativeRunner: YAML-based plugins (all platforms)
/// - LuaRunner: Lua plugins via lua_dardo (all platforms, embedded)
class PluginExecutor {
  factory PluginExecutor() => instance;
  PluginExecutor._();
  
  static final PluginExecutor instance = PluginExecutor._();
  
  final ScriptRunner _scriptRunner = const ScriptRunner();
  final DartRunner _dartRunner = DartRunner();
  final DeclarativeRunner _declarativeRunner = DeclarativeRunner();
  final LuaRunner _luaRunner = LuaRunner();
  
  /// Run a plugin using the appropriate runner
  Future<PluginOutput> run(
    Plugin plugin, {
    Map<String, String> additionalEnv = const {},
  }) async {
    final runnerType = getRunnerType(plugin.path);
    
    switch (runnerType) {
      case RunnerType.declarative:
        return _runDeclarative(plugin);
        
      case RunnerType.dart:
        return _runDart(plugin);
        
      case RunnerType.lua:
        return _runLua(plugin);
        
      case RunnerType.script:
        return _runScript(plugin, additionalEnv);
        
      case RunnerType.unknown:
        return PluginOutput.error(
          plugin.id,
          'Unknown plugin type: ${plugin.path}',
        );
    }
  }
  
  /// Get the runner type for a plugin path
  RunnerType getRunnerType(String pluginPath) {
    final ext = _getExtension(pluginPath);
    
    // YAML plugins - work everywhere
    if (ext == 'yaml' || ext == 'yml') {
      return RunnerType.declarative;
    }
    
    // Lua plugins - embedded interpreter works everywhere
    if (ext == 'lua') {
      return RunnerType.lua;
    }
    
    // JavaScript plugins - always use Node on desktop (no embedded JS for now)
    // Note: flutter_js requires Flutter context, can't use in pure Dart CLI
    if (ext == 'js') {
      return RunnerType.script;
    }
    
    // Dart plugins - run via 'dart run' like other scripts
    // Note: dart_eval is too limited (no dart:io support), so we run natively
    if (ext == 'dart') {
      return RunnerType.script;
    }
    
    // Script plugins (bash, python, go, rust, compiled dart)
    if (_isScriptExtension(ext) || pluginPath.endsWith('.dart.exe')) {
      return RunnerType.script;
    }
    
    return RunnerType.unknown;
  }
  
  /// Check if runner can execute on current platform
  bool canRunOnPlatform(String pluginPath) {
    final runnerType = getRunnerType(pluginPath);
    
    switch (runnerType) {
      case RunnerType.declarative:
      case RunnerType.lua:
        // These work everywhere (embedded interpreters)
        return true;
        
      case RunnerType.dart:
      case RunnerType.script:
        // Scripts (including Dart via dart run) only work on desktop platforms
        return Platform.isLinux || Platform.isMacOS || Platform.isWindows;
        
      case RunnerType.unknown:
        return false;
    }
  }
  
  /// Get list of supported extensions
  List<String> get supportedExtensions => [
    // Declarative
    'yaml', 'yml',
    // Embedded (work everywhere)
    'lua',
    // Scripts (desktop only, but .js can use Node)
    'js',
    // Dart
    'dart',
    // Scripts (desktop only)
    'sh', 'bash', 'zsh',
    'py', 'python',
    'go',
    'rs',
  ];
  
  /// Run declarative (YAML) plugin
  Future<PluginOutput> _runDeclarative(Plugin plugin) async {
    final result = await _declarativeRunner.run(plugin.path);
    
    if (!result.success) {
      return PluginOutput.error(plugin.id, result.error ?? 'Unknown error');
    }
    
    // Convert menu items
    final menuItems = result.menu.map(_convertMenuItem).toList();
    
    return PluginOutput(
      pluginId: plugin.id,
      icon: result.icon ?? '',
      text: result.output,
      trayTooltip: result.tooltip,
      menu: menuItems,
    );
  }
  
  /// Run interpreted Dart plugin
  Future<PluginOutput> _runDart(Plugin plugin) async {
    final result = await _dartRunner.run(plugin.path);
    
    if (!result.success) {
      return PluginOutput.error(plugin.id, result.errors);
    }
    
    // Parse the output using standard format
    return _parseOutput(plugin.id, result.output);
  }
  
  /// Run Lua plugin using embedded interpreter
  Future<PluginOutput> _runLua(Plugin plugin) async {
    final result = await _luaRunner.run(plugin.path);
    
    if (!result.success) {
      return PluginOutput.error(plugin.id, result.error ?? 'Unknown error');
    }
    
    return _parseOutput(plugin.id, result.output);
  }
  
  /// Run script plugin (bash, python, node, etc.)
  Future<PluginOutput> _runScript(
    Plugin plugin,
    Map<String, String> additionalEnv,
  ) async {
    return _scriptRunner.run(plugin, additionalEnv: additionalEnv);
  }
  
  /// Parse raw output into PluginOutput
  PluginOutput _parseOutput(String pluginId, String rawOutput) {
    final lines = rawOutput.split('\n');
    if (lines.isEmpty) {
      return PluginOutput(pluginId: pluginId, icon: '', text: '');
    }
    
    // First line is the main output
    final firstLine = lines.first;
    
    // Check for icon at start
    var icon = '';
    var text = firstLine;
    
    // Simple icon detection (emoji at start)
    if (firstLine.isNotEmpty) {
      final firstCodeUnit = firstLine.codeUnitAt(0);
      if (firstCodeUnit > 127) {
        // Likely an emoji, split it
        final parts = firstLine.split(' ');
        if (parts.length >= 2) {
          icon = parts.first;
          text = parts.skip(1).join(' ');
        }
      }
    }
    
    return PluginOutput(
      pluginId: pluginId,
      icon: icon,
      text: text.trim(),
    );
  }
  
  /// Convert DeclarativeMenuItem to MenuItem
  MenuItem _convertMenuItem(DeclarativeMenuItem item) {
    if (item.isSeparator) {
      return MenuItem.separator();
    }
    
    // Parse action into appropriate field
    String? bash;
    String? href;
    
    if (item.action != null) {
      if (item.action!.startsWith('exec:')) {
        bash = item.action!.substring(5);
      } else if (item.action!.startsWith('url:')) {
        href = item.action!.substring(4);
      }
    }
    
    return MenuItem(
      text: item.title,
      bash: bash,
      href: href,
    );
  }
  
  String _getExtension(String path) {
    // Handle special case like "plugin.1s.dart"
    final parts = path.split('.');
    if (parts.length < 2) return '';
    return parts.last.toLowerCase();
  }
  
  bool _isScriptExtension(String ext) {
    return const [
      'sh', 'bash', 'zsh',
      'py', 'python',
      'js', 'node',
      'go',
      'rs',
    ].contains(ext);
  }
}

/// Type of runner to use for a plugin
enum RunnerType {
  /// YAML-based declarative plugins
  declarative,
  
  /// Interpreted Dart plugins
  dart,
  
  /// Lua plugins (embedded lua_dardo)
  lua,
  
  /// Script plugins (bash, python, node, go, rust)
  script,
  
  /// Unknown/unsupported type
  unknown,
}
