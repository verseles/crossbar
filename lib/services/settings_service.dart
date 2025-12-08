import 'dart:io';

import 'package:crossbar/services/logger_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TrayDisplayMode {
  unified,
  separate,
  smartCollapse,
  smartOverflow,
}

/// Theme mode options: light, dark, or system (auto-detect)
enum ThemeModeOption {
  light,
  dark,
  system,
}

class SettingsService extends ChangeNotifier {

  factory SettingsService() => _instance;

  SettingsService._internal();
  static final SettingsService _instance = SettingsService._internal();

  late SharedPreferences _prefs;
  bool _initialized = false;

  // Keys
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyStartWithSystem = 'start_with_system';
  static const String _keyShowInTray = 'show_in_tray';
  static const String _keyLanguage = 'language';
  static const String _keyTrayDisplayMode = 'tray_display_mode';
  static const String _keyTrayClusterThreshold = 'tray_cluster_threshold';

  // Default Values
  static const ThemeModeOption _defaultThemeMode = ThemeModeOption.system;
  static const bool _defaultStartWithSystem = false;
  static const bool _defaultShowInTray = true;
  static const String _defaultLanguage = 'system';
  // NOTE: tray_manager uses a single global tray instance.
  // Using 'unified' mode ensures a single tray icon with submenus for plugins.
  // Other modes (separate, smartCollapse) are reserved for future multi-tray implementations.
  static const TrayDisplayMode _defaultTrayDisplayMode = TrayDisplayMode.unified;
  static const int _defaultTrayClusterThreshold = 3;

  // State
  ThemeModeOption _themeMode = _defaultThemeMode;
  bool _startWithSystem = _defaultStartWithSystem;
  bool _showInTray = _defaultShowInTray;
  String _language = _defaultLanguage;
  TrayDisplayMode _trayDisplayMode = _defaultTrayDisplayMode;
  int _trayClusterThreshold = _defaultTrayClusterThreshold;

  bool get isInitialized => _initialized;

  // Getters
  ThemeModeOption get themeMode => _themeMode;
  
  /// Legacy getter for backwards compatibility
  @Deprecated('Use themeMode instead')
  bool get darkMode => _themeMode == ThemeModeOption.dark;
  bool get startWithSystem => _startWithSystem;
  bool get showInTray => _showInTray;
  String get language => _language;
  TrayDisplayMode get trayDisplayMode => _trayDisplayMode;
  int get trayClusterThreshold => _trayClusterThreshold;

  // Setters
  set themeMode(ThemeModeOption value) {
    if (_themeMode != value) {
      _themeMode = value;
      _saveString(_keyThemeMode, value.name);
      notifyListeners();
    }
  }

  /// Legacy setter for backwards compatibility
  @Deprecated('Use themeMode instead')
  set darkMode(bool value) {
    themeMode = value ? ThemeModeOption.dark : ThemeModeOption.light;
  }

  set startWithSystem(bool value) {
    if (_startWithSystem != value) {
      _startWithSystem = value;
      _saveBool(_keyStartWithSystem, value);
      _updateAutostart(value);
      notifyListeners();
    }
  }

  /// Creates or removes the autostart entry for Linux/freedesktop systems.
  /// The autostart file is placed in ~/.config/autostart/crossbar.desktop
  Future<void> _updateAutostart(bool enable) async {
    // Only applicable on Linux
    if (!Platform.isLinux) return;

    try {
      final homeDir = Platform.environment['HOME'];
      if (homeDir == null) {
        LoggerService().warning('HOME environment variable not set, cannot manage autostart');
        return;
      }

      final autostartDir = Directory('$homeDir/.config/autostart');
      final autostartFile = File('${autostartDir.path}/crossbar.desktop');

      if (enable) {
        // Create autostart directory if it doesn't exist
        if (!await autostartDir.exists()) {
          await autostartDir.create(recursive: true);
        }

        // Create the desktop entry content
        // Try to find the installed executable path
        final localBin = '$homeDir/.local/bin/crossbar';
        final execPath = await File(localBin).exists() 
            ? localBin 
            : 'crossbar'; // Fallback to PATH lookup

        final desktopEntry = '''[Desktop Entry]
Type=Application
Name=Crossbar
Comment=Universal Plugin System for Taskbar/Menu Bar
Exec=$execPath
Icon=crossbar
Terminal=false
StartupWMClass=crossbar
X-GNOME-Autostart-enabled=true
''';

        await autostartFile.writeAsString(desktopEntry);
        LoggerService().info('Autostart entry created at ${autostartFile.path}');
      } else {
        // Remove autostart file if it exists
        if (await autostartFile.exists()) {
          await autostartFile.delete();
          LoggerService().info('Autostart entry removed: ${autostartFile.path}');
        }
      }
    } catch (e, stackTrace) {
      LoggerService().error('Failed to update autostart entry', e, stackTrace);
    }
  }


