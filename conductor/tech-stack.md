# Technology Stack - Crossbar

## Core Technologies
*   **Primary Language:** Dart (3.10.0+)
*   **Main Framework:** Flutter (3.38.3+)
*   **Architecture:** Monorepo with separated packages (`crossbar_core`, `crossbar_cli`, `crossbar_api`).

## Platforms & Integrations
*   **Desktop (Linux, Windows, macOS):**
    *   System Tray integration via `tray_manager`.
    *   Native runners (GTK, Cocoa, Win32).
*   **Mobile (Android, iOS):**
    *   **Core Reliance:** Heavy reliance on **Home Screen Widgets** and **Persistent Notifications** for user interaction (no traditional app UI focus).
    *   **Android:** Kotlin/Android Native Bridge, XML Layouts, Broadcast Receivers.
    *   **iOS:** SwiftUI/WidgetKit, App Groups.
    *   **Bridge:** `home_widget` for Flutter <-> Native Widget communication.

## Plugin Ecosystem
*   **Embedded Runner:** Lua (`lua_dardo`) for universal, dependency-free plugins.
*   **External Runners:** Bash, Python, Node.js, Rust, Go (Desktop only).
*   **Configuration:** JSON Schema + `flutter_secure_storage` for credentials.

## Infrastructure & Tools
*   **Build & Test System:** `Makefile` (wraps build, analysis, and test commands like `make precommit` and `make coverage`).
*   **CI/CD:** GitHub Actions (Multi-platform builds).
*   **Testing:** `flutter test`, `codecov` integration.
