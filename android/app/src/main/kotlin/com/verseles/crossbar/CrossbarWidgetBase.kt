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

            if (layoutId == R.layout.crossbar_widget_large) {
                 // Bind ListService for ListView
                 val serviceIntent = Intent(context, CrossbarWidgetListService::class.java).apply {
                     putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                     data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
                 }

                 views.setRemoteAdapter(R.id.widget_list_view, serviceIntent)
                 // Note: we don't set empty view ID here because we handle fallback manually or via adapter count 0

                 // Template for item clicks
                 val clickIntent = Intent(context, MainActivity::class.java).apply {
                      flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                 }
                 val pendingIntent = PendingIntent.getActivity(
                     context,
                     appWidgetId,
                     clickIntent,
                     PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
                 )
                 views.setPendingIntentTemplate(R.id.widget_list_view, pendingIntent)

                 appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.widget_list_view)

            } else {
                 // Small/Medium: Parse JSON manually
                 val allDataJson = widgetData.getString("flutter.widget_data", null)
                 var hasData = false

                 if (allDataJson != null) {
                     try {
                         val allData = JSONObject(allDataJson)
                         val myData = allData.optJSONArray(appWidgetId.toString())

                         if (myData != null && myData.length() > 0) {
                              val item = myData.getJSONObject(0)
                              updateSinglePluginWidget(views, item, layoutId)
                              hasData = true
                         }
                     } catch (e: Exception) {
                         android.util.Log.e(TAG, "Error parsing widget data", e)
                     }
                 }

                 if (!hasData) {
                     setNoDataState(views, layoutId)
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
        pluginData: JSONObject,
        layoutId: Int
    ) {
        try {
            val icon = pluginData.optString("icon", "📊")
            val text = pluginData.optString("text", "--")
            val title = pluginData.optString("title", "Plugin")

            views.setTextViewText(R.id.widget_icon, icon)
            views.setTextViewText(R.id.widget_value, text)

            if (layoutId == R.layout.crossbar_widget_medium) {
                views.setTextViewText(R.id.widget_title, formatPluginTitle(title))
                views.setViewVisibility(R.id.widget_subtitle, View.GONE)
            }

            val colorHex = pluginData.optString("color", null)
            if (colorHex != null && colorHex.length >= 6) {
                try {
                    val color = android.graphics.Color.parseColor("#$colorHex")
                    views.setTextColor(R.id.widget_value, color)
                } catch (e: Exception) {
                    // Ignore
                }
            }

        } catch (e: Exception) {
            android.util.Log.e(TAG, "Error parsing plugin data", e)
            setNoDataState(views, layoutId)
        }
    }

    private fun setNoDataState(views: RemoteViews, layoutId: Int) {
        when (layoutId) {
            R.layout.crossbar_widget_large -> {
                // Handled by ListService usually, but if we fell back here?
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
