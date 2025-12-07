import 'dart:io';

import 'package:crossbar/services/logger_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TrayDisplayMode {
  unified,
  separate,
  smartCollapse,
  smartOverflow,
}

class SettingsService extends ChangeNotifier {

  factory SettingsService() => _instance;

  SettingsService._internal();
  static final SettingsService _instance = SettingsService._internal();

  late SharedPreferences _prefs;
  bool _initialized = false;

  // Keys
  static const String _keyDarkMode = 'dark_mode';
  static const String _keyStartWithSystem = 'start_with_system';
  static const String _keyShowInTray = 'show_in_tray';
  static const String _keyLanguage = 'language';
  static const String _keyTrayDisplayMode = 'tray_display_mode';
  static const String _keyTrayClusterThreshold = 'tray_cluster_threshold';

  // Default Values
  static const bool _defaultDarkMode = false;
  static const bool _defaultStartWithSystem = false;
  static const bool _defaultShowInTray = true;
  static const String _defaultLanguage = 'system';
  // NOTE: tray_manager uses a single global tray instance.
  // Using 'unified' mode ensures a single tray icon with submenus for plugins.
  // Other modes (separate, smartCollapse) are reserved for future multi-tray implementations.
  static const TrayDisplayMode _defaultTrayDisplayMode = TrayDisplayMode.unified;
  static const int _defaultTrayClusterThreshold = 3;

  // State
  bool _darkMode = _defaultDarkMode;
  bool _startWithSystem = _defaultStartWithSystem;
  bool _showInTray = _defaultShowInTray;
  String _language = _defaultLanguage;
  TrayDisplayMode _trayDisplayMode = _defaultTrayDisplayMode;
  int _trayClusterThreshold = _defaultTrayClusterThreshold;

  bool get isInitialized => _initialized;

  // Getters
  bool get darkMode => _darkMode;
  bool get startWithSystem => _startWithSystem;
  bool get showInTray => _showInTray;
  String get language => _language;
  TrayDisplayMode get trayDisplayMode => _trayDisplayMode;
  int get trayClusterThreshold => _trayClusterThreshold;

  // Setters
  set darkMode(bool value) {
    if (_darkMode != value) {
      _darkMode = value;
      _saveBool(_keyDarkMode, value);
      notifyListeners();
    }
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
      notifyListeners();
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

      _darkMode = _prefs.getBool(_keyDarkMode) ?? _defaultDarkMode;
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
    _darkMode = _defaultDarkMode;
    _startWithSystem = _defaultStartWithSystem;
    _showInTray = _defaultShowInTray;
    _language = _defaultLanguage;
    _trayDisplayMode = _defaultTrayDisplayMode;
    _trayClusterThreshold = _defaultTrayClusterThreshold;
  }
}
