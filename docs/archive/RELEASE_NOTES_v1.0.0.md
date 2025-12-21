# Crossbar v1.0.0 - Initial Release

> **Universal Plugin System for Taskbar/Menu Bar** - Write Once, Run Everywhere

We're thrilled to announce the first public release of **Crossbar**, a revolutionary cross-platform plugin system that brings the power of BitBar/Argos-style scriptable widgets to **all platforms** - desktop and mobile!

## 🎉 What is Crossbar?

Crossbar lets you create custom status bar widgets, tray icons, and home screen widgets using simple scripts in your favorite language. Write once, run everywhere: Linux, macOS, Windows, Android, and iOS.

```python
#!/usr/bin/env python3
# This plugin works WITHOUT MODIFICATION on all 5 platforms!
import subprocess, json

cpu = subprocess.run(['crossbar', '--cpu'], capture_output=True, text=True)
print(json.dumps({
    "icon": "⚡",
    "text": f"{cpu.stdout.strip()}%",
    "menu": [{"text": "Details", "bash": "crossbar --process-list"}]
}))
```

## ✨ Key Features

### 🌍 True Cross-Platform
- **Linux**: System tray with tray_manager
- **macOS**: Menu bar integration (native)
- **Windows**: System tray (native)
- **Android**: Persistent notifications + home widgets
- **iOS**: WidgetKit home screen widgets

One plugin file, five platforms. No modifications needed.

### 6️⃣ Multi-Language Support

Write plugins in the language you prefer:
- **Bash** (.sh) - Universal scripting
- **Python** (.py) - Rich ecosystem
- **Node.js** (.js) - Web-friendly
- **Dart** (.dart) - Native Flutter
- **Go** (.go) - High performance
- **Rust** (.rs) - Safe & fast

### ⚡ Hot Reload

Automatic plugin detection and reload in <1 second. Add, modify, or remove plugins and see changes immediately.

### 🌐 Unified CLI API

47 commands providing system information, network status, media controls, and more:

```bash
crossbar --cpu              # CPU usage
crossbar --memory           # RAM usage
crossbar --battery          # Battery level
crossbar --net-ip           # Local IP
crossbar --media-playing    # Current media
crossbar --audio-volume-set 50  # Control volume
# ...and 41 more!
```

### 🎨 Adaptive Rendering

Same plugin automatically renders as:
- Desktop: Tray icon with menu
- Android: Persistent notification + widget
- iOS: Home screen widget

### 🔒 Secure Configuration

- Declarative JSON configuration
- Auto-generated settings dialogs
- Passwords stored in Keychain/KeyStore (never plaintext)
- 25+ field types (text, password, color, file picker, etc.)

### 🌍 Internationalization

Localized in 10 languages:
🇺🇸 English • 🇧🇷 Portuguese • 🇪🇸 Spanish • 🇩🇪 German • 🇫🇷 French
🇨🇳 Chinese • 🇯🇵 Japanese • 🇰🇷 Korean • 🇮🇹 Italian • 🇷🇺 Russian

## 📦 What's Included

### Example Plugins (24 total)

**Bash** (8):
- CPU, Memory, Battery, Disk monitors
- Network speed tracker
- Docker container status
- Spotify now playing

**Python** (8):
- Weather forecast (OpenWeatherMap)
- Live clock & countdown timer
- Bitcoin price tracker
- GitHub notifications
- Process monitor
- Daily quotes

**Node.js** (6):
- NPM package stats
- IP geolocation
- World clocks
- Pomodoro timer
- Emoji clock

**Dart** (2):
- System info dashboard
- Git repository status

### Core Services

- **PluginManager**: Discovery, lifecycle, concurrent execution (max 10)
- **SchedulerService**: Background auto-refresh with configurable intervals
- **HotReloadService**: File watcher with 500ms debounce
- **MarketplaceService**: GitHub plugin discovery and installation
- **LoggerService**: Rotating logs (5MB max, 5 files)
- **NotificationService**: Cross-platform push notifications
- **TrayService**: System tray with dynamic icons
- **WidgetService**: Home screen widget updates

### Documentation

- **CHANGELOG.md**: Detailed release notes
- **README.md**: Quick start, API reference, examples
- **CONTRIBUTING.md**: Developer guidelines
- **MASTER_PLAN.md**: Complete specification (2,500+ lines)

