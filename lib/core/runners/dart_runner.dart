import 'dart:async';
import 'dart:io';

import 'package:crossbar_core/crossbar_core.dart';
import 'package:dart_eval/dart_eval.dart';
import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';

/// DartRunner - Executes Dart plugins dynamically via dart_eval
///
/// This runner interprets .dart plugin files at runtime, injecting
/// the CrossbarBridge for system access. Plugins run in a sandboxed
/// environment with only access to the bridge APIs.
///
/// Example plugin code:
/// ```dart
/// import 'package:crossbar_bridge/crossbar_bridge.dart';
///
/// void main() {
///   final crossbar = CrossbarBridge();
///   final time = crossbar.time();
///   final cpu = crossbar.cpu();  // Returns Future<double>
///   print('Time: $time | CPU: ${await cpu}%');
/// }
/// ```
///
/// Available APIs via CrossbarBridge:
/// - System: cpu(), memory(), battery(), uptime(), disk(), os(), osDetails()
/// - Time: time(format), date(format)
/// - Network: web(url), netStatus(), localIp(), publicIp(), ping()
/// - Utils: exec(cmd), notify(title, msg), openUrl(), openFile()
/// - Env: env(name), platform, homeDir, isMobile, isDesktop
/// - Encoding: hash(), uuid(), base64Encode/Decode(), random()
class DartRunner {
  factory DartRunner() => instance;
  DartRunner._();

  static final DartRunner instance = DartRunner._();

  /// Execute a Dart plugin file and capture its output
  Future<DartRunResult> run(String pluginPath) async {
    final file = File(pluginPath);
    if (!file.existsSync()) {
      return DartRunResult.error('Plugin file not found: $pluginPath');
    }

    final sourceCode = await file.readAsString();
    return runSource(sourceCode, pluginPath: pluginPath);
  }

  /// Execute Dart source code and capture its output
  Future<DartRunResult> runSource(
    String sourceCode, {
    String? pluginPath,
  }) async {
    final output = StringBuffer();
    final errors = StringBuffer();
    var exitCode = 0;

    try {
      // Wrap the source code with our bridge injection
      final wrappedCode = _wrapWithBridge(sourceCode);

      // Compile
      final compiler = Compiler();
      compiler.addPlugin(CrossbarPlugin());

      final program = compiler.compile({
        'crossbar_plugin': {'main.dart': wrappedCode},
      });

      final runtime = Runtime.ofProgram(program);
      runtime.addPlugin(CrossbarPlugin());

      // Capture print statements using Zone
      await runZoned(
        () async {
          // Execute main function
          final result = runtime.executeLib(
            'package:crossbar_plugin/main.dart',
            'main',
          );

          // Handle async results
          if (result is Future) {
            await result;
          } else if (result is $Value) {
            final reified = result.$reified;
            if (reified is Future) {
              await reified;
            }
          }
        },
        zoneSpecification: ZoneSpecification(
          print: (self, parent, zone, line) {
            output.writeln(line);
          },
        ),
      );
    } catch (e, stack) {
      errors.writeln('Error executing plugin: $e');
      errors.writeln(stack.toString().split('\n').take(5).join('\n'));
      exitCode = 1;
    }

    return DartRunResult(
      output: output.toString().trim(),
      errors: errors.toString().trim(),
      exitCode: exitCode,
      pluginPath: pluginPath,
    );
  }

  /// Wrap plugin code with bridge injection
  String _wrapWithBridge(String sourceCode) {
    // Check if code already has main function
    if (!sourceCode.contains('void main()') &&
        !sourceCode.contains('void main(') &&
        !sourceCode.contains('Future<void> main()') &&
        !sourceCode.contains('Future main()')) {
      // Wrap in main if no main function
      sourceCode =
          '''
void main() {
$sourceCode
}
''';
    }

    // Check if already has import
    if (!sourceCode.contains('crossbar_bridge')) {
      // Inject bridge import
      sourceCode =
          '''
import 'package:crossbar_bridge/crossbar_bridge.dart';

$sourceCode
''';
    }

    return sourceCode;
  }

  /// Check if this runner can handle the given plugin
  bool canRun(String pluginPath) {
    final ext = pluginPath.split('.').last.toLowerCase();
    // Handles .dart files but NOT .dart.exe (compiled)
    return ext == 'dart' && !pluginPath.contains('.dart.exe');
  }
}

/// Result of running a Dart plugin
class DartRunResult {
  DartRunResult({
    required this.output,
    required this.errors,
    required this.exitCode,
    this.pluginPath,
  });

