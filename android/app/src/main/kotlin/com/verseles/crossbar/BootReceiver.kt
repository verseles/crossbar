package com.verseles.crossbar

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == "android.intent.action.QUICKBOOT_POWERON" ||
            intent.action == "com.htc.intent.action.QUICKBOOT_POWERON") {

            Log.d("Crossbar", "Boot completed received")

            // Check preferences
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            // 'flutter.' prefix is added by shared_preferences plugin
            val startWithSystem = prefs.getBoolean("flutter.start_with_system", false)

            if (startWithSystem) {
                Log.d("Crossbar", "Starting CrossbarService from boot")
                val serviceIntent = Intent(context, CrossbarService::class.java)
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }
            } else {
                Log.d("Crossbar", "Start on boot disabled in settings")
            }
        }
    }
}
