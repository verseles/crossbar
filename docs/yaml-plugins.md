# YAML Plugins Guide

Create plugins without writing code using declarative YAML configuration.

## Basic Structure

```yaml
name: Plugin Name
interval: 5m # Optional, extracted from filename

source:
  type: http|system|exec|static
  # source-specific options

output:
  icon: "🎯"
  text: "${response.field}"
  tooltip: "Optional tooltip"

menu: # Optional
  - title: "Menu item"
    action: url:https://example.com
  - separator
  - title: "Refresh"
    action: refresh
```

## Source Types

### HTTP

Fetch data from APIs:

```yaml
source:
  type: http
  url: "https://api.example.com/data"
  method: GET # Optional, default: GET
  headers: # Optional
    Authorization: "Bearer ${API_TOKEN}"
```

**Environment Variables**: Use `${VAR_NAME}` to inject from environment.

### System

Get system information:

```yaml
source:
  type: system
  command: cpu|memory|battery|time|date|uptime|network
```

| Command   | Returns                              |
| --------- | ------------------------------------ |
| `cpu`     | `{value, percent}`                   |
| `memory`  | `{total, used, free, percent, unit}` |
| `battery` | `{level, charging, status}`          |
| `time`    | `{value}`                            |
| `date`    | `{value}`                            |
| `uptime`  | `{value}`                            |
| `network` | `{status, localIp}`                  |

### Exec

Run shell commands:

```yaml
source:
  type: exec
  command: "uname -r"
```

Returns: `{output}`

### Static

Inline data:

```yaml
source:
  type: static
  data:
    name: "John"
    value: 42
```

## Template Syntax

Access data using `${path.to.value}`:

```yaml
output:
  text: "${response.data.amount}"      # Nested access
  text: "${response.items[0].name}"    # Array access
  text: "Hello ${USER}"                # Environment variable
```

## Menu Items

```yaml
menu:
  - title: "Open Website"
    action: url:https://example.com

  - title: "Run Command"
    action: exec:gnome-system-monitor

  - separator

  - title: "Refresh"
    action: refresh
```

## Complete Examples

### Bitcoin Price

```yaml
name: Bitcoin Price
interval: 5m

source:
  type: http
  url: "https://api.coinbase.com/v2/prices/BTC-USD/spot"

output:
  icon: "₿"
  text: "$${response.data.amount}"
  tooltip: "BTC/USD from Coinbase"

menu:
  - title: "Open Coinbase"
    action: url:https://coinbase.com
  - separator
  - title: "Refresh"
    action: refresh
```

### CPU Monitor

```yaml
name: CPU Monitor
interval: 5s

source:
  type: system
  command: cpu

output:
  icon: "💻"
  text: "${response.percent}%"

menu:
  - title: "Open System Monitor"
    action: exec:gnome-system-monitor
```

### Weather

```yaml
name: Weather
interval: 30m

source:
  type: http
  url: "https://api.openweathermap.org/data/2.5/weather?q=London&appid=${WEATHER_API_KEY}&units=metric"

output:
  icon: "🌡️"
  text: "${response.main.temp}°C"
  tooltip: "${response.weather[0].description}"

menu:
  - title: "Humidity: ${response.main.humidity}%"
  - title: "Wind: ${response.wind.speed} m/s"
  - separator
  - title: "Open Weather.com"
    action: url:https://weather.com
```

## Tips

1. **File naming**: Use `name.interval.yaml` format (e.g., `bitcoin.5m.yaml`)
2. **Environment variables**: Store API keys in env vars, not in the YAML
3. **Fallback**: If a path doesn't exist, it renders as empty string
4. **Mobile**: YAML plugins work on all platforms including mobile!
