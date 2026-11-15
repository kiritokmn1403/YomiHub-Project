package com.kodjodevf.mangayomi

import androidx.annotation.NonNull
import libmtorrentserver.Libmtorrentserver
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec
import io.flutter.embedding.android.FlutterFragmentActivity
import androidx.core.content.FileProvider
import android.app.UiModeManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.os.Build
import android.net.Uri
import java.io.File
import android.app.PictureInPictureParams
import android.util.Rational

class MainActivity: FlutterFragmentActivity() {

    // YomiHub 0.5.7 (P8F-2): "video has sound but a black picture" on the
    // Galaxy Note 9 (Android 10, Exynos 9810 / Mali-G72). mpv decoded and
    // rendered every frame (its own window screenshot showed the film), the
    // picture was lost afterwards: from Android 10 on Flutter backs video
    // textures with ImageReader / HardwareBuffer, which is defective on some
    // Android <= 10 devices (Flutter itself already avoids it for Huawei
    // <= API 29, flutter/flutter#166481, #156459, #154068). On Android <= 10
    // YomiHub therefore uses the classic SurfaceTexture path for every
    // device. SurfaceTexture is only defined for the OpenGL renderers, so
    // Impeller (which may pick Vulkan) is switched off there as well - the
    // same renderer Android 9 and older already get.
    private fun yhUseLegacyVideoTextures() {
        if (Build.VERSION.SDK_INT > 29) return
        try {
            val f = Class.forName("io.flutter.embedding.engine.renderer.FlutterRenderer")
                .getField("debugForceSurfaceProducerGlTextures")
            f.setBoolean(null, true)
            if (intent != null && !intent.hasExtra("enable-impeller")) {
                intent.putExtra("enable-impeller", false)
            }
            android.util.Log.i("YomiHub", "Android <= 10: SurfaceTexture video textures, Impeller off")
        } catch (e: Throwable) {
            android.util.Log.w("YomiHub", "legacy video textures not available: $e")
        }
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        // must run before super.onCreate(): the Flutter fragment reads the
        // shell arguments from the intent when it is created.
        yhUseLegacyVideoTextures()
        super.onCreate(savedInstanceState)
    }

    // YomiHub 0.1.8: system Picture-in-Picture for the web player (servers
    // that only play in the site's own player, e.g. AVSub DU/HDX). The mpv
    // player keeps using the media_kit PiP controller.
    private var pipChannel: MethodChannel? = null
    private var webPipAuto = false
    private var webPipW = 16
    private var webPipH = 9

