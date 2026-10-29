package yomihub.bridge

import okhttp3.Cookie
import okhttp3.CookieJar
import okhttp3.HttpUrl
import org.json.JSONObject
import java.io.File
import java.util.concurrent.ConcurrentHashMap

/** Small persisted key/value store + cookie jar for the JVM bridge. */
object Store {
    lateinit var dir: File
    private lateinit var file: File
    private val map = ConcurrentHashMap<String, String>()
    @Volatile private var dirty = false

    fun init(d: File) {
        dir = d
        file = File(d, "prefs.json")
        try {
            if (file.exists()) {
                val o = JSONObject(file.readText())
                for (k in o.keys()) map[k] = o.getString(k)
            }
        } catch (_: Throwable) {
        }
        Thread {
            while (true) {
                Thread.sleep(5000)
                if (dirty) flush()
            }
        }.apply { isDaemon = true }.start()
    }

    fun get(k: String): String? = map[k]
    fun put(k: String, v: String?) {
        if (v == null) map.remove(k) else map[k] = v
        dirty = true
    }
    fun contains(k: String) = map.containsKey(k)

    @Synchronized
    fun flush() {
        if (!::file.isInitialized) return
        dirty = false
        try {
            val tmp = File(file.path + ".tmp")
            tmp.writeText(JSONObject(map as Map<*, *>).toString())
            if (!tmp.renameTo(file)) {
                file.delete(); tmp.renameTo(file)
            }
        } catch (_: Throwable) {
        }
    }

    /** Cookies kept per host, saved with the prefs. */
    val cookieJar: CookieJar = object : CookieJar {
        private val cookies = ConcurrentHashMap<String, MutableMap<String, Cookie>>()

        override fun saveFromResponse(url: HttpUrl, cookies: List<Cookie>) {
            for (c in cookies) {
                this.cookies.getOrPut(c.domain) { ConcurrentHashMap() }[c.name] = c
            }
        }

        override fun loadForRequest(url: HttpUrl): List<Cookie> {
            val now = System.currentTimeMillis()
            val out = ArrayList<Cookie>()
            for ((_, m) in cookies) {
                val it = m.values.iterator()
                while (it.hasNext()) {
                    val c = it.next()
                    if (c.expiresAt < now) {
                        it.remove(); continue
                    }
                    if (c.matches(url)) out += c
                }
            }
            return out
        }
    }
}
