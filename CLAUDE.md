# Claude Context - Crossbar Project

> **Context file for future Claude sessions on the Crossbar project**
> Last updated: December 1, 2025

## Project Overview

**Crossbar** is a Universal Plugin System for Taskbar/Menu Bar - a cross-platform alternative to BitBar/Argos built with Flutter.

- **Version**: 1.0.0 (released)
- **Repository**: verseles/crossbar
- **Branch**: main
- **Language**: Dart 3.10+ / Flutter 3.38+
- **License**: AGPLv3

## Project Status

### Completed (v1.0.0 + v1.1.0 Features)

All 7 phases from MASTER_PLAN.md + 10 sprints from ROADMAP.md are **100% complete**:

**Original Phases:**
1. **Phase 1**: Core & CLI Foundation (75+ commands, 6 languages)
2. **Phase 2**: Desktop GUI (Material Design 3, 3 tabs)
3. **Phase 3**: Mobile & Widgets (notifications, scheduling)
4. **Phase 4**: Extended CLI & Services (marketplace, logging)
5. **Phase 5**: Example Plugins & i18n (32 plugins, 10 languages)
6. **Phase 6**: Hot Reload & CI/CD (file watcher, GitHub Actions)
7. **Phase 7**: Release & Documentation (CHANGELOG, README, ROADMAP)

**Additional Sprints (from ROADMAP.md):**
- **Sprint 1-4**: Media controls, system controls, Bluetooth/VPN, utilities (32 new CLI commands)
- **Sprint 5**: Go & Rust example plugins (8 plugins)
- **Sprint 6**: Plugin scaffolding (`init`, `install` commands)
- **Sprint 7**: IPC Server (localhost:48291 for GUI ↔ background)
- **Sprint 8**: Documentation (4 comprehensive docs)
- **Sprint 9**: CI/CD improvements (Codecov integration)
- **Sprint 10**: Docker/Podman infrastructure

**CI Status**: All 5 platforms building successfully

## Critical Technical Decisions

### Flutter & Dart Versions

**IMPORTANT**: CI requires exact Flutter 3.38.3 (not 3.38.0 or 3.35.0)

- **Local dev**: Flutter 3.38.3, Dart 3.10.1
- **CI/CD**: Flutter 3.38.3 (in both ci.yml and release.yml)
- **Reason**: Flutter 3.38.0 ships Dart 3.10.0-290.4.beta (pre-release), which fails `^3.10.0` constraint

### Dual-Mode Execution (GUI + CLI)

**Key Feature**: The main `crossbar` executable supports both GUI and CLI modes via a launcher architecture.

**Architecture** (3 binaries in one bundle):
- `crossbar` - Launcher (routes to GUI or CLI)
- `crossbar-gui` - Flutter GUI application
- `crossbar-cli` - Pure Dart CLI (no GTK dependencies)

**How it works**:
- `bin/launcher.dart` checks for command-line arguments on startup
- **No arguments** → Executes `crossbar-gui` (Flutter app)
- **With arguments** → Executes `crossbar-cli` (pure Dart, no GTK warnings)

**Usage**:
```bash
./crossbar              # GUI mode (launches window)
./crossbar --cpu        # CLI mode (prints CPU usage, no GTK warnings)
./crossbar --help       # CLI mode (shows help)
```

**Implementation**:
- `bin/launcher.dart`: Routes to appropriate binary based on args
- `bin/crossbar.dart`: CLI entry point (pure Dart)
- `lib/main.dart`: GUI-only entry point (Flutter)
- `lib/cli/cli_handler.dart`: Contains all CLI commands

**Why this architecture**:
- Flutter Linux builds initialize GTK even before checking arguments
- This caused GTK theme parsing warnings in CLI mode
- Pure Dart CLI (`dart compile exe`) has no GTK dependencies
- Launcher provides seamless single-command UX

### Linux Build Dependencies

Required packages for Ubuntu CI runners:
```bash
clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev libsecret-1-dev libayatana-appindicator3-dev
```

**Why each dependency**:
- `libsecret-1-dev`: Required by flutter_secure_storage_linux
- `libayatana-appindicator3-dev`: Required by tray_manager (system tray)

