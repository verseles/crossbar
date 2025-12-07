# Crossbar

> **Universal Plugin System for Taskbar/Menu Bar** - Write Once, Run Everywhere

[![CI](https://github.com/verseles/crossbar/actions/workflows/ci.yml/badge.svg)](https://github.com/verseles/crossbar/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/verseles/crossbar/branch/main/graph/badge.svg)](https://codecov.io/gh/verseles/crossbar)
[![License](https://img.shields.io/badge/license-AGPLv3-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.38.3+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10.0+-0175C2?logo=dart)](https://dart.dev)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS%20%7C%20Windows%20%7C%20Android%20%7C%20iOS-lightgrey)](#supported-platforms)

Crossbar is a revolutionary cross-platform plugin system inspired by [BitBar](https://github.com/matryer/xbar) (macOS) and [Argos](https://github.com/p-e-w/argos) (Linux), bringing the power of scriptable status bar widgets to **all platforms** - desktop and mobile.

```python
#!/usr/bin/env python3
# This plugin works WITHOUT MODIFICATION on:
# Linux, Windows, macOS, Android, iOS
import subprocess, json

cpu = subprocess.run(['crossbar', 'cpu'], capture_output=True, text=True)
print(json.dumps({
    "icon": "⚡",
    "text": f"{cpu.stdout.strip()}%",
    "menu": [{"text": "Details", "bash": "crossbar process list"}]
}))
```

## ✨ Features

### 🚀 Core Capabilities

- **🌍 True Cross-Platform**: One plugin, five target platforms (Linux, macOS, Windows, Android, iOS)
- **8️⃣ Multi-Language Support**: Write plugins in Bash, Python, Node.js, Dart (Interpreted & Compiled), Go, Rust, or YAML
- **⚡ Hot Reload**: Automatic plugin detection and reload (<1s)
- **🎨 Adaptive Rendering**: Same plugin renders as tray icon, notification, or widget
- **🔒 Secure Storage**: Passwords stored in system Keychain/KeyStore
- **🌐 47+ CLI Commands**: Unified API for system info, network, media, clipboard, and more

### 🎯 Revolutionary Advantages Over BitBar/Argos

| Feature        | BitBar/Argos                        | Crossbar                                                                         |
| -------------- | ----------------------------------- | -------------------------------------------------------------------------------- |
| Platforms      | macOS/Linux only                    | Linux + Windows + macOS + Android + iOS                                          |
| Output Formats | Text only                           | Text + JSON + Structured Data                                                    |
| UI Targets     | Menu bar only                       | Tray + Notifications + Widgets + Menu bar                                        |
| CLI API        | None (scripts call system commands) | 47 unified commands (`crossbar cpu`)                                             |
| Configuration  | Manual scripting                    | Declarative JSON with auto-generated UI                                          |
| Mobile Support | ❌ None                             | ✅ Widgets + Persistent Notifications (Android) + Home/Lock Screen Widgets (iOS) |
| Controls       | Read-only                           | Bidirectional (volume, media, system)                                            |
| Hot Reload     | Manual refresh                      | Automatic file watching                                                          |

### 📱 Platform-Specific Features

#### Desktop (Linux/macOS/Windows)

- System tray integration with custom icons
- Menu bar dropdown with unlimited items
- Window management and theming
- **Tray Display Mode** (Settings → System Tray):
  - _Unified_: Single tray icon with menu for all plugins (default)
  - _Separate_: One tray icon per plugin (Linux only, coming soon)
  - _Smart Collapse/Overflow_: Automatic modes (coming soon)

#### Mobile (Android/iOS)

- Home screen widgets (1x1, 2x2, 4x4 layouts)
- Persistent notifications (Android foreground service)
- Lock screen widgets (iOS)

## 🚀 Quick Start

### Installation

#### 1. Development Setup (Recommended for Contributors)

If you plan to develop plugins or contribute to Crossbar core, we recommend setting up the full environment.

**Prerequisites:**

- Flutter 3.35.0+ ([Install Flutter](https://docs.flutter.dev/get-started/install))
- Dart 3.10.0+ (comes with Flutter)
- `make` (optional, for easier build commands)

**Setup:**

```bash
# Clone the repository
git clone https://github.com/verseles/crossbar.git
cd crossbar

# Install dependencies
flutter pub get

# Build and Run (Desktop)
# Using Makefile (Recommended - builds full architecture)
make linux   # or make macos, make windows

# Or using Flutter directly (GUI only)
flutter run -d linux
```

#### 2. Download Pre-built Binaries (For Users)

Download the latest release from [GitHub Releases](https://github.com/verseles/crossbar/releases).

**Linux**: Extract `crossbar-linux.zip` and run:

```bash
./crossbar          # Launch (Start in Tray)
./crossbar gui      # Launch GUI (Open Window)
./crossbar --help   # Show CLI commands
./crossbar cpu      # Example CLI usage
```

### Your First Plugin

1. Create a plugin file in `~/.crossbar/plugins/` (plugins can be files in the root or inside subdirectories):

```bash
#!/bin/bash
# ~/.crossbar/plugins/hello.10s.sh
echo "👋 Hello Crossbar!"
echo "---"
echo "System: $(uname -s)"
echo "Refresh | refresh=true"
```

2. Make it executable:

```bash
chmod +x ~/.crossbar/plugins/hello.10s.sh
```

3. The plugin will auto-refresh every 10 seconds (from filename `*.10s.sh`)

## 📖 Documentation

### Plugin Types

Crossbar supports multiple plugin types for different use cases:

| Type                 | Extension           | Platforms | Use Case                            |
| -------------------- | ------------------- | --------- | ----------------------------------- |
| **YAML**             | `.yaml`             | All ✅    | Simple data display, no code needed |
| **Dart Interpreted** | `.dart`             | All ✅    | Logic without external packages     |
| **Script**           | `.sh`, `.py`, `.js` | Desktop   | Existing scripts, shell commands    |
| **Dart Compiled**    | `.dart.exe`         | Desktop   | Full Dart with any package          |

**Quick Examples:**

```yaml
# YAML Plugin - weather.30m.yaml
name: Weather
source:
  type: http
  url: "https://api.example.com/weather"
output:
  text: "🌡️ ${response.temp}°C"
```

```dart
// Dart Plugin - clock.1s.dart
import 'package:crossbar_bridge/crossbar_bridge.dart';

void main() {
  final crossbar = CrossbarBridge();
  print('⏰ ${crossbar.time()}');
}
```

📖 **Detailed Guides:**

- [Plugin Types Overview](docs/plugin-types.md)
- [YAML Plugins](docs/yaml-plugins.md)
- [Dart Plugins](docs/dart-plugins.md)
- [Writing Portable Plugins](docs/writing-portable-plugins.md)
- [crossbar_api Package](packages/crossbar_api/README.md)

### Plugin Format

Crossbar supports **two output formats**:

#### 1. BitBar Text Format (Legacy Compatible)

```bash
#!/bin/bash
echo "🔋 85%"          # Tray text (first line)
echo "---"             # Separator
echo "Status | color=green"
echo "Details | bash='crossbar battery --json'"
```

**Attributes**:

- `color=red|blue|#FF0000` - Text color
- `bash='command'` - Execute on click
- `refresh=true` - Refresh all plugins on click
- `href='https://url'` - Open URL on click
- `font=Monaco` - Custom font
- `size=12` - Font size

#### 2. JSON Format (Recommended)

```python
#!/usr/bin/env python3
import json
print(json.dumps({
    "icon": "🔋",
    "text": "85%",
    "tooltip": "Battery Level",
    "color": "#00FF00",
    "menu": [
        {"text": "Show Details", "bash": "crossbar battery --json"},
        {"text": "---"},  # Separator
        {"text": "Settings", "href": "https://settings"}
    ]
}))
```

### CLI API Reference

Crossbar provides 47+ unified commands accessible via `crossbar [command]`.

#### System Information

```bash
crossbar cpu                # CPU usage (0-100)
crossbar memory             # Memory usage (e.g., "8.2/16 GB")
crossbar battery            # Battery status
crossbar disk               # Disk usage
crossbar uptime             # System uptime
crossbar hostname           # Machine hostname
crossbar username           # Current user
crossbar kernel             # Kernel version
crossbar arch               # Architecture (x64, arm64)
crossbar os                 # Operating system
```

#### Network

```bash
crossbar net status         # "online" | "offline" | "wifi"
crossbar net ip             # Local IP address
crossbar net ip --public    # Public IP (via ipify.org)
crossbar net ping google.com # Ping latency
crossbar wifi status        # WiFi status
crossbar wifi ssid          # WiFi network name
crossbar bluetooth status   # "on" | "off"
crossbar vpn status         # VPN status
```

#### Device & Hardware

```bash
crossbar screen size        # Screen resolution
crossbar screen brightness  # Get brightness
crossbar power sleep        # Suspend system
crossbar wallpaper          # Get current wallpaper path
```

#### Audio & Media

```bash
crossbar audio volume             # Current volume (0-100)
crossbar audio volume 50          # Set volume
crossbar audio mute               # Toggle mute
crossbar media playing --json     # Current media info
crossbar media play               # Resume playback
crossbar media pause
crossbar media next
crossbar media prev
```

#### Clipboard

```bash
crossbar clipboard                # Get clipboard text
crossbar clipboard "text"         # Copy to clipboard
```

#### File Operations

```bash
crossbar file exists /path/file
crossbar file read /path/file
crossbar file size /path/file
crossbar dir list /path/dir
```

#### Time & Utilities

```bash
crossbar time [12h|24h]
crossbar date
crossbar uuid                     # Generate UUID
crossbar random [min] [max]
crossbar hash "text"
crossbar base64 encode "text"
crossbar base64 decode "dGV4dA=="
crossbar exec "command"           # Execute shell command
crossbar notify "Title" "Msg"     # Send notification
crossbar open url "https://..."   # Open URL
crossbar open file "/path/..."    # Open file
```

**See full API**: [MASTER_PLAN.md](MASTER_PLAN.md#5-cli-api-unificada)

### Plugin Configuration

Plugins can declare their configuration needs:

```json
// ~/.crossbar/plugins/weather.30m.py.schema.json
{
  "name": "Weather Plugin",
  "description": "Shows current weather",
  "version": "1.0.0",
  "settings": [
    {
      "key": "API_KEY",
      "type": "password",
      "label": "OpenWeather API Key",
      "required": true
    },
    {
      "key": "LOCATION",
      "type": "text",
      "label": "City Name",
      "default": "São Paulo"
    },
    {
      "key": "UNITS",
      "type": "select",
      "label": "Temperature Units",
      "options": ["metric", "imperial"],
      "default": "metric"
    }
  ]
}
```

Crossbar automatically generates a configuration dialog with proper UI controls.

### Environment Variables

Every plugin receives these variables:

```bash
CROSSBAR_OS=linux              # Platform (linux/macos/windows/android/ios)
CROSSBAR_DARK_MODE=true        # System theme
CROSSBAR_VERSION=1.0.0         # Crossbar version
CROSSBAR_PLUGIN_ID=cpu.10s.sh  # Plugin filename

# User configs (from .schema.json)
WEATHER_API_KEY=abc123         # Passwords from Keychain
WEATHER_LOCATION=São Paulo
WEATHER_UNITS=metric
```

### Detailed Documentation

For comprehensive documentation, see:

- **[API Reference](docs/api-reference.md)** - Complete CLI command documentation (~75 commands)
- **[Plugin Development Guide](docs/plugin-development.md)** - Step-by-step tutorial for all 6 languages
- **[Configuration Schema](docs/config-schema.md)** - 25+ field types and grid layout system
- **[Security Policy](SECURITY.md)** - Vulnerability reporting and security considerations

## 📦 Example Plugins

Crossbar includes **24 example plugins** in 6 languages:

### Bash (8 plugins)

- `cpu.10s.sh` - CPU usage with color coding
- `memory.10s.sh` - RAM usage visualization
- `battery.30s.sh` - Battery status with icon
- `disk.5m.sh` - Disk space monitor
- `network.30s.sh` - Network speed (up/down)
- `uptime.1m.sh` - System uptime
- `docker-status.1m.sh` - Docker container count
- `spotify.5s.sh` - Now playing on Spotify

### Python (8 plugins)

- `weather.30m.py` - Weather from OpenWeatherMap API
- `time.1s.py` - Live clock
- `countdown.1s.py` - Event countdown timer
- `todo.1m.py` - Simple todo list
- `bitcoin.5m.py` - BTC price from CoinGecko
- `github-notifications.5m.py` - GitHub notifications
- `process-monitor.10s.py` - Top CPU processes
- `quotes.1h.py` - Random inspirational quotes

### Node.js (6 plugins)

- `npm-downloads.1h.js` - NPM package stats
- `ip-info.1h.js` - Geolocation info
- `world-clock.1m.js` - Multi-timezone clocks
- `pomodoro.1s.js` - Pomodoro timer
- `emoji-clock.1m.js` - Time as emojis

### Dart (2 plugins)

- `system-info.1m.dart` - Comprehensive system info
- `git-status.30s.dart` - Current repo status

## 🏗️ Architecture

```
crossbar/
├── lib/
│   ├── core/                   # Core plugin system
│   │   ├── plugin_manager.dart       # Discovery & lifecycle
│   │   ├── script_runner.dart        # Execution engine
│   │   ├── output_parser.dart        # BitBar/JSON parser
│   │   └── api/                      # CLI commands
│   ├── models/                 # Data models
│   ├── services/               # Background services
│   │   ├── scheduler_service.dart    # Auto-refresh
│   │   ├── tray_service.dart         # System tray
│   │   ├── hot_reload_service.dart   # File watcher
│   │   ├── marketplace_service.dart  # Plugin discovery
│   │   ├── logger_service.dart       # Rotating logs
│   │   ├── ipc_server.dart           # Inter-process communication
│   │   ├── notification_service.dart # Cross-platform notifications
│   │   ├── settings_service.dart     # User settings management
│   │   └── widget_service.dart       # Home screen widget updates
│   ├── ui/                     # User interface
│   └── l10n/                   # 10 languages
├── bin/
│   └── crossbar.dart           # CLI entry point (47 commands)
├── plugins/                    # Example plugins
├── test/                       # 116 tests (>90% coverage)
└── .github/workflows/          # CI/CD pipelines
```

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# Analyze code
flutter analyze
```

**Current stats**:

- 116 tests (114 passing, 2 skipped)
- > 90% code coverage
- 0 analysis errors

## 🔧 Development

### Project Structure

- **Core**: Plugin discovery, execution, parsing
- **Services**: Background tasks, system integration
- **UI**: Flutter Material Design 3 interface
- **CLI**: Dart-based command-line API

### Key Technologies

- **Flutter 3.35+** - Cross-platform framework
- **Dart 3.10+** - Type-safe language
- **tray_manager** - System tray integration
- **dio** - HTTP client for API calls
- **flutter_local_notifications** - Push notifications
- **home_widget** - Home screen widgets
- **flutter_secure_storage** - Keychain integration

### Adding a New CLI Command

1. Add API method in `lib/core/api/`:

```dart
// lib/core/api/system_api.dart
Future<String> getHostname() async {
  final result = await Process.run('hostname', []);
  return result.stdout.toString().trim();
}
```

2. Add CLI handler in `lib/cli/cli_handler.dart` (in the switch statement):

```dart
case 'hostname':
  print(Platform.localHostname);
```

Note: The main executable (`crossbar`) automatically supports both GUI (no args) and CLI (with args) modes.

3. Add tests in `test/unit/core/api/system_api_test.dart`

## 🌐 Internationalization

Crossbar supports **10 languages**:

- 🇺🇸 English (en)
- 🇧🇷 Portuguese (pt)
- 🇪🇸 Spanish (es)
- 🇩🇪 German (de)
- 🇫🇷 French (fr)
- 🇨🇳 Chinese (zh)
- 🇯🇵 Japanese (ja)
- 🇰🇷 Korean (ko)
- 🇮🇹 Italian (it)
- 🇷🇺 Russian (ru)

Locale is auto-detected from system settings.

## 📊 Performance

| Metric                    | Target | Actual    |
| ------------------------- | ------ | --------- |
| Boot Time (desktop)       | <2s    | ✅ ~1.5s  |
| Memory (idle, 3 plugins)  | <150MB | ✅ ~120MB |
| Plugin Execution Overhead | <50ms  | ✅ ~30ms  |
| Hot Reload                | <1s    | ✅ ~500ms |
| Binary Size (Linux)       | <50MB  | ✅ 41MB   |

## 🤝 Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Ways to Contribute

- 🐛 Report bugs via [GitHub Issues](https://github.com/verseles/crossbar/issues)
- 💡 Suggest features
- 📝 Improve documentation
- 🔌 Create and share plugins
- 🌐 Add translations
- 🧪 Write tests

## 📄 License

This project is licensed under the **GNU Affero General Public License v3.0 (AGPLv3)**.

This ensures that:

- ✅ You can use, modify, and distribute the software
- ✅ All derivatives must remain open source
- ✅ SaaS deployments must share source code (network copyleft)
- ✅ Community improvements benefit everyone

See [LICENSE](LICENSE) for full terms.

## 🙏 Acknowledgments

Inspired by:

- [BitBar](https://github.com/matryer/xbar) by Mat Ryer
- [Argos](https://github.com/p-e-w/argos) by Philipp Emanuel Weidmann

Built with:

- [Flutter](https://flutter.dev) - Google's UI toolkit
- [Dart](https://dart.dev) - Client-optimized language

## 📞 Support

- 📖 [Documentation](MASTER_PLAN.md)
- 🐛 [Issue Tracker](https://github.com/verseles/crossbar/issues)
- 💬 [Discussions](https://github.com/verseles/crossbar/discussions)
- 📧 Email: support@crossbar.dev (coming soon)

## 🗺️ Roadmap

> **Full roadmap**: See [ROADMAP.md](ROADMAP.md) for detailed timeline, completed features, and technical debt tracking.

### ✅ v1.3.0 (Current - 2025)

**Universal Plugins (Multi-Runner Architecture)**

- Core plugin system (Declarative YAML, Dart, Script).
- 47+ CLI commands.
- 5 platform support (Linux, macOS, Windows, Android, iOS).
- Hot reload & CI/CD.
- 24+ example plugins.
- i18n (10 languages).
- Comprehensive documentation.

**Current Focus**:

- iOS Widgets (WidgetKit).
- Universal Plugin Runners (Declarative/Dart).
- Advanced Desktop UI.

### 🎯 v1.4.0 (Next)

**Advanced Desktop UI**

- Global Hotkey (Ctrl+Alt+C).
- Tray Overflow Logic (Smart Collapse).
- Window State Persistence.

### 🌟 Visão de Longo Prazo (v2.0.0+)

- 🌐 Plugins remotos (execução server-side).
- 📊 Integração OpenTelemetry e Grafana.
- 🤖 Sugestões de plugins com IA.
- 🔗 Plataforma de integração (webhooks, IFTTT/Zapier).
- 🎮 Editor visual de plugins (no-code).
- 🌍 Extensão de navegador e suporte a smartwatch.

**Quer influenciar o roadmap?** Vote em funcionalidades nas [GitHub Issues](https://github.com/verseles/crossbar/issues) ou participe das [Discussions](https://github.com/verseles/crossbar/discussions)!

<details>
<summary>📜 Changelog</summary>

### [1.0.0] - 2025-12-01 🎉 Initial Release

First public release of Crossbar - Universal Plugin System for Taskbar/Menu Bar.

#### ✨ Key Features Highlights:

- **Multi-language plugin support**: Bash, Python, Node.js, Dart, Go, Rust.
- **BitBar-compatible text format parser** & **JSON output format** for structured data.
- **Hot reload system** with automatic plugin detection.
- **39 CLI Commands**: Unified API for System, Network, Device, Audio/Media, Clipboard, Utilities.
- **Desktop Support**: System tray (Linux/Windows), Menu bar (macOS).
- **Mobile Features**: Android (Foreground service, persistent notifications), iOS (Home screen widgets - planned).
- **Declarative plugin configs** with auto-generated UI (25+ field types), secure storage for passwords.
- **Comprehensive test suite**: >90% coverage for core modules, 0 analysis errors.
- **CI/CD pipelines** with multi-platform builds (Linux, macOS, Windows, Android).
- **Internationalization**: 10 languages supported.

#### 🏗️ Architecture Overview:

- **Core**: Plugin Manager, Script Runner, Output Parser, CLI API implementations.
- **Models**: Plugin, PluginOutput, PluginConfig.
- **Services**: Scheduler, Tray, Hot Reload, Marketplace, Logger, IPC, Notification, Settings, Widget.
- **UI**: Modern Material Design 3.

#### 📦 By the Numbers (v1.0.0):

- ~6,661 lines of Dart code
- 39 CLI commands
- 24 example plugins (in 6 languages)
- 10 languages (i18n)
- 4+ platforms supported (Linux, macOS, Windows, Android, iOS - planned)
- > 90% test coverage
- <150MB memory footprint (idle, 3 plugins)
- <50ms plugin execution overhead
- 41MB Linux binary size
</details>

<details>
<summary>🔒 Security Policy</summary>

Crossbar takes security seriously. If you discover a security vulnerability, please report it responsibly.

### Supported Versions

- **1.x.x**: Fully supported for security patches.
- **< 1.0**: Not supported.

### Reporting a Vulnerability

**DO NOT** open a public GitHub issue for security vulnerabilities.
Instead, please report security issues by emailing: **security@verseles.com**
Alternatively, use GitHub's private vulnerability reporting: [Security tab](https://github.com/verseles/crossbar/security).

**What to Include**: Description, Impact, Steps to Reproduce, Affected Versions, Possible Fix, Your Contact.

**Response Timeline**:

- **Acknowledgment**: Within 48 hours.
- **Initial Assessment**: Within 7 days.
- **Resolution**: Aim for 30 days for critical vulnerabilities.

### Security Considerations & Known Limitations

- **Plugin Security**: Plugins execute with the same permissions as the running user. **Only run trusted plugins.** Review third-party plugins.
- **No Plugin Sandboxing**: Plugins run with full user permissions.
- **Secure Storage**: Sensitive values (type `password`) are stored using platform-specific secure storage (Keychain, Credential Manager, libsecret).
- **Network Security**: All HTTP requests use HTTPS by default. The IPC server only listens on `localhost:48291` (not remotely accessible).
- **File Permissions**: Plugin files should have restricted permissions (`chmod 700`).

### Best Practices for Users

- Keep Crossbar updated.
- Review plugin source code.
- Use secure API keys.
- Limit plugin permissions (if possible).
- Monitor plugin behavior.

### Best Practices for Plugin Developers

- Validate all inputs.
- Use HTTPS.
- Don't hardcode secrets.
- Handle errors gracefully.
- Minimize dependencies.
- Document security requirements.

For security concerns: **security@verseles.com**

</details>

<details>
<summary>🤝 Contributing</summary>

Thank you for considering contributing to Crossbar!

### How Can I Contribute?

#### Reporting Bugs

- Check existing issues first.
- Provide a clear description, steps to reproduce, expected behavior, screenshots, and environment details.

#### Suggesting Enhancements

- Use a clear and descriptive title.
- Provide a detailed description and explain its usefulness.
- List similar features in other applications.

#### Pull Requests (PRs)

1.  **Before Submitting**: Check existing PRs, create an issue for major changes, follow coding style, write/update tests, update documentation.
2.  **PR Process**:
    - Fork the repo and create your branch from `main`.
    - Make changes following coding standards.
    - Add tests (`flutter test`).
    - Ensure all tests pass and analysis is clean (`flutter analyze`).
    - Update documentation (README.md, CHANGELOG.md, code comments).
    - Commit using [Conventional Commits](https://www.conventionalcommits.org/): `feat:`, `fix:`, `docs:`, `style:`, `refactor:`, `test:`, `chore:`.
    - Push to your fork and submit a pull request.

### Development Setup

#### Prerequisites

- Flutter 3.35.0+
- Dart 3.10.0+
- Git
- Your favorite IDE

#### Setup Steps

1.  Clone your fork: `git clone https://github.com/YOUR-USERNAME/crossbar.git`
2.  Add upstream remote: `git remote add upstream https://github.com/verseles/crossbar.git`
3.  Install dependencies: `flutter pub get`
4.  Run tests: `flutter test`
5.  Run the app: `flutter run -d linux`

### Coding Standards

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart).
- Use `flutter analyze` and `dart format`.
- **Test Coverage**: Aim for >90% for new code.
- **Documentation**: Document public APIs with DartDoc.
- **Null Safety**: Use strict null safety.

See `CONTRIBUTING.md` for more details.

</details>

## ⭐ Star History

If you find Crossbar useful, please consider giving it a star!

---

**Made with ❤️ by the Crossbar Team**

[Website](https://crossbar.dev) • [GitHub](https://github.com/verseles/crossbar) • [Twitter](https://twitter.com/crossbardev)
