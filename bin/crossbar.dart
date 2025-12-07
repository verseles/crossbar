import 'dart:io';

import 'package:crossbar/cli/cli_handler.dart';

/// Crossbar CLI Entry Point
/// 
/// This is the main entry point for Crossbar. It handles:
/// - No arguments → launches GUI in tray mode (crossbar-gui --minimized)
/// - 'gui' → launches GUI visible (crossbar-gui)
/// - Other arguments → executes CLI commands directly
/// 
/// Architecture:
/// - crossbar (this file) → CLI + launcher (Dart standalone)
/// - crossbar-gui → Flutter GUI application (separate binary)
void main(List<String> args) async {
  // GUI launch mode: no args or explicit 'gui' command
  if (args.isEmpty || args.first == 'gui') {
    await _launchGui(args);
    return;
  }

  // CLI mode: handle all other commands
  final exitCode = await handleCliCommand(args);
  exit(exitCode);
}

/// Launches the GUI application as a separate process.
/// - No args → minimized (tray mode)
/// - 'gui' → visible window
Future<void> _launchGui(List<String> args) async {
  final executablePath = Platform.resolvedExecutable;
  final executableDir = File(executablePath).parent.path;
  final isWindows = Platform.isWindows;
  
  final guiBinary = isWindows ? 'crossbar-gui.exe' : 'crossbar-gui';
  final guiPath = '$executableDir/$guiBinary';

  // Check if GUI binary exists
  if (!File(guiPath).existsSync()) {
    // Try to find it in common locations
    final alternativePaths = [
      guiPath,
      '$executableDir/../share/crossbar/$guiBinary', // Installed location
      '/usr/local/bin/$guiBinary',
      '/usr/bin/$guiBinary',
    ];

    String? foundPath;
    for (final path in alternativePaths) {
      if (File(path).existsSync()) {
        foundPath = path;
        break;
      }
    }

    if (foundPath == null) {
      stderr.writeln('Error: GUI binary not found.');
      stderr.writeln('Searched in:');
      for (final path in alternativePaths) {
        stderr.writeln('  - $path');
      }
      stderr.writeln('\nMake sure crossbar-gui is installed alongside crossbar.');
      exit(1);
    }

    // Use the found path
    await _startGui(foundPath, args);
    return;
  }

  await _startGui(guiPath, args);
}

Future<void> _startGui(String guiPath, List<String> args) async {
  List<String> guiArgs;
  
  if (args.isEmpty) {
    // Default: start minimized in tray
    guiArgs = ['--minimized'];
  } else if (args.first == 'gui') {
    // Explicit GUI mode: pass remaining args
    guiArgs = args.length > 1 ? args.sublist(1) : [];
  } else {
    guiArgs = args;
  }

  try {
    // Start GUI as detached process (don't block terminal)
    await Process.start(
      guiPath,
      guiArgs,
      mode: ProcessStartMode.detached,
    );
    // Exit immediately - GUI runs independently
    exit(0);
  } catch (e) {
    stderr.writeln('Failed to launch GUI: $e');
    exit(1);
  }
}
