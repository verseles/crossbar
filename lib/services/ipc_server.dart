import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../core/plugin_manager.dart';
import 'window_service.dart';

/// IPC Server for GUI ↔ background communication
/// Runs on localhost:48291 and provides REST API for plugin management
class IpcServer {
  IpcServer({
    PluginManager? pluginManager,
    this.port = defaultPort,
  }) : _pluginManager = pluginManager ?? PluginManager();

  static const int defaultPort = 48291;
  static const String host = 'localhost';

  HttpServer? _server;
  final PluginManager _pluginManager;
  final int port;

  bool get isRunning => _server != null;

  /// Start the IPC server
  Future<bool> start() async {
    if (_server != null) {
      return true; // Already running
    }

    try {
      _server = await HttpServer.bind(host, port);
      _server!.listen(_handleRequest);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Stop the IPC server
  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  /// Handle incoming HTTP requests
  Future<void> _handleRequest(HttpRequest request) async {
    // Add CORS headers for local development
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type');
    request.response.headers.contentType = ContentType.json;

    // Handle OPTIONS for CORS preflight
    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      return;
    }

    try {
      final path = request.uri.path;

      // Route the request
      switch (path) {
        case '/status':
          await _handleStatus(request);
        case '/plugins':
          await _handlePlugins(request);
        case '/plugins/refresh':
          await _handleRefresh(request);
        case '/health':
          await _handleHealth(request);
        case '/window/show':
          await _handleWindowAction(request, 'show');
        case '/window/hide':
          await _handleWindowAction(request, 'hide');
        case '/window/quit':
          await _handleWindowAction(request, 'quit');
        default:
          if (path.startsWith('/plugins/')) {
            await _handlePluginAction(request, path);
          } else {
            _sendError(request, HttpStatus.notFound, 'Not found');
          }
      }
    } catch (e) {
      _sendError(request, HttpStatus.internalServerError, e.toString());
    }
  }

  /// GET /status - Get overall server status
  Future<void> _handleStatus(HttpRequest request) async {
    if (request.method != 'GET') {
      _sendError(request, HttpStatus.methodNotAllowed, 'Method not allowed');
      return;
    }

    final response = {
      'status': 'running',
      'port': port,
      'version': '1.0.0',
      'plugins': {
        'total': _pluginManager.plugins.length,
        'enabled': _pluginManager.plugins.where((p) => p.enabled).length,
      },
    };

    _sendJson(request, response);
  }

  /// GET /plugins - List all plugins
  /// POST /plugins - Not implemented (use CLI)
  Future<void> _handlePlugins(HttpRequest request) async {
    if (request.method != 'GET') {
      _sendError(request, HttpStatus.methodNotAllowed, 'Method not allowed');
      return;
    }

    final plugins = _pluginManager.plugins.map((p) => {
      'id': p.id,
      'path': p.path,
      'interpreter': p.interpreter,
      'enabled': p.enabled,
      'refreshInterval': p.refreshInterval.inMilliseconds,
      'lastRun': p.lastRun?.toIso8601String(),
      'lastError': p.lastError,
    }).toList();

    _sendJson(request, {'plugins': plugins});
  }

  /// POST /plugins/refresh - Refresh all plugins
  Future<void> _handleRefresh(HttpRequest request) async {
    if (request.method != 'POST') {
      _sendError(request, HttpStatus.methodNotAllowed, 'Method not allowed');
      return;
    }

    await _pluginManager.runAllEnabled();
    _sendJson(request, {'status': 'ok', 'message': 'Plugins refreshed'});
  }

  /// GET /health - Health check endpoint
  Future<void> _handleHealth(HttpRequest request) async {
    if (request.method != 'GET') {
      _sendError(request, HttpStatus.methodNotAllowed, 'Method not allowed');
      return;
    }

    _sendJson(request, {'status': 'healthy', 'timestamp': DateTime.now().toIso8601String()});
  }

  /// Handle window actions (show, hide, quit)
  Future<void> _handleWindowAction(HttpRequest request, String action) async {
    if (request.method != 'GET' && request.method != 'POST') {
      _sendError(request, HttpStatus.methodNotAllowed, 'Method not allowed');
      return;
    }

    try {
      switch (action) {
        case 'show':
          await WindowService().show();
        case 'hide':
          await WindowService().hide();
        case 'quit':
          await WindowService().quit();
      }
      _sendJson(request, {'status': 'ok', 'action': action});
    } catch (e) {
      _sendError(request, HttpStatus.internalServerError, e.toString());
    }
  }

  /// Handle plugin-specific actions
  /// GET /plugins/:id - Get plugin details
  /// PUT /plugins/:id/enable - Enable plugin
  /// PUT /plugins/:id/disable - Disable plugin
  /// POST /plugins/:id/run - Run plugin
  Future<void> _handlePluginAction(HttpRequest request, String path) async {
    final parts = path.split('/').where((p) => p.isNotEmpty).toList();

    if (parts.length < 2) {
      _sendError(request, HttpStatus.badRequest, 'Invalid path');
      return;
    }

    final pluginId = Uri.decodeComponent(parts[1]);
    final action = parts.length > 2 ? parts[2] : null;

    final plugin = _pluginManager.getPlugin(pluginId);
    if (plugin == null) {
      _sendError(request, HttpStatus.notFound, 'Plugin not found: $pluginId');
      return;
    }

    if (action == null && request.method == 'GET') {
      // GET /plugins/:id - Get plugin details
      _sendJson(request, {
        'id': plugin.id,
        'path': plugin.path,
        'interpreter': plugin.interpreter,
        'enabled': plugin.enabled,
        'refreshInterval': plugin.refreshInterval.inMilliseconds,
        'lastRun': plugin.lastRun?.toIso8601String(),
        'lastError': plugin.lastError,
      });
      return;
    }

    if (request.method != 'PUT' && request.method != 'POST') {
      _sendError(request, HttpStatus.methodNotAllowed, 'Method not allowed');
      return;
    }

    switch (action) {
      case 'enable':
        _pluginManager.enablePlugin(pluginId);
        _sendJson(request, {'status': 'ok', 'message': 'Plugin enabled', 'id': pluginId});

      case 'disable':
        _pluginManager.disablePlugin(pluginId);
        _sendJson(request, {'status': 'ok', 'message': 'Plugin disabled', 'id': pluginId});

      case 'toggle':
        _pluginManager.togglePlugin(pluginId);
        final p = _pluginManager.getPlugin(pluginId);
        _sendJson(request, {
          'status': 'ok',
          'message': 'Plugin toggled',
          'id': pluginId,
          'enabled': p?.enabled ?? false,
        });

      case 'run':
        final output = await _pluginManager.runPlugin(pluginId);
        if (output != null) {
          _sendJson(request, {
            'status': 'ok',
            'output': {
              'pluginId': output.pluginId,
              'icon': output.icon,
              'text': output.text,
              'hasError': output.hasError,
              'errorMessage': output.errorMessage,
            },
          });
        } else {
          _sendError(request, HttpStatus.internalServerError, 'Failed to run plugin');
        }

      default:
        _sendError(request, HttpStatus.notFound, 'Unknown action: $action');
    }
  }

  /// Send JSON response
  void _sendJson(HttpRequest request, Map<String, dynamic> data) {
    request.response.statusCode = HttpStatus.ok;
    request.response.write(jsonEncode(data));
    request.response.close();
  }

  /// Send error response
  void _sendError(HttpRequest request, int statusCode, String message) {
    request.response.statusCode = statusCode;
    request.response.write(jsonEncode({'error': message}));
    request.response.close();
  }
}
