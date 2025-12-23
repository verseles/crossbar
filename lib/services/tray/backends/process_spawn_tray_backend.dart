import 'dart:convert';
import 'dart:io';

import '../tray_backend.dart';
import '../tray_menu_item.dart';
import '../../logger_service.dart';

/// Tray backend that spawns separate daemon processes for each icon.
///
/// This backend is used on Linux when the standard SNI approach fails
/// due to D-Bus name collision issues. Each plugin gets its own
/// daemon process that creates an independent tray icon.
class ProcessSpawnTrayBackend implements TrayBackend {
  bool _initialized = false;
  final Map<int, _DaemonProcess> _daemons = {};
  int _nextId = 0;
  String? _daemonPath;

  @override
  String get name => 'ProcessSpawnTrayBackend';

  @override
  bool get supportsMultipleIcons => true;

  @override
  int get maxIcons => 10;

  @override
  bool get isInitialized => _initialized;

  @override
  Future<bool> init() async {
    if (_initialized) return true;

    // Only works on Linux
    if (!Platform.isLinux) {
      LoggerService().info('$name: Not supported on non-Linux platforms');
      return false;
    }

    // Find the daemon executable
    _daemonPath = await _findDaemonPath();
    if (_daemonPath == null) {
      LoggerService().warning('$name: Could not find crossbar_tray_daemon');
      return false;
    }

    _initialized = true;
    LoggerService().info('$name: Initialized with daemon at $_daemonPath');
    return true;
  }

  /// Finds the path to the crossbar_tray_daemon executable.
  Future<String?> _findDaemonPath() async {
    // Check for compiled daemon next to main executable
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final compiledPath = '$exeDir/crossbar_tray_daemon';
    if (await File(compiledPath).exists()) {
      return compiledPath;
    }

    // Check for dart script in development
    final scriptPath = 'bin/crossbar_tray_daemon.dart';
    if (await File(scriptPath).exists()) {
      return scriptPath;
    }

    return null;
  }

  @override
  Future<int?> createIcon({
    required String pluginId,
    required String iconPath,
    required String tooltip,
  }) async {
    if (!_initialized || _daemonPath == null) {
      LoggerService().warning('$name: Cannot create icon - not initialized');
      return null;
    }

    if (_daemons.length >= maxIcons) {
      LoggerService().warning('$name: Maximum icon limit ($maxIcons) reached');
      return null;
    }

    try {
      final id = _nextId++;
      
      // Start daemon process
      Process process;
      if (_daemonPath!.endsWith('.dart')) {
        // Development mode - run via dart
        process = await Process.start('dart', ['run', _daemonPath!]);
      } else {
        // Production mode - compiled executable
        process = await Process.start(_daemonPath!, []);
      }

      final daemon = _DaemonProcess(
        id: id,
        pluginId: pluginId,
        process: process,
      );
      _daemons[id] = daemon;

      // Listen for stdout (actions from daemon)
      process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
        _handleDaemonOutput(id, line);
      });

      // Listen for stderr (errors)
      process.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
        LoggerService().warning('$name: Daemon $id stderr: $line');
      });

      // Send initial data
      final initialData = {
        'pluginId': pluginId,
        'title': tooltip,
        'iconName': 'applications-utilities',
        'menu': <Map<String, dynamic>>[],
      };
      process.stdin.writeln(jsonEncode(initialData));

      LoggerService().info('$name: Spawned daemon $id for plugin $pluginId (pid: ${process.pid})');
      return id;
    } catch (e, stack) {
      LoggerService().error('$name: Failed to spawn daemon: $e', e, stack);
      return null;
    }
  }

  void _handleDaemonOutput(int id, String line) {
    try {
      final data = jsonDecode(line) as Map<String, dynamic>;
      final action = data['action'] as String?;
      
      if (action != null) {
        LoggerService().debug('$name: Daemon $id action: $action');
        // TODO: Handle actions (show, quit, refresh, etc.)
      }
    } catch (e) {
      LoggerService().debug('$name: Daemon $id output: $line');
    }
  }

  @override
  Future<void> updateIcon({
    required int iconId,
    String? iconPath,
    String? title,
    String? tooltip,
    List<TrayMenuItem>? menu,
  }) async {
    if (!_initialized) return;

    final daemon = _daemons[iconId];
    if (daemon == null) {
      LoggerService().warning('$name: Daemon $iconId not found');
      return;
    }

    try {
      final data = <String, dynamic>{
        'pluginId': daemon.pluginId,
      };

      if (title != null) data['title'] = title;
      if (tooltip != null) data['title'] = tooltip;
      if (iconPath != null) data['iconName'] = iconPath;
      if (menu != null) data['menu'] = _convertMenu(menu);

      daemon.process.stdin.writeln(jsonEncode(data));
    } catch (e) {
      LoggerService().warning('$name: Failed to update daemon $iconId: $e');
    }
  }

  List<Map<String, dynamic>> _convertMenu(List<TrayMenuItem> items) {
    return items.map((item) {
      if (item.isSeparator) {
        return {'separator': true};
      }
      return {
        'label': item.label,
        'key': item.key,
        if (item.submenu != null) 'submenu': _convertMenu(item.submenu!),
      };
    }).toList();
  }

  @override
  Future<void> destroyIcon(int iconId) async {
    if (!_initialized) return;

    final daemon = _daemons.remove(iconId);
    if (daemon == null) return;

    try {
      // Close stdin to signal shutdown
      await daemon.process.stdin.close();
      
      // Wait briefly for graceful exit
      final exitCode = await daemon.process.exitCode.timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          daemon.process.kill();
          return -1;
        },
      );
      
      LoggerService().info('$name: Daemon $iconId exited with code $exitCode');
    } catch (e) {
      LoggerService().warning('$name: Error destroying daemon $iconId: $e');
      daemon.process.kill();
    }
  }

  @override
  Future<void> dispose() async {
    // Kill all daemon processes
    for (final daemon in _daemons.values) {
      try {
        await daemon.process.stdin.close();
        daemon.process.kill();
      } catch (_) {}
    }
    _daemons.clear();
    _nextId = 0;
    _initialized = false;
    LoggerService().info('$name: Disposed');
  }
}

class _DaemonProcess {
  _DaemonProcess({
    required this.id,
    required this.pluginId,
    required this.process,
  });

  final int id;
  final String pluginId;
  final Process process;
}
