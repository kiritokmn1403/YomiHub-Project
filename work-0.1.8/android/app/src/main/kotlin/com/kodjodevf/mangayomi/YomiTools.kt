package com.kodjodevf.mangayomi

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.pdf.PdfRenderer
import android.net.Uri
import android.net.wifi.WifiManager
import android.os.Build
import android.os.ParcelFileDescriptor
import androidx.core.content.FileProvider
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.concurrent.atomic.AtomicInteger

/**
 * YomiHub tools, native side:
 *  - PDF reader backed by android.graphics.pdf.PdfRenderer (API 21+, no extra
 *    library, so the APK stays small).
 *  - AirDrop & Quicksharing: hand files to Google Quick Share (Nearby Share),
 *    Samsung Quick Share, or the system share sheet; keep Wi-Fi multicast on
 *    while the LAN receiver is discoverable.
 */
class YomiTools(private val activity: Activity, messenger: BinaryMessenger) {
    private class Doc(val pfd: ParcelFileDescriptor, val renderer: PdfRenderer)
    private val docs = HashMap<Int, Doc>()
    private val ids = AtomicInteger(1)
    private var multicastLock: WifiManager.MulticastLock? = null

    init {
        MethodChannel(
            messenger, "com.yomihub/tools", StandardMethodCodec.INSTANCE,
            messenger.makeBackgroundTaskQueue()
        ).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    // YomiHub 0.1.7: free / total space for "Thư mục cục bộ"
                    "diskSpace" -> {
                        var f = File(call.argument<String>("path")!!)
                        while (!f.exists() && f.parentFile != null) f = f.parentFile!!
                        val st = android.os.StatFs(f.path)
                        result.success(mapOf("free" to st.availableBytes, "total" to st.totalBytes))
                    }
                    "pdfOpen" -> {
                        val path = call.argument<String>("path")!!
                        val pfd = ParcelFileDescriptor.open(File(path), ParcelFileDescriptor.MODE_READ_ONLY)
                        val r = PdfRenderer(pfd)
                        val id = ids.getAndIncrement()
                        synchronized(docs) { docs[id] = Doc(pfd, r) }
                        val sizes = ArrayList<Double>()
                        synchronized(r) {
                            for (i in 0 until r.pageCount) {
                                r.openPage(i).use { p -> sizes.add(p.width.toDouble()); sizes.add(p.height.toDouble()) }
                            }
                        }
                        result.success(mapOf("id" to id, "pages" to r.pageCount, "sizes" to sizes))
                    }
                    "pdfRender" -> {
                        val id = call.argument<Int>("id")!!
                        val index = call.argument<Int>("page")!!
                        val width = (call.argument<Int>("width") ?: 1080).coerceIn(200, 4096)
                        val doc = synchronized(docs) { docs[id] } ?: throw IllegalStateException("closed")
                        val bytes = synchronized(doc.renderer) {
                            doc.renderer.openPage(index).use { page ->
                                val h = (width.toDouble() * page.height / page.width).toInt().coerceAtLeast(1)
                                val bmp = Bitmap.createBitmap(width, h, Bitmap.Config.ARGB_8888)
                                bmp.eraseColor(Color.WHITE)
                                page.render(bmp, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                                val out = ByteArrayOutputStream()
                                bmp.compress(Bitmap.CompressFormat.JPEG, 90, out)
                                bmp.recycle()
                                out.toByteArray()
                            }
                        }
                        result.success(bytes)
                    }
                    "pdfClose" -> {
                        val id = call.argument<Int>("id")!!
                        val doc = synchronized(docs) { docs.remove(id) }
                        if (doc != null) synchronized(doc.renderer) { doc.renderer.close(); doc.pfd.close() }
                        result.success(null)
                    }
                    "share" -> {
                        val paths = call.argument<List<String>>("paths") ?: emptyList()
                        val target = call.argument<String>("target") ?: "system"
                        result.success(share(paths, call.argument<String>("text"), target))
                    }
                    "targets" -> result.success(mapOf(
                        "google" to hasActivity(GOOGLE_QS),
                        "samsung" to isInstalled(SAMSUNG_QS_PKG)
                    ))
                    "multicast" -> {
                        val on = call.argument<Boolean>("on") ?: false
                        setMulticast(on)
                        result.success(null)
                    }
                    "deviceName" -> result.success(
                        (android.provider.Settings.Global.getString(activity.contentResolver, "device_name")
                            ?: "${Build.MANUFACTURER} ${Build.MODEL}")
                    )
                    // YomiHub 0.1.5: microG (Settings › microG)
                    "microgStatus" -> result.success(microgStatus())
                    "openComponent" -> {
                        val pkg = call.argument<String>("package")!!
                        val cls = call.argument<String>("class")
                        val ok = try {
                            val i = if (cls != null) Intent().setComponent(ComponentName(pkg, cls))
                            else activity.packageManager.getLaunchIntentForPackage(pkg)
                            if (i == null) false else {
                                i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                activity.startActivity(i); true
                            }
                        } catch (e: Exception) { false }
                        result.success(ok)
                    }
                    "openAppInfo" -> {
                        val pkg = call.argument<String>("package")!!
                        val ok = try {
                            activity.startActivity(
                                Intent(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$pkg"))
                                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            ); true
                        } catch (e: Exception) { false }
                        result.success(ok)
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Throwable) {
                result.error("YH_TOOLS", e.message ?: e.toString(), null)
            }
        }
    }

    companion object {
        val GOOGLE_QS = ComponentName("com.google.android.gms", "com.google.android.gms.nearby.sharing.ShareSheetActivity")
        const val SAMSUNG_QS_PKG = "com.samsung.android.app.sharelive"
    }

    private fun isInstalled(pkg: String): Boolean = try {
        activity.packageManager.getPackageInfo(pkg, 0); true
    } catch (e: Exception) { false }

    private fun hasActivity(c: ComponentName): Boolean = try {
        activity.packageManager.getActivityInfo(c, 0); true
    } catch (e: Exception) { false }

    private fun uriFor(f: File): Uri =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N)
            FileProvider.getUriForFile(activity, "${activity.packageName}.fileprovider", f)
        else Uri.fromFile(f)

