# Crossbar Configuration Schema

Complete documentation for plugin configuration field types and the grid layout system.

**Version**: 1.0.0
**Last Updated**: December 2025

## Table of Contents

1. [Overview](#overview)
2. [Configuration File Structure](#configuration-file-structure)
3. [Field Types Reference](#field-types-reference)
4. [Grid Layout System](#grid-layout-system)
5. [Validation Rules](#validation-rules)
6. [Examples](#examples)

---

## Overview

Crossbar plugins can declare their configuration in a JSON file. When present, Crossbar automatically generates a settings GUI for users to configure the plugin.

**Benefits**:
- No UI code required in plugins
- Consistent user experience across plugins
- Automatic validation and type checking
- Secure storage for sensitive values (passwords)

### Configuration File Location

Configuration files are placed alongside the plugin file:

```
plugin.10s.py
plugin.10s.py.config.json
```

---

## Configuration File Structure

### Basic Structure

```json
{
  "name": "Plugin Name",
  "version": "1.0.0",
  "description": "A description of what the plugin does",
  "author": "Author Name",
  "icon": "🔌",
  "config_required": "optional",
  "settings": [
    {
      "key": "SETTING_KEY",
      "label": "Setting Label",
      "type": "text",
      "default": "",
      "required": false,
      "placeholder": "Enter value...",
      "help": "Help text explaining the setting",
      "width": 50
    }
  ]
}
```

### Root Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `name` | string | Yes | Plugin display name |
| `version` | string | No | Plugin version (semver) |
| `description` | string | No | Plugin description |
| `author` | string | No | Author name or email |
| `icon` | string | No | Plugin icon (emoji or icon name) |
| `config_required` | string | No | `"required"` or `"optional"` |
| `settings` | array | Yes | Array of setting definitions |

### Setting Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `key` | string | Yes | Environment variable name |
| `label` | string | Yes | Display label |
| `type` | string | Yes | Field type (see below) |
| `default` | any | No | Default value |
| `required` | boolean | No | Whether the field is required |
| `placeholder` | string | No | Placeholder text for inputs |
| `help` | string | No | Help text shown below field |
| `width` | integer | No | Grid width (1-100) |
| `options` | object | No | Type-specific options |

---

## Field Types Reference

### Basic Inputs

#### `text`

Simple text input field.

```json
{
  "key": "USERNAME",
  "type": "text",
  "label": "Username",
  "placeholder": "Enter username",
  "default": ""
}
```

**Options**:
| Option | Type | Description |
|--------|------|-------------|
| `minLength` | number | Minimum characters |
| `maxLength` | number | Maximum characters |
| `pattern` | string | Regex pattern for validation |

---

#### `password`

Masked text input for sensitive data. Values are stored in the system's secure storage (Keychain on macOS, libsecret on Linux, Credential Manager on Windows).

```json
{
  "key": "API_KEY",
  "type": "password",
  "label": "API Key",
  "required": true,
  "help": "Get your API key from the settings page"
}
```

---

#### `number`

Numeric input with optional constraints.

```json
{
  "key": "REFRESH_RATE",
  "type": "number",
  "label": "Refresh Rate",
  "default": 10,
  "options": {
    "min": 1,
    "max": 3600,
    "step": 1,
    "unit": "seconds"
  }
}
```

**Options**:
| Option | Type | Description |
|--------|------|-------------|
| `min` | number | Minimum value |
| `max` | number | Maximum value |
| `step` | number | Step increment |
| `unit` | string | Unit label (displayed after input) |

---

#### `textarea`

Multi-line text input.

```json
{
  "key": "CUSTOM_SCRIPT",
  "type": "textarea",
  "label": "Custom Script",
  "placeholder": "Enter your custom code here...",
  "options": {
    "rows": 5
  }
}
```

**Options**:
| Option | Type | Description |
|--------|------|-------------|
| `rows` | number | Number of visible rows (default: 3) |
| `maxLength` | number | Maximum characters |

---

#### `hidden`

Hidden field (not shown in UI). Useful for storing internal values.

```json
{
  "key": "VERSION",
  "type": "hidden",
  "default": "1.0.0"
}
```

---

### Selection Fields

#### `select` / `dropdown`

Dropdown selection from predefined options.

```json
{
  "key": "TEMPERATURE_UNIT",
  "type": "select",
  "label": "Temperature Unit",
  "default": "celsius",
  "options": {
    "choices": [
      {"value": "celsius", "label": "Celsius (°C)"},
      {"value": "fahrenheit", "label": "Fahrenheit (°F)"},
      {"value": "kelvin", "label": "Kelvin (K)"}
    ]
  }
}
```

**Options**:
| Option | Type | Description |
|--------|------|-------------|
| `choices` | array | Array of `{value, label}` objects |

**Simple format** (value equals label):
```json
{
  "key": "COLOR",
  "type": "select",
  "options": {
    "choices": ["red", "green", "blue"]
  }
}
```

---

#### `radio`

Radio button group.

```json
{
  "key": "THEME",
  "type": "radio",
  "label": "Theme",
  "default": "system",
  "options": {
    "choices": [
      {"value": "light", "label": "Light"},
      {"value": "dark", "label": "Dark"},
      {"value": "system", "label": "System Default"}
    ]
  }
}
```

---

#### `checkbox`

Boolean toggle checkbox.

```json
{
  "key": "SHOW_NOTIFICATIONS",
  "type": "checkbox",
  "label": "Show Notifications",
  "default": true,
  "help": "Display desktop notifications for alerts"
}
```

---

#### `switch`

Toggle switch (visually different from checkbox).

```json
{
  "key": "ENABLED",
  "type": "switch",
  "label": "Enable Plugin",
  "default": true
}
```

---

#### `multiselect`

Select multiple options.

```json
{
  "key": "MONITORED_SERVICES",
  "type": "multiselect",
  "label": "Services to Monitor",
  "options": {
    "choices": [
      {"value": "nginx", "label": "Nginx"},
      {"value": "postgresql", "label": "PostgreSQL"},
      {"value": "redis", "label": "Redis"},
      {"value": "docker", "label": "Docker"}
    ]
  }
}
```

---

#### `tags`

Free-form tag input.

```json
{
  "key": "KEYWORDS",
  "type": "tags",
  "label": "Keywords",
  "options": {
    "suggestions": ["important", "urgent", "low-priority"],
    "max": 10
  }
}
```

**Options**:
| Option | Type | Description |
|--------|------|-------------|
| `suggestions` | array | Suggested tags (autocomplete) |
| `max` | number | Maximum number of tags |

---

### File Fields

#### `file`

File picker.

```json
{
  "key": "CONFIG_FILE",
  "type": "file",
  "label": "Configuration File",
  "options": {
    "accept": ".json,.yaml,.yml",
    "maxSize": "10MB"
  }
}
```

**Options**:
| Option | Type | Description |
|--------|------|-------------|
| `accept` | string | Accepted file extensions |
| `maxSize` | string | Maximum file size (e.g., "10MB") |

---

#### `directory`

Directory picker.

```json
{
  "key": "OUTPUT_DIR",
  "type": "directory",
  "label": "Output Directory",
  "default": "~/Downloads"
}
```

---

#### `path`

Generic path input (file or directory).

```json
{
  "key": "SCRIPT_PATH",
  "type": "path",
  "label": "Script Path",
  "placeholder": "/path/to/script.sh"
}
```

---

#### `image`

Image file picker with preview.

```json
{
  "key": "ICON",
  "type": "image",
  "label": "Custom Icon",
  "options": {
    "accept": ".png,.jpg,.svg",
    "maxSize": "2MB",
    "preview": true
  }
}
```

---

### Visual Fields

#### `color`

Color picker.

```json
{
  "key": "ACCENT_COLOR",
  "type": "color",
  "label": "Accent Color",
  "default": "#3B82F6"
}
```

---

#### `slider`

Range slider.

```json
{
  "key": "VOLUME",
  "type": "slider",
  "label": "Volume",
  "default": 75,
  "options": {
    "min": 0,
    "max": 100,
    "step": 5,
    "unit": "%"
  }
}
```

**Options**:
| Option | Type | Description |
|--------|------|-------------|
| `min` | number | Minimum value |
| `max` | number | Maximum value |
| `step` | number | Step increment |
| `unit` | string | Unit label |
| `showValue` | boolean | Show current value (default: true) |

---

#### `range`

Dual-handle range selector.

```json
{
  "key": "PRICE_RANGE",
  "type": "range",
  "label": "Price Range",
  "options": {
    "min": 0,
    "max": 1000,
    "step": 10,
    "unit": "$"
  },
  "default": {"min": 100, "max": 500}
}
```

---

#### `icon`

Icon picker.

```json
{
  "key": "MENU_ICON",
  "type": "icon",
  "label": "Menu Icon",
  "default": "🔔",
  "options": {
    "type": "emoji"
  }
}
```

**Options**:
| Option | Type | Description |
|--------|------|-------------|
| `type` | string | `"emoji"` or `"material"` |

---

### Date & Time Fields

#### `date`

Date picker.

```json
{
  "key": "START_DATE",
  "type": "date",
  "label": "Start Date",
  "default": "today",
  "options": {
    "format": "YYYY-MM-DD"
  }
}
```

---

#### `time`

Time picker.

```json
{
  "key": "NOTIFY_TIME",
  "type": "time",
  "label": "Notification Time",
  "default": "09:00",
  "options": {
    "format": "24h"
  }
}
```

**Options**:
| Option | Type | Description |
|--------|------|-------------|
| `format` | string | `"12h"` or `"24h"` |

---

#### `datetime`

Combined date and time picker.

```json
{
  "key": "DEADLINE",
  "type": "datetime",
  "label": "Deadline"
}
```

---

#### `timerange`

Time range selector.

```json
{
  "key": "ACTIVE_HOURS",
  "type": "timerange",
  "label": "Active Hours",
  "default": {"start": "09:00", "end": "17:00"}
}
```

---

#### `duration`

Duration input.

```json
{
  "key": "TIMEOUT",
  "type": "duration",
  "label": "Timeout",
  "default": "5m",
  "options": {
    "units": ["s", "m", "h"],
    "min": "1s",
    "max": "1h"
  }
}
```

---

### Network Fields

#### `url`

URL input with validation.

```json
{
  "key": "API_ENDPOINT",
  "type": "url",
  "label": "API Endpoint",
  "placeholder": "https://api.example.com",
  "options": {
    "protocols": ["http", "https"]
  }
}
```

---

#### `email`

Email input with validation.

```json
{
  "key": "ADMIN_EMAIL",
  "type": "email",
  "label": "Admin Email",
  "placeholder": "admin@example.com"
}
```

---

#### `phone`

Phone number input.

```json
{
  "key": "ALERT_PHONE",
  "type": "phone",
  "label": "Alert Phone Number"
}
```

---

#### `port`

Port number input (1-65535).

```json
{
  "key": "SERVER_PORT",
  "type": "port",
  "label": "Server Port",
  "default": 8080
}
```

---

### Layout Fields

#### `group`

Group related fields together.

```json
{
  "type": "group",
  "label": "Authentication",
  "options": {
    "collapsible": true,
    "collapsed": false
  },
  "settings": [
    {"key": "USERNAME", "type": "text", "label": "Username"},
    {"key": "PASSWORD", "type": "password", "label": "Password"}
  ]
}
```

---

#### `accordion`

Collapsible sections.

```json
{
  "type": "accordion",
  "sections": [
    {
      "label": "Basic Settings",
      "settings": [...]
    },
    {
      "label": "Advanced Settings",
      "settings": [...]
    }
  ]
}
```

---

#### `tabs`

Tabbed interface.

```json
{
  "type": "tabs",
  "tabs": [
    {"label": "General", "settings": [...]},
    {"label": "Advanced", "settings": [...]},
    {"label": "About", "settings": [...]}
  ]
}
```

---

#### `separator`

Visual separator line.

```json
{
  "type": "separator",
  "label": "Optional Section Label"
}
```

---

#### `info`

Informational text (non-editable).

```json
{
  "type": "info",
  "options": {
    "text": "This plugin requires an API key from example.com",
    "variant": "info"
  }
}
```

**Variants**: `info`, `warning`, `error`, `success`

---

## Grid Layout System

Crossbar uses a 1-100 grid system for field layout, where the width represents the percentage of the row.

### Why 1-100?

More intuitive than traditional 12-column grids:
- `width: 50` = 50% of the row (half width)
- `width: 33` = 33% of the row (one third)
- `width: 75` = 75% of the row (three quarters)

### Layout Rules

1. Fields are placed on the same row while `sum(widths) ≤ 100`
2. If `sum > 100`, a new row starts
3. If `sum < 100` on a row, fields expand proportionally

### Examples

**Two equal columns**:
```json
[
  {"key": "FIRST_NAME", "type": "text", "width": 50},
  {"key": "LAST_NAME", "type": "text", "width": 50}
]
```

**Three columns**:
```json
[
  {"key": "CITY", "type": "text", "width": 33},
  {"key": "STATE", "type": "text", "width": 33},
  {"key": "ZIP", "type": "text", "width": 34}
]
```

**Mixed widths**:
```json
[
  {"key": "EMAIL", "type": "email", "width": 70},
  {"key": "AGE", "type": "number", "width": 30}
]
```

**Full width (default)**:
```json
[
  {"key": "DESCRIPTION", "type": "textarea"}
]
```

### Complex Layout

```json
{
  "settings": [
    {"key": "NAME", "type": "text", "width": 100, "label": "Full Name"},
    {"key": "EMAIL", "type": "email", "width": 60, "label": "Email"},
    {"key": "PHONE", "type": "phone", "width": 40, "label": "Phone"},
    {"key": "ADDRESS", "type": "text", "width": 100, "label": "Address"},
    {"key": "CITY", "type": "text", "width": 40, "label": "City"},
    {"key": "STATE", "type": "select", "width": 30, "label": "State"},
    {"key": "ZIP", "type": "text", "width": 30, "label": "ZIP Code"}
  ]
}
```

This produces:
```
┌────────────────────────────────────────────┐
│ Full Name                                  │
├──────────────────────────┬─────────────────┤
│ Email                    │ Phone           │
├────────────────────────────────────────────┤
│ Address                                    │
├────────────────┬───────────┬───────────────┤
│ City           │ State     │ ZIP Code      │
└────────────────┴───────────┴───────────────┘
```

---

## Validation Rules

### Built-in Validation

| Rule | Type | Description |
|------|------|-------------|
| `required` | boolean | Field must have a value |
| `minLength` | number | Minimum string length |
| `maxLength` | number | Maximum string length |
| `min` | number | Minimum numeric value |
| `max` | number | Maximum numeric value |
| `pattern` | string | Regex pattern |

### Custom Validation

```json
{
  "key": "API_KEY",
  "type": "text",
  "required": true,
  "options": {
    "pattern": "^[A-Za-z0-9]{32}$",
    "errorMessage": "API key must be 32 alphanumeric characters"
  }
}
```

---

## Examples

### Weather Plugin

```json
{
  "name": "Weather Plugin",
  "version": "1.0.0",
  "description": "Shows current weather for your location",
  "author": "Crossbar Team",
  "icon": "🌤️",
  "settings": [
    {
      "key": "API_KEY",
      "type": "password",
      "label": "OpenWeather API Key",
      "required": true,
      "help": "Get your free API key at openweathermap.org"
    },
    {
      "key": "CITY",
      "type": "text",
      "label": "City",
      "default": "London",
      "placeholder": "Enter city name",
      "width": 70
    },
    {
      "key": "UNITS",
      "type": "select",
      "label": "Units",
      "default": "metric",
      "width": 30,
      "options": {
        "choices": [
          {"value": "metric", "label": "Celsius"},
          {"value": "imperial", "label": "Fahrenheit"}
        ]
      }
    },
    {
      "key": "SHOW_HUMIDITY",
      "type": "checkbox",
      "label": "Show Humidity",
      "default": true,
      "width": 50
    },
    {
      "key": "SHOW_WIND",
      "type": "checkbox",
      "label": "Show Wind Speed",
      "default": false,
      "width": 50
    }
  ]
}
```

### System Monitor Plugin

```json
{
  "name": "System Monitor",
  "version": "2.0.0",
  "description": "Monitor system resources",
  "settings": [
    {
      "type": "group",
      "label": "Display Options",
      "settings": [
        {
          "key": "SHOW_CPU",
          "type": "switch",
          "label": "Show CPU Usage",
          "default": true,
          "width": 33
        },
        {
          "key": "SHOW_MEMORY",
          "type": "switch",
          "label": "Show Memory",
          "default": true,
          "width": 33
        },
        {
          "key": "SHOW_DISK",
          "type": "switch",
          "label": "Show Disk",
          "default": false,
          "width": 34
        }
      ]
    },
    {
      "type": "separator"
    },
    {
      "key": "WARN_THRESHOLD",
      "type": "slider",
      "label": "Warning Threshold",
      "default": 70,
      "options": {
        "min": 50,
        "max": 95,
        "step": 5,
        "unit": "%"
      }
    },
    {
      "key": "CRITICAL_THRESHOLD",
      "type": "slider",
      "label": "Critical Threshold",
      "default": 90,
      "options": {
        "min": 60,
        "max": 99,
        "step": 1,
        "unit": "%"
      }
    },
    {
      "type": "group",
      "label": "Notifications",
      "options": {"collapsible": true, "collapsed": true},
      "settings": [
        {
          "key": "NOTIFY_ENABLED",
          "type": "switch",
          "label": "Enable Notifications",
          "default": true
        },
        {
          "key": "NOTIFY_SOUND",
          "type": "select",
          "label": "Sound",
          "default": "default",
          "options": {
            "choices": ["default", "alert", "chime", "none"]
          }
        }
      ]
    }
  ]
}
```

### GitHub Notifications Plugin

```json
{
  "name": "GitHub Notifications",
  "version": "1.0.0",
  "description": "Shows unread GitHub notifications",
  "config_required": "required",
  "settings": [
    {
      "type": "info",
      "options": {
        "text": "Create a personal access token at github.com/settings/tokens",
        "variant": "info"
      }
    },
    {
      "key": "GITHUB_TOKEN",
      "type": "password",
      "label": "Personal Access Token",
      "required": true
    },
    {
      "key": "FILTER_REPOS",
      "type": "tags",
      "label": "Filter Repositories",
      "help": "Only show notifications from these repos (leave empty for all)",
      "options": {
        "suggestions": ["owner/repo"]
      }
    },
    {
      "key": "TYPES",
      "type": "multiselect",
      "label": "Notification Types",
      "default": ["issue", "pr", "release"],
      "options": {
        "choices": [
          {"value": "issue", "label": "Issues"},
          {"value": "pr", "label": "Pull Requests"},
          {"value": "release", "label": "Releases"},
          {"value": "discussion", "label": "Discussions"}
        ]
      }
    }
  ]
}
```

---

## Best Practices

1. **Group related settings** using `group` or `tabs`
2. **Provide sensible defaults** for optional settings
3. **Use help text** to explain complex settings
4. **Use appropriate field types** (e.g., `password` for secrets)
5. **Validate input** with `required`, `min`, `max`, `pattern`
6. **Use the grid system** for better layout on different screen sizes
7. **Keep it simple** - only expose necessary settings

---

## Further Reading

- [Plugin Development Guide](plugin-development.md)
- [API Reference](api-reference.md)
- [README](../README.md)
