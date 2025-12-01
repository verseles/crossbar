import 'dart:io';

/// Crossbar Launcher
/// Routes execution to the appropriate binary:
/// - No arguments → launches GUI (crossbar-gui)
/// - With arguments → runs CLI (crossbar-cli)
void main(List<String> args) async {
  final executableDir = File(Platform.resolvedExecutable).parent.path;

  String targetBinary;
  if (args.isEmpty) {
    // GUI mode
    targetBinary = Platform.isWindows ? 'crossbar-gui.exe' : 'crossbar-gui';
  } else {
    // CLI mode
    targetBinary = Platform.isWindows ? 'crossbar-cli.exe' : 'crossbar-cli';
  }

  final binaryPath = '$executableDir/$targetBinary';

  // Check if target binary exists
  if (!File(binaryPath).existsSync()) {
    stderr.writeln('Error: $targetBinary not found at $executableDir');
    stderr.writeln('Make sure all Crossbar binaries are in the same directory.');
    exit(1);
  }

  // Execute the target binary
  final process = await Process.start(
    binaryPath,
    args,
    mode: ProcessStartMode.inheritStdio,
  );

  // Wait for completion and propagate exit code
  final exitCode = await process.exitCode;
  exit(exitCode);
}
