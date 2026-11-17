package com.kodjodevf.mangayomi

import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.OutcomeReceiver
import android.os.ext.SdkExtensions
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.time.Instant
import java.time.ZoneId
import java.util.concurrent.Executors

/**
 * YomiHub 0.4.4: native side of `com.yomihub/health_connect`.
 *
 * Until 0.4.3 the Dart service called this channel but nothing answered on
 * Android, so every check logged `MissingPluginException` (logs 1.txt,
 * 29/10/2026) and Health Connect never worked.
 *
 * Uses the platform Health Connect API (android.health.connect, Android 14+)
 * so no extra Jetpack library has to be bundled. Reading/watching time is
 * written as a MindfulnessSessionRecord (needs Health Connect SDK extension
 * 15, i.e. Android 16 or an updated Android 14/15). On Android 9–13 Health
 * Connect is a separate app: availability and its settings page work there,
 * writing records is reported as unsupported instead of failing silently.
 */
class YomiHealth(private val activity: Activity, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "com.yomihub/health_connect")
    private val io = Executors.newSingleThreadExecutor()
    private val writePerm = "android.permission.health.WRITE_MINDFULNESS"

    init {
        channel.setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "isAvailable" -> result.success(isAvailable())
                    "status" -> result.success(status())
                    "openSettings" -> result.success(openSettings())
                    "requestPermission" -> result.success(requestPermission())
                    "syncSession" -> syncSession(
                        (call.argument<Number>("minutes") ?: 0).toLong(),
                        (call.argument<Number>("timestamp") ?: System.currentTimeMillis()).toLong(),
                        result
                    )
                    else -> result.notImplemented()
                }
            } catch (e: Throwable) {
                result.error("HEALTH", e.message ?: e.toString(), null)
            }
        }
    }

    private fun platformApi(): Boolean = Build.VERSION.SDK_INT >= 34

    private fun hcAppInstalled(): Boolean = try {
        activity.packageManager.getPackageInfo("com.google.android.apps.healthdata", 0); true
    } catch (_: Exception) { false }

    private fun isAvailable(): Boolean =
        if (platformApi()) activity.getSystemService("healthconnect") != null
        else Build.VERSION.SDK_INT >= 28 && hcAppInstalled()

    private fun canWriteMindfulness(): Boolean =
        Build.VERSION.SDK_INT >= 36 ||
            (Build.VERSION.SDK_INT >= 34 &&
                SdkExtensions.getExtensionVersion(Build.VERSION_CODES.UPSIDE_DOWN_CAKE) >= 15)

    private fun granted(): Boolean =
        platformApi() && activity.checkSelfPermission(writePerm) == PackageManager.PERMISSION_GRANTED

    private fun status(): Map<String, Any> = mapOf(
        "available" to isAvailable(),
        "platformApi" to platformApi(),
        "canWrite" to canWriteMindfulness(),
        "granted" to granted(),
        "sdk" to Build.VERSION.SDK_INT
    )

    private fun openSettings(): Boolean {
        val actions = if (platformApi())
            listOf("android.health.connect.action.HEALTH_HOME_SETTINGS",
                "android.health.connect.action.MANAGE_HEALTH_PERMISSIONS")
        else listOf("androidx.health.ACTION_HEALTH_CONNECT_SETTINGS")
        for (a in actions) {
            try {
                val i = Intent(a)
                if (a.endsWith("MANAGE_HEALTH_PERMISSIONS")) i.putExtra(Intent.EXTRA_PACKAGE_NAME, activity.packageName)
                activity.startActivity(i); return true
            } catch (_: Exception) {}
        }
        if (!platformApi()) {
            try {
                activity.startActivity(Intent(Intent.ACTION_VIEW,
                    Uri.parse("market://details?id=com.google.android.apps.healthdata")))
                return true
            } catch (_: Exception) {}
        }
        return false
    }

    private fun requestPermission(): Boolean {
        if (!platformApi() || !canWriteMindfulness()) return false
        if (granted()) return true
        activity.requestPermissions(arrayOf(writePerm), 7431)
        return false
    }

    private fun syncSession(minutes: Long, endMs: Long, result: MethodChannel.Result) {
        if (minutes <= 0) { result.success(false); return }
        if (!platformApi() || !canWriteMindfulness()) {
            result.error("UNSUPPORTED", "Thiết bị chưa hỗ trợ ghi phiên vào Health Connect (cần Android 14+ có Health Connect bản mới)", null)
            return
        }
        if (!granted()) {
            result.error("PERMISSION", "Chưa cấp quyền ghi \"Chánh niệm\" cho YomiHub trong Health Connect", null)
            return
        }
        writeMindfulness(minutes, endMs, result)
    }

    @android.annotation.SuppressLint("NewApi")
    private fun writeMindfulness(minutes: Long, endMs: Long, result: MethodChannel.Result) {
        val hc = activity.getSystemService(android.health.connect.HealthConnectManager::class.java)
        if (hc == null) { result.error("UNAVAILABLE", "Health Connect không khả dụng", null); return }
        val end = Instant.ofEpochMilli(endMs)
        val start = end.minusSeconds(minutes * 60)
        val zone = ZoneId.systemDefault().rules.getOffset(end)
        val meta = android.health.connect.datatypes.Metadata.Builder()
            .setClientRecordId("yomihub-$endMs")
            .build()
        val rec = android.health.connect.datatypes.MindfulnessSessionRecord.Builder(
            meta, start, end,
            android.health.connect.datatypes.MindfulnessSessionRecord.MINDFULNESS_SESSION_TYPE_OTHER
        ).setTitle("YomiHub").setStartZoneOffset(zone).setEndZoneOffset(zone).build()
        hc.insertRecords(listOf<android.health.connect.datatypes.Record>(rec), io,
            object : OutcomeReceiver<android.health.connect.InsertRecordsResponse,
                android.health.connect.HealthConnectException> {
                override fun onResult(r: android.health.connect.InsertRecordsResponse) {
                    activity.runOnUiThread { result.success(true) }
                }
                override fun onError(e: android.health.connect.HealthConnectException) {
                    activity.runOnUiThread { result.error("HEALTH", e.message ?: e.toString(), null) }
                }
            })
    }
}
