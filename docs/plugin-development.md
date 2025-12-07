# Crossbar Plugin Development Guide

A comprehensive tutorial for creating plugins for Crossbar.

**Version**: 1.0.0
**Last Updated**: December 2025

## Table of Contents

1. [Introduction](#introduction)
2. [Quick Start](#quick-start)
3. [Plugin Fundamentals](#plugin-fundamentals)
4. [Output Format](#output-format)
5. [Language Guides](#language-guides)
6. [Configuration Files](#configuration-files)
7. [Environment Variables](#environment-variables)
8. [Best Practices](#best-practices)
9. [Debugging](#debugging)
10. [Publishing Plugins](#publishing-plugins)

---

## Introduction

Crossbar plugins are simple scripts that output information in a specific format. Plugins can be written in any language that can output to stdout:

- **Bash** (.sh)
- **Python** (.py)
- **Node.js** (.js)
- **Dart** (.dart)
- **Go** (.go)
- **Rust** (.rs)

Plugins are executed periodically based on the interval specified in their filename.

### How Plugins Work

1. Crossbar discovers plugins in the plugins directory
2. The filename determines the refresh interval (e.g., `cpu.10s.sh` runs every 10 seconds)
3. Crossbar executes the plugin and captures stdout
4. Output is parsed and displayed in the menu bar/system tray

---

## Quick Start

### Using the CLI (Recommended)

The fastest way to create a plugin:

```bash
# Create a Python monitor plugin
crossbar init --lang python --type monitor --name my-plugin

# Output:
# Plugin created: ~/.crossbar/plugins/my-plugin.10s.py
# Config file: ~/.crossbar/plugins/my-plugin.10s.py.schema.json
```

### Available Options

```bash
crossbar init --lang <language> --type <type> [--name <name>] [--output <dir>]
```

**Languages**: `bash`, `python`, `node`, `dart`, `go`, `rust`

**Types and Intervals**:
| Type | Interval | Use Case |
|------|----------|----------|
| `clock` | 1s | Time displays, live counters |
| `monitor` | 10s | System stats, resource monitoring |
| `status` | 30s | Service status, connectivity |
| `api` | 5m | External APIs, rate-limited services |
| `custom` | 1m | General purpose |

### Manual Plugin Creation

1. Create a script file with the naming convention: `name.interval.extension`
2. Make it executable: `chmod +x plugin.10s.sh`
3. Place it in `~/.crossbar/plugins/` or the language subdirectory

**Example** - `hello.30s.sh`:

```bash
#!/bin/bash
echo "Hello World"
```

---

## Plugin Fundamentals

### Filename Convention

Plugins follow this naming pattern:

```
<name>.<interval>.<extension>
```

**Examples**:

- `cpu.10s.sh` - CPU monitor, refreshes every 10 seconds
- `weather.30m.py` - Weather, refreshes every 30 minutes
- `clock.1s.js` - Clock, refreshes every second

**Supported Intervals**:
| Suffix | Duration |
|--------|----------|
| `s` | Seconds |
| `m` | Minutes |
| `h` | Hours |
| `d` | Days |

**Examples**: `1s`, `5s`, `10s`, `30s`, `1m`, `5m`, `15m`, `30m`, `1h`, `6h`, `1d`

### Plugin Discovery

Crossbar searches for plugins in:

1. `~/.crossbar/plugins/` (user plugins - flat structure)
2. `~/.crossbar/plugins/<subdirectory>/` (git repositories or organized folders, 1 level deep)
3. Application bundle's `plugins/` directory (bundled examples)

---

## Output Format

Crossbar supports two output formats: **BitBar Text Format** and **JSON**.

### BitBar Text Format

The traditional format, compatible with BitBar and Argos.

#### Basic Output

```
Title text
```

Just output a single line for the menu bar title.

#### With Dropdown Menu

```
Title text
---
Menu item 1
Menu item 2
Menu item 3
```

The first line is the title. After `---`, each line becomes a menu item.

#### Attributes

Add attributes using the pipe (`|`) character:

```
Title | color=blue size=14 font=Monaco
---
Red item | color=red
Green item | color=green
Bold item | font=bold
```

**Supported Attributes**:

| Attribute       | Description              | Example                        |
| --------------- | ------------------------ | ------------------------------ |
| `color`         | Text color (name or hex) | `color=red`, `color=#FF5733`   |
| `size`          | Font size                | `size=14`                      |
| `font`          | Font name or style       | `font=Monaco`, `font=bold`     |
| `href`          | URL to open on click     | `href=https://github.com`      |
| `bash`          | Shell command to run     | `bash=/usr/bin/open -a Safari` |
| `terminal`      | Run in terminal          | `terminal=true`                |
| `refresh`       | Refresh plugin on click  | `refresh=true`                 |
| `image`         | Base64 encoded image     | `image=iVBORw0KGgo...`         |
| `templateImage` | Template image (macOS)   | `templateImage=...`            |
| `dropdown`      | Include in dropdown      | `dropdown=false`               |

#### Nested Submenus

Use `--` prefix for submenu items:

```
Main Title
---
Parent Item
--Child Item 1
--Child Item 2
----Grandchild Item
Another Item
```

#### Examples

**CPU Monitor**:

```
🖥️ 23.5% | color=green
---
CPU Usage: 23.5%
Cores: 8
---
Show Details | href=file:///proc/cpuinfo
Refresh | refresh=true
```

**Weather**:

```
☀️ 24°C
---
Location: London
Condition: Sunny
Humidity: 45%
---
Open Weather App | bash=open -a Weather
Refresh | refresh=true
```

### JSON Output Format

For more complex data, use JSON:

```json
{
  "icon": "🔋",
  "text": "85%",
  "color": "green",
  "menu": [
    { "text": "Battery: 85%" },
    { "text": "Time remaining: 3:45" },
    { "separator": true },
    {
      "text": "Power Settings",
      "href": "x-apple.systempreferences:com.apple.preference.battery"
    }
  ]
}
```

**JSON Schema**:

```json
{
  "icon": "string", // Emoji or icon character
  "text": "string", // Main display text
  "color": "string", // Text color
  "font": "string", // Font name
  "size": "number", // Font size
  "tooltip": "string", // Tooltip text
  "menu": [
    // Dropdown menu items
    {
      "text": "string", // Menu item text
      "color": "string", // Item color
      "href": "string", // URL to open
      "bash": "string", // Command to run
      "terminal": "boolean", // Run in terminal
      "refresh": "boolean", // Refresh after click
      "separator": "boolean", // Is separator line
      "submenu": [] // Nested submenu
    }
  ]
}
```

---

## Language Guides

### Bash

Simple and fast for system commands.

```bash
#!/bin/bash
# cpu.10s.sh - CPU Monitor

cpu=$(crossbar cpu) # Use the Crossbar CLI API to get CPU usage

# Color based on load
if (( $(echo "$cpu > 80" | bc -l 2>/dev/null || echo 0) )); then
    color="red"
elif (( $(echo "$cpu > 50" | bc -l 2>/dev/null || echo 0) )); then
    color="yellow"
else
    color="green"
fi

echo "🖥️ ${cpu}% | color=$color"
echo "---"
echo "CPU Usage: ${cpu}%"
echo "Refresh | refresh=true"
```

**Tips**:

- Use `#!/bin/bash` shebang
- Handle errors with `|| echo "fallback"`
- Use `2>/dev/null` to suppress error output

### Python

Best for API calls and complex logic.

```python
#!/usr/bin/env python3
"""weather.30m.py - Weather Plugin"""

import json
import subprocess # Import subprocess for calling crossbar CLI
import urllib.parse
import os

CITY = os.environ.get('CROSSBAR_WEATHER_CITY', 'London')
UNITS = os.environ.get('CROSSBAR_PLUGIN_UNITS', 'celsius') # Use CROSSBAR_PLUGIN_UNITS

def get_weather():
    try:
        encoded_city = urllib.parse.quote(CITY)
        url = f"https://wttr.in/{encoded_city}?format=j1"
        # Use crossbar web command for HTTP request
        result = subprocess.run(
            ['crossbar', 'web', url, '--json'],
            capture_output=True,
            text=True,
            check=True # Raise an exception for non-zero exit codes
        )
        data = json.loads(result.stdout)
        current = data['current_condition'][0]
            
        # Get temp based on units preference
        if UNITS == 'fahrenheit':
            temp = current['temp_F']
            unit = 'F'
        else:
            temp = current['temp_C']
            unit = 'C'
        
        desc = current['weatherDesc'][0]['value']
        humidity = current['humidity']
        
        # Weather icons based on condition
        if 'sun' in desc.lower() or 'clear' in desc.lower():
            icon = '☀️'
        elif 'cloud' in desc.lower():
            icon = '☁️'
        elif 'rain' in desc.lower():
            icon = '🌧️'
        elif 'snow' in desc.lower():
            icon = '🌨️'
        else:
            icon = '🌈'

        return {
            'icon': icon,
            'temp': temp,
            'unit': unit,
            'desc': desc,
            'humidity': humidity,
            'city': CITY
        }
    except subprocess.CalledProcessError as e:
        return {'error': f"Crossbar web command failed: {e.stderr.strip()}"}
    except json.JSONDecodeError as e:
        return {'error': f"Failed to parse JSON response: {e}"}
    except Exception as e:
        return {'error': str(e)}

weather = get_weather()

if 'error' in weather:
    print(f" N/A | color=gray")
    print("---")
    print(f"Error: {weather['error']}")
else:
    print(f"{weather['icon']} {weather['temp']}°{weather['unit']}")
    print("---")
    print(f"Location: {weather['city']}")
    print(f"Condition: {weather['desc']}")
    print(f"Temperature: {weather['temp']}°{weather['unit']}")
    print(f"Humidity: {weather['humidity']}%")
    print("---")
    print("Refresh | refresh=true")
```

**Tips**:

- Use `#!/usr/bin/env python3` for portability
- Handle exceptions to avoid plugin failures
- Use environment variables for configuration
- Keep dependencies minimal (prefer stdlib)

### Node.js

Great for async operations and web APIs.

```javascript
#!/usr/bin/env node
/**
 * github-stars.1h.js - GitHub Stars Counter
 */

const https = require("https");

const REPO = process.env.CROSSBAR_GITHUB_REPO || "verseles/crossbar";

function fetchStars() {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: "api.github.com",
      path: `/repos/${REPO}`,
      headers: { "User-Agent": "Crossbar-Plugin" },
    };

    https
      .get(options, (res) => {
        let data = "";
        res.on("data", (chunk) => (data += chunk));
        res.on("end", () => {
          try {
            const json = JSON.parse(data);
            resolve(json.stargazers_count);
          } catch (e) {
            reject(e);
          }
        });
      })
      .on("error", reject);
  });
}

(async () => {
  try {
    const stars = await fetchStars();
    console.log(`⭐ ${stars}`);
    console.log("---");
    console.log(`Repository: ${REPO}`);
    console.log(`Stars: ${stars}`);
    console.log("---");
    console.log(`Open Repo | href=https://github.com/${REPO}`);
    console.log("Refresh | refresh=true");
  } catch (error) {
    console.log("⭐ Error | color=red");
    console.log("---");
    console.log(`Error: ${error.message}`);
  }
})();
```

**Tips**:

- Use `#!/usr/bin/env node` shebang
- Use async/await for cleaner async code
- Wrap in IIFE for top-level await

### Dart

Ideal for complex plugins that benefit from type safety.

```dart
#!/usr/bin/env dart
// system-info.1m.dart - System Information

import 'dart:io';
import 'dart:convert'; // For JSON parsing

void main() async {
  final List<String> output = [];

  output.add('System Information');
  output.add('---');

  // OS Info
  final osResult = await Process.run('crossbar', ['os', '--json']);
  if (osResult.exitCode == 0) {
    try {
      final osInfo = jsonDecode(osResult.stdout.toString());
      output.add('OS: ${osInfo['name']} (${osInfo['short']})');
      output.add('Version: ${osInfo['version']}');
      output.add('Kernel: ${osInfo['kernel']}');
      output.add('Architecture: ${osInfo['arch']}');
    } catch (e) {
      output.add('OS: Error parsing crossbar os --json');
    }
  } else {
    output.add('OS: Error getting info from crossbar os');
  }

  // CPU Cores (derived from cpu --json)
  final cpuResult = await Process.run('crossbar', ['cpu', '--json']);
  if (cpuResult.exitCode == 0) {
    try {
      final cpuInfo = jsonDecode(cpuResult.stdout.toString());
      output.add('Processors: ${cpuInfo['cores']}');
    } catch (e) {
      output.add('Processors: Error parsing crossbar cpu --json');
    }
  } else {
    output.add('Processors: Error getting info from crossbar cpu');
  }

  // Locale
  final localeResult = await Process.run('crossbar', ['locale']);
  if (localeResult.exitCode == 0) {
    output.add('Locale: ${localeResult.stdout.toString().trim()}');
  } else {
    output.add('Locale: Error getting info from crossbar locale');
  }

  // Environment variables (keep as is, as crossbar env is meant for plugin's perspective)
  output.add('---');
  output.add('Environment:');
  Platform.environment.forEach((key, value) {
    if (key.startsWith('CROSSBAR_')) {
      output.add('  $key: $value');
    }
  });

  output.add('---');
  output.add('Refresh | refresh=true');

  for (final line in output) {
    print(line);
  }
}
```

**Tips**:

- Use `#!/usr/bin/env dart` for script mode
- Import only `dart:io` and `dart:convert` for zero dependencies
- Take advantage of type safety

### Go

Excellent performance for computationally intensive plugins.

```go
package main

import (
	"fmt"
	"os/exec"
	"strconv"
	"strings"
)

func main() {
	// Use Crossbar CLI API to get current time
	cmd := exec.Command("crossbar", "time", "24h") // Request 24-hour format
	output, err := cmd.Output()
	timeStr := "N/A"
	if err == nil {
		timeStr = strings.TrimSpace(string(output)) // Example: "14:30:05"
	}

	// Parse time string to get hour for color logic
	hour := -1
	if parts := strings.Split(timeStr, ":"); len(parts) >= 1 {
		if h, err := strconv.Atoi(parts[0]); err == nil {
			hour = h
		}
	}

	// Determine icon
	icon := "⏰"

	// Determine color based on time of day (example logic)
	var color string
	if hour >= 6 && hour < 12 {
		color = "blue" // Morning
	} else if hour >= 12 && hour < 18 {
		color = "green" // Afternoon
	} else {
		color = "gray" // Evening/Night
	}

	// Print output
	fmt.Printf("%s %s | color=%s\n", icon, timeStr, color)
	fmt.Println("---")
	fmt.Printf("Current Time: %s\n", timeStr)
	// Optionally get date using crossbar date
	cmdDate := exec.Command("crossbar", "date")
	outputDate, errDate := cmdDate.Output()
	dateStr := "N/A"
	if errDate == nil {
		dateStr = strings.TrimSpace(string(outputDate))
	}
	fmt.Printf("Current Date: %s\n", dateStr)
	fmt.Println("Refresh | refresh=true")
}
```

**Important**: Include `// +build ignore` at the top to prevent Go from trying to build it as a package.

**Tips**:

- Use `// +build ignore` directive
- Crossbar runs plugins with `go run`
- Keep imports minimal for fast compilation

### Rust

Maximum performance with memory safety.

```rust
use std::process::Command;
use std::str;
use std::str::FromStr;

fn main() {
    // Use Crossbar CLI API to get current time
    let output_time = Command::new("crossbar")
        .arg("time")
        .arg("24h")
        .output();

    let time_str = match output_time {
        Ok(cmd_output) => str::from_utf8(&cmd_output.stdout).unwrap_or("N/A").trim().to_string(),
        Err(_) => "N/A".to_string(),
    };

    // Use Crossbar CLI API to get current date
    let output_date = Command::new("crossbar")
        .arg("date")
        .output();

    let date_str = match output_date {
        Ok(cmd_output) => str::from_utf8(&cmd_output.stdout).unwrap_or("N/A").trim().to_string(),
        Err(_) => "N/A".to_string(),
    };

    // Try to parse hour for icon logic
    let mut hour: i32 = -1;
    if let Some(h_str) = time_str.split(':').next() {
        if let Ok(h) = i32::from_str(h_str) {
            hour = h;
        }
    }

    // Determine icon based on time of day
    let icon = match hour {
        6..=11 => "\u{1F305}", // sunrise
        12..=17 => "\u{2600}\u{FE0F}", // sun
        18..=20 => "\u{1F307}", // sunset
        _ => "\u{1F319}", // moon
    };

    println!("{} {}", icon, time_str);
    println!("---");
    println!("Date: {}", date_str);
    // Removed Week and Day of Year as crossbar CLI doesn't provide these directly in a simple format
    println!("---");
    println!("Refresh | refresh=true");
}```

**Note**: Rust plugins are compiled on first run. Crossbar handles compilation automatically.

**Tips**:

- Avoid external crates for faster compilation
- Use standard library when possible
- Compiled binary is cached for subsequent runs

---

## Configuration Files

Plugins can have associated configuration files that allow users to customize behavior.

### Configuration File Location

Configuration files are placed alongside the plugin:

```
plugin.10s.py
plugin.10s.py.config.json
```

### Configuration Schema

```json
{
  "name": "My Plugin",
  "version": "1.0.0",
  "description": "A description of what the plugin does",
  "author": "Your Name",
  "settings": [
    {
      "key": "API_KEY",
      "type": "password",
      "label": "API Key",
      "default": "",
      "required": true,
      "description": "Your API key from example.com"
    },
    {
      "key": "CITY",
      "type": "text",
      "label": "City Name",
      "default": "London",
      "required": false
    },
    {
      "key": "UNITS",
      "type": "dropdown",
      "label": "Temperature Units",
      "options": ["celsius", "fahrenheit"],
      "default": "celsius"
    },
    {
      "key": "SHOW_HUMIDITY",
      "type": "checkbox",
      "label": "Show Humidity",
      "default": true
    }
  ]
}
```

### Field Types

| Type       | Description         | Options              |
| ---------- | ------------------- | -------------------- |
| `text`     | Text input          | -                    |
| `password` | Masked text input   | -                    |
| `number`   | Numeric input       | `min`, `max`, `step` |
| `checkbox` | Boolean toggle      | -                    |
| `dropdown` | Select from options | `options`            |
| `slider`   | Range slider        | `min`, `max`, `step` |
| `color`    | Color picker        | -                    |
| `file`     | File path selector  | -                    |
| `textarea` | Multi-line text     | -                    |

See [Configuration Schema](config-schema.md) for complete documentation.

---

## Environment Variables

Crossbar injects several environment variables when running plugins:

### Standard Variables

| Variable               | Description       | Example                                   |
| ---------------------- | ----------------- | ----------------------------------------- |
| `CROSSBAR_VERSION`     | Crossbar version  | `1.0.0`                                   |
| `CROSSBAR_OS`          | Operating system  | `linux`, `macos`, `windows`               |
| `CROSSBAR_PLUGIN_ID`   | Plugin identifier | `cpu.10s.sh`                              |
| `CROSSBAR_PLUGIN_PATH` | Full plugin path  | `/home/user/.crossbar/plugins/cpu.10s.sh` |
| `CROSSBAR_PLUGINS_DIR` | Plugins directory | `/home/user/.crossbar/plugins`            |
| `CROSSBAR_CONFIG_DIR`  | Config directory  | `/home/user/.crossbar`                    |

### User-Defined Variables

Settings from configuration files are injected as environment variables:

```json
{
  "settings": [{ "key": "CITY", "type": "text", "default": "London" }]
}
```

In your plugin:

```bash
#!/bin/bash
echo "Weather in $CITY"
```

Or in Python:

```python
import os
city = os.environ.get('CITY', 'London')
```

---

## Best Practices

### Performance

1. **Keep execution fast**: Plugins should complete within a few seconds
2. **Cache expensive operations**: Store API responses for reuse
3. **Use appropriate intervals**: Don't poll every second for data that changes hourly

### Reliability

1. **Handle errors gracefully**: Always have fallback output
2. **Set timeouts**: Don't hang indefinitely on network requests
3. **Validate inputs**: Check environment variables exist

### User Experience

1. **Use meaningful icons**: Help users identify plugins at a glance
2. **Show loading states**: Output "Loading..." during long operations
3. **Provide useful tooltips**: Add context without cluttering the UI

### Security

1. **Don't hardcode secrets**: Use environment variables or config files
2. **Validate external data**: Sanitize API responses
3. **Limit file access**: Only access necessary files

### Example: Robust Plugin Template

```python
#!/usr/bin/env python3
"""robust-plugin.10s.py - Example of a well-structured plugin"""

import os
import json
import sys
import urllib.request
from datetime import datetime

# Configuration with defaults
API_KEY = os.environ.get('API_KEY', '')
TIMEOUT = int(os.environ.get('TIMEOUT', '5'))
DEBUG = os.environ.get('DEBUG', 'false').lower() == 'true'

def log(message):
    """Debug logging"""
    if DEBUG:
        print(f"[DEBUG] {message}", file=sys.stderr)

def fetch_data():
    """Fetch data with error handling"""
    if not API_KEY:
        return {'error': 'API_KEY not configured'}

    try:
        url = f"https://api.example.com/data?key={API_KEY}"
        req = urllib.request.Request(url)
        req.add_header('User-Agent', 'Crossbar-Plugin/1.0')

        with urllib.request.urlopen(req, timeout=TIMEOUT) as response:
            return json.loads(response.read().decode())
    except urllib.error.URLError as e:
        log(f"Network error: {e}")
        return {'error': f'Network error: {e.reason}'}
    except json.JSONDecodeError as e:
        log(f"Parse error: {e}")
        return {'error': 'Invalid response from API'}
    except Exception as e:
        log(f"Unexpected error: {e}")
        return {'error': str(e)}

def render_output(data):
    """Render plugin output"""
    if 'error' in data:
        print(f"⚠️ Error | color=red")
        print("---")
        print(f"Error: {data['error']}")
        print("---")
        print("Check configuration")
        return

    # Success case
    value = data.get('value', 'N/A')
    print(f"✅ {value} | color=green")
    print("---")
    print(f"Value: {value}")
    print(f"Updated: {datetime.now().strftime('%H:%M:%S')}")
    print("---")
    print("Refresh | refresh=true")

def main():
    log("Plugin starting")
    data = fetch_data()
    log(f"Data received: {data}")
    render_output(data)
    log("Plugin complete")

if __name__ == "__main__":
    main()
```

---

## Debugging

### Test Your Plugin

Run plugins directly from the command line:

```bash
# Bash
bash ./my-plugin.10s.sh

# Python
python3 ./my-plugin.10s.py

# Node.js
node ./my-plugin.1m.js

# Dart
dart ./my-plugin.30s.dart

# Go
go run ./my-plugin.5m.go

# Rust (compile first)
rustc ./my-plugin.1h.rs -o /tmp/plugin && /tmp/plugin
```

### Using the CLI

```bash
# Test via crossbar
crossbar exec "python3 ~/.crossbar/plugins/python/my-plugin.10s.py"
```

### Common Issues

#### Plugin Not Appearing

1. Check file permissions: `chmod +x plugin.sh`
2. Verify filename format: `name.interval.extension`
3. Check plugin directory location
4. Look for syntax errors: run manually

#### Output Not Displaying Correctly

1. Ensure first line is the title (no leading newlines)
2. Check for special characters that need escaping
3. Verify color names are valid

#### Plugin Timing Out

1. Default timeout is 30 seconds
2. Reduce complexity or increase interval
3. Add timeout handling in network requests

### Debug Mode

Add debug output to stderr (not captured by Crossbar):

```python
import sys

def debug(msg):
    print(f"[DEBUG] {msg}", file=sys.stderr)

debug("Starting plugin...")
```

### Viewing Logs

Crossbar logs are available at:

- Linux: `~/.crossbar/logs/crossbar.log`
- macOS: `~/Library/Logs/Crossbar/crossbar.log`
- Windows: `%APPDATA%\Crossbar\logs\crossbar.log`

---

## Publishing Plugins

### GitHub Repository Structure

```
my-crossbar-plugin/
├── plugin.30s.py           # Main plugin.10s.py.schema.json
├── plugin.30s.py.schema.json  # Configuration schema
├── README.md               # Documentation
├── LICENSE                 # License file
└── screenshots/            # Screenshots (optional)
    └── preview.png
```

### README Template

````markdown
# My Crossbar Plugin

Description of what your plugin does.

## Installation

```bash
crossbar install https://github.com/username/my-crossbar-plugin
```
````

## Configuration

After installation, configure in Crossbar settings:

| Setting | Description  | Default |
| ------- | ------------ | ------- |
| API_KEY | Your API key | -       |
| CITY    | City name    | London  |

## Screenshots

![Screenshot](screenshots/preview.png)

## License

MIT License

````

### Installation via CLI

Users can install your plugin with:

```bash
crossbar install https://github.com/username/my-crossbar-plugin
````

This will:

1. Clone the repository
2. Detect the plugin language
3. Move files to the plugins directory
4. Set executable permissions

---

## Examples

Crossbar comes with a rich set of **35+ example plugins** demonstrating various functionalities and languages.

Browse the `plugins/` directory for source code and ideas:

-   **Bash**, **Python**, **Node.js**, **Dart**, **Go**, **Rust**, **YAML**

These examples cover:
-   System monitoring (CPU, Memory, Battery, Disk, Uptime)
-   Network checks (Site-check, IP info)
-   Time and date displays
-   Media controls (Spotify)
-   Specific service integrations (Docker)
-   External API calls (Bitcoin, Weather, GitHub)

The `plugins/` directory is organized by language or type, making it easy to find examples relevant to your needs.


---

## Further Reading

- [API Reference](api-reference.md) - Complete CLI documentation
- [Configuration Schema](config-schema.md) - All config field types
- [GitHub Repository](https://github.com/verseles/crossbar) - Source code and issues

---

**Happy Plugin Development!** 🔌