**Common mistake**: Forgetting `libayatana-appindicator3-dev` causes cryptic CMake error

### Android Build Configuration

**Core library desugaring** is REQUIRED:

```kotlin
// android/app/build.gradle.kts
compileOptions {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
    isCoreLibraryDesugaringEnabled = true  // ← CRITICAL
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
```

**Why**: flutter_local_notifications 17.2.4+ requires it for AAR metadata compatibility

### CMake Configuration (Linux)

```cmake
# linux/CMakeLists.txt
target_compile_options(${TARGET} PRIVATE -Wall -Wno-deprecated-declarations -Wno-deprecated-literal-operator)
```

**Why**: Suppress deprecation warnings that would fail build with `-Werror`

## Key Files & Structure

```
crossbar/
├── MASTER_PLAN.md          # Authoritative specification (DO NOT MODIFY)
├── CHANGELOG.md            # Detailed release history
├── README.md               # User-facing documentation
├── ROADMAP.md              # Future features and roadmap (10 sprints complete)
├── CONTRIBUTING.md         # Developer guidelines
├── SECURITY.md             # Security policy & vulnerability reporting
├── RELEASE_NOTES_v1.0.0.md # GitHub release notes
├── docs/
│   ├── api-reference.md    # Complete CLI API (75+ commands)
│   ├── plugin-development.md # Tutorial for all 6 languages
│   └── config-schema.md    # 25+ field types documentation
├── lib/
│   ├── core/               # Plugin system (manager, parser, runner)
│   │   └── api/            # Media, System, Network, Utils APIs
│   ├── models/             # Data models
│   ├── services/           # 8 background services (including IPC server)
│   ├── ui/                 # Material Design 3 interface
│   ├── cli/                # CLI implementation (75+ commands)
│   └── l10n/               # 10 language ARB files
├── bin/
│   ├── crossbar.dart       # CLI entry point
│   └── launcher.dart       # GUI/CLI router
├── plugins/                # 32 example plugins (6 languages)
├── test/                   # 289 tests (286 passing, 3 skipped)
├── docker/
│   ├── Dockerfile.linux    # Linux build container
│   └── Dockerfile.android  # Android build container
├── docker-compose.yml      # Docker compose (5 services)
├── podman-compose.yml      # Podman compose (5 services)
└── .github/workflows/      # CI/CD pipelines
```

## Services Architecture

8 background services in `lib/services/`:

| Service | Purpose |
|---------|---------|
| `tray_service.dart` | System tray integration |
| `notification_service.dart` | Cross-platform notifications |
| `scheduler_service.dart` | Plugin auto-refresh scheduling |
| `widget_service.dart` | Home screen widgets (mobile) |
| `marketplace_service.dart` | GitHub plugin discovery |
| `logger_service.dart` | Rotating log files |
| `hot_reload_service.dart` | File watcher (500ms debounce) |
| `ipc_server.dart` | HTTP API on localhost:48291 |

### IPC Server Endpoints

```
GET  /health              # Health check
GET  /status              # App status
GET  /plugins             # List all plugins
GET  /plugins/:id         # Get plugin details
PUT  /plugins/:id/enable  # Enable plugin
PUT  /plugins/:id/disable # Disable plugin
PUT  /plugins/:id/toggle  # Toggle plugin state
POST /plugins/refresh     # Refresh all plugins
POST /plugins/:id/run     # Run specific plugin
```

## Test Coverage

- **289 total tests**: 286 passing, 3 skipped
- **Coverage**: ~46% (realistic for platform-dependent code)
- **CI Threshold**: 44% (fail build if below)
- **Skipped tests**:
  - `NetworkApi.getPublicIp`: Requires network access
  - `NetworkApi.setWifi`: Requires system permissions
  - `NetworkApi.getPingResult`: Requires network access

**Note**: Coverage is lower than typical because much of the codebase consists of platform-specific code (MPRIS, PulseAudio, D-Bus, GTK, macOS AppleScript, Windows PowerShell) that cannot be unit tested without mocking system services.

## Build Status by Platform

| Platform | CI Status | Notes |
|----------|-----------|-------|
| Linux | Built | 41MB bundle |
| macOS | Built | Requires macOS runner |
| Windows | Built | Requires Windows runner |
| Android | Built | APK generated |
| iOS | Structure ready | Not built (requires Xcode) |

