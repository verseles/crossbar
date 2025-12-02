import 'dart:ui';

import 'package:flutter/material.dart';

import 'core/plugin_manager.dart';
import 'services/hot_reload_service.dart';
import 'services/logger_service.dart';
import 'services/scheduler_service.dart';
import 'ui/main_window.dart';

void main(List<String> args) async {
  FlutterError.onError = (details) {
    // Log Flutter errors to console/file in debug mode
    FlutterError.dumpErrorToConsole(details);
    // In production, send to error tracking service
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    // Log unhandled errors
    print('Uncaught error: $error');
    print('Stack trace: $stack');
    return true;
  };

  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize services
    final logger = LoggerService();
    await logger.init();
    logger.info('Crossbar starting...');

    // Discover plugins
    final pluginManager = PluginManager();
    await pluginManager.discoverPlugins();
    logger.info('Discovered ${pluginManager.plugins.length} plugins');

    // Start scheduler
    final scheduler = SchedulerService();
    await scheduler.start();
    logger.info('Scheduler started');

    // Initialize hot reload
    final hotReload = HotReloadService();
    await hotReload.init();
    logger.info('Hot reload initialized');

    runApp(const CrossbarApp());
  } catch (e, stack) {
    // Catch any errors during initialization
    print('Failed to initialize: $e');
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
