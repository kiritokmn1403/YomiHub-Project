package com.kodjodevf.mangayomi

import android.app.Activity
import android.content.Context
import android.os.Handler
import android.os.Looper
import com.wireguard.android.backend.GoBackend
import com.wireguard.android.backend.Tunnel
import com.wireguard.config.Config
import de.blinkt.openvpn.OnVPNStatusChangeListener
import de.blinkt.openvpn.VPNHelper
import de.blinkt.openvpn.core.LogItem
import de.blinkt.openvpn.core.VpnStatus
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayInputStream
import java.util.concurrent.Executors

/**
 * YomiHub 0.1.4 VPN engines, native side (channel `yomihub/tunnels`):
 *
 *  - OpenVPN (ics-openvpn): .ovpn profiles, VPN Gate / SoftEther servers
 *    (SoftEther servers speak the OpenVPN protocol) and any OpenVPN provider.
 *  - WireGuard: user .conf profiles through wireguard-android's GoBackend
 *    (the same engine WARP uses; one tunnel at a time).
 *  - Xray (the core Mihon Proxy embeds): VLESS/REALITY, VMess, Trojan,
 *    Shadowsocks, run as a separate process (jniLibs/<abi>/libxray.so) and
 *    exposed as a local SOCKS + HTTP proxy YomiHub routes extensions through.
 */