## Plugin System

**What works**:
- Bash, Python, Node.js, Dart, Go, Rust plugins
- BitBar text format parsing
- JSON output format
- XML output format (enterprise)
- Hot reload (500ms debounce)
- Refresh intervals from filename (e.g., `cpu.10s.sh`)
- Plugin scaffolding (`crossbar init`)
- GitHub installation (`crossbar install`)

**What's missing**:
- Plugin sandboxing (runs with full permissions)
- Plugin signing/verification
- Plugin versioning in marketplace
- Plugin dependency management

## CLI Commands Summary

**75+ commands** organized by category:

| Category | Commands |
|----------|----------|
| System | `--cpu`, `--memory`, `--disk`, `--battery`, `--uptime`, `--os` |
| Network | `--net-ip`, `--net-status`, `--wifi-ssid`, `--web` |
| Media | `--media-play`, `--media-pause`, `--audio-volume`, `--screen-brightness` |
| Bluetooth | `--bluetooth-status`, `--bluetooth-on`, `--bluetooth-off`, `--bluetooth-devices` |
| Power | `--power-sleep`, `--power-restart`, `--power-shutdown` |
| Screenshot | `--screenshot`, `--screenshot --clipboard` |
| Wallpaper | `--wallpaper-get`, `--wallpaper-set` |
| Notifications | `--notify`, `--dnd-status`, `--dnd-set` |
| Open/Launch | `--open-url`, `--open-file`, `--open-app` |
| Utilities | `--hash`, `--uuid`, `--random`, `--time`, `--date` |
| Plugin Mgmt | `init`, `install`, `list`, `enable`, `disable` |
| Output | `--json`, `--xml` flags for structured output |

Full documentation: `docs/api-reference.md`

## Docker/Podman Development

### Quick Start

```bash
# Using Docker
make docker-build    # Build images
make docker-shell    # Interactive shell
make docker-test     # Run tests
make docker-linux    # Build Linux release

# Using Podman (preferred on Fedora/RHEL)
make podman-build
make podman-shell
make podman-test
make podman-linux

# Auto-detect compose tool
make container-build
make container-test
```

### Services Available

| Service | Purpose |
|---------|---------|
| `flutter-linux` | Interactive dev environment |
| `flutter-android` | Android dev with SDK |
| `flutter-test` | Automated test runner |
| `flutter-build` | Linux release builds |
| `flutter-apk` | Android APK builds |

## Common Issues & Solutions

### Issue: CI fails with "Dart SDK version X.Y.Z doesn't satisfy ^3.10.0"

**Solution**: Update Flutter version in `.github/workflows/*.yml` to exactly `3.38.3`

### Issue: Linux build fails with "libsecret-1 not found"

**Solution**: Add to apt-get install line:
```bash
libsecret-1-dev libayatana-appindicator3-dev
```

### Issue: Android build fails with "requires core library desugaring"

**Solution**: Enable in `android/app/build.gradle.kts`:
```kotlin
isCoreLibraryDesugaringEnabled = true
```

### Issue: Coverage below threshold

**Solution**: Current threshold is 44%. Platform-dependent code (media, bluetooth, screenshots) can't be easily unit tested. Focus tests on:
- Models (`lib/models/`) - easy to test
- Output parser (`lib/core/output_parser.dart`) - pure logic
- Plugin scaffolding (`lib/cli/plugin_scaffolding.dart`)

### Issue: Tests pass locally but fail in CI

**Likely causes**:
1. Different Flutter/Dart version
2. Missing platform-specific dependencies
3. Network-dependent tests not skipped
4. File permission issues

## Development Workflow

### Running Tests

```bash
# All tests
flutter test

# With coverage
flutter test --coverage

# Check coverage percentage
lcov --summary coverage/lcov.info

# Specific test file
flutter test test/unit/core/plugin_manager_test.dart
```

### Building

```bash
# Linux (with launcher architecture)
make linux

# Or manually:
flutter build linux --release
mv build/linux/x64/release/bundle/crossbar build/linux/x64/release/bundle/crossbar-gui
dart compile exe bin/crossbar.dart -o build/linux/x64/release/bundle/crossbar-cli
dart compile exe bin/launcher.dart -o build/linux/x64/release/bundle/crossbar

# Android
flutter build apk --release

# Test CLI after build
make test-cli
```

