// ignore_for_file: avoid_slow_async_io
import 'dart:io';

class SystemApi {
  SystemApi();

  // State for CPU calculation (Linux)
  List<int>? _lastLinuxCpuValues;

  Future<String> getCpuUsage() async {
    try {
      if (Platform.isLinux) {
        return _getLinuxCpuUsage();
      }

      if (Platform.isMacOS) {
        return _getMacOsCpuUsage();
      }

      if (Platform.isWindows) {
        return _getWindowsCpuUsage();
      }

      if (Platform.isAndroid) {
        return _getAndroidCpuUsage();
      }

      return '0.0';
    } catch (e) {
      return '0.0';
    }
  }

  /// Synchronous CPU usage (Stateful for Linux/Android)
  String getCpuUsageSync() {
    try {
      if (Platform.isLinux || Platform.isAndroid) {
        return _getLinuxCpuUsageSync();
      }
      return '0.0';
    } catch (e) {
      return '0.0';
    }
  }

  Future<String> _getLinuxCpuUsage() async {
    // Current Async implementation does sleep 100ms.
    // We can keep it or switch to stateful too. Keeping it stateless for async is fine for now.
    final stat1 = await File('/proc/stat').readAsString();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final stat2 = await File('/proc/stat').readAsString();

    final values1 = _parseProcStat(stat1);
    final values2 = _parseProcStat(stat2);

    if (values1 == null || values2 == null) return '0.0';

    final idle1 = values1[3];
    final idle2 = values2[3];
    final total1 = values1.reduce((a, b) => a + b);
    final total2 = values2.reduce((a, b) => a + b);

    final idleDelta = idle2 - idle1;
    final totalDelta = total2 - total1;

    if (totalDelta == 0) return '0.0';

    final usage = (totalDelta - idleDelta) / totalDelta * 100;
    return usage.toStringAsFixed(1);
  }

  String _getLinuxCpuUsageSync() {
    try {
      final content = File('/proc/stat').readAsStringSync();
      final currentValues = _parseProcStat(content);

      if (currentValues == null) return '0.0';

      if (_lastLinuxCpuValues == null) {
        _lastLinuxCpuValues = currentValues;
        return '...'; // Initializing
      }

      final values1 = _lastLinuxCpuValues!;
      final values2 = currentValues;
      
      // Update state for next call (continuous measurement)
      _lastLinuxCpuValues = currentValues;

      final idle1 = values1[3];
      final idle2 = values2[3];
      final total1 = values1.reduce((a, b) => a + b);
      final total2 = values2.reduce((a, b) => a + b);

      final idleDelta = idle2 - idle1;
      final totalDelta = total2 - total1;

      if (totalDelta == 0) return '0.0';

      final usage = (totalDelta - idleDelta) / totalDelta * 100;
      return usage.toStringAsFixed(1);
    } catch (e) {
      return '0.0';
    }
  }

  List<int>? _parseProcStat(String content) {
    final lines = content.split('\n');
    for (final line in lines) {
      if (line.startsWith('cpu ')) {
        final parts = line.split(RegExp(r'\s+')).skip(1).toList();
        if (parts.length >= 4) {
          return parts.take(7).map(int.parse).toList();
        }
      }
    }
    return null;
  }

  Future<String> _getMacOsCpuUsage() async {
    final result = await Process.run(
      'sh',
      ['-c', "top -l1 | grep 'CPU usage'"],
    );

    final match = RegExp(r'(\d+\.\d+)%\s+user').firstMatch(result.stdout as String);
    if (match != null) {
      final userPercent = double.parse(match.group(1)!);
      final sysMatch = RegExp(r'(\d+\.\d+)%\s+sys').firstMatch(result.stdout as String);
      if (sysMatch != null) {
        final sysPercent = double.parse(sysMatch.group(1)!);
        return (userPercent + sysPercent).toStringAsFixed(1);
      }
      return userPercent.toStringAsFixed(1);
    }
    return '0.0';
  }

  Future<String> _getWindowsCpuUsage() async {
    final result = await Process.run(
      'wmic',
      ['cpu', 'get', 'loadpercentage'],
    );

    final match = RegExp(r'(\d+)').firstMatch(result.stdout as String);
    if (match != null) {
      return '${match.group(1)}.0';
    }
    return '0.0';
  }

