package com.verseles.crossbar

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import es.antonborri.home_widget.HomeWidgetPlugin
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import org.json.JSONArray

/**
 * CrossbarForegroundService - Persistent notification service
 * 
 * This service runs in the foreground with a persistent notification that shows:
 * - The number of active plugins
 * - Quick actions: Refresh, Open App, Stop Service
 * 
 * The notification cannot be dismissed by the user (ongoing notification).
 * On Android 13+, users can dismiss it but the service continues running.
 */
class CrossbarForegroundService : Service() {

    companion object {
        private const val TAG = "CrossbarFGService"
        private const val CHANNEL_ID = "crossbar_service"
        private const val NOTIFICATION_ID = 9999

        private const val ACTION_REFRESH = "com.verseles.crossbar.ACTION_REFRESH"
        private const val ACTION_STOP = "com.verseles.crossbar.ACTION_STOP"

        // Service instance reference for reliable startForeground() updates
        private var instance: CrossbarForegroundService? = null

        /**
         * Updates the foreground notification content from Dart via MethodChannel.
         * Uses startForeground() from the service instance (guaranteed to work)
         * instead of NotificationManager.notify() which can't reliably replace
         * a notification created by startForeground().
         */
        fun updateContent(context: Context, title: String, body: String, lines: List<String>?) {
            Log.d(TAG, "updateContent: title=$title, body=$body, lines=${lines?.size ?: 0}")

            val openIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val openPendingIntent = PendingIntent.getActivity(
                context, 0, openIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val refreshIntent = Intent(context, CrossbarForegroundService::class.java).apply {
                action = ACTION_REFRESH
            }
            val refreshPendingIntent = PendingIntent.getService(
                context, 1, refreshIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val stopIntent = Intent(context, CrossbarForegroundService::class.java).apply {
                action = ACTION_STOP
            }
            val stopPendingIntent = PendingIntent.getService(
                context, 2, stopIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val builder = NotificationCompat.Builder(context, CHANNEL_ID)
                .setContentTitle(title)
                .setContentText(body)
                .setSmallIcon(R.drawable.ic_stat_crossbar)
                .setContentIntent(openPendingIntent)
                .setOngoing(true)
                .setAutoCancel(false)
                .setShowWhen(false)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setCategory(NotificationCompat.CATEGORY_SERVICE)
                .addAction(R.drawable.ic_refresh, context.getString(R.string.action_refresh), refreshPendingIntent)
                .addAction(R.drawable.ic_stop, context.getString(R.string.action_stop), stopPendingIntent)

            if (lines != null && lines.isNotEmpty()) {
                val inboxStyle = NotificationCompat.InboxStyle()
                    .setBigContentTitle(title)
                    .setSummaryText("${lines.size} plugin(s) active")
                for (line in lines.take(6)) {
                    inboxStyle.addLine(line)
                }
                builder.setStyle(inboxStyle)
            }

            val notification = builder.build()
            val svc = instance
            if (svc != null) {
                // startForeground() is the ONLY reliable way to update the notification
                Log.d(TAG, "updateContent: using startForeground (service alive)")
                svc.startForeground(NOTIFICATION_ID, notification)
            } else {
                // Service not yet started - use NotificationManager as fallback
                Log.w(TAG, "updateContent: service instance null, using nm.notify fallback")
                val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                nm.notify(NOTIFICATION_ID, notification)
            }
        }
    }

    private lateinit var notificationManager: NotificationManager

    override fun onCreate() {
        super.onCreate()
        instance = this
        Log.d(TAG, "Service created, instance stored")
        notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "Service started with action: ${intent?.action}")

        when (intent?.action) {
            ACTION_STOP -> {
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_REFRESH -> {
                val refreshIntent = Intent(this, MainActivity::class.java).apply {
                    action = "com.verseles.crossbar.ACTION_REFRESH"
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                }
                startActivity(refreshIntent)
                updateNotification()
                return START_STICKY
            }
        }

        // Initial foreground notification — Dart will overwrite this shortly
        startForeground(NOTIFICATION_ID, buildNotification())

        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        Log.d(TAG, "Service destroyed, clearing instance")
        instance = null
        val flutterPrefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        flutterPrefs.edit().putBoolean("flutter.show_in_tray", false).apply()
        super.onDestroy()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                getString(R.string.notification_channel_name),
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = getString(R.string.notification_channel_description)
                setShowBadge(false)
            }
            notificationManager.createNotificationChannel(channel)
            Log.d(TAG, "Notification channel created")
        }
    }

    private fun buildNotification(): Notification {
        val pluginCount = getActivePluginCount()

        val openIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openPendingIntent = PendingIntent.getActivity(
            this, 0, openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val refreshIntent = Intent(this, CrossbarForegroundService::class.java).apply {
            action = ACTION_REFRESH
        }
        val refreshPendingIntent = PendingIntent.getService(
            this, 1, refreshIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val stopIntent = Intent(this, CrossbarForegroundService::class.java).apply {
            action = ACTION_STOP
        }
        val stopPendingIntent = PendingIntent.getService(
            this, 2, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val contentText = resources.getQuantityString(
            R.plurals.notification_text_plugins,
            pluginCount,
            pluginCount
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(getString(R.string.notification_title))
            .setContentText(contentText)
            .setSmallIcon(R.drawable.ic_stat_crossbar)
            .setContentIntent(openPendingIntent)
            .setOngoing(true)
            .setAutoCancel(false)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .addAction(R.drawable.ic_refresh, getString(R.string.action_refresh), refreshPendingIntent)
            .addAction(R.drawable.ic_stop, getString(R.string.action_stop), stopPendingIntent)
            .build()
    }

    private fun updateNotification() {
        notificationManager.notify(NOTIFICATION_ID, buildNotification())
    }

    private fun getActivePluginCount(): Int {
        return try {
            val prefs = HomeWidgetPlugin.getData(this)
            val pluginIdsJson = prefs.getString("plugin_ids", null)
            if (pluginIdsJson != null) {
                val jsonArray = JSONArray(pluginIdsJson)
                jsonArray.length()
            } else {
                0
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error getting plugin count", e)
            0
        }
    }
}
