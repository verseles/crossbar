# Crossbar Codebase Guide

Welcome to the **Crossbar** codebase. This document provides a high-level architectural overview, mapping the project's structure, core components, and design patterns to help developers navigate and contribute effectively.

---

## 🏗 Architecture Overview

Crossbar is built as a **Monorepo** using Flutter and Dart. It follows a modular architecture designed for maximum portability ("Write Once, Run Everywhere") across Linux, Windows, macOS, Android, and iOS.

### Core Modules (Packages)

The project is divided into specialized packages under the `packages/` directory:

1.  **`crossbar_core`**: The "brain" of the system.
    -   **Pure Dart**: No dependency on `dart:ui` or Flutter widgets.
    -   **Models**: Defines `Plugin`, `PluginOutput`, `PluginConfig`, and `PluginAction`.
    -   **Engine**: Contains `PluginManager` (discovery), `PluginExecutor` (routing), and `RefreshService` (lifecycle).
    -   **Runners**: Implements embedded interpreters like `LuaRunner` (via `lua_dardo`) and `DeclarativeRunner` (YAML).
2.  **`crossbar_cli`**: The command-line interface.
    -   Compiles to a standalone native binary (`crossbar`).
    -   Handles CLI commands (e.g., `crossbar cpu`, `crossbar list`).
    -   Acts as a launcher for the GUI version.
3.  **`crossbar_api`**: Helper library for plugin authors.
    -   Provides type-safe wrappers and utilities for creating high-quality plugins in Dart.

### Main Application (Flutter)

The root project is a Flutter application that provides:
-   **GUI**: Material 3 interface for managing plugins and settings.
-   **Tray System**: Advanced tray management, including the **Multi-Icon SNI architecture** for Linux (ADR-012).
-   **Mobile Integration**: Native bridges for Android and iOS home screen widgets.

---

## 🚀 Plugin System & Runners

Crossbar supports multiple types of plugins, each handled by a specialized `Runner`:

| Runner | Language | Platform | Portability | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **LuaRunner** | `.lua` | All | ⭐⭐⭐⭐⭐ | Embedded (zero dependencies). Recommended for universal plugins. |
| **Declarative** | `.yaml` | All | ⭐⭐⭐⭐⭐ | DSL-based. Great for simple status/menu plugins. |
| **ScriptRunner** | `.sh`, `.py`, `.js` | Desktop | ⭐⭐⭐ | Uses host interpreters. Doesn't work on Mobile. |
| **DartRunner** | `.dart` | Desktop/AOT | ⭐⭐⭐⭐ | High performance. |

### Plugin Discovery
Plugins are discovered in `~/.crossbar/plugins/` (Linux/macOS/Windows) or internal storage (Android/iOS). The discovery logic supports:
-   **Recursive scanning**: Plugins can be grouped in subdirectories.
-   **Shebang detection**: Identifies interpreters for script-based plugins.
-   **Versioning**: Handles update cycles (e.g., `cpu.10s.sh`).

---

## 📱 Platform Specifics

### Mobile (Android & iOS)
-   **Widgets**: Integration via `home_widget` package.
-   **Background**: Periodic execution via `WorkManager` (Android) and `WidgetKit` (iOS).
-   **Native Bridges**: `AndroidNativeBridge` provides access to system info (Battery, Uptime) when standard files are restricted by SELinux (ADR-010).

### Linux (Desktop)
-   **Multi-Icon Tray (ADR-012)**: Uses a daemon-based approach (`crossbar_tray_daemon`) to spawn multiple independent tray icons on GNOME/KDE, bypassing `libappindicator` limitations.

---

## 🛠 Key Services

-   **`RefreshService`**: The unified engine that triggers plugin executions based on timers, manual refreshes, or system events.
-   **`PluginConfigService`**: Manages plugin settings.
    -   **Schemas**: Uses `.schema.json` to generate dynamic configuration UIs.
    -   **Security**: Stores passwords/secrets in the system keyring/secure storage.
-   **`SchedulerService`**: Manages background task scheduling for different platforms.

---

## 📂 Directory Structure

```text
crossbar/
├── bin/                    # Unified Entrypoints (CLI + Launcher)
├── packages/
│   ├── crossbar_core/      # Shared Business Logic & Runners (Pure Dart)
│   ├── crossbar_cli/       # Standalone CLI Executable
│   └── crossbar_api/       # Developer SDK for Dart Plugins
├── lib/
│   ├── main.dart           # Flutter GUI Entrypoint
│   ├── services/           # Singleton Services (Tray, Refresh, Config)
│   ├── ui/                 # Flutter Widgets & Tabs
│   └── core/               # App-specific core logic (Widget Service, Bridge)
├── android/                # Native Android Kotlin/XML (Widgets)
├── ios/                    # Native iOS Swift (WidgetKit)
├── linux/                  # GTK/Runner C++ logic
├── plugins/                # Bundled example plugins (7+ languages)
├── test/                   # Comprehensive Test Suite (Unit, Widget, Integration)
└── docs/                   # ADRs, Specifications, and Guides
```

---

## 🧪 Testing & Quality

-   **Goal**: >60% coverage (excluding generated code).
-   **CI/CD**: GitHub Actions validates builds for 5 platforms on every push.
-   **Pre-commit**: Always run `make analyze` and `make coverage` before committing.
-   **Hardware Tags**: Tests that modify system state (volume, wifi) are tagged with `hardware` and should be excluded in restricted environments.

---

## 📜 Development Guidelines

-   **Portability First**: Prefer Lua for new plugins to ensure they work on mobile.
-   **Async/Sync**: The core uses `Future` (Async), but provides `Sync` variants for embedded interpreters to ensure low latency.
-   **ADRs**: Architecture decisions are documented in `AGENTS.md` and `docs/archive/`. Always check them before introducing major changes.
