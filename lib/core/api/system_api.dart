import 'dart:io';

class SystemApi {
  const SystemApi();

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

      return '0.0';
    } catch (e) {
      return '0.0';
    }
  }

  Future<String> _getLinuxCpuUsage() async {
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

  Future<String> getMemoryUsage() async {
    try {
      if (Platform.isLinux) {
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

  Future<String> _getLinuxMemoryUsage() async {
    final memInfo = await File('/proc/meminfo').readAsString();
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

    final pageSize = 4096;
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

  Future<String> getBatteryStatus() async {
    try {
      if (Platform.isLinux) {
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

  Future<String> _getLinuxBatteryStatus() async {
    final batteryPath = '/sys/class/power_supply/BAT0';
    final batteryDir = Directory(batteryPath);

    if (!await batteryDir.exists()) {
      final bat1Path = '/sys/class/power_supply/BAT1';
      final bat1Dir = Directory(bat1Path);
      if (!await bat1Dir.exists()) {
        return 'N/A';
      }
      return _readLinuxBattery(bat1Path);
    }

    return _readLinuxBattery(batteryPath);
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

  Future<String> _getLinuxUptime() async {
    final uptimeFile = File('/proc/uptime');
    if (!await uptimeFile.exists()) return 'Unknown';

    final content = await uptimeFile.readAsString();
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
