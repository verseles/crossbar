# Android Widget Setup Guide

This document describes the Crossbar home screen widget implementation on Android.

## Overview

Crossbar uses Android's `AppWidgetProvider` along with the `home_widget` Flutter package to display plugin data on the home screen. The implementation supports three widget sizes:

- **Small (1x1)**: Icon + Value
- **Medium (2x1)**: Icon + Title + Value + Refresh
- **Large (2x2+)**: Multiple plugins list

## Architecture

```
┌─────────────────┐     ┌─────────────────┐
│  Flutter App    │────▶│ SharedPreferences│
│  (WidgetService)│     │  (home_widget)   │
└─────────────────┘     └────────┬─────────┘
                                 │
                                 ▼
                    ┌──────────────────────┐
                    │ CrossbarWidgetProvider │
                    │      (Kotlin)          │
                    └──────────────────────┘
                                 │
                                 ▼
                    ┌──────────────────────┐
                    │     RemoteViews      │
                    │   (XML Layouts)      │
                    └──────────────────────┘
```

## File Structure

```
android/app/src/main/
├── kotlin/com/verseles/crossbar/
│   ├── MainActivity.kt
│   └── CrossbarWidgetProvider.kt    # Widget logic
├── res/
│   ├── layout/
│   │   ├── crossbar_widget_small.xml   # 1x1 layout
│   │   ├── crossbar_widget_medium.xml  # 2x1 layout
│   │   └── crossbar_widget_large.xml   # 2x2+ layout
│   ├── drawable/
│   │   ├── widget_background.xml       # Light theme
│   │   └── widget_background_dark.xml  # Dark theme
│   ├── xml/
│   │   └── crossbar_widget_info.xml    # Widget metadata
│   └── values/
│       └── strings.xml                 # Widget strings
└── AndroidManifest.xml                  # Receiver registration
```

## How It Works

### 1. Data Flow

1. **Flutter SchedulerService** runs plugins periodically
2. **WidgetService.updateWidget()** saves data via `home_widget`
3. `home_widget` stores data in **SharedPreferences**
4. **CrossbarWidgetProvider.onUpdate()** reads from SharedPreferences
5. Data is mapped to **RemoteViews** and displayed on home screen

### 2. Widget Provider

The `CrossbarWidgetProvider` extends `HomeWidgetProvider` from the home_widget package:

```kotlin
class CrossbarWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences  // Data from Flutter
    ) {
        // Read plugin data and update RemoteViews
    }
}
```

### 3. Layout Selection

The widget automatically selects the appropriate layout based on size:

| Dimensions                 | Layout                       |
| -------------------------- | ---------------------------- |
| < 110dp wide               | `crossbar_widget_small.xml`  |
| ≥ 110dp wide               | `crossbar_widget_medium.xml` |
| ≥ 180dp wide, ≥ 100dp tall | `crossbar_widget_large.xml`  |

### 4. Data Format

The Flutter app saves data in JSON format:

```json
// Key: "plugin_ids"
["cpu.10s.sh", "memory.10s.sh"]

// Key: "plugin_cpu.10s.sh"
{
    "pluginId": "cpu.10s.sh",
    "text": "45%",
    "icon": "⚡",
    "color": "ff5733",
    "tooltip": "Current CPU usage"
}
```

## Adding the Widget

1. Long-press on Android home screen
2. Select "Widgets"
3. Find "Crossbar Plugin"
4. Drag to home screen
5. Resize as needed (supports horizontal and vertical resize)

## Refresh Behavior

- **Automatic**: Every 30 minutes (configurable in `crossbar_widget_info.xml`)
- **On Plugin Run**: When SchedulerService executes a plugin
- **Manual**: Tap the refresh icon on medium/large widgets

## Click Actions

- **Widget Container**: Opens the Crossbar app
- **Refresh Button**: Triggers widget update

## Customization

### Changing Update Interval

In `crossbar_widget_info.xml`:

```xml
android:updatePeriodMillis="1800000"  <!-- 30 minutes -->
```

Note: Android limits minimum to 30 minutes for battery optimization.

### Adding Themes

The widget uses `@drawable/widget_background` for the container.
To support dark theme, you can:

1. Create `res/drawable-night/widget_background.xml` with dark colors
2. Or use `AppCompatDelegate` to detect theme in the Provider

## Testing

### Using ADB

```bash
# List available widgets
adb shell appwidget list

# Update all Crossbar widgets
adb shell am broadcast -a android.appwidget.action.APPWIDGET_UPDATE \
  --es appwidget_provider com.verseles.crossbar.CrossbarWidgetProvider

# View widget logs
adb logcat | grep CrossbarWidget
```

### Using Flutter

```dart
// Request widget pin (adds to home screen)
await WidgetService().requestWidgetPin('cpu.10s.sh');

// Force update
await WidgetService().updateWidget(pluginId, output);
```

## Troubleshooting

### Widget shows "No data"

- Ensure the Flutter app has run at least once
- Check that plugins have executed successfully
- Verify SharedPreferences contains `plugin_ids` key

### Widget doesn't update

- Check logcat for errors: `adb logcat | grep Crossbar`
- Ensure receiver is registered in AndroidManifest.xml
- Try removing and re-adding the widget

### Build errors

- Sync Gradle: `./gradlew clean build`
- Ensure `home_widget` package is properly configured
- Check that Kotlin version matches (1.9.0+)
