package com.kodjodevf.mangayomi

import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log
import java.io.File

/** JNI entry points of hev-socks5-tunnel (libhev-socks5-tunnel.so). The
 *  library registers its natives on this exact class name in JNI_OnLoad. */
object TProxyService {
    @Volatile private var loaded = false
    fun load(): Boolean {
        if (!loaded) {
            loaded = try {
                System.loadLibrary("hev-socks5-tunnel"); true
            } catch (t: Throwable) {
                Log.e("YomiTorVpn", "load hev", t); false
            }
        }
        return loaded
    }
    @JvmStatic external fun TProxyStartService(configPath: String, fd: Int): Boolean
    @JvmStatic external fun TProxyStopService(): Boolean
    @JvmStatic external fun TProxyIsRunning(): Boolean
    @JvmStatic external fun TProxyGetStats(): LongArray?
}

/**
 * YomiHub 0.1.6: Tor for other apps / the whole device.
 *
 * Android's VpnService hands us a TUN interface; hev-socks5-tunnel turns the
 * packets on it into connections to Tor's SOCKS port (the same tor-android
 * daemon YomiHub already runs). DNS is answered by hev's "mapdns": every
 * name gets a placeholder address and the real name goes to Tor in the SOCKS
 * request, so lookups are resolved by the Tor exit and never leak to the
 * local network. YomiHub itself is excluded from the tunnel (Tor runs inside
 * it and must reach the Tor network directly); its own traffic follows the
 * in-app scope.
 *
 * Tor carries TCP only: other UDP (e.g. QUIC) fails and apps fall back to
 * TCP, the same behaviour as Orbot's VPN mode.
 */
class YomiTorVpnService : VpnService() {
    companion object {
        const val ACTION_START = "com.kodjodevf.mangayomi.TOR_VPN_START"
        const val ACTION_STOP = "com.kodjodevf.mangayomi.TOR_VPN_STOP"
        @Volatile var running = false
            private set
        @Volatile var lastError: String? = null
            private set
        var listener: ((Boolean) -> Unit)? = null
        private fun notify(up: Boolean) {
            running = up
            listener?.invoke(up)
        }
    }

    private var tun: ParcelFileDescriptor? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopTunnel()
            stopSelf()
            return START_NOT_STICKY
        }
        val port = intent?.getIntExtra("socksPort", 9050) ?: 9050
        val apps = intent?.getStringArrayListExtra("apps") ?: arrayListOf()
        Thread { startTunnel(if (port > 0) port else 9050, apps) }.start()
        return START_NOT_STICKY
    }

    @Synchronized
    private fun startTunnel(socksPort: Int, apps: List<String>) {
        stopTunnel()
        lastError = null
        if (!TProxyService.load()) {
            lastError = "Thiếu thư viện tun2socks cho kiến trúc máy này"
            notify(false); return
        }
        try {
            val b = Builder()
                .setSession("YomiHub · Tor")
                .setMtu(8500)
                .addAddress("198.18.0.1", 32)
                .addRoute("0.0.0.0", 0)
                .addDnsServer("198.18.0.2")
            try {
                b.addAddress("fc00::1", 128)
                b.addRoute("::", 0)
            } catch (_: Exception) {
            }
            val own = packageName
            val wanted = apps.filter { it.isNotBlank() && it != own }
            if (wanted.isEmpty()) {
                b.addDisallowedApplication(own)
            } else {
                for (p in wanted) {
                    try { b.addAllowedApplication(p) } catch (_: Exception) {}
                }
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) b.setMetered(false)
            val pfd = b.establish() ?: run {
                lastError = "Android từ chối tạo VPN (chưa cấp quyền?)"
                notify(false); return
            }
            tun = pfd
            val conf = File(cacheDir, "tor_tun.yml")
            conf.writeText(
                """
                tunnel:
                  mtu: 8500
                  ipv4: 198.18.0.1
                  ipv6: 'fc00::1'
                socks5:
                  port: $socksPort
                  address: 127.0.0.1
                  udp: 'udp'
                mapdns:
                  address: 198.18.0.2
                  port: 53
                  network: 100.64.0.0
                  netmask: 255.192.0.0
                  cache-size: 10000
                misc:
                  task-stack-size: 24576
                  connect-timeout: 15000
                  read-write-timeout: 300000
                  log-level: warn
                """.trimIndent() + "\n"
            )
            val ok = TProxyService.TProxyStartService(conf.absolutePath, pfd.fd)
            if (!ok) {
                lastError = "Không khởi động được tun2socks"
                stopTunnel(); notify(false); return
            }
            notify(true)
        } catch (e: Exception) {
            lastError = e.message ?: e.toString()
            stopTunnel()
            notify(false)
        }
    }

    @Synchronized
    private fun stopTunnel() {
        try {
            if (TProxyService.load() && TProxyService.TProxyIsRunning()) {
                TProxyService.TProxyStopService()
            }
        } catch (_: Throwable) {
        }
        try { tun?.close() } catch (_: Exception) {}
        val was = tun != null
        tun = null
        if (was) notify(false)
    }

    override fun onRevoke() {
        stopTunnel()
        stopSelf()
    }

    override fun onDestroy() {
        stopTunnel()
        super.onDestroy()
    }
}
