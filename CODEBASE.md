# Crossbar Codebase Guide

Welcome to the Crossbar codebase. This document provides a high-level architectural overview to help you navigate the monorepo and understand how the CLI, GUI, and plugin engine fit together.

---

## Architecture Overview

Crossbar is a monorepo with a Flutter application and multiple pure Dart packages. The build produces three binaries:

- `crossbar`: unified CLI + launcher
- `crossbar-gui`: Flutter GUI application
- `crossbar_tray_daemon`: Linux tray daemon for multi-icon mode

### Binaries and Entrypoints

- `crossbar` (CLI + launcher)
  - Build target: `packages/crossbar_cli/bin/crossbar.dart`
  - Function: CLI unified + launcher. No args or explicit `gui` command launches the GUI. Other args execute CLI commands via `handleCliCommand`.
- `crossbar-gui` (Flutter GUI)
  - Entry: `lib/main.dart`
  - Function: Graphical interface, Tray, and Services.
- `crossbar_tray_daemon` (Linux only)
  - Entry: `bin/crossbar_tray_daemon.dart`
  - Spawns one daemon per plugin to create independent tray icons via SNI.

### Packages

1. `crossbar_core`
   - Pure Dart (no `dart:ui`). Shared models: `Plugin`, `PluginOutput`, `PluginConfig`.
   - Core runners: `LuaRunner` (embedded), `OutputParser`.
   - Bridge APIs: `CrossbarBridge`, `SystemApi`, `NetworkApi`.
2. `crossbar_cli`
   - Compiled into the `crossbar` binary.
   - Depends on `crossbar_core`.
   - Registry and handler for hardware, network, and utility CLI commands.
3. `crossbar_api`
   - SDK for authors of compiled Dart plugins.

### Main Application (Flutter)

The root Flutter app provides the GUI, tray integration, widget updates, and background services. It depends on `crossbar_core` for models and shared APIs.

---

## Plugin System and Runners

### Discovery and IDs

- Manager: `lib/core/plugin_manager.dart`
- Desktop path: `~/.crossbar/plugins`
- Mobile path: app documents directory + `/plugins` (see `lib/core/paths/platform_paths_flutter.dart`)
- Discovery is recursive and groups files by directory + base name
- Refresh interval parsed from filename suffix (e.g. `cpu.10s.sh`)
- Plugin ID rules:
  - Root files: filename (e.g. `cpu.10s.sh`)
  - Subdirectory groups: directory name (e.g. `plugins/battery/battery.30s.lua` -> `battery`)

### Execution and Runners

- Router: `lib/core/plugin_executor.dart`
- Runners:
  - `LuaRunner` (embedded, all platforms) in `crossbar_core`
  - `DeclarativeRunner` (YAML) in `lib/core/runners/declarative_runner.dart`
  - `ScriptRunner` (bash/python/node/go/rust/dart run) in `lib/core/script_runner.dart`
  - `DartRunner` (dart_eval) exists in `lib/core/runners/dart_runner.dart`, but the executor currently routes `.dart` to `ScriptRunner` for full `dart:io` support

### Output Parsing

- `OutputParser` in `crossbar_core` accepts JSON or BitBar/Argos text
- Nested menus are supported via indented `--` prefixes
- `PluginOutput` includes `trayIcon` for Freedesktop theme icons (Linux)
- Web cache: `WebCacheStore` provides LRU + disk persistence for `crossbar.web`

### Configuration

- Schema: `<plugin>.schema.json` next to the plugin file
- GUI values:
  - Desktop: `~/.crossbar/configs/<pluginId>.json`
  - Mobile: `<app-documents>/configs/<pluginId>.json`
  - Secure storage for password fields
- Optional custom display title stored as `_crossbar_title` in the config values
- CLI values: `~/.crossbar/config/<pluginId>.json` (plain JSON, no secure storage)

---

## Services and Runtime Flow

### Startup (GUI)

Entry: `lib/main.dart`

