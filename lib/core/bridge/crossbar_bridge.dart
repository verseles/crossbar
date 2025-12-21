import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../api/android_native_bridge.dart';
import '../api/network_api.dart';
import '../api/system_api.dart';
import '../api/utils_api.dart';

/// CrossbarBridge - Unified API for plugins across all platforms
/// 
/// This bridge provides a consistent interface for plugins to access
/// system information and utilities. It works on:
/// - Desktop (Linux, macOS, Windows): Uses native APIs via Process.run
/// - Mobile (Android, iOS): Uses Flutter plugins (battery_plus, etc.)
/// 
/// Usage in interpreted plugins (DartRunner):
/// ```dart
/// final cpu = await crossbar.cpu();
/// final weather = await crossbar.web('api.example.com/weather');
/// ```
class CrossbarBridge {
  factory CrossbarBridge() => instance;
  CrossbarBridge._();
  
  static final CrossbarBridge instance = CrossbarBridge._();

  final SystemApi _systemApi = SystemApi();
  final NetworkApi _networkApi = const NetworkApi();
  final UtilsApi _utilsApi = const UtilsApi();
  final AndroidNativeBridge _androidBridge = AndroidNativeBridge();

  // Cache for Android battery status (platform channels are async)
  Map<String, dynamic>? _androidBatteryCache;
  DateTime? _androidBatteryCacheTime;
  
