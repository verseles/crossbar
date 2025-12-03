import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crossbar/services/logger_service.dart';

class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();

  factory SettingsService() => _instance;

  SettingsService._internal();

  late SharedPreferences _prefs;
  bool _initialized = false;

  // Keys
  static const String _keyDarkMode = 'dark_mode';
  static const String _keyStartWithSystem = 'start_with_system';
  static const String _keyShowInTray = 'show_in_tray';
  static const String _keyLanguage = 'language';

  // Default Values
  static const bool _defaultDarkMode = false;
  static const bool _defaultStartWithSystem = false;
  static const bool _defaultShowInTray = true;
  static const String _defaultLanguage = 'system';

  // State
  bool _darkMode = _defaultDarkMode;
  bool _startWithSystem = _defaultStartWithSystem;
  bool _showInTray = _defaultShowInTray;
  String _language = _defaultLanguage;

  bool get isInitialized => _initialized;

  // Getters
  bool get darkMode => _darkMode;
  bool get startWithSystem => _startWithSystem;
  bool get showInTray => _showInTray;
  String get language => _language;

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
      notifyListeners();
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

  Future<void> init() async {
    if (_initialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();

      _darkMode = _prefs.getBool(_keyDarkMode) ?? _defaultDarkMode;
      _startWithSystem = _prefs.getBool(_keyStartWithSystem) ?? _defaultStartWithSystem;
      _showInTray = _prefs.getBool(_keyShowInTray) ?? _defaultShowInTray;
      _language = _prefs.getString(_keyLanguage) ?? _defaultLanguage;

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

  @visibleForTesting
  void resetForTesting() {
    _initialized = false;
    _darkMode = _defaultDarkMode;
    _startWithSystem = _defaultStartWithSystem;
    _showInTray = _defaultShowInTray;
    _language = _defaultLanguage;
  }
}
