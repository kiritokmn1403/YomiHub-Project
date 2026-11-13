package com.kodjodevf.mangayomi

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.ServiceConnection
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.net.VpnService
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import com.wireguard.android.backend.GoBackend
import com.wireguard.android.backend.Tunnel
import com.wireguard.config.Config
import com.wireguard.crypto.KeyPair
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import org.torproject.jni.TorService
import java.io.ByteArrayInputStream
import java.util.concurrent.Executors

/**
 * YomiHub "VPN" section, native side.
 *
 *  - Tor: runs the tor-android daemon inside the app and exposes its SOCKS and
 *    HTTP-tunnel ports, which the Dart side routes chosen sources through.
 *  - WARP: a WireGuard tunnel (wireguard-android GoBackend) to Cloudflare WARP,
 *    applied through Android's VpnService either to YomiHub only, to the apps
 *    the user picked, or to the whole device.
 */
class YomiVpn(private val activity: Activity, messenger: BinaryMessenger) {
    companion object {
        const val VPN_REQUEST = 7341
        private var instance: YomiVpn? = null
        fun onActivityResult(requestCode: Int, resultCode: Int): Boolean {
            if (requestCode != VPN_REQUEST) return false
            instance?.pendingPrepare?.let { r ->
                instance?.pendingPrepare = null
                r.success(resultCode == Activity.RESULT_OK)
            }
            return true
        }
    }

    private val channel = MethodChannel(messenger, "yomihub/vpn")
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private val ctx: Context = activity.applicationContext

    private var torService: TorService? = null
    private var torStatus: String = TorService.STATUS_OFF
    private var torWaiters = mutableListOf<MethodChannel.Result>()
    private var pendingPrepare: MethodChannel.Result? = null

    private val backend: GoBackend by lazy { GoBackend(ctx) }
    private val warpTunnel = object : Tunnel {
        override fun getName(): String = "yomihub-warp"
        override fun onStateChange(newState: Tunnel.State) {
            main.post { channel.invokeMethod("warpState", newState == Tunnel.State.UP) }
        }
    }

