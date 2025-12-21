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

- See [docs/](docs/) for complete documentation
- Plugin examples in `plugins/` directory
- CLI reference: run `crossbar --help`

### 🙏 Credits

Built with Flutter & Dart by the Crossbar team.
Licensed under AGPLv3 - ensuring all derivatives remain open source.

---

## [1.4.1] - 2025-12-21

### 🔄 Unified Refresh Engine & Architecture Refinement

#### ✨ Features

- **RefreshService**: Introduced a centralized service to manage all plugin and widget updates, ensuring consistent behavior across UI, Tray, and Background.
- **RefreshSource tracking**: New system to identify the trigger of each refresh (timer, manual, boot, or settings change).
- **Synchronous Uptime API**: Added `getUptimeSync` to `SystemApi` and `crossbar.uptime()` to LuaRunner, enabling embedded scripts to access system uptime without async overhead.

#### 🔧 Technical Improvements

- **SchedulerService refactor**: Now focuses solely on scheduling, delegating execution to the unified `RefreshService`.
- **Improved ID tracking**: Resolved race conditions and inconsistencies in tracking plugin update IDs.
- **UI Responsiveness**: Plugins Tab now uses `RefreshService` for manual triggers, ensuring immediate UI feedback and Tray synchronization.
- **IPC Server integration**: `RefreshService` now handles remote refresh requests via IPC consistently.

#### 🏗️ Architecture Update

- Moved refresh logic from `SchedulerService` and `PluginsTab` to `RefreshService`.
- Updated `LuaRunner` to register the new `uptime` sync function.
- Updated `CrossbarBridge` with synchronous `uptime` support.

---

## [1.4.0] - 2025-12-08

### 🌍 Internationalization & Android Polish

#### ✨ Features

- **Complete i18n support**: All 12 languages now include Android-specific strings (`keepOnBackground`, `showPersistentNotification`)
- **Auto theme mode**: Automatic light/dark theme switching based on system preferences
- **GitHub integration**: Dynamic version display and GitHub button in Settings tab
- **Android Start on Boot**: Auto-start Crossbar when system boots (when "Start on Boot" enabled)
- **Foreground Service**: Persistent notification with plugin count, refresh and stop actions
- **Android Widget Styling**: Material 3 design with:
  - Semantic color system (light/dark themes)
  - Rounded corners (24dp) and semi-transparent backgrounds
  - Enhanced typography and Material 3 spacing
  - Custom refresh icon with ripple effect
  - Preview image for widget picker

#### 🔧 Technical Improvements

- **ADR-008**: Finalized Android plugins directory strategy (internal app folder only)
- **System info optimization**: Simplified Android system info to avoid Flutter dependency in CLI
- **Method Channels**: Added native Android integration for system APIs and widget refresh
- **CI optimization**: Optimized builds for target architectures (faster builds)
- **Versioning**: Updated versioning strategy to prioritize minor versions

#### 🐛 Bug Fixes

- Fixed large widget layout handling in `setNoDataState`
- Improved Android widget refresh reliability
- Fixed OutputParser integration for Lua/Dart plugins to parse BitBar attributes
- Corrected asset path for uptime plugin

---

## [1.3.4] - 2025-12-08

### 🔧 Bug Fixes

- **Corrected version numbering**: Fixed v1.3.4 version numbering in pubspec.yaml

---

## [1.3.3] - 2025-12-07

### 📱 Android UX & Integration

#### ✨ Features

- **Android Boot Receiver**: Implements `BootReceiver.kt` to intercept BOOT_COMPLETED
- **Foreground Service**: Persistent notification with NotificationChannel and ongoing status
- **Auto-start integration**: Settings service integration via Method Channel for Start on Boot
- **Notification permissions**: Added permission request for Android 13+

#### 📚 Documentation

- Added ADR-007 for Android system info via `/proc`
- Updated roadmap with Android UX & Integration tasks

---

## [1.3.2] - 2025-12-07

### 🔧 Android System Improvements

#### 🔧 Technical Fixes

- **Simplified Android system info**: Removed Flutter dependency from CLI to fix AOT compilation
- **Method Channels**: Added native Android support for system info and widget refresh
- **Battery API**: Removed battery_plus from system_api to fix AOT compilation
- **Build optimization**: Optimized Android build speed for ARM64 targets

#### 🧪 Testing

- Added unified contract tests for multi-language sample plugins
- Added Android support for system APIs and Lua plugin tests
- Tagged contract tests as hardware to skip in CI

---

## [1.3.1] - 2025-12-07

### 🔧 UX Fixes & Plugin Management

#### ✨ Features

- **Linux Desktop Integration**:

  - `make install/uninstall` for easy Linux installation (~/.local/)
  - Auto-start desktop entry support
  - GNOME dock icon association via APPLICATION_ID
  - Icon system with rounded corners (squircle style)
  - Proper WM_CLASS configuration for window manager

- **Plugin Management UX**:

  - Double-click to delete (requires two clicks in 3s)
  - Edit button opens plugin in system default editor
  - Copy live output button
  - Copy last error button
  - Auto-refresh of list and tray after closing Sample Plugins dialog

- **Sample Plugins Dialog**:
  - Responsive grid layout (2 columns >700px, 3 columns >1000px)
  - Multiple language variants support
  - Language indicator with checkmarks
  - Compact card design

#### 🐛 Bug Fixes

