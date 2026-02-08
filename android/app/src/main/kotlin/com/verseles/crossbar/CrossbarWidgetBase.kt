package com.verseles.crossbar

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
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
    }

    /**
     * Returns the layout resource ID for this widget size.
     */
    abstract fun getLayoutId(): Int

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

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        super.onDeleted(context, appWidgetIds)
        val prefs = HomeWidgetPlugin.getData(context)
        val editor = prefs.edit()
        for (appWidgetId in appWidgetIds) {
            val key = "widget_${appWidgetId}_plugins"
            editor.remove(key)
            WidgetLogStore.append(
                context,
                "INFO",
                TAG,
                "Config cleared on delete",
                appWidgetId,
            )
        }
        editor.commit()
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        widgetData: SharedPreferences
    ) {
        try {
            val resolvedData = HomeWidgetPlugin.getData(context)
            val layoutId = getLayoutId()
            val views = RemoteViews(context.packageName, layoutId)

            // Get plugin IDs - first try per-widget config, then fallback to global
            val perWidgetKey = "widget_${appWidgetId}_plugins"
            val perWidgetJson = resolvedData.getString(perWidgetKey, null)
            val globalJson = resolvedData.getString("plugin_ids", null)
            
            val pluginIdsJson = perWidgetJson ?: globalJson

            WidgetLogStore.append(
                context,
                "INFO",
                TAG,
                "Update start",
                appWidgetId,
                "perWidget=${perWidgetJson != null} global=${globalJson != null}",
            )
            
            val pluginIds = try {
                if (pluginIdsJson != null) {
                    val jsonArray = JSONArray(pluginIdsJson)
                    (0 until jsonArray.length()).map { jsonArray.getString(it) }
                } else {
                    emptyList()
                }
            } catch (e: Exception) {
                android.util.Log.e(TAG, "Error parsing plugin IDs for widget $appWidgetId", e)
                WidgetLogStore.append(
                    context,
                    "ERROR",
                    TAG,
                    "Plugin IDs parse error",
                    appWidgetId,
                    "error=${e.message}",
                )
                emptyList()
            }

            var resolvedPluginIds = pluginIds

            if (globalJson != null) {
                val globalIds = try {
                    val globalArray = JSONArray(globalJson)
                    (0 until globalArray.length()).map { globalArray.getString(it) }
                } catch (_: Exception) {
                    emptyList()
                }

                if (globalIds.isNotEmpty()) {
                    val hasOnlyMissing = resolvedPluginIds.isNotEmpty() &&
                        resolvedPluginIds.all { id -> !globalIds.contains(id) }

                    if (hasOnlyMissing) {
                        resolvedPluginIds = globalIds
                        resolvedData.edit().putString(perWidgetKey, globalJson).commit()
                        WidgetLogStore.append(
                            context,
                            "INFO",
                            TAG,
                            "Config migrated to global",
                            appWidgetId,
                        )
                    }
                }
            }

            if (resolvedPluginIds.isEmpty()) {
                WidgetLogStore.append(
                    context,
                    "WARN",
                    TAG,
                    "No plugin IDs",
                    appWidgetId,
                )
                setNoDataState(views, layoutId)
            } else {
                when (layoutId) {
                    R.layout.crossbar_widget_large -> {
                        updateLargeWidget(
                            context,
                            views,
                            resolvedData,
                            resolvedPluginIds.take(4),
                            appWidgetId,
                        )
                    }
                    else -> {
                        val firstPluginId = resolvedPluginIds.first()
                        updateSinglePluginWidget(
                            context,
                            views,
                            resolvedData,
                            firstPluginId,
                            layoutId,
                            appWidgetId,
                        )
                    }
                }
            }

            setupClickHandlers(context, views, appWidgetId)
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
        context: Context,
        views: RemoteViews,
        widgetData: SharedPreferences,
        pluginId: String,
        layoutId: Int,
        appWidgetId: Int
    ) {
        val pluginDataJson = getPluginData(widgetData, pluginId, appWidgetId, context)

        if (pluginDataJson == null) {
            WidgetLogStore.append(
                context,
                "WARN",
                TAG,
                "Missing plugin data",
                appWidgetId,
                "pluginId=$pluginId",
            )
            setNoDataState(views, layoutId)
            return
        }

        try {
            val pluginData = JSONObject(pluginDataJson)

            val icon = pluginData.optString("icon", "📊")
            val text = pluginData.optString("text", "--")
            val rawTitle = pluginData.optString("title", "")
            val title = if (rawTitle.isNotBlank()) {
                rawTitle
            } else {
                pluginData.optString("pluginId", "Plugin")
            }
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

            // Show/hide menu button based on whether plugin has menu items
            val hasMenu = hasMenuItems(pluginData)
            views.setViewVisibility(R.id.widget_menu, if (hasMenu) View.VISIBLE else View.GONE)
            if (hasMenu) {
                setupMenuClickHandler(context, views, R.id.widget_menu, pluginId, appWidgetId + 4000)
            }

        } catch (e: Exception) {
            android.util.Log.e(TAG, "Error parsing plugin data for $pluginId", e)
            WidgetLogStore.append(
                context,
                "ERROR",
                TAG,
                "Plugin data parse error",
                appWidgetId,
                "pluginId=$pluginId error=${e.message}",
            )
            setNoDataState(views, layoutId)
        }
    }

    private fun updateLargeWidget(
        context: Context,
        views: RemoteViews,
        widgetData: SharedPreferences,
        pluginIds: List<String>,
        appWidgetId: Int
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
        val menuIds = listOf(
            R.id.plugin_1_menu, R.id.plugin_2_menu, R.id.plugin_3_menu, R.id.plugin_4_menu
        )

        itemContainerIds.forEach { views.setViewVisibility(it, View.GONE) }

        pluginIds.forEachIndexed { index, pluginId ->
            if (index >= 4) return@forEachIndexed

            val pluginDataJson = getPluginData(widgetData, pluginId, appWidgetId, context)
            if (pluginDataJson != null) {
                try {
                    val pluginData = JSONObject(pluginDataJson)

                    val icon = pluginData.optString("icon", "📊")
                    val text = pluginData.optString("text", "--")
                    val rawTitle = pluginData.optString("title", "")
                    val title = if (rawTitle.isNotBlank()) {
                        rawTitle
                    } else {
                        pluginData.optString("pluginId", "Plugin")
                    }

                    views.setViewVisibility(itemContainerIds[index], View.VISIBLE)
                    views.setTextViewText(iconIds[index], icon)
                    views.setTextViewText(titleIds[index], formatPluginTitle(title))
                    views.setTextViewText(valueIds[index], text)

                    // Show/hide menu button for this row
                    val hasMenu = hasMenuItems(pluginData)
                    views.setViewVisibility(menuIds[index], if (hasMenu) View.VISIBLE else View.GONE)
                    if (hasMenu) {
                        setupMenuClickHandler(
                            context, views, menuIds[index], pluginId,
                            appWidgetId + 5000 + (index * 100)
                        )
                    }

                } catch (e: Exception) {
                    android.util.Log.e(TAG, "Error parsing plugin data for $pluginId", e)
                    WidgetLogStore.append(
                        context,
                        "ERROR",
                        TAG,
                        "Large widget parse error",
                        appWidgetId,
                        "pluginId=$pluginId error=${e.message}",
                    )
                }
            } else {
                WidgetLogStore.append(
                    context,
                    "WARN",
                    TAG,
                    "Large widget missing data",
                    appWidgetId,
                    "pluginId=$pluginId",
                )
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

    private fun getPluginData(
        widgetData: SharedPreferences,
        pluginId: String,
        appWidgetId: Int,
        context: Context
    ): String? {
        val direct = widgetData.getString("plugin_$pluginId", null)
        if (direct != null) return direct

        val canonicalId = canonicalPluginId(pluginId)
        if (canonicalId != pluginId) {
            val fallback = widgetData.getString("plugin_$canonicalId", null)
            if (fallback != null) {
                WidgetLogStore.append(
                    context,
                    "INFO",
                    TAG,
                    "Fallback plugin data",
                    appWidgetId,
                    "pluginId=$pluginId canonical=$canonicalId",
                )
            }
            return fallback
        }

        return null
    }

    private fun canonicalPluginId(pluginId: String): String {
        val withoutOff = pluginId.replace(".off.", ".")
        val match = Regex("^(.+?)\\.(?:\\d+(?:\\.\\d+)?)[smh]\\.").find(withoutOff)
        return match?.groupValues?.get(1) ?: withoutOff
    }

    private fun setupClickHandlers(
        context: Context,
        views: RemoteViews,
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

        val editIntent = Intent(context, WidgetConfigActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        }
        val editPendingIntent = PendingIntent.getActivity(
            context,
            appWidgetId + 2000,
            editIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_edit, editPendingIntent)
    }

    private fun formatPluginTitle(pluginId: String): String {
        return pluginId
            .substringBefore(".")
            .replaceFirstChar { it.uppercase() }
    }

    /**
     * Check if plugin data contains non-empty menu items (excluding separators).
     */
    private fun hasMenuItems(pluginData: JSONObject): Boolean {
        val menu = pluginData.optJSONArray("menu") ?: return false
        for (i in 0 until menu.length()) {
            val item = menu.optJSONObject(i) ?: continue
            if (!item.optBoolean("separator", false)) return true
        }
        return false
    }

    /**
     * Set up a PendingIntent that opens WidgetMenuActivity for a specific plugin.
     */
    private fun setupMenuClickHandler(
        context: Context,
        views: RemoteViews,
        viewId: Int,
        pluginId: String,
        requestCode: Int
    ) {
        val menuIntent = Intent(context, WidgetMenuActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
            putExtra(WidgetMenuActivity.EXTRA_PLUGIN_ID, pluginId)
        }
        val menuPendingIntent = PendingIntent.getActivity(
            context,
            requestCode,
            menuIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(viewId, menuPendingIntent)
    }
}