  factory DartRunResult.error(String message) {
    return DartRunResult(output: '', errors: message, exitCode: 1);
  }

  final String output;
  final String errors;
  final int exitCode;
  final String? pluginPath;

  bool get success => exitCode == 0;
  bool get hasOutput => output.isNotEmpty;
  bool get hasErrors => errors.isNotEmpty;

  @override
  String toString() {
    if (hasErrors) {
      return 'DartRunResult(exitCode: $exitCode, errors: $errors)';
    }
    return 'DartRunResult(exitCode: $exitCode, output: $output)';
  }
}

/// Plugin to expose CrossbarBridge to dart_eval
class CrossbarPlugin implements EvalPlugin {
  @override
  String get identifier => 'crossbar_bridge';

  @override
  void configureForCompile(BridgeDeclarationRegistry registry) {
    // Register CrossbarBridge class
    registry.defineBridgeClass($CrossbarBridgeDeclaration());

    // Register 'crossbar' top-level getter
    registry.defineBridgeTopLevelFunction(_crossbarGetterDeclaration);
  }

  @override
  void configureForRuntime(Runtime runtime) {
    // Register constructor
    runtime.registerBridgeFunc(
      'package:crossbar_bridge/crossbar_bridge.dart',
      'CrossbarBridge.',
      $CrossbarBridge.$new,
    );

    // Register 'crossbar' top-level getter
    runtime.registerBridgeFunc(
      'package:crossbar_bridge/crossbar_bridge.dart',
      'crossbar',
      (runtime, target, args) => $CrossbarBridge.wrap(CrossbarBridge.instance),
    );
  }

  static const _crossbarGetterDeclaration = BridgeFunctionDeclaration(
    'package:crossbar_bridge/crossbar_bridge.dart',
    'crossbar',
    BridgeFunctionDef(
      returns: BridgeTypeAnnotation(
        BridgeTypeRef(
          BridgeTypeSpec(
            'package:crossbar_bridge/crossbar_bridge.dart',
            'CrossbarBridge',
          ),
        ),
      ),
    ),
  );
}

/// Bridge declaration for CrossbarBridge
BridgeClassDef $CrossbarBridgeDeclaration() => const BridgeClassDef(
  BridgeClassType(
    BridgeTypeRef(
      BridgeTypeSpec(
        'package:crossbar_bridge/crossbar_bridge.dart',
        'CrossbarBridge',
      ),
    ),
  ),
  constructors: {
    '': BridgeConstructorDef(
      BridgeFunctionDef(
        returns: BridgeTypeAnnotation(
          BridgeTypeRef(
            BridgeTypeSpec(
              'package:crossbar_bridge/crossbar_bridge.dart',
              'CrossbarBridge',
            ),
          ),
        ),
      ),
    ),
  },
  methods: {
    'cpu': BridgeMethodDef(
      BridgeFunctionDef(
        returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future)),
      ),
    ),
    'memory': BridgeMethodDef(
      BridgeFunctionDef(
        returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future)),
      ),
    ),
    'battery': BridgeMethodDef(
      BridgeFunctionDef(
        returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future)),
      ),
    ),
    'time': BridgeMethodDef(
      BridgeFunctionDef(
        returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
        params: [
          BridgeParameter(
            'format',
            BridgeTypeAnnotation(
              BridgeTypeRef(CoreTypes.string),
              nullable: true,
            ),
            true,
          ),
        ],
      ),
    ),
    'date': BridgeMethodDef(
      BridgeFunctionDef(
        returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
        params: [
          BridgeParameter(
            'format',
            BridgeTypeAnnotation(
              BridgeTypeRef(CoreTypes.string),
              nullable: true,
            ),
            true,
          ),
        ],
      ),
    ),
    'notify': BridgeMethodDef(
      BridgeFunctionDef(
        returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future)),
        params: [
          BridgeParameter(
            'title',
            BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
            false,
          ),
          BridgeParameter(
            'message',
            BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
            false,
          ),
        ],
      ),
    ),
    'web': BridgeMethodDef(
      BridgeFunctionDef(
        returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future)),
        params: [
          BridgeParameter(
            'url',
            BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
            false,
          ),
        ],
      ),
    ),
    'exec': BridgeMethodDef(
      BridgeFunctionDef(
        returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.future)),
        params: [
          BridgeParameter(
            'command',
            BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
            false,
          ),
        ],
      ),
    ),
    'env': BridgeMethodDef(
      BridgeFunctionDef(
        returns: BridgeTypeAnnotation(
          BridgeTypeRef(CoreTypes.string),
          nullable: true,
        ),
        params: [
          BridgeParameter(
            'name',
            BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
            false,
          ),
        ],
      ),
    ),
  },
  getters: {
    'platform': BridgeMethodDef(
      BridgeFunctionDef(
        returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
      ),
    ),
    'homeDir': BridgeMethodDef(
      BridgeFunctionDef(
        returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.string)),
      ),
    ),
    'isMobile': BridgeMethodDef(
      BridgeFunctionDef(
        returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
      ),
    ),
    'isDesktop': BridgeMethodDef(
      BridgeFunctionDef(
        returns: BridgeTypeAnnotation(BridgeTypeRef(CoreTypes.bool)),
      ),
    ),
  },
  wrap: true,
);

