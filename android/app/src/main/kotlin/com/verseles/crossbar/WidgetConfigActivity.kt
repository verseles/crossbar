package com.verseles.crossbar

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import es.antonborri.home_widget.HomeWidgetPlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Configuration activity for Crossbar widgets.
 * Launches when user adds a widget to home screen.
 * Shows plugin selection dialog via Flutter deep link.
 *
 * CRITICAL: Each configuration MUST use a fresh FlutterEngine to avoid
 * the alternating success/failure pattern. This is achieved by:
 * 1. getCachedEngineId() returning null (no engine caching)
 * 2. shouldDestroyEngineWithHost() returning true (destroy engine on finish)
 */
class WidgetConfigActivity : FlutterActivity() {

    companion object {
        private const val TAG = "WidgetConfigActivity"
        private const val CHANNEL = "com.verseles.crossbar/widget_config"
    }

    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID
    private var widgetSize = "small"

    // CRITICAL: Never use a cached engine - always create fresh
    override fun getCachedEngineId(): String? = null

    // CRITICAL: Always destroy engine when activity finishes
    override fun shouldDestroyEngineWithHost(): Boolean = true

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
            WidgetLogStore.append(
                this,
                "ERROR",
                TAG,
                "Invalid widget ID",
                appWidgetId,
            )
            finish()
            return
        }

        // Determine widget size using AppWidgetManager
        widgetSize = determineWidgetSize()

        android.util.Log.d(TAG, "Configuring widget $appWidgetId, size: $widgetSize")
        WidgetLogStore.append(
            this,
            "INFO",
            TAG,
            "Config started",
            appWidgetId,
            "size=$widgetSize",
        )
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
                    result.success(true)
                }
                "completeWidgetConfig" -> {
                    val pluginIds = call.argument<List<String>>("pluginIds") ?: emptyList()

                    // Update the widget after Flutter primes the data
                    updateWidget()

                    // Set success result
                    val resultValue = Intent().apply {
                        putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                    }
                    setResult(RESULT_OK, resultValue)

                    android.util.Log.d(TAG, "Widget $appWidgetId configuration completed")
                    WidgetLogStore.append(
                        this,
                        "INFO",
                        TAG,
                        "Config completed",
                        appWidgetId,
                        "plugins=${pluginIds.joinToString(",")}",
                    )

                    result.success(true)
                    finish()
                }
                "cancelWidgetConfig" -> {
                    val cancelIntent = Intent().apply {
                        putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                    }
                    setResult(RESULT_CANCELED, cancelIntent)
                    android.util.Log.d(TAG, "Widget $appWidgetId configuration cancelled")
                    WidgetLogStore.append(
                        this,
                        "INFO",
                        TAG,
                        "Config cancelled",
                        appWidgetId,
                    )
                    result.success(true)
                    finish()
                }
                "getAvailablePlugins" -> {
                    // Get stored plugin data from HomeWidget SharedPreferences
                    val prefs = HomeWidgetPlugin.getData(this)
                    val pluginIdsJson = prefs.getString("plugin_ids", null)
                    result.success(pluginIdsJson)
                }
                else -> result.notImplemented()
            }
        }
    }
    
    private fun saveWidgetConfig(widgetId: Int, pluginIds: List<String>) {
        val prefs = HomeWidgetPlugin.getData(this)
        val editor = prefs.edit()
        
        // Save per-widget config
        val jsonArray = org.json.JSONArray(pluginIds)
        editor.putString("widget_${widgetId}_plugins", jsonArray.toString())
        val committed = editor.commit()
        if (!committed) {
            android.util.Log.w(TAG, "Failed to commit config for widget $widgetId")
            WidgetLogStore.append(
                this,
                "WARN",
                TAG,
                "Commit failed",
                widgetId,
            )
        }

        android.util.Log.d(TAG, "Saved config for widget $widgetId: $pluginIds")
        WidgetLogStore.append(
            this,
            "INFO",
            TAG,
            "Config saved",
            widgetId,
            "plugins=${pluginIds.joinToString(",")}",
        )
    }
    
    private fun updateWidget() {
        val appWidgetManager = AppWidgetManager.getInstance(this)
        
        // Determine which widget class to use based on size
        val widgetProvider = when (widgetSize) {
            "large" -> CrossbarWidgetLarge::class.java
            "medium" -> CrossbarWidgetMedium::class.java
            else -> CrossbarWidgetSmall::class.java
        }

        WidgetLogStore.append(
            this,
            "INFO",
            TAG,
            "Trigger update",
            appWidgetId,
            "provider=${widgetProvider.simpleName}",
        )
        
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
