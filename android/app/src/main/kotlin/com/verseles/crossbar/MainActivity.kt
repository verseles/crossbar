package com.verseles.crossbar

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
        // Android 8+ blocks /proc/stat via SELinux
        // System-wide CPU monitoring is unavailable - return 0.0
        // Note: Dart layer will add "unavailable" message to status
        android.util.Log.d("Crossbar", "CPU monitoring unavailable on Android 8+ (SELinux blocks /proc/stat)")
        return 0.0
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
        if (intent?.action == "com.verseles.crossbar.ACTION_REFRESH") {
            android.util.Log.d("Crossbar", "Widget refresh requested")
            // Notify Flutter to refresh widgets via Method Channel
            flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                MethodChannel(messenger, CHANNEL).invokeMethod("onWidgetRefresh", null)
            }
        }
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
