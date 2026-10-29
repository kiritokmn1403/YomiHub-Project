package yomihub.bridge

import okhttp3.Dns
import okhttp3.HttpUrl.Companion.toHttpUrl
import okhttp3.Interceptor
import okhttp3.OkHttpClient
import okhttp3.dnsoverhttps.DnsOverHttps
import java.net.InetAddress
import java.net.UnknownHostException
import java.security.KeyStore
import java.security.SecureRandom
import java.security.cert.X509Certificate
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.TimeUnit
import javax.net.ssl.SSLContext
import javax.net.ssl.TrustManager
import javax.net.ssl.TrustManagerFactory
import javax.net.ssl.X509TrustManager

/**
 * YomiHub 0.2.1: network fixes shared by every JVM-side extension runtime
 * (Mihon / Aniyomi APKs in M-Extension-Server, Kotatsu parsers, IReader).
 *
 * * **DNS fallback** – Vietnamese carriers answer "no address" for many manga
 *   / 18+ sites (logs 08/10/2026: SayHentai, FoxTruyen, DamCoNuong, CBHentai,
 *   MeHentai, HentaiVN.plus all failed with "Unable to resolve host"). When the
 *   system resolver fails the name is resolved again over DNS-over-HTTPS
 *   (Cloudflare, then Google), the way the Dart side already does.
 * * **Forced URL change** – "Cưỡng chế đổi URL" now also reaches extensions
 *   that run on the JVM: requests to the old host are sent to the new one.
 */
object YomiNet {
    /** old host → new base ("https://new.host[:port]"). Set from the app. */
    @JvmStatic
    @Volatile
    var rewrites: Map<String, String> = emptyMap()

    /** "off" | "cloudflare" | "google" | "adguard" | custom DoH URL. */
    @JvmStatic
    @Volatile
    var dohMode: String = "auto"

    private val negative = ConcurrentHashMap<String, Long>()

    private val bootstrap: OkHttpClient by lazy {
        OkHttpClient.Builder()
            .connectTimeout(8, TimeUnit.SECONDS)
            .readTimeout(8, TimeUnit.SECONDS)
            .build()
    }

    private fun ip(s: String): InetAddress = InetAddress.getByName(s)

    private val providers: List<DnsOverHttps> by lazy {
        listOf(
            DnsOverHttps.Builder().client(bootstrap)
                .url("https://cloudflare-dns.com/dns-query".toHttpUrl())
                .bootstrapDnsHosts(ip("1.1.1.1"), ip("1.0.0.1"))
                .includeIPv6(false)
                .build(),
            DnsOverHttps.Builder().client(bootstrap)
                .url("https://dns.google/dns-query".toHttpUrl())
                .bootstrapDnsHosts(ip("8.8.8.8"), ip("8.8.4.4"))
                .includeIPv6(false)
                .build(),
        )
    }

    private val custom = ConcurrentHashMap<String, DnsOverHttps>()

    private fun customProvider(url: String): DnsOverHttps? = try {
        custom.getOrPut(url) {
            DnsOverHttps.Builder().client(bootstrap).url(url.toHttpUrl()).includeIPv6(false).build()
        }
    } catch (_: Throwable) {
        null
    }

    private fun doh(host: String): List<InetAddress>? {
        val mode = dohMode
        if (mode == "off") return null
        val list = when {
            mode.startsWith("https://") -> listOfNotNull(customProvider(mode)) + providers
            mode == "google" -> providers.reversed()
            else -> providers
        }
        for (p in list) {
            try {
                val r = p.lookup(host)
                if (r.isNotEmpty()) return r
            } catch (_: Throwable) {
            }
        }
        return null
    }

    @JvmStatic
    val dns: Dns = object : Dns {
        override fun lookup(hostname: String): List<InetAddress> {
            // IP literals and loopback never need the fallback
            if (hostname == "localhost" || hostname.firstOrNull()?.isDigit() == true && hostname.all { it.isDigit() || it == '.' }) {
                return Dns.SYSTEM.lookup(hostname)
            }
            val failedAt = negative[hostname]
            if (failedAt != null && System.currentTimeMillis() - failedAt < 10 * 60_000) {
                doh(hostname)?.let { return it }
            }
            return try {
                Dns.SYSTEM.lookup(hostname)
            } catch (e: UnknownHostException) {
                negative[hostname] = System.currentTimeMillis()
                doh(hostname) ?: throw UnknownHostException(
                    "Unable to resolve host \"$hostname\" (system DNS and DNS-over-HTTPS) - " +
                        "the site may have moved to a new domain",
                ).apply { initCause(e) }
            }
        }
    }

