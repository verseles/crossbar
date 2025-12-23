// Crossbar Tray Daemon for Linux
//
// This standalone executable creates a SINGLE tray icon for one plugin.
// It receives data via stdin (JSON) and updates the icon/menu accordingly.
// The main Crossbar process spawns one daemon per plugin in "separate" mode.
//
// Usage: crossbar_tray_daemon
// Communication: JSON via stdin, signals via stdout
//
// JSON input format:
// {
//   "pluginId": "cpu",
//   "title": "🖥️ CPU 5%",
//   "iconName": "applications-utilities",
//   "menu": [
//     {"label": "Show Graph", "key": "show_graph"},
//     {"separator": true},
//     {"label": "Refresh", "key": "refresh"}
//   ]
// }

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dbus/dbus.dart';
import 'package:xdg_status_notifier_item/xdg_status_notifier_item.dart';

StatusNotifierItemClient? _client;
DBusClient? _bus;
String _currentTitle = 'Crossbar';

/// Maps plugin IDs to Freedesktop icon names.
/// Plugins can also provide their own icon name via the 'freedesktopIcon' field.
String _resolveIconName(String? pluginId, String? customIcon) {
  // If plugin provides a custom icon name, use it
  if (customIcon != null && customIcon.isNotEmpty && customIcon != 'applications-utilities') {
    return customIcon;
  }

  // Map common plugin IDs to Freedesktop icon names
  final iconMap = <String, String>{
    'battery': 'battery-full-symbolic',
    'cpu': 'utilities-system-monitor-symbolic',
    'memory': 'drive-harddisk-symbolic',
    'disk': 'drive-harddisk-symbolic',
    'network': 'network-wired-symbolic',
    'wifi': 'network-wireless-symbolic',
    'bluetooth': 'bluetooth-symbolic',
    'volume': 'audio-volume-high-symbolic',
    'brightness': 'display-brightness-symbolic',
    'emoji-clock': 'preferences-system-time-symbolic',
    'clock': 'preferences-system-time-symbolic',
    'weather': 'weather-clear-symbolic',
    'temperature': 'sensors-temperature-symbolic',
  };

  // Try exact match first
  if (pluginId != null && iconMap.containsKey(pluginId)) {
    return iconMap[pluginId]!;
  }

  // Try partial match (e.g., 'battery-monitor' matches 'battery')
  if (pluginId != null) {
    for (final entry in iconMap.entries) {
      if (pluginId.contains(entry.key)) {
        return entry.value;
      }
    }
  }

  // Fallback to generic application icon
  return 'applications-utilities-symbolic';
}

Future<void> main(List<String> args) async {
  // Set up signal handlers for graceful shutdown
  ProcessSignal.sigterm.watch().listen((_) => _shutdown());
  ProcessSignal.sigint.watch().listen((_) => _shutdown());

  // Listen for JSON data on stdin
  final stdinLines = stdin.transform(utf8.decoder).transform(const LineSplitter());

  await for (final line in stdinLines) {
    try {
      final data = jsonDecode(line) as Map<String, dynamic>;
      await _processMessage(data);
    } catch (e) {
      stderr.writeln('Error processing message: $e');
    }
  }

  // EOF received, shutdown
  await _shutdown();
}

Future<void> _processMessage(Map<String, dynamic> data) async {
  final pluginId = data['pluginId'] as String?;
  final title = data['title'] as String? ?? 'Crossbar';
  final iconName = _resolveIconName(pluginId, data['iconName'] as String?);
  final menuData = data['menu'] as List<dynamic>? ?? [];

  _currentTitle = title;

  // Build menu
  final menuItems = <DBusMenuItem>[];
  menuItems.add(DBusMenuItem(label: title, enabled: false));
  menuItems.add(DBusMenuItem.separator());
  
  for (final item in menuData) {
    if (item is Map<String, dynamic>) {
      if (item['separator'] == true) {
        menuItems.add(DBusMenuItem.separator());
      } else {
        final label = item['label'] as String? ?? '';
        final key = item['key'] as String?;
        menuItems.add(DBusMenuItem(
          label: label,
          onClicked: key != null ? () async {
            // Send action back to main process
            stdout.writeln(jsonEncode({'action': key, 'pluginId': pluginId}));
          } : null,
        ));
      }
    }
  }

  // Note: Standard actions (Refresh, Show, Quit) are added by TrayService's
  // _buildPluginMenu, so we don't add them here to avoid duplicates.

  final menu = DBusMenuItem(children: menuItems);

  if (_client == null) {
    // Create new icon
    _bus = DBusClient.session();
    _client = StatusNotifierItemClient(
      id: 'crossbar-${pluginId ?? 'unknown'}-${pid}',
      title: title,
      iconName: iconName,
      menu: menu,
      bus: _bus,
    );
    
    try {
      await _client!.connect();
      stdout.writeln(jsonEncode({'status': 'connected', 'pluginId': pluginId}));
    } catch (e) {
      stderr.writeln('Failed to connect SNI: $e');
      await _shutdown();
    }
  } else {
    // Update existing icon menu
    try {
      await _client!.updateMenu(menu);
    } catch (e) {
      stderr.writeln('Failed to update menu: $e');
    }
  }
}

Future<void> _shutdown() async {
  try {
    await _client?.close();
    await _bus?.close();
  } catch (_) {}
  exit(0);
}
