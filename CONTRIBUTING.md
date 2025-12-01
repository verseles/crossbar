# Contributing to Crossbar

First off, thank you for considering contributing to Crossbar! It's people like you that make Crossbar such a great tool.

## Code of Conduct

This project and everyone participating in it is governed by respect, inclusivity, and collaboration. By participating, you are expected to uphold this standard.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues to avoid duplicates. When you create a bug report, include as many details as possible:

**Bug Report Template**:

```markdown
**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '....'
3. See error

**Expected behavior**
What you expected to happen.

**Screenshots**
If applicable, add screenshots.

**Environment:**
 - OS: [e.g., Linux, macOS, Windows, Android, iOS]
 - OS Version: [e.g., Ubuntu 22.04, macOS Sonoma 14.1]
 - Flutter Version: [e.g., 3.35.0]
 - Dart Version: [e.g., 3.10.0]
 - Crossbar Version: [e.g., 1.0.0]

**Additional context**
Add any other context about the problem here.
```

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, please include:

- **Use a clear and descriptive title**
- **Provide a detailed description** of the suggested enhancement
- **Explain why this enhancement would be useful** to most Crossbar users
- **List any similar features** in other applications (BitBar, Argos, etc.)

### Pull Requests

#### Before Submitting

1. **Check existing PRs** to avoid duplicates
2. **Create an issue first** for major changes to discuss the approach
3. **Follow the coding style** used throughout the project
4. **Write/update tests** for your changes
5. **Update documentation** if needed

#### PR Process

1. Fork the repo and create your branch from `main`:
   ```bash
   git checkout -b feature/amazing-feature
   ```

2. Make your changes following our coding standards

3. Add tests for your changes:
   ```bash
   flutter test
   ```

4. Ensure all tests pass and code analysis is clean:
   ```bash
   flutter analyze
   flutter test
   ```

5. Update documentation (README.md, CHANGELOG.md, code comments)

6. Commit your changes using clear commit messages:
   ```bash
   git commit -m "feat: Add amazing feature

   - Implement X functionality
   - Add tests for Y
   - Update documentation"
   ```

7. Push to your fork and submit a pull request

8. Wait for review and address any feedback

#### Commit Message Convention

