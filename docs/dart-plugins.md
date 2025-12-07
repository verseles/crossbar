# Dart Plugins Guide

Create Dart plugins that run on all platforms including mobile.

## Two Approaches

### 1. Interpreted (Recommended for Simple Plugins)

Uses `dart_eval` for runtime execution. No compilation needed.

```dart
// plugins/clock.1s.dart
import 'package:crossbar_bridge/crossbar_bridge.dart';

void main() {
  final crossbar = CrossbarBridge();
  print('⏰ ${crossbar.time()}');
}
```

**Pros:**

- ✅ Works on all platforms (mobile + desktop)
- ✅ No compilation step
- ✅ Sandboxed execution
- ✅ Simple deployment

**Cons:**

- ❌ Cannot use external packages
- ❌ Limited to CrossbarBridge APIs

### 2. Compiled (For Advanced Plugins)

Uses `crossbar_api` package. Compile to native binary.

```dart
// my_plugin.dart
import 'package:crossbar_api/crossbar_api.dart';
import 'package:http/http.dart' as http; // Any package!

void main() async {
  final cpu = await Crossbar.cpu();
  print('💻 $cpu%');
}
```

Compile:

```bash
dart compile exe my_plugin.dart -o my_plugin.5s.dart.exe
```

**Pros:**

- ✅ Use any pub.dev package
- ✅ Maximum performance
- ✅ Full Dart language

**Cons:**

- ❌ Desktop only
- ❌ Requires compilation
- ❌ Larger file size

## Interpreted Plugin API

### Setup

```dart
import 'package:crossbar_bridge/crossbar_bridge.dart';

void main() {
  final crossbar = CrossbarBridge();
  // Use crossbar.* methods
}
```

### Available Methods

#### System

```dart
final cpu = await crossbar.cpu();        // double (0-100)
final mem = await crossbar.memory();     // Map with total, used, free
final bat = await crossbar.battery();    // Map with level, charging
final up = await crossbar.uptime();      // String
```

#### Time

```dart
final time = crossbar.time();            // "HH:mm:ss"
final time = crossbar.time('HH:mm');     // Custom format
final date = crossbar.date();            // "yyyy-MM-dd"
```

#### Network

```dart
final status = await crossbar.netStatus(); // bool
final ip = await crossbar.localIp();       // String
final pub = await crossbar.publicIp();     // String
final data = await crossbar.web(url);      // String or Map
```

#### Utilities

```dart
final out = await crossbar.exec('ls');           // String
await crossbar.notify('Title', 'Message');       // void
final clip = await crossbar.clipboard();         // String
await crossbar.setClipboard('text');             // void
```

#### Environment

```dart
final home = crossbar.homeDir;           // String
final platform = crossbar.platform;      // "linux", "macos", etc.
final isMobile = crossbar.isMobile;      // bool
final key = crossbar.env('API_KEY');     // String?
```

## Output Format

Plugins output to stdout. First line is displayed in menubar.

```dart
void main() {
  // Main text (shown in menubar)
  print('⏰ 14:30');

  // Menu items (after ---)
  print('---');
  print('Full date: 2024-12-06');
  print('---');
  print('Refresh | refresh=true');
}
```

## Complete Examples

### CPU Monitor

```dart
import 'package:crossbar_bridge/crossbar_bridge.dart';

void main() async {
  final crossbar = CrossbarBridge();
  final cpu = await crossbar.cpu();

  String icon;
  if (cpu > 80) {
    icon = '🔥';
  } else if (cpu > 50) {
    icon = '⚡';
  } else {
    icon = '💻';
  }

  print('$icon ${cpu.toStringAsFixed(0)}%');
}
```

### Network Status

```dart
import 'package:crossbar_bridge/crossbar_bridge.dart';

void main() async {
  final crossbar = CrossbarBridge();
  final online = await crossbar.netStatus();

  if (online) {
    final ip = await crossbar.localIp();
    print('🌐 Online ($ip)');
  } else {
    print('📵 Offline');
  }
}
```

### Weather (with API)

```dart
import 'package:crossbar_bridge/crossbar_bridge.dart';

void main() async {
  final crossbar = CrossbarBridge();
  final apiKey = crossbar.env('WEATHER_API_KEY');

  if (apiKey == null) {
    print('⚠️ No API key');
    return;
  }

  final data = await crossbar.web(
    'https://api.openweathermap.org/data/2.5/weather?q=London&appid=$apiKey&units=metric'
  );

  if (data is Map) {
    final temp = data['main']['temp'];
    final desc = data['weather'][0]['description'];
    print('🌡️ ${temp.round()}°C');
    print('---');
    print('$desc');
  }
}
```

## Tips

1. **File naming**: `name.interval.dart` (e.g., `clock.1s.dart`)
2. **Always include import**: `import 'package:crossbar_bridge/crossbar_bridge.dart';`
3. **Error handling**: Wrap network calls in try-catch
4. **Async**: Use `async/await` for system and network calls
5. **Output**: First `print()` is shown in menubar, rest is dropdown
