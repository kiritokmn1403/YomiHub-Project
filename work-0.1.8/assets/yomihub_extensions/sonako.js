// Sonako – Light Novel tiếng Việt (sonako.fandom.com/vi). Bundled with YomiHub 0.1.5.
// Uses the wiki's MediaWiki API (parse / search / recentchanges). Fandom sits
// behind Cloudflare: the app's Cloudflare solver (WebView / CloudScraper)
// clears the challenge once, then the API answers normally. If the API is
// still blocked, chapters fall back to a hidden WebView render.
const SONAKO_SKIP = /^(Trang_Chính|Sonako_Light_Novel|Đặc_biệt|Thể_loại|Category|Tập_tin|File|Bản_mẫu|Template|Thảo_luận|Talk|Thành_viên|User|Sonako:|Trợ_giúp|Help|MediaWiki|Blog|Diễn_đàn|Forum|Message_Wall|Bức_tường)/i;

class DefaultExtension extends MProvider {
  constructor() {
    super();
    this.client = new Client();
  }
  get supportsLatest() { return true; }
  base() { return yhBase(this); }
  wiki() { return this.base() + "/vi"; }
  // No User-Agent here: the Cloudflare solver stores its own UA with the
  // cf_clearance cookie and the app adds both to every request.
  getHeaders(url) { return { "Referer": this.wiki() + "/" }; }

