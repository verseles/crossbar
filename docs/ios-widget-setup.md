# iOS Widget Setup Guide

This document describes how to set up the Crossbar home screen widget on iOS using Xcode.

## Prerequisites

- macOS with Xcode 14+ installed
- iOS deployment target: 14.0+
- Apple Developer Account (for testing on physical devices)

## Step 1: Create Widget Extension Target

1. Open the iOS project in Xcode: `open ios/Runner.xcworkspace`
2. Go to **File → New → Target**
3. Select **Widget Extension**
4. Configure:
   - Product Name: `CrossbarWidget`
   - Team: Your team
   - Include Configuration Intent: **No** (we use StaticConfiguration)
5. Click **Finish**

## Step 2: Configure App Groups

Both the main app (Runner) and the widget extension need to share data via App Groups.

### For Runner target:

1. Select **Runner** target
2. Go to **Signing & Capabilities**
3. Click **+ Capability** → **App Groups**
4. Add group: `group.crossbar.widgets`

### For CrossbarWidget target:

1. Select **CrossbarWidget** target
2. Go to **Signing & Capabilities**
3. Click **+ Capability** → **App Groups**
4. Add the same group: `group.crossbar.widgets`

## Step 3: Replace Widget Code

1. Delete the auto-generated `CrossbarWidget.swift` in the widget target
2. Copy the content from `ios/CrossbarWidget/CrossbarWidget.swift` (this file) to the target

## Step 4: Update Info.plist

In the `CrossbarWidget/Info.plist`, ensure:

```xml
<key>NSWidgetKind</key>
<string>com.apple.HomeWidget</string>
```

## Step 5: Build and Run

1. Select the **Runner** scheme
2. Build and run on a device/simulator with iOS 14+
3. Long-press on home screen → Add Widget → Find "Crossbar Plugin"

## Troubleshooting

### Widget not showing data

- Ensure App Groups are configured correctly on both targets
- Check that the `appGroupId` in `CrossbarWidget.swift` matches (`group.crossbar.widgets`)
- Make sure the Flutter app has saved data at least once

### Widget not appearing in list

- Clean build folder: **Product → Clean Build Folder**
- Rebuild the project
- On simulator: Reset Content and Settings

### Data not updating

- The widget refreshes every 30 minutes by default
- To force update, remove and re-add the widget
- Or call `WidgetCenter.shared.reloadAllTimelines()` from the app

## Architecture

```
┌─────────────────┐     ┌─────────────────┐
│  Flutter App    │────▶│  UserDefaults   │
│  (Runner)       │     │  (App Group)    │
└─────────────────┘     └────────┬────────┘
                                 │
                                 ▼
                    ┌─────────────────────┐
                    │  CrossbarWidget     │
                    │  (Widget Extension) │
                    └─────────────────────┘
```

## Data Format

The Flutter app saves data in the following format:

```json
// Key: "plugin_ids"
["cpu.10s.sh", "memory.10s.sh", "battery.30s.sh"]

// Key: "plugin_cpu.10s.sh"
{
  "pluginId": "cpu.10s.sh",
  "text": "45%",
  "icon": "⚡",
  "color": "FF5733",
  "tooltip": "Current CPU usage"
}
```

The widget reads this data via `UserDefaults(suiteName: "group.crossbar.widgets")`.
