package yomihub.bridge

import fi.iki.elonen.NanoHTTPD
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeoutOrNull
import okhttp3.CookieJar
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
import java.awt.image.BufferedImage
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.util.Base64
import java.util.Locale
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.TimeUnit
import javax.imageio.ImageIO

/**
 * YomiHub 0.2.1: the Kotatsu bridge of the Android app (YomiKotatsu.kt)
 * ported to the desktop JVM, so Kotatsu-Redo parsers (~1 200 sources) work
 * in the Windows version too. Same loopback API on port 47350, used by the
 * same generated JavaScript extensions. Fork jars (d8/dex) are Android-only.
 */
object KotatsuJvm {
    const val PORT = 47350
    private var server: Server? = null

    private val sources = ConcurrentHashMap<String, MangaSource>()
    private val sourceRepo = ConcurrentHashMap<String, String>()
    private val parsers = ConcurrentHashMap<String, MangaParser>()
    private val forkFactories = ConcurrentHashMap<String, (MangaSource) -> MangaParser>()
    private val mangaCache = ConcurrentHashMap<String, Manga>()
    private val chapterCache = ConcurrentHashMap<String, MangaChapter>()
    private val pageCache = ConcurrentHashMap<String, MangaPage>()
    private val pageSizes = ConcurrentHashMap<String, Int>()

    val context: Ctx by lazy { Ctx() }

    /** host → User-Agent bound to that host's cf_clearance cookie. */
    val hostUa = ConcurrentHashMap<String, String>()

    fun uaFor(host: String): String? {
        var h = host.removePrefix("www.")
        while (true) {
            hostUa[h]?.let { return it }
            val i = h.indexOf('.')
            if (i < 0 || h.indexOf('.', i + 1) < 0) return null
            h = h.substring(i + 1)
        }
    }

    private fun isCloudflare(e: Throwable): Boolean {
        var t: Throwable? = e
        while (t != null) {
            val n = t.javaClass.name
            val m = t.message ?: ""
            if (n.contains("CloudFlare", true) || n.contains("Cloudflare", true)) return true
            if (Regex("Status=(403|503)").containsMatchIn(m)) return true
            t = t.cause
        }
        return false
    }

    private fun cfUrl(e: Throwable, id: String): String? {
        var t: Throwable? = e
        while (t != null) {
            Regex("URL=(https?://\\S+)").find(t.message ?: "")?.let { return it.groupValues[1].trimEnd(',', ')') }
            t = t.cause
        }
        return try {
            "https://" + parser(id).domain + "/"
        } catch (_: Throwable) {
            null
        }
    }

    /**
     * On Windows the app solves the challenge in its own WebView and sends
     * the cookies + User-Agent back with /kotatsu/setCookies; here the
     * request only reports it (the JS extension shows the WebView button).
     */
    /** Loopback port of the app's Cloudflare solver (0 = none). */
    @Volatile
    var cfPort = 0

    private fun solveViaApp(url: String): Boolean {
        if (cfPort <= 0) return false
        return try {
            val client = okhttp3.OkHttpClient.Builder()
                .readTimeout(160, TimeUnit.SECONDS).callTimeout(170, TimeUnit.SECONDS).build()
            val req = Request.Builder()
                .url("http://127.0.0.1:$cfPort/solveCf?url=" + java.net.URLEncoder.encode(url, "UTF-8")).build()
            client.newCall(req).execute().use { r ->
                val o = JSONObject(r.body.string())
                if (!o.optBoolean("ok")) return false
                val host = try { java.net.URI(url).host ?: "" } catch (_: Throwable) { "" }
                val ua = o.optString("ua")
                if (host.isNotEmpty() && ua.isNotEmpty()) hostUa[host.removePrefix("www.")] = ua
                val hu = okhttp3.HttpUrl.Builder().scheme("https").host(host.ifEmpty { "localhost" }).build()
                val list = o.optString("cookies").split(";").mapNotNull { okhttp3.Cookie.parse(hu, it.trim() + "; Domain=" + host.removePrefix("www.") + "; Path=/") }
                Store.cookieJar.saveFromResponse(hu, list)
                true
            }
        } catch (_: Throwable) {
            false
        }
    }

    /** Runs [block]; on a Cloudflare challenge asks the app to solve it once. */
    fun <T> withCf(id: String, block: () -> T): T {
        try {
            return block()
        } catch (e: Throwable) {
            if (!isCloudflare(e)) throw e
            val url = cfUrl(e, id) ?: throw e
            if (!solveViaApp(url)) throw CfFailed(url, e)
            return block()
        }
    }

    class CfFailed(val url: String, cause: Throwable) : Exception("Cloudflare: $url", cause)

    private fun isDns(e: Throwable): Boolean {
        var t: Throwable? = e
        while (t != null) {
            if (t is java.net.UnknownHostException) return true
            t = t.cause
        }
        return false
    }