1. Initialize Flutter and inject `AndroidNativeBridge` into `CrossbarBridge`.
2. Initialize `LoggerService` and `BackgroundService` (Android).
3. Initialize `WindowService` (Lifecycle) and `SettingsService` (Persistence).
4. Start `IpcServer` on `localhost:48291`.
5. Sync/Discover plugins via `SamplePluginsService` and `PluginManager`.
6. Initialize `TrayService` and start `SchedulerService` (delegates to `RefreshService`).
7. Initialize `HotReloadService`.

### Key Services

- `RefreshService`: Single source of truth for plugin execution and output caching.
- `SchedulerService`: Schedules periodic runs and delegates to `RefreshService`.
- `PluginManager`: Central registry for plugin discovery and state management.
- `SettingsService`: Manages application settings and theme detection.
- `TrayService`: Manages tray icon lifecycle (Unified or Separate backends).
- `PluginConfigService`: Handles schema-based configuration and secure storage.
- `WidgetService`: Synchronizes data with Android/iOS home screen widgets.
- `NotificationService`: Manages system notifications and Android foreground services.
- `SamplePluginsService`: Synchronizes default/example plugins to the user's directory.
- `MarketplaceService`: Plugin installation and discovery via GitHub.
- `IpcServer`: HTTP server for inter-process communication.
- `LoggerService`: Rotating log file management.
- `HotReloadService`: Watches for file changes to auto-refresh plugins.

---

## Tray Architecture

- `TrayService` selects the backend via `HybridTrayBackend`
- On Linux, the active backend is `ProcessSpawnTrayBackend` (daemon-per-icon)
- Fallback for other platforms: `LegacyTrayBackend` (single icon via `tray_manager`)
- `SniMultiTrayBackend` exists for StatusNotifierItem support but is not active in the hybrid selection
- Linux daemon: `crossbar_tray_daemon` communicates via stdin/stdout JSON

---

## Platform Notes

### Android

- MethodChannel bridge: `lib/core/api/android_native_bridge.dart`
- Native implementations in `android/app/src/main/kotlin/com/verseles/crossbar`
- Widgets: `CrossbarWidgetSmall/Medium/Large` + XML layouts
- Widget logs: `WidgetLogStore` stored in HomeWidget preferences
- Background updates: `WorkManager` via `BackgroundService`

### iOS

- Widget extension: `ios/CrossbarWidget/CrossbarWidget.swift`
- HomeWidget app group: `group.crossbar.widgets`

### Desktop

- Linux `.desktop` file: `linux/com.verseles.crossbar.desktop`
- Tray icons in `assets/icons/`

---

## Directory Structure

```text
├── assets/
│   ├── icons/                  # Tray and app icons (PNG, SVG, ICO)
│   └── fonts/                  # Custom application fonts
├── bin/                        # Standalone Dart scripts and daemons
├── lib/
│   ├── cli/                    # CLI logic (non-Flutter)
│   ├── core/                   # Core business logic and runners
│   ├── services/               # Singleton application services
│   ├── ui/                     # Flutter widgets and screens
│   └── main.dart               # GUI entrypoint
├── packages/
│   ├── crossbar_core/          # Shared models and runners (Pure Dart)
│   ├── crossbar_cli/           # CLI Command implementations
│   └── crossbar_api/           # Public SDK for plugin authors
├── android/                    # Android-specific native code and layouts
├── ios/                        # iOS-specific native code and WidgetKit
├── linux/                      # Linux-specific runner and .desktop files
├── macos/                      # macOS-specific runner
├── windows/                    # Windows-specific runner
├── plugins/                    # Default and sample plugins
├── docs/                       # Technical documentation and guides
├── test/                       # Unit, widget, and functional tests
└── Makefile                    # Build and development orchestration
```

---

## Testing and Quality

- Static analysis: `make analyze`
- Tests + coverage: `make coverage` (coverage target 35%)
- Builds: `make linux`, `make android`
- Hardware-affecting tests are tagged `hardware` and should be excluded locally

---

## Documentation

- Architectural decisions: `ADR.md`
- Operational rules and context: `AGENTS.md`
- API reference and plugin guides: `docs/`
