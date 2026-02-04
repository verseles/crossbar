import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

import '../../api/network_api.dart';
import '../../api/system_api.dart';
import '../../api/utils_api.dart';
import 'android_bridge_interface.dart';
import 'android_bridge_stub.dart'; // Default to stub

/// CrossbarBridge - Unified API for plugins across all platforms
class CrossbarBridge {
  factory CrossbarBridge() => instance;
  CrossbarBridge._();

  static final CrossbarBridge instance = CrossbarBridge._();

  final SystemApi _systemApi = SystemApi();
  final NetworkApi _networkApi = const NetworkApi();
  final UtilsApi _utilsApi = const UtilsApi();

  AndroidBridgeInterface _androidBridge =
      AndroidNativeBridge(); // Default to stub

  String? _appDataDir;

  /// Optional app-private data directory (mobile).
  set appDataDir(String? value) => _appDataDir = value;
  String? get appDataDir => _appDataDir;

  /// Inject a platform-specific implementation (e.g. from Flutter)
  set androidBridge(AndroidBridgeInterface bridge) => _androidBridge = bridge;

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

  Future<double> cpu() async {
    if (Platform.isAndroid) return 0.0;
    final result = await _systemApi.getCpuUsage();
    return double.tryParse(result.replaceAll('%', '')) ?? 0.0;
  }

  double cpuSync() {
    if (Platform.isAndroid) return 0.0;
    final result = _systemApi.getCpuUsageSync();
    return double.tryParse(result.replaceAll('%', '')) ?? 0.0;
  }

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

  Future<Map<String, dynamic>> battery() async {
    if (Platform.isAndroid) {
      final nativeResult = await _androidBridge.getBatteryStatus();
      if (nativeResult != null) {
        final parsed = _parseAndroidBatteryResult(nativeResult);
        _androidBatteryCache = parsed;
        _androidBatteryCacheTime = DateTime.now();
        return parsed;
      }
    }
    final result = await _systemApi.getBatteryStatus();
    return _parseBatteryResult(result);
  }

  Map<String, dynamic> batterySync() {
    if (Platform.isAndroid) {
      if (_androidBatteryCache != null &&
          _androidBatteryCacheTime != null &&
          DateTime.now().difference(_androidBatteryCacheTime!).inSeconds < 5) {
        return _androidBatteryCache!;
      }
      battery(); // Fire and forget update
      return _androidBatteryCache ??
          {
            'level': null,
            'charging': false,
            'status': 'Initializing...',
            'available': false,
          };
    }
    final result = _systemApi.getBatteryStatusSync();
    return _parseBatteryResult(result);
  }

  Map<String, dynamic> _parseBatteryResult(String result) {
    final match = RegExp(r'(\d+)%').firstMatch(result);
    final isCharging =
        result.contains('⚡') || result.toLowerCase().contains('charging');

    return {
      'level': match != null ? int.parse(match.group(1)!) : null,
      'charging': isCharging,
      'status': result,
      'available': !result.toLowerCase().contains('unavailable') &&
          !result.toLowerCase().contains('no battery') &&
          !result.toLowerCase().contains('n/a'),
    };
  }

  Map<String, dynamic> _parseAndroidBatteryResult(Map<String, dynamic> result) {
    return {
      'level': result['level'],
      'charging': result['isCharging'] ?? false,
      'status': result['status'] ?? 'unknown',
      'available': true,
    };
  }

  Future<String> uptime() async {
    if (Platform.isAndroid) {
      final nativeResult = await _androidBridge.getUptime();
      return nativeResult ?? 'Unknown';
    }
    return _systemApi.getUptime();
  }

  String uptimeSync() {
    if (Platform.isAndroid) {
      return _androidBridge.getUptimeSync() ?? 'Unknown';
    }
    return _systemApi.getUptimeSync();
  }

  Future<String> disk([String? path]) async => _systemApi.getDiskUsage(path);
  Future<String> os() async => _systemApi.getOs();
  Future<Map<String, dynamic>> osDetails() async => _systemApi.getOsDetails();

  // ═══════════════════════════════════════════════════════════════
  // TIME & DATE
  // ═══════════════════════════════════════════════════════════════