  /// Android CPU usage via /proc/stat
  /// Note: May be blocked on Android 8+ due to security
  Future<String> _getAndroidCpuUsage() async {
    try {
      // Use /proc/stat (may be blocked on Android 8+)
      final stat1 = await File('/proc/stat').readAsString();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final stat2 = await File('/proc/stat').readAsString();

      final values1 = _parseProcStat(stat1);
      final values2 = _parseProcStat(stat2);

      if (values1 == null || values2 == null) return '0.0';

      final idle1 = values1[3];
      final idle2 = values2[3];
      final total1 = values1.reduce((a, b) => a + b);
      final total2 = values2.reduce((a, b) => a + b);

      final idleDelta = idle2 - idle1;
      final totalDelta = total2 - total1;

      if (totalDelta == 0) return '0.0';

      final usage = (totalDelta - idleDelta) / totalDelta * 100;
      return usage.toStringAsFixed(1);
    } catch (e) {
      return '0.0';
    }
  }

  // MEMORY

  Future<String> getMemoryUsage() async {
    try {
      if (Platform.isLinux || Platform.isAndroid) {
        // Android can also read /proc/meminfo
        return _getLinuxMemoryUsage();
      }
      if (Platform.isMacOS) {
        return _getMacOsMemoryUsage();
      }
      if (Platform.isWindows) {
        return _getWindowsMemoryUsage();
      }
      return 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  String getMemoryUsageSync() {
    try {
      if (Platform.isLinux || Platform.isAndroid) {
        return _getLinuxMemoryUsageSync();
      }
      // TODO: Implement sync for macOS/Windows if needed
      return 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<String> _getLinuxMemoryUsage() async {
    final memInfo = await File('/proc/meminfo').readAsString();
    return _parseLinuxMemory(memInfo);
  }

  String _getLinuxMemoryUsageSync() {
    final memInfo = File('/proc/meminfo').readAsStringSync();
    return _parseLinuxMemory(memInfo);
  }

  String _parseLinuxMemory(String memInfo) {
    final total = _parseMemValue(memInfo, 'MemTotal:');
    final available = _parseMemValue(memInfo, 'MemAvailable:');
    final used = total - available;
    final usedGB = (used / 1024 / 1024).toStringAsFixed(1);
    final totalGB = (total / 1024 / 1024).toStringAsFixed(1);
    return '$usedGB/$totalGB GB';
  }

  int _parseMemValue(String content, String key) {
    final match = RegExp('$key\\s+(\\d+)').firstMatch(content);
    return match != null ? int.parse(match.group(1)!) : 0;
  }

  Future<String> _getMacOsMemoryUsage() async {
    final result = await Process.run('vm_stat', []);
    final output = result.stdout as String;

    const pageSize = 4096;
    final freeMatch = RegExp(r'Pages free:\s+(\d+)').firstMatch(output);
    final activeMatch = RegExp(r'Pages active:\s+(\d+)').firstMatch(output);
    final inactiveMatch = RegExp(r'Pages inactive:\s+(\d+)').firstMatch(output);
    final wiredMatch = RegExp(r'Pages wired down:\s+(\d+)').firstMatch(output);

    if (freeMatch != null && activeMatch != null) {
      final free = int.parse(freeMatch.group(1)!) * pageSize;
      final active = int.parse(activeMatch.group(1)!) * pageSize;
      final inactive = int.parse(inactiveMatch?.group(1) ?? '0') * pageSize;
      final wired = int.parse(wiredMatch?.group(1) ?? '0') * pageSize;

      final used = active + inactive + wired;
      final total = used + free;

      final usedGB = (used / 1024 / 1024 / 1024).toStringAsFixed(1);
      final totalGB = (total / 1024 / 1024 / 1024).toStringAsFixed(1);
      return '$usedGB/$totalGB GB';
    }

    return 'Unknown';
  }

  Future<String> _getWindowsMemoryUsage() async {
    final result = await Process.run(
      'wmic',
      ['OS', 'get', 'FreePhysicalMemory,TotalVisibleMemorySize'],
    );

    final lines = (result.stdout as String).split('\n');
    for (final line in lines) {
      final parts = line.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        final free = int.tryParse(parts[0]);
        final total = int.tryParse(parts[1]);
        if (free != null && total != null && total > 0) {
          final used = total - free;
          final usedGB = (used / 1024 / 1024).toStringAsFixed(1);
          final totalGB = (total / 1024 / 1024).toStringAsFixed(1);
          return '$usedGB/$totalGB GB';
        }
      }
    }
    return 'Unknown';
  }

  // BATTERY

  Future<String> getBatteryStatus() async {
    try {
      if (Platform.isLinux || Platform.isAndroid) {
        // Android can also read /sys/class/power_supply
        return _getLinuxBatteryStatus();
      }
      if (Platform.isMacOS) {
        return _getMacOsBatteryStatus();
      }
      if (Platform.isWindows) {
        return _getWindowsBatteryStatus();
      }
      return 'N/A';
    } catch (e) {
      return 'N/A';
    }
  }

  String getBatteryStatusSync() {
    try {
      if (Platform.isLinux || Platform.isAndroid) {
        return _getLinuxBatteryStatusSync();
      }
      return 'N/A';
    } catch (e) {
      return 'N/A';
    }
  }

  Future<String> _getLinuxBatteryStatus() async {
    // Find battery path dynamically (works on Linux and Android)
    final batteryPath = await _findBatteryPath();
    if (batteryPath == null) return 'N/A';
    return _readLinuxBattery(batteryPath);
  }

  /// Finds the battery path in /sys/class/power_supply/
  /// Returns the first directory that has a 'capacity' file
  Future<String?> _findBatteryPath() async {
    const basePath = '/sys/class/power_supply';
    try {
      final dir = Directory(basePath);
      if (!await dir.exists()) return null;

      await for (final entity in dir.list()) {
        if (entity is Directory) {
          final capacityFile = File('${entity.path}/capacity');
          if (await capacityFile.exists()) {
            return entity.path;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  String _getLinuxBatteryStatusSync() {
    final batteryPath = _findBatteryPathSync();
    if (batteryPath == null) return 'N/A';
    return _readLinuxBatterySync(batteryPath);
  }

  /// Finds the battery path synchronously in /sys/class/power_supply/
  /// Returns the first directory that has a 'capacity' file
  String? _findBatteryPathSync() {
    const basePath = '/sys/class/power_supply';
    try {
      final dir = Directory(basePath);
      if (!dir.existsSync()) return null;

      for (final entity in dir.listSync()) {
        if (entity is Directory) {
          final capacityFile = File('${entity.path}/capacity');
          if (capacityFile.existsSync()) {
            return entity.path;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<String> _readLinuxBattery(String batteryPath) async {
    final capacityFile = File('$batteryPath/capacity');
    final statusFile = File('$batteryPath/status');

    if (!await capacityFile.exists()) return 'N/A';

    final capacity = (await capacityFile.readAsString()).trim();
    var status = '';

    if (await statusFile.exists()) {
      final statusValue = (await statusFile.readAsString()).trim().toLowerCase();
      if (statusValue == 'charging') {
        status = ' ⚡';
      } else if (statusValue == 'full') {
        status = ' ✓';
      }
    }

    return '$capacity%$status';
  }

  String _readLinuxBatterySync(String batteryPath) {
    final capacityFile = File('$batteryPath/capacity');
    final statusFile = File('$batteryPath/status');

    if (!capacityFile.existsSync()) return 'N/A';

    final capacity = capacityFile.readAsStringSync().trim();
    var status = '';

    if (statusFile.existsSync()) {
      final statusValue = statusFile.readAsStringSync().trim().toLowerCase();
      if (statusValue == 'charging') {
        status = ' ⚡';
      } else if (statusValue == 'full') {
        status = ' ✓';
      }
    }

    return '$capacity%$status';
  }

  Future<String> _getMacOsBatteryStatus() async {
    final result = await Process.run(
      'pmset',
      ['-g', 'batt'],
    );

    final output = result.stdout as String;
    final match = RegExp(r'(\d+)%').firstMatch(output);
    if (match != null) {
      final percent = match.group(1);
      final isCharging = output.contains('charging') || output.contains('AC Power');
      return '$percent%${isCharging ? " ⚡" : ""}';
    }
    return 'N/A';
  }

  Future<String> _getWindowsBatteryStatus() async {
    final result = await Process.run(
      'wmic',
      ['path', 'Win32_Battery', 'get', 'EstimatedChargeRemaining,BatteryStatus'],
    );

    final lines = (result.stdout as String).split('\n');
    for (final line in lines) {
      final parts = line.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        final status = int.tryParse(parts[0]);
        final charge = int.tryParse(parts[1]);
        if (charge != null) {
          final isCharging = status == 2 || status == 6;
          return '$charge%${isCharging ? " ⚡" : ""}';
        }
      }
    }
    return 'N/A';
  }

  Future<String> getUptime() async {
    try {
      if (Platform.isLinux) {
        return _getLinuxUptime();
      }
      if (Platform.isMacOS) {
        return _getMacOsUptime();
      }
      if (Platform.isWindows) {
        return _getWindowsUptime();
      }
      return 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Synchronous uptime getter (Linux/Android only)
  String getUptimeSync() {
    try {
      if (Platform.isLinux || Platform.isAndroid) {
        return _getLinuxUptimeSync();
      }
      return 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<String> _getLinuxUptime() async {
    final uptimeFile = File('/proc/uptime');
    if (!await uptimeFile.exists()) return 'Unknown';

    final content = await uptimeFile.readAsString();
    final seconds = double.parse(content.split(' ')[0]);
    return _formatUptime(Duration(seconds: seconds.round()));
  }

  String _getLinuxUptimeSync() {
    final uptimeFile = File('/proc/uptime');
    if (!uptimeFile.existsSync()) return 'Unknown';

    final content = uptimeFile.readAsStringSync();
    final seconds = double.parse(content.split(' ')[0]);
    return _formatUptime(Duration(seconds: seconds.round()));
  }

  Future<String> _getMacOsUptime() async {
    final result = await Process.run('uptime', []);
    final output = result.stdout as String;

    final match = RegExp(r'up\s+(\d+)\s+days?,?\s+(\d+):(\d+)').firstMatch(output);
    if (match != null) {
      final days = int.parse(match.group(1)!);
      final hours = int.parse(match.group(2)!);
      final minutes = int.parse(match.group(3)!);
      return _formatUptime(Duration(days: days, hours: hours, minutes: minutes));
    }

    final shortMatch = RegExp(r'up\s+(\d+):(\d+)').firstMatch(output);
    if (shortMatch != null) {
      final hours = int.parse(shortMatch.group(1)!);
      final minutes = int.parse(shortMatch.group(2)!);
      return _formatUptime(Duration(hours: hours, minutes: minutes));
    }

    return 'Unknown';
  }

  Future<String> _getWindowsUptime() async {
    final result = await Process.run(
      'wmic',
      ['os', 'get', 'lastbootuptime'],
    );

    final output = result.stdout as String;
    final match = RegExp(r'(\d{14})').firstMatch(output);
    if (match != null) {
      final dateStr = match.group(1)!;
      final year = int.parse(dateStr.substring(0, 4));
      final month = int.parse(dateStr.substring(4, 6));
      final day = int.parse(dateStr.substring(6, 8));
      final hour = int.parse(dateStr.substring(8, 10));
      final minute = int.parse(dateStr.substring(10, 12));
      final second = int.parse(dateStr.substring(12, 14));

      final bootTime = DateTime(year, month, day, hour, minute, second);
      final uptime = DateTime.now().difference(bootTime);
      return _formatUptime(uptime);
    }

    return 'Unknown';
  }

  String _formatUptime(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;

    final parts = <String>[];
    if (days > 0) parts.add('${days}d');
    if (hours > 0) parts.add('${hours}h');
    if (minutes > 0 || parts.isEmpty) parts.add('${minutes}m');

    return parts.join(' ');
  }

  Future<String> getDiskUsage([String? path]) async {
    try {
      final targetPath = path ?? '/';

      if (Platform.isLinux || Platform.isMacOS) {
        final result = await Process.run('df', ['-h', targetPath]);
        final lines = (result.stdout as String).split('\n');
        if (lines.length > 1) {
          final parts = lines[1].split(RegExp(r'\s+'));
          if (parts.length >= 4) {
            return '${parts[2]}/${parts[1]}';
          }
        }
      }

      if (Platform.isWindows) {
        final result = await Process.run(
          'wmic',
          ['logicaldisk', 'get', 'size,freespace,caption'],
        );
        return result.stdout.toString().trim();
      }

      return 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  String getOs() {
    return Platform.operatingSystem;
  }

  Map<String, String> getOsDetails() {
    return {
      'short': Platform.operatingSystem,
      'version': Platform.operatingSystemVersion,
    };
  }
}
