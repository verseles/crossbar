# Plugin Types

Crossbar supports multiple plugin types, each with different trade-offs. Choose the right type for your use case.

## Quick Comparison

| Type                 | Extension           | Platforms | External Packages | Complexity        | Performance    |
| -------------------- | ------------------- | --------- | ----------------- | ----------------- | -------------- |
| **YAML**             | `.yaml`             | All       | ❌ No             | ⭐ Easiest        | ⚡ Fast        |
| **Dart Interpreted** | `.dart`             | All       | ❌ No             | ⭐⭐ Easy         | ⚡ Fast        |
| **Script**           | `.sh`, `.py`, `.js` | Desktop   | ✅ Yes            | ⭐⭐⭐ Medium     | ⚡⚡ Medium    |
| **Dart Compiled**    | `.dart.exe`         | Desktop   | ✅ Yes            | ⭐⭐⭐⭐ Advanced | ⚡⚡⚡ Fastest |

## YAML Plugins (Declarative)

**Best for:** Simple data display, API fetching, system monitoring

No code required! Define data sources and templates in YAML.

```yaml
# plugins/bitcoin.5m.yaml
name: Bitcoin Price
interval: 5m

source:
  type: http
  url: "https://api.coinbase.com/v2/prices/BTC-USD/spot"

output:
  icon: "₿"
  text: "$${response.data.amount}"
```

### Source Types

| Type     | Use Case                             |
| -------- | ------------------------------------ |
| `http`   | Fetch data from APIs                 |
| `system` | Get CPU, memory, battery, time, etc. |
| `exec`   | Run shell commands                   |
| `static` | Inline data                          |

📖 See [YAML Plugins Guide](yaml-plugins.md)

## Dart Interpreted Plugins

**Best for:** Logic that's too complex for YAML, but doesn't need external packages

Uses `dart_eval` to run Dart code at runtime. Works on all platforms including mobile.

```dart
// plugins/clock.1s.dart
import 'package:crossbar_bridge/crossbar_bridge.dart';

void main() {
  final crossbar = CrossbarBridge();
  final time = crossbar.time('HH:mm:ss');
  print('⏰ $time');
}
```

### Available APIs

- `crossbar.cpu()`, `memory()`, `battery()`
- `crossbar.time()`, `date()`
- `crossbar.web(url)`
- `crossbar.exec(command)`
- `crossbar.notify(title, message)`

📖 See [Dart Plugins Guide](dart-plugins.md)

## Script Plugins

**Best for:** Leveraging existing scripts, using language-specific libraries

Traditional scripts that run as subprocesses. Desktop only.

```bash
#!/bin/bash
# plugins/uptime.1h.sh
echo "⏱️ $(uptime -p | sed 's/up //')"
```

### Supported Languages

- Bash (`.sh`)
- Python (`.py`)
- Node.js (`.js`)
- Go (`.go`)
- Rust (`.rs`)

## Dart Compiled Plugins

**Best for:** Maximum performance, using any pub.dev package

Full Dart with `crossbar_api` package. Compile to native binary.

```dart
// my_plugin.dart
import 'package:crossbar_api/crossbar_api.dart';
import 'package:some_package/some_package.dart'; // Any package!

void main() async {
  final cpu = await Crossbar.cpu();
  print('💻 $cpu%');
}
```

Compile:

```bash
dart compile exe my_plugin.dart -o my_plugin.5s.dart.exe
```

📖 See [crossbar_api Package](../packages/crossbar_api/README.md)

## Decision Flowchart

```
Need external packages?
├── No → Need complex logic?
│   ├── No → Use YAML
│   └── Yes → Use Dart Interpreted
└── Yes → Need mobile support?
    ├── Yes → (Not supported yet, use YAML/Interpreted)
    └── No → Use Script or Dart Compiled
```

## File Naming Convention

All plugins follow this pattern:

```
name.interval.extension
```

Examples:

- `cpu.5s.sh` - Runs every 5 seconds
- `weather.30m.yaml` - Runs every 30 minutes
- `backup.1h.dart` - Runs every hour

Intervals:

- `s` - seconds
- `m` - minutes
- `h` - hours