### Code Quality

```bash
# Analyze (no warnings allowed in CI)
flutter analyze --no-fatal-infos

# Format
dart format lib/ test/ bin/

# Check for issues
flutter pub outdated
```

## Git Workflow

- **Main branch**: `main`
- **Tag format**: `v1.0.0`, `v1.1.0`, etc.
- **Commit style**: Conventional Commits (feat, fix, docs, ci, etc.)
- **Co-authored commits**: Do NOT add co-authors (user preference)

### Post-Push CI Monitoring (IMPORTANT)

After every `git push`, you MUST:
1. Use `gh run list --limit 1` to get the run ID
2. Monitor with `gh run watch <id> --exit-status` in **background** (pipeline is long, ~8min)
3. Use `sleep` + `BashOutput` to periodically check progress and avoid shell timeout
4. If CI fails, immediately investigate with `gh run view <id> --log-failed` and fix
5. Keep iterating until CI passes - don't leave broken builds

**Exception**: Skip CI monitoring when ONLY documentation/text files were changed:
- `*.md` (markdown files)
- `CLAUDE.md`, `README.md`, `CHANGELOG.md`, `ROADMAP.md`, etc.
- `LICENSE`, `.gitignore`, comments-only changes

These don't affect the build, so monitoring is unnecessary.

## CI/CD

### GitHub Actions Workflows

1. **ci.yml**: Runs on push to main/develop
   - test job: analyze + test + coverage check (44% min)
   - build jobs: Linux, macOS, Windows, Android (parallel)
   - Codecov integration

2. **release.yml**: Runs on tags `v*`
   - Multi-platform matrix builds
   - Artifact compression and upload
   - Auto-creates GitHub releases

### Artifacts Generated

- `crossbar-linux`: Linux x64 bundle (tar.gz)
- `crossbar-macos`: macOS universal binary (tar.gz)
- `crossbar-windows`: Windows x64 (zip)
- `crossbar-android`: Android APK

## Important Notes for Future Sessions

1. **DO NOT modify MASTER_PLAN.md** - it's the authoritative spec
2. **Always run flutter analyze before committing** - CI will fail otherwise
3. **Test locally before pushing** - CI takes 5-10 minutes per run
4. **Check Flutter version matches** - local vs CI mismatch causes issues
5. **Plugins are real and functional** - 32 examples in `plugins/` directory
6. **i18n is complete** - 10 languages with 40-70 strings each
7. **Coverage is ~46%** - realistic for platform-dependent code
8. **All 5 platforms build** - Linux, macOS, Windows, Android working in CI
9. **Docker/Podman ready** - containerized dev environment available
10. **IPC server available** - localhost:48291 for external integrations

## Commands Quick Reference

### Git

```bash
gh run list --limit 5              # Check CI runs
gh run view <id>                   # View run details
gh run view <id> --log-failed      # View failed logs
gh run watch <id> --exit-status    # Watch run live
```

### Flutter

```bash
flutter pub get                    # Get dependencies
flutter pub outdated               # Check for updates
flutter analyze                    # Static analysis
flutter test                       # Run tests
flutter build <platform> --release # Build release
```

### Project-Specific

```bash
# Build with launcher architecture
make linux

# Run tests
make test

# Test CLI commands
make test-cli

# Container development
make container-shell

# Update repomix (if exists)
make mix
```

## Success Metrics (Current)

- **GitHub Stars**: 0 (just released)
- **Downloads**: 0 (awaiting release)
- **Open Issues**: 0
- **Contributors**: 1
- **Plugins**: 32 (examples in 6 languages)
- **Tests**: 289 (286 passing, 3 skipped)
- **Coverage**: ~46%
- **CLI Commands**: 75+
- **Languages**: 10 (i18n)
- **CI Status**: Green

---

**For the next session**: Start by reviewing this file, checking CI status with `gh run list`, and reading any new issues on GitHub. All sprints are complete - focus on community requests, bug fixes, or v2.0.0 features from ROADMAP.md.
