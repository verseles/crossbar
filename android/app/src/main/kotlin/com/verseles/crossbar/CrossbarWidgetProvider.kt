package com.verseles.crossbar

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import org.json.JSONObject

/**
 * CrossbarWidgetProvider - Android Home Screen Widget
 * 
 * This provider handles the display of Crossbar plugin data on Android home screen widgets.
 * It reads data saved by the Flutter app via the home_widget package and displays it
 * using RemoteViews.
 * 
 * Supports three layout sizes:
 * - Small (1x1): Icon + Value only
 * - Medium (2x1): Icon + Title + Value + Refresh action
 * - Large (2x2+): Multiple plugins in a list
 */
class CrossbarWidgetProvider : HomeWidgetProvider() {

    companion object {
        private const val TAG = "CrossbarWidget"
        private const val ACTION_REFRESH = "com.verseles.crossbar.ACTION_REFRESH"
        private const val ACTION_OPEN_APP = "com.verseles.crossbar.ACTION_OPEN_APP"
        private const val EXTRA_PLUGIN_ID = "pluginId"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId, widgetData)
        }
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        widgetData: SharedPreferences
    ) {
        // Get widget dimensions to determine which layout to use
        val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
        val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 110)
        val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 40)

        // Choose layout based on size
        val layoutId = when {
            minWidth >= 180 && minHeight >= 100 -> R.layout.crossbar_widget_large
            minWidth >= 110 -> R.layout.crossbar_widget_medium
            else -> R.layout.crossbar_widget_small
        }

        val views = RemoteViews(context.packageName, layoutId)

        // Get plugin IDs from stored data
        val pluginIdsJson = widgetData.getString("plugin_ids", null)
        val pluginIds = try {
            if (pluginIdsJson != null) {
                val jsonArray = JSONArray(pluginIdsJson)
                (0 until jsonArray.length()).map { jsonArray.getString(it) }
            } else {
                emptyList()
            }
        } catch (e: Exception) {
            android.util.Log.e(TAG, "Error parsing plugin IDs", e)
            emptyList()
        }

        if (pluginIds.isEmpty()) {
            // Show "No data" state
            setNoDataState(views, layoutId)
        } else {
            // Display first plugin for small/medium, multiple for large
            when (layoutId) {
                R.layout.crossbar_widget_large -> {
                    updateLargeWidget(views, widgetData, pluginIds.take(4))
                }
                else -> {
                    val firstPluginId = pluginIds.first()
                    updateSinglePluginWidget(views, widgetData, firstPluginId, layoutId)
                }
            }
        }

        // Set up click handlers
        setupClickHandlers(context, views, layoutId, appWidgetId)

        // Update the widget
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun updateSinglePluginWidget(
        views: RemoteViews,
        widgetData: SharedPreferences,
        pluginId: String,
        layoutId: Int
    ) {
        val pluginDataJson = widgetData.getString("plugin_$pluginId", null)
        
        if (pluginDataJson == null) {
            setNoDataState(views, layoutId)
            return
        }

        try {
            val pluginData = JSONObject(pluginDataJson)
            
            // Extract data
            val icon = pluginData.optString("icon", "📊")
            val text = pluginData.optString("text", "--")
            val title = pluginData.optString("pluginId", "Plugin")
            val tooltip = pluginData.optString("tooltip", "")

            // Set icon
            views.setTextViewText(R.id.widget_icon, icon)
            
            // Set value
            views.setTextViewText(R.id.widget_value, text)

            // Set title for medium layout
            if (layoutId == R.layout.crossbar_widget_medium) {
                views.setTextViewText(R.id.widget_title, formatPluginTitle(title))
                
                // Show subtitle if tooltip exists
                if (tooltip.isNotEmpty()) {
                    views.setTextViewText(R.id.widget_subtitle, tooltip)
                    views.setViewVisibility(R.id.widget_subtitle, View.VISIBLE)
                } else {
                    views.setViewVisibility(R.id.widget_subtitle, View.GONE)
                }
            }

            // Handle colors if present
            val colorHex = pluginData.optString("color", null)
            if (colorHex != null && colorHex.length >= 6) {
                try {
                    val color = android.graphics.Color.parseColor("#$colorHex")
                    views.setTextColor(R.id.widget_value, color)
                } catch (e: Exception) {
                    // Ignore invalid colors
                }
            }

        } catch (e: Exception) {
            android.util.Log.e(TAG, "Error parsing plugin data for $pluginId", e)
            setNoDataState(views, layoutId)
        }
    }

    private fun updateLargeWidget(
        views: RemoteViews,
        widgetData: SharedPreferences,
        pluginIds: List<String>
    ) {
        // Plugin item IDs
        val itemContainerIds = listOf(
            R.id.plugin_item_1, R.id.plugin_item_2, R.id.plugin_item_3, R.id.plugin_item_4
        )
        val iconIds = listOf(
            R.id.plugin_1_icon, R.id.plugin_2_icon, R.id.plugin_3_icon, R.id.plugin_4_icon
        )
        val titleIds = listOf(
            R.id.plugin_1_title, R.id.plugin_2_title, R.id.plugin_3_title, R.id.plugin_4_title
        )
        val valueIds = listOf(
            R.id.plugin_1_value, R.id.plugin_2_value, R.id.plugin_3_value, R.id.plugin_4_value
        )

        // Hide all items first
        itemContainerIds.forEach { views.setViewVisibility(it, View.GONE) }

        // Populate with data
        pluginIds.forEachIndexed { index, pluginId ->
            if (index >= 4) return@forEachIndexed

            val pluginDataJson = widgetData.getString("plugin_$pluginId", null)
            if (pluginDataJson != null) {
                try {
                    val pluginData = JSONObject(pluginDataJson)
                    
                    val icon = pluginData.optString("icon", "📊")
                    val text = pluginData.optString("text", "--")
                    val title = pluginData.optString("pluginId", "Plugin")

                    views.setViewVisibility(itemContainerIds[index], View.VISIBLE)
                    views.setTextViewText(iconIds[index], icon)
                    views.setTextViewText(titleIds[index], formatPluginTitle(title))
                    views.setTextViewText(valueIds[index], text)

                } catch (e: Exception) {
                    android.util.Log.e(TAG, "Error parsing plugin data for $pluginId", e)
                }
            }
        }

        // Update last updated timestamp
        views.setTextViewText(R.id.widget_last_updated, "Updated just now")
    }

    private fun setNoDataState(views: RemoteViews, layoutId: Int) {
        views.setTextViewText(R.id.widget_icon, "📊")
        views.setTextViewText(R.id.widget_value, "--")
        
        if (layoutId == R.layout.crossbar_widget_medium) {
            views.setTextViewText(R.id.widget_title, "Crossbar")
            views.setViewVisibility(R.id.widget_subtitle, View.GONE)
        }
    }

    private fun setupClickHandlers(
        context: Context,
        views: RemoteViews,
        layoutId: Int,
        appWidgetId: Int
    ) {
        // Click on widget container opens the app
        val openAppIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openAppPendingIntent = PendingIntent.getActivity(
            context,
            appWidgetId,
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_container, openAppPendingIntent)

        // Refresh button triggers widget update
        if (layoutId != R.layout.crossbar_widget_small) {
            val refreshIntent = Intent(context, CrossbarWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(appWidgetId))
                // Use a unique URI to make sure PendingIntent is unique
                data = Uri.parse("crossbar://refresh/$appWidgetId")
            }
            val refreshPendingIntent = PendingIntent.getBroadcast(
                context,
                appWidgetId,
                refreshIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_refresh, refreshPendingIntent)
        }
    }

    /**
     * Format plugin ID to a readable title
     * e.g., "cpu.10s.sh" -> "Cpu"
     */
    private fun formatPluginTitle(pluginId: String): String {
        return pluginId
            .substringBefore(".")
            .replaceFirstChar { it.uppercase() }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: android.os.Bundle
    ) {
        // Re-render when widget is resized
        val widgetData = es.antonborri.home_widget.HomeWidgetPlugin.getData(context)
        updateWidget(context, appWidgetManager, appWidgetId, widgetData)
    }
}
