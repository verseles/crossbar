import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'models/battery_info.dart';
import 'models/memory_info.dart';
import 'models/web_response.dart';

/// Main Crossbar API class for creating compiled plugins
///
/// All methods are static for easy access without instantiation.
///
/// Example:
/// ```dart
/// import 'package:crossbar_api/crossbar_api.dart';
///
/// void main() async {
///   final cpu = await Crossbar.cpu();
///   final time = Crossbar.time();
///   print('$time | CPU: $cpu%');
/// }
/// ```
class Crossbar {
  Crossbar._();

  static final Dio _dio = Dio();
  static final Uuid _uuid = const Uuid();

  // ============ System APIs ============

  /// Get CPU usage percentage (0-100)
  static Future<double> cpu() async {
    if (Platform.isLinux) {
      final result = await Process.run('bash', [
        '-c',
        r"top -bn1 | grep 'Cpu(s)' | awk '{print 100 - \$8}'"
      ]);
      return double.tryParse(result.stdout.toString().trim()) ?? 0.0;
    }
    if (Platform.isMacOS) {
      final result = await Process.run('bash', [
        '-c',
        r"top -l 1 | grep 'CPU usage' | awk '{print \$3}' | tr -d '%'"
      ]);
      return double.tryParse(result.stdout.toString().trim()) ?? 0.0;
    }
    if (Platform.isWindows) {
      final result = await Process.run('powershell', [
        '-command',
        r"(Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue"
      ]);
      return double.tryParse(result.stdout.toString().trim()) ?? 0.0;
    }
    return 0.0;
  }

  /// Get memory usage information
  static Future<MemoryInfo> memory() async {
    if (Platform.isLinux) {
      final result = await Process.run('free', ['-m']);
      final lines = result.stdout.toString().split('\n');
      if (lines.length > 1) {
        final parts = lines[1].split(RegExp(r'\s+'));
        if (parts.length >= 3) {
          final total = int.tryParse(parts[1]) ?? 0;
          final used = int.tryParse(parts[2]) ?? 0;
          return MemoryInfo(
            total: total,
            used: used,
            free: total - used,
            unit: 'MB',
          );
        }
      }
    }
    if (Platform.isMacOS) {
      final result = await Process.run('vm_stat', []);
      final output = result.stdout.toString();
      final pageSize = 4096;
      final freeMatch = RegExp(r'Pages free:\s+(\d+)').firstMatch(output);
      final activeMatch = RegExp(r'Pages active:\s+(\d+)').firstMatch(output);
      final inactiveMatch = RegExp(r'Pages inactive:\s+(\d+)').firstMatch(output);
      final wiredMatch = RegExp(r'Pages wired down:\s+(\d+)').firstMatch(output);
      
      final free = (int.tryParse(freeMatch?.group(1) ?? '0') ?? 0) * pageSize ~/ 1048576;
      final active = (int.tryParse(activeMatch?.group(1) ?? '0') ?? 0) * pageSize ~/ 1048576;
      final inactive = (int.tryParse(inactiveMatch?.group(1) ?? '0') ?? 0) * pageSize ~/ 1048576;
      final wired = (int.tryParse(wiredMatch?.group(1) ?? '0') ?? 0) * pageSize ~/ 1048576;
      
      final used = active + inactive + wired;
      final total = used + free;
      
      return MemoryInfo(total: total, used: used, free: free, unit: 'MB');
    }
    return MemoryInfo(total: 0, used: 0, free: 0, unit: 'MB');
  }

  /// Get battery information
  static Future<BatteryInfo> battery() async {
    if (Platform.isLinux) {
      try {
        final capacityFile = File('/sys/class/power_supply/BAT0/capacity');
        final statusFile = File('/sys/class/power_supply/BAT0/status');
        if (await capacityFile.exists()) {
          final level = int.tryParse(await capacityFile.readAsString().then((s) => s.trim())) ?? 0;
          final status = await statusFile.exists() ? await statusFile.readAsString().then((s) => s.trim()) : 'Unknown';
          return BatteryInfo(
            level: level,
            charging: status == 'Charging',
            status: status,
          );
        }
      } catch (_) {}
    }
    if (Platform.isMacOS) {
      final result = await Process.run('pmset', ['-g', 'batt']);
      final output = result.stdout.toString();
      final match = RegExp(r'(\d+)%').firstMatch(output);
      final level = int.tryParse(match?.group(1) ?? '0') ?? 0;
      final charging = output.contains('charging') || output.contains('AC Power');
      return BatteryInfo(level: level, charging: charging, status: charging ? 'Charging' : 'Discharging');
    }
    return BatteryInfo(level: 100, charging: false, status: 'Unknown');
  }

  /// Get system uptime as formatted string
  static Future<String> uptime() async {
    if (Platform.isLinux || Platform.isMacOS) {
      final result = await Process.run('uptime', ['-p']);
      return result.stdout.toString().trim().replaceFirst('up ', '');
    }
    if (Platform.isWindows) {
      final result = await Process.run('net', ['stats', 'workstation']);
      final output = result.stdout.toString();
      final match = RegExp(r'Statistics since (.+)').firstMatch(output);
      return match?.group(1) ?? 'Unknown';
    }
    return 'Unknown';
  }

  /// Get disk usage information
  static Future<Map<String, dynamic>> disk() async {
    if (Platform.isLinux || Platform.isMacOS) {
      final result = await Process.run('df', ['-h', '/']);
      final lines = result.stdout.toString().split('\n');
      if (lines.length > 1) {
        final parts = lines[1].split(RegExp(r'\s+'));
        if (parts.length >= 5) {
          return {
            'total': parts[1],
            'used': parts[2],
            'available': parts[3],
            'percent': parts[4],
          };
        }
      }
    }
    return {'total': '0', 'used': '0', 'available': '0', 'percent': '0%'};
  }

