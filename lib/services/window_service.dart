import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'settings_service.dart';

class WindowService with WindowListener {
  factory WindowService() => _instance;

  WindowService._internal();

  static final WindowService _instance = WindowService._internal();

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> init({bool startMinimized = false}) async {
    if (_isInitialized) return;
    if (!Platform.isLinux && !Platform.isMacOS && !Platform.isWindows) return;

    await windowManager.ensureInitialized();

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
    await windowManager.hide();
    // Ensure it is skipped in taskbar when hidden (if supported)
    try {
      await windowManager.setSkipTaskbar(true);
    } catch (_) {
      // Ignore
    }
  }

  Future<void> quit() async {
    await windowManager.destroy();
  }

  @override
  void onWindowClose() async {
    if (SettingsService().showInTray) {
      await hide();
    } else {
      await quit();
    }
  }
}
