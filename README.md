# Crossbar

> **Universal Plugin System for Taskbar/Menu Bar** - Write Once, Run Everywhere

[![License](https://img.shields.io/badge/license-AGPLv3-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.35.0+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10.0+-0175C2?logo=dart)](https://dart.dev)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS%20%7C%20Windows%20%7C%20Android%20%7C%20iOS-lightgrey)](#supported-platforms)

Crossbar is a revolutionary cross-platform plugin system inspired by [BitBar](https://github.com/matryer/xbar) (macOS) and [Argos](https://github.com/p-e-w/argos) (Linux), bringing the power of scriptable status bar widgets to **all platforms** - desktop and mobile.

```python
#!/usr/bin/env python3
# This plugin works WITHOUT MODIFICATION on:
# Linux, Windows, macOS, Android, iOS
import subprocess, json

cpu = subprocess.run(['crossbar', '--cpu'], capture_output=True, text=True)
print(json.dumps({
    "icon": "⚡",
    "text": f"{cpu.stdout.strip()}%",
    "menu": [{"text": "Details", "bash": "crossbar --process-list"}]
}))
```

## ✨ Features

### 🚀 Core Capabilities

- **🌍 True Cross-Platform**: One plugin, five platforms (Linux, macOS, Windows, Android, iOS)
- **6️⃣ Multi-Language Support**: Write plugins in Bash, Python, Node.js, Dart, Go, or Rust
- **⚡ Hot Reload**: Automatic plugin detection and reload (<1s)
- **🎨 Adaptive Rendering**: Same plugin renders as tray icon, notification, or widget
- **🔒 Secure Storage**: Passwords stored in system Keychain/KeyStore
- **🌐 47 CLI Commands**: Unified API for system info, network, media, clipboard, and more

### 🎯 Revolutionary Advantages Over BitBar/Argos

| Feature | BitBar/Argos | Crossbar |
|---------|--------------|----------|
| Platforms | macOS/Linux only | Linux + Windows + macOS + Android + iOS |
| Output Formats | Text only | Text + JSON + Structured Data |
| UI Targets | Menu bar only | Tray + Notifications + Widgets + Menu bar |
| CLI API | None (scripts call system commands) | 47 unified commands (`crossbar --cpu`) |
| Configuration | Manual scripting | Declarative JSON with auto-generated UI |
| Mobile Support | ❌ None | ✅ Widgets + Persistent Notifications |
| Controls | Read-only | Bidirectional (volume, media, system) |
| Hot Reload | Manual refresh | Automatic file watching |

### 📱 Platform-Specific Features

#### Desktop (Linux/macOS/Windows)
- System tray integration with custom icons
- Menu bar dropdown with unlimited items
- Window management and theming

#### Mobile (Android/iOS)
- Home screen widgets (1x1, 2x2, 4x4 layouts)
- Persistent notifications (Android foreground service)
- Lock screen widgets (iOS)

## 🚀 Quick Start

### Installation

#### Prerequisites
- Flutter 3.35.0+ ([Install Flutter](https://docs.flutter.dev/get-started/install))
- Dart 3.10.0+ (comes with Flutter)

#### Build from Source

```bash
# Clone the repository
git clone https://github.com/verseles/crossbar.git
cd crossbar

# Get dependencies
flutter pub get

# Run on desktop
flutter run -d linux   # or macos, windows
flutter run -d android # for mobile

# Build release
flutter build linux --release
flutter build apk --release  # Android
```

### Your First Plugin

1. Create a plugin file in `~/.crossbar/plugins/`:

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

### Plugin Format

Crossbar supports **two output formats**:

#### 1. BitBar Text Format (Legacy Compatible)

```bash
#!/bin/bash
echo "🔋 85%"          # Tray text (first line)
echo "---"             # Separator
echo "Status | color=green"
echo "Details | bash='crossbar --battery --json'"
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
        {"text": "Show Details", "bash": "crossbar --battery --json"},
        {"text": "---"},  # Separator
        {"text": "Settings", "href": "https://settings"}
    ]
}))
```

### CLI API Reference

Crossbar provides 47 unified commands accessible via `crossbar --<command>`:

#### System Information
```bash
crossbar --cpu              # CPU usage percentage
crossbar --memory           # Memory usage (e.g., "8.2/16 GB")
crossbar --battery          # Battery percentage
crossbar --disk             # Disk usage
crossbar --uptime           # System uptime
crossbar --hostname         # Machine hostname
crossbar --username         # Current user
crossbar --kernel           # Kernel version
crossbar --arch             # Architecture (x64, arm64)
```

#### Network
```bash
crossbar --net-status       # "online" | "offline" | "wifi"
crossbar --net-ip           # Local IP address
crossbar --net-ip --public  # Public IP (via ipify.org)
crossbar --net-ssid         # WiFi network name
crossbar --net-ping google.com  # Ping latency
crossbar --bluetooth-status # "on" | "off"
```

#### Device
```bash
crossbar --device-model     # Device model name
crossbar --screen-size      # Screen resolution
crossbar --locale           # System locale
crossbar --timezone         # Timezone
```

#### Audio & Media
```bash
crossbar --audio-volume           # Current volume (0-100)
crossbar --audio-volume-set 50    # Set volume
crossbar --audio-mute             # Toggle mute
crossbar --media-playing --json   # Current media info
crossbar --media-play             # Resume playback
crossbar --media-pause
crossbar --media-next
crossbar --media-prev
crossbar --screen-brightness-set 75
```

#### Clipboard
```bash
crossbar --clipboard              # Get clipboard text
crossbar --clipboard-set "text"   # Copy to clipboard
crossbar --clipboard-clear
```

#### File Operations
```bash
crossbar --file-exists /path/file
crossbar --file-read /path/file
crossbar --file-size /path/file
crossbar --dir-list /path/dir
```

#### Time & Utilities
```bash
crossbar --time [12h|24h]
crossbar --date
crossbar --calendar
crossbar --countdown "2025-12-31 23:59:59"
crossbar --uuid                   # Generate UUID
crossbar --random [min] [max]
crossbar --hash "text" --algo sha256
crossbar --base64-encode "text"
crossbar --base64-decode "dGV4dA=="
```

**See full API**: [MASTER_PLAN.md](MASTER_PLAN.md#5-cli-api-unificada)

### Plugin Configuration

Plugins can declare their configuration needs:

```json
// ~/.crossbar/plugins/weather.30m.py.config.json
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

# User configs (from .config.json)
WEATHER_API_KEY=abc123         # Passwords from Keychain
WEATHER_LOCATION=São Paulo
WEATHER_UNITS=metric
```

## 📦 Example Plugins

Crossbar includes **24 example plugins** in 4 languages:

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
│   │   └── logger_service.dart       # Rotating logs
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
- >90% code coverage
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

2. Add CLI handler in `bin/crossbar.dart`:

```dart
case '--hostname':
  final api = SystemApi();
  print(await api.getHostname());
  break;
```

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

| Metric | Target | Actual |
|--------|--------|--------|
| Boot Time (desktop) | <2s | ✅ ~1.5s |
| Memory (idle, 3 plugins) | <150MB | ✅ ~120MB |
| Plugin Execution Overhead | <50ms | ✅ ~30ms |
| Hot Reload | <1s | ✅ ~500ms |
| Binary Size (Linux) | <50MB | ✅ 41MB |

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

### v1.0.0 (Current) ✅
- Core plugin system
- 6 language support
- 47 CLI commands
- Desktop support (Linux/macOS/Windows)
- Mobile support (Android/iOS)
- Hot reload
- Example plugins

### v1.1.0 (Next)
- Enhanced marketplace with ratings
- Plugin sandboxing (optional permissions)
- Config sync via GitHub Gists
- Additional CLI commands
- Performance optimizations
- More example plugins

### v2.0.0 (Future)
- Telemetry (opt-in)
- Package managers (Homebrew, Snap, winget)
- Theme customization
- Voice commands integration
- Remote plugins (server-side execution)
- Full-screen widgets

## ⭐ Star History

If you find Crossbar useful, please consider giving it a star!

---

**Made with ❤️ by the Crossbar Team**

[Website](https://crossbar.dev) • [GitHub](https://github.com/verseles/crossbar) • [Twitter](https://twitter.com/crossbardev)