    private val torReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val status = intent?.getStringExtra(TorService.EXTRA_STATUS) ?: return
            if (torDormant && status == TorService.STATUS_ON) return
            torStatus = status
            main.post { channel.invokeMethod("torStatus", status) }
            if (status == TorService.STATUS_ON) flushTorWaiters()
        }
    }

    private val torConnection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
            torService = (service as? TorService.LocalBinder)?.service
            if (bridgeMode.isNotEmpty() || bridgeApplied.isNotEmpty()) startBridgeWatcher()
        }

        override fun onServiceDisconnected(name: ComponentName?) {
            torService = null
        }
    }

    init {
        instance = this
        LocalBroadcastManager.getInstance(ctx)
            .registerReceiver(torReceiver, IntentFilter(TorService.ACTION_STATUS))
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "torStart" -> torStart(result)
                "torStop" -> {
                    torStop(); result.success(true)
                }
                "torStatus" -> result.success(torInfo())
                "torDiag" -> io.execute {
                    // 0.4.5: proof of the path tor really uses (bridge or relay)
                    val c = torService?.torControlConnection
                    val m = try {
                        val built = (c?.getInfo("circuit-status") ?: "").lines().firstOrNull { it.contains(" BUILT ") } ?: ""
                        mapOf(
                            "useBridges" to (c?.getConf("UseBridges")?.firstOrNull()?.value ?: ""),
                            "bridges" to (c?.getConf("Bridge")?.size ?: 0),
                            "firstHop" to (built.split(" ").getOrNull(2)?.split(",")?.firstOrNull() ?: ""),
                            "bootstrap" to (c?.getInfo("status/bootstrap-phase") ?: ""),
                            "applied" to bridgeApplied,
                        )
                    } catch (e: Exception) { mapOf("error" to "${e.message}") }
                    main.post { result.success(m) }
                }
                "torBridges" -> {
                    // 0.4.5: bridge mode + bridge lines (pt_config.json of the Tor
                    // Expert Bundle, sent by Dart). Applied live over the control port.
                    bridgeMode = call.argument<String>("mode") ?: ""
                    @Suppress("UNCHECKED_CAST")
                    bridgeLines = (call.argument<Map<String, List<String>>>("lines") ?: emptyMap())
                    if (torService != null && !torDormant) startBridgeWatcher()
                    result.success(true)
                }
                "jvmProxy" -> {
                    setJvmProxy(call.argument<String>("url") ?: ""); result.success(true)
                }
                "torExitNodes" -> {
                    val cc = (call.argument<String>("country") ?: "").lowercase()
                    io.execute {
                        val ok = try {
                            val c = torService?.torControlConnection
                            if (c != null) {
                                if (cc.isEmpty()) {
                                    c.resetConf(listOf("ExitNodes", "StrictNodes"))
                                } else {
                                    c.setConf("ExitNodes", "{$cc}")
                                    c.setConf("StrictNodes", "0")
                                }
                                c.signal("NEWNYM")
                                true
                            } else false
                        } catch (e: Exception) {
                            false
                        }
                        main.post { result.success(ok) }
                    }
                }
                "torNewIdentity" -> io.execute {
                    val ok = try {
                        torService?.torControlConnection?.signal("NEWNYM"); true
                    } catch (e: Exception) {
                        false
                    }
                    main.post { result.success(ok) }
                }
                "vpnPrepare" -> vpnPrepare(result)
                "warpKeyPair" -> {
                    val kp = KeyPair()
                    result.success(
                        mapOf(
                            "private" to kp.privateKey.toBase64(),
                            "public" to kp.publicKey.toBase64()
                        )
                    )
                }
                "warpUp" -> {
                    // YomiHub 0.4.3: wireguard-android needs API 24 (APK installs on 6.0)
                    if (android.os.Build.VERSION.SDK_INT < 24) {
                        result.error("WG", "WireGuard/WARP cần Android 7.0 trở lên – trên Android 6.0 hãy dùng Proxy hoặc DNS-over-HTTPS", null)
                        return@setMethodCallHandler
                    }
                    val conf = call.argument<String>("config") ?: ""
                    io.execute {
                        try {
                            val cfg = Config.parse(ByteArrayInputStream(conf.toByteArray()))
                            backend.setState(warpTunnel, Tunnel.State.UP, cfg)
                            main.post { result.success(true) }
                        } catch (e: Exception) {
                            main.post { result.error("WARP", e.message ?: e.toString(), null) }
                        }
                    }
                }
                "warpDown" -> io.execute {
                    try {
                        backend.setState(warpTunnel, Tunnel.State.DOWN, null)
                    } catch (_: Exception) {
                    }
                    main.post { result.success(true) }
                }
                "warpState" -> io.execute {
                    val up = try {
                        backend.getState(warpTunnel) == Tunnel.State.UP
                    } catch (_: Exception) {
                        false
                    }
                    main.post { result.success(up) }
                }
                "installedApps" -> io.execute {
                    val apps = if (call.argument<Boolean>("all") == true) listAllPackages() else listApps()
                    main.post { result.success(apps) }
                }
                "packageName" -> result.success(ctx.packageName)
                // YomiHub 0.1.6: Tor for other apps / the whole device.
                "torVpnStart" -> {
                    val apps = ArrayList(call.argument<List<String>>("apps") ?: emptyList())
                    val port = call.argument<Int>("socksPort") ?: (torService?.socksPort ?: 9050)
                    YomiTorVpnService.listener = { up ->
                        main.post { channel.invokeMethod("torVpnState", mapOf("up" to up, "error" to YomiTorVpnService.lastError)) }
                    }
                    val i = Intent(ctx, YomiTorVpnService::class.java)
                        .setAction(YomiTorVpnService.ACTION_START)
                        .putExtra("socksPort", port)
                        .putStringArrayListExtra("apps", apps)
                    try {
                        ctx.startService(i); result.success(true)
                    } catch (e: Exception) {
                        result.error("TORVPN", e.message, null)
                    }
                }
                "torVpnStop" -> {
                    try {
                        ctx.startService(Intent(ctx, YomiTorVpnService::class.java).setAction(YomiTorVpnService.ACTION_STOP))
                    } catch (_: Exception) {
                    }
                    result.success(true)
                }
                "torVpnState" -> result.success(mapOf("up" to YomiTorVpnService.running, "error" to YomiTorVpnService.lastError))
                else -> result.notImplemented()
            }
        }
    }

    private fun torInfo(): Map<String, Any?> = mapOf(
        "status" to torStatus,
        "socksPort" to (torService?.socksPort ?: 0),
        "httpPort" to (torService?.httpTunnelPort ?: 0),
        // 0.4.4: last bootstrap phase, shown when tor is slow / blocked
        "bootstrap" to (if (torStatus == TorService.STATUS_ON) "" else torBoot),
        // 0.4.5: pluggable transport in use ("" = direct)
        "bridge" to bridgeApplied
    )

    // ───────────── 0.4.5: Tor bridges (lyrebird) ─────────────
    // 30/10/2026 Xiaomi 15T: tor stopped at 50 % "Loading relay descriptors"
    // for > 5 min – the network blocks Tor relays. tor-android has no
    // pluggable transports; IPtProxy cannot be bundled (its gomobile
    // libgojni.so clashes with libmtorrentserver). The Tor Expert Bundle 16.0
    // for Android ships `lyrebird` as a standalone PIE executable: it is
    // packaged as jniLibs/<abi>/liblyrebird.so (extracted, useLegacyPackaging)
    // and tor starts it itself through ClientTransportPlugin … exec.
    @Volatile private var bridgeMode = "auto"
    @Volatile private var bridgeLines: Map<String, List<String>> = emptyMap()
    @Volatile private var bridgeApplied = ""
    @Volatile private var bridgeWatcher: Thread? = null

    private fun lyrebird(): java.io.File = java.io.File(ctx.applicationInfo.nativeLibraryDir, "liblyrebird.so")

    private fun applyBridge(kind: String): Boolean {
        val c = torService?.torControlConnection ?: return false
        return try {
            if (kind.isEmpty()) {
                if (bridgeApplied.isNotEmpty()) c.setConf("UseBridges", "0")
                bridgeApplied = ""
                true
            } else {
                val lines = bridgeLines[kind].orEmpty()
                val lyre = lyrebird()
                if (lines.isEmpty() || !lyre.exists()) return false
                val conf = mutableListOf(
                    "ClientTransportPlugin meek_lite,obfs2,obfs3,obfs4,scramblesuit,webtunnel,snowflake exec ${lyre.absolutePath}",
                )
                lines.forEach { conf.add("Bridge $it") }
                conf.add("UseBridges 1")
                c.setConf(conf)
                bridgeApplied = kind
                main.post { channel.invokeMethod("torBridge", kind) }
                true
            }
        } catch (e: Exception) {
            main.post { channel.invokeMethod("torBridgeError", "$kind: ${e.message}") }
            false
        }
    }

    private fun bootPercent(): Int = try {
        val p = torService?.torControlConnection?.getInfo("status/bootstrap-phase") ?: ""
        torBoot = p
        Regex("PROGRESS=(\\d+)").find(p)?.groupValues?.get(1)?.toInt() ?: 0
    } catch (_: Exception) { 0 }

    /** Fixed mode: apply as soon as the control port is up. "auto": start
     *  direct; when bootstrap stalls, try snowflake → obfs4 → meek. */
    private fun startBridgeWatcher() {
        bridgeWatcher?.interrupt()
        val t = Thread {
            try {
                var waited = 0
                while (torService?.torControlConnection == null && waited < 60) { Thread.sleep(1000); waited++ }
                val mode = bridgeMode
                if (mode != "auto") {
                    if (mode != bridgeApplied) applyBridge(mode)
                    return@Thread
                }
                val order = listOf("", "snowflake", "obfs4", "meek")
                var idx = maxOf(0, order.indexOf(bridgeApplied))
                var best = bootPercent(); var since = System.currentTimeMillis()
                while (!Thread.currentThread().isInterrupted) {
                    Thread.sleep(3000)
                    if (torDormant) return@Thread
                    val pct = bootPercent()
                    if (pct >= 100) return@Thread
                    if (pct > best) { best = pct; since = System.currentTimeMillis() }
                    // direct: give it 40 s without progress; a transport: 75 s
                    val limit = if (idx == 0) 40_000 else 75_000
                    if (System.currentTimeMillis() - since > limit) {
                        if (idx + 1 >= order.size) return@Thread
                        idx++
                        if (!applyBridge(order[idx])) continue
                        best = 0; since = System.currentTimeMillis()
                    }
                }
            } catch (_: InterruptedException) {
            }
        }
        t.isDaemon = true
        bridgeWatcher = t
        t.start()
    }

    // 0.4.4: read on the io thread (control-port socket), never on main
    @Volatile private var torBoot = ""

    private fun flushTorWaiters() {
        val waiting = torWaiters
        torWaiters = mutableListOf()
        // ports are filled in by TorService shortly after it reports ON
        main.postDelayed({ waiting.forEach { it.success(torInfo()) } }, 300)
    }

    // tor-android can run tor only once per process: stopping the service and
    // starting it again aborts natively (hs_circuitmap_init). "Off" therefore
    // keeps the service and just makes tor dormant (DisableNetwork 1).
    private var torDormant = false
    private var torEverStarted = false

    private fun torStart(result: MethodChannel.Result) {
        // YomiHub 0.4.3: tor-android needs API 24; the APK now installs on 6.0
        if (android.os.Build.VERSION.SDK_INT < 24) {
            result.error("TOR", "Tor cần Android 7.0 trở lên – trên Android 6.0 hãy dùng WARP/Proxy hoặc DNS-over-HTTPS", null)
            return
        }
        val svc = torService
        if (svc != null && torDormant) {
            io.execute {
                val c = svc.torControlConnection
                try {
                    c?.setConf("DisableNetwork", "0")
                } catch (_: Exception) {
                }
                torDormant = false
                startBridgeWatcher()
                // Report "on" only once tor has a working circuit again.
                var ready = false
                for (i in 0 until 90) {
                    ready = try {
                        (c?.getInfo("status/bootstrap-phase") ?: "").contains("PROGRESS=100") &&
                            (c?.getInfo("status/circuit-established") ?: "") == "1"
                    } catch (_: Exception) {
                        false
                    }
                    if (ready) break
                    Thread.sleep(1000)
                }
                torStatus = if (ready) TorService.STATUS_ON else TorService.STATUS_STARTING
                main.post {
                    channel.invokeMethod("torStatus", torStatus)
                    result.success(torInfo())
                }
            }
            return
        }
        if (torStatus == TorService.STATUS_ON && svc != null) {
            result.success(torInfo()); return
        }
        if (svc == null && torEverStarted) {
            result.error("TOR", "Tor cần khởi động lại ứng dụng để bật lại", null)
            return
        }
        torEverStarted = true
        torWaiters.add(result)
        val intent = Intent(ctx, TorService::class.java)
        ctx.bindService(intent, torConnection, Context.BIND_AUTO_CREATE)
        // Give up after 90 s so the UI never hangs.
        main.postDelayed({
            if (torWaiters.contains(result)) {
                torWaiters.remove(result)
                io.execute {
                    torBoot = try {
                        torService?.torControlConnection?.getInfo("status/bootstrap-phase") ?: ""
                    } catch (_: Exception) { "" }
                    main.post { result.success(torInfo()) }
                }
            }
        }, 90_000)
    }

    private fun torStop() {
        val svc = torService
        if (svc == null) {
            torStatus = TorService.STATUS_OFF
            return
        }
        torDormant = true
        torStatus = TorService.STATUS_OFF
        io.execute {
            try {
                svc.torControlConnection?.setConf("DisableNetwork", "1")
            } catch (_: Exception) {
            }
        }
    }

    private fun vpnPrepare(result: MethodChannel.Result) {
        val intent = VpnService.prepare(activity)
        if (intent == null) {
            result.success(true); return
        }
        pendingPrepare = result
        activity.startActivityForResult(intent, VPN_REQUEST)
    }

    /** Every installed package (needs QUERY_ALL_PACKAGES on Android 11+):
     *  used to build the OpenVPN exclusion list for "only these apps". */
    private fun listAllPackages(): List<Map<String, Any>> {
        val pm = ctx.packageManager
        @Suppress("DEPRECATION")
        val apps = pm.getInstalledApplications(0)
        return apps.map {
            mapOf(
                "package" to it.packageName,
                "label" to it.packageName,
                "system" to ((it.flags and ApplicationInfo.FLAG_SYSTEM) != 0)
            )
        }
    }

    private fun listApps(): List<Map<String, Any>> {
        val pm = ctx.packageManager
        val launcher = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        @Suppress("DEPRECATION")
        val activities = pm.queryIntentActivities(launcher, 0)
        return activities
            .map { it.activityInfo.applicationInfo }
            .distinctBy { it.packageName }
            .map {
                mapOf(
                    "package" to it.packageName,
                    "label" to pm.getApplicationLabel(it).toString(),
                    "system" to ((it.flags and ApplicationInfo.FLAG_SYSTEM) != 0)
                )
            }
            .sortedBy { (it["label"] as String).lowercase() }
    }

    /** Routes in-process JVM traffic (the built-in M-Extension-Server's
     *  OkHttp, used by Mihon/Aniyomi APK extensions) through a proxy. The
     *  default ProxySelector reads these properties on every connection. */
    private fun setJvmProxy(url: String) {
        val keys = listOf(
            "http.proxyHost", "http.proxyPort", "https.proxyHost", "https.proxyPort",
            "socksProxyHost", "socksProxyPort",
        )
        keys.forEach { System.clearProperty(it) }
        if (url.isBlank()) return
        try {
            val u = java.net.URI(url)
            val host = u.host ?: return
            val socks = (u.scheme ?: "").startsWith("socks")
            val port = if (u.port > 0) u.port else if (socks) 1080 else 8080
            System.setProperty("http.nonProxyHosts", "localhost|127.*|[::1]")
            if (socks) {
                System.setProperty("socksProxyHost", host)
                System.setProperty("socksProxyPort", port.toString())
            } else {
                System.setProperty("http.proxyHost", host)
                System.setProperty("http.proxyPort", port.toString())
                System.setProperty("https.proxyHost", host)
                System.setProperty("https.proxyPort", port.toString())
            }
        } catch (_: Exception) {
        }
    }

}