    private fun pipParams(): PictureInPictureParams? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return null
        var w = webPipW.coerceAtLeast(1); var h = webPipH.coerceAtLeast(1)
        // Android only accepts ratios between 1:2.39 and 2.39:1
        val r = w.toDouble() / h
        if (r > 2.39) { w = 239; h = 100 } else if (r < 1 / 2.39) { w = 100; h = 239 }
        val b = PictureInPictureParams.Builder().setAspectRatio(Rational(w, h))
        if (Build.VERSION.SDK_INT >= 31) {
            b.setAutoEnterEnabled(webPipAuto)
            b.setSeamlessResizeEnabled(true)
        }
        return b.build()
    }

    private fun enterWebPip(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        if (!packageManager.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)) return false
        return try { enterPictureInPictureMode(pipParams()!!) } catch (e: Exception) { false }
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        if (webPipAuto && Build.VERSION.SDK_INT in Build.VERSION_CODES.O until 31) enterWebPip()
    }

    // YomiHub 0.2.3: give memory back before the system kills the app
    override fun onTrimMemory(level: Int) {
        super.onTrimMemory(level)
        if (level >= android.content.ComponentCallbacks2.TRIM_MEMORY_RUNNING_LOW) {
            try { YomiKotatsu.trim(level >= android.content.ComponentCallbacks2.TRIM_MEMORY_RUNNING_CRITICAL) } catch (_: Throwable) {}
        }
    }

    override fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean, newConfig: Configuration) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        try { pipChannel?.invokeMethod("pipChanged", isInPictureInPictureMode) } catch (_: Exception) {}
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // YomiHub: Tor + Cloudflare WARP ("VPN" settings section)
        YomiVpn(this, flutterEngine.dartExecutor.binaryMessenger)
        // YomiHub 0.1.4: OpenVPN / SoftEther (VPN Gate), WireGuard, Xray
        YomiTunnels(this, flutterEngine.dartExecutor.binaryMessenger)
        // YomiHub 0.1.4: Firefox (GeckoView) engine for the in-app browser
        YomiGecko.register(this, flutterEngine)
        // YomiHub 0.1.4: Kotatsu parsers (kotatsu-multi-parsers) bridge
        YomiKotatsu.register(this, flutterEngine.dartExecutor.binaryMessenger)
        YomiIReader.register(this, flutterEngine.dartExecutor.binaryMessenger)
        YomiOcr.register(flutterEngine.dartExecutor.binaryMessenger)
        // YomiHub: PDF reader + AirDrop & Quicksharing helpers
        YomiTools(this, flutterEngine.dartExecutor.binaryMessenger)
        // YomiHub 0.2.0: Bluetooth send / receive (AirDrop & Quicksharing)
        YomiBluetooth(this, flutterEngine.dartExecutor.binaryMessenger)
        YomiHealth(this, flutterEngine.dartExecutor.binaryMessenger) // 0.4.4
        pipChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "yomihub/web_pip").also { ch ->
            ch.setMethodCallHandler { call, result ->
                when (call.method) {
                    "supported" -> result.success(
                        Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                            packageManager.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE))
                    "setup" -> {
                        webPipAuto = call.argument<Boolean>("auto") ?: false
                        webPipW = call.argument<Int>("w") ?: 16
                        webPipH = call.argument<Int>("h") ?: 9
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            try { setPictureInPictureParams(pipParams()!!) } catch (_: Exception) {}
                        }
                        result.success(true)
                    }
                    "enter" -> result.success(enterWebPip())
                    "inPip" -> result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.N && isInPictureInPictureMode)
                    else -> result.notImplemented()
                }
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.kodjodevf.mangayomi.libmtorrentserver",
            StandardMethodCodec.INSTANCE,
            flutterEngine.dartExecutor.binaryMessenger.makeBackgroundTaskQueue()
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    val config = call.argument<String>("config")
                    try {
                        val port = Libmtorrentserver.start(config)
                        result.success(port)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.kodjodevf.mangayomi.apk_install",
            StandardMethodCodec.INSTANCE,
            flutterEngine.dartExecutor.binaryMessenger.makeBackgroundTaskQueue()
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "installApk" -> {
                    val filePath = call.argument<String>("filePath")
                    installApk(filePath)
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.kodjodevf.mangayomi.device",
            StandardMethodCodec.INSTANCE
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isTv" -> {
                    result.success(isTvDevice())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    // Reports whether this is an Android TV / leanback device. Used by the
    // Dart side to branch the UI on form factor (see #729). Kept conservative
    // so a phone is never misdetected as a TV: a phone has neither the
    // television UI mode nor the leanback feature.
    private fun isTvDevice(): Boolean {
        val uiModeManager = getSystemService(Context.UI_MODE_SERVICE) as? UiModeManager
        if (uiModeManager?.currentModeType == Configuration.UI_MODE_TYPE_TELEVISION) {
            return true
        }
        return packageManager.hasSystemFeature(PackageManager.FEATURE_LEANBACK)
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (YomiVpn.onActivityResult(requestCode, resultCode)) return
        super.onActivityResult(requestCode, resultCode, data)
    }

    private fun installApk(filePath: String?) {
        if (filePath == null) return
        val file = File(filePath)
        val intent = Intent(Intent.ACTION_VIEW)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        val apkUri: Uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            intent.flags = Intent.FLAG_GRANT_READ_URI_PERMISSION
            FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
        } else {
            Uri.fromFile(file)
        }
        intent.setDataAndType(apkUri, "application/vnd.android.package-archive")
        startActivity(intent)
    }
}
