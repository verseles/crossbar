import 'package:flutter/material.dart';

import 'core/plugin_manager.dart';
import 'services/hot_reload_service.dart';
import 'services/logger_service.dart';
import 'services/scheduler_service.dart';
import 'ui/main_window.dart';

void main() async {
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
}

class CrossbarApp extends StatelessWidget {
  const CrossbarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainWindow();
  }
}
