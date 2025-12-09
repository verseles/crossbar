package com.verseles.crossbar

import android.content.Intent
import android.widget.RemoteViewsService

class CrossbarWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return CrossbarWidgetFactory(this.applicationContext, intent)
    }
}