## 📊 By the Numbers

- **6,661** lines of Dart code
- **38** source files
- **116** tests (114 passing, 2 skipped)
- **>90%** test coverage
- **0** analysis errors
- **47** CLI commands
- **24** example plugins
- **10** languages (i18n)
- **5** platforms supported
- **41MB** Linux binary size

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/verseles/crossbar.git
cd crossbar

# Install dependencies
flutter pub get

# Run on desktop
flutter run -d linux  # or macos, windows

# Build release
flutter build linux --release
```

### Create Your First Plugin

```bash
#!/bin/bash
# ~/.crossbar/plugins/hello.10s.sh
echo "👋 Hello Crossbar!"
echo "---"
echo "System: $(uname -s)"
echo "Refresh | refresh=true"
```

Make it executable: `chmod +x ~/.crossbar/plugins/hello.10s.sh`

## 🎯 Advantages Over BitBar/Argos

| Feature | BitBar/Argos | Crossbar |
|---------|--------------|----------|
| Platforms | macOS/Linux only | Linux + macOS + Windows + Android + iOS |
| Output Formats | Text only | Text + JSON |
| UI Targets | Menu bar only | Tray + Notifications + Widgets |
| CLI API | None | 47 unified commands |
| Configuration | Manual scripting | Declarative JSON |
| Mobile Support | ❌ | ✅ Widgets + Notifications |
| Controls | Read-only | Bidirectional (volume, media, etc.) |
| Hot Reload | Manual | Automatic |

## 🏗️ Architecture

```
crossbar/
├── lib/
│   ├── core/           # Plugin system (manager, parser, runner)
│   ├── models/         # Data models (Plugin, PluginOutput, Config)
│   ├── services/       # Background services (7 services)
│   ├── ui/             # Material Design 3 interface
│   └── l10n/           # 10 language translations
├── bin/
│   └── crossbar.dart   # CLI with 47 commands
├── plugins/            # 24 example plugins
├── test/               # 116 unit/integration tests
└── .github/workflows/  # CI/CD pipelines
```

## 🧪 Quality Assurance

- **Unit Tests**: Core functionality coverage
- **Integration Tests**: End-to-end plugin execution
- **Widget Tests**: UI component verification
- **CI/CD**: GitHub Actions for all platforms
- **Code Analysis**: Zero warnings with flutter analyze
- **Code Coverage**: >90% for core modules

## 📄 License

**AGPLv3** - Network Copyleft License

Ensures that:
✅ Free to use, modify, and distribute
✅ All derivatives remain open source
✅ SaaS deployments must share code
✅ Community improvements benefit everyone

## 🗺️ Roadmap

### v1.1.0 (Next)
- Enhanced marketplace with plugin ratings
- Plugin sandboxing (optional permissions)
- Config sync via GitHub Gists
- Additional CLI commands (screenshot, wallpaper)
- Performance optimizations

### v2.0.0 (Future)
- Opt-in telemetry (OpenTelemetry)
- Package managers (Homebrew, Snap, winget, AUR)
- Theme customization beyond dark/light
- Voice commands integration
- Remote plugins (server-side execution)
- Full-screen widgets

## 🙏 Acknowledgments

Inspired by:
- **BitBar** by Mat Ryer - The original macOS menu bar plugin system
- **Argos** by Philipp Emanuel Weidmann - BitBar for Linux

Built with:
- **Flutter** 3.35+ - Google's UI toolkit
- **Dart** 3.10+ - Client-optimized language

## 🤝 Get Involved

- ⭐ **Star** the repo if you find it useful
- 🐛 **Report bugs** via GitHub Issues
- 💡 **Suggest features** via Discussions
- 🔌 **Share plugins** with the community
- 🌐 **Translate** to your language
- 🧑‍💻 **Contribute** code (see CONTRIBUTING.md)

## 📞 Links

- **Repository**: https://github.com/verseles/crossbar
- **Documentation**: See MASTER_PLAN.md
- **Issues**: https://github.com/verseles/crossbar/issues
- **Discussions**: https://github.com/verseles/crossbar/discussions

---

**Made with ❤️ for the open source community**

Thank you for being part of Crossbar's journey from day one! 🚀
