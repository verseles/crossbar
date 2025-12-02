## Flutter specific rules
## https://developer.android.com/build/shrink-code

-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.**  { *; }

# Keep the main application class
-keep class com.example.crossbar.** { *; }

# Keep plugin classes
-keep class * extends io.flutter.plugin.FlutterPlugin { *; }
-keep class * implements io.flutter.plugin.FlutterPlugin { *; }

# Keep GeneratedPluginRegistrant
-keep class * {
    public static void registerWith(io.flutter.embedding.engine.FlutterEngine);
}

# Keep MethodChannels and EventChannels
-keep class * extends io.flutter.plugin.common.MethodChannel { *; }
-keep class * extends io.flutter.plugin.common.EventChannel { *; }
