package yomihub.bridge

import fi.iki.elonen.NanoHTTPD
import ireader.core.http.HttpClients
import ireader.core.prefs.Preference
import ireader.core.prefs.PreferenceStore
import ireader.core.source.CatalogSource
import ireader.core.source.Dependencies
import ireader.core.source.model.ChapterInfo
import ireader.core.source.model.Filter
import ireader.core.source.model.FilterList
import ireader.core.source.model.ImageBase64
import ireader.core.source.model.ImageUrl
import ireader.core.source.model.MangaInfo
import ireader.core.source.model.MangasPageInfo
import ireader.core.source.model.PageUrl
import ireader.core.source.model.Text
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.runBlocking
import kotlinx.serialization.KSerializer
import kotlinx.serialization.json.Json
import kotlinx.serialization.modules.SerializersModule
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.net.URLClassLoader
import java.util.concurrent.ConcurrentHashMap
import java.util.zip.ZipFile

/**
 * YomiHub 0.2.1: the IReader bridge (YomiIReader.kt) for the Windows
 * version. IReader publishes a desktop build of every extension
 * (`jar/ireader-<lang>-<name>-v<ver>.jar` in IReader-extensions/repov2);
 * it is loaded with a URLClassLoader on top of IReader's desktop
 * source-api and served on the same loopback API (port 47360).
 */
object IReaderJvm {
    const val PORT = 47360
    private var server: Server? = null

    private val sources = ConcurrentHashMap<String, CatalogSource>()
    private val packages = ConcurrentHashMap<String, List<String>>()

    private val prefs by lazy { StorePrefs() }

    private val deps: Dependencies by lazy {
        Dependencies(HttpClients(prefs), prefs)
    }

    @Synchronized
    fun start() {
        if (server != null) return
        val srv = Server()
        srv.start(NanoHTTPD.SOCKET_READ_TIMEOUT, true)
        server = srv
    }

    /** Finds the extension entry class of a desktop extension jar. */
    private fun entryClass(jar: File, loader: ClassLoader): Class<*> {
        val names = ZipFile(jar).use { z ->
            z.entries().asSequence().map { it.name }.filter { it.endsWith(".class") && '$' !in it }
                .map { it.removeSuffix(".class").replace('/', '.') }.toList()
        }
        val preferred = listOf("tachiyomix.extension.Extension") + names.filter { it.endsWith(".Extension") }
        for (n in preferred + names) {
            val c = try {
                Class.forName(n, false, loader)
            } catch (_: Throwable) {
                continue
            }
            val ok = try {
                c.getConstructor(Dependencies::class.java); true
            } catch (_: Throwable) {
                false
            }
            if (ok) return c
        }
        throw IllegalStateException("${jar.name}: no IReader extension class")
    }

    /** Loads an extension jar; returns its sources as JSON. */
    @Synchronized
    fun load(jar: File): JSONArray {
        if (!jar.exists()) throw IllegalArgumentException("JAR not found: $jar")
        val loader = URLClassLoader(arrayOf(jar.toURI().toURL()), IReaderJvm::class.java.classLoader)
        val cls = entryClass(jar, loader)
        val obj = cls.getConstructor(Dependencies::class.java).newInstance(deps)
        val list = when (obj) {
            is CatalogSource -> listOf(obj)
            else -> try {
                @Suppress("UNCHECKED_CAST")
                (obj.javaClass.getMethod("createSources").invoke(obj) as List<Any>).filterIsInstance<CatalogSource>()
            } catch (_: Throwable) {
                emptyList()
            }
        }
        if (list.isEmpty()) throw IllegalStateException("${jar.name}: no IReader catalog source")
        val ids = ArrayList<String>()
        val arr = JSONArray()
        for (s in list) {
            val id = s.id.toString()
            sources[id] = s
            ids += id
            arr.put(
                JSONObject().put("id", id).put("name", s.name).put("lang", s.lang)
                    .put("baseUrl", baseUrlOf(s))
                    .put("latest", s.supportsLatest())
                    .put("search", s.supportsSearch()),
            )
        }
        packages[jar.nameWithoutExtension] = ids
        return arr
    }

    private fun baseUrlOf(s: CatalogSource): String = try {
        (s as? ireader.core.source.HttpSource)?.baseUrl ?: ""
    } catch (_: Throwable) {
        ""
    }

    private fun src(id: String): CatalogSource =
        sources[id] ?: throw IllegalStateException("IReader source $id is not loaded")

    // ───────────── filters ─────────────

