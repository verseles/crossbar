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
 * It opens the Flutter app and finishes itself. When the user returns,
 * we check if the widget was configured via SharedPreferences.
 */
class WidgetConfigActivity : Activity() {

    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID
    private var hasLaunchedFlutter = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Set result to CANCELED in case user backs out
        setResult(RESULT_CANCELED)

        // Get the widget ID from the intent
        appWidgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID

        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            android.util.Log.e("WidgetConfig", "Invalid widget ID, finishing")
            finish()
            return
        }

        android.util.Log.d("WidgetConfig", "Configuring widget ID: $appWidgetId")

        // Get widget size from the class that launched this
        val widgetSize = intent?.getStringExtra("widget_size") ?: "medium"

        // Launch Flutter app with widget config extras
        val configIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            putExtra("widget_size", widgetSize)
            putExtra("widget_config_mode", true)
        }
        
        hasLaunchedFlutter = true
        startActivity(configIntent)
    }

    override fun onResume() {
        super.onResume()
        
        // Only check for configuration after we've launched Flutter and returned
        if (!hasLaunchedFlutter) return
        
        android.util.Log.d("WidgetConfig", "onResume - checking if widget was configured")
        
        try {
            val widgetData = es.antonborri.home_widget.HomeWidgetPlugin.getData(this)
            val configuredPlugins = widgetData.getString("widget_${appWidgetId}_plugins", null)
            
            if (configuredPlugins != null) {
                android.util.Log.d("WidgetConfig", "Widget $appWidgetId configured with: $configuredPlugins")
                
                // Trigger widget update
                val updateIntent = Intent(AppWidgetManager.ACTION_APPWIDGET_UPDATE).apply {
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(appWidgetId))
                }
                sendBroadcast(updateIntent)

                val resultValue = Intent().apply {
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                }
                setResult(RESULT_OK, resultValue)
            } else {
                android.util.Log.d("WidgetConfig", "Widget $appWidgetId NOT configured, canceling")
            }
        } catch (e: Exception) {
            android.util.Log.e("WidgetConfig", "Error checking widget config", e)
        }
        
        finish()
    }
}