    private fun share(paths: List<String>, text: String?, target: String): String {
        val uris = ArrayList<Uri>(paths.map { uriFor(File(it)) })
        val intent = if (uris.size > 1) Intent(Intent.ACTION_SEND_MULTIPLE).apply {
            putParcelableArrayListExtra(Intent.EXTRA_STREAM, uris)
        } else Intent(Intent.ACTION_SEND).apply {
            if (uris.isNotEmpty()) putExtra(Intent.EXTRA_STREAM, uris[0])
        }
        intent.type = if (uris.isEmpty()) "text/plain" else "*/*"
        if (text != null) intent.putExtra(Intent.EXTRA_TEXT, text)
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        when (target) {
            "google" -> intent.component = GOOGLE_QS
            "samsung" -> intent.setPackage(SAMSUNG_QS_PKG)
        }
        return try {
            activity.runOnUiThread {
                try {
                    if (target == "system") activity.startActivity(Intent.createChooser(intent, "Chia sẻ qua"))
                    else activity.startActivity(intent)
                } catch (e: ActivityNotFoundException) {
                    intent.component = null; intent.setPackage(null)
                    activity.startActivity(Intent.createChooser(intent, "Chia sẻ qua"))
                }
            }
            "ok"
        } catch (e: Exception) { e.message ?: "error" }
    }

    private fun setMulticast(on: Boolean) {
        val wm = activity.applicationContext.getSystemService(android.content.Context.WIFI_SERVICE) as? WifiManager ?: return
        if (on) {
            if (multicastLock == null) multicastLock = wm.createMulticastLock("yomihub-share").apply { setReferenceCounted(false) }
            multicastLock?.acquire()
        } else {
            multicastLock?.release()
        }
    }

    /** Installed microG / Google components and what they are. */
    private fun microgStatus(): Map<String, Any?> {
        val pm = activity.packageManager
        fun info(pkg: String): Map<String, Any?>? = try {
            @Suppress("DEPRECATION")
            val pi = pm.getPackageInfo(pkg, android.content.pm.PackageManager.GET_ACTIVITIES)
            val acts = pi.activities?.map { it.name } ?: emptyList()
            mapOf(
                "package" to pkg,
                "version" to (pi.versionName ?: ""),
                "enabled" to (pi.applicationInfo?.enabled ?: true),
                "microg" to acts.any { it.startsWith("org.microg.") },
                "activities" to acts.filter { it.startsWith("org.microg.") }.take(60),
            )
        } catch (e: Exception) { null }
        val spoof = try {
            pm.checkPermission("android.permission.FAKE_PACKAGE_SIGNATURE", "com.google.android.gms") ==
                android.content.pm.PackageManager.PERMISSION_GRANTED
        } catch (e: Exception) { false }
        return mapOf(
            "gms" to info("com.google.android.gms"),
            "vending" to info("com.android.vending"),
            "gsf" to info("com.google.android.gsf"),
            "droidguard" to info("org.microg.gms.droidguard"),
            "nlpBackend" to info("org.microg.nlp.backend.ichnaea"),
            "signatureSpoofing" to spoof,
            "sdk" to Build.VERSION.SDK_INT,
        )
    }
}