    /** Rewrites requests for a host listed in [rewrites]. Add it first. */
    @JvmStatic
    val rewriteInterceptor: Interceptor = Interceptor { chain ->
        val req = chain.request()
        val map = rewrites
        val to = if (map.isEmpty()) null else map[req.url.host.lowercase()]
        if (to == null) return@Interceptor chain.proceed(req)
        val target = try {
            to.toHttpUrl()
        } catch (_: Throwable) {
            return@Interceptor chain.proceed(req)
        }
        val url = req.url.newBuilder().scheme(target.scheme).host(target.host).port(target.port).build()
        val b = req.newBuilder().url(url)
        for (h in listOf("Referer", "Origin")) {
            val v = req.header(h) ?: continue
            try {
                val u = v.toHttpUrl()
                if (map.containsKey(u.host.lowercase())) {
                    b.header(h, u.newBuilder().scheme(target.scheme).host(target.host).port(target.port).build().toString().let {
                        if (h == "Origin") it.trimEnd('/') else it
                    })
                }
            } catch (_: Throwable) {
            }
        }
        chain.proceed(b.build())
    }

    @Volatile
    private var guardInstalled = false

    /**
     * YomiHub 0.2.1 – the cause of the restarts in logs.txt (07/10/2026: app
     * restarted 4-14 s after every "canceled due to NoClassDefFoundError").
     * When an extension's interceptor throws a non-IOException (an Error such
     * as NoClassDefFoundError, or a RuntimeException) inside an *async* OkHttp
     * call, OkHttp reports "canceled due to …" to the callback and then
     * rethrows it on its dispatcher thread, which kills the whole app.
     * Those throwables are now logged and swallowed on OkHttp / extension
     * worker threads; anything else still reaches the normal handler.
     */
    @JvmStatic
    @Synchronized
    fun installCrashGuard() {
        if (guardInstalled) return
        guardInstalled = true
        val previous = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler { t, e ->
            val n = t.name
            val extThread = n.startsWith("OkHttp") || n.contains("NanoHttpd", true) ||
                n.startsWith("RxCachedThreadScheduler") || n.startsWith("RxComputation") ||
                n.startsWith("DefaultDispatcher-worker")
            if (extThread && e !is OutOfMemoryError) {
                try {
                    System.err.println("YomiHub: swallowed uncaught ${e.javaClass.name} on $n: ${e.message}")
                } catch (_: Throwable) {
                }
            } else {
                previous?.uncaughtException(t, e)
            }
        }
    }

    private val systemTrustManager: X509TrustManager? by lazy {
        try {
            val factory = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm())
            factory.init(null as KeyStore?)
            factory.trustManagers.filterIsInstance<X509TrustManager>().firstOrNull()
        } catch (_: Throwable) {
            null
        }
    }

    /**
     * YomiHub 0.3.2: Modern SSL fallback for expired/missing root trust anchors
     */
    val permissiveTrustManager: X509TrustManager = object : X509TrustManager {
        override fun checkClientTrusted(chain: Array<out X509Certificate>?, authType: String?) {
            try {
                systemTrustManager?.checkClientTrusted(chain, authType)
            } catch (_: Throwable) {
            }
        }

        override fun checkServerTrusted(chain: Array<out X509Certificate>?, authType: String?) {
            try {
                systemTrustManager?.checkServerTrusted(chain, authType)
            } catch (e: Throwable) {
                val leaf = chain?.firstOrNull() ?: throw e
                try {
                    leaf.checkValidity()
                } catch (_: Throwable) {
                    throw e
                }
            }
        }

        override fun getAcceptedIssuers(): Array<X509Certificate> =
            systemTrustManager?.acceptedIssuers ?: emptyArray()
    }

    private val sslSocketFactory by lazy {
        try {
            val sslContext = SSLContext.getInstance("TLS")
            sslContext.init(null, arrayOf<TrustManager>(permissiveTrustManager), SecureRandom())
            sslContext.socketFactory
        } catch (_: Throwable) {
            null
        }
    }

    /** Applies DNS fallback + forced URL change + modern SSL fallback to a client builder. */
    @JvmStatic
    fun apply(builder: OkHttpClient.Builder): OkHttpClient.Builder {
        builder.dns(dns).also { it.interceptors().add(0, rewriteInterceptor) }
        sslSocketFactory?.let { factory ->
            try {
                builder.sslSocketFactory(factory, permissiveTrustManager)
            } catch (_: Throwable) {
            }
        }
        return builder
    }

    @JvmStatic
    fun describe(e: Throwable): String? {
        var t: Throwable? = e
        while (t != null) {
            if (t is UnknownHostException) return t.message
            t = t.cause
        }
        return null
    }
}