    private fun filterJson(f: Filter<*>): JSONObject {
        val o = JSONObject().put("name", f.name)
        when (f) {
            is Filter.Note -> o.put("type", "note")
            is Filter.Text -> o.put("type", "text").put("value", f.value)
            is Filter.Check -> o.put("type", "check").put("value", when (f.value) {
                true -> 1
                false -> 2
                null -> 0
            }).put("tri", f.allowsExclusion)
            is Filter.Select -> o.put("type", "select").put("value", f.value)
                .put("options", JSONArray(f.options.toList()))
            is Filter.Sort -> o.put("type", "sort")
                .put("options", JSONArray(f.options.toList()))
                .put("index", f.value?.index ?: 0).put("ascending", f.value?.ascending ?: false)
            is Filter.Group -> o.put("type", "group").put("filters", JSONArray(f.filters.map { filterJson(it) }))
            else -> o.put("type", "note")
        }
        return o
    }

    @Suppress("UNCHECKED_CAST")
    private fun applyFilter(f: Filter<*>, v: JSONObject) {
        when (f) {
            is Filter.Text -> f.value = v.optString("value", "")
            is Filter.Check -> f.value = when (v.optInt("value", 0)) {
                1 -> true
                2 -> false
                else -> null
            }
            is Filter.Select -> f.value = v.optInt("value", 0)
            is Filter.Sort -> f.value = Filter.Sort.Selection(v.optInt("index", 0), v.optBoolean("ascending", false))
            is Filter.Group -> {
                val a = v.optJSONArray("filters") ?: return
                f.filters.forEachIndexed { i, c -> a.optJSONObject(i)?.let { applyFilter(c, it) } }
            }
            else -> {}
        }
    }

    private fun filtersJson(id: String): JSONArray =
        JSONArray(src(id).getFilters().map { filterJson(it) })

    // ───────────── content ─────────────

    private fun mangaJson(m: MangaInfo) = JSONObject()
        .put("name", m.title).put("link", m.key).put("imageUrl", m.cover)

    private fun pageJson(p: MangasPageInfo): JSONObject {
        val arr = JSONArray()
        p.mangas.forEach { if (it.key.isNotBlank()) arr.put(mangaJson(it)) }
        return JSONObject().put("list", arr).put("hasNextPage", p.hasNextPage)
    }

    private suspend fun list(id: String, q: Map<String, String>): JSONObject {
        val s = src(id)
        val page = (q["page"] ?: "1").toIntOrNull() ?: 1
        val query = q["query"]?.trim().orEmpty()
        val filterArg = q["filters"]?.takeIf { it.isNotBlank() }
        return when {
            query.isNotEmpty() || filterArg != null -> {
                val fl: FilterList = s.getFilters()
                filterArg?.let { raw ->
                    val a = JSONArray(raw)
                    fl.forEachIndexed { i, f -> a.optJSONObject(i)?.let { applyFilter(f, it) } }
                }
                if (query.isNotEmpty()) {
                    val title = fl.firstOrNull { it is Filter.Title } as? Filter.Title
                        ?: fl.firstOrNull { it is Filter.Text } as? Filter.Text
                    title?.value = query
                }
                pageJson(s.getMangaList(fl, page))
            }
            else -> {
                val listings = s.getListings()
                val pick = if (q["kind"] == "latest") {
                    listings.firstOrNull { it.name.contains("latest", true) || it.name.contains("update", true) }
                        ?: listings.getOrNull(1) ?: listings.firstOrNull()
                } else {
                    listings.firstOrNull { it.name.contains("popular", true) } ?: listings.firstOrNull()
                }
                pageJson(s.getMangaList(pick, page))
            }
        }
    }

    private suspend fun details(id: String, url: String, title: String, cover: String): JSONObject {
        val s = src(id)
        val base = MangaInfo(key = url, title = title, cover = cover)
        val m = try {
            s.getMangaDetails(base, emptyList())
        } catch (_: Throwable) {
            base
        }
        val chapters = s.getChapterList(m.copy(key = url), emptyList())
        val arr = JSONArray()
        // newest first, as Mangayomi lists chapters
        chapters.asReversed().forEach { c: ChapterInfo ->
            arr.put(
                JSONObject().put("name", c.name).put("url", c.key)
                    .put("dateUpload", if (c.dateUpload > 0) c.dateUpload.toString() else "").put("scanlator", c.scanlator),
            )
        }
        val status = when (m.status) {
            MangaInfo.ONGOING -> 0
            MangaInfo.COMPLETED, MangaInfo.PUBLISHING_FINISHED -> 1
            MangaInfo.ON_HIATUS -> 2
            MangaInfo.CANCELLED -> 3
            else -> 5
        }
        return JSONObject()
            .put("name", m.title.ifBlank { title })
            .put("imageUrl", m.cover.ifBlank { cover })
            .put("description", m.description)
            .put("author", m.author)
            .put("artist", m.artist)
            .put("status", status)
            .put("genre", JSONArray(m.genres))
            .put("chapters", arr)
    }

