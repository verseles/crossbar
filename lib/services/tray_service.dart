import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/scheduler.dart';
import 'package:path/path.dart' as p;
import 'package:tray_manager/tray_manager.dart';

import '../core/plugin_manager.dart';
import '../models/plugin_output.dart' hide MenuItem;
import 'logger_service.dart';
import 'refresh_service.dart';
import 'window_service.dart';

class TrayService with TrayListener {
  factory TrayService() => _instance;
  TrayService._internal();
  static final TrayService _instance = TrayService._internal();

  final PluginManager _pluginManager = PluginManager();
  final RefreshService _refreshService = RefreshService();
  StreamSubscription? _pluginOutputSubscription;
  Map<String, PluginOutput> _pluginOutputs = {};

  bool _initialized = false;
  String? _iconPath;
  Brightness? _lastBrightness;

  Future<void> init() async {
    if (_initialized) return;
    if (!Platform.isLinux && !Platform.isMacOS && !Platform.isWindows) return;

    trayManager.addListener(this);
    _pluginOutputSubscription =
        _refreshService.outputsStream.listen(_onPluginOutput);

    await _resolveAndSetIcon();
    await _updateMenu();

    if (!Platform.isLinux) {
      try {
        await trayManager.setToolTip('Crossbar');
      } catch (_) {}
    }

    try {
      await trayManager.setTitle('Crossbar');
    } catch (_) {}

    if (Platform.isLinux) {
      _setupThemeListener();
    }

    _initialized = true;
    LoggerService().info('Tray service initialized');
  }

  void _onPluginOutput(Map<String, PluginOutput> outputs) {
    _pluginOutputs = outputs;
    _updateMenu();
    _updateTitle();
    _updateTooltip();
  }

  void _setupThemeListener() {
    final dispatcher = SchedulerBinding.instance.platformDispatcher;
    dispatcher.onPlatformBrightnessChanged = _onThemeChanged;
  }

  void _onThemeChanged() {
    if (!Platform.isLinux) return;
    final currentBrightness =
        SchedulerBinding.instance.platformDispatcher.platformBrightness;
    if (_lastBrightness != currentBrightness) {
      _lastBrightness = currentBrightness;
      LoggerService().info('Theme changed to: $currentBrightness');
      _resolveAndSetIcon();
    }
  }

  Future<void> _resolveAndSetIcon() async {
    String candidate;
    if (Platform.isLinux) {
      final brightness =
          SchedulerBinding.instance.platformDispatcher.platformBrightness;
      _lastBrightness = brightness;
      candidate = brightness == Brightness.dark
          ? 'assets/icons/tray_icon_light.png'
          : 'assets/icons/tray_icon_dark.png';
      LoggerService().info('Linux theme: $brightness, using icon: $candidate');
    } else if (Platform.isMacOS) {
      candidate = 'assets/icons/tray_icon_macos.png';
    } else {
      candidate = 'assets/icons/tray_icon.ico';
    }

    if (await File(candidate).exists()) {
      _iconPath = candidate;
    } else if (Platform.isLinux || Platform.isWindows) {
      try {
        final exeDir = p.dirname(Platform.resolvedExecutable);
        final bundlePath = p.join(exeDir, 'data', 'flutter_assets', candidate);
        if (await File(bundlePath).exists()) {
          _iconPath = bundlePath;
        }
      } catch (_) {}
    }

    if (_iconPath == null) {
      LoggerService()
          .warning('Tray icon not found at $candidate. May not display.');
      _iconPath = candidate;
    } else {
      LoggerService().info('Tray icon resolved to: $_iconPath');
    }

    try {
      await trayManager.setIcon(_iconPath!);
    } catch (e) {
      LoggerService().warning('Failed to set tray icon: $e');
    }
  }

  Future<void> _updateMenu() async {
    final menuItems = <MenuItem>[];
    for (final plugin in _pluginManager.plugins.where((p) => p.enabled)) {
      final output = _pluginOutputs[plugin.id];
      if (output != null && output.text != null && output.text!.isNotEmpty) {
        menuItems.add(MenuItem(
          label: '${output.icon} ${output.text}',
          disabled: true,
        ));
      }
    }

    if (menuItems.isNotEmpty) {
      menuItems.add(MenuItem.separator());
    }

    menuItems.addAll([
      MenuItem(key: 'show', label: 'Show Crossbar'),
      MenuItem(key: 'refresh', label: 'Refresh All Plugins'),
      MenuItem.separator(),
      MenuItem(key: 'quit', label: 'Quit'),
    ]);

    try {
      await trayManager.setContextMenu(Menu(items: menuItems));
    } catch (e) {
      LoggerService().warning('Failed to set tray context menu: $e');
    }
  }

  Future<void> refreshMenu() async {
    await _updateMenu();
  }

  void _updateTooltip() {
    if (Platform.isLinux || _pluginOutputs.isEmpty) return;
    final tooltipParts = <String>[];
    for (final entry in _pluginOutputs.entries.take(3)) {
      final output = entry.value;
      if (output.text != null) {
        tooltipParts.add('${output.icon} ${output.text}');
      }
    }
    try {
      trayManager.setToolTip(tooltipParts.join(' | '));
    } catch (e) {
      LoggerService().warning('Failed to set tray tooltip: $e');
    }
  }

  Future<void> _updateTitle() async {
    final firstEnabled =
        _pluginManager.plugins.where((p) => p.enabled).firstOrNull;
    if (firstEnabled == null) return;

    final output = _pluginOutputs[firstEnabled.id];
    if (output == null) return;

    var title = '';
    if (output.icon.isNotEmpty && output.icon != '⚙️') {
      title += '${output.icon} ';
    }
    if (output.text != null) {
      title += output.text!;
    }

    try {
      await trayManager.setTitle(title);
    } catch (e) {
      LoggerService().warning('Failed to set tray title: $e');
    }
  }

  @override
  void onTrayIconMouseDown() => WindowService().show();

  @override
  void onTrayIconRightMouseDown() => trayManager.popUpContextMenu();

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show':
        WindowService().show();
        break;
      case 'refresh':
        _refreshService.refreshAll();
        break;
      case 'quit':
        WindowService().quit();
        break;
    }
  }

  Future<void> dispose() async {
    if (!_initialized) return;
    _pluginOutputSubscription?.cancel();
    trayManager.removeListener(this);
    try {
      await trayManager.destroy();
    } catch (e) {
      LoggerService().warning('Failed to destroy tray: $e');
    }
    _initialized = false;
  }
}