- CPU output unified (returns raw number, plugins add %)
- Fixed window icon loading via relative paths
- Added tray tooltip with "Crossbar" title
- Android notification permission request
- Updated CPU test to expect number without %

---

## [1.3.0] - 2025-12-07

### 🌍 Universal Plugins (Multi-Runner Architecture)

#### ✨ Major Features

**CrossbarBridge - Unified API**:

- Cross-platform API exposing System, Network, Utils, Time, and Environment APIs
- 25+ methods: `cpu()`, `memory()`, `battery()`, `web()`, `time()`, `date()`, `ping()`, etc.
- Works on ALL platforms (desktop + mobile)
- Global instance accessible in plugins

**Multi-Runner Architecture**:

- **LuaRunner**: Embedded Lua 5.3 via lua_dardo (zero external deps)
- **DartRunner**: Interpreted Dart plugins via dart_eval (mobile-friendly)
- **DeclarativeRunner**: YAML-based plugins with template engine
- **ScriptRunner**: Native scripts (bash, python, node, go, rust)
- **PluginExecutor**: Unified router for all runner types

**36 Universal Plugins**:

- 6 plugin types × 6 languages = 36 example plugins
- Re-written to use Crossbar API instead of direct system calls
- Categories: clock, cpu, battery, memory, weather, bitcoin
- Full mobile compatibility (Lua + Dart interpreters)

**crossbar_api Package**:

- Standalone Dart package for compiled plugins
- Supports external packages and FFI
- IntelliSense/Autocomplete support
- Maximum performance for desktop plugins

**YAML Plugins**:

- Ultra-portable declarative plugins
- HTTP, system, exec, and static providers
- Template engine with `${variable}` interpolation
- Environment variable support

#### 🔧 Technical Improvements

- **ADR-006**: Universal Synchronous API for embedded scripting
- **ADR-003**: QuickJS removed (conflicted with CLI requirements)
- **ADR-002**: Lua embedded interpreter for universal plugins
- **ADR-001**: Unified CLI binary (crossbar + crossbar-gui)
- **ADR-004**: GNOME desktop integration with APPLICATION_ID
- **ADR-005**: Linux icon with rounded corners

---

## [1.2.0] - 2025-12-07

### 📱 Mobile Mastery (Android & iOS Widgets)

#### ✨ Android Native Implementation

- **Widget layouts**: Created XML layouts for 1x1, 2x1, and 4x4 widgets
- **Kotlin Provider**: `CrossbarWidgetProvider.kt` with RemoteViews
- **Widget backgrounds**: Theme-aware drawable resources
- **Widget info**: Configuration files for widget picker
- **Android Manifest**: Registered receiver and provider

#### ✨ iOS Native Implementation (WidgetKit)

- **SwiftUI Views**: Functional TimelineProvider for widget updates
- **App Groups**: Configured shared data between Runner and Widget targets
- **Adaptive layouts**: Support for systemSmall and systemMedium widgets
- **Documentation**: Complete iOS widget setup guide

#### 🔧 Technical Features

- **Widget Service**: Serializes PluginOutput for native consumption
- **Scheduler Integration**: Auto-updates widgets after plugin execution
- **Background Sync**: Headless task support for Android (future enhancement)

---

## [1.1.0] - 2025-12-07

### ⚙️ Configuration Engine

#### ✨ Complete Configuration System

- **PluginConfigService**: Full CRUD for plugin configurations
- **Secure storage**: flutter_secure_storage for password fields
- **Environment injection**: Auto-injects config values as ENV vars
- **Schema validation**: JSON schema validation for plugin configs
- **UI integration**: Auto-generated config dialogs from schema

#### 🔧 Technical Implementation

- **Schema format**: `.schema.json` for config definitions
- **Values storage**: `~/.crossbar/configs/` for user data
- **Plugin binding**: Automatic config detection and loading
- **Secret handling**: Separate secure storage for password fields
- **Environment building**: Seamless injection into plugin execution

#### 🧪 Testing

- **Unit tests**: PluginConfigService with encryption and I/O
- **Functional tests**: End-to-end config save → execute → output verification

---

## [1.0.1] - 2025-12-01

### 🐛 Hotfix Release

#### 🔧 Critical Fixes

- Fixed startup crash on some Linux distributions
- Corrected plugin discovery path in development mode
- Updated dependency constraints for Flutter 3.38.3

---

[1.4.1]: https://github.com/verseles/crossbar/releases/tag/v1.4.1
[1.4.0]: https://github.com/verseles/crossbar/releases/tag/v1.4.0
[1.3.4]: https://github.com/verseles/crossbar/releases/tag/v1.3.4
[1.3.3]: https://github.com/verseles/crossbar/releases/tag/v1.3.3
[1.3.2]: https://github.com/verseles/crossbar/releases/tag/v1.3.2
[1.3.1]: https://github.com/verseles/crossbar/releases/tag/v1.3.1
[1.3.0]: https://github.com/verseles/crossbar/releases/tag/v1.3.0
[1.2.0]: https://github.com/verseles/crossbar/releases/tag/v1.2.0
[1.1.0]: https://github.com/verseles/crossbar/releases/tag/v1.1.0
[1.0.1]: https://github.com/verseles/crossbar/releases/tag/v1.0.1
[1.0.0]: https://github.com/verseles/crossbar/releases/tag/v1.0.0
