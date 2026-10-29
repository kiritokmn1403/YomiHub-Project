package com.kodjodevf.mangayomi

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.os.Handler
import android.os.Looper
import android.webkit.CookieManager
import android.webkit.WebView
import android.webkit.WebViewClient
import dalvik.system.DexClassLoader
import fi.iki.elonen.NanoHTTPD
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull
import okhttp3.Cookie
import okhttp3.CookieJar
import okhttp3.HttpUrl
import okhttp3.Interceptor
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import okhttp3.ResponseBody.Companion.toResponseBody
import org.json.JSONArray
import org.json.JSONObject
import org.koitharu.kotatsu.parsers.MangaLoaderContext
import org.koitharu.kotatsu.parsers.MangaParser
import org.koitharu.kotatsu.parsers.bitmap.Bitmap
import org.koitharu.kotatsu.parsers.bitmap.Rect
import org.koitharu.kotatsu.parsers.config.ConfigKey
import org.koitharu.kotatsu.parsers.config.MangaSourceConfig
import org.koitharu.kotatsu.parsers.model.ContentRating
import org.koitharu.kotatsu.parsers.model.Manga
import org.koitharu.kotatsu.parsers.model.MangaChapter
import org.koitharu.kotatsu.parsers.model.MangaListFilter
import org.koitharu.kotatsu.parsers.model.MangaPage
import org.koitharu.kotatsu.parsers.model.MangaParserSource
import org.koitharu.kotatsu.parsers.model.MangaSource
import org.koitharu.kotatsu.parsers.model.MangaState
import org.koitharu.kotatsu.parsers.model.MangaTag
import org.koitharu.kotatsu.parsers.model.SortOrder
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.Locale
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.TimeUnit
import kotlin.coroutines.resume

/**
 * YomiHub 0.1.4: Kotatsu parsers built into the app.
 *
 * The Kotatsu-Redo parser library (≈1 200 sources, the main repo of
 * Shebyyy/kotatsu-multi-parsers) is compiled in. The other repos of
 * kotatsu-multi-parsers (glitch-228, hany18h, skepsun, Gekkoushi…) are
 * downloaded as d8-processed jars and loaded with a classloader that shares
 * the parser API with the built-in library.
 *
 * Mangayomi talks to them through a loopback HTTP API (port 47350) used by
 * small generated JavaScript extensions, so they get the normal browse /
 * search / filter / reader UI.
 */
object YomiKotatsu {
    const val PORT = 47350
    private var server: Server? = null
    private lateinit var app: Context
    private val main = Handler(Looper.getMainLooper())

    /** "built-in" plus every loaded fork → its sources. */
    private val sources = ConcurrentHashMap<String, MangaSource>()
    private val sourceRepo = ConcurrentHashMap<String, String>()
    private val parsers = ConcurrentHashMap<String, MangaParser>()
    private val forkFactories = ConcurrentHashMap<String, (MangaSource) -> MangaParser>()
    private val mangaCache = ConcurrentHashMap<String, Manga>()
    private val chapterCache = ConcurrentHashMap<String, MangaChapter>()
    private val pageCache = ConcurrentHashMap<String, MangaPage>()
    private val pageSizes = ConcurrentHashMap<String, Int>()

    val context: Ctx by lazy { Ctx(app) }

