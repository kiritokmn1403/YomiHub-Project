package com.kodjodevf.mangayomi

import android.content.Context
import com.wireguard.android.backend.GoBackend
import com.wireguard.android.backend.Tunnel

/**
 * YomiHub 0.5.6.1 (V7, AVD 13/11/2026): ONE WireGuard engine per process.
 *
 * Before, YomiVpn (WARP) and YomiTunnels (WireGuard profiles) each created
 * their own GoBackend, per Activity. Swiping YomiHub out of recents and
 * opening it again recreates the Activity + Flutter engine while the process
 * (and the VpnService with the running tunnel) lives on: the new instances
 * got a fresh GoBackend that did not know the running tunnel – WireGuard
 * showed "VPN đang tắt" while the device had no Internet, WARP hung on
 * "Đang kết nối…", and "Tắt" could not take the orphan tunnel down.
 *
 * Now the backend and both Tunnel objects live here for the whole process;
 * each new Activity only re-points the state listeners to its own channel.
 */
object YomiWg {
    @Volatile private var backend: GoBackend? = null

    fun backend(ctx: Context): GoBackend =
        backend ?: synchronized(this) {
            backend ?: GoBackend(ctx.applicationContext).also { backend = it }
        }

    /** Set by the current Activity's YomiVpn / YomiTunnels. */
    @Volatile var warpListener: ((Boolean) -> Unit)? = null
    @Volatile var wgListener: ((Boolean) -> Unit)? = null

    val warp: Tunnel = object : Tunnel {
        override fun getName(): String = "yomihub-warp"
        override fun onStateChange(newState: Tunnel.State) {
            warpListener?.invoke(newState == Tunnel.State.UP)
        }
    }

    val wg: Tunnel = object : Tunnel {
        override fun getName(): String = "yomihub-wg"
        override fun onStateChange(newState: Tunnel.State) {
            wgListener?.invoke(newState == Tunnel.State.UP)
        }
    }

    fun isUp(ctx: Context, t: Tunnel): Boolean = try {
        backend(ctx).getState(t) == Tunnel.State.UP
    } catch (_: Throwable) {
        false
    }

    /**
     * V8: real tunnel health. `handshake` = newest latest-handshake time of
     * any peer (epoch ms, 0 = never), `rx` = bytes received from the peers.
     */
    fun stats(ctx: Context, t: Tunnel): Map<String, Any> {
        var hs = 0L
        var rx = 0L
        try {
            val s = backend(ctx).getStatistics(t)
            for (k in s.peers()) {
                val p = s.peer(k) ?: continue
                if (p.latestHandshakeEpochMillis() > hs) hs = p.latestHandshakeEpochMillis()
                rx += p.rxBytes()
            }
        } catch (_: Throwable) {
        }
        return mapOf("up" to isUp(ctx, t), "handshake" to hs, "rx" to rx, "now" to System.currentTimeMillis())
    }
}
