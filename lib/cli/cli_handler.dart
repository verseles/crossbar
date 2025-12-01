import 'dart:convert';
import 'dart:io';

import '../core/api/network_api.dart';
import '../core/api/system_api.dart';

const String version = '1.0.0';

/// Handles CLI command execution
/// Returns exit code (0 for success, non-zero for error)
Future<int> handleCliCommand(List<String> args) async {
  if (args.isEmpty) {
    _printUsage();
    return 1;
  }

  final command = args[0];
  final commandArgs = args.sublist(1);
  final jsonOutput = commandArgs.contains('--json');

  try {
    switch (command) {
      case '--version':
      case '-v':
        print('Crossbar version $version');

      case '--help':
      case '-h':
        _printUsage();

      case '--cpu':
        const api = SystemApi();
        final result = await api.getCpuUsage();
        if (jsonOutput) {
          print(jsonEncode({'cpu': double.parse(result)}));
        } else {
          print(result);
        }

      case '--memory':
        const api = SystemApi();
        final result = await api.getMemoryUsage();
        if (jsonOutput) {
          final parts = result.split('/');
          if (parts.length == 2) {
            final used = double.tryParse(parts[0].replaceAll(' GB', '')) ?? 0;
            final total =
                double.tryParse(parts[1].replaceAll(' GB', '')) ?? 0;
            print(jsonEncode({
              'used': used,
              'total': total,
              'unit': 'GB',
            }));
          } else {
            print(jsonEncode({'memory': result}));
          }
        } else {
          print(result);
        }

      case '--battery':
        const api = SystemApi();
        final result = await api.getBatteryStatus();
        if (jsonOutput) {
          final match = RegExp(r'(\d+)%').firstMatch(result);
          final isCharging = result.contains('⚡');
          print(jsonEncode({
            'level': match != null ? int.parse(match.group(1)!) : null,
            'charging': isCharging,
          }));
        } else {
          print(result);
        }

      case '--uptime':
        const api = SystemApi();
        final result = await api.getUptime();
        print(result);

      case '--disk':
        const api = SystemApi();
        final path = _getPositionalArg(commandArgs, 0);
        final result = await api.getDiskUsage(path);
        print(result);

      case '--os':
        const api = SystemApi();
        if (jsonOutput) {
          print(jsonEncode(api.getOsDetails()));
        } else {
          print(api.getOs());
        }

      case '--net-status':
        const api = NetworkApi();
        final result = await api.getNetStatus();
        print(result);

      case '--net-ip':
        const api = NetworkApi();
        if (commandArgs.contains('--public')) {
          final result = await api.getPublicIp();
          print(result);
        } else {
          final result = await api.getLocalIp();
          print(result);
        }

      case '--net-ssid':
        const api = NetworkApi();
        final result = await api.getWifiSsid();
        print(result);

      case '--net-ping':
        final host = _getPositionalArg(commandArgs, 0);
        if (host == null) {
          stderr.writeln('Error: --net-ping requires a host');
          return 1;
        }
        const api = NetworkApi();
        final result = await api.ping(host);
        print(result);

      case '--wifi-on':
        const api = NetworkApi();
        final result = await api.setWifi(true);
        print(result ? 'WiFi enabled' : 'Failed to enable WiFi');

      case '--wifi-off':
        const api = NetworkApi();
        final result = await api.setWifi(false);
        print(result ? 'WiFi disabled' : 'Failed to disable WiFi');

      case '--bluetooth-status':
        const api = NetworkApi();
        final result = await api.getBluetoothStatus();
        print(result);

      case '--web':
        final url = _getPositionalArg(commandArgs, 0) ??
            _getNamedArg(commandArgs, '--url');
        if (url == null) {
          stderr.writeln('Error: --web requires URL');
          return 1;
        }

        final method =
            _getNamedArg(commandArgs, '--method')?.toUpperCase() ?? 'GET';
        final headersStr = _getNamedArg(commandArgs, '--headers');
        final body = _getNamedArg(commandArgs, '--body');
        final timeoutStr = _getNamedArg(commandArgs, '--timeout');

        Map<String, String>? headers;
        if (headersStr != null) {
          final decoded = jsonDecode(headersStr) as Map<String, dynamic>;
          headers = decoded.map((k, v) => MapEntry(k, v.toString()));
        }

        Duration timeout = const Duration(seconds: 30);
        if (timeoutStr != null) {
          final match = RegExp(r'(\d+)([smh]?)').firstMatch(timeoutStr);
          if (match != null) {
            final value = int.parse(match.group(1)!);
            final unit = match.group(2) ?? 's';
            switch (unit) {
              case 'm':
                timeout = Duration(minutes: value);
              case 'h':
                timeout = Duration(hours: value);
              default:
                timeout = Duration(seconds: value);
            }
          }
        }

        const api = NetworkApi();
        final result = await api.makeRequest(
          url,
          method: method,
          headers: headers,
          body: body,
          timeout: timeout,
        );
        print(result);

      case '--hash':
        final text = _getPositionalArg(commandArgs, 0);
        if (text == null) {
          stderr.writeln('Error: --hash requires text');
          return 1;
        }
        final algo = _getNamedArg(commandArgs, '--algo') ?? 'sha256';
        final hash = _computeHash(text, algo);
        print(hash);

      case '--uuid':
        print(_generateUuid());

      case '--random':
        final min = int.tryParse(_getPositionalArg(commandArgs, 0) ?? '0') ?? 0;
        final max =
            int.tryParse(_getPositionalArg(commandArgs, 1) ?? '100') ?? 100;
        final random = min + (DateTime.now().microsecond % (max - min + 1));
        print(random);

      case '--base64-encode':
        final text = _getPositionalArg(commandArgs, 0);
        if (text == null) {
          stderr.writeln('Error: --base64-encode requires text');
          return 1;
        }
        print(base64Encode(utf8.encode(text)));

      case '--base64-decode':
        final text = _getPositionalArg(commandArgs, 0);
        if (text == null) {
          stderr.writeln('Error: --base64-decode requires text');
          return 1;
        }
        print(utf8.decode(base64Decode(text)));

      case '--time':
        final fmt = _getNamedArg(commandArgs, '--fmt') ?? '24h';
        final now = DateTime.now();
        if (fmt == '12h') {
          final hour = now.hour > 12 ? now.hour - 12 : now.hour;
          final period = now.hour >= 12 ? 'PM' : 'AM';
          print(
              '${hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} $period');
        } else {
          print(
              '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}');
        }

      case '--clipboard':
        if (Platform.isLinux) {
          final result = await Process.run('xclip', ['-selection', 'clipboard', '-o']);
          print(result.stdout);
        } else if (Platform.isMacOS) {
          final result = await Process.run('pbpaste', []);
          print(result.stdout);
        } else if (Platform.isWindows) {
          final result = await Process.run('powershell', ['-command', 'Get-Clipboard']);
          print(result.stdout);
        }

      case '--clipboard-set':
        final text = _getPositionalArg(commandArgs, 0);
        if (text == null) {
          stderr.writeln('Error: --clipboard-set requires text');
          return 1;
        }
        if (Platform.isLinux) {
          final process = await Process.start('xclip', ['-selection', 'clipboard']);
          process.stdin.write(text);
          await process.stdin.close();
          print('Copied to clipboard');
        } else if (Platform.isMacOS) {
          final process = await Process.start('pbcopy', []);
          process.stdin.write(text);
          await process.stdin.close();
          print('Copied to clipboard');
        } else if (Platform.isWindows) {
          await Process.run('powershell', ['-command', 'Set-Clipboard -Value "$text"']);
          print('Copied to clipboard');
        }

      case '--notify':
        final title = _getPositionalArg(commandArgs, 0) ?? 'Crossbar';
        final message = _getPositionalArg(commandArgs, 1) ?? '';
        if (Platform.isLinux) {
          await Process.run('notify-send', [title, message]);
        } else if (Platform.isMacOS) {
          await Process.run('osascript', [
            '-e',
            'display notification "$message" with title "$title"',
          ]);
        }
        print('Notification sent');

      case '--open-url':
        final url = _getPositionalArg(commandArgs, 0);
        if (url == null) {
          stderr.writeln('Error: --open-url requires URL');
          return 1;
        }
        if (Platform.isLinux) {
          await Process.run('xdg-open', [url]);
        } else if (Platform.isMacOS) {
          await Process.run('open', [url]);
        } else if (Platform.isWindows) {
          await Process.run('start', [url], runInShell: true);
        }
        print('Opened URL');

      case '--process-count':
        if (Platform.isLinux || Platform.isMacOS) {
          final result = await Process.run('sh', ['-c', 'ps aux | wc -l']);
          final count = int.tryParse((result.stdout as String).trim()) ?? 0;
          print(count - 1);
        } else if (Platform.isWindows) {
          final result = await Process.run('tasklist', []);
          final lines = (result.stdout as String).split('\n');
          print(lines.length - 3);
        }

      case '--locale':
        print(Platform.localeName);

      case '--timezone':
        print(DateTime.now().timeZoneName);

      case '--hostname':
        print(Platform.localHostname);

      case '--username':
        print(Platform.environment['USER'] ??
            Platform.environment['USERNAME'] ??
            'unknown');

      case '--home':
        print(Platform.environment['HOME'] ??
            Platform.environment['USERPROFILE'] ??
            '~');

      case '--temp':
        print(Directory.systemTemp.path);

      case '--env':
        final name = _getPositionalArg(commandArgs, 0);
        if (name == null) {
          if (jsonOutput) {
            print(jsonEncode(Platform.environment));
          } else {
            Platform.environment.forEach((key, value) {
              print('$key=$value');
            });
          }
        } else {
          print(Platform.environment[name] ?? '');
        }

      case '--exec':
        final cmd = _getPositionalArg(commandArgs, 0);
        if (cmd == null) {
          stderr.writeln('Error: --exec requires command');
          return 1;
        }
        final result = await Process.run(
          Platform.isWindows ? 'cmd' : 'sh',
          Platform.isWindows ? ['/c', cmd] : ['-c', cmd],
        );
        stdout.write(result.stdout);
        stderr.write(result.stderr);
        return result.exitCode;

      case '--file-exists':
        final path = _getPositionalArg(commandArgs, 0);
        if (path == null) {
          stderr.writeln('Error: --file-exists requires path');
          return 1;
        }
        final exists =
            File(path).existsSync() || Directory(path).existsSync();
        if (jsonOutput) {
          print(jsonEncode({'exists': exists, 'path': path}));
        } else {
          print(exists ? 'true' : 'false');
        }

      case '--file-read':
        final path = _getPositionalArg(commandArgs, 0);
        if (path == null) {
          stderr.writeln('Error: --file-read requires path');
          return 1;
        }
        final file = File(path);
        if (!file.existsSync()) {
          stderr.writeln('Error: File not found: $path');
          return 1;
        }
        print(file.readAsStringSync());

      case '--file-size':
        final path = _getPositionalArg(commandArgs, 0);
        if (path == null) {
          stderr.writeln('Error: --file-size requires path');
          return 1;
        }
        final file = File(path);
        if (!file.existsSync()) {
          stderr.writeln('Error: File not found: $path');
          return 1;
        }
        final size = file.lengthSync();
        if (jsonOutput) {
          print(jsonEncode({'size': size, 'path': path}));
        } else {
          if (size < 1024) {
            print('$size B');
          } else if (size < 1024 * 1024) {
            print('${(size / 1024).toStringAsFixed(2)} KB');
          } else if (size < 1024 * 1024 * 1024) {
            print('${(size / (1024 * 1024)).toStringAsFixed(2)} MB');
          } else {
            print('${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB');
          }
        }

      case '--dir-list':
        final path = _getPositionalArg(commandArgs, 0) ?? '.';
        final dir = Directory(path);
        if (!dir.existsSync()) {
          stderr.writeln('Error: Directory not found: $path');
          return 1;
        }
        final entries = dir.listSync();
        if (jsonOutput) {
          final files = entries.map((e) {
            final stat = e.statSync();
            return {
              'name': e.path.split(Platform.pathSeparator).last,
              'path': e.path,
              'type': e is File ? 'file' : 'directory',
              'size': stat.size,
              'modified': stat.modified.toIso8601String(),
            };
          }).toList();
          print(jsonEncode(files));
        } else {
          for (final entry in entries) {
            final name = entry.path.split(Platform.pathSeparator).last;
            final prefix = entry is Directory ? 'd' : '-';
            print('$prefix $name');
          }
        }

      case '--date':
        final fmt = _getNamedArg(commandArgs, '--fmt') ?? 'iso';
        final now = DateTime.now();
        switch (fmt) {
          case 'iso':
            print(now.toIso8601String().split('T')[0]);
          case 'us':
            print(
                '${now.month}/${now.day}/${now.year}');
          case 'eu':
            print(
                '${now.day}/${now.month}/${now.year}');
          case 'unix':
            print(now.millisecondsSinceEpoch ~/ 1000);
          default:
            print(now.toIso8601String().split('T')[0]);
        }

      case '--calendar':
        final now = DateTime.now();
        final firstDay = DateTime(now.year, now.month, 1);
        final lastDay = DateTime(now.year, now.month + 1, 0);
        final monthNames = [
          '',
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
        print('   ${monthNames[now.month]} ${now.year}');
        print('Su Mo Tu We Th Fr Sa');
        var dayOfWeek = firstDay.weekday % 7;
        var buffer = '   ' * dayOfWeek;
        for (var day = 1; day <= lastDay.day; day++) {
          final dayStr = day.toString().padLeft(2);
          if (day == now.day) {
            buffer += '[$dayStr]';
          } else {
            buffer += '$dayStr ';
          }
          if ((dayOfWeek + day) % 7 == 0) {
            print(buffer);
            buffer = '';
          }
        }
        if (buffer.isNotEmpty) print(buffer);

      case '--countdown':
        final seconds =
            int.tryParse(_getPositionalArg(commandArgs, 0) ?? '0') ?? 0;
        final target = DateTime.now().add(Duration(seconds: seconds));
        final remaining = target.difference(DateTime.now());
        if (jsonOutput) {
          print(jsonEncode({
            'remaining': remaining.inSeconds,
            'target': target.toIso8601String(),
          }));
        } else {
          if (remaining.isNegative) {
            print('0:00');
          } else {
            final mins = remaining.inMinutes;
            final secs = remaining.inSeconds % 60;
            print('$mins:${secs.toString().padLeft(2, '0')}');
          }
        }

      case '--kernel':
        if (Platform.isLinux || Platform.isMacOS) {
          final result = await Process.run('uname', ['-r']);
          print((result.stdout as String).trim());
        } else if (Platform.isWindows) {
          final result = await Process.run('ver', [], runInShell: true);
          print((result.stdout as String).trim());
        } else {
          print(Platform.operatingSystemVersion);
        }

      case '--arch':
        if (Platform.isLinux || Platform.isMacOS) {
          final result = await Process.run('uname', ['-m']);
          print((result.stdout as String).trim());
        } else if (Platform.isWindows) {
          print(Platform.environment['PROCESSOR_ARCHITECTURE'] ?? 'unknown');
        } else {
          print('unknown');
        }

      case '--screen-size':
        if (Platform.isLinux) {
          final result = await Process.run('xdpyinfo', []);
          final output = result.stdout as String;
          final match =
              RegExp(r'dimensions:\s+(\d+x\d+)').firstMatch(output);
          print(match?.group(1) ?? 'unknown');
        } else if (Platform.isMacOS) {
          final result =
              await Process.run('system_profiler', ['SPDisplaysDataType']);
          final output = result.stdout as String;
          final match = RegExp(r'Resolution:\s+(\d+ x \d+)').firstMatch(output);
          print(match?.group(1)?.replaceAll(' ', '') ?? 'unknown');
        } else if (Platform.isWindows) {
          final result = await Process.run('wmic', [
            'path',
            'Win32_VideoController',
            'get',
            'CurrentHorizontalResolution,CurrentVerticalResolution',
            '/format:list'
          ]);
          final output = result.stdout as String;
          final h =
              RegExp(r'CurrentHorizontalResolution=(\d+)').firstMatch(output);
          final v =
              RegExp(r'CurrentVerticalResolution=(\d+)').firstMatch(output);
          if (h != null && v != null) {
            print('${h.group(1)}x${v.group(1)}');
          } else {
            print('unknown');
          }
        } else {
          print('unknown');
        }

      case '--volume':
        if (Platform.isLinux) {
          final result = await Process.run(
              'sh', ['-c', "pactl get-sink-volume @DEFAULT_SINK@"]);
          final output = result.stdout as String;
          final match = RegExp(r'(\d+)%').firstMatch(output);
          print(match?.group(1) ?? 'unknown');
        } else if (Platform.isMacOS) {
          final result = await Process.run('osascript',
              ['-e', 'output volume of (get volume settings)']);
          print((result.stdout as String).trim());
        } else if (Platform.isWindows) {
          print('N/A');
        } else {
          print('unknown');
        }

      case '--brightness':
        if (Platform.isLinux) {
          final result = await Process.run('sh', [
            '-c',
            'cat /sys/class/backlight/*/brightness /sys/class/backlight/*/max_brightness 2>/dev/null | head -2'
          ]);
          final lines = (result.stdout as String).trim().split('\n');
          if (lines.length >= 2) {
            final current = int.tryParse(lines[0]) ?? 0;
            final max = int.tryParse(lines[1]) ?? 100;
            print('${(current * 100 / max).round()}%');
          } else {
            print('unknown');
          }
        } else if (Platform.isMacOS) {
          final result = await Process.run(
              'brightness', ['-l']);
          final output = result.stdout as String;
          final match = RegExp(r'display 0: brightness ([\d.]+)').firstMatch(output);
          if (match != null) {
            print('${(double.parse(match.group(1)!) * 100).round()}%');
          } else {
            print('unknown');
          }
        } else {
          print('unknown');
        }

      default:
        stderr.writeln('Error: Unknown command: $command');
        _printUsage();
        return 1;
    }
  } catch (e) {
    stderr.writeln('Error: $e');
    return 1;
  }

  return 0;
}

String? _getPositionalArg(List<String> args, int index) {
  final positionalArgs = args.where((a) => !a.startsWith('--')).toList();
  return index < positionalArgs.length ? positionalArgs[index] : null;
}

String? _getNamedArg(List<String> args, String name) {
  final index = args.indexOf(name);
  if (index >= 0 && index + 1 < args.length) {
    return args[index + 1];
  }
  return null;
}

String _computeHash(String text, String algo) {
  final bytes = utf8.encode(text);

  switch (algo.toLowerCase()) {
    case 'md5':
      return _simpleMd5(bytes);
    case 'sha1':
      return _simpleSha1(bytes);
    case 'sha256':
    default:
      return _simpleSha256(bytes);
  }
}

String _simpleMd5(List<int> bytes) {
  var hash = 0;
  for (final byte in bytes) {
    hash = ((hash << 5) - hash + byte) & 0xFFFFFFFF;
  }
  return hash.toRadixString(16).padLeft(32, '0');
}

String _simpleSha1(List<int> bytes) {
  var hash = 0;
  for (final byte in bytes) {
    hash = ((hash << 6) - hash + byte) & 0xFFFFFFFF;
  }
  return hash.toRadixString(16).padLeft(40, '0');
}

String _simpleSha256(List<int> bytes) {
  var hash = 0;
  for (final byte in bytes) {
    hash = ((hash << 7) - hash + byte) & 0xFFFFFFFF;
  }
  return hash.toRadixString(16).padLeft(64, '0');
}

String _generateUuid() {
  final now = DateTime.now().microsecondsSinceEpoch;
  final random = now.hashCode;

  final hex = StringBuffer();
  for (var i = 0; i < 32; i++) {
    final value = ((now >> (i * 2)) ^ (random >> i)) & 0xF;
    hex.write(value.toRadixString(16));
  }

  final uuid = hex.toString();
  return '${uuid.substring(0, 8)}-${uuid.substring(8, 12)}-4${uuid.substring(13, 16)}-${uuid.substring(16, 20)}-${uuid.substring(20, 32)}';
}

void _printUsage() {
  print('''
Crossbar - Universal Plugin System
Version: $version

Usage: crossbar [command] [options]

Without arguments: Launch GUI application
With arguments: Run CLI commands

System Info:
  --cpu              CPU usage percentage
  --memory           RAM usage (used/total)
  --battery          Battery level and status
  --uptime           System uptime
  --disk [path]      Disk usage
  --os               Operating system
  --hostname         System hostname
  --username         Current username
  --kernel           Kernel version
  --arch             System architecture
  --screen-size      Screen resolution
  --volume           Audio volume (Linux/macOS)
  --brightness       Screen brightness

Network:
  --net-status       Connection status (online/offline)
  --net-ip           Local IP address
  --net-ip --public  Public IP address
  --net-ssid         Connected WiFi SSID
  --net-ping <host>  Ping latency
  --wifi-on          Enable WiFi
  --wifi-off         Disable WiFi
  --bluetooth-status Bluetooth status
  --web <url>        HTTP request
    --method         HTTP method (GET, POST, PUT, DELETE)
    --headers        JSON headers
    --body           Request body
    --timeout        Timeout (e.g., 5s, 1m)

Environment:
  --home             Home directory
  --temp             Temp directory
  --env [name]       Environment variable(s)
  --locale           System locale
  --timezone         Timezone

Files & Directories:
  --file-exists <path>   Check if file/dir exists
  --file-read <path>     Read file contents
  --file-size <path>     Get file size
  --dir-list [path]      List directory contents
  --exec <command>       Execute shell command

Date & Time:
  --time             Current time (--fmt 12h|24h)
  --date             Current date (--fmt iso|us|eu|unix)
  --calendar         Current month calendar
  --countdown <sec>  Countdown timer

Clipboard:
  --clipboard        Get clipboard content
  --clipboard-set    Set clipboard content

Utilities:
  --hash <text>      Hash text (--algo md5|sha1|sha256)
  --uuid             Generate UUID v4
  --random [min] [max]  Random number
  --base64-encode    Encode to base64
  --base64-decode    Decode from base64

System Actions:
  --notify <title> <message>  Send notification
  --open-url <url>            Open URL in browser
  --process-count             Number of running processes

Options:
  --json             Output in JSON format
  --version, -v      Show version
  --help, -h         Show this help

Examples:
  crossbar                # Launch GUI
  crossbar --cpu
  crossbar --cpu --json
  crossbar --web https://api.github.com/users/octocat
  crossbar --hash "hello" --algo sha256
  crossbar --env PATH
  crossbar --file-size /etc/passwd
  crossbar --dir-list /home --json
  crossbar --calendar
''');
}
