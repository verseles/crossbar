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
  - Repository mirror: `bin/crossbar.dart` (same launcher logic)
  - Behavior: no args launches GUI (minimized), `gui` launches visible GUI, other args run CLI commands
- `crossbar-gui` (Flutter GUI)
  - Entry: `lib/main.dart`
- `crossbar_tray_daemon` (Linux only)
  - Entry: `bin/crossbar_tray_daemon.dart`
  - Spawns one daemon per plugin to create independent tray icons

### Packages

1. `crossbar_core`
   - Pure Dart (no `dart:ui`)
   - Shared models: `Plugin`, `PluginOutput`, `PluginConfig`
   - Output parsing: `OutputParser` (JSON or BitBar)
   - Embedded Lua runner: `LuaRunner` (via `lua_dardo`)
   - Plugin API bridge: `CrossbarBridge` + `AndroidBridgeInterface`
   - Core APIs: `SystemApi`, `NetworkApi`, `MediaApi`, `UtilsApi`

2. `crossbar_cli`
   - CLI package compiled into the `crossbar` binary
   - Command registry in `packages/crossbar_cli/lib/src/commands`
   - CLI handler: `packages/crossbar_cli/lib/src/cli_handler.dart`
   - CLI-only plugin discovery: `PluginManagerCli`
   - JSON/XML output helpers in `packages/crossbar_cli/lib/src/cli_utils.dart`

3. `crossbar_api`
   - SDK for authors of compiled Dart plugins
   - Type-safe API surface for system/network/utility access
   - See `packages/crossbar_api/README.md`

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

1. Initialize Flutter and inject `AndroidNativeBridge` into `CrossbarBridge`
2. Initialize `LoggerService`, `WindowService`, `SettingsService`
3. Start `IpcServer` on `localhost:48291`
4. Discover plugins via `PluginManager`
5. Initialize `TrayService`
6. Start `SchedulerService` (which uses `RefreshService`)
7. Initialize `HotReloadService`

### Key Services

- `RefreshService`: single source of truth for plugin execution + output cache
- `SchedulerService`: schedules periodic runs and delegates execution to `RefreshService`
- `TrayService`: unified and separate tray modes
- `WidgetService`: HomeWidget sync for Android/iOS widgets
- `BackgroundService`: WorkManager-based background updates on Android
- `PluginConfigService`: schema-based config persistence and secure storage
- `MarketplaceService`: plugin discovery/installation via GitHub
- `IpcServer`: local HTTP control surface for UI and external tools
- `HotReloadService`: file watcher for plugins/config changes
- `NotificationService`: system notifications + Android foreground service channel
- `WindowService`: desktop window lifecycle
- `LoggerService`: rotating log files under `~/.crossbar/logs`
- `DebugLogsPage`: in-app log viewer with widget-native log section

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
crossbar/
├── bin/
│   ├── crossbar.dart
│   └── crossbar_tray_daemon.dart
├── lib/
│   ├── main.dart
│   ├── core/
│   ├── services/
│   ├── ui/
│   └── cli/
├── packages/
│   ├── crossbar_core/
│   ├── crossbar_cli/
│   └── crossbar_api/
├── android/
├── ios/
├── linux/
├── macos/
├── windows/
├── plugins/
├── docs/
├── test/
└── Makefile
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
