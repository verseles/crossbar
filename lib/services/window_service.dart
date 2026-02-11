import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'settings_service.dart';

class WindowService with WindowListener {
  factory WindowService() => _instance;

  WindowService._internal();

  static final WindowService _instance = WindowService._internal();

  bool _isInitialized = false;
  SharedPreferences? _prefs;

  bool get isInitialized => _isInitialized;

  @visibleForTesting
  void resetForTesting() {
    _isInitialized = false;
    _prefs = null;
  }

  Future<void> init({bool startMinimized = false}) async {
    if (_isInitialized) return;
    if (!Platform.isLinux && !Platform.isMacOS && !Platform.isWindows) return;

    await windowManager.ensureInitialized();
    _prefs = await SharedPreferences.getInstance();

    final windowOptions = WindowOptions(
      size: const Size(900, 600),
      minimumSize: const Size(600, 400),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: startMinimized,
      titleBarStyle: TitleBarStyle.normal,
      title: 'Crossbar',
    );

    // Register listener before showing/ready to catch early events
    windowManager.addListener(this);

    // Prevent default close behavior so we can minimize instead
    await windowManager.setPreventClose(true);

    // Initialize hotkey manager
    await hotKeyManager.unregisterAll();

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await _restoreWindowState();
      if (!startMinimized) {
        await show();
      }
    });

    _isInitialized = true;
  }

  Future<void> registerGlobalHotkey() async {
    final hotKey = HotKey(
      key: PhysicalKeyboardKey.keyC,
      modifiers: [
        Platform.isMacOS ? HotKeyModifier.meta : HotKeyModifier.control,
        HotKeyModifier.alt,
      ],
      scope: HotKeyScope.system,
    );

    await hotKeyManager.register(
      hotKey,
      keyDownHandler: (hotKey) async {
        if (await windowManager.isVisible()) {
          if (await windowManager.isFocused()) {
            await hide();
          } else {
            await show();
          }
        } else {
          await show();
        }
      },
    );
  }

  Future<void> unregisterGlobalHotkey() async {
    final hotKey = HotKey(
      key: PhysicalKeyboardKey.keyC,
      modifiers: [
        Platform.isMacOS ? HotKeyModifier.meta : HotKeyModifier.control,
        HotKeyModifier.alt,
      ],
      scope: HotKeyScope.system,
    );
    await hotKeyManager.unregister(hotKey);
  }

  Future<void> show() async {
    await windowManager.show();
    await windowManager.focus();
    // Ensure it's not skipped in taskbar when shown
    try {
      await windowManager.setSkipTaskbar(false);
    } catch (_) {
      // Ignore if method not found or failed, hide() usually handles this
    }
  }

  Future<void> hide() async {
    await _saveWindowState();
    await windowManager.hide();
    // Ensure it is skipped in taskbar when hidden (if supported)
    try {
      await windowManager.setSkipTaskbar(true);
    } catch (_) {
      // Ignore
    }
  }

  Future<void> quit() async {
    await _saveWindowState();
    await windowManager.destroy();
  }

  @override
  void onWindowClose() async {
    await _saveWindowState();
    if (SettingsService().showInTray) {
      await hide();
    } else {
      await quit();
    }
  }

  @override
  void onWindowBlur() {
    _saveWindowState();
    super.onWindowBlur();
  }

  @override
  void onWindowMaximize() {
    _saveWindowState();
    super.onWindowMaximize();
  }

  @override
  void onWindowUnmaximize() {
    _saveWindowState();
    super.onWindowUnmaximize();
  }

  Future<void> _saveWindowState() async {
    if (_prefs == null) return;

    try {
      final isMaximized = await windowManager.isMaximized();
      await _prefs!.setBool('window_maximized', isMaximized);

      if (!isMaximized) {
        final bounds = await windowManager.getBounds();
        await _prefs!.setDouble('window_x', bounds.left);
        await _prefs!.setDouble('window_y', bounds.top);
        await _prefs!.setDouble('window_width', bounds.width);
        await _prefs!.setDouble('window_height', bounds.height);
      }
    } catch (e) {
      // Ignore errors when window is already destroyed or not available
    }
  }

  Future<void> _restoreWindowState() async {
    if (_prefs == null) return;

    try {
      final maximized = _prefs!.getBool('window_maximized') ?? false;
      if (maximized) {
        await windowManager.maximize();
      } else {
        final x = _prefs!.getDouble('window_x');
        final y = _prefs!.getDouble('window_y');
        final w = _prefs!.getDouble('window_width');
        final h = _prefs!.getDouble('window_height');

        if (x != null && y != null && w != null && h != null) {
          // Verify bounds are reasonable (width > 0, height > 0)
          if (w > 0 && h > 0) {
            await windowManager.setBounds(Rect.fromLTWH(x, y, w, h));
          }
        }
      }
    } catch (e) {
      // Ignore errors
    }
  }
}
