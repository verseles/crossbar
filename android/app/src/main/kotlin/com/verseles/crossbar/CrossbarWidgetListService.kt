package com.verseles.crossbar

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONObject

class CrossbarWidgetListService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return CrossbarRemoteViewsFactory(this.applicationContext, intent)
    }
}

class CrossbarRemoteViewsFactory(
    private val context: Context,
    intent: Intent
) : RemoteViewsService.RemoteViewsFactory {

    private val appWidgetId: Int = intent.getIntExtra(
        AppWidgetManager.EXTRA_APPWIDGET_ID,
        AppWidgetManager.INVALID_APPWIDGET_ID
    )
    private var dataList: List<PluginData> = ArrayList()

    data class PluginData(val id: String, val title: String, val text: String, val icon: String = "📊")

    override fun onCreate() {
        // No-op
    }

    override fun onDataSetChanged() {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val allDataJson = prefs.getString("flutter.widget_data", null)

        val newData = ArrayList<PluginData>()

        if (allDataJson != null) {
            try {
                val allData = JSONObject(allDataJson)
                val myData = allData.optJSONArray(appWidgetId.toString())

                if (myData != null) {
                    for (i in 0 until myData.length()) {
                        val obj = myData.getJSONObject(i)
                        newData.add(PluginData(
                            id = obj.optString("id", ""),
                            title = obj.optString("title", "Plugin"),
                            text = obj.optString("text", "--")
                        ))
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }

        dataList = newData
    }

    override fun onDestroy() {
        // No-op
    }

    override fun getCount(): Int {
        return dataList.size
    }

    override fun getViewAt(position: Int): RemoteViews {
        if (position >= dataList.size) return RemoteViews(context.packageName, R.layout.crossbar_widget_list_item)

        val item = dataList[position]
        val rv = RemoteViews(context.packageName, R.layout.crossbar_widget_list_item)

        rv.setTextViewText(R.id.plugin_title, formatPluginTitle(item.title))
        rv.setTextViewText(R.id.plugin_value, item.text)
        rv.setTextViewText(R.id.plugin_icon, item.icon)

        // Fill-in Intent for click
        val fillInIntent = Intent()
        fillInIntent.putExtra("pluginId", item.id)
        rv.setOnClickFillInIntent(R.id.plugin_item, fillInIntent)

        return rv
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
        return false
    }

    private fun formatPluginTitle(pluginId: String): String {
        return pluginId
            .substringBefore(".")
            .replaceFirstChar { it.uppercase() }
    }
}
