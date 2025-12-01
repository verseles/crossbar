import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/plugin.dart';
import '../models/plugin_output.dart';
import 'output_parser.dart';

abstract class IProcessRunner {
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    Map<String, String>? environment,
    required Duration timeout,
  });
}

class SystemProcessRunner implements IProcessRunner {
  const SystemProcessRunner();

  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    Map<String, String>? environment,
    required Duration timeout,
  }) async {
    final process = await Process.start(
      executable,
      arguments,
      environment: environment,
      runInShell: true,
    );

    final stdoutFuture = process.stdout.transform(utf8.decoder).join();
    final stderrFuture = process.stderr.transform(utf8.decoder).join();

    final exitCodeFuture = process.exitCode;

    try {
      final results = await Future.wait([
        stdoutFuture,
        stderrFuture,
        exitCodeFuture,
      ]).timeout(timeout);

      return ProcessResult(
        process.pid,
        results[2] as int,
        results[0],
        results[1],
      );
    } on TimeoutException {
      process.kill(ProcessSignal.sigterm);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      process.kill(ProcessSignal.sigkill);
      rethrow;
    }
  }
}

class MockProcessRunner implements IProcessRunner {
  final Map<String, String> mockOutputs;
  final Map<String, int> mockExitCodes;

  const MockProcessRunner({
    this.mockOutputs = const {},
    this.mockExitCodes = const {},
  });

  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    Map<String, String>? environment,
    required Duration timeout,
  }) async {
    final key = arguments.isNotEmpty ? arguments.first : executable;
    final output = mockOutputs[key] ?? '';
    final exitCode = mockExitCodes[key] ?? 0;

    return ProcessResult(
      0,
      exitCode,
      output,
      '',
    );
  }
}

class ScriptRunner {
  final IProcessRunner processRunner;
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const String crossbarVersion = '1.0.0';

  const ScriptRunner({this.processRunner = const SystemProcessRunner()});

  Future<PluginOutput> run(Plugin plugin) async {
    try {
      final environment = _buildEnvironment(plugin);

      // Get the appropriate executable and arguments for this interpreter
      final (executable, arguments) = _getExecutableAndArgs(plugin);

      final result = await processRunner.run(
        executable,
        arguments,
        environment: environment,
        timeout: defaultTimeout,
      );

      if (result.exitCode != 0) {
        return PluginOutput.error(
          plugin.id,
          'Plugin exited with code ${result.exitCode}: ${result.stderr}',
        );
      }

      return OutputParser.parse(result.stdout.toString(), plugin.id);
    } on TimeoutException {
      return PluginOutput.error(plugin.id, 'Plugin execution timed out');
    } catch (e) {
      return PluginOutput.error(plugin.id, 'Failed to run plugin: $e');
    }
  }

  /// Returns (executable, arguments) tuple for the given plugin interpreter
  (String, List<String>) _getExecutableAndArgs(Plugin plugin) {
    switch (plugin.interpreter) {
      case 'go':
        // Go requires 'go run file.go'
        return ('go', ['run', plugin.path]);
      case 'rust':
        // For Rust, we expect a compiled binary with same name (without .rs)
        // Or we can use 'rustc' to compile and run inline
        final binaryPath = plugin.path.replaceAll('.rs', '');
        if (File(binaryPath).existsSync()) {
          return (binaryPath, []);
        }
        // Fallback: compile to temp and run with proper crate name
        // Extract a valid crate name (alphanumeric and underscores only)
        final fileName = plugin.path.split('/').last.replaceAll('.rs', '');
        final crateName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
        return ('sh', ['-c', 'rustc --crate-name $crateName ${plugin.path} -o /tmp/crossbar_rust_$crateName && /tmp/crossbar_rust_$crateName']);
      default:
        return (plugin.interpreter, [plugin.path]);
    }
  }

  Map<String, String> _buildEnvironment(Plugin plugin) {
    return {
      ...Platform.environment,
      'CROSSBAR_OS': Platform.operatingSystem,
      'CROSSBAR_VERSION': crossbarVersion,
      'CROSSBAR_PLUGIN_ID': plugin.id,
    };
  }
}
