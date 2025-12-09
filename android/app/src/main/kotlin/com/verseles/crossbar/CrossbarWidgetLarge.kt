package com.verseles.crossbar

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews

/**
 * Large Widget (2x2) implementation.
 * Displays a list of selected plugins.
 */
class CrossbarWidgetLarge : CrossbarWidgetBase() {

    override fun getLayoutId(): Int = R.layout.crossbar_widget_large

    override fun hasRefreshButton(): Boolean = true

    // Note: We do NOT override updateLargeWidget here anymore because
    // the base implementation in CrossbarWidgetBase handles the ListView binding
    // AND the notification to update data.
}