  late final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));
  
  // ═══════════════════════════════════════════════════════════════
  // SYSTEM INFORMATION
  // ═══════════════════════════════════════════════════════════════
  
  /// Get CPU usage percentage (0-100)
  Future<double> cpu() async {
    final result = await _systemApi.getCpuUsage();
    return double.tryParse(result.replaceAll('%', '')) ?? 0.0;
  }

  /// Get CPU usage percentage synchronously (Stateful)
  double cpuSync() {
    final result = _systemApi.getCpuUsageSync();
    return double.tryParse(result.replaceAll('%', '')) ?? 0.0;
  }
  
  /// Get memory usage as map {used, total, unit, percent}
  Future<Map<String, dynamic>> memory() async {
    final result = await _systemApi.getMemoryUsage();
    return _parseMemoryResult(result);
  }

  Map<String, dynamic> memorySync() {
    final result = _systemApi.getMemoryUsageSync();
    return _parseMemoryResult(result);
  }

  Map<String, dynamic> _parseMemoryResult(String result) {
    final parts = result.split('/');
    if (parts.length == 2) {
      final usedStr = parts[0].trim();
      final totalStr = parts[1].trim();
      
      final usedMatch = RegExp(r'([\d.]+)\s*(\w+)?').firstMatch(usedStr);
      final totalMatch = RegExp(r'([\d.]+)\s*(\w+)?').firstMatch(totalStr);
      
      if (usedMatch != null && totalMatch != null) {
        final used = double.tryParse(usedMatch.group(1)!) ?? 0;
        final total = double.tryParse(totalMatch.group(1)!) ?? 1;
        final unit = totalMatch.group(2) ?? 'GB';
        
        return {
          'used': used,
          'total': total,
          'unit': unit,
          'percent': total > 0 ? (used / total * 100).round() : 0,
          'raw': result,
        };
      }
    }
    return {'raw': result};
  }
  
  /// Get battery status as map {level, charging, status}
  Future<Map<String, dynamic>> battery() async {
    // On Android, use native BatteryManager (SELinux blocks /sys access)
    if (Platform.isAndroid) {
      final nativeResult = await _androidBridge.getBatteryStatus();
      if (nativeResult != null) {
        final parsed = _parseAndroidBatteryResult(nativeResult);
        // Update cache for sync calls
        _androidBatteryCache = parsed;
        _androidBatteryCacheTime = DateTime.now();
        return parsed;
      }
    }

    // Fallback to /sys (Linux, macOS, Windows)
    final result = await _systemApi.getBatteryStatus();
    return _parseBatteryResult(result);
  }

  Map<String, dynamic> batterySync() {
    // On Android, use cached value from last async call
    if (Platform.isAndroid) {
      // If cache exists and is fresh (< 5 seconds), use it
      if (_androidBatteryCache != null &&
          _androidBatteryCacheTime != null &&
          DateTime.now().difference(_androidBatteryCacheTime!).inSeconds < 5) {
        return _androidBatteryCache!;
      }

      // Cache is stale or doesn't exist - trigger async update for next time
      battery(); // Fire and forget

      // Return fallback or cached (stale) value
      return _androidBatteryCache ?? {
        'level': null,
        'charging': false,
        'status': 'Initializing...',
        'available': false,
      };
    }

    // Fallback to /sys (Linux, macOS, Windows)
    final result = _systemApi.getBatteryStatusSync();
    return _parseBatteryResult(result);
  }

  Map<String, dynamic> _parseBatteryResult(String result) {
    final match = RegExp(r'(\d+)%').firstMatch(result);
    final isCharging = result.contains('⚡') ||
                       result.toLowerCase().contains('charging');

    return {
      'level': match != null ? int.parse(match.group(1)!) : null,
      'charging': isCharging,
      'status': result,
      'available': !result.toLowerCase().contains('unavailable') &&
                   !result.toLowerCase().contains('no battery') &&
                   !result.toLowerCase().contains('n/a'),
    };
  }

  /// Parse native Android battery result from BatteryManager
  Map<String, dynamic> _parseAndroidBatteryResult(Map<String, dynamic> result) {
    return {
      'level': result['level'],
      'charging': result['isCharging'] ?? false,
      'status': result['status'] ?? 'unknown',
      'available': true,
    };
  }
  
  /// Get system uptime
  Future<String> uptime() async {
    return _systemApi.getUptime();
  }

  /// Get system uptime (sync)
  String uptimeSync() {
    return _systemApi.getUptimeSync();
  }

  /// Get disk usage for path (default: root)
  Future<String> disk([String? path]) async {
    return _systemApi.getDiskUsage(path);
  }
  
  /// Get OS name
  Future<String> os() async {
    return _systemApi.getOs();
  }
  
  /// Get detailed OS info as map
  Future<Map<String, dynamic>> osDetails() async {
    return _systemApi.getOsDetails();
  }
  
  // ═══════════════════════════════════════════════════════════════
  // TIME & DATE
  // ═══════════════════════════════════════════════════════════════
  
  /// Get current time in specified format
  /// Formats: 'HH:mm', 'HH:mm:ss', 'h:mm a', 'HH:mm:ss.SSS'
  String time([String format = 'HH:mm:ss']) {
    final now = DateTime.now();
    
    switch (format) {
      case 'HH:mm':
        return '${_pad(now.hour)}:${_pad(now.minute)}';
      case 'HH:mm:ss':
        return '${_pad(now.hour)}:${_pad(now.minute)}:${_pad(now.second)}';
      case 'h:mm a':
        final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
        final ampm = now.hour >= 12 ? 'PM' : 'AM';
        return '$hour:${_pad(now.minute)} $ampm';
      case 'HH:mm:ss.SSS':
        return '${_pad(now.hour)}:${_pad(now.minute)}:${_pad(now.second)}.${_pad(now.millisecond, 3)}';
      default:
        return now.toIso8601String();
    }
  }
  
  /// Get current date in specified format
  /// Formats: 'yyyy-MM-dd', 'dd/MM/yyyy', 'MM/dd/yyyy', 'EEEE, MMMM d, yyyy'
  String date([String format = 'yyyy-MM-dd']) {
    final now = DateTime.now();
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 
                    'July', 'August', 'September', 'October', 'November', 'December'];
    
    switch (format) {
      case 'yyyy-MM-dd':
        return '${now.year}-${_pad(now.month)}-${_pad(now.day)}';
      case 'dd/MM/yyyy':
        return '${_pad(now.day)}/${_pad(now.month)}/${now.year}';
      case 'MM/dd/yyyy':
        return '${_pad(now.month)}/${_pad(now.day)}/${now.year}';
      case 'EEEE, MMMM d, yyyy':
        return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';
      default:
        return now.toIso8601String().split('T')[0];
    }
  }
  
  String _pad(int n, [int width = 2]) => n.toString().padLeft(width, '0');
  
  // ═══════════════════════════════════════════════════════════════
  // NETWORK
  // ═══════════════════════════════════════════════════════════════
  
  /// Make HTTP request (powered by Dio)
  /// Returns response body as string, or parsed JSON if response is JSON
  Future<dynamic> web(
    String url, {
    String method = 'GET',
    Map<String, String>? headers,
    dynamic body,
    int timeout = 30,
  }) async {
    // Auto-prefix https if needed
    var fullUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      fullUrl = 'https://$url';
    }
    
    try {
      final options = Options(
        method: method,
        headers: headers,
        receiveTimeout: Duration(seconds: timeout),
        sendTimeout: Duration(seconds: timeout),
      );
      
      final response = await _dio.request<dynamic>(
        fullUrl,
        data: body,
        options: options,
      );
      
      // Try to return parsed data if it's already a Map/List
      if (response.data is Map || response.data is List) {
        return response.data;
      }
      
      // Try to parse as JSON
      try {
        return jsonDecode(response.data.toString());
      } catch (_) {
        return response.data.toString();
      }
    } on DioException catch (e) {
      return {
        'error': true,
        'type': e.type.toString(),
        'message': e.message,
        'statusCode': e.response?.statusCode,
      };
    }
  }
  
  /// Get network status (online/offline)
  Future<String> netStatus() async {
    return _networkApi.getNetStatus();
  }
  
  /// Get local IP address
  Future<String> localIp() async {
    return _networkApi.getLocalIp();
  }
  
  /// Get public IP address
  Future<String> publicIp() async {
    return _networkApi.getPublicIp();
  }
  
  /// Get WiFi SSID
  Future<String> wifiSsid() async {
    return _networkApi.getWifiSsid();
  }
  
  /// Ping host and return latency
  Future<String> ping(String host) async {
    return _networkApi.ping(host);
  }
  
  // ═══════════════════════════════════════════════════════════════
  // UTILITIES
  // ═══════════════════════════════════════════════════════════════
  
  /// Get clipboard content
  Future<String> clipboard() async {
    try {
      if (Platform.isLinux) {
        // Try xclip first
        var result = await Process.run('xclip', ['-selection', 'clipboard', '-o']);
        if (result.exitCode == 0) return (result.stdout as String).trim();
        
        // Try xsel
        result = await Process.run('xsel', ['--clipboard', '--output']);
        if (result.exitCode == 0) return (result.stdout as String).trim();
        
        // Try wl-paste for Wayland
        result = await Process.run('wl-paste', []);
        if (result.exitCode == 0) return (result.stdout as String).trim();
      }
      
      if (Platform.isMacOS) {
        final result = await Process.run('pbpaste', []);
        if (result.exitCode == 0) return (result.stdout as String).trim();
      }
      
      if (Platform.isWindows) {
        final result = await Process.run(
          'powershell',
          ['-command', 'Get-Clipboard'],
        );
        if (result.exitCode == 0) return (result.stdout as String).trim();
      }
      
      return '';
    } catch (_) {
      return '';
    }
  }
  
  /// Set clipboard content
  Future<bool> setClipboard(String text) async {
    try {
      if (Platform.isLinux) {
        var result = await Process.run(
          'xclip',
          ['-selection', 'clipboard'],
          runInShell: true,
        );
        if (result.exitCode != 0) {
          // Try wl-copy for Wayland
          result = await Process.run('wl-copy', [text]);
        }
        return result.exitCode == 0;
      }
      
      if (Platform.isMacOS) {
        final result = await Process.run('pbcopy', [], runInShell: true);
        return result.exitCode == 0;
      }
      
      if (Platform.isWindows) {
        final result = await Process.run(
          'powershell',
          ['-command', 'Set-Clipboard', '-Value', text],
        );
        return result.exitCode == 0;
      }
      
      return false;
    } catch (_) {
      return false;
    }
  }
  
  /// Execute shell command and return output
  Future<String> exec(String command) async {
    try {
      final result = await Process.run(
        Platform.isWindows ? 'cmd' : 'sh',
        Platform.isWindows ? ['/c', command] : ['-c', command],
      );
      return (result.stdout as String).trim();
    } catch (e) {
      return 'Error: $e';
    }
  }

  /// Execute shell command synchronously and return output
  String execSync(String command) {
    try {
      final result = Process.runSync(
        Platform.isWindows ? 'cmd' : 'sh',
        Platform.isWindows ? ['/c', command] : ['-c', command],
      );
      return (result.stdout as String).trim();
    } catch (e) {
      return 'Error: $e';
    }
  }
  
  /// Send desktop notification
  Future<void> notify(String title, String message, {String? icon}) async {
    await _utilsApi.sendNotification(
      title: title,
      message: message,
      icon: icon,
    );
  }
  
  /// Open URL in default browser
  Future<void> openUrl(String url) async {
    await _utilsApi.openUrl(url);
  }
  
  /// Open file with default application
  Future<void> openFile(String path) async {
    await _utilsApi.openFile(path);
  }
  
  // ═══════════════════════════════════════════════════════════════
  // ENVIRONMENT
  // ═══════════════════════════════════════════════════════════════
  
  /// Get environment variable
  String? env(String name) {
    return Platform.environment[name];
  }
  
  /// Get all environment variables
  Map<String, String> get envAll => Platform.environment;
  
  /// Get home directory
  String get homeDir {
    return Platform.environment['HOME'] ?? 
           Platform.environment['USERPROFILE'] ?? 
           '~';
  }
  
  /// Get temp directory
  String get tempDir => Directory.systemTemp.path;
  
  /// Get current platform name
  String get platform {
    if (Platform.isLinux) return 'linux';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }
  
  /// Check if running on mobile
  bool get isMobile => Platform.isAndroid || Platform.isIOS;
  
  /// Check if running on desktop
  bool get isDesktop => Platform.isLinux || Platform.isMacOS || Platform.isWindows;
  
  // ═══════════════════════════════════════════════════════════════
  // HASHING & ENCODING
  // ═══════════════════════════════════════════════════════════════
  
  /// Compute SHA256 hash
  String hash(String input) {
    // Using dart:crypto would require importing the package
    // For now, delegate to the CLI
    // In future: use crypto package directly
    try {
      final result = Process.runSync(
        Platform.isWindows ? 'powershell' : 'sh',
        Platform.isWindows 
            ? ['-command', "[System.BitConverter]::ToString([System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes('$input'))).Replace('-','').ToLower()"]
            : ['-c', "echo -n '$input' | sha256sum | cut -d' ' -f1"],
      );
      return (result.stdout as String).trim();
    } catch (_) {
      return '';
    }
  }
  
  /// Generate UUID v4
  String uuid() {
    // Simple UUID v4 generation
    final random = DateTime.now().millisecondsSinceEpoch;
    return '${_hexPart(random, 8)}-${_hexPart(random ~/ 2, 4)}-4${_hexPart(random ~/ 3, 3)}-${_hexPart(random ~/ 4 | 0x8000, 4)}-${_hexPart(random ~/ 5, 12)}';
  }
  
  String _hexPart(int seed, int length) {
    final hex = seed.toRadixString(16);
    return hex.padLeft(length, '0').substring(0, length);
  }
  
  /// Base64 encode
  String base64Encode(String input) {
    return base64.encode(utf8.encode(input));
  }
  
  /// Base64 decode
  String base64Decode(String input) {
    return utf8.decode(base64.decode(input));
  }
  
  /// Generate random number
  int random([int max = 100]) {
    return DateTime.now().microsecond % max;
  }
}

/// Global instance for easy access
final crossbar = CrossbarBridge.instance;
