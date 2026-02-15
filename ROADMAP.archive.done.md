# Crossbar - Completed Epics Archive

> Epics moved here from ROADMAP.md after completion to keep the active roadmap focused.
> Each section preserves the original task breakdown and completion status.

---

## Epic v1.1.0: The Configuration Engine (Completed)

**Objective:** Allow plugins to declare configurations (JSON), users to fill them (UI), and the system to inject them (ENV vars) securely.

### Phase 1: Persistence & Security
- [x] Create Service: `lib/services/plugin_config_service.dart`
- [x] Implement `loadValues(pluginId)` reading from `~/.crossbar/configs/`
- [x] Implement `saveValues(pluginId, map)` writing JSON
- [x] Integrate `flutter_secure_storage` for `type: password` fields
- [x] Link Plugin: verify existence of `[plugin].config.json` in `plugin_manager.dart`
- [x] Unit Test: `test/unit/services/plugin_config_service_test.dart`

### Phase 2: Variable Injection
- [x] Update Runner: inject `PluginConfigService` in `script_runner.dart`
- [x] Merge loaded values into `environment` map for `Process.start`
- [x] Functional Test: validate env vars appear in STDOUT

### Phase 3: UI Connection
- [x] Add "Configure" button in plugins_tab if `plugin.config != null`
- [x] Load current values before opening dialog
- [x] Call `saveValues` on `onSave` callback

---

## Epic v1.2.0: Mobile Mastery - Widgets & Services (Completed)

**Objective:** Make Crossbar a first-class citizen on Android and iOS using `home_widget`.

### Phase 1: Android Native (XML & Receiver)
- [x] XML Layouts: small (1x1), medium (2x1), large (list/grid)
- [x] Kotlin Provider: `CrossbarWidgetProvider` extending `HomeWidgetProvider`
- [x] AndroidManifest registration

### Phase 2: iOS Native (WidgetKit)
- [x] XCode Target: Widget Extension
- [x] App Groups configuration
- [x] SwiftUI View: `CrossbarWidget.swift` with TimelineProvider

### Phase 3: Widget Service Logic
- [x] Serialization in `widget_service.dart`
- [x] Background Sync via WorkManager (15-minute periodic)
- [x] Supports Lua, YAML, and Dart plugins

---

## Epic v1.4.0: API & Marketplace Completion (Completed)

**Objective:** Fill CLI gaps and make Marketplace functional.

### Phase 1: CLI Gaps
- [x] Geolocation: IP geolocation, geocoding, reverse geocoding via Nominatim
- [x] QR Code: ASCII and PNG base64 generation
- [x] Screenshot: Multi-platform API (gnome-screenshot/scrot/spectacle/PowerShell/screencapture)

### Phase 2: Marketplace Engine
- [x] GitHub API search via `api.github.com`
- [x] Cache for rate limiting prevention
- [x] Install command: clone/download, validate, copy, chmod +x

---

## Epic v1.8.1: Plugin Display Titles (Completed)

- [x] User-customizable title override with fallback to default name (commit: 969c394)

---

## Epic v1.9.1: Code Quality & Robustness (Completed)

**Objective:** Resolve technical debt from code review (commits 32faafb..73d8515).

### Phase 1: Resource Management
- [x] LRU Cache for `_webCache` in LuaRunner (100 entries max)
- [x] Android WidgetLogStore rotation (200 lines FIFO)
- [x] Empty Discovery Guard documentation

### Phase 2: Test Coverage Expansion
- [x] Output Parser edge cases (97.5% coverage)
- [x] Widget tests for plugins_tab
- [x] Web cache persistence integration test

### Phase 3: Code Organization
- [x] Move `customTitleKey` to Core
- [x] Cache compression evaluation
- [x] Widget Log Storage abstraction (MemoryLogStore/FileLogStore)

**Success Metrics:** Coverage 44.3% (target 35%), zero memory leaks in 24h+ runs.

---

## Epic v1.13.0: Mobile Notifications & Widget Menus (Completed)

**Objective:** Make plugin menu items accessible on mobile via widgets and configurable notifications.

### Phase 1: Settings Mobile - Notifications Section
- [x] NotificationStyle enum (combined/individual/both)
- [x] Settings UI: "System Tray" replaced by "Notifications" on mobile
- [x] i18n keys added

### Phase 2: Widget Menu Button + WidgetMenuActivity
- [x] ic_more_vert.xml vector drawable
- [x] Layouts updated with menu button
- [x] WidgetMenuActivity.kt: pure Kotlin Activity, dialog-themed
- [x] CrossbarWidgetBase.kt: menu detection and PendingIntent setup

### Phase 3: Combined + Individual Notifications
- [x] NotificationService: showCombinedNotification (InboxStyle) + showIndividualNotification (BigTextStyle)
- [x] SchedulerService integration with NotificationStyle
- [x] Group notifications and stable IDs
