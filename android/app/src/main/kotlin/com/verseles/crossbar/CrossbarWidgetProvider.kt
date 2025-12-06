package com.verseles.crossbar

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import org.json.JSONArray
import org.json.JSONObject

open class CrossbarWidgetProviderBase(private val layoutId: Int) : HomeWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, layoutId).apply {
                // Open App on Click
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java
                )
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)

                updateViews(this, widgetData)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    open fun updateViews(views: RemoteViews, widgetData: SharedPreferences) {
        val pluginIdsJson = widgetData.getString("plugin_ids", "[]")
        val pluginIds = parsePluginIds(pluginIdsJson)

        if (pluginIds.isNotEmpty()) {
            val firstPluginId = pluginIds[0]
            val pluginDataJson = widgetData.getString("plugin_" + firstPluginId, null)

            if (pluginDataJson != null) {
                try {
                    val data = JSONObject(pluginDataJson)

                     val title = data.optString("title", firstPluginId)
                     val value = data.optString("value", "--")
                     val subtitle = data.optString("subtitle", "")

                     // Common IDs
                     // We use try-catch because small layout might not have subtitle, etc.
                     try { views.setTextViewText(R.id.widget_title, title) } catch(e: Exception){}
                     try { views.setTextViewText(R.id.widget_value, value) } catch(e: Exception){}
                     try { views.setTextViewText(R.id.widget_subtitle, subtitle) } catch(e: Exception){}

                } catch (e: Exception) {
                    try { views.setTextViewText(R.id.widget_title, "Error") } catch(e1: Exception){}
                }
            }
        } else {
             try { views.setTextViewText(R.id.widget_title, "No Plugins") } catch(e: Exception){}
        }
    }

    private fun parsePluginIds(json: String?): List<String> {
        val list = mutableListOf<String>()
        if (json == null) return list
        try {
            // Check if it is a JSON Array
            if (json.startsWith("[")) {
                val jsonArray = JSONArray(json)
                for (i in 0 until jsonArray.length()) {
                    list.add(jsonArray.getString(i))
                }
            } else {
                // Fallback attempt
                list.add(json)
            }
        } catch (e: Exception) {
            // ignore
        }
        return list
    }
}

class CrossbarWidgetProvider : CrossbarWidgetProviderBase(R.layout.widget_layout_medium)
class CrossbarWidgetSmallProvider : CrossbarWidgetProviderBase(R.layout.widget_layout_small)
class CrossbarWidgetLargeProvider : CrossbarWidgetProviderBase(R.layout.widget_layout_large)
