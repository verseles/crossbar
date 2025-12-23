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
  final iconName = data['iconName'] as String? ?? 'applications-utilities';
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

  // Add standard actions
  menuItems.add(DBusMenuItem.separator());
  menuItems.add(DBusMenuItem(
    label: 'Show Crossbar',
    onClicked: () async {
      stdout.writeln(jsonEncode({'action': 'show'}));
    },
  ));
  menuItems.add(DBusMenuItem(
    label: 'Quit',
    onClicked: () async {
      stdout.writeln(jsonEncode({'action': 'quit'}));
    },
  ));

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