    fun register(ctx: Context, messenger: BinaryMessenger) {
        app = ctx.applicationContext
        MethodChannel(messenger, "yomihub/kotatsu").setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> Thread {
                    val ok = try {
                        start(); true
                    } catch (e: Throwable) {
                        false
                    }
                    main.post { result.success(if (ok) PORT else 0) }
                }.start()
                "loadFork" -> {
                    val path = call.argument<String>("path") ?: ""
                    val name = call.argument<String>("name") ?: ""
                    Thread {
                        val res = try {
                            "ok:" + loadFork(name, File(path))
                        } catch (e: Throwable) {
                            "error:" + (e.message ?: e.toString())
                        }
                        main.post { result.success(res) }
                    }.start()
                }
                else -> result.notImplemented()
            }
        }
    }

    @Synchronized
    fun start() {
        if (server != null) return
        for (s in MangaParserSource.values()) {
            sources[s.name] = s
            sourceRepo[s.name] = "Kotatsu-Redo"
        }
        val srv = Server()
        srv.start(NanoHTTPD.SOCKET_READ_TIMEOUT, true)
        server = srv
    }

    // ───────────── forks (other kotatsu-multi-parsers jars) ─────────────

    /** Parent-first for the parser API, child-first for the fork's sites. */
    private class ForkLoader(dex: String, odex: String, parent: ClassLoader) :
        DexClassLoader(dex, odex, null, parent) {
        private val childFirst = listOf(
            "org.koitharu.kotatsu.parsers.site.",
            "org.koitharu.kotatsu.parsers.model.MangaParserSource",
            "org.koitharu.kotatsu.parsers.MangaParserFactory",
        )

        override fun loadClass(name: String, resolve: Boolean): Class<*> {
            if (childFirst.any { name.startsWith(it) }) {
                synchronized(this) {
                    findLoadedClass(name)?.let { return it }
                    try {
                        return findClass(name)
                    } catch (_: ClassNotFoundException) {
                    }
                }
            }
            return super.loadClass(name, resolve)
        }
    }

    private fun loadFork(name: String, jar: File): Int {
        start()
        val odex = File(app.codeCacheDir, "kotatsu_$name").apply { mkdirs() }
        // Android 14+: dynamically loaded code must be read-only.
        jar.setReadOnly()
        val loader = ForkLoader(jar.absolutePath, odex.absolutePath, YomiKotatsu::class.java.classLoader!!)
        val enumClass = loader.loadClass("org.koitharu.kotatsu.parsers.model.MangaParserSource")
        val factory = listOf(
            "org.koitharu.kotatsu.parsers.MangaParserFactoryKt",
            "org.koitharu.kotatsu.parsers.MangaParserFactory",
        ).firstNotNullOfOrNull {
            try {
                loader.loadClass(it)
            } catch (_: Throwable) {
                null
            }
        } ?: throw IllegalStateException("factory not found")
        val newParser = factory.declaredMethods.first { m ->
            m.name.startsWith("newParser") && m.parameterTypes.size == 2
        }.apply { isAccessible = true }
        var n = 0
        for (constant in enumClass.enumConstants ?: emptyArray()) {
            val src = constant as MangaSource
            val key = "$name:${src.name}"
            sources[key] = src
            sourceRepo[key] = name
            forkFactories[key] = { s -> newParser.invoke(null, s, context) as MangaParser }
            n++
        }
        return n
    }

    private fun parser(id: String): MangaParser {
        parsers[id]?.let { return it }
        val src = sources[id] ?: throw IllegalArgumentException("Unknown Kotatsu source $id")
        val p = forkFactories[id]?.invoke(src)
            ?: context.newParserInstance(src as MangaParserSource)
        parsers[id] = p
        return p
    }

    // ───────────── JSON helpers ─────────────

    private fun stateCode(s: MangaState?): Int = when (s) {
        MangaState.ONGOING -> 0
        MangaState.FINISHED -> 1
        MangaState.PAUSED -> 2
        MangaState.ABANDONED -> 3
        else -> 5
    }

    private fun mangaJson(id: String, m: Manga): JSONObject {
        mangaCache["$id|${m.url}"] = m
        return JSONObject()
            .put("name", m.title)
            .put("imageUrl", m.largeCoverUrl ?: m.coverUrl ?: "")
            .put("link", m.url)
            .put("publicUrl", m.publicUrl)
    }

    private fun mangaFor(id: String, url: String, title: String = ""): Manga {
        mangaCache["$id|$url"]?.let { return it }
        val p = parser(id)
        val public = if (url.startsWith("http")) url else "https://${p.domain}$url"
        return Manga(
            id = (id + url).hashCode().toLong(),
            title = title,
            altTitles = emptySet(),
            url = url,
            publicUrl = public,
            rating = -1f,
            contentRating = null,
            coverUrl = null,
            tags = emptySet(),
            state = null,
            authors = emptySet(),
            source = p.source,
        )
    }

    private fun sourcesJson(): JSONArray {
        val arr = JSONArray()
        for ((key, s) in sources) {
            val o = JSONObject().put("id", key).put("name", s.name).put("repo", sourceRepo[key])
            if (s is MangaParserSource) {
                o.put("title", s.title).put("lang", s.locale).put("type", s.contentType.name)
                    .put("broken", s.isBroken)
            } else {
                // fork enum: same shape, read reflectively
                fun field(n: String): Any? = try {
                    s.javaClass.getMethod("get" + n.replaceFirstChar { it.uppercase() }).invoke(s)
                } catch (_: Throwable) {
                    null
                }
                o.put("title", field("title") ?: s.name)
                    .put("lang", field("locale") ?: "")
                    .put("type", field("contentType")?.toString() ?: "MANGA")
                    .put("broken", field("isBroken") == true)
            }
            arr.put(o)
        }
        return arr
    }

    private suspend fun filtersJson(id: String): JSONObject {
        val p = parser(id)
        val o = JSONObject()
        o.put("sort", JSONArray(p.availableSortOrders.map { it.name }))
        val caps = p.filterCapabilities
        o.put("multiTag", caps.isMultipleTagsSupported)
        o.put("excludeTag", caps.isTagsExclusionSupported)
        o.put("searchWithFilters", caps.isSearchWithFiltersSupported)
        try {
            val opts = p.getFilterOptions()
            o.put("tags", JSONArray(opts.availableTags.sortedBy { it.title }.map {
                JSONObject().put("title", it.title).put("key", it.key)
            }))
            o.put("states", JSONArray(opts.availableStates.map { it.name }))
            o.put("ratings", JSONArray(opts.availableContentRating.map { it.name }))
        } catch (e: Throwable) {
            o.put("tags", JSONArray()).put("states", JSONArray()).put("ratings", JSONArray())
            o.put("error", e.message ?: e.toString())
        }
        return o
    }

    private suspend fun list(id: String, q: Map<String, String>): JSONObject {
        val p = parser(id)
        val page = (q["page"] ?: "1").toIntOrNull() ?: 1
        val query = q["query"]?.takeIf { it.isNotBlank() }
        val f = q["filter"]?.let { JSONObject(it) } ?: JSONObject()
        val order = f.optString("sort").takeIf { it.isNotEmpty() }?.let {
            try {
                SortOrder.valueOf(it)
            } catch (_: Throwable) {
                null
            }
        } ?: when (q["kind"]) {
            "latest" -> if (SortOrder.UPDATED in p.availableSortOrders) SortOrder.UPDATED else p.availableSortOrders.first()
            "search" -> if (SortOrder.RELEVANCE in p.availableSortOrders) SortOrder.RELEVANCE else p.availableSortOrders.first()
            else -> if (SortOrder.POPULARITY in p.availableSortOrders) SortOrder.POPULARITY else p.availableSortOrders.first()
        }
        val tagSet = HashSet<MangaTag>()
        val exclude = HashSet<MangaTag>()
        f.optJSONArray("tags")?.let { a ->
            for (i in 0 until a.length()) tagSet += MangaTag(a.getJSONObject(i).optString("title"), a.getJSONObject(i).optString("key"), p.source)
        }
        f.optJSONArray("exclude")?.let { a ->
            for (i in 0 until a.length()) exclude += MangaTag(a.getJSONObject(i).optString("title"), a.getJSONObject(i).optString("key"), p.source)
        }
        val states = HashSet<MangaState>()
        f.optJSONArray("states")?.let { a ->
            for (i in 0 until a.length()) try {
                states += MangaState.valueOf(a.getString(i))
            } catch (_: Throwable) {
            }
        }
        val ratings = HashSet<ContentRating>()
        f.optJSONArray("ratings")?.let { a ->
            for (i in 0 until a.length()) try {
                ratings += ContentRating.valueOf(a.getString(i))
            } catch (_: Throwable) {
            }
        }
        val filter = MangaListFilter(
            query = query,
            tags = tagSet,
            tagsExclude = exclude,
            states = states,
            contentRating = ratings,
        )
        val key = "$id|$order|$query|${f}"
        val size = pageSizes[key] ?: 0
        val offset = if (page <= 1) 0 else (size.takeIf { it > 0 } ?: 20) * (page - 1)
        val items = p.getList(offset, order, filter)
        if (page == 1 && items.isNotEmpty()) pageSizes[key] = items.size
        val arr = JSONArray()
        items.forEach { arr.put(mangaJson(id, it)) }
        return JSONObject().put("list", arr).put("hasNextPage", items.isNotEmpty())
    }

    private suspend fun details(id: String, url: String, title: String): JSONObject {
        val p = parser(id)
        val m = p.getDetails(mangaFor(id, url, title))
        mangaCache["$id|${m.url}"] = m
        val chapters = JSONArray()
        (m.chapters ?: emptyList()).sortedWith(compareByDescending<MangaChapter> { it.volume }.thenByDescending { it.number })
            .forEach { c ->
                chapterCache["$id|${c.url}"] = c
                val title = buildString {
                    if (c.branch != null) append("[${c.branch}] ")
                    append(c.name)
                }
                chapters.put(
                    JSONObject().put("name", title).put("url", c.url)
                        .put("dateUpload", c.uploadDate.toString())
                        .put("scanlator", c.scanlator ?: ""),
                )
            }
        return JSONObject()
            .put("name", m.title)
            .put("imageUrl", m.largeCoverUrl ?: m.coverUrl ?: "")
            .put("description", m.description ?: "")
            .put("author", m.authors.joinToString(", "))
            .put("status", stateCode(m.state))
            .put("genre", JSONArray(m.tags.map { it.title }))
            .put("link", m.url)
            .put("publicUrl", m.publicUrl)
            .put("chapters", chapters)
    }

    private suspend fun pages(id: String, url: String): JSONArray {
        val p = parser(id)
        val chapter = chapterCache["$id|$url"] ?: MangaChapter(
            id = (id + url).hashCode().toLong(),
            title = null,
            number = 0f,
            volume = 0,
            url = url,
            scanlator = null,
            uploadDate = 0,
            branch = null,
            source = p.source,
        )
        val arr = JSONArray()
        p.getPages(chapter).forEach { pg ->
            val k = "$id|${pg.url}"
            pageCache[k] = pg
            arr.put(
                "http://127.0.0.1:$PORT/kotatsu/image?source=${enc(id)}&page=${enc(pg.url)}",
            )
        }
        return arr
    }

    private fun enc(s: String) = java.net.URLEncoder.encode(s, "UTF-8")

    private suspend fun image(id: String, pageUrl: String): Pair<String, ByteArray> {
        val p = parser(id)
        val page = pageCache["$id|$pageUrl"] ?: MangaPage(
            id = (id + pageUrl).hashCode().toLong(),
            url = pageUrl,
            preview = null,
            source = p.source,
        )
        val real = p.getPageUrl(page)
        val builder = context.httpClient.newBuilder()
        if (p is Interceptor) builder.addInterceptor(p)
        val req = Request.Builder().url(real).headers(p.getRequestHeaders()).apply {
            header("Referer", "https://${p.domain}/")
        }.build()
        builder.build().newCall(req).execute().use { r ->
            val bytes = r.body.bytes()
            return (r.header("Content-Type") ?: "image/jpeg") to bytes
        }
    }

    // ───────────── HTTP server ─────────────

    private class Server : NanoHTTPD("127.0.0.1", PORT) {
        override fun serve(session: IHTTPSession): Response {
            val q = session.parameters.mapValues { it.value.firstOrNull() ?: "" }
            return try {
                runBlocking(Dispatchers.IO) {
                    val id = q["source"] ?: ""
                    when (session.uri) {
                        "/kotatsu/sources" -> json(sourcesJson().toString())
                        "/kotatsu/filters" -> json(filtersJson(id).toString())
                        "/kotatsu/list" -> json(list(id, q).toString())
                        "/kotatsu/details" -> json(details(id, q["url"] ?: "", q["title"] ?: "").toString())
                        "/kotatsu/pages" -> json(pages(id, q["url"] ?: "").toString())
                        "/kotatsu/image" -> {
                            val (mime, bytes) = image(id, q["page"] ?: "")
                            newFixedLengthResponse(Response.Status.OK, mime, ByteArrayInputStream(bytes), bytes.size.toLong())
                        }
                        "/kotatsu/ping" -> json("{\"ok\":true,\"sources\":${sources.size}}")
                        else -> newFixedLengthResponse(Response.Status.NOT_FOUND, "text/plain", "not found")
                    }
                }
            } catch (e: Throwable) {
                newFixedLengthResponse(
                    Response.Status.INTERNAL_ERROR,
                    "application/json",
                    JSONObject().put("error", e.message ?: e.toString()).toString(),
                )
            }
        }

        private fun json(text: String) = newFixedLengthResponse(Response.Status.OK, "application/json; charset=utf-8", text)
    }

    // ───────────── loader context ─────────────

    class Ctx(private val app: Context) : MangaLoaderContext() {
        private val prefs = app.getSharedPreferences("yomihub_kotatsu", Context.MODE_PRIVATE)
        private val ua = try {
            android.webkit.WebSettings.getDefaultUserAgent(app)
        } catch (_: Throwable) {
            "Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Mobile Safari/537.36"
        }

        override val cookieJar: CookieJar = object : CookieJar {
            override fun saveFromResponse(url: HttpUrl, cookies: List<Cookie>) {
                val cm = CookieManager.getInstance()
                cookies.forEach { cm.setCookie(url.toString(), it.toString()) }
            }

            override fun loadForRequest(url: HttpUrl): List<Cookie> {
                val raw = CookieManager.getInstance().getCookie(url.toString()) ?: return emptyList()
                return raw.split(";").mapNotNull { Cookie.parse(url, it.trim()) }
            }
        }

        override val httpClient: OkHttpClient = OkHttpClient.Builder()
            .cookieJar(cookieJar)
            .connectTimeout(20, TimeUnit.SECONDS)
            .readTimeout(60, TimeUnit.SECONDS)
            .addInterceptor { chain ->
                val r = chain.request()
                chain.proceed(
                    if (r.header("User-Agent") == null) r.newBuilder().header("User-Agent", ua).build() else r,
                )
            }
            .build()

        override fun encodeBase64(data: ByteArray): String =
            android.util.Base64.encodeToString(data, android.util.Base64.NO_WRAP)

        override fun decodeBase64(data: String): ByteArray =
            android.util.Base64.decode(data, android.util.Base64.DEFAULT)

        override fun getPreferredLocales(): List<Locale> = listOf(Locale.getDefault(), Locale.ENGLISH)

        @Deprecated("Provide a base url")
        override suspend fun evaluateJs(script: String): String? = evaluateJs("about:blank", script, 30_000)

        @SuppressLint("SetJavaScriptEnabled")
        override suspend fun evaluateJs(baseUrl: String, script: String, timeout: Long): String? =
            withTimeoutOrNull(timeout) {
                withContext(Dispatchers.Main) {
                    suspendCancellableCoroutine { cont ->
                        val wv = WebView(app)
                        wv.settings.javaScriptEnabled = true
                        wv.settings.domStorageEnabled = true
                        wv.settings.userAgentString = ua
                        var done = false
                        wv.webViewClient = object : WebViewClient() {
                            override fun onPageFinished(view: WebView, url: String?) {
                                if (done) return
                                done = true
                                view.evaluateJavascript(script) { r ->
                                    val v = try {
                                        if (r == null || r == "null") null else JSONArray("[$r]").get(0).toString()
                                    } catch (_: Throwable) {
                                        r
                                    }
                                    view.destroy()
                                    if (cont.isActive) cont.resume(v)
                                }
                            }
                        }
                        cont.invokeOnCancellation { main.post { wv.destroy() } }
                        wv.loadUrl(baseUrl)
                    }
                }
            }

        override fun getConfig(source: MangaSource): MangaSourceConfig = object : MangaSourceConfig {
            @Suppress("UNCHECKED_CAST")
            override fun <T> get(key: ConfigKey<T>): T {
                val k = "${source.name}_${key.key}"
                val def = key.defaultValue
                return when (def) {
                    is Boolean -> prefs.getBoolean(k, def) as T
                    is String -> (prefs.getString(k, def) ?: def) as T
                    else -> def
                }
            }
        }

        override fun getDefaultUserAgent(): String = ua

        override fun redrawImageResponse(response: Response, redraw: (image: Bitmap) -> Bitmap): Response {
            val bytes = response.body.bytes()
            val src = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
                ?: return response.newBuilder().body(bytes.toResponseBody(response.body.contentType())).build()
            val out = redraw(AndroidBitmap(src.copy(android.graphics.Bitmap.Config.ARGB_8888, true))) as AndroidBitmap
            val baos = ByteArrayOutputStream()
            out.bitmap.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, baos)
            return response.newBuilder().body(baos.toByteArray().toResponseBody("image/png".toMediaType())).build()
        }

        override fun createBitmap(width: Int, height: Int): Bitmap =
            AndroidBitmap(android.graphics.Bitmap.createBitmap(width, height, android.graphics.Bitmap.Config.ARGB_8888))
    }

    class AndroidBitmap(val bitmap: android.graphics.Bitmap) : Bitmap {
        override val width: Int get() = bitmap.width
        override val height: Int get() = bitmap.height
        override fun drawBitmap(sourceBitmap: Bitmap, src: Rect, dst: Rect) {
            val s = (sourceBitmap as AndroidBitmap).bitmap
            Canvas(bitmap).drawBitmap(
                s,
                android.graphics.Rect(src.left, src.top, src.right, src.bottom),
                android.graphics.Rect(dst.left, dst.top, dst.right, dst.bottom),
                null,
            )
        }
    }
}