  async api(params) {
    const q = Object.keys(params).map((k) => k + "=" + encodeURIComponent(params[k])).join("&");
    const url = `${this.wiki()}/api.php?${q}&format=json&formatversion=2&origin=*`;
    let body = "";
    try { body = (await this.client.get(url, this.getHeaders(""))).body || ""; } catch (e) {}
    if (!body.trim().startsWith("{")) {
      // Cloudflare challenge: let a real (hidden) WebView pass it and read the JSON.
      const script = `(function(){var n=0;var t=setInterval(function(){n++;var b=(document.body&&document.body.innerText)||'';
        if(b.trim().charAt(0)==='{'||n>80){clearInterval(t);window.flutter_inappwebview.callHandler('setResponse', b);}},250);})();`;
      try { body = await evaluateJavascriptViaWebview(url, this.getHeaders(url), [script]); } catch (e) {}
    }
    if (!body || !body.trim().startsWith("{")) throw new Error("Fandom đang chặn (Cloudflare) – mở WebView của tiện ích để xác minh rồi thử lại");
    return JSON.parse(body);
  }
  titleOf(link) {
    let t = ("" + link).replace(/^https?:\/\/[^/]+/i, "").replace(/^\/vi\/wiki\//, "").replace(/^\/wiki\//, "");
    try { t = decodeURIComponent(t); } catch (e) {}
    return t.replace(/ /g, "_").split("#")[0];
  }
  pageUrl(title) { return `${this.wiki()}/wiki/${encodeURIComponent(title.replace(/ /g, "_")).replace(/%2F/g, "/").replace(/%3A/g, ":")}`; }
  series(title) { return title.replace(/ /g, "_").split(/[:/]/)[0]; }

  async covers(titles) {
    const out = {};
    for (let i = 0; i < titles.length; i += 40) {
      try {
        const r = await this.api({ action: "query", prop: "pageimages", piprop: "thumbnail", pithumbsize: "320", titles: titles.slice(i, i + 40).join("|") });
        for (const p of (r.query && r.query.pages) || []) {
          if (p.thumbnail) out[p.title.replace(/ /g, "_")] = p.thumbnail.source;
        }
      } catch (e) {}
    }
    return out;
  }
  async toList(titles, hasNextPage) {
    const uniq = [...new Set(titles.map((t) => t.replace(/ /g, "_")))].filter((t) => t && !SONAKO_SKIP.test(t));
    const cov = await this.covers(uniq);
    return {
      list: uniq.map((t) => ({ name: t.replace(/_/g, " "), link: this.pageUrl(t), imageUrl: cov[t] || "" })),
      hasNextPage,
    };
  }

  async getPopular(page) {
    // Series listed on the main "Sonako Light Novel" page, 40 per page.
    if (!this._all) {
      const r = await this.api({ action: "parse", page: "Sonako_Light_Novel", prop: "links" });
      this._all = ((r.parse && r.parse.links) || [])
        .filter((l) => l.ns === 0 && l.exists !== false)
        .map((l) => l.title.replace(/ /g, "_"))
        .filter((t) => !SONAKO_SKIP.test(t) && !/[:/]/.test(t));
    }
    const start = (page - 1) * 40;
    return this.toList(this._all.slice(start, start + 40), start + 40 < this._all.length);
  }
  async getLatestUpdates(page) {
    const r = await this.api({ action: "query", list: "recentchanges", rcnamespace: "0", rclimit: "200", rctype: "edit|new", rcprop: "title" });
    const ser = [];
    for (const c of (r.query && r.query.recentchanges) || []) {
      const s = this.series(c.title);
      if (!ser.includes(s)) ser.push(s);
    }
    const start = (page - 1) * 30;
    return this.toList(ser.slice(start, start + 30), start + 30 < ser.length);
  }
  async search(query, page, filters) {
    if (!query || !query.trim()) return this.getPopular(page);
    const r = await this.api({ action: "query", list: "search", srsearch: query.trim(), srnamespace: "0", srlimit: "30", sroffset: "" + (page - 1) * 30 });
    const ser = [];
    for (const s of (r.query && r.query.search) || []) {
      const t = this.series(s.title);
      if (!ser.includes(t)) ser.push(t);
    }
    return this.toList(ser, !!(r.continue));
  }

  async getDetail(url) {
    const title = this.titleOf(url);
    const r = await this.api({ action: "parse", page: title, prop: "text|displaytitle", redirects: "1" });
    const html = (r.parse && r.parse.text) || "";
    const doc = new Document(html);
    const name = yhText((r.parse && r.parse.displaytitle || title).replace(/<[^>]+>/g, "").replace(/_/g, " "));
    const img = doc.selectFirst("img[data-src], img[src]");
    let imageUrl = img ? (img.attr("data-src") || img.attr("src") || "") : "";
    if (imageUrl.startsWith("data:")) imageUrl = "";
    const description = doc.select("p").slice(0, 4).map((p) => yhText(p.text)).filter(Boolean).join("\n");
    const chapters = [];
    const seen = {};
    let vol = "";
    for (const el of doc.select("h2, h3, h4, a[href]")) {
      const tag = (el.tagName || el.localName || "").toLowerCase();
      if (/^h[2-4]$/.test(tag)) { vol = yhText(el.text).replace(/\[.*?\]/g, "").trim(); continue; }
      const href = el.attr("href") || "";
      if (!/^\/(vi\/)?wiki\//.test(href) || /action=|redlink=1/.test(href)) continue;
      const t = this.titleOf(href);
      if (SONAKO_SKIP.test(t) || t === title.replace(/ /g, "_") || seen[t]) continue;
      // chapter pages are sub-pages of the series or name a chapter/volume
      const own = t.startsWith(title.replace(/ /g, "_") + ":") || t.startsWith(title.replace(/ /g, "_") + "/");
      if (!own && !/(Chương|Chapter|Tập|Volume|Vol|Phần|Mở_đầu|Kết|Lời_bạt|Ngoại_truyện|Prologue|Epilogue|Minh_họa)/i.test(t)) continue;
      seen[t] = 1;
      const label = yhText(el.text) || t.replace(/_/g, " ");
      chapters.push({ name: vol ? `${vol} – ${label}` : label, url: this.pageUrl(t), scanlator: vol });
    }
    chapters.reverse();
    return { name, imageUrl, description, genre: [], status: 5, link: this.pageUrl(title), chapters };
  }

  async getHtmlContent(name, url) {
    const title = this.titleOf(url);
    try {
      const r = await this.api({ action: "parse", page: title, prop: "text", redirects: "1", disableeditsection: "1" });
      let html = (r.parse && r.parse.text) || "";
      html = html
        .replace(/<table[^>]*class="[^"]*(navbox|wikitable)[^"]*"[\s\S]*?<\/table>/gi, "")
        .replace(/<div[^>]*class="[^"]*(toc|navbox|printfooter)[^"]*"[\s\S]*?<\/div>/gi, "")
        .replace(/<span class="mw-editsection">[\s\S]*?<\/span>/gi, "")
        .replace(/<img([^>]*?)data-src="([^"]+)"/gi, '<img$1src="$2"');
      if (html.replace(/<[^>]+>/g, "").trim().length > 30) return html;
    } catch (e) {}
    const full = this.pageUrl(title);
    const script = `(function(){var n=0;var t=setInterval(function(){n++;var el=document.querySelector('.mw-parser-output');
      if(el||n>60){clearInterval(t);var c=el?el.cloneNode(true):null;
      if(c){c.querySelectorAll('script,style,noscript,.navbox,.toc,.mw-editsection').forEach(function(e){e.remove();});}
      window.flutter_inappwebview.callHandler('setResponse', c?c.innerHTML:'');}},250);})();`;
    try {
      const w = await evaluateJavascriptViaWebview(full, this.getHeaders(full), [script]);
      if (w && w.replace(/<[^>]+>/g, "").trim().length > 30) return w;
    } catch (e) {}
    return `<p>Không đọc được chương này (Fandom có thể đang yêu cầu xác minh Cloudflare – mở WebView của tiện ích rồi thử lại).</p><p><small>${full}</small></p>`;
  }
  async cleanHtmlContent(html) { return html; }
  getFilterList() { return [yhHeader("Sonako: tìm theo tên truyện")]; }
  getSourcePreferences() { return [yhDomainPref("https://sonako.fandom.com")]; }
}