    fun <T> withDomainFallback(id: String, block: () -> T): T {
        try {
            return block()
        } catch (e: Throwable) {
            if (id.isEmpty() || !isDns(e)) throw e
            val p = try { parser(id) } catch (_: Throwable) { throw e }
            val current = try { p.domain } catch (_: Throwable) { "" }
            val presets = try {
                (p.javaClass.methods.firstOrNull { it.name == "getConfigKeyDomain" }?.invoke(p) as? ConfigKey.Domain)
                    ?.presetValues?.toList().orEmpty()
            } catch (_: Throwable) {
                emptyList()
            }
            for (d in presets) {
                if (d == current) continue
                val ok = try { YomiNet.dns.lookup(d).isNotEmpty() } catch (_: Throwable) { false }
                if (!ok) continue
                context.setDomain(p.source, d)
                domainCache.remove(id)
                try {
                    return block()
                } catch (_: Throwable) {
                }
            }
            context.setDomain(p.source, null)
            throw e
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

    private fun parser(id: String): MangaParser {
        parsers[id]?.let { return it }
        val src = sources[id] ?: throw IllegalArgumentException("Unknown Kotatsu source $id")
        val p = forkFactories[id]?.invoke(src)
            ?: context.newParserInstance(src as MangaParserSource)
        parsers[id] = p
        return p
    }

    private val domainCache = ConcurrentHashMap<String, String>()

    private fun domainsJson(): JSONObject {
        val o = JSONObject()
        for ((key, src) in sources) {
            val d = domainCache[key] ?: try {
                (parsers[key] ?: context.newParserInstance(src as MangaParserSource)).domain
            } catch (_: Throwable) {
                null
            }
            if (!d.isNullOrEmpty()) {
                domainCache[key] = d
                o.put(key, d)
            }
        }
        return o
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
        // YomiHub 0.1.9: the whole Kotatsu filter model (as in Kotatsu's own
        // filter sheet), not only tags / states / ratings
        o.put("year", caps.isYearSupported)
        o.put("yearRange", caps.isYearRangeSupported)
        o.put("originalLocale", caps.isOriginalLocaleSupported)
        o.put("author", caps.isAuthorSearchSupported)
        try {
            val opts = p.getFilterOptions()
            o.put("tags", JSONArray(opts.availableTags.sortedBy { it.title }.map {
                JSONObject().put("title", it.title).put("key", it.key)
            }))
            o.put("states", JSONArray(opts.availableStates.map { it.name }))
            o.put("ratings", JSONArray(opts.availableContentRating.map { it.name }))
            o.put("types", JSONArray(opts.availableContentTypes.map { it.name }))
            o.put("demographics", JSONArray(opts.availableDemographics.map { it.name }))
            o.put("locales", JSONArray(opts.availableLocales.map {
                JSONObject().put("key", it.toLanguageTag()).put("title", it.getDisplayName(it).replaceFirstChar { c -> c.uppercase() })
            }))
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
        fun <E : Enum<E>> enums(key: String, parse: (String) -> E): Set<E> {
            val out = HashSet<E>()
            f.optJSONArray(key)?.let { a ->
                for (i in 0 until a.length()) try {
                    out += parse(a.getString(i))
                } catch (_: Throwable) {
                }
            }
            return out
        }
        val types = enums("types") { org.koitharu.kotatsu.parsers.model.ContentType.valueOf(it) }
        val demos = enums("demographics") { org.koitharu.kotatsu.parsers.model.Demographic.valueOf(it) }
        val locale = f.optString("locale").takeIf { it.isNotEmpty() }?.let { Locale.forLanguageTag(it) }
        val origLocale = f.optString("originalLocale").takeIf { it.isNotEmpty() }?.let { Locale.forLanguageTag(it) }
        val yearOf = { k: String -> f.optInt(k, 0).takeIf { it in 1900..2100 } ?: org.koitharu.kotatsu.parsers.model.YEAR_UNKNOWN }
        val filter = MangaListFilter(
            query = query,
            tags = tagSet,
            tagsExclude = exclude,
            locale = locale,
            originalLocale = origLocale,
            states = states,
            contentRating = ratings,
            types = types,
            demographics = demos,
            year = yearOf("year"),
            yearFrom = yearOf("yearFrom"),
            yearTo = yearOf("yearTo"),
            author = f.optString("author").takeIf { it.isNotBlank() },
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
                val id = q["source"] ?: ""
                if (session.uri == "/kotatsu/setCookies") {
                    // cookies + UA from the app's WebView (Cloudflare solved there)
                    val url = q["url"] ?: ""
                    val ua = q["ua"] ?: ""
                    val host = try { java.net.URI(url).host ?: "" } catch (_: Throwable) { "" }
                    if (host.isNotEmpty() && ua.isNotEmpty()) hostUa[host.removePrefix("www.")] = ua
                    val hu = okhttp3.HttpUrl.Builder().scheme("https").host(host.ifEmpty { "localhost" }).build()
                    val list = (q["cookies"] ?: "").split(";").mapNotNull { okhttp3.Cookie.parse(hu, it.trim()) }
                    Store.cookieJar.saveFromResponse(hu, list)
                    return json("{\"ok\":true}")
                }
                if (session.uri == "/kotatsu/setDomain") {
                    val src = sources[id] ?: throw IllegalArgumentException("Unknown Kotatsu source $id")
                    context.setDomain(src, q["domain"]?.removePrefix("https://")?.removePrefix("http://")?.trimEnd('/'))
                    domainCache.remove(id)
                    return json("{\"ok\":true}")
                }
                withDomainFallback(id) { withCf(id) {
                    runBlocking(Dispatchers.IO) {
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
                            "/kotatsu/domains" -> json(domainsJson().toString())
                            "/kotatsu/ping" -> json("{\"ok\":true,\"sources\":${sources.size}}")
                            else -> newFixedLengthResponse(Response.Status.NOT_FOUND, "text/plain", "not found")
                        }
                    }
                } }
            } catch (e: Throwable) {
                val o = JSONObject().put(
                    "error",
                    (YomiNet.describe(e) ?: e.message ?: "").ifBlank { e.javaClass.simpleName },
                )
                if (e is CfFailed) o.put("cloudflare", true).put("url", e.url).put("code", 403)
                newFixedLengthResponse(Response.Status.INTERNAL_ERROR, "application/json", o.toString())
            }
        }

        private fun json(text: String) = newFixedLengthResponse(Response.Status.OK, "application/json; charset=utf-8", text)
    }

    // ───────────── loader context (desktop) ─────────────

    class Ctx : MangaLoaderContext() {
        private val ua =
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36"

        override val cookieJar: CookieJar = Store.cookieJar

        override val httpClient: OkHttpClient = YomiNet.apply(OkHttpClient.Builder())
            .cookieJar(cookieJar)
            .connectTimeout(20, TimeUnit.SECONDS)
            .readTimeout(60, TimeUnit.SECONDS)
            .addInterceptor { chain ->
                val r = chain.request()
                val cfUa = KotatsuJvm.uaFor(r.url.host)
                chain.proceed(
                    when {
                        cfUa != null -> r.newBuilder().header("User-Agent", cfUa).build()
                        r.header("User-Agent") == null -> r.newBuilder().header("User-Agent", ua).build()
                        else -> r
                    },
                )
            }
            .build()

        override fun encodeBase64(data: ByteArray): String = Base64.getEncoder().encodeToString(data)

        override fun decodeBase64(data: String): ByteArray = Base64.getMimeDecoder().decode(data)

        override fun getPreferredLocales(): List<Locale> = listOf(Locale.getDefault(), Locale.ENGLISH)

        @Deprecated("Provide a base url")
        override suspend fun evaluateJs(script: String): String? = null

        // no headless browser on the desktop bridge: parsers that need it
        // report an error (same as Kotatsu without WebView)
        override suspend fun evaluateJs(baseUrl: String, script: String, timeout: Long): String? = null

        override fun getConfig(source: MangaSource): MangaSourceConfig = object : MangaSourceConfig {
            @Suppress("UNCHECKED_CAST")
            override fun <T> get(key: ConfigKey<T>): T {
                val k = "kt_${source.name}_${key.key}"
                val def = key.defaultValue
                if (key is ConfigKey.Domain) {
                    val o = Store.get("kt_${source.name}_domainOverride")
                    if (!o.isNullOrBlank()) return o as T
                }
                return when (def) {
                    is Boolean -> (Store.get(k)?.toBooleanStrictOrNull() ?: def) as T
                    is String -> (Store.get(k) ?: def) as T
                    else -> def
                }
            }
        }

        fun setDomain(source: MangaSource, domain: String?) {
            Store.put("kt_${source.name}_domainOverride", domain?.takeIf { it.isNotBlank() })
        }

        override fun getDefaultUserAgent(): String = ua

        override fun redrawImageResponse(response: Response, redraw: (image: Bitmap) -> Bitmap): Response {
            val bytes = response.body.bytes()
            val img = try {
                ImageIO.read(ByteArrayInputStream(bytes))
            } catch (_: Throwable) {
                null
            } ?: return response.newBuilder().body(bytes.toResponseBody(response.body.contentType())).build()
            val argb = BufferedImage(img.width, img.height, BufferedImage.TYPE_INT_ARGB)
            argb.createGraphics().apply { drawImage(img, 0, 0, null); dispose() }
            val out = redraw(AwtBitmap(argb)) as AwtBitmap
            val baos = ByteArrayOutputStream()
            ImageIO.write(out.image, "png", baos)
            return response.newBuilder().body(baos.toByteArray().toResponseBody("image/png".toMediaType())).build()
        }

        override fun createBitmap(width: Int, height: Int): Bitmap =
            AwtBitmap(BufferedImage(width, height, BufferedImage.TYPE_INT_ARGB))
    }

    class AwtBitmap(val image: BufferedImage) : Bitmap {
        override val width: Int get() = image.width
        override val height: Int get() = image.height
        override fun drawBitmap(sourceBitmap: Bitmap, src: Rect, dst: Rect) {
            val s = (sourceBitmap as AwtBitmap).image
            val g = image.createGraphics()
            g.drawImage(s, dst.left, dst.top, dst.right, dst.bottom, src.left, src.top, src.right, src.bottom, null)
            g.dispose()
        }
    }
}
