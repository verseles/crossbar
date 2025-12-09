package com.verseles.crossbar

/**
 * Small Widget (1x1): Shows icon and value only.
 * No resize allowed - fixed size for stability.
 */
class CrossbarWidgetSmall : CrossbarWidgetBase() {
    override fun getLayoutId(): Int = R.layout.crossbar_widget_small
    override fun hasRefreshButton(): Boolean = false
}
