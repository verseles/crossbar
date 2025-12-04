import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';

import '../core/plugin_manager.dart';
import '../models/plugin_output.dart' hide MenuItem;
import 'scheduler_service.dart';
import 'window_service.dart';

class TrayService with TrayListener {
  factory TrayService() => _instance;

  TrayService._internal();

  static final TrayService _instance = TrayService._internal();

  final PluginManager _pluginManager = PluginManager();
  final Map<String, PluginOutput> _pluginOutputs = {};

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
    _updateTitle(pluginId, output);

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

  Future<void> _updateTitle(String pluginId, PluginOutput output) async {
    // Find the first enabled plugin to use as the main tray title
    final firstEnabled = _pluginManager.plugins
        .where((p) => p.enabled)
        .firstOrNull;

    if (firstEnabled?.id == pluginId) {
      String title = '';
      // Use emoji icon from plugin output if available
      if (output.icon.isNotEmpty && output.icon != '⚙️') {
        title += '${output.icon} ';
      }
      if (output.text != null) {
        title += output.text!;
      }
      await trayManager.setTitle(title);
    }
  }

  void clearPluginOutput(String pluginId) {
    _pluginOutputs.remove(pluginId);
    _updateMenu();
  }

  @override
  void onTrayIconMouseDown() {
    WindowService().show();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show':
        WindowService().show();
      case 'refresh':
        _refreshAllPlugins();
      case 'quit':
        WindowService().quit();
    }
  }

  Future<void> _refreshAllPlugins() async {
    // Delegate to SchedulerService to ensure consistency
    await SchedulerService().refreshAll();
  }

  Future<void> dispose() async {
    if (!_initialized) return;

    trayManager.removeListener(this);
    await trayManager.destroy();
    _initialized = false;
  }
}
