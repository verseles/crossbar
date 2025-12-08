package com.verseles.crossbar

import android.content.Intent
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

class NotificationBlockerService : NotificationListenerService() {

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        super.onNotificationRemoved(sbn)

        if (sbn?.packageName == packageName && sbn?.id == CrossbarService.NOTIFICATION_ID) {
            Log.w("Crossbar", "Persistent notification removed! Attempting to restore...")

             val prefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
             val keepInBackground = prefs.getBoolean("flutter.show_in_tray", true)

             if (keepInBackground) {
                 val intent = Intent(this, CrossbarService::class.java)
                 if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                     startForegroundService(intent)
                 } else {
                     startService(intent)
                 }
             }
        }
    }
}