/// Wrapper class for CrossbarBridge in dart_eval
class $CrossbarBridge implements $Instance {
  $CrossbarBridge.wrap(this.$value);

  static $CrossbarBridge $new(
    Runtime runtime,
    $Value? target,
    List<$Value?> args,
  ) {
    return $CrossbarBridge.wrap(CrossbarBridge.instance);
  }

  static const $type = BridgeTypeRef(
    BridgeTypeSpec(
      'package:crossbar_bridge/crossbar_bridge.dart',
      'CrossbarBridge',
    ),
  );

  @override
  final CrossbarBridge $value;

  @override
  CrossbarBridge get $reified => $value;

  @override
  int $getRuntimeType(Runtime runtime) => runtime.lookupType($type.spec!);

  @override
  $Value? $getProperty(Runtime runtime, String identifier) {
    switch (identifier) {
      case 'cpu':
        return $Function((runtime, target, args) {
          return $Future.wrap($value.cpu().then($double.new));
        });
      case 'memory':
        return $Function((runtime, target, args) {
          return $Future.wrap(
            $value.memory().then((v) => $Map.wrap(_wrapDartMap(v))),
          );
        });
      case 'battery':
        return $Function((runtime, target, args) {
          return $Future.wrap(
            $value.battery().then((v) => $Map.wrap(_wrapDartMap(v))),
          );
        });
      case 'time':
        return $Function((runtime, target, args) {
          final format = args.isNotEmpty && args[0] != null
              ? args[0]!.$value as String
              : 'HH:mm:ss';
          return $String($value.time(format));
        });
      case 'date':
        return $Function((runtime, target, args) {
          final format = args.isNotEmpty && args[0] != null
              ? args[0]!.$value as String
              : 'yyyy-MM-dd';
          return $String($value.date(format));
        });
      case 'notify':
        return $Function((runtime, target, args) {
          final title = args[0]!.$value as String;
          final message = args[1]!.$value as String;
          return $Future.wrap(
            $value.notify(title, message).then((_) => const $null()),
          );
        });
      case 'web':
        return $Function((runtime, target, args) {
          final url = args[0]!.$value as String;
          return $Future.wrap(
            $value.web(url).then((v) => $Map.wrap(_wrapDartMap(v))),
          );
        });
      case 'exec':
        return $Function((runtime, target, args) {
          final command = args[0]!.$value as String;
          return $Future.wrap($value.exec(command).then($String.new));
        });
      case 'env':
        return $Function((runtime, target, args) {
          final name = args[0]!.$value as String;
          final envValue = $value.env(name);
          return envValue != null ? $String(envValue) : const $null();
        });
      case 'platform':
        return $String($value.platform);
      case 'homeDir':
        return $String($value.homeDir);
      case 'isMobile':
        return $bool($value.isMobile);
      case 'isDesktop':
        return $bool($value.isDesktop);
    }
    return null;
  }

  @override
  void $setProperty(Runtime runtime, String identifier, $Value value) {
    // Read-only
  }

  /// Wrap a Dart Map for dart_eval
  static Map<$Value, $Value> _wrapDartMap(Map<dynamic, dynamic> map) {
    return map.map((k, v) => MapEntry($String(k.toString()), _wrapValue(v)));
  }

  /// Wrap a dynamic value for dart_eval
  static $Value _wrapValue(dynamic v) {
    if (v == null) return const $null();
    if (v is bool) return $bool(v);
    if (v is int) return $int(v);
    if (v is double) return $double(v);
    if (v is String) return $String(v);
    if (v is List) return $List.wrap(v.map(_wrapValue).toList());
    if (v is Map) return $Map.wrap(_wrapDartMap(v));
    return $String(v.toString());
  }
}
