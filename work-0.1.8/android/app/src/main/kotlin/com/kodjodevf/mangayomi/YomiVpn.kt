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
        "httpPort" to (torService?.httpTunnelPort ?: 0)
    )

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
        val svc = torService
        if (svc != null && torDormant) {
            io.execute {
                val c = svc.torControlConnection
                try {
                    c?.setConf("DisableNetwork", "0")
                } catch (_: Exception) {
                }
                torDormant = false
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
                result.success(torInfo())
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