  /// Get operating system name
  static String os() => Platform.operatingSystem;

  /// Get detailed OS information
  static Future<Map<String, String>> osDetails() async {
    return {
      'os': Platform.operatingSystem,
      'version': Platform.operatingSystemVersion,
      'locale': Platform.localeName,
      'hostname': Platform.localHostname,
    };
  }

  // ============ Time APIs ============

  /// Get current time with optional format
  static String time([String format = 'HH:mm:ss']) {
    return DateFormat(format).format(DateTime.now());
  }

  /// Get current date with optional format
  static String date([String format = 'yyyy-MM-dd']) {
    return DateFormat(format).format(DateTime.now());
  }

  // ============ Network APIs ============

  /// Make HTTP request
  static Future<WebResponse> web(
    String url, {
    String method = 'GET',
    Map<String, String>? headers,
    dynamic body,
    int timeout = 30,
  }) async {
    try {
      final response = await _dio.request(
        url,
        options: Options(
          method: method,
          headers: headers,
          receiveTimeout: Duration(seconds: timeout),
          sendTimeout: Duration(seconds: timeout),
        ),
        data: body,
      );
      return WebResponse(
        statusCode: response.statusCode ?? 0,
        body: response.data,
        headers: response.headers.map.map((k, v) => MapEntry(k, v.join(', '))),
      );
    } on DioException catch (e) {
      return WebResponse(
        statusCode: e.response?.statusCode ?? 0,
        body: null,
        error: e.message,
      );
    }
  }

  /// Check if network is available
  static Future<bool> netStatus() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Get local IP address
  static Future<String> localIp() async {
    try {
      final interfaces = await NetworkInterface.list();
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (_) {}
    return '127.0.0.1';
  }

  /// Get public IP address
  static Future<String> publicIp() async {
    try {
      final response = await web('https://api.ipify.org');
      return response.body?.toString() ?? 'Unknown';
    } catch (_) {
      return 'Unknown';
    }
  }

  /// Ping a host and return latency in ms
  static Future<int> ping(String host) async {
    try {
      final result = await Process.run('ping', ['-c', '1', '-W', '5', host]);
      final output = result.stdout.toString();
      final match = RegExp(r'time[=<](\d+\.?\d*)').firstMatch(output);
      if (match != null) {
        return double.parse(match.group(1)!).round();
      }
    } catch (_) {}
    return -1;
  }

  // ============ Utility APIs ============

  /// Execute shell command
  static Future<String> exec(String command) async {
    try {
      final result = await Process.run(
        Platform.isWindows ? 'cmd' : 'sh',
        Platform.isWindows ? ['/c', command] : ['-c', command],
      );
      return result.stdout.toString().trim();
    } catch (e) {
      return 'Error: $e';
    }
  }

  /// Send desktop notification
  static Future<bool> notify(String title, String message) async {
    try {
      if (Platform.isLinux) {
        final result = await Process.run('notify-send', [title, message]);
        return result.exitCode == 0;
      }
      if (Platform.isMacOS) {
        final result = await Process.run('osascript', [
          '-e',
          'display notification "$message" with title "$title"'
        ]);
        return result.exitCode == 0;
      }
    } catch (_) {}
    return false;
  }

  /// Get clipboard content
  static Future<String> clipboard() async {
    try {
      if (Platform.isLinux) {
        final result = await Process.run('xclip', ['-selection', 'clipboard', '-o']);
        return result.stdout.toString();
      }
      if (Platform.isMacOS) {
        final result = await Process.run('pbpaste', []);
        return result.stdout.toString();
      }
    } catch (_) {}
    return '';
  }

  /// Set clipboard content
  static Future<bool> setClipboard(String content) async {
    try {
      if (Platform.isLinux) {
        final process = await Process.start('xclip', ['-selection', 'clipboard']);
        process.stdin.write(content);
        await process.stdin.close();
        return true;
      }
      if (Platform.isMacOS) {
        final process = await Process.start('pbcopy', []);
        process.stdin.write(content);
        await process.stdin.close();
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Open URL in default browser
  static Future<bool> openUrl(String url) async {
    try {
      if (Platform.isLinux) {
        await Process.run('xdg-open', [url]);
        return true;
      }
      if (Platform.isMacOS) {
        await Process.run('open', [url]);
        return true;
      }
      if (Platform.isWindows) {
        await Process.run('start', [url], runInShell: true);
        return true;
      }
    } catch (_) {}
    return false;
  }

  // ============ Environment APIs ============

  /// Get environment variable
  static String? env(String name) => Platform.environment[name];

  /// Get home directory
  static String get homeDir =>
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';

  /// Get temp directory
  static String get tempDir => Directory.systemTemp.path;

  /// Get current platform name
  static String get platform => Platform.operatingSystem;

  /// Check if running on mobile
  static bool get isMobile => Platform.isAndroid || Platform.isIOS;

  /// Check if running on desktop
  static bool get isDesktop =>
      Platform.isLinux || Platform.isMacOS || Platform.isWindows;

  // ============ Encoding APIs ============

  /// Generate MD5 hash
  static String hashMd5(String input) =>
      md5.convert(utf8.encode(input)).toString();

  /// Generate SHA256 hash
  static String hashSha256(String input) =>
      sha256.convert(utf8.encode(input)).toString();

  /// Generate UUID v4
  static String uuid() => _uuid.v4();

  /// Base64 encode
  static String base64Encode(String input) => base64.encode(utf8.encode(input));

  /// Base64 decode
  static String base64Decode(String input) =>
      utf8.decode(base64.decode(input));
}
