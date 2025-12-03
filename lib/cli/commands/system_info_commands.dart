import 'dart:io';

import '../../core/api/system_api.dart';
import 'base_command.dart';

class SystemInfoCommand extends CliCommand {
  SystemInfoCommand(this._name, this._desc);

  final String _name;
  final String _desc;

  @override
  String get name => _name;

  @override
  String get description => _desc;

  @override
  Future<int> execute(List<String> args) async {
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
    final val = double.tryParse(result) ?? 0;

    printFormatted(
      {'cpu': val},
      json: args.contains('--json'),
      xml: args.contains('--xml'),
      plain: (_) => '$result%',
    );
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

    var data = <String, dynamic>{'memory': result};
    final parts = result.split('/');
    if (parts.length == 2) {
      final used = double.tryParse(parts[0].replaceAll(' GB', '')) ?? 0;
      final total = double.tryParse(parts[1].replaceAll(' GB', '')) ?? 0;
      data = {
        'used': used,
        'total': total,
        'unit': 'GB',
      };
    }

    printFormatted(
      data,
      json: args.contains('--json'),
      xml: args.contains('--xml'),
      plain: (_) => result,
    );
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

    final match = RegExp(r'(\d+)%').firstMatch(result);
    final isCharging = result.contains('⚡');
    final data = {
        'level': match != null ? int.parse(match.group(1)!) : null,
        'charging': isCharging,
        'status': result
    };

    printFormatted(
      data,
      json: args.contains('--json'),
      xml: args.contains('--xml'),
      plain: (_) => result,
    );
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
    final result = await api.getUptime();
    printFormatted(
        {'uptime': result},
        json: args.contains('--json'),
        xml: args.contains('--xml'),
        plain: (_) => result
    );
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
    final path = values.isNotEmpty ? values[0] : null;
    final result = await api.getDiskUsage(path);

    // Attempt to parse result to structured data if possible, currently just string
    // "Used: 50GB, Free: 100GB" typically
    printFormatted(
        {'disk': result}, // Ideally parse this better but sticking to string for now if format is complex
        json: args.contains('--json'),
        xml: args.contains('--xml'),
        plain: (_) => result
    );
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
    printFormatted(
        api.getOsDetails(),
        json: args.contains('--json'),
        xml: args.contains('--xml'),
        plain: (_) => api.getOs()
    );
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
    String resultStr;
    if (Platform.isLinux || Platform.isMacOS) {
      final res = await Process.run('uname', ['-r']);
      resultStr = (res.stdout as String).trim();
    } else if (Platform.isWindows) {
      final res = await Process.run('ver', [], runInShell: true);
      resultStr = (res.stdout as String).trim();
    } else {
      resultStr = Platform.operatingSystemVersion;
    }

    printFormatted(
        {'kernel': resultStr},
        json: args.contains('--json'),
        xml: args.contains('--xml'),
        plain: (_) => resultStr
    );
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
    String resultStr;
    if (Platform.isLinux || Platform.isMacOS) {
      final res = await Process.run('uname', ['-m']);
      resultStr = (res.stdout as String).trim();
    } else if (Platform.isWindows) {
      resultStr = Platform.environment['PROCESSOR_ARCHITECTURE'] ?? 'unknown';
    } else {
      resultStr = 'unknown';
    }

    printFormatted(
        {'arch': resultStr},
        json: args.contains('--json'),
        xml: args.contains('--xml'),
        plain: (_) => resultStr
    );
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
    final result = Platform.localHostname;
    printFormatted(
        {'hostname': result},
        json: args.contains('--json'),
        xml: args.contains('--xml'),
        plain: (_) => result
    );
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
    final result = Platform.environment['USER'] ?? Platform.environment['USERNAME'] ?? 'unknown';
    printFormatted(
        {'username': result},
        json: args.contains('--json'),
        xml: args.contains('--xml'),
        plain: (_) => result
    );
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
    final result = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '~';
    printFormatted(
        {'home': result},
        json: args.contains('--json'),
        xml: args.contains('--xml'),
        plain: (_) => result
    );
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
    final result = Directory.systemTemp.path;
    printFormatted(
        {'temp': result},
        json: args.contains('--json'),
        xml: args.contains('--xml'),
        plain: (_) => result
    );
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
    final json = args.contains('--json');
    final xml = args.contains('--xml');

    if (name == null) {
        printFormatted(
            Platform.environment,
            json: json,
            xml: xml,
            plain: (data) {
                final map = data as Map<String, String>;
                return map.entries.map((e) => '${e.key}=${e.value}').join('\n');
            }
        );
    } else {
        final value = Platform.environment[name] ?? '';
        printFormatted(
            {name: value},
            json: json,
            xml: xml,
            plain: (_) => value,
        );
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
    final result = Platform.localeName;
    printFormatted(
        {'locale': result},
        json: args.contains('--json'),
        xml: args.contains('--xml'),
        plain: (_) => result
    );
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
    final result = DateTime.now().timeZoneName;
    printFormatted(
        {'timezone': result},
        json: args.contains('--json'),
        xml: args.contains('--xml'),
        plain: (_) => result
    );
    return 0;
  }
}
