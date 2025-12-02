package com.example.crossbar

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Add error handling for release mode
        Thread.setDefaultUncaughtExceptionHandler { thread, ex ->
            // Log to logcat
            android.util.Log.e("Crossbar", "Uncaught exception", ex)
        }
    }
}
