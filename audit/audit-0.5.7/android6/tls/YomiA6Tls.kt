package com.kodjodevf.mangayomi

// YomiHub 0.5.6.1 A6 (chỉ có trong APK Android 6.0, build23): Android 6 thiếu CA gốc mới
// (ISRG Root X1, GTS Root R1...). Khi SDK < 24, gộp kho CA hệ thống với bộ CA Mozilla đóng gói
// (assets/yh_a6_cacert.pem) cho mọi mã Java/Kotlin (OkHttp của Kotatsu / M-Extension-Server,
// HttpsURLConnection). Không tắt kiểm tra chứng chỉ: chỉ thêm gốc tin cậy.

import android.content.Context
import android.os.Build
import android.util.Log
import java.security.KeyStore
import java.security.Provider
import java.security.Security
import java.security.cert.CertificateException
import java.security.cert.CertificateFactory
import java.security.cert.X509Certificate
import javax.net.ssl.HttpsURLConnection
import javax.net.ssl.ManagerFactoryParameters
import javax.net.ssl.SSLContext
import javax.net.ssl.TrustManager
import javax.net.ssl.TrustManagerFactory
import javax.net.ssl.TrustManagerFactorySpi
import javax.net.ssl.X509TrustManager

object YomiA6Tls {
    @Volatile private var done = false
    @Volatile var composite: X509TrustManager? = null
    @Volatile var original: Provider? = null
    @Volatile var algorithm: String = "PKIX"

    @JvmStatic
    fun install(ctx: Context) {
        if (done || Build.VERSION.SDK_INT >= 24) return
        done = true
        // Android 6 không đặt TMPDIR cho tiến trình app -> Directory.systemTemp của Dart rơi về
        // /data/local/tmp (app không ghi được) -> trang ảnh CBZ (ghi tệp tạm) báo "Không tải được ảnh này".
        try {
            if (android.system.Os.getenv("TMPDIR").isNullOrEmpty()) {
                android.system.Os.setenv("TMPDIR", ctx.cacheDir.absolutePath, true)
                Log.i("YomiA6Tls", "TMPDIR = ${ctx.cacheDir.absolutePath}")
            }
        } catch (t: Throwable) { Log.w("YomiA6Tls", "không đặt được TMPDIR", t) }
        try {
            val cf = CertificateFactory.getInstance("X.509")
            val ks = KeyStore.getInstance(KeyStore.getDefaultType())
            ks.load(null, null)
            var n = 0
            // Tệp có dòng chú thích "# Tên CA" giữa các khối -> generateCertificates() của Android 6 đọc được 0;
            // tách từng khối PEM rồi đọc riêng.
            val pem = ctx.assets.open("yh_a6_cacert.pem").use { it.readBytes().toString(Charsets.US_ASCII) }
            for (m in Regex("-----BEGIN CERTIFICATE-----[\\s\\S]+?-----END CERTIFICATE-----").findAll(pem)) {
                try {
                    val c = cf.generateCertificate(java.io.ByteArrayInputStream(m.value.toByteArray(Charsets.US_ASCII)))
                    ks.setCertificateEntry("yh_a6_$n", c); n++
                } catch (_: Exception) {}
            }
            algorithm = TrustManagerFactory.getDefaultAlgorithm()
            val sysTmf = TrustManagerFactory.getInstance(algorithm)
            original = sysTmf.provider
            sysTmf.init(null as KeyStore?)
            val bunTmf = TrustManagerFactory.getInstance(algorithm, sysTmf.provider)
            bunTmf.init(ks)
            val sys = sysTmf.trustManagers.filterIsInstance<X509TrustManager>().first()
            val bun = bunTmf.trustManagers.filterIsInstance<X509TrustManager>().first()
            val tm = YomiA6CompositeTrustManager(sys, bun)
            composite = tm
            Security.insertProviderAt(YomiA6TlsProvider(), 1)
            val sc = SSLContext.getInstance("TLS")
            sc.init(null, arrayOf<TrustManager>(tm), null)
            SSLContext.setDefault(sc)
            HttpsURLConnection.setDefaultSSLSocketFactory(sc.socketFactory)
            Log.i("YomiA6Tls", "Android ${Build.VERSION.SDK_INT}: thêm $n CA gốc đóng gói vào kho tin cậy Java")
        } catch (t: Throwable) {
            Log.w("YomiA6Tls", "không nạp được bộ CA đóng gói", t)
        }
    }
}

class YomiA6CompositeTrustManager(
    private val sys: X509TrustManager,
    private val bundled: X509TrustManager,
) : X509TrustManager {
    override fun checkClientTrusted(chain: Array<X509Certificate>, authType: String) =
        sys.checkClientTrusted(chain, authType)

    override fun checkServerTrusted(chain: Array<X509Certificate>, authType: String) {
        try {
            sys.checkServerTrusted(chain, authType)
        } catch (e: CertificateException) {
            try { bundled.checkServerTrusted(chain, authType) } catch (_: CertificateException) { throw e }
        }
    }

    override fun getAcceptedIssuers(): Array<X509Certificate> = sys.acceptedIssuers + bundled.acceptedIssuers
}

/** TrustManagerFactory "PKIX"/"X509" ưu tiên: init(null) -> kho gộp; init(KeyStore riêng) -> giữ nguyên hành vi gốc. */
class YomiA6TrustManagerFactorySpi : TrustManagerFactorySpi() {
    private var managers: Array<TrustManager>? = null
    override fun engineInit(ks: KeyStore?) {
        managers = if (ks == null) arrayOf(YomiA6Tls.composite!!) else {
            val f = TrustManagerFactory.getInstance(YomiA6Tls.algorithm, YomiA6Tls.original!!)
            f.init(ks); f.trustManagers
        }
    }
    override fun engineInit(spec: ManagerFactoryParameters?) {
        val f = TrustManagerFactory.getInstance(YomiA6Tls.algorithm, YomiA6Tls.original!!)
        f.init(spec); managers = f.trustManagers
    }
    override fun engineGetTrustManagers(): Array<TrustManager> = managers ?: arrayOf(YomiA6Tls.composite!!)
}

@Suppress("DEPRECATION")
class YomiA6TlsProvider : Provider("YomiA6Tls", 1.0, "YomiHub A6: CA gốc đóng gói cho Android 6") {
    init {
        put("TrustManagerFactory.PKIX", YomiA6TrustManagerFactorySpi::class.java.name)
        put("TrustManagerFactory.X509", YomiA6TrustManagerFactorySpi::class.java.name)
    }
}
