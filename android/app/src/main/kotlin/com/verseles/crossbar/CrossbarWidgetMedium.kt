package com.verseles.crossbar

/**
 * Medium Widget (2x1): Shows icon, title, value, and edit button.
 * No resize allowed - fixed size for stability.
 */
class CrossbarWidgetMedium : CrossbarWidgetBase() {
    override fun getLayoutId(): Int = R.layout.crossbar_widget_medium
}