    private suspend fun content(id: String, url: String, name: String): JSONObject {
        val s = src(id)
        val pages = s.getPageList(ChapterInfo(key = url, name = name), emptyList())
        val text = StringBuilder()
        val images = JSONArray()
        for (p in pages) {
            when (p) {
                is Text -> if (p.text.isNotBlank()) text.append("<p>").append(escape(p.text)).append("</p>\n")
                is ImageUrl -> images.put(p.url)
                is ImageBase64 -> images.put("data:image/jpeg;base64," + p.data)
                is PageUrl -> images.put(p.url)
                else -> {}
            }
        }
        return JSONObject().put("html", text.toString()).put("images", images)
    }

    private fun escape(s: String) = s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
        .replace("\n", "<br>")

    // ───────────── HTTP server ─────────────

    private class Server : NanoHTTPD("127.0.0.1", PORT) {
        override fun serve(session: IHTTPSession): Response {
            val q = session.parameters.mapValues { it.value.firstOrNull() ?: "" }
            return try {
                val id = q["source"] ?: ""
                val body = runBlocking(Dispatchers.IO) {
                    when (session.uri) {
                        "/ireader/ping" -> JSONObject().put("ok", true).put("sources", sources.size).toString()
                        "/ireader/sources" -> JSONArray(sources.keys().toList()).toString()
                        "/ireader/load" -> load(java.io.File(q["path"] ?: "")).toString()
                        "/ireader/filters" -> filtersJson(id).toString()
                        "/ireader/list" -> list(id, q).toString()
                        "/ireader/details" -> details(id, q["url"] ?: "", q["title"] ?: "", q["cover"] ?: "").toString()
                        "/ireader/content" -> content(id, q["url"] ?: "", q["name"] ?: "").toString()
                        else -> null
                    }
                }
                if (body == null) {
                    newFixedLengthResponse(Response.Status.NOT_FOUND, "text/plain", "not found")
                } else {
                    newFixedLengthResponse(Response.Status.OK, "application/json; charset=utf-8", body)
                }
            } catch (e: Throwable) {
                newFixedLengthResponse(
                    Response.Status.INTERNAL_ERROR,
                    "application/json",
                    JSONObject().put("error", (e.message ?: "").ifBlank { e.javaClass.simpleName }).toString(),
                )
            }
        }
    }

    // ───────────── IReader preferences on the bridge store ─────────────

    private class StorePrefs : PreferenceStore {
        private inner class P<T>(
            private val k: String,
            private val def: T,
            private val read: (String) -> T,
            private val write: (T) -> String,
        ) : Preference<T> {
            private val key = "ir_$k"
            private val flow = MutableStateFlow(get())
            override fun key() = k
            override fun get(): T {
                val raw = Store.get(key) ?: return def
                return try {
                    read(raw)
                } catch (_: Throwable) {
                    def
                }
            }
            override fun set(value: T) {
                Store.put(key, write(value))
                flow.value = value
            }
            override fun isSet() = Store.contains(key)
            override fun delete() {
                Store.put(key, null)
                flow.value = def
            }
            override fun defaultValue() = def
            override fun changes(): Flow<T> = flow
            override fun stateIn(scope: CoroutineScope): StateFlow<T> = flow.stateIn(scope, SharingStarted.Eagerly, get())
        }

        override fun getString(key: String, defaultValue: String): Preference<String> = P(key, defaultValue, { it }, { it })
        override fun getLong(key: String, defaultValue: Long): Preference<Long> = P(key, defaultValue, { it.toLong() }, { it.toString() })
        override fun getInt(key: String, defaultValue: Int): Preference<Int> = P(key, defaultValue, { it.toInt() }, { it.toString() })
        override fun getFloat(key: String, defaultValue: Float): Preference<Float> = P(key, defaultValue, { it.toFloat() }, { it.toString() })
        override fun getBoolean(key: String, defaultValue: Boolean): Preference<Boolean> = P(key, defaultValue, { it.toBoolean() }, { it.toString() })
        override fun getStringSet(key: String, defaultValue: Set<String>): Preference<Set<String>> =
            P(key, defaultValue, { s -> JSONArray(s).let { a -> (0 until a.length()).map { a.getString(it) }.toSet() } }, { JSONArray(it.toList()).toString() })

        override fun <T> getObject(
            key: String,
            defaultValue: T,
            serializer: (T) -> String,
            deserializer: (String) -> T,
        ): Preference<T> = P(key, defaultValue, deserializer, serializer)

        override fun <T> getJsonObject(
            key: String,
            defaultValue: T,
            serializer: KSerializer<T>,
            serializersModule: SerializersModule,
        ): Preference<T> {
            val json = Json { this.serializersModule = serializersModule; ignoreUnknownKeys = true }
            return P(key, defaultValue, { json.decodeFromString(serializer, it) }, { json.encodeToString(serializer, it) })
        }
    }
}
