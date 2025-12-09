package com.verseles.crossbar

/**
 * Large Widget (2x2): Shows list of up to 4 plugins.
 * No resize allowed - fixed size for stability.
 */
class CrossbarWidgetLarge : CrossbarWidgetBase() {
    override fun getLayoutId(): Int = R.layout.crossbar_widget_large
    override fun hasRefreshButton(): Boolean = true
}
