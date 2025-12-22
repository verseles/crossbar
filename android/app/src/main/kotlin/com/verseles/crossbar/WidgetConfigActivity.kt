package com.verseles.crossbar

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.content.SharedPreferences
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Configuration activity for Crossbar widgets.
 * Launches when user adds a widget to home screen.
 * Shows plugin selection dialog via Flutter deep link.
 *
 * Uses standard launchMode to ensure a fresh FlutterEngine for each config.
 * This avoids the alternating success/failure pattern caused by singleInstance.
 */
class WidgetConfigActivity : FlutterActivity() {

    companion object {
        private const val TAG = "WidgetConfigActivity"
        private const val CHANNEL = "com.verseles.crossbar/widget_config"
        private const val PREFS_NAME = "HomeWidgetPreferences"
    }

    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID
    private var widgetSize = "small"

    override fun onCreate(savedInstanceState: Bundle?) {
        // Get widget ID before super.onCreate
        appWidgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID

        super.onCreate(savedInstanceState)

        // Set result to CANCELED in case user backs out
        val cancelIntent = Intent().apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        }
        setResult(RESULT_CANCELED, cancelIntent)

        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            android.util.Log.e(TAG, "Invalid widget ID, finishing")
            finish()
            return
        }

        // Determine widget size using AppWidgetManager
        widgetSize = determineWidgetSize()

        android.util.Log.d(TAG, "Configuring widget $appWidgetId, size: $widgetSize")
    }
    
    private fun determineWidgetSize(): String {
        // Use AppWidgetManager to get the provider info for this widget ID
        // This correctly identifies which widget class (Small/Medium/Large) was added
        val appWidgetManager = AppWidgetManager.getInstance(this)
        val providerInfo = appWidgetManager.getAppWidgetInfo(appWidgetId)

        if (providerInfo != null) {
            val providerClassName = providerInfo.provider.className
            android.util.Log.d(TAG, "Widget provider class: $providerClassName")

            return when {
                providerClassName.contains("Large") -> "large"
                providerClassName.contains("Medium") -> "medium"
                else -> "small"
            }
        }

        // Fallback: Check layout dimensions from provider info
        // Large = 2x2, Medium = 2x1, Small = 1x1
        android.util.Log.w(TAG, "Could not get provider info for widget $appWidgetId, defaulting to small")
        return "small"
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getWidgetConfigParams" -> {
                    result.success(mapOf(
                        "widgetId" to appWidgetId,
                        "size" to widgetSize
                    ))
                }
                "saveWidgetConfig" -> {
                    val widgetId = call.argument<Int>("widgetId") ?: appWidgetId
                    val pluginIds = call.argument<List<String>>("pluginIds") ?: emptyList()

                    saveWidgetConfig(widgetId, pluginIds)

                    // Update the widget immediately
                    updateWidget()

                    // Set success result
                    val resultValue = Intent().apply {
                        putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                    }
                    setResult(RESULT_OK, resultValue)

                    android.util.Log.d(TAG, "Widget $appWidgetId configured with plugins: $pluginIds")

                    result.success(true)
                    finish()
                }
                "cancelWidgetConfig" -> {
                    val cancelIntent = Intent().apply {
                        putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                    }
                    setResult(RESULT_CANCELED, cancelIntent)
                    android.util.Log.d(TAG, "Widget $appWidgetId configuration cancelled")
                    result.success(true)
                    finish()
                }
                "getAvailablePlugins" -> {
                    // Get stored plugin data from SharedPreferences
                    val prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
                    val pluginIdsJson = prefs.getString("plugin_ids", null)
                    result.success(pluginIdsJson)
                }
                else -> result.notImplemented()
            }
        }
    }
    
    private fun saveWidgetConfig(widgetId: Int, pluginIds: List<String>) {
        val prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
        val editor = prefs.edit()
        
        // Save per-widget config
        val jsonArray = org.json.JSONArray(pluginIds)
        editor.putString("widget_${widgetId}_plugins", jsonArray.toString())
        editor.apply()
        
        android.util.Log.d(TAG, "Saved config for widget $widgetId: $pluginIds")
    }
    
    private fun updateWidget() {
        val appWidgetManager = AppWidgetManager.getInstance(this)
        
        // Determine which widget class to use based on size
        val widgetProvider = when (widgetSize) {
            "large" -> CrossbarWidgetLarge::class.java
            "medium" -> CrossbarWidgetMedium::class.java
            else -> CrossbarWidgetSmall::class.java
        }
        
        // Trigger widget update
        val intent = Intent(this, widgetProvider).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(appWidgetId))
        }
        sendBroadcast(intent)
    }
    
    override fun getInitialRoute(): String {
        return "/widget/config?id=$appWidgetId&size=$widgetSize"
    }
}
