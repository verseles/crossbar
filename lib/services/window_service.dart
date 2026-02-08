import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'logger_service.dart';
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

    Rect? savedBounds;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey('window_x') &&
          prefs.containsKey('window_y') &&
          prefs.containsKey('window_width') &&
          prefs.containsKey('window_height')) {
        final bounds = Rect.fromLTWH(
          prefs.getDouble('window_x')!,
          prefs.getDouble('window_y')!,
          prefs.getDouble('window_width')!,
          prefs.getDouble('window_height')!,
        );

        // Validate if the saved bounds are within any available display
        bool isOnScreen = false;
        try {
          final displays = await screenRetriever.getAllDisplays();
          for (final display in displays) {
            // Check if the center of the saved window is within the display's visible area
            final visibleFrame = display.visiblePosition != null && display.size != null
                ? Rect.fromLTWH(
                    display.visiblePosition!.dx,
                    display.visiblePosition!.dy,
                    display.size!.width,
                    display.size!.height,
                  )
                : null;

            if (visibleFrame != null && visibleFrame.contains(bounds.center)) {
              isOnScreen = true;
              break;
            }
          }
        } catch (e) {
          LoggerService().warning('Failed to validate window bounds against screens: $e');
          // If validation fails, assume it's valid to avoid resetting on error,
          // or invalid to be safe?
          // Let's assume valid if we can't check, but usually getAllDisplays should work.
          // However, if we can't verify, maybe safe default (center) is better?
          // But getAllDisplays might fail on some platforms/setups.
          // Let's stick to "if we can't verify, use it" to be less aggressive,
          // unless the user specifically asked for "fallback to centered defaults".
          // The user said: "validate saved coordinates against current screens (or fallback to centered defaults)".
          // So if validation fails (exception), maybe we should fallback.
          // But empty list of displays is a valid failure case where we definitely want fallback.
          // Exception might be platform error.
          isOnScreen = true; // Fallback to trusting the saved value on error
        }

        if (isOnScreen) {
          savedBounds = bounds;
        } else {
          LoggerService().info('Saved window bounds off-screen, resetting to center');
        }
      }
    } catch (e, stackTrace) {
      LoggerService().error('Failed to load window state', e, stackTrace);
    }

    final windowOptions = WindowOptions(
      size: savedBounds?.size ?? const Size(900, 600),
      minimumSize: const Size(600, 400),
      center: savedBounds == null,
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
      if (savedBounds != null) {
        // Explicitly set position and size to ensure it works across all platforms
        try {
          await windowManager.setBounds(savedBounds!);
          await windowManager.setPosition(savedBounds!.topLeft);
        } catch (e, stackTrace) {
          LoggerService().error('Failed to restore window state', e, stackTrace);
        }
      }

      if (!startMinimized) {
        await show();
      }
    });

    _isInitialized = true;
  }

  Future<void> _saveWindowState() async {
    try {
      final bounds = await windowManager.getBounds();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('window_x', bounds.left);
      await prefs.setDouble('window_y', bounds.top);
      await prefs.setDouble('window_width', bounds.width);
      await prefs.setDouble('window_height', bounds.height);
    } catch (e, stackTrace) {
      LoggerService().error('Failed to save window state', e, stackTrace);
    }
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
    if (SettingsService().showInTray) {
      await hide();
    } else {
      await quit();
    }
  }

  @visibleForTesting
  void resetForTesting() {
    _isInitialized = false;
  }
}
