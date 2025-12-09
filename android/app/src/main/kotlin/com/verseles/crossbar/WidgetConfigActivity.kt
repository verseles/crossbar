package com.verseles.crossbar

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle

/**
 * Configuration Activity for Crossbar widgets.
 * 
 * This activity launches when a widget is added to the home screen,
 * allowing the user to select which plugin(s) to display.
 * 
 * It opens the Flutter MainActivity with extras to trigger the configuration dialog,
 * then waits for the result and returns it to the launcher.
 */
class WidgetConfigActivity : Activity() {

    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Set result to CANCELED in case user backs out without configuration
        setResult(RESULT_CANCELED)

        // Get the widget ID from the intent
        appWidgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID

        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            android.util.Log.e(TAG, "Invalid widget ID received, finishing")
            finish()
            return
        }

        android.util.Log.d(TAG, "Starting config for widget ID: $appWidgetId")

        // Determine widget size based on componentName or caller info
        val widgetSize = determineWidgetSize()

        // Launch Flutter app with configuration mode extras
        val configIntent = Intent(this, MainActivity::class.java).apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            putExtra(EXTRA_WIDGET_CONFIG_MODE, true)
            putExtra(EXTRA_WIDGET_SIZE, widgetSize)
            // Use FLAG_ACTIVITY_FORWARD_RESULT would not work here since we need explicit control
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        
        startActivityForResult(configIntent, REQUEST_CONFIGURE_WIDGET)
    }

    private fun determineWidgetSize(): String {
        // Try to determine widget size from the calling component
        val callerComponent = callingActivity?.className ?: ""
        return when {
            callerComponent.contains("Small", ignoreCase = true) -> "small"
            callerComponent.contains("Large", ignoreCase = true) -> "large"
            callerComponent.contains("Medium", ignoreCase = true) -> "medium"
            else -> {
                // Fallback: try to get from intent
                intent?.getStringExtra(EXTRA_WIDGET_SIZE) ?: "medium"
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        android.util.Log.d(TAG, "onActivityResult: requestCode=$requestCode, resultCode=$resultCode")

        if (requestCode == REQUEST_CONFIGURE_WIDGET) {
            val resultIntent = Intent().apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            }

            if (resultCode == RESULT_OK) {
                android.util.Log.d(TAG, "Configuration complete for widget $appWidgetId")
                
                // Trigger widget update
                val updateIntent = Intent(AppWidgetManager.ACTION_APPWIDGET_UPDATE).apply {
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(appWidgetId))
                }
                sendBroadcast(updateIntent)
                
                setResult(RESULT_OK, resultIntent)
            } else {
                android.util.Log.d(TAG, "Configuration cancelled for widget $appWidgetId")
                setResult(RESULT_CANCELED, resultIntent)
            }
        }
        
        finish()
    }

    companion object {
        private const val TAG = "WidgetConfigActivity"
        private const val REQUEST_CONFIGURE_WIDGET = 1001
        
        const val EXTRA_WIDGET_CONFIG_MODE = "widget_config_mode"
        const val EXTRA_WIDGET_SIZE = "widget_size"
    }
}
