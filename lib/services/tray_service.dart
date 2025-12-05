import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'package:crossbar/core/plugin_manager.dart';
import 'package:crossbar/models/plugin.dart';
import 'package:crossbar/models/plugin_output.dart' as model;
import 'package:crossbar/services/scheduler_service.dart';
import 'package:crossbar/services/settings_service.dart';
import 'package:crossbar/services/window_service.dart';
import 'package:meta/meta.dart';
import 'package:system_tray/system_tray.dart';
import 'package:uuid/uuid.dart';
class TrayService {
  factory TrayService() => _instance;
  TrayService._internal();
  static final TrayService _instance = TrayService._internal();

  final PluginManager _pluginManager = PluginManager();
  final SettingsService _settings = SettingsService();
  final Map<String, model.PluginOutput> _pluginOutputs = {};

  // Logical Key -> Tray Instance
  final Map<String, _TrayInstance> _activeTrays = {};

  bool _initialized = false;
  String? _iconPath;

  Future<void> init() async {
    if (_initialized) return;

    // Resolve icon path once
    String candidate = 'assets/icons/tray_icon.ico';
    if (Platform.isLinux) {
      candidate = 'assets/icons/tray_icon.png';
    } else if (Platform.isMacOS) {
      candidate = 'assets/icons/tray_icon_macos.png';
    }

    // Check existence
    if (await File(candidate).exists()) {
      _iconPath = candidate;
    } else {
      // Try to find in bundle (Linux/Windows specific structure)
      if (Platform.isLinux || Platform.isWindows) {
        try {
          final exeDir = path.dirname(Platform.resolvedExecutable);
          final bundlePath = path.join(exeDir, 'data', 'flutter_assets', candidate);
          if (await File(bundlePath).exists()) {
            _iconPath = bundlePath;
          }
        } catch (_) {
          // Ignore resolution errors
        }
      }
    }

    // Fallback if still not found (log warning)
    if (_iconPath == null) {
      LoggerService().warning('Tray icon not found at $candidate. Tray may fail to initialize.');
      _iconPath = candidate;
    } else {
      LoggerService().info('Tray icon resolved to: $_iconPath');
    }
    }

    _settings.addListener(_onSettingsChanged);
    _initialized = true;

    // Initial reconciliation
    try {
      await _reconcile();
    } catch (e, stack) {
      LoggerService().error('Failed to initialize tray', e, stack);
    }
  }

  void _onSettingsChanged() {
    _reconcile();
  }

  void updatePluginOutput(String pluginId, model.PluginOutput output) {
    _pluginOutputs[pluginId] = output;
    _reconcile();
  }

  void clearPluginOutput(String pluginId) {
    _pluginOutputs.remove(pluginId);
    _reconcile();
  }

  Future<void> _reconcile() async {
    if (!_initialized || _iconPath == null) return;

    // 1. Determine Desired Layout
    final enabledPlugins = _pluginManager.plugins.where((p) => p.enabled).toList();
    final mode = _settings.trayDisplayMode;
    final threshold = _settings.trayClusterThreshold;

    final desiredTrays = <String, _TrayContent>{}; // Key -> Content

    if (mode == TrayDisplayMode.unified) {
      desiredTrays['unified'] = _buildUnifiedContent(enabledPlugins);
    } else if (mode == TrayDisplayMode.separate) {
      for (final p in enabledPlugins) {
        desiredTrays['plugin:${p.id}'] = _buildPluginContent(p);
      }
    } else if (mode == TrayDisplayMode.smartCollapse) {
      if (enabledPlugins.length > threshold) {
        desiredTrays['unified'] = _buildUnifiedContent(enabledPlugins);
      } else {
        for (final p in enabledPlugins) {
          desiredTrays['plugin:${p.id}'] = _buildPluginContent(p);
        }
      }
    } else if (mode == TrayDisplayMode.smartOverflow) {
      if (enabledPlugins.length > threshold) {
        // First N separate
        for (var i = 0; i < threshold; i++) {
          final p = enabledPlugins[i];
          desiredTrays['plugin:${p.id}'] = _buildPluginContent(p);
        }
        // Rest in overflow
        final overflowPlugins = enabledPlugins.sublist(threshold);
        desiredTrays['overflow'] = _buildUnifiedContent(overflowPlugins, isOverflow: true);
      } else {
         for (final p in enabledPlugins) {
          desiredTrays['plugin:${p.id}'] = _buildPluginContent(p);
        }
      }
    }

    // 2. Diff and Apply

    // Remove old trays
    final keysToRemove = _activeTrays.keys.where((k) => !desiredTrays.containsKey(k)).toList();
    for (final key in keysToRemove) {
      await _activeTrays[key]?.destroy();
      _activeTrays.remove(key);
    }

    // Create or Update trays
    for (final entry in desiredTrays.entries) {
      final key = entry.key;
      final content = entry.value;

      if (!_activeTrays.containsKey(key)) {
         // Create new
         final tray = _TrayInstance();
         await tray.init(key, _iconPath!);
         _activeTrays[key] = tray;
      }

      // Update content
      await _activeTrays[key]?.update(content);
    }
  }

  _TrayContent _buildPluginContent(Plugin p) {
    final output = _pluginOutputs[p.id];
    String title = '';
    String tooltip = p.id;
    List<model.MenuItem> menuItems = [];

    if (output != null) {
       title = output.icon + (output.text != null ? ' ${output.text}' : '');
       // Clean up title (remove double spaces)
       title = title.trim();
       if (title.isEmpty) title = p.id;

       tooltip = output.trayTooltip ?? '${p.id}: ${output.text ?? ""}';
       menuItems = output.menu;
    } else {
      title = p.id;
    }

    return _TrayContent(
      title: title,
      tooltip: tooltip,
      menuItems: menuItems,
      appendGlobalActions: true,
    );
  }

  _TrayContent _buildUnifiedContent(List<Plugin> plugins, {bool isOverflow = false}) {
     String title = isOverflow ? '...' : '';

     // Build menu: Submenus for each plugin
     List<model.MenuItem> menuItems = [];

     for (final p in plugins) {
        final output = _pluginOutputs[p.id];
        String label = p.id;
        List<model.MenuItem>? submenu;

        if (output != null) {
           label = '${output.icon} ${output.text ?? p.id}';
           submenu = output.menu;
        }

        menuItems.add(model.MenuItem(
           text: label,
           submenu: submenu ?? [],
        ));
     }

     return _TrayContent(
       title: title,
       tooltip: isOverflow ? 'More Plugins' : 'Crossbar',
       menuItems: menuItems,
       appendGlobalActions: true,
     );
  }

  @visibleForTesting
  void resetForTesting() {
    _settings.removeListener(_onSettingsChanged);
    _initialized = false;
    _activeTrays.clear();
    _pluginOutputs.clear();
  }
}

