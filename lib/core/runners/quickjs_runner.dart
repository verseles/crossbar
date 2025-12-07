import 'dart:io';

import 'package:flutter_js/flutter_js.dart';

import '../bridge/crossbar_bridge.dart';

/// Result of a JavaScript script execution
class JsRunResult {
  JsRunResult({
    required this.success,
    this.output = '',
    this.error,
  });

  factory JsRunResult.error(String message) => JsRunResult(
        success: false,
        error: message,
      );

  final bool success;
  final String output;
  final String? error;
}

/// QuickJsRunner - Executes JavaScript plugins using QuickJS/JavaScriptCore
///
/// This runner interprets .js plugin files at runtime using flutter_js,
/// which uses QuickJS on Android/Desktop and JavaScriptCore on iOS.
/// Works on ALL platforms without external Node.js dependency.
///
/// Example plugin code:
/// ```javascript
/// // clock.1s.js
/// var time = crossbar.time();
/// console.log("🕐 " + time);
/// ```
class QuickJsRunner {
  factory QuickJsRunner() => instance;
  QuickJsRunner._();

  static final QuickJsRunner instance = QuickJsRunner._();
  final CrossbarBridge _bridge = CrossbarBridge();

  JavascriptRuntime? _runtime;
  bool _isInitialized = false;

  /// Get or create the JS runtime
  JavascriptRuntime _getRuntime() {
    if (_runtime == null || !_isInitialized) {
      _runtime = getJavascriptRuntime();
      _registerCrossbarBridge(_runtime!);
      _isInitialized = true;
    }
    return _runtime!;
  }

  /// Execute a JavaScript plugin file and capture its output
  Future<JsRunResult> run(String pluginPath) async {
    final file = File(pluginPath);
    if (!file.existsSync()) {
      return JsRunResult.error('Plugin file not found: $pluginPath');
    }

    final sourceCode = await file.readAsString();
    return runSource(sourceCode, pluginPath: pluginPath);
  }

  /// Execute JavaScript source code and return result
  Future<JsRunResult> runSource(String source, {String? pluginPath}) async {
    try {
      final runtime = _getRuntime();

      // Wrap code to capture console.log output
      final wrappedCode = '''
        (function() {
          var __output__ = [];
          var __originalLog__ = console.log;
          console.log = function() {
            var args = Array.prototype.slice.call(arguments);
            __output__.push(args.join(' '));
            if (__originalLog__) __originalLog__.apply(console, arguments);
          };
          
          try {
            $source
          } catch (e) {
            __output__.push('Error: ' + e.toString());
          }
          
          return __output__.join('\\n');
        })();
      ''';

      final result = runtime.evaluate(wrappedCode);

      if (result.isError) {
        return JsRunResult.error('JavaScript error: ${result.stringResult}');
      }

      return JsRunResult(
        success: true,
        output: result.stringResult,
      );
    } catch (e) {
      return JsRunResult.error('JavaScript execution failed: $e');
    }
  }

  /// Register crossbar bridge functions in the JS runtime
  void _registerCrossbarBridge(JavascriptRuntime runtime) {
    // Register message handlers for sync functions
    runtime.onMessage('crossbar_time', (args) {
      final format = _parseArgs(args);
      return _bridge.time(format);
    });

    runtime.onMessage('crossbar_date', (args) {
      final format = _parseArgs(args);
      return _bridge.date(format);
    });

    runtime.onMessage('crossbar_hash', (args) {
      final text = _parseArgs(args);
      return _bridge.hash(text);
    });

    runtime.onMessage('crossbar_uuid', (args) {
      return _bridge.uuid();
    });

    runtime.onMessage('crossbar_random', (args) {
      final maxStr = _parseArgs(args);
      final max = int.tryParse(maxStr) ?? 100;
      return _bridge.random(max).toString();
    });

    runtime.onMessage('crossbar_base64Encode', (args) {
      final text = _parseArgs(args);
      return _bridge.base64Encode(text);
    });

    runtime.onMessage('crossbar_base64Decode', (args) {
      final text = _parseArgs(args);
      return _bridge.base64Decode(text);
    });

    runtime.onMessage('crossbar_platform', (args) => _bridge.platform);
    runtime.onMessage('crossbar_homeDir', (args) => _bridge.homeDir);
    runtime.onMessage('crossbar_isMobile', (args) => _bridge.isMobile.toString());
    runtime.onMessage('crossbar_isDesktop', (args) => _bridge.isDesktop.toString());

    // Inject the crossbar object with message-based calls
    runtime.evaluate('''
      var crossbar = {
        time: function(format) {
          return sendMessage('crossbar_time', format || '');
        },
        date: function(format) {
          return sendMessage('crossbar_date', format || '');
        },
        hash: function(text) {
          return sendMessage('crossbar_hash', text || '');
        },
        uuid: function() {
          return sendMessage('crossbar_uuid', '');
        },
        random: function(max) {
          return parseInt(sendMessage('crossbar_random', (max || 100).toString()));
        },
        base64Encode: function(text) {
          return sendMessage('crossbar_base64Encode', text || '');
        },
        base64Decode: function(text) {
          return sendMessage('crossbar_base64Decode', text || '');
        },
        platform: sendMessage('crossbar_platform', ''),
        homeDir: sendMessage('crossbar_homeDir', ''),
        isMobile: sendMessage('crossbar_isMobile', '') === 'true',
        isDesktop: sendMessage('crossbar_isDesktop', '') === 'true'
      };
    ''');
  }

  /// Parse args from message (handles string directly or JSON)
  String _parseArgs(dynamic args) {
    if (args == null) return '';
    if (args is String) return args;
    if (args is List && args.isNotEmpty) return args[0].toString();
    return args.toString();
  }

  /// Dispose the runtime
  void dispose() {
    _runtime?.dispose();
    _runtime = null;
    _isInitialized = false;
  }
}