  String time([String format = 'HH:mm:ss']) {
    final now = DateTime.now();
    switch (format) {
      case 'HH:mm':
        return '${_pad(now.hour)}:${_pad(now.minute)}';
      case 'HH:mm:ss':
        return '${_pad(now.hour)}:${_pad(now.minute)}:${_pad(now.second)}';
      case 'h:mm a':
        final hour =
            now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
        final ampm = now.hour >= 12 ? 'PM' : 'AM';
        return '$hour:${_pad(now.minute)} $ampm';
      case 'HH:mm:ss.SSS':
        return '${_pad(now.hour)}:${_pad(now.minute)}:${_pad(now.second)}.${_pad(now.millisecond, 3)}';
      default:
        return now.toIso8601String();
    }
  }

  String date([String format = 'yyyy-MM-dd']) {
    final now = DateTime.now();
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

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
  // NETWORK & UTILS
  // ═══════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> web(
    String url, {
    String method = 'GET',
    Map<String, String>? headers,
    dynamic body,
    int timeout = 30,
  }) async {
    final fullUrl = url.startsWith('http') ? url : 'https://$url';
    try {
      final response = await _dio.request<dynamic>(
        fullUrl,
        data: body,
        options: Options(
          method: method,
          headers: headers,
          receiveTimeout: Duration(seconds: timeout),
          sendTimeout: Duration(seconds: timeout),
          validateStatus: (status) => true,
        ),
      );
      return _buildWebResponse(response);
    } on DioException catch (e) {
      final response = e.response;
      if (response != null) {
        final result = _buildWebResponse(response);
        result['error'] = true;
        result['message'] = e.message ?? 'Request failed';
        return result;
      }
      return {
        'error': true,
        'message': e.message ?? e.toString(),
      };
    } catch (e) {
      return {
        'error': true,
        'message': e.toString(),
      };
    }
  }

  Map<String, dynamic> _buildWebResponse(Response<dynamic> response) {
    return {
      'status': response.statusCode,
      'statusMessage': response.statusMessage,
      'data': response.data,
      'headers': response.headers.map.map(
        (key, value) => MapEntry(key, value.length == 1 ? value.first : value),
      ),
    };
  }

  Future<String> netStatus() async => _networkApi.getNetStatus();
  Future<String> localIp() async => _networkApi.getLocalIp();
  Future<String> publicIp() async => _networkApi.getPublicIp();
  Future<String> wifiSsid() async => _networkApi.getWifiSsid();
  Future<String> ping(String host) async => _networkApi.ping(host);

  Future<String> clipboard() async {
    if (Platform.isLinux) {
      final res = await Process.run('xclip', ['-selection', 'clipboard', '-o']);
      return res.exitCode == 0 ? (res.stdout as String).trim() : '';
    }
    return '';
  }

  Future<String> exec(String command) async {
    final res = await Process.run(Platform.isWindows ? 'cmd' : 'sh',
        [Platform.isWindows ? '/c' : '-c', command]);
    return (res.stdout as String).trim();
  }

  String execSync(String command) {
    final res = Process.runSync(Platform.isWindows ? 'cmd' : 'sh',
        [Platform.isWindows ? '/c' : '-c', command]);
    return (res.stdout as String).trim();
  }

  String hash(String input) => sha256.convert(utf8.encode(input)).toString();
  String uuid() => Uuid().v4();
  String base64Encode(String input) => base64.encode(utf8.encode(input));
  String base64Decode(String input) => utf8.decode(base64.decode(input));
  int random([int max = 100]) => DateTime.now().microsecond % max;

  String get platform => Platform.operatingSystem;
  bool get isMobile => Platform.isAndroid || Platform.isIOS;
  bool get isDesktop => !isMobile;
  Future<void> notify(String title, String message, {String? icon}) async {
    await _utilsApi.sendNotification(
      title: title,
      message: message,
      icon: icon,
    );
  }

  Future<void> openUrl(String url) async {
    await _utilsApi.openUrl(url);
  }

  Future<void> openFile(String path) async {
    await _utilsApi.openFile(path);
  }

  // ═══════════════════════════════════════════════════════════════
  // ENVIRONMENT
  // ═══════════════════════════════════════════════════════════════

  String? env(String name) => Platform.environment[name];
  Map<String, String> get envAll => Platform.environment;

  String get homeDir =>
      Platform.environment['HOME'] ??
      Platform.environment['USERPROFILE'] ??
      '~';
  String get tempDir => Directory.systemTemp.path;
}

final crossbar = CrossbarBridge.instance;