class _TrayContent {
  final String title;
  final String tooltip;
  final List<model.MenuItem> menuItems;
  final bool appendGlobalActions;

  _TrayContent({required this.title, required this.tooltip, required this.menuItems, this.appendGlobalActions = true});
}

class _TrayInstance {
  final SystemTray _systemTray = SystemTray();
  // ignore: unused_field
  final String _uuid = const Uuid().v4();

  Future<void> init(String key, String iconPath) async {
     await _systemTray.initSystemTray(
       title: '',
       iconPath: iconPath,
       toolTip: '',
     );

     _systemTray.registerSystemTrayEventHandler((eventName) {
       if (eventName == kSystemTrayEventClick) {
          _systemTray.popUpContextMenu();
       } else if (eventName == kSystemTrayEventRightClick) {
          _systemTray.popUpContextMenu();
       }
     });
  }

  Future<void> update(_TrayContent content) async {
     await _systemTray.setTitle(content.title);
     await _systemTray.setToolTip(content.tooltip);

     final menu = Menu();
     final items = <MenuItemBase>[];

     // Convert model.MenuItem to system_tray.MenuItemBase
     for (final item in content.menuItems) {
       items.add(_convertMenuItem(item));
     }

     if (content.appendGlobalActions) {
       if (items.isNotEmpty) items.add(MenuSeparator());
       items.addAll([
         MenuItemLabel(label: 'Show Crossbar', onClicked: (_) => WindowService().show()),
         MenuItemLabel(label: 'Refresh All', onClicked: (_) => SchedulerService().refreshAll()),
         MenuSeparator(),
         MenuItemLabel(label: 'Quit', onClicked: (_) => WindowService().quit()),
       ]);
     }

     await menu.buildFrom(items);
     await _systemTray.setContextMenu(menu);
  }

  MenuItemBase _convertMenuItem(model.MenuItem item) {
    if (item.separator) return MenuSeparator();

    if (item.submenu != null && item.submenu!.isNotEmpty) {
      return SubMenu(
        label: item.text ?? '',
        children: item.submenu!.map(_convertMenuItem).toList(),
      );
    }

    return MenuItemLabel(
      label: item.text ?? '',
      onClicked: (_) {},
      enabled: item.bash != null || item.href != null,
    );
  }

  Future<void> destroy() async {
    await _systemTray.destroy();
  }
}
