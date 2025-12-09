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

            // Read specific configuration for this widget ID
            val configKey = "widget_config_$appWidgetId"
            val pluginIdsJson = widgetData.getString(configKey, null)

            val pluginIds = try {
                if (pluginIdsJson != null) {
                    val jsonArray = JSONArray(pluginIdsJson)
                    (0 until jsonArray.length()).map { jsonArray.getString(it) }
                } else {
                    // Legacy fallback: Try global list only if specific config not found?
                    // Or strictly empty? Let's check global for migration or just show "Configure"
                    // User requirement: "No more random defaults". So if no config, show Configure state.
                    emptyList()
                }
            } catch (e: Exception) {
                android.util.Log.e(TAG, "Error parsing plugin IDs", e)
                emptyList()
            }

            if (pluginIds.isEmpty()) {
                setNoDataState(views, layoutId)
            } else {
                when (layoutId) {
                    R.layout.crossbar_widget_large -> {
                        updateLargeWidget(context, views, appWidgetId)
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
            // Configured but no data yet (or plugin disabled/removed)
            views.setTextViewText(R.id.widget_icon, "⏳")
            views.setTextViewText(R.id.widget_value, "Loading...")
            if (layoutId == R.layout.crossbar_widget_medium) {
                 views.setTextViewText(R.id.widget_title, formatPluginTitle(pluginId))
                 views.setViewVisibility(R.id.widget_subtitle, View.GONE)
            }
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

    open fun updateLargeWidget(
        context: Context,
        views: RemoteViews,
        appWidgetId: Int
    ) {
        // Default implementation for standard list widget
        // Bind the RemoteViewsService to the ListView
        val intent = Intent(context, CrossbarWidgetService::class.java).apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            data = android.net.Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
        }
        views.setRemoteAdapter(R.id.widget_list_view, intent)
        views.setEmptyView(R.id.widget_list_view, R.id.widget_last_updated) // Or a dedicated empty view

        // Notify the list to refresh its data
        val appWidgetManager = AppWidgetManager.getInstance(context)
        appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.widget_list_view)
    }

    private fun setNoDataState(views: RemoteViews, layoutId: Int) {
        when (layoutId) {
            R.layout.crossbar_widget_large -> {
                 // For large widget, maybe show a "Tap to Configure" message inside the list or header
                 views.setTextViewText(R.id.widget_header_title, "Crossbar (Tap to set up)")
            }
            R.layout.crossbar_widget_medium -> {
                views.setTextViewText(R.id.widget_icon, "⚙️")
                views.setTextViewText(R.id.widget_value, "Configure")
                views.setTextViewText(R.id.widget_title, "Crossbar")
                views.setTextViewText(R.id.widget_subtitle, "Tap to select plugin")
                views.setViewVisibility(R.id.widget_subtitle, View.VISIBLE)
            }
            else -> {
                views.setTextViewText(R.id.widget_icon, "⚙️")
                views.setTextViewText(R.id.widget_value, "Setup")
            }
        }
    }

    private fun setupClickHandlers(
        context: Context,
        views: RemoteViews,
        layoutId: Int,
        appWidgetId: Int
    ) {
        // If not configured (no data state), click should open config
        // Actually, MainActivity handles Intent. If we send ACTION_APPWIDGET_CONFIGURE,
        // it triggers the config flow again.

        val configIntent = Intent(context, MainActivity::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_CONFIGURE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            data = android.net.Uri.parse("crossbar://configure/$appWidgetId")
        }

        val configPendingIntent = PendingIntent.getActivity(
            context,
            appWidgetId,
            configIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Bind click to main container
        views.setOnClickPendingIntent(R.id.widget_container, configPendingIntent)

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