We follow [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation only
- `style:` Code style changes (formatting, etc.)
- `refactor:` Code refactoring
- `test:` Adding/updating tests
- `chore:` Maintenance tasks

Examples:
```
feat: Add --screenshot CLI command
fix: Handle timeout in plugin execution
docs: Update CLI API reference in README
test: Add integration tests for JSON parser
refactor: Extract tray menu builder to separate method
```

## Development Setup

### Prerequisites

- Flutter 3.35.0+
- Dart 3.10.0+
- Git
- Your favorite IDE (VS Code, Android Studio, IntelliJ)

### Setup Steps

1. **Clone your fork**:
   ```bash
   git clone https://github.com/YOUR-USERNAME/crossbar.git
   cd crossbar
   ```

2. **Add upstream remote**:
   ```bash
   git remote add upstream https://github.com/verseles/crossbar.git
   ```

3. **Install dependencies**:
   ```bash
   flutter pub get
   ```

4. **Run tests**:
   ```bash
   flutter test
   ```

5. **Run the app**:
   ```bash
   flutter run -d linux  # or macos, windows, android
   ```

### Project Structure

```
crossbar/
├── lib/
│   ├── core/           # Core plugin system
│   ├── models/         # Data models
│   ├── services/       # Background services
│   ├── ui/             # User interface
│   ├── utils/          # Utilities
│   └── l10n/           # Localization
├── bin/
│   └── crossbar.dart   # CLI entry point
├── test/
│   ├── unit/           # Unit tests
│   ├── integration/    # Integration tests
│   └── widget/         # Widget tests
├── plugins/            # Example plugins
└── .github/
    └── workflows/      # CI/CD
```

## Coding Standards

### Dart/Flutter Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Use `flutter analyze` and fix all warnings
- Format code with `dart format`:
  ```bash
  dart format lib/ test/ bin/
  ```

### Code Quality

- **Test Coverage**: Aim for >90% coverage for new code
- **Documentation**: Document public APIs with DartDoc comments
- **Null Safety**: Use strict null safety
- **Error Handling**: Handle errors gracefully with try-catch

### Example Code Style

```dart
/// Executes a plugin and returns the parsed output.
///
/// Throws [PluginExecutionException] if execution fails.
/// Throws [TimeoutException] if execution exceeds [timeout].
///
/// Example:
/// ```dart
/// final runner = ScriptRunner();
/// final output = await runner.execute(plugin);
/// print(output.text);
/// ```
Future<PluginOutput> execute(
  Plugin plugin, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  try {
    final result = await Process.run(
      plugin.interpreter,
      [plugin.path],
      timeout: timeout,
    );
    return _parseOutput(result.stdout);
  } on TimeoutException {
    throw PluginExecutionException('Plugin timed out: ${plugin.name}');
  } catch (e) {
    throw PluginExecutionException('Failed to execute plugin: $e');
  }
}
```

## Testing

### Running Tests

```bash
# All tests
flutter test

# Specific test file
flutter test test/unit/core/plugin_manager_test.dart

# With coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Writing Tests

Every feature should have corresponding tests:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:crossbar/core/plugin_manager.dart';

void main() {
  group('PluginManager', () {
    late PluginManager manager;

    setUp(() {
      manager = PluginManager();
    });

    test('discovers plugins in directory', () async {
      await manager.discoverPlugins();
      expect(manager.plugins, isNotEmpty);
    });

    test('filters by language', () async {
      await manager.discoverPlugins();
      final bashPlugins = manager.plugins
          .where((p) => p.language == 'bash')
          .toList();
      expect(bashPlugins, isNotEmpty);
    });
  });
}
```

## Adding New Features

### Adding a CLI Command

1. **Add API method** in `lib/core/api/`:
   ```dart
   // lib/core/api/system_api.dart
   Future<String> getHostname() async {
     final result = await Process.run('hostname', []);
     return result.stdout.toString().trim();
   }
   ```

2. **Add CLI handler** in `lib/cli/cli_handler.dart` (in the switch statement):
   ```dart
   case '--hostname':
     print(Platform.localHostname);
   ```

   Note: The CLI is automatically available through the main executable.

3. **Add tests**:
   ```dart
   test('getHostname returns machine name', () async {
     final api = SystemApi();
     final hostname = await api.getHostname();
     expect(hostname, isNotEmpty);
   });
   ```

4. **Update documentation** in README.md

### Adding a Service

1. Create service in `lib/services/`:
   ```dart
   class MyService {
     static final MyService _instance = MyService._internal();
     factory MyService() => _instance;
     MyService._internal();

     Future<void> init() async {
       // Initialization
     }
   }
   ```

2. Add tests in `test/unit/services/`

3. Document usage in code and README

### Creating Example Plugins

1. Add plugin to `plugins/` directory
2. Include `.config.json` if needed
3. Make executable: `chmod +x plugins/myplugin.sh`
4. Test with: `./plugins/myplugin.sh`
5. Document in README under "Example Plugins"

## Internationalization

### Adding a New Language

1. Create ARB file in `lib/l10n/`:
   ```
   lib/l10n/app_pl.arb  # Polish
   ```

2. Copy structure from `app_en.arb`:
   ```json
   {
     "appTitle": "Crossbar",
     "pluginsTab": "Wtyczki",
     "settingsTab": "Ustawienia"
   }
   ```

3. Run code generation:
   ```bash
   flutter gen-l10n
   ```

4. Test the new locale

## CI/CD

Our GitHub Actions workflows automatically:

- Run tests on every push
- Check code formatting
- Run `flutter analyze`
- Build for all platforms on tags
- Generate coverage reports

Make sure your PR passes all CI checks before requesting review.

## Documentation

### What to Document

- Public APIs (classes, methods, functions)
- Complex algorithms or logic
- Configuration options
- CLI commands
- Plugin format specifications

### DartDoc Comments

```dart
/// Parses plugin output in BitBar text format.
///
/// The format supports the following attributes:
/// - `color=red|#FF0000` - Text color
/// - `bash='command'` - Command to run on click
/// - `refresh=true` - Refresh all plugins
///
/// Example input:
/// ```
/// CPU: 45%
/// ---
/// Details | color=blue
/// ```
///
/// Returns a [PluginOutput] with parsed text and menu items.
PluginOutput parseTextFormat(String output) {
  // Implementation
}
```

## Community

### Getting Help

- 📖 Read the [MASTER_PLAN.md](MASTER_PLAN.md) for complete specs
- 💬 Use [GitHub Discussions](https://github.com/verseles/crossbar/discussions) for questions
- 🐛 Check [Issues](https://github.com/verseles/crossbar/issues) for known problems

### Staying Updated

- Watch the repository for notifications
- Follow the [CHANGELOG.md](CHANGELOG.md)
- Subscribe to releases

## Recognition

Contributors will be recognized in:

- README.md Contributors section
- Release notes
- GitHub insights

Thank you for contributing to Crossbar! 🎉

## License

By contributing to Crossbar, you agree that your contributions will be licensed under the AGPLv3 license.