class YomiTunnels(private val activity: Activity, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "yomihub/tunnels")
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private val ctx: Context = activity.applicationContext

    private var ovpn: VPNHelper? = null

    // OpenVPN log: kept for the UI (why a connection failed) and logcat.
    private val ovpnLog = ArrayDeque<String>()
    private val logListener = object : VpnStatus.LogListener {
        override fun newLog(logItem: LogItem?) {
            val line = try { logItem?.getString(ctx) } catch (_: Throwable) { null } ?: return
            android.util.Log.i("YomiOVPN", line)
            synchronized(ovpnLog) {
                ovpnLog.addLast(line)
                while (ovpnLog.size > 60) ovpnLog.removeFirst()
            }
        }
    }

    init {
        try { VpnStatus.addLogListener(logListener) } catch (_: Throwable) {}
    }
    private val backend: GoBackend by lazy { GoBackend(ctx) }
    private val wgTunnel = object : Tunnel {
        override fun getName(): String = "yomihub-wg"
        override fun onStateChange(newState: Tunnel.State) {
            main.post { channel.invokeMethod("wgState", newState == Tunnel.State.UP) }
        }
    }

    // ───────────── Xray (separate process) ─────────────
    private var xray: Process? = null

    private fun xrayBin() = java.io.File(ctx.applicationInfo.nativeLibraryDir, "libxray.so")

    /** Starts the Xray core with [config]; returns an error text or null. */
    private fun xrayStart(config: String): String? {
        xrayStop()
        val bin = xrayBin()
        if (!bin.exists()) return "Thiếu lõi Xray (libxray.so) cho kiến trúc máy này"
        val dir = java.io.File(ctx.filesDir, "xray").apply { mkdirs() }
        val cfg = java.io.File(dir, "config.json")
        cfg.writeText(config)
        val log = java.io.File(dir, "xray.log")
        return try {
            val pb = ProcessBuilder(bin.absolutePath, "run", "-c", cfg.absolutePath)
                .directory(dir)
                .redirectErrorStream(true)
                .redirectOutput(log)
            pb.environment()["XRAY_LOCATION_ASSET"] = dir.absolutePath
            val p = pb.start()
            xray = p
            // Give it a moment: a bad config makes it exit right away.
            Thread.sleep(1200)
            if (!alive(p)) {
                val text = try { log.readText().takeLast(600) } catch (_: Throwable) { "" }
                xray = null
                "Xray dừng ngay khi chạy: $text"
            } else null
        } catch (e: Throwable) {
            e.message ?: e.toString()
        }
    }

    /** Process.isAlive needs API 26; minSdk is 24. */
    private fun alive(p: Process): Boolean = try {
        p.exitValue()
        false
    } catch (_: IllegalThreadStateException) {
        true
    }

    private fun xrayStop() {
        try {
            xray?.destroy()
        } catch (_: Throwable) {
        }
        xray = null
    }

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "ovpnUp" -> {
                    val config = call.argument<String>("config") ?: ""
                    val user = call.argument<String>("username") ?: ""
                    val pass = call.argument<String>("password") ?: ""
                    val name = call.argument<String>("name") ?: "YomiHub"
                    val bypass = call.argument<List<String>>("bypass") ?: emptyList()
                    try {
                        val h = ovpn ?: VPNHelper(activity).also { helper ->
                            helper.setOnVPNStatusChangeListener(object : OnVPNStatusChangeListener {
                                override fun onVPNStatusChanged(status: String?) {
                                    main.post { channel.invokeMethod("ovpnState", status ?: "idle") }
                                }

                                override fun onConnectionStatusChanged(
                                    duration: String?,
                                    lastPacketReceive: String?,
                                    byteIn: String?,
                                    byteOut: String?,
                                ) {
                                    main.post {
                                        channel.invokeMethod(
                                            "ovpnTraffic",
                                            mapOf("duration" to duration, "in" to byteIn, "out" to byteOut),
                                        )
                                    }
                                }
                            })
                            ovpn = helper
                        }
                        h.startVPN(config, user, pass, name, ArrayList(bypass))
                        result.success(true)
                    } catch (e: Throwable) {
                        result.error("OVPN", e.message ?: e.toString(), null)
                    }
                }
                "ovpnLog" -> result.success(synchronized(ovpnLog) { ovpnLog.toList() })
                "ovpnDown" -> {
                    try {
                        ovpn?.stopVPN()
                    } catch (_: Throwable) {
                    }
                    result.success(true)
                }
                "wgUp" -> {
                    // YomiHub 0.4.3: wireguard-android needs API 24 (APK installs on 6.0)
                    if (android.os.Build.VERSION.SDK_INT < 24) {
                        result.error("WG", "WireGuard/WARP cần Android 7.0 trở lên – trên Android 6.0 hãy dùng Proxy hoặc DNS-over-HTTPS", null)
                        return@setMethodCallHandler
                    }
                    val conf = call.argument<String>("config") ?: ""
                    io.execute {
                        try {
                            val cfg = Config.parse(ByteArrayInputStream(conf.toByteArray()))
                            backend.setState(wgTunnel, Tunnel.State.UP, cfg)
                            main.post { result.success(true) }
                        } catch (e: Throwable) {
                            main.post { result.error("WG", e.message ?: e.toString(), null) }
                        }
                    }
                }
                "wgDown" -> io.execute {
                    try {
                        backend.setState(wgTunnel, Tunnel.State.DOWN, null)
                    } catch (_: Throwable) {
                    }
                    main.post { result.success(true) }
                }
                "xrayStart" -> {
                    val config = call.argument<String>("config") ?: ""
                    io.execute {
                        val err = xrayStart(config)
                        main.post {
                            if (err == null) result.success(true) else result.error("XRAY", err, null)
                        }
                    }
                }
                "xrayStop" -> {
                    xrayStop()
                    result.success(true)
                }
                "xrayRunning" -> result.success(xray?.let { alive(it) } == true)
                "xrayVersion" -> io.execute {
                    val v = try {
                        val p = ProcessBuilder(xrayBin().absolutePath, "version").redirectErrorStream(true).start()
                        val out = p.inputStream.bufferedReader().readText()
                        p.waitFor()
                        out.lines().firstOrNull() ?: ""
                    } catch (e: Throwable) {
                        ""
                    }
                    main.post { result.success(v) }
                }
                "torrc" -> {
                    // Extra torrc lines (exit country…), read by TorService on start.
                    val text = call.argument<String>("text") ?: ""
                    try {
                        val f = org.torproject.jni.TorService.getTorrc(ctx)
                        f.parentFile?.mkdirs()
                        f.writeText(text)
                        result.success(true)
                    } catch (e: Throwable) {
                        result.error("TORRC", e.message ?: e.toString(), null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
