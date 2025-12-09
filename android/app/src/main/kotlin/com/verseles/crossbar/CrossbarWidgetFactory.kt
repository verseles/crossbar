package com.verseles.crossbar

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONArray
import org.json.JSONObject
import es.antonborri.home_widget.HomeWidgetPlugin

class CrossbarWidgetFactory(
    private val context: Context,
    intent: Intent
) : RemoteViewsService.RemoteViewsFactory {

    private val appWidgetId: Int = intent.getIntExtra(
        android.appwidget.AppWidgetManager.EXTRA_APPWIDGET_ID,
        android.appwidget.AppWidgetManager.INVALID_APPWIDGET_ID
    )
    private var pluginIds: List<String> = emptyList()

    override fun onCreate() {
        // Initialize data
        loadData()
    }

    override fun onDataSetChanged() {
        // Refresh data
        loadData()
    }

    private fun loadData() {
        try {
            val widgetData = HomeWidgetPlugin.getData(context)
            val configKey = "widget_config_$appWidgetId"
            val pluginIdsJson = widgetData.getString(configKey, null)

            pluginIds = if (pluginIdsJson != null) {
                try {
                    val jsonArray = JSONArray(pluginIdsJson)
                    (0 until jsonArray.length()).map { jsonArray.getString(it) }
                } catch (e: Exception) {
                    emptyList()
                }
            } else {
                emptyList()
            }
        } catch (e: Exception) {
            pluginIds = emptyList()
        }
    }

    override fun onDestroy() {
        pluginIds = emptyList()
    }

    override fun getCount(): Int {
        return pluginIds.size
    }

    override fun getViewAt(position: Int): RemoteViews {
        if (position >= pluginIds.size) return RemoteViews(context.packageName, R.layout.item_widget_plugin)

        val views = RemoteViews(context.packageName, R.layout.item_widget_plugin)
        val pluginId = pluginIds[position]

        try {
            val widgetData = HomeWidgetPlugin.getData(context)
            val pluginDataJson = widgetData.getString("plugin_$pluginId", null)

            if (pluginDataJson != null) {
                val pluginData = JSONObject(pluginDataJson)

                val icon = pluginData.optString("icon", "📊")
                val text = pluginData.optString("text", "--")
                val title = pluginData.optString("pluginId", "Plugin")
                val colorHex = pluginData.optString("color", null)

                views.setTextViewText(R.id.widget_item_icon, icon)
                views.setTextViewText(R.id.widget_item_title, formatPluginTitle(title))
                views.setTextViewText(R.id.widget_item_value, text)

                if (colorHex != null && colorHex.length >= 6) {
                    try {
                        val color = Color.parseColor("#$colorHex")
                        views.setTextColor(R.id.widget_item_value, color)
                    } catch (e: Exception) {
                        // Use default color
                    }
                }
            } else {
                views.setTextViewText(R.id.widget_item_title, formatPluginTitle(pluginId))
                views.setTextViewText(R.id.widget_item_value, "Loading...")
            }
        } catch (e: Exception) {
             android.util.Log.e("CrossbarWidgetFactory", "Error binding view at $position", e)
        }

        return views
    }

    private fun formatPluginTitle(pluginId: String): String {
        return pluginId
            .substringBefore(".")
            .replaceFirstChar { it.uppercase() }
    }

    override fun getLoadingView(): RemoteViews? {
        return null
    }

    override fun getViewTypeCount(): Int {
        return 1
    }

    override fun getItemId(position: Int): Long {
        return position.toLong()
    }

    override fun hasStableIds(): Boolean {
        return true
    }
}
