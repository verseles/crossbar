/// Abstract base class for CLI commands
abstract class CliCommand {
  /// The command name (e.g., 'audio', 'cpu')
  String get name;

  /// Short description for help output
  String get description;

  /// Executes the command with the given arguments
  /// Returns the exit code (0 for success)
  Future<int> execute(List<String> args);
}
