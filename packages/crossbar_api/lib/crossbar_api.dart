/// Crossbar API - Official Dart package for creating compiled Crossbar plugins
///
/// This package provides a type-safe API for building plugins that can use
/// any Dart package and compile to native binaries for maximum performance.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:crossbar_api/crossbar_api.dart';
///
/// void main() async {
///   final cpu = await Crossbar.cpu();
///   print('💻 $cpu%');
/// }
/// ```
///
/// ## Key Features
///
/// - **Full IntelliSense**: Complete IDE support with autocompletion
/// - **Type Safety**: All methods are strongly typed
/// - **Any Package**: Use any pub.dev package in your plugins
/// - **Native Performance**: Compile to fast native binaries
///
/// ## Available APIs
///
/// ### System
/// - [Crossbar.cpu] - CPU usage percentage
/// - [Crossbar.memory] - Memory usage stats
/// - [Crossbar.battery] - Battery level and status
/// - [Crossbar.uptime] - System uptime
/// - [Crossbar.disk] - Disk usage
/// - [Crossbar.os] - Operating system name
///
/// ### Time
/// - [Crossbar.time] - Current time with format
/// - [Crossbar.date] - Current date with format
///
/// ### Network
/// - [Crossbar.web] - HTTP requests
/// - [Crossbar.netStatus] - Online/offline status
/// - [Crossbar.localIp] - Local IP address
/// - [Crossbar.publicIp] - Public IP address
/// - [Crossbar.ping] - Network latency
///
/// ### Utilities
/// - [Crossbar.exec] - Run shell commands
/// - [Crossbar.notify] - Send notifications
/// - [Crossbar.clipboard] - Clipboard access
/// - [Crossbar.openUrl] - Open URLs
library crossbar_api;

export 'src/crossbar.dart';
export 'src/models/memory_info.dart';
export 'src/models/battery_info.dart';
export 'src/models/web_response.dart';
