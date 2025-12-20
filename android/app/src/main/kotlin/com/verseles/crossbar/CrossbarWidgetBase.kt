package com.verseles.crossbar

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import org.json.JSONObject

/**
 * Base class for Crossbar widgets with shared functionality.
 * Each size-specific widget extends this class.
 */
abstract class CrossbarWidgetBase : HomeWidgetProvider() {

    companion object {
        private const val TAG = "CrossbarWidget"
        private const val ACTION_REFRESH = "com.verseles.crossbar.ACTION_REFRESH"
    }

    /**
     * Returns the layout resource ID for this widget size.
     */
    abstract fun getLayoutId(): Int

    /**
     * Returns whether this widget shows refresh button.
     */
    open fun hasRefreshButton(): Boolean = false

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
        try {
            val layoutId = getLayoutId()
            val views = RemoteViews(context.packageName, layoutId)

            // Get plugin IDs - first try per-widget config, then fallback to global
            val perWidgetKey = "widget_${appWidgetId}_plugins"
            val perWidgetJson = widgetData.getString(perWidgetKey, null)
            val globalJson = widgetData.getString("plugin_ids", null)
            
            val pluginIdsJson = perWidgetJson ?: globalJson
            
            val pluginIds = try {
                if (pluginIdsJson != null) {
                    val jsonArray = JSONArray(pluginIdsJson)
                    (0 until jsonArray.length()).map { jsonArray.getString(it) }
                } else {
                    emptyList()
                }
            } catch (e: Exception) {
                android.util.Log.e(TAG, "Error parsing plugin IDs for widget $appWidgetId", e)
                emptyList()
            }

            if (pluginIds.isEmpty()) {
                setNoDataState(views, layoutId)
            } else {
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

            setupClickHandlers(context, views, layoutId, appWidgetId)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        } catch (e: Exception) {
            android.util.Log.e(TAG, "Error updating widget $appWidgetId", e)
            showFallbackWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun showFallbackWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        try {
            val fallbackViews = RemoteViews(context.packageName, R.layout.crossbar_widget_small)
            fallbackViews.setTextViewText(R.id.widget_icon, "⚠️")
            fallbackViews.setTextViewText(R.id.widget_value, "Tap to open")
            
            val openAppIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val openAppPendingIntent = PendingIntent.getActivity(
                context,
                appWidgetId,
                openAppIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            fallbackViews.setOnClickPendingIntent(R.id.widget_container, openAppPendingIntent)
            
            appWidgetManager.updateAppWidget(appWidgetId, fallbackViews)
        } catch (fallbackError: Exception) {
            android.util.Log.e(TAG, "Failed to show fallback widget", fallbackError)
        }
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
            
            val icon = pluginData.optString("icon", "📊")
            val text = pluginData.optString("text", "--")
            val title = pluginData.optString("pluginId", "Plugin")
            val tooltip = pluginData.optString("tooltip", "")

            views.setTextViewText(R.id.widget_icon, icon)
            views.setTextViewText(R.id.widget_value, text)

            if (layoutId == R.layout.crossbar_widget_medium) {
                views.setTextViewText(R.id.widget_title, formatPluginTitle(title))
                
                if (tooltip.isNotEmpty()) {
                    views.setTextViewText(R.id.widget_subtitle, tooltip)
                    views.setViewVisibility(R.id.widget_subtitle, View.VISIBLE)
                } else {
                    views.setViewVisibility(R.id.widget_subtitle, View.GONE)
                }
            }

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

        itemContainerIds.forEach { views.setViewVisibility(it, View.GONE) }

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

        views.setTextViewText(R.id.widget_last_updated, "Updated just now")
    }

    private fun setNoDataState(views: RemoteViews, layoutId: Int) {
        when (layoutId) {
            R.layout.crossbar_widget_large -> {
                views.setViewVisibility(R.id.plugin_item_1, View.VISIBLE)
                views.setTextViewText(R.id.plugin_1_icon, "⚙️")
                views.setTextViewText(R.id.plugin_1_title, "Crossbar")
                views.setTextViewText(R.id.plugin_1_value, "Open app to start")
                views.setViewVisibility(R.id.plugin_item_2, View.GONE)
                views.setViewVisibility(R.id.plugin_item_3, View.GONE)
                views.setViewVisibility(R.id.plugin_item_4, View.GONE)
            }
            R.layout.crossbar_widget_medium -> {
                views.setTextViewText(R.id.widget_icon, "⚙️")
                views.setTextViewText(R.id.widget_value, "Open app")
                views.setTextViewText(R.id.widget_title, "Crossbar")
                views.setTextViewText(R.id.widget_subtitle, "Tap to start")
                views.setViewVisibility(R.id.widget_subtitle, View.VISIBLE)
            }
            else -> {
                views.setTextViewText(R.id.widget_icon, "⚙️")
                views.setTextViewText(R.id.widget_value, "Open app")
            }
        }
    }

    private fun setupClickHandlers(
        context: Context,
        views: RemoteViews,
        layoutId: Int,
        appWidgetId: Int
    ) {
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

        if (hasRefreshButton() && layoutId != R.layout.crossbar_widget_small) {
            val refreshIntent = Intent(context, MainActivity::class.java).apply {
                action = ACTION_REFRESH
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtra("refresh_widgets", true)
                data = android.net.Uri.parse("crossbar://refresh/$appWidgetId")
            }
            val refreshPendingIntent = PendingIntent.getActivity(
                context,
                appWidgetId + 1000,
                refreshIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_refresh, refreshPendingIntent)
        }
    }

    private fun formatPluginTitle(pluginId: String): String {
        return pluginId
            .substringBefore(".")
            .replaceFirstChar { it.uppercase() }
    }
}
