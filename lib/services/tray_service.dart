import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../core/plugin_manager.dart';
import '../models/plugin_output.dart' hide MenuItem;

class TrayService with TrayListener {
  static final TrayService _instance = TrayService._internal();

  factory TrayService() => _instance;

  TrayService._internal();

  final PluginManager _pluginManager = PluginManager();
  final Map<String, PluginOutput> _pluginOutputs = {};
  VoidCallback? onShowWindow;
  VoidCallback? onQuit;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    if (!Platform.isLinux && !Platform.isMacOS && !Platform.isWindows) {
      return;
    }

    trayManager.addListener(this);

    await _setIcon();
    await _updateMenu();

    _initialized = true;
  }

  Future<void> _setIcon() async {
    String iconPath;

    if (Platform.isLinux) {
      iconPath = 'assets/icons/tray_icon.png';
    } else if (Platform.isMacOS) {
      iconPath = 'assets/icons/tray_icon_macos.png';
    } else {
      iconPath = 'assets/icons/tray_icon.ico';
    }

    final iconFile = File(iconPath);
    if (await iconFile.exists()) {
      await trayManager.setIcon(iconPath);
    }
  }

  Future<void> _updateMenu() async {
    final menuItems = <MenuItem>[];

    // Plugin outputs
    for (final entry in _pluginOutputs.entries) {
      final output = entry.value;
      if (output.text != null && output.text!.isNotEmpty) {
        menuItems.add(MenuItem(
          label: '${output.icon} ${output.text}',
          disabled: true,
        ));
      }
    }

    if (menuItems.isNotEmpty) {
      menuItems.add(MenuItem.separator());
    }

    // Standard menu items
    menuItems.addAll([
      MenuItem(
        key: 'show',
        label: 'Show Crossbar',
      ),
      MenuItem(
        key: 'refresh',
        label: 'Refresh All Plugins',
      ),
      MenuItem.separator(),
      MenuItem(
        key: 'quit',
        label: 'Quit',
      ),
    ]);

    await trayManager.setContextMenu(Menu(items: menuItems));
  }

  void updatePluginOutput(String pluginId, PluginOutput output) {
    _pluginOutputs[pluginId] = output;
    _updateMenu();

    // Update tray tooltip
    if (_pluginOutputs.isNotEmpty) {
      final tooltipParts = <String>[];
      for (final entry in _pluginOutputs.entries.take(3)) {
        final output = entry.value;
        if (output.text != null) {
          tooltipParts.add('${output.icon} ${output.text}');
        }
      }
      trayManager.setToolTip(tooltipParts.join(' | '));
    }
  }

  void clearPluginOutput(String pluginId) {
    _pluginOutputs.remove(pluginId);
    _updateMenu();
  }

  @override
  void onTrayIconMouseDown() {
    onShowWindow?.call();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show':
        onShowWindow?.call();
      case 'refresh':
        _refreshAllPlugins();
      case 'quit':
        onQuit?.call();
    }
  }

  Future<void> _refreshAllPlugins() async {
    final outputs = await _pluginManager.runAllEnabled();
    for (final output in outputs) {
      updatePluginOutput(output.pluginId, output);
    }
  }

  Future<void> dispose() async {
    if (!_initialized) return;

    trayManager.removeListener(this);
    await trayManager.destroy();
    _initialized = false;
  }
}

class WindowService with WindowListener {
  static final WindowService _instance = WindowService._internal();

  factory WindowService() => _instance;

  WindowService._internal();

  bool _initialized = false;
  bool _minimizeToTray = true;

  bool get minimizeToTray => _minimizeToTray;
  set minimizeToTray(bool value) => _minimizeToTray = value;

  Future<void> init() async {
    if (_initialized) return;
    if (!Platform.isLinux && !Platform.isMacOS && !Platform.isWindows) {
      return;
    }

    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(900, 600),
      minimumSize: Size(600, 400),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      title: 'Crossbar',
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });

    windowManager.addListener(this);
    _initialized = true;
  }

  Future<void> show() async {
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> hide() async {
    await windowManager.hide();
  }

  Future<void> close() async {
    await windowManager.close();
  }

  @override
  void onWindowClose() async {
    if (_minimizeToTray) {
      await hide();
    } else {
      await windowManager.destroy();
    }
  }

  @override
  void onWindowMinimize() {
    if (_minimizeToTray) {
      hide();
    }
  }

  Future<void> dispose() async {
    if (!_initialized) return;

    windowManager.removeListener(this);
    _initialized = false;
  }
}
