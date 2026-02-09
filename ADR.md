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
- ADR-013: Platform Theme Detection & Monochrome Icons (2026-02-06)
- ADR-014: Lua-First Sample Plugin System (2026-02-06)
- ADR-015: Mobile Notification & Widget Menu Architecture (2026-02-08)

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

---

## ADR-013: Platform Theme Detection & Monochrome Icons (2026-02-06)

Status: Accepted

Context:
- Flutter's `platformDispatcher.onPlatformBrightnessChanged` does not fire when the user toggles light/dark mode in GNOME Settings. The initial value is read correctly, but runtime changes are not propagated by the GTK event loop.
- Android and GNOME both require monochrome (white + transparent) icons for notifications and status bars.

Decision:
- Use `gsettings monitor org.gnome.desktop.interface color-scheme` as an external process to detect theme changes in real time on Linux. The stdout events propagate brightness to `SettingsService.detectedSystemBrightness`, triggering `notifyListeners()` and a `MaterialApp` rebuild. Flutter's `onPlatformBrightnessChanged` is kept as a fallback.
- Generate monochrome PNGs (white + transparency via ImageMagick `CopyOpacity`) in 5 Android densities (`ic_stat_crossbar.png`). Reference via `AndroidNotificationDetails.icon`. The foreground service Kotlin code also uses `R.drawable.ic_stat_crossbar`.

Consequences:
- App theme and tray icon react in real time to GNOME theme changes.
- Monochrome notification icons work correctly on Android and GNOME.
- Depends on `gsettings` (available on GNOME/GTK; fails silently on KDE/others).
- One additional external process on Linux (minimal overhead, event-driven).
- `AndroidInitializationSettings` must use `@mipmap/ic_launcher`, never a custom drawable (causes silent failure).

---

## ADR-014: Lua-First Sample Plugin System (2026-02-06)

Status: Accepted

Context:
- Crossbar supported 8 languages for sample plugins (Bash, Python, Node.js, Dart, Go, Rust, Lua, YAML). Each plugin maintained 2-8 variants, totaling ~80 files, UI complexity (language dropdown per plugin), and unnecessary assets in the bundle. All 25 plugins already had a working Lua version. Lua is the only language with an embedded interpreter (`lua_dardo`), working on all platforms without external dependencies.

Decision:
- Make official samples Lua-only (remove bash/python/node/dart/go/rust/yaml variants).
- Keep the full `PluginLanguage` enum and execution core intact (users can create plugins in any language).
- Simplify the sample dialog UI (remove language dropdown).
- Scaffolding (`crossbar init`) and marketplace continue supporting all languages.

Consequences:
- ~47 fewer files in the bundle (~43 scripts + 4 schemas).
- Dramatically simplified UI (no language dropdown).
- Smaller APK/bundle size.
- All samples work on all platforms.
- Trade-off: developers who prefer bash/python must create their own plugins.
- Marketplace and user plugin execution are not affected.

---

## ADR-015: Mobile Notification & Widget Menu Architecture (2026-02-08)

Status: Accepted

Context:
- On desktop, plugins display menus in the systray (tray icon submenus). On mobile (Android/iOS), widgets completely ignored plugin menu items, and the Settings section showed irrelevant "System Tray" options (Unified/Separate/SmartCollapse). There was no way to access links or information from menu items on mobile.

Decision:
1. Replace "System Tray" settings section with "Notifications" on mobile, with a `NotificationStyle` option (Combined/Individual/Both). Move "Keep on Background" toggle from Behavior to Notifications on mobile. Desktop keeps System Tray unchanged.
2. Add a more_vert (three dots) button on Android widgets. Clicking opens `WidgetMenuActivity` — a pure Kotlin Activity (no Flutter engine), dialog-themed (`Theme.Translucent.NoTitleBar`), that reads menu items from SharedPreferences and renders a programmatic bottom-sheet. Items with `href` open browser, items with `bash` appear disabled ("Desktop only"). Supports inline submenus, separators, custom colors, and dark mode.
3. Implement `showCombinedNotification()` (InboxStyle, up to 6 lines) and `showIndividualNotification()` (BigTextStyle with expanded menu items). Notifications use `setGroup()` for Android 7+ grouping. Stable IDs via `pluginId.hashCode` for updates without duplication.

Architecture:

```
Widget (RemoteViews) -> PendingIntent -> WidgetMenuActivity
                                           -> SharedPreferences -> plugin_<id> JSON -> menu[]
                                           -> Programmatic UI (LinearLayout + ScrollView)
                                           -> href items: Intent.ACTION_VIEW -> Browser

SchedulerService._onPluginOutput()
    -> check NotificationStyle
    -> combined: NotificationService.showCombinedNotification() -> InboxStyle
    -> individual: NotificationService.showIndividualNotification() -> BigTextStyle
    -> both: both above
```

PendingIntent offsets (to avoid collision):
- Container (open app): `appWidgetId`
- Edit: `appWidgetId + 2000`
- Menu (single plugin widget): `appWidgetId + 4000`
- Menu (large widget row N): `appWidgetId + 5000 + (N * 100)`

Consequences:
- Plugin menu items are accessible on mobile via widgets and notifications.
- `WidgetMenuActivity` does not depend on Flutter engine (instant startup).
- Notifications are user-configurable (Combined/Individual/Both).
- Items with `bash` are disabled on mobile (no shell available).
- `WidgetMenuActivity` builds UI programmatically (no XML layout) — more flexible but less standard.
- Dark mode detected via `Configuration.uiMode`.
