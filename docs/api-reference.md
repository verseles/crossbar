# Crossbar CLI API Reference

Complete documentation for all Crossbar CLI commands.

**Version**: 1.0.0
**Last Updated**: December 2025

## Table of Contents

1. [Global Options](#global-options)
2. [System Information](#system-information)
3. [Media Controls](#media-controls)
4. [Audio Controls](#audio-controls)
5. [Screen Controls](#screen-controls)
6. [Power Management](#power-management)
7. [Do Not Disturb](#do-not-disturb)
8. [Bluetooth](#bluetooth)
9. [VPN](#vpn)
10. [Network](#network)
11. [Environment](#environment)
12. [Files & Directories](#files--directories)
13. [Date & Time](#date--time)
14. [Clipboard](#clipboard)
15. [Utilities](#utilities)
16. [Plugin Management](#plugin-management)
17. [System Actions](#system-actions)
18. [Platform Compatibility](#platform-compatibility)

---

## Global Options

These options can be added to most commands:

| Option | Description |
|--------|-------------|
| `--json` | Output in JSON format |
| `--xml` | Output in XML format |
| `--version`, `-v` | Show version |
| `--help`, `-h` | Show help |

### Without Arguments

Running `crossbar` without arguments launches the GUI application.

```bash
crossbar           # Launch GUI
crossbar --cpu     # CLI mode
```

---

## System Information

### `--cpu`

Get CPU usage percentage.

```bash
crossbar --cpu
# Output: 23.5%

crossbar --cpu --json
# Output: {"cpu":23.5}

crossbar --cpu --xml
# Output:
# <?xml version="1.0" encoding="UTF-8"?>
# <crossbar>
#   <cpu>23.5</cpu>
# </crossbar>
```

**Platforms**: Linux, macOS, Windows

---

### `--memory`

Get RAM usage (used/total).

```bash
crossbar --memory
# Output: 8.2 GB / 16.0 GB

crossbar --memory --json
# Output: {"used":8.2,"total":16.0,"unit":"GB"}
```

**Platforms**: Linux, macOS, Windows

---

### `--battery`

Get battery level and charging status.

```bash
crossbar --battery
# Output: 85% ⚡

crossbar --battery --json
# Output: {"level":85,"charging":true}
```

**Platforms**: Linux, macOS, Windows (laptops only)

---

### `--uptime`

Get system uptime.

```bash
crossbar --uptime
# Output: 3 days, 4:23:15
```

**Platforms**: Linux, macOS, Windows

---

### `--disk [path]`

Get disk usage for a path (default: root).

```bash
crossbar --disk
# Output: 120 GB / 500 GB (24%)

crossbar --disk /home
# Output: 80 GB / 500 GB (16%)
```

**Platforms**: Linux, macOS, Windows

---

### `--os`

Get operating system information.

```bash
crossbar --os
# Output: Linux 6.17.9-zen1-1-zen

crossbar --os --json
# Output: {"name":"Linux","version":"6.17.9-zen1-1-zen","platform":"linux"}
```

**Platforms**: Linux, macOS, Windows

---

### `--hostname`

Get system hostname.

```bash
crossbar --hostname
# Output: my-computer
```

**Platforms**: Linux, macOS, Windows

---

### `--username`

Get current username.

```bash
crossbar --username
# Output: helio
```

**Platforms**: Linux, macOS, Windows

---

### `--kernel`

Get kernel version.

```bash
crossbar --kernel
# Output: 6.17.9-zen1-1-zen
```

**Platforms**: Linux, macOS, Windows

---

### `--arch`

Get system architecture.

```bash
crossbar --arch
# Output: x86_64
```

**Platforms**: Linux, macOS, Windows

---

### `--screen-size`

Get screen resolution.

```bash
crossbar --screen-size
# Output: 1920x1080
```

**Platforms**: Linux (X11), macOS, Windows

---

### `--volume`

Get audio volume (legacy command, prefer `--audio-volume`).

```bash
crossbar --volume
# Output: 75
```

**Platforms**: Linux (PulseAudio), macOS

---

### `--brightness`

Get screen brightness (legacy command, prefer `--screen-brightness`).

```bash
crossbar --brightness
# Output: 80%
```

**Platforms**: Linux (backlight), macOS

---

## Media Controls

Control media playback on the system.

### `--media-play`

Resume media playback.

```bash
crossbar --media-play
# Output: Playing
```

**Platforms**: Linux (MPRIS), macOS (AppleScript), Windows (Media Keys)

---

### `--media-pause`

Pause media playback.

```bash
crossbar --media-pause
# Output: Paused
```

**Platforms**: Linux, macOS, Windows

---

### `--media-play-pause`

Toggle between play and pause.

```bash
crossbar --media-play-pause
# Output: Toggled
```

**Platforms**: Linux, macOS, Windows

---

### `--media-stop`

Stop media playback.

```bash
crossbar --media-stop
# Output: Stopped
```

**Platforms**: Linux, macOS, Windows

---

### `--media-next`

Skip to next track.

```bash
crossbar --media-next
# Output: Next track
```

**Platforms**: Linux, macOS, Windows

---

### `--media-prev`

Go to previous track.

```bash
crossbar --media-prev
# Output: Previous track
```

**Platforms**: Linux, macOS, Windows

---

### `--media-seek <offset>`

Seek forward or backward.

**Arguments**:
- `offset` - Time offset (e.g., `+30s`, `-10s`, `+1m`)

```bash
crossbar --media-seek +30s
# Output: Seeked +30s

crossbar --media-seek -15s
# Output: Seeked -15s
```

**Platforms**: Linux, macOS

---

### `--media-playing`

Get current track information.

```bash
crossbar --media-playing
# Output:
# Song Title - Artist Name
# Album: Album Name
# 1:23 / 3:45

crossbar --media-playing --json
# Output: {
#   "playing": true,
#   "title": "Song Title",
#   "artist": "Artist Name",
#   "album": "Album Name",
#   "position": "1:23",
#   "duration": "3:45"
# }

crossbar --media-playing --xml
# Output: XML format with media root element
```

**Platforms**: Linux, macOS, Windows

---

## Audio Controls

### `--audio-volume`

Get current volume (0-100).

```bash
crossbar --audio-volume
# Output: 75%

crossbar --audio-volume --json
# Output: {"volume":75}
```

**Platforms**: Linux (PulseAudio), macOS, Windows

---

### `--audio-volume-set <level>`

Set volume level (0-100).

**Arguments**:
- `level` - Volume level from 0 to 100

```bash
crossbar --audio-volume-set 50
# Output: Volume set to 50%

crossbar --audio-volume-set 0
# Output: Volume set to 0%
```

**Platforms**: Linux, macOS, Windows

---

### `--audio-mute`

Toggle mute state.

```bash
crossbar --audio-mute
# Output: Muted

crossbar --audio-mute  # Run again
# Output: Unmuted
```

**Platforms**: Linux, macOS, Windows

---

### `--audio-output`

Get current audio output device.

```bash
crossbar --audio-output
# Output: Built-in Speakers
```

**Platforms**: Linux, macOS, Windows

---

### `--audio-output --list`

List all audio output devices.

```bash
crossbar --audio-output --list
# Output:
# alsa_output.pci-0000_00_1f.3.analog-stereo: Built-in Audio
# bluez_sink.AA_BB_CC_DD_EE_FF: Bluetooth Headphones

crossbar --audio-output --list --json
# Output: [{"id":"alsa_output...","name":"Built-in Audio"},...]
```

**Platforms**: Linux, macOS, Windows

---

### `--audio-output-set <device>`

Set audio output device.

**Arguments**:
- `device` - Device ID (from `--audio-output --list`)

```bash
crossbar --audio-output-set alsa_output.pci-0000_00_1f.3.analog-stereo
# Output: Output set to alsa_output.pci-0000_00_1f.3.analog-stereo
```

**Platforms**: Linux, macOS, Windows

---

## Screen Controls

### `--screen-brightness`

Get screen brightness (0-100).

```bash
crossbar --screen-brightness
# Output: 80%

crossbar --screen-brightness --json
# Output: {"brightness":80}
```

**Platforms**: Linux (backlight), macOS

---

### `--screen-brightness-set <level>`

Set screen brightness (0-100).

**Arguments**:
- `level` - Brightness level from 0 to 100

```bash
crossbar --screen-brightness-set 70
# Output: Brightness set to 70%
```

**Platforms**: Linux, macOS

---

### `--screenshot [path]`

Take a screenshot.

**Arguments**:
- `path` - Optional output path (default: auto-generated in Pictures)

**Options**:
- `--clipboard` - Copy to clipboard instead of file

```bash
crossbar --screenshot
# Output: Screenshot saved to: /home/user/Pictures/screenshot-2025-12-01.png

crossbar --screenshot ~/Desktop/shot.png
# Output: Screenshot saved to: /home/user/Desktop/shot.png

crossbar --screenshot --clipboard
# Output: Screenshot copied to clipboard
```

**Platforms**: Linux (gnome-screenshot/scrot/spectacle), macOS (screencapture), Windows (PowerShell)

---

### `--wallpaper-get`

Get current wallpaper path.

```bash
crossbar --wallpaper-get
# Output: /home/user/Pictures/wallpaper.jpg
```

**Platforms**: Linux (GNOME/KDE), macOS, Windows

---

### `--wallpaper-set <path>`

Set desktop wallpaper.

**Arguments**:
- `path` - Path to image file

```bash
crossbar --wallpaper-set ~/Pictures/new-wallpaper.jpg
# Output: Wallpaper set to /home/user/Pictures/new-wallpaper.jpg
```

**Platforms**: Linux, macOS, Windows

---

## Power Management

### `--power-sleep`

Suspend the system.

```bash
crossbar --power-sleep
# Output: System going to sleep...
```

**Platforms**: Linux (systemctl), macOS (pmset), Windows (PowerShell)

---

### `--power-restart --confirm`

Restart the system. Requires `--confirm` flag for safety.

```bash
crossbar --power-restart --confirm
# Output: System restarting...

crossbar --power-restart  # Without --confirm
# Error: --power-restart requires --confirm flag for safety
```

**Platforms**: Linux, macOS, Windows

---

### `--power-shutdown --confirm`

Shutdown the system. Requires `--confirm` flag for safety.

```bash
crossbar --power-shutdown --confirm
# Output: System shutting down...

crossbar --power-shutdown  # Without --confirm
# Error: --power-shutdown requires --confirm flag for safety
```

**Platforms**: Linux, macOS, Windows

---

## Do Not Disturb

### `--dnd-status`

Get Do Not Disturb status.

```bash
crossbar --dnd-status
# Output: Do Not Disturb: OFF

crossbar --dnd-status --json
# Output: {"dnd":false}
```

**Platforms**: Linux (GNOME), macOS, Windows

---

### `--dnd-set <on|off>`

Set Do Not Disturb status.

**Arguments**:
- `on` - Enable DND
- `off` - Disable DND

```bash
crossbar --dnd-set on
# Output: DND set to on

crossbar --dnd-set off
# Output: DND set to off
```

**Platforms**: Linux, macOS, Windows

---

## Bluetooth

### `--bluetooth-status`

Get Bluetooth status.

```bash
crossbar --bluetooth-status
# Output: Bluetooth: on

crossbar --bluetooth-status --json
# Output: {"bluetooth":"on"}
```

Returns: `on`, `off`, or `unavailable`

**Platforms**: Linux (bluetoothctl), macOS, Windows

---

### `--bluetooth-on`

Enable Bluetooth.

```bash
crossbar --bluetooth-on
# Output: Bluetooth enabled
```

**Platforms**: Linux, macOS, Windows

---

### `--bluetooth-off`

Disable Bluetooth.

```bash
crossbar --bluetooth-off
# Output: Bluetooth disabled
```

**Platforms**: Linux, macOS, Windows

---

### `--bluetooth-devices`

List paired Bluetooth devices.

```bash
crossbar --bluetooth-devices
# Output:
# AA:BB:CC:DD:EE:FF: Bluetooth Headphones
# 11:22:33:44:55:66: Wireless Mouse

crossbar --bluetooth-devices --json
# Output: [
#   {"mac":"AA:BB:CC:DD:EE:FF","name":"Bluetooth Headphones"},
#   {"mac":"11:22:33:44:55:66","name":"Wireless Mouse"}
# ]
```

**Platforms**: Linux, macOS, Windows

---

## VPN

### `--vpn-status`

Get VPN connection status.

```bash
crossbar --vpn-status
# Output: VPN: Connected (WireGuard)

crossbar --vpn-status --json
# Output: {"connected":true,"name":"WireGuard","type":"wireguard"}

crossbar --vpn-status --xml
# Output: XML format with vpn root element
```

**Platforms**: Linux (nmcli/wg), macOS, Windows

---

## Network

### `--net-status`

Get network connection status.

```bash
crossbar --net-status
# Output: online
```

Returns: `online` or `offline`

**Platforms**: Linux, macOS, Windows

---

### `--net-ip`

Get local IP address.

```bash
crossbar --net-ip
# Output: 192.168.1.100
```

**Platforms**: Linux, macOS, Windows

---

### `--net-ip --public`

Get public IP address (requires internet).

```bash
crossbar --net-ip --public
# Output: 203.0.113.42
```

**Platforms**: Linux, macOS, Windows (requires network)

---

### `--net-ssid`

Get connected WiFi SSID.

```bash
crossbar --net-ssid
# Output: MyWiFiNetwork
```

**Platforms**: Linux, macOS, Windows

---

### `--net-ping <host>`

Ping a host and get latency.

**Arguments**:
- `host` - Hostname or IP address to ping

```bash
crossbar --net-ping google.com
# Output: 15.2 ms

crossbar --net-ping 8.8.8.8
# Output: 12.8 ms
```

**Platforms**: Linux, macOS, Windows

---

### `--wifi-on`

Enable WiFi.

```bash
crossbar --wifi-on
# Output: WiFi enabled
```

**Platforms**: Linux (nmcli), macOS, Windows

---

### `--wifi-off`

Disable WiFi.

```bash
crossbar --wifi-off
# Output: WiFi disabled
```

**Platforms**: Linux, macOS, Windows

---

### `--web <url>`

Make HTTP request.

**Arguments**:
- `url` - URL to request

**Options**:
- `--method <METHOD>` - HTTP method (GET, POST, PUT, DELETE). Default: GET
- `--headers <JSON>` - JSON object of headers
- `--body <DATA>` - Request body
- `--timeout <DURATION>` - Timeout (e.g., `5s`, `1m`, `1h`). Default: 30s

```bash
# Simple GET
crossbar --web https://api.github.com/users/octocat

# POST with body
crossbar --web https://api.example.com/data --method POST --body '{"key":"value"}'

# With headers
crossbar --web https://api.example.com --headers '{"Authorization":"Bearer token"}'

# With timeout
crossbar --web https://slow-api.com --timeout 2m
```

**Platforms**: Linux, macOS, Windows

---

## Environment

### `--home`

Get home directory.

```bash
crossbar --home
# Output: /home/helio
```

**Platforms**: Linux, macOS, Windows

---

### `--temp`

Get temp directory.

```bash
crossbar --temp
# Output: /tmp
```

**Platforms**: Linux, macOS, Windows

---

### `--env [name]`

Get environment variable(s).

**Arguments**:
- `name` - Optional variable name (all if omitted)

```bash
crossbar --env PATH
# Output: /usr/bin:/bin:/usr/local/bin

crossbar --env
# Output: (all environment variables)

crossbar --env --json
# Output: {"PATH":"/usr/bin:...", "HOME":"/home/user", ...}
```

**Platforms**: Linux, macOS, Windows

---

### `--locale`

Get system locale.

```bash
crossbar --locale
# Output: en_US.UTF-8
```

**Platforms**: Linux, macOS, Windows

---

### `--timezone`

Get timezone.

```bash
crossbar --timezone
# Output: BRT
```

**Platforms**: Linux, macOS, Windows

---

## Files & Directories

### `--file-exists <path>`

Check if file or directory exists.

**Arguments**:
- `path` - Path to check

```bash
crossbar --file-exists /etc/passwd
# Output: true

crossbar --file-exists /nonexistent
# Output: false

crossbar --file-exists /etc/passwd --json
# Output: {"exists":true,"path":"/etc/passwd"}
```

**Platforms**: Linux, macOS, Windows

---

### `--file-read <path>`

Read file contents.

**Arguments**:
- `path` - Path to file

```bash
crossbar --file-read /etc/hostname
# Output: my-computer
```

**Platforms**: Linux, macOS, Windows

---

### `--file-size <path>`

Get file size.

**Arguments**:
- `path` - Path to file

```bash
crossbar --file-size /etc/passwd
# Output: 2.34 KB

crossbar --file-size /etc/passwd --json
# Output: {"size":2396,"path":"/etc/passwd"}
```

**Platforms**: Linux, macOS, Windows

---

### `--dir-list [path]`

List directory contents.

**Arguments**:
- `path` - Directory path (default: current directory)

```bash
crossbar --dir-list
# Output:
# d Documents
# d Downloads
# - file.txt

crossbar --dir-list /home --json
# Output: [
#   {"name":"user","path":"/home/user","type":"directory","size":4096,...},
#   ...
# ]
```

**Platforms**: Linux, macOS, Windows

---

### `--exec <command>`

Execute shell command.

**Arguments**:
- `command` - Command to execute

```bash
crossbar --exec "ls -la"
# Output: (directory listing)

crossbar --exec "echo Hello World"
# Output: Hello World
```

**Platforms**: Linux (sh), macOS (sh), Windows (cmd)

---

## Date & Time

### `--time`

Get current time.

**Options**:
- `--fmt <12h|24h>` - Time format (default: 24h)

```bash
crossbar --time
# Output: 14:30

crossbar --time --fmt 12h
# Output: 02:30 PM
```

**Platforms**: Linux, macOS, Windows

---

### `--date`

Get current date.

**Options**:
- `--fmt <iso|us|eu|unix>` - Date format (default: iso)

```bash
crossbar --date
# Output: 2025-12-01

crossbar --date --fmt us
# Output: 12/1/2025

crossbar --date --fmt eu
# Output: 1/12/2025

crossbar --date --fmt unix
# Output: 1733011200
```

**Platforms**: Linux, macOS, Windows

---

### `--calendar`

Display current month calendar.

```bash
crossbar --calendar
# Output:
#    December 2025
# Su Mo Tu We Th Fr Sa
#     1  2  3  4  5  6
#  7  8  9 10 11 12 13
# 14 15 16 17 18 19 20
# 21 22 23 24 25 26 27
# 28 29 30 31
```

**Platforms**: Linux, macOS, Windows

---

### `--countdown <seconds>`

Start countdown timer.

**Arguments**:
- `seconds` - Number of seconds

```bash
crossbar --countdown 60
# Output: 1:00

crossbar --countdown 300 --json
# Output: {"remaining":300,"target":"2025-12-01T14:35:00.000"}
```

**Platforms**: Linux, macOS, Windows

---

## Clipboard

### `--clipboard`

Get clipboard content.

```bash
crossbar --clipboard
# Output: (clipboard contents)
```

**Platforms**: Linux (xclip), macOS (pbpaste), Windows (PowerShell)

---

### `--clipboard-set <text>`

Set clipboard content.

**Arguments**:
- `text` - Text to copy

```bash
crossbar --clipboard-set "Hello World"
# Output: Copied to clipboard
```

**Platforms**: Linux (xclip), macOS (pbcopy), Windows (PowerShell)

---

## Utilities

### `--hash <text>`

Hash text with specified algorithm.

**Arguments**:
- `text` - Text to hash

**Options**:
- `--algo <algorithm>` - Hash algorithm (default: sha256)
  - Supported: `md5`, `sha1`, `sha256`, `sha384`, `sha512`

```bash
crossbar --hash "Hello World"
# Output: a591a6d40bf420404a011733cfb7b190d62c65bf0bcda32b57b277d9ad9f146e

crossbar --hash "Hello World" --algo md5
# Output: b10a8db164e0754105b7a99be72e3fe5

crossbar --hash "Hello World" --algo sha1
# Output: 0a4d55a8d778e5022fab701977c5d840bbc486d0
```

**Platforms**: Linux, macOS, Windows

---

### `--uuid`

Generate UUID v4.

```bash
crossbar --uuid
# Output: 550e8400-e29b-41d4-a716-446655440000
```

**Platforms**: Linux, macOS, Windows

---

### `--random [min] [max]`

Generate random number.

**Arguments**:
- `min` - Minimum value (default: 0)
- `max` - Maximum value (default: 100)

```bash
crossbar --random
# Output: 42

crossbar --random 1 10
# Output: 7

crossbar --random 100 999
# Output: 547
```

**Platforms**: Linux, macOS, Windows

---

### `--base64-encode <text>`

Encode text to base64.

**Arguments**:
- `text` - Text to encode

```bash
crossbar --base64-encode "Hello World"
# Output: SGVsbG8gV29ybGQ=
```

**Platforms**: Linux, macOS, Windows

---

### `--base64-decode <text>`

Decode base64 text.

**Arguments**:
- `text` - Base64 text to decode

```bash
crossbar --base64-decode "SGVsbG8gV29ybGQ="
# Output: Hello World
```

**Platforms**: Linux, macOS, Windows

---

## Plugin Management

### `init`

Create a new plugin from template.

**Options**:
- `--lang <language>` - Plugin language (required)
  - Supported: `bash`, `python`, `node`, `dart`, `go`, `rust`
- `--type <type>` - Plugin type (default: custom)
  - Supported: `clock`, `monitor`, `status`, `api`, `custom`
- `--name <name>` - Plugin name (default: auto-generated)
- `--output <dir>` - Output directory (default: ~/.config/crossbar/plugins)

```bash
crossbar init --lang python --type monitor --name cpu-monitor
# Output:
# Plugin created: ~/.config/crossbar/plugins/python/cpu-monitor.10s.py
# Config file: ~/.config/crossbar/plugins/python/cpu-monitor.10s.py.config.json
#
# Next steps:
#   1. Edit the plugin file to add your logic
#   2. Customize the config file for settings
#   3. Test with: crossbar --exec "python3 ~/.config/crossbar/plugins/python/cpu-monitor.10s.py"

crossbar init --lang bash --type clock
# Output: Plugin created with 1s interval

crossbar init --lang go --type api --name weather
# Output: Plugin created with 5m interval
```

**Plugin Type Intervals**:
| Type | Interval |
|------|----------|
| clock | 1s |
| monitor | 10s |
| status | 30s |
| api | 5m |
| custom | 1m |

**Platforms**: Linux, macOS, Windows

---

### `install`

Install plugin from GitHub repository.

**Arguments**:
- `url` - GitHub repository URL

```bash
crossbar install https://github.com/user/my-crossbar-plugin
# Output:
# Installing plugin from: https://github.com/user/my-crossbar-plugin
# Plugin installed: ~/.config/crossbar/plugins/bash/my-plugin.30s.sh
```

**Requirements**:
- `git` must be installed
- Repository must contain valid plugin files

**Platforms**: Linux, macOS, Windows

---

## System Actions

### `--notify`

Send desktop notification.

**Arguments**:
- `title` - Notification title
- `message` - Notification message

**Options**:
- `--icon <icon>` - Icon path or name
- `--priority <level>` - Priority: `low`, `normal`, `critical`

```bash
crossbar --notify "Build Complete" "All tests passed!"
# Output: Notification sent

crossbar --notify "Warning" "Disk space low" --priority critical
# Output: Notification sent

crossbar --notify "Update" "New version available" --icon software-update
# Output: Notification sent
```

**Platforms**: Linux (notify-send), macOS (osascript), Windows (PowerShell)

---

### `--open-url <url>`

Open URL in default browser.

**Arguments**:
- `url` - URL to open

```bash
crossbar --open-url https://github.com
# Output: Opened: https://github.com
```

**Platforms**: Linux (xdg-open), macOS (open), Windows (start)

---

### `--open-file <path>`

Open file with default application.

**Arguments**:
- `path` - File path

```bash
crossbar --open-file ~/Documents/report.pdf
# Output: Opened: /home/user/Documents/report.pdf
```

**Platforms**: Linux, macOS, Windows

---

### `--open-app <name>`

Launch application by name.

**Arguments**:
- `name` - Application name

```bash
crossbar --open-app firefox
# Output: Launched: firefox

crossbar --open-app "Visual Studio Code"
# Output: Launched: Visual Studio Code
```

**Platforms**: Linux, macOS, Windows

---

### `--process-count`

Get number of running processes.

```bash
crossbar --process-count
# Output: 247
```

**Platforms**: Linux, macOS, Windows

---

## Platform Compatibility

| Command | Linux | macOS | Windows |
|---------|:-----:|:-----:|:-------:|
| **System Info** |
| `--cpu` | ✅ | ✅ | ✅ |
| `--memory` | ✅ | ✅ | ✅ |
| `--battery` | ✅ | ✅ | ✅ |
| `--uptime` | ✅ | ✅ | ✅ |
| `--disk` | ✅ | ✅ | ✅ |
| `--os` | ✅ | ✅ | ✅ |
| `--hostname` | ✅ | ✅ | ✅ |
| `--username` | ✅ | ✅ | ✅ |
| `--kernel` | ✅ | ✅ | ✅ |
| `--arch` | ✅ | ✅ | ✅ |
| `--screen-size` | ✅ (X11) | ✅ | ✅ |
| `--volume` | ✅ (PA) | ✅ | ⚠️ |
| `--brightness` | ✅ | ✅ | ❌ |
| **Media Controls** |
| `--media-*` | ✅ (MPRIS) | ✅ | ✅ |
| **Audio Controls** |
| `--audio-*` | ✅ (PA) | ✅ | ✅ |
| **Screen Controls** |
| `--screen-brightness` | ✅ | ✅ | ⚠️ |
| `--screenshot` | ✅ | ✅ | ✅ |
| `--wallpaper-*` | ✅ | ✅ | ✅ |
| **Power** |
| `--power-*` | ✅ | ✅ | ✅ |
| **DND** |
| `--dnd-*` | ✅ (GNOME) | ✅ | ⚠️ |
| **Bluetooth** |
| `--bluetooth-*` | ✅ | ✅ | ✅ |
| **VPN** |
| `--vpn-status` | ✅ | ✅ | ✅ |
| **Network** |
| `--net-*` | ✅ | ✅ | ✅ |
| `--wifi-*` | ✅ | ✅ | ✅ |
| `--web` | ✅ | ✅ | ✅ |
| **Environment** |
| All | ✅ | ✅ | ✅ |
| **Files** |
| All | ✅ | ✅ | ✅ |
| **Date/Time** |
| All | ✅ | ✅ | ✅ |
| **Clipboard** |
| `--clipboard` | ✅ (xclip) | ✅ | ✅ |
| `--clipboard-set` | ✅ (xclip) | ✅ | ✅ |
| **Utilities** |
| All | ✅ | ✅ | ✅ |
| **Plugin Mgmt** |
| `init` | ✅ | ✅ | ✅ |
| `install` | ✅ | ✅ | ✅ |
| **System Actions** |
| `--notify` | ✅ | ✅ | ✅ |
| `--open-*` | ✅ | ✅ | ✅ |
| `--process-count` | ✅ | ✅ | ✅ |

**Legend**:
- ✅ Full support
- ⚠️ Partial support / may require additional setup
- ❌ Not supported
- (PA) = PulseAudio required
- (MPRIS) = MPRIS D-Bus required
- (X11) = X11 required (Wayland support varies)
- (GNOME) = GNOME desktop required

---

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Error (invalid arguments, command failed, etc.) |

---

## Examples

### Daily Workflow

```bash
# Morning check
crossbar --battery
crossbar --net-status
crossbar --dnd-set off

# Development
crossbar --notify "Build Started" "Running tests..."
crossbar --exec "npm test"
crossbar --notify "Build Complete" "All tests passed!"

# Media control
crossbar --media-play-pause
crossbar --audio-volume-set 30

# End of day
crossbar --dnd-set on
crossbar --power-sleep
```

### Scripting

```bash
#!/bin/bash
# Battery warning script

LEVEL=$(crossbar --battery --json | jq '.level')

if [ "$LEVEL" -lt 20 ]; then
    crossbar --notify "Low Battery" "Battery at $LEVEL%" --priority critical
fi
```

### Plugin Development

```bash
# Create new plugin
crossbar init --lang python --type monitor --name disk-usage

# Test it
crossbar --exec "python3 ~/.config/crossbar/plugins/python/disk-usage.10s.py"

# Install community plugin
crossbar install https://github.com/example/crossbar-weather-plugin
```

---

**Total Commands**: ~75 commands across 17 categories

**See Also**:
- [Plugin Development Guide](plugin-development.md)
- [Configuration Schema](config-schema.md)
- [README](../README.md)
