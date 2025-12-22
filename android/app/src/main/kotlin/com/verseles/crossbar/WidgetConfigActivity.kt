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
 * Uses singleInstance launchMode to avoid FlutterEngine conflicts
 * with the main app's FlutterActivity.
 */
class WidgetConfigActivity : FlutterActivity() {

    companion object {
        private const val TAG = "WidgetConfigActivity"
        private const val CHANNEL = "com.verseles.crossbar/widget_config"
        private const val PREFS_NAME = "HomeWidgetPreferences"
    }

    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID
    private var widgetSize = "small"
    private var isConfigurationComplete = false

    override fun onCreate(savedInstanceState: Bundle?) {
        // Get widget ID before super.onCreate to avoid race conditions
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

        // Determine widget size from caller class name
        widgetSize = determineWidgetSize()

        android.util.Log.d(TAG, "Configuring widget $appWidgetId, size: $widgetSize")
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Handle new intents if activity is reused
        val newWidgetId = intent.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID

        if (newWidgetId != AppWidgetManager.INVALID_APPWIDGET_ID) {
            appWidgetId = newWidgetId
            widgetSize = determineWidgetSize()
            android.util.Log.d(TAG, "Reconfiguring widget $appWidgetId, size: $widgetSize")
        }
    }
    
    private fun determineWidgetSize(): String {
        // Check the referrer or caller to determine widget size
        val callerClass = intent?.component?.className ?: ""
        return when {
            callerClass.contains("Large") -> "large"
            callerClass.contains("Medium") -> "medium"
            else -> "small"
        }
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

                    // Mark configuration as complete and return success result
                    isConfigurationComplete = true
                    val resultValue = Intent().apply {
                        putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                    }
                    setResult(RESULT_OK, resultValue)

                    android.util.Log.d(TAG, "Widget $appWidgetId configured successfully with plugins: $pluginIds")

                    result.success(true)

                    // Finish after saving
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

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        // Ensure RESULT_CANCELED is set with the widget ID before finishing
        if (!isConfigurationComplete) {
            val cancelIntent = Intent().apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            }
            setResult(RESULT_CANCELED, cancelIntent)
            android.util.Log.d(TAG, "Widget $appWidgetId configuration cancelled via back press")
        }
        super.onBackPressed()
    }

    override fun onDestroy() {
        // Log the final state
        android.util.Log.d(TAG, "WidgetConfigActivity destroyed. Configuration complete: $isConfigurationComplete")
        super.onDestroy()
    }
}
