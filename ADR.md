# Architecture Decision Records (ADR)

This file consolidates the architectural decisions for Crossbar. Operational rules and project context still live in `AGENTS.md`; if there is any conflict, treat `AGENTS.md` as the source of truth.

## Index

- ADR-001: Unified CLI Binary (2024-12-07) [Superseded]
- ADR-002: Embedded Lua Interpreter (2024-12-07)
- ADR-003: QuickJS Fallback for JavaScript (2024-12-07) [Rejected]
- ADR-004: GNOME Desktop Integration (2024-12-07)
- ADR-005: Separated Icon for Linux (2024-12-07)
- ADR-006: Universal Synchronous API for Embedded Scripting (2024-12-07)
- ADR-007: Android System Info via /proc (2024-12-07) [Deprecated]
- ADR-008: Android Internal Plugins Directory (2024-12-08)
- ADR-009: Unified Refresh Behavior via RefreshService (2025-12-21)
- ADR-010: Android Native APIs via Method Channel (2025-12-21)
- ADR-011: Monorepo with Separate Packages (2025-12-22)
- ADR-012: Multi-Icon Tray Architecture for Linux (2025-12-23)

---

## ADR-001: Unified CLI Binary (2024-12-07)

Status: Superseded by ADR-011

Context:
- The project previously shipped three binaries (launcher, CLI, GUI), which complicated distribution and process spawning.

Decision:
- Merge launcher and CLI into a single `crossbar` binary; keep `crossbar-gui` as the GUI binary.

Consequences:
- Fewer binaries to distribute and manage.
- `crossbar --version` and CLI commands run without extra process hops.
- GUI is still a separate Flutter binary.

---

## ADR-002: Embedded Lua Interpreter (2024-12-07)

Status: Accepted

Context:
- Script-based plugins (bash/python/node) depend on external interpreters and do not work on mobile.

Decision:
- Embed Lua 5.3 via `lua_dardo` for a universal, pure-Dart interpreter.

Consequences:
- Lua plugins run on all platforms (desktop and mobile).
- No external dependencies required.
- Performance trade-off compared to native Node/Python.

---

## ADR-003: QuickJS Fallback for JavaScript (2024-12-07)

Status: Rejected

Context:
- JavaScript plugins needed a mobile-compatible runtime.

Decision:
- Rejected `flutter_js` (QuickJS) because it depends on `dart:ui` and breaks the pure Dart CLI build.

Consequences:
- Desktop JS plugins run via Node.
- Mobile JS plugins are not supported; Lua is the recommended cross-platform alternative.

---

## ADR-004: GNOME Desktop Integration (2024-12-07)

Status: Accepted

Context:
- GNOME dock/taskbar integration was inconsistent due to mismatched application IDs and icons.

Decision:
- Standardize `APPLICATION_ID` (`com.verseles.crossbar`) across:
  - `.desktop` file name and fields
  - icon name and `StartupWMClass`
  - GTK runner WM_CLASS

Consequences:
- Correct icon association on GNOME and compatible desktops.
- Improved dock/taskbar behavior.

---

## ADR-005: Separated Icon for Linux (2024-12-07)

Status: Accepted

Context:
- The transparent icon did not render well across Linux desktop environments.

Decision:
- Generate a Linux-specific icon with rounded corners (`icon_linux.png`).

Consequences:
- More consistent appearance on GNOME and similar environments.
- Icon generation automated in the build pipeline.

---

## ADR-006: Universal Synchronous API for Embedded Scripting (2024-12-07)

Status: Accepted

Context:
- Embedded Lua is synchronous; the original API was entirely async, which complicated Lua access to system data.

Decision:
- Add sync variants to core APIs and expose them via the Lua bridge.

Consequences:
- Lua plugins can use `crossbar.cpu()`, `crossbar.memory()`, etc. synchronously.
- Some calls block the Dart isolate.

---

## ADR-007: Android System Info via /proc (2024-12-07)

Status: Deprecated (superseded by ADR-010)

Context:
- Android tightened access to `/proc` and `/sys`, breaking CPU/battery reads.

Decision:
- Read `/proc/stat`, `/proc/meminfo`, and `/sys/class/power_supply` for Android system info.

Consequences:
- CLI remained pure Dart.
- CPU returned 0% on Android 8+.
- Battery access failed on newer Android releases.

---

## ADR-008: Android Internal Plugins Directory (2024-12-08)

Status: Accepted

Context:
- Plugin storage on Android required a decision between internal storage and external folders (SAF).

Decision:
- Use only internal app storage for plugins.

Consequences:
- Simple, secure implementation.
- Users cannot add plugins manually via file manager on Android.

---

## ADR-009: Unified Refresh Behavior via RefreshService (2025-12-21)

Status: Accepted

Context:
- Refresh logic was split across services, causing inconsistent behavior between UI, tray, and scheduler.

Decision:
- Centralize refresh execution and caching in `RefreshService`.

Consequences:
- Consistent refresh behavior across UI, tray, IPC, and widgets.
- Clearer ownership of plugin outputs.

---

## ADR-010: Android Native APIs via Method Channel (2025-12-21)

Status: Accepted

Context:
- `/proc` and `/sys` access for CPU/battery was blocked by Android security.

Decision:
- Introduce `AndroidNativeBridge` with MethodChannel calls to native APIs (BatteryManager, ActivityManager), plus caching for sync access.

Consequences:
- Battery data works reliably on Android.
- CPU remains unavailable; APIs return 0.0 with a clear limitation.
- Separation keeps the CLI build pure Dart.

---

## ADR-011: Monorepo with Separate Packages (2025-12-22)

Status: Accepted

Context:
- `dart compile exe` could not handle conditional Flutter imports used by the CLI.

Decision:
- Create a monorepo with separate packages:
  - `crossbar_core` for pure Dart shared logic
  - `crossbar_cli` for the CLI binary
  - Flutter app as the root package

Consequences:
- CLI compiles without Flutter dependencies.
- Shared models and APIs live in `crossbar_core`.

---

## ADR-012: Multi-Icon Tray Architecture for Linux (2025-12-23)

Status: Accepted

Context:
- Linux tray APIs allow only a single icon per process in many environments.

Decision:
- Spawn a separate daemon process per plugin to own its own SNI icon.

Consequences:
- Multiple tray icons work on Linux (GNOME/KDE).
- Additional processes are required and capped (default 10).
- Some visual updates depend on user interaction due to SNI limitations.
