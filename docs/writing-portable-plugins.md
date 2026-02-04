# Writing Portable Plugins

Best practices for creating plugins that work across platforms.

## Platform Compatibility Matrix

| Plugin Type      | Linux | macOS | Windows | Android | iOS |
| ---------------- | ----- | ----- | ------- | ------- | --- |
| Lua              | ✅    | ✅    | ✅      | ✅      | ✅  |
| YAML             | ✅    | ✅    | ✅      | ✅      | ✅  |
| Dart Interpreted | ✅    | ✅    | ✅      | ✅      | ✅  |
| Script (.sh)     | ✅    | ✅    | ⚠️      | ❌      | ❌  |
| Script (.py)     | ✅    | ✅    | ✅      | ❌      | ❌  |
| Dart Compiled    | ✅    | ✅    | ✅      | ❌      | ❌  |

## Best Practices

### 1. Prefer YAML for Simple Tasks

If your plugin just fetches data and displays it, use YAML:

```yaml
# ✅ Portable - works everywhere
name: Bitcoin
source:
  type: http
  url: "https://api.coinbase.com/v2/prices/BTC-USD/spot"
output:
  text: "₿ $${response.data.amount}"
```

### 2. Use Interpreted Dart for Logic

If you need conditionals or calculations, use interpreted Dart:

```dart
// ✅ Portable - works everywhere
import 'package:crossbar_bridge/crossbar_bridge.dart';

void main() async {
  final crossbar = CrossbarBridge();
  final cpu = await crossbar.cpu();

  // Logic that YAML can't do
  final icon = cpu > 80 ? '🔥' : '💻';
  print('$icon ${cpu.toStringAsFixed(0)}%');
}
```

### 3. Avoid Shell Commands When Possible

Instead of:

```bash
# ❌ Only works on Linux/macOS
#!/bin/bash
uptime -p
```

Use:

```yaml
# ✅ Portable
source:
  type: system
  command: uptime
output:
  text: "⏱️ ${response.value}"
```

### 4. Handle Missing Features Gracefully

```dart
void main() async {
  final crossbar = CrossbarBridge();

  // Battery might not be available on desktop
  final battery = await crossbar.battery();
  if (battery['level'] != null) {
    print('🔋 ${battery['level']}%');
  } else {
    print('🔌 Plugged in');
  }
}
```

### 5. Use Environment Variables for Config

```yaml
# Config in environment, not hardcoded
source:
  type: http
  url: "https://api.example.com?key=${API_KEY}"
```

### 6. Provide Fallback Variants

Create multiple versions of the same plugin:

```
plugins/
├── weather.30m.yaml      # Portable version
├── weather.30m.sh        # Linux/macOS with more features
└── weather.30m.dart      # Dart version with logic
```

Crossbar will prefer the most compatible one.

## API Portability

### Always Portable

These work on all platforms:

- `crossbar.time()`, `date()`
- `crossbar.web(url)`
- `crossbar.env(name)`
- `crossbar.platform`, `isMobile`, `isDesktop`
- `crossbar.uuid()`, `hash()`, `base64*()`

### Desktop Only

These require desktop:

- `crossbar.exec(command)`
- `crossbar.clipboard()`, `setClipboard()`
- `crossbar.notify()` (on mobile, use push notifications instead)
- `crossbar.openUrl()`, `openFile()`

### Mobile Web Cache

On mobile, Lua `crossbar.web()` returns the last successful response and
refreshes in the background. If there is no cached value yet, it may return
an error with `message = "Fetching..."` on the first call.

### Platform-Specific Results

These work everywhere but have different data:

- `crossbar.cpu()` - Different methods per OS
- `crossbar.memory()` - Different precision
- `crossbar.battery()` - May return null on desktop

## Testing Portability

### 1. Test on Multiple Platforms

```bash
# Linux
flutter test

# Run on Android emulator
flutter run -d android

# Run on iOS simulator
flutter run -d ios
```

### 2. Check Platform in Code

```dart
if (crossbar.isMobile) {
  // Mobile-specific behavior
} else {
  // Desktop-specific behavior
}
```

### 3. Graceful Degradation

```dart
void main() async {
  final crossbar = CrossbarBridge();

  try {
    final result = await crossbar.exec('custom-command');
    print(result);
  } catch (e) {
    // Fallback for mobile
    print('Feature not available');
  }
}
```

## Summary

| Goal                  | Solution                          |
| --------------------- | --------------------------------- |
| Maximum portability   | Use YAML plugins                  |
| Portable with logic   | Use interpreted Dart              |
| Use external packages | Use compiled Dart (desktop only)  |
| Maximum performance   | Use compiled Dart                 |
| Existing scripts      | Use script plugins (desktop only) |
