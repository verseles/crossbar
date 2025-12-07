# crossbar_api

Official Dart API for creating compiled Crossbar plugins with full IntelliSense support.

## Features

- **Full IntelliSense**: Complete IDE support with autocompletion
- **Type Safety**: All methods are strongly typed
- **Any Package**: Use any pub.dev package in your plugins
- **Native Performance**: Compile to fast native binaries

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  crossbar_api:
    git:
      url: https://github.com/verseles/crossbar.git
      path: packages/crossbar_api
```

## Quick Start

```dart
import 'package:crossbar_api/crossbar_api.dart';

void main() async {
  // System info
  final cpu = await Crossbar.cpu();
  final mem = await Crossbar.memory();

  // Time
  final time = Crossbar.time('HH:mm');

  // Network
  final btc = await Crossbar.web('https://api.coinbase.com/v2/prices/BTC-USD/spot');

  print('💻 CPU: $cpu% | 🧠 RAM: ${mem.percent.toStringAsFixed(0)}%');
  print('⏰ $time');
  print('₿ \$${btc.json?['data']['amount']}');
}
```

## Available APIs

### System

| Method        | Returns               | Description                         |
| ------------- | --------------------- | ----------------------------------- |
| `cpu()`       | `Future<double>`      | CPU usage percentage (0-100)        |
| `memory()`    | `Future<MemoryInfo>`  | Memory usage with total, used, free |
| `battery()`   | `Future<BatteryInfo>` | Battery level and charging status   |
| `uptime()`    | `Future<String>`      | System uptime                       |
| `disk()`      | `Future<Map>`         | Disk usage                          |
| `os()`        | `String`              | Operating system name               |
| `osDetails()` | `Future<Map>`         | Detailed OS info                    |

### Time

| Method           | Returns  | Description                        |
| ---------------- | -------- | ---------------------------------- |
| `time([format])` | `String` | Current time (default: HH:mm:ss)   |
| `date([format])` | `String` | Current date (default: yyyy-MM-dd) |

### Network

| Method                              | Returns               | Description       |
| ----------------------------------- | --------------------- | ----------------- |
| `web(url, {method, headers, body})` | `Future<WebResponse>` | HTTP request      |
| `netStatus()`                       | `Future<bool>`        | Online status     |
| `localIp()`                         | `Future<String>`      | Local IP address  |
| `publicIp()`                        | `Future<String>`      | Public IP address |
| `ping(host)`                        | `Future<int>`         | Latency in ms     |

### Utilities

| Method                   | Returns          | Description       |
| ------------------------ | ---------------- | ----------------- |
| `exec(command)`          | `Future<String>` | Run shell command |
| `notify(title, message)` | `Future<bool>`   | Send notification |
| `clipboard()`            | `Future<String>` | Get clipboard     |
| `setClipboard(content)`  | `Future<bool>`   | Set clipboard     |
| `openUrl(url)`           | `Future<bool>`   | Open in browser   |

### Environment

| Property/Method | Returns   | Description          |
| --------------- | --------- | -------------------- |
| `env(name)`     | `String?` | Environment variable |
| `homeDir`       | `String`  | Home directory       |
| `tempDir`       | `String`  | Temp directory       |
| `platform`      | `String`  | Platform name        |
| `isMobile`      | `bool`    | Running on mobile    |
| `isDesktop`     | `bool`    | Running on desktop   |

### Encoding

| Method                | Returns  | Description   |
| --------------------- | -------- | ------------- |
| `hashMd5(input)`      | `String` | MD5 hash      |
| `hashSha256(input)`   | `String` | SHA256 hash   |
| `uuid()`              | `String` | UUID v4       |
| `base64Encode(input)` | `String` | Base64 encode |
| `base64Decode(input)` | `String` | Base64 decode |

## Compiling Plugins

```bash
# Compile to native binary
dart compile exe my_plugin.dart -o my_plugin.5m.dart.exe

# Move to plugins directory
mv my_plugin.5m.dart.exe ~/.crossbar/plugins/
```

## License

MIT License - see [LICENSE](../../LICENSE) for details.
