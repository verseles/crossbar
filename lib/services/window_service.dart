import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class WindowService with WindowListener {
  static final WindowService _instance = WindowService._internal();
  factory WindowService() => _instance;
  WindowService._internal();

  bool _isInitialized = false;
  final bool _minimizeToTray = true;

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

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      if (!startMinimized) {
        await show();
      }
    });

    _isInitialized = true;
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
    if (_minimizeToTray) {
      await hide();
    } else {
      await quit();
    }
  }
}
