package com.verseles.crossbar

/**
 * Medium Widget (2x1): Shows icon, title, value, and refresh button.
 * No resize allowed - fixed size for stability.
 */
class CrossbarWidgetMedium : CrossbarWidgetBase() {
    override fun getLayoutId(): Int = R.layout.crossbar_widget_medium
    override fun hasRefreshButton(): Boolean = true
}
