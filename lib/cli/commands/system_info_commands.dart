import 'dart:convert';
import 'dart:io';

import '../../core/api/system_api.dart';
import '../cli_utils.dart';
import 'base_command.dart';

class SystemInfoCommand extends CliCommand {
  final String _name;
  final String _desc;

  SystemInfoCommand(this._name, this._desc);

  @override
  String get name => _name;

  @override
  String get description => _desc;

  @override
  Future<int> execute(List<String> args) async {
    // This is a generic handler, but logic differs.
    // Better to have subclasses or a switch here if using one class.
    return 0;
  }
}

class CpuCommand extends CliCommand {
  @override
  String get name => 'cpu';
  @override
  String get description => 'CPU usage percentage';

  @override
  Future<int> execute(List<String> args) async {
    const api = SystemApi();
    final result = await api.getCpuUsage();
    final jsonOutput = args.contains('--json');
    final xmlOutput = args.contains('--xml');

    final cpuData = {'cpu': double.tryParse(result) ?? 0};
    if (jsonOutput) {
      print(jsonEncode(cpuData));
    } else if (xmlOutput) {
      print(mapToXml(cpuData));
    } else {
      print('$result%');
    }
    return 0;
  }
}

class MemoryCommand extends CliCommand {
  @override
  String get name => 'memory';
  @override
  String get description => 'RAM usage';

  @override
  Future<int> execute(List<String> args) async {
    const api = SystemApi();
    final result = await api.getMemoryUsage();
    final jsonOutput = args.contains('--json');

    if (jsonOutput) {
      final parts = result.split('/');
      if (parts.length == 2) {
        final used = double.tryParse(parts[0].replaceAll(' GB', '')) ?? 0;
        final total = double.tryParse(parts[1].replaceAll(' GB', '')) ?? 0;
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
    return 0;
  }
}

class BatteryCommand extends CliCommand {
  @override
  String get name => 'battery';
  @override
  String get description => 'Battery status';

  @override
  Future<int> execute(List<String> args) async {
    const api = SystemApi();
    final result = await api.getBatteryStatus();
    final jsonOutput = args.contains('--json');

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
    return 0;
  }
}

class UptimeCommand extends CliCommand {
  @override
  String get name => 'uptime';
  @override
  String get description => 'System uptime';

  @override
  Future<int> execute(List<String> args) async {
    const api = SystemApi();
    print(await api.getUptime());
    return 0;
  }
}

class DiskCommand extends CliCommand {
  @override
  String get name => 'disk';
  @override
  String get description => 'Disk usage';

  @override
  Future<int> execute(List<String> args) async {
    const api = SystemApi();
    final values = args.where((a) => !a.startsWith('--')).toList();
    final path = values.isNotEmpty ? values[0] : null; // null means root/default
    final result = await api.getDiskUsage(path);
    print(result);
    return 0;
  }
}

class OsCommand extends CliCommand {
  @override
  String get name => 'os';
  @override
  String get description => 'Operating system info';

  @override
  Future<int> execute(List<String> args) async {
    const api = SystemApi();
    final jsonOutput = args.contains('--json');
    if (jsonOutput) {
      print(jsonEncode(api.getOsDetails()));
    } else {
      print(api.getOs());
    }
    return 0;
  }
}

class KernelCommand extends CliCommand {
  @override
  String get name => 'kernel';
  @override
  String get description => 'Kernel version';

  @override
  Future<int> execute(List<String> args) async {
    if (Platform.isLinux || Platform.isMacOS) {
      final result = await Process.run('uname', ['-r']);
      print((result.stdout as String).trim());
    } else if (Platform.isWindows) {
      final result = await Process.run('ver', [], runInShell: true);
      print((result.stdout as String).trim());
    } else {
      print(Platform.operatingSystemVersion);
    }
    return 0;
  }
}

class ArchCommand extends CliCommand {
  @override
  String get name => 'arch';
  @override
  String get description => 'System architecture';

  @override
  Future<int> execute(List<String> args) async {
    if (Platform.isLinux || Platform.isMacOS) {
      final result = await Process.run('uname', ['-m']);
      print((result.stdout as String).trim());
    } else if (Platform.isWindows) {
      print(Platform.environment['PROCESSOR_ARCHITECTURE'] ?? 'unknown');
    } else {
      print('unknown');
    }
    return 0;
  }
}

class HostnameCommand extends CliCommand {
  @override
  String get name => 'hostname';
  @override
  String get description => 'System hostname';

  @override
  Future<int> execute(List<String> args) async {
    print(Platform.localHostname);
    return 0;
  }
}

class UsernameCommand extends CliCommand {
  @override
  String get name => 'username';
  @override
  String get description => 'Current username';

  @override
  Future<int> execute(List<String> args) async {
    print(Platform.environment['USER'] ?? Platform.environment['USERNAME'] ?? 'unknown');
    return 0;
  }
}

class HomeCommand extends CliCommand {
  @override
  String get name => 'home';
  @override
  String get description => 'Home directory';

  @override
  Future<int> execute(List<String> args) async {
    print(Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '~');
    return 0;
  }
}

class TempCommand extends CliCommand {
  @override
  String get name => 'temp';
  @override
  String get description => 'Temp directory';

  @override
  Future<int> execute(List<String> args) async {
    print(Directory.systemTemp.path);
    return 0;
  }
}

class EnvCommand extends CliCommand {
  @override
  String get name => 'env';
  @override
  String get description => 'Environment variables';

  @override
  Future<int> execute(List<String> args) async {
    final values = args.where((a) => !a.startsWith('--')).toList();
    final name = values.isNotEmpty ? values[0] : null;
    final jsonOutput = args.contains('--json');

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
    return 0;
  }
}

class LocaleCommand extends CliCommand {
  @override
  String get name => 'locale';
  @override
  String get description => 'System locale';

  @override
  Future<int> execute(List<String> args) async {
    print(Platform.localeName);
    return 0;
  }
}

class TimezoneCommand extends CliCommand {
  @override
  String get name => 'timezone';
  @override
  String get description => 'System timezone';

  @override
  Future<int> execute(List<String> args) async {
    print(DateTime.now().timeZoneName);
    return 0;
  }
}
