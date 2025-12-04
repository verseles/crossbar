import 'dart:io';

/// Crossbar Launcher
/// Routes execution to the appropriate binary:
/// - No arguments → launches GUI in tray (crossbar-gui --minimized)
/// - 'gui' → launches GUI visible (crossbar-gui)
/// - Other arguments → runs CLI (crossbar-cli)
void main(List<String> args) async {
  final executableDir = File(Platform.resolvedExecutable).parent.path;
  final isWindows = Platform.isWindows;

  String targetBinary;
  List<String> targetArgs;

  if (args.isEmpty) {
    // Default mode: Start GUI in tray
    targetBinary = isWindows ? 'crossbar-gui.exe' : 'crossbar-gui';
    targetArgs = ['--minimized'];
  } else if (args.first == 'gui') {
    // Explicit GUI mode: Start visible
    targetBinary = isWindows ? 'crossbar-gui.exe' : 'crossbar-gui';
    targetArgs = args.sublist(1);
  } else {
    // CLI mode
    targetBinary = isWindows ? 'crossbar-cli.exe' : 'crossbar-cli';
    targetArgs = args;
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
    targetArgs,
    mode: ProcessStartMode.inheritStdio,
  );

  // Wait for completion and propagate exit code
  final exitCode = await process.exitCode;
  exit(exitCode);
}
