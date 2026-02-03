package com.verseles.crossbar

import android.content.Context
import android.content.SharedPreferences
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

object WidgetLogStore {
    private const val PREFS_NAME = "HomeWidgetPreferences"
    private const val LOG_KEY = "widget_debug_logs"
    private const val MAX_LINES = 200

    fun append(
        context: Context,
        level: String,
        source: String,
        message: String,
        widgetId: Int? = null,
        details: String? = null,
    ) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val timestamp = isoTimestamp()

        val lineBuilder = StringBuilder()
        lineBuilder.append("[").append(timestamp).append("] ")
        lineBuilder.append("[").append(level).append("] ")
        lineBuilder.append("[").append(source).append("]")
        if (widgetId != null) {
            lineBuilder.append(" widgetId=").append(widgetId)
        }
        if (!details.isNullOrBlank()) {
            lineBuilder.append(" ").append(details)
        }
        lineBuilder.append(" ").append(message)

        val existing = prefs.getString(LOG_KEY, "")
        val lines = if (existing.isNullOrBlank()) {
            mutableListOf<String>()
        } else {
            existing.split("\n").toMutableList()
        }

        lines.add(lineBuilder.toString().trim())
        while (lines.size > MAX_LINES) {
            lines.removeAt(0)
        }

        prefs.edit().putString(LOG_KEY, lines.joinToString("\n")).apply()
    }

    fun clear(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().remove(LOG_KEY).apply()
    }

    private fun isoTimestamp(): String {
        val formatter = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
        formatter.timeZone = TimeZone.getTimeZone("UTC")
        return formatter.format(Date())
    }
}
