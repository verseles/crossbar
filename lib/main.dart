import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'core/plugin_manager.dart';
import 'services/hot_reload_service.dart';
import 'services/ipc_server.dart';
import 'services/logger_service.dart';
import 'services/scheduler_service.dart';
import 'services/settings_service.dart';
import 'services/tray_service.dart';
import 'services/window_service.dart';
import 'ui/main_window.dart';

void main(List<String> args) async {
  // ignore: unnecessary_lambdas
  FlutterError.onError = (details) {
    // Log Flutter errors to console/file in debug mode
    FlutterError.dumpErrorToConsole(details);
    // In production, send to error tracking service
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    // Log unhandled errors
    // ignore: avoid_print
    print('Uncaught error: $error');
    // ignore: avoid_print
    print('Stack trace: $stack');
    return true;
  };

  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize services
    final logger = LoggerService();
    await logger.init();
    logger.info('Crossbar starting...');

    final startMinimized = args.contains('--minimized');

    // Initialize WindowService first
    final windowService = WindowService();
    await windowService.init(startMinimized: startMinimized);
    logger.info('Window service initialized (minimized: $startMinimized)');

    // Initialize settings
    final settings = SettingsService();
    await settings.init();
    logger.info('Settings initialized');

    // Check for existing instance EARLY - before initializing scheduler/tray
    final ipcServer = IpcServer();
    final ipcStarted = await ipcServer.start();

    if (!ipcStarted) {
      logger.info('IPC server failed to start (port busy). Another instance is likely running.');

      if (!startMinimized) {
        // If we wanted to start visible, try to tell the existing instance to show itself
        logger.info('Attempting to signal existing instance to show window...');
        try {
          final client = HttpClient();
          final request = await client.getUrl(Uri.parse('http://localhost:${IpcServer.defaultPort}/window/show'));
          final response = await request.close();
          if (response.statusCode == HttpStatus.ok) {
            logger.info('Signal sent successfully.');
          } else {
            logger.info('Signal sent but received status ${response.statusCode}');
          }
        } catch (e) {
          logger.info('Failed to contact existing instance: $e');
        }
      }

      logger.info('Exiting application.');
      exit(0);
    }

    logger.info('IPC server started on port ${ipcServer.port}');

    // Now that we know we're the primary instance, continue initialization

    // Discover plugins
    final pluginManager = PluginManager();
    await pluginManager.discoverPlugins();
    logger.info('Discovered ${pluginManager.plugins.length} plugins');

    // Initialize tray service
    final trayService = TrayService();
    // Do not await tray initialization to prevent blocking UI startup
    // Also add a small delay to ensure window is ready
    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        await trayService.init();
        logger.info('Tray service initialized');
      } catch (e, stack) {
        logger.error('Failed to initialize tray service', e, stack);
      }
    });

    // Start scheduler
    final scheduler = SchedulerService();
    // Connect tray to scheduler before starting, so we catch initial runs if any
    scheduler.addListener(trayService.updatePluginOutput);
    await scheduler.start();
    logger.info('Scheduler started');

    // Initialize hot reload
    final hotReload = HotReloadService();
    await hotReload.init();
    logger.info('Hot reload initialized');

    runApp(const CrossbarApp());
  } catch (e, stack) {
    // Catch any errors during initialization
    // ignore: avoid_print
    print('Failed to initialize: $e');
    // ignore: avoid_print
    print('Stack trace: $stack');

    // Run app with error screen
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Failed to start Crossbar',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Error: $e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}

class CrossbarApp extends StatelessWidget {
  const CrossbarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainWindow();
  }
}
