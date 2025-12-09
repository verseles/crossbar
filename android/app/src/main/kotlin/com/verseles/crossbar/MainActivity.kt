package com.verseles.crossbar

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.io.RandomAccessFile

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.verseles.crossbar/system"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getBatteryLevel" -> {
                    val level = getBatteryLevel()
                    result.success(level)
                }
                "getBatteryStatus" -> {
                    val status = getBatteryStatus()
                    result.success(status)
                }
                "getCpuUsage" -> {
                    val cpu = getCpuUsage()
                    result.success(cpu)
                }
                "getMemoryInfo" -> {
                    val memory = getMemoryInfo()
                    result.success(memory)
                }
                "startForegroundService" -> {
                    startCrossbarForegroundService()
                    result.success(true)
                }
                "stopForegroundService" -> {
                    stopCrossbarForegroundService()
                    result.success(true)
                }
                "finishWidgetConfiguration" -> {
                    val appWidgetId = call.argument<Int>("appWidgetId")
                    if (appWidgetId != null) {
                        finishWidgetConfiguration(appWidgetId)
                        result.success(true)
                    } else {
                        result.error("INVALID_ID", "AppWidgetId is required", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getBatteryLevel(): Int {
        val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        return batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
    }

    private fun getBatteryStatus(): Map<String, Any> {
        val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        val level = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        
        val intent = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val status = intent?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
        val isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING ||
                         status == BatteryManager.BATTERY_STATUS_FULL

        return mapOf(
            "level" to level,
            "isCharging" to isCharging,
            "status" to when (status) {
                BatteryManager.BATTERY_STATUS_CHARGING -> "charging"
                BatteryManager.BATTERY_STATUS_DISCHARGING -> "discharging"
                BatteryManager.BATTERY_STATUS_FULL -> "full"
                BatteryManager.BATTERY_STATUS_NOT_CHARGING -> "not_charging"
                else -> "unknown"
            }
        )
    }

    private fun getCpuUsage(): Double {
        // Try to read /proc/stat (may fail on Android 8+)
        try {
            val reader = RandomAccessFile("/proc/stat", "r")
            val load = reader.readLine()
            reader.close()

            val toks = load.split(" ".toRegex()).filter { it.isNotEmpty() }
            if (toks.size >= 5) {
                val idle1 = toks[4].toLong()
                val cpu1 = toks[1].toLong() + toks[2].toLong() + toks[3].toLong() + toks[4].toLong() +
                          toks[5].toLong() + toks[6].toLong() + toks[7].toLong()

                Thread.sleep(100)

                val reader2 = RandomAccessFile("/proc/stat", "r")
                val load2 = reader2.readLine()
                reader2.close()

                val toks2 = load2.split(" ".toRegex()).filter { it.isNotEmpty() }
                if (toks2.size >= 5) {
                    val idle2 = toks2[4].toLong()
                    val cpu2 = toks2[1].toLong() + toks2[2].toLong() + toks2[3].toLong() + toks2[4].toLong() +
                              toks2[5].toLong() + toks2[6].toLong() + toks2[7].toLong()

                    val idleDiff = idle2 - idle1
                    val cpuDiff = cpu2 - cpu1

                    if (cpuDiff > 0) {
                        return ((cpuDiff - idleDiff).toDouble() / cpuDiff.toDouble()) * 100.0
                    }
                }
            }
        } catch (e: Exception) {
            android.util.Log.w("Crossbar", "Could not read CPU: ${e.message}")
        }
        return -1.0 // Indicates unavailable
    }

    private fun getMemoryInfo(): Map<String, Long> {
        val runtime = Runtime.getRuntime()
        val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as android.app.ActivityManager
        val memInfo = android.app.ActivityManager.MemoryInfo()
        activityManager.getMemoryInfo(memInfo)

        return mapOf(
            "totalMem" to memInfo.totalMem,
            "availMem" to memInfo.availMem,
            "usedMem" to (memInfo.totalMem - memInfo.availMem),
            "threshold" to memInfo.threshold,
            "lowMemory" to if (memInfo.lowMemory) 1L else 0L
        )
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Thread.setDefaultUncaughtExceptionHandler { thread, ex ->
            android.util.Log.e("Crossbar", "Uncaught exception", ex)
        }
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return

        if (intent.action == "com.verseles.crossbar.ACTION_REFRESH") {
            android.util.Log.d("Crossbar", "Widget refresh requested")
            // Notify Flutter to refresh widgets via Method Channel
            flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                MethodChannel(messenger, CHANNEL).invokeMethod("onWidgetRefresh", null)
            }
        } else if (intent.action == AppWidgetManager.ACTION_APPWIDGET_CONFIGURE) {
            val appWidgetId = intent.getIntExtra(
                AppWidgetManager.EXTRA_APPWIDGET_ID,
                AppWidgetManager.INVALID_APPWIDGET_ID
            )

            if (appWidgetId != AppWidgetManager.INVALID_APPWIDGET_ID) {
                // Determine widget type
                val appWidgetManager = AppWidgetManager.getInstance(this)
                val providerInfo = appWidgetManager.getAppWidgetInfo(appWidgetId)
                val providerClassName = providerInfo?.provider?.className ?: ""

                val type = when {
                    providerClassName.endsWith("CrossbarWidgetLarge") -> "large"
                    providerClassName.endsWith("CrossbarWidgetMedium") -> "medium"
                    else -> "small"
                }

                android.util.Log.d("Crossbar", "Configuring widget $appWidgetId of type $type")

                // Notify Flutter to open configuration screen
                flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                    MethodChannel(messenger, CHANNEL).invokeMethod("configureWidget", mapOf(
                        "appWidgetId" to appWidgetId,
                        "type" to type
                    ))
                }
            }
        }
    }

    private fun finishWidgetConfiguration(appWidgetId: Int) {
        val resultValue = Intent()
        resultValue.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        setResult(RESULT_OK, resultValue)

        // Update the widget immediately
        val appWidgetManager = AppWidgetManager.getInstance(this)
        val intent = Intent(this, CrossbarWidgetLarge::class.java)
        intent.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
        intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(appWidgetId))
        sendBroadcast(intent)

        finish()
    }

    private fun startCrossbarForegroundService() {
        try {
            val serviceIntent = Intent(this, CrossbarForegroundService::class.java)
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                startForegroundService(serviceIntent)
            } else {
                startService(serviceIntent)
            }
            android.util.Log.d("Crossbar", "Foreground service started")
        } catch (e: Exception) {
            android.util.Log.e("Crossbar", "Failed to start foreground service", e)
        }
    }

    private fun stopCrossbarForegroundService() {
        try {
            val serviceIntent = Intent(this, CrossbarForegroundService::class.java)
            stopService(serviceIntent)
            android.util.Log.d("Crossbar", "Foreground service stopped")
        } catch (e: Exception) {
            android.util.Log.e("Crossbar", "Failed to stop foreground service", e)
        }
    }
}
