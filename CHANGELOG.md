# Changelog

All notable changes to Crossbar will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-12-01

### 🎉 Initial Release

First public release of Crossbar - Universal Plugin System for Taskbar/Menu Bar.

### ✨ Features

#### Core Architecture
- **Multi-language plugin support**: Bash, Python, Node.js, Dart, Go, Rust
- **BitBar-compatible text format parser** with color, emoji, and menu support
- **JSON output format** for structured data and advanced features
- **Hot reload system** with automatic plugin detection (500ms debounce)
- **Plugin Manager** with concurrent execution (max 10 parallel)
- **Refresh interval parsing** from filename (e.g., `cpu.10s.sh`, `weather.5m.py`)

#### CLI API (47 Commands)
- **System Info**: cpu, memory, battery, disk, uptime, hostname, username, kernel, arch
- **Network**: status, IP (local/public), WiFi SSID, ping, Bluetooth status
- **Device**: model, screen size, locale, timezone
- **Audio/Media**: volume get/set, media controls (play/pause/next/prev), brightness
- **Clipboard**: get, set, clear
- **Files**: exists, read, size, directory listing
- **Time**: current time, date, calendar, countdown
- **Utilities**: hash, UUID, random, base64, QR code generation

#### Desktop Support
- **Linux**: System tray integration with tray_manager
- **macOS**: Menu bar support (native bindings)
- **Windows**: System tray (native)
- **Cross-platform window management** with window_manager

#### Mobile Features
- **Android**: Foreground service with persistent notifications
- **iOS**: Home screen widgets (WidgetKit)
- **Home screen widgets** (1x1, 2x2, 4x4 grid layouts)
- **Push notifications** with flutter_local_notifications

#### Configuration System
- **Declarative plugin configs** in JSON format
- **25+ field types**: text, password, number, color, file picker, dropdown, etc.
- **Auto-generated configuration dialogs** from plugin metadata
- **Secure storage** for passwords (Keychain/KeyStore integration)

#### Services
- **SchedulerService**: Background plugin execution with Timer.periodic
- **NotificationService**: Cross-platform push notifications
- **WidgetService**: Home screen widget updates
- **TrayService**: System tray menu with dynamic icons
- **MarketplaceService**: GitHub plugin discovery and installation
- **LoggerService**: Rotating file logs (5MB max, 5 files retention)
- **HotReloadService**: File watcher integration with auto-reload

#### UI/UX
- **Modern Material Design 3** with adaptive theming
- **Dark/Light mode** following system preferences
- **Three main tabs**: Plugins, Settings, Marketplace
- **NavigationRail** for desktop, adaptive navigation for mobile
- **Plugin configuration dialogs** with dynamic form generation

#### Internationalization
- **10 languages supported**: English, Portuguese, Spanish, German, French, Chinese, Japanese, Korean, Italian, Russian
- **ARB-based localization** with compile-time safety
- **Automatic locale detection** from system

#### Developer Experience
- **24 example plugins** across 4 languages (bash, python, node, dart)
  - System monitoring (CPU, memory, battery, disk, network, uptime)
  - Real-time data (weather, Bitcoin price, world clock)
  - Productivity (todo list, Pomodoro timer, countdown)
  - DevOps (Docker status, SSH connections, process monitor, git status)
  - Entertainment (Spotify now playing, random quotes)
- **Comprehensive test suite**: 116 unit/integration tests (>90% coverage)
- **CI/CD pipelines** with GitHub Actions
  - Multi-platform builds (Linux, macOS, Windows, Android)
  - Automated testing on every push
  - Release workflow with artifact uploads

#### Quality & Testing
- **116 tests** (114 passing, 2 skipped for network/permissions)
- **Flutter analyze** with zero errors
- **Test coverage**: >90% for core modules
- **Integration tests** for plugin execution and parsing

### 🏗️ Architecture

```
lib/
├── core/                  # Core plugin system
│   ├── plugin_manager.dart      # Plugin discovery & lifecycle
│   ├── script_runner.dart       # Process execution
│   ├── output_parser.dart       # BitBar/JSON parsing
│   └── api/                     # CLI API implementations
│       ├── system_api.dart      # System info commands
│       └── network_api.dart     # Network commands
├── models/                # Data models
│   ├── plugin.dart             # Plugin metadata
│   ├── plugin_output.dart      # Parsed output
│   └── plugin_config.dart      # Configuration schema
├── services/              # Background services
│   ├── scheduler_service.dart   # Background execution
│   ├── tray_service.dart        # System tray
│   ├── notification_service.dart
│   ├── widget_service.dart
│   ├── marketplace_service.dart
│   ├── logger_service.dart
│   └── hot_reload_service.dart
├── ui/                    # User interface
│   ├── tabs/                   # Main application tabs
│   └── dialogs/                # Configuration dialogs
└── utils/                 # Utilities
    └── file_watcher.dart       # Hot reload watcher

bin/
└── crossbar.dart          # CLI entry point (47 commands)
```

### 📦 Dependencies

**Core**:
- Flutter 3.35.0+
- Dart 3.10.0+

**Key Packages**:
- `tray_manager` ^0.2.3 - System tray integration
- `window_manager` ^0.4.2 - Window management
- `dio` ^5.7.0 - HTTP client
- `flutter_local_notifications` ^17.2.3 - Push notifications
- `home_widget` ^0.6.0 - Home screen widgets
- `flutter_secure_storage` ^9.2.2 - Secure credential storage
- `path_provider` ^2.1.4 - System paths
- `intl` ^0.20.2 - Internationalization

### 🔧 Technical Details

- **Binary size**: ~41MB (Linux release bundle)
- **Memory footprint**: <150MB with 3 active plugins
- **Plugin execution overhead**: <50ms
- **Hot reload time**: <1s
- **Minimum refresh interval**: 1 second (prevents fork bombs)
- **Maximum concurrent plugins**: 10 (prevents resource exhaustion)
- **Default timeout**: 30 seconds per plugin execution

### 📝 Plugin Format Examples

**BitBar Text Format**:
```bash
#!/bin/bash
echo "⚡ 45%"
echo "---"
echo "Details | color=blue"
echo "Refresh | refresh=true"
```

**JSON Format**:
```python
#!/usr/bin/env python3
import json
print(json.dumps({
    "icon": "🔋",
    "text": "85%",
    "tooltip": "Battery charged",
    "menu": [
        {"text": "Show details", "bash": "crossbar --battery --json"}
    ]
}))
```

### 🐛 Known Limitations

- macOS/Windows builds require respective platforms (not built in this release)
- iOS builds require Xcode on macOS
- Some CLI commands require elevated permissions (--wifi-on/off, --wallpaper-set)
- Android 12+ requires foreground service notification to stay visible

### 📚 Documentation

- See [MASTER_PLAN.md](MASTER_PLAN.md) for complete specification
- Plugin examples in `plugins/` directory
- CLI reference: run `crossbar --help`

### 🙏 Credits

Built with Flutter & Dart by the Crossbar team.
Licensed under AGPLv3 - ensuring all derivatives remain open source.

---

## [Unreleased]

### Planned for v1.1.0
- Additional CLI commands (screenshot, wallpaper, media controls)
- Plugin marketplace with rating system
- Config sync via GitHub Gists
- More example plugins
- Performance optimizations

---

[1.0.0]: https://github.com/verseles/crossbar/releases/tag/v1.0.0