  set showInTray(bool value) {
    if (_showInTray != value) {
      _showInTray = value;
      _saveBool(_keyShowInTray, value);
      _updateAndroidForegroundService(value);
      notifyListeners();
    }
  }

  /// Starts or stops the Android foreground service based on the setting.
  Future<void> _updateAndroidForegroundService(bool enable) async {
    if (!Platform.isAndroid) return;

    try {
      const channel = MethodChannel('com.verseles.crossbar/system');
      if (enable) {
        await channel.invokeMethod('startForegroundService');
        LoggerService().info('Android foreground service started');
      } else {
        await channel.invokeMethod('stopForegroundService');
        LoggerService().info('Android foreground service stopped');
      }
    } catch (e, stackTrace) {
      LoggerService().error('Failed to update Android foreground service', e, stackTrace);
    }
  }

  set language(String value) {
    if (_language != value) {
      _language = value;
      _saveString(_keyLanguage, value);
      notifyListeners();
    }
  }

  set trayDisplayMode(TrayDisplayMode value) {
    if (_trayDisplayMode != value) {
      _trayDisplayMode = value;
      _saveString(_keyTrayDisplayMode, value.name);
      notifyListeners();
    }
  }

  set trayClusterThreshold(int value) {
    if (_trayClusterThreshold != value) {
      _trayClusterThreshold = value;
      _saveInt(_keyTrayClusterThreshold, value);
      notifyListeners();
    }
  }

  Future<void> init() async {
    if (_initialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();

      // Load theme mode (with migration from old darkMode boolean)
      final themeModeString = _prefs.getString(_keyThemeMode);
      if (themeModeString != null) {
        _themeMode = ThemeModeOption.values.firstWhere(
          (e) => e.name == themeModeString,
          orElse: () => _defaultThemeMode,
        );
      } else {
        // Migrate from old boolean darkMode setting
        final oldDarkMode = _prefs.getBool('dark_mode');
        if (oldDarkMode != null) {
          _themeMode = oldDarkMode ? ThemeModeOption.dark : ThemeModeOption.light;
          // Save migrated value
          await _prefs.setString(_keyThemeMode, _themeMode.name);
          // Remove old key
          await _prefs.remove('dark_mode');
        } else {
          _themeMode = _defaultThemeMode;
        }
      }
      _startWithSystem = _prefs.getBool(_keyStartWithSystem) ?? _defaultStartWithSystem;
      _showInTray = _prefs.getBool(_keyShowInTray) ?? _defaultShowInTray;
      _language = _prefs.getString(_keyLanguage) ?? _defaultLanguage;

      final modeString = _prefs.getString(_keyTrayDisplayMode);
      if (modeString != null) {
        try {
          _trayDisplayMode = TrayDisplayMode.values.firstWhere((e) => e.name == modeString);
        } catch (_) {
          _trayDisplayMode = _defaultTrayDisplayMode;
        }
      } else {
        _trayDisplayMode = _defaultTrayDisplayMode;
      }

      _trayClusterThreshold = _prefs.getInt(_keyTrayClusterThreshold) ?? _defaultTrayClusterThreshold;

      _initialized = true;
      LoggerService().info('SettingsService initialized');
    } catch (e, stackTrace) {
      LoggerService().error('Failed to initialize SettingsService', e, stackTrace);
      // Fallback to defaults if initialization fails
    }
  }

  Future<void> _saveBool(String key, bool value) async {
    if (!_initialized) return;
    try {
      await _prefs.setBool(key, value);
    } catch (e, stackTrace) {
      LoggerService().error('Failed to save boolean setting: $key=$value', e, stackTrace);
    }
  }

  Future<void> _saveString(String key, String value) async {
    if (!_initialized) return;
    try {
      await _prefs.setString(key, value);
    } catch (e, stackTrace) {
      LoggerService().error('Failed to save string setting: $key=$value', e, stackTrace);
    }
  }

  Future<void> _saveInt(String key, int value) async {
    if (!_initialized) return;
    try {
      await _prefs.setInt(key, value);
    } catch (e, stackTrace) {
      LoggerService().error('Failed to save int setting: $key=$value', e, stackTrace);
    }
  }

  @visibleForTesting
  void resetForTesting() {
    _initialized = false;
    _themeMode = _defaultThemeMode;
    _startWithSystem = _defaultStartWithSystem;
    _showInTray = _defaultShowInTray;
    _language = _defaultLanguage;
    _trayDisplayMode = _defaultTrayDisplayMode;
    _trayClusterThreshold = _defaultTrayClusterThreshold;
  }
}
