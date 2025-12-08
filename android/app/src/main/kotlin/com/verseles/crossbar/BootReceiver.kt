package com.verseles.crossbar

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

/**
 * BootReceiver - Handles BOOT_COMPLETED broadcast
 * 
 * When the device finishes booting, this receiver checks if "Start on Boot" 
 * is enabled in the app settings. If enabled, it starts the CrossbarForegroundService
 * which will maintain the persistent notification and run plugins in the background.
 */
class BootReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "CrossbarBootReceiver"
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val KEY_START_WITH_SYSTEM = "flutter.start_with_system"
        private const val KEY_SHOW_IN_TRAY = "flutter.show_in_tray"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) {
            return
        }

        Log.d(TAG, "Boot completed received")

        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val startOnBoot = prefs.getBoolean(KEY_START_WITH_SYSTEM, false)
        val keepOnBackground = prefs.getBoolean(KEY_SHOW_IN_TRAY, true)

        Log.d(TAG, "Start on boot: $startOnBoot, Keep on background: $keepOnBackground")

        if (startOnBoot) {
            if (keepOnBackground) {
                // Start foreground service - this will show persistent notification
                startForegroundService(context)
            } else {
                // Just launch the main activity
                launchMainActivity(context)
            }
        }
    }

    private fun startForegroundService(context: Context) {
        try {
            val serviceIntent = Intent(context, CrossbarForegroundService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
            Log.d(TAG, "Foreground service started")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start foreground service", e)
            // Fallback to launching main activity
            launchMainActivity(context)
        }
    }

    private fun launchMainActivity(context: Context) {
        try {
            val activityIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            context.startActivity(activityIntent)
            Log.d(TAG, "Main activity launched")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to launch main activity", e)
        }
    }
}
