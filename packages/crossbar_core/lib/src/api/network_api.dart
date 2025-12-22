import 'dart:convert';
import 'dart:io';

class NetworkApi {
  const NetworkApi();

  Future<String> getNetStatus() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return 'online';
      }
      return 'offline';
    } catch (_) {
      return 'offline';
    }
  }

  Future<String> getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );

      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback) {
            return addr.address;
          }
        }
      }

      return '127.0.0.1';
    } catch (e) {
      return '127.0.0.1';
    }
  }

  Future<String> getPublicIp() async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(
        Uri.parse('https://api.ipify.org?format=text'),
      );
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        return body.trim();
      }

      return 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<String> getWifiSsid() async {
    try {
      if (Platform.isLinux) {
        final result = await Process.run('iwgetid', ['-r']);
        if (result.exitCode == 0) {
          return (result.stdout as String).trim();
        }

        final nmResult = await Process.run('nmcli', [
          '-t',
          '-f',
          'active,ssid',
          'dev',
          'wifi',
        ]);
        if (nmResult.exitCode == 0) {
          final lines = (nmResult.stdout as String).split('\n');
          for (final line in lines) {
            if (line.startsWith('yes:')) {
              return line.substring(4);
            }
          }
        }
      }

      if (Platform.isMacOS) {
        final result = await Process.run(
          '/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport',
          ['-I'],
        );
        if (result.exitCode == 0) {
          final match =
              RegExp(r'SSID:\s*(.+)').firstMatch(result.stdout as String);
          if (match != null) {
            return match.group(1)!.trim();
          }
        }
      }

      if (Platform.isWindows) {
        final result = await Process.run('netsh', [
          'wlan',
          'show',
          'interfaces',
        ]);
        if (result.exitCode == 0) {
          final match =
              RegExp(r'SSID\s*:\s*(.+)').firstMatch(result.stdout as String);
          if (match != null) {
            return match.group(1)!.trim();
          }
        }
      }

      return 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<String> ping(String host) async {
    try {
      final flag = Platform.isWindows ? '-n' : '-c';
      final result = await Process.run('ping', [flag, '1', host]);

      if (result.exitCode == 0) {
        final output = result.stdout as String;

        RegExp pattern;
        if (Platform.isWindows) {
          pattern = RegExp(r'Average = (\d+)ms');
        } else {
          pattern = RegExp(r'time[=<](\d+\.?\d*)\s*ms');
        }

        final match = pattern.firstMatch(output);
        if (match != null) {
          return '${match.group(1)}ms';
        }
      }

      return 'timeout';
    } catch (e) {
      return 'error';
    }
  }

  Future<String> makeRequest(
    String url, {
    String method = 'GET',
    Map<String, String>? headers,
    String? body,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = timeout;

      final uri = Uri.parse(url);
      HttpClientRequest request;

      switch (method.toUpperCase()) {
        case 'POST':
          request = await client.postUrl(uri);
        case 'PUT':
          request = await client.putUrl(uri);
        case 'DELETE':
          request = await client.deleteUrl(uri);
        case 'HEAD':
          request = await client.headUrl(uri);
        default:
          request = await client.getUrl(uri);
      }

      headers?.forEach((key, value) {
        request.headers.add(key, value);
      });

      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.write(body);
      }

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      return responseBody;
    } catch (e) {
      throw Exception('Request failed: $e');
    }
  }

  Future<Map<String, dynamic>> makeRequestJson(
    String url, {
    String method = 'GET',
    Map<String, String>? headers,
    String? body,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final response = await makeRequest(
      url,
      method: method,
      headers: headers,
      body: body,
      timeout: timeout,
    );

    return jsonDecode(response) as Map<String, dynamic>;
  }

  Future<bool> setWifi(bool enabled) async {
    try {
      if (Platform.isLinux) {
        final action = enabled ? 'on' : 'off';
        final result = await Process.run('nmcli', ['radio', 'wifi', action]);
        return result.exitCode == 0;
      }

      if (Platform.isMacOS) {
        final action = enabled ? 'on' : 'off';
        final result = await Process.run('networksetup', [
          '-setairportpower',
          'en0',
          action,
        ]);
        return result.exitCode == 0;
      }

      if (Platform.isWindows) {
        final action = enabled ? 'enable' : 'disable';
        final result = await Process.run('netsh', [
          'interface',
          'set',
          'interface',
          'Wi-Fi',
          action,
        ]);
        return result.exitCode == 0;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  Future<String> getBluetoothStatus() async {
    try {
      if (Platform.isLinux) {
        final result = await Process.run('bluetoothctl', ['show']);
        if (result.exitCode == 0) {
          final output = result.stdout as String;
          if (output.contains('Powered: yes')) {
            final devicesResult = await Process.run('bluetoothctl', ['devices']);
            final devices = (devicesResult.stdout as String)
                .split('\n')
                .where((l) => l.trim().isNotEmpty)
                .length;
            return devices > 0 ? 'on:$devices' : 'on';
          }
          return 'off';
        }
      }

      if (Platform.isMacOS) {
        final result = await Process.run('system_profiler', [
          'SPBluetoothDataType',
        ]);
        if (result.exitCode == 0) {
          final output = result.stdout as String;
          if (output.contains('State: On')) {
            return 'on';
          }
          return 'off';
        }
      }

      return 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }
}
