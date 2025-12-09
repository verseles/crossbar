package com.verseles.crossbar

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.net.Uri
import android.os.Bundle

/**
 * Configuration Activity for Crossbar widgets.
 * 
 * This activity launches when a widget is added to the home screen,
 * allowing the user to select which plugin(s) to display.
 * 
 * It opens the Flutter app with a deep link to the widget configuration screen,
 * passing the widget ID so the user can configure that specific widget instance.
 */
class WidgetConfigActivity : Activity() {

    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID

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
            finish()
            return
        }

        // Get widget size from the class that launched this
        val widgetSize = intent?.getStringExtra("widget_size") ?: "medium"

        // Launch Flutter app with deep link to configuration screen
        val configIntent = Intent(this, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = Uri.parse("crossbar://widget-config/$appWidgetId?size=$widgetSize")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            putExtra("widget_size", widgetSize)
        }
        
        startActivityForResult(configIntent, REQUEST_CONFIGURE_WIDGET)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (requestCode == REQUEST_CONFIGURE_WIDGET) {
            if (resultCode == RESULT_OK) {
                // Configuration complete, widget should be added
                val resultValue = Intent().apply {
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                }
                setResult(RESULT_OK, resultValue)
            }
            finish()
        }
    }

    override fun onResume() {
        super.onResume()
        // If returning from Flutter without explicit result, check if widget was configured
        // by seeing if SharedPreferences has data for this widget
        val widgetData = es.antonborri.home_widget.HomeWidgetPlugin.getData(this)
        val configuredPlugins = widgetData.getString("widget_${appWidgetId}_plugins", null)
        
        if (configuredPlugins != null) {
            // Widget was configured, update it and return success
            val appWidgetManager = AppWidgetManager.getInstance(this)
            
            // Trigger widget update
            val updateIntent = Intent(AppWidgetManager.ACTION_APPWIDGET_UPDATE).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(appWidgetId))
            }
            sendBroadcast(updateIntent)

            val resultValue = Intent().apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            }
            setResult(RESULT_OK, resultValue)
            finish()
        }
    }

    companion object {
        private const val REQUEST_CONFIGURE_WIDGET = 1001
    }
}
