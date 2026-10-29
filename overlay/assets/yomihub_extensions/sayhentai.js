// SayHentai (18+) – truyện hentai, manhwa 18+ Vietsub. Bundled with YomiHub.
// 0.3.6: rewritten for the current site (Madara-like layout behind
// Cloudflare – solve it once in the extension's WebView). Addresses from the
// "Website Extension" sheet: sayhentai.cx, sayhentais.com, sayhentaii.art.
const SH_MIRRORS = ["https://sayhentai.cx", "https://sayhentaii.art", "https://sayhentais.com"];
const SH_GENRES = [
  ["Tất cả", ""], ["Manhwa", "manhwa"], ["Manga", "manga"], ["Adult", "adult"], ["NTR", "ntr"], ["Harem", "harem"], ["Romance", "romance"],
  ["Fantasy", "fantasy"], ["Học đường", "school-life"], ["Drama", "drama"], ["Milf", "milf"], ["Ngực lớn", "nguc-lon"],
];

class DefaultExtension extends MProvider {
  constructor() { super(); this.client = new Client(); }
  get supportsLatest() { return true; }
  base() { return yhBase(this); }
  getHeaders(url) { return { "User-Agent": YH_UA, "Referer": this.base() + "/" }; }
  async get(path) {
    const first = this.base();
    let err = null;
    for (const h of [first].concat(SH_MIRRORS.filter((m) => m !== first))) {
      try {
        const r = await this.client.get(h + path, this.getHeaders(h + path));
        if (r.statusCode < 400 && r.body) return r.body;
        err = new Error("HTTP " + r.statusCode);
        if (r.statusCode === 403 || r.statusCode === 503) break; // Cloudflare: solve in WebView
      } catch (e) { err = e; }
    }
    throw new Error("SayHentai: không tải được trang (" + (err && err.message || err) + "). Nếu là Cloudflare, mở WebView của tiện ích để xác minh.");
  }
  pathOf(u) { return ("" + u).replace(/^https?:\/\/[^/]+/, ""); }
  parse(html) {
    const doc = new Document(html);
    const list = [];
    const seen = {};
    for (const it of doc.select(".page-item-detail, .item")) {
      const a = it.selectFirst(".item-thumb a, .img-item a, h3 a, a[href$='.html']");
      if (!a) continue;
      const href = this.pathOf(a.getHref);
      if (!/\.html$/.test(href) || seen[href]) continue;
      seen[href] = 1;
      const img = it.selectFirst("img");
      const ch = it.selectFirst(".chapter a, .chapter-item a");
      const name = yhText(a.attr("title") || (img ? img.attr("alt") : "") || a.text);
      if (!name) continue;
      list.push({ name: name + (ch ? " (" + yhText(ch.text) + ")" : ""), link: href, imageUrl: img ? (img.attr("data-src") || img.attr("src")) : "" });
    }
    return { list, hasNextPage: /[?&](?:amp;)?page=\d+/.test(html) && list.length >= 10 };
  }
  async getPopular(page) { return this.parse(await this.get(`/genre/manhwa?page=${page}`)); }
  async getLatestUpdates(page) { return this.parse(await this.get(`/?page=${page}`)); }
  async search(query, page, filters) {
    query = (query || "").trim();
    if (query) return this.parse(await this.get(`/search?s=${encodeURIComponent(query)}&page=${page}`));
    const g = yhF(filters, "genre");
    return this.parse(await this.get(g ? `/genre/${g}?page=${page}` : `/?page=${page}`));
  }
  async getDetail(url) {
    const path = this.pathOf(url);
    const html = await this.get(path);
    const doc = new Document(html);
    const h1 = doc.selectFirst("h1");
    const img = doc.selectFirst(".summary_image img");
    const desc = doc.selectFirst(".summary__content");
    let author = "", status = 5;
    const genre = [];
    for (const it of doc.select(".post-content_item")) {
      const t = yhText(it.text);
      if (/^Tác giả/.test(t)) author = t.replace(/^Tác giả\s*/, "");
      if (/Trạng thái|Tình trạng/.test(t)) status = yhStatus(t);
      if (/^Thể Loại/i.test(t)) it.select("a").forEach((a) => genre.push(yhText(a.text)));
    }
    const chapters = [];
    const seen = {};
    const add = (d) => {
      for (const li of d.select("li.wp-manga-chapter")) {
        const a = li.selectFirst("a");
        if (!a) continue;
        const href = this.pathOf(a.getHref);
        if (seen[href]) continue;
        seen[href] = 1;
        chapters.push({ name: yhText(a.text), url: href, dateUpload: "" });
      }
    };
    add(doc);
    const more = (html.match(/data-ajax-url="([^"]+)"/) || [])[1];
    if (more) {
      try {
        const r = await this.client.get(more, Object.assign({ "X-Requested-With": "XMLHttpRequest" }, this.getHeaders()));
        if (r.statusCode < 400) add(new Document("<ul>" + (r.body || "") + "</ul>"));
      } catch (e) {}
    }
    if (/Đang cập nhật|đang cập nhật/.test(desc ? desc.text : "")) status = 0;
    return {
      name: h1 ? yhText(h1.text) : "",
      imageUrl: img ? (img.attr("data-src") || img.attr("src")) : "",
      description: yhText(desc ? desc.text : ""),
      author,
      genre,
      status,
      chapters,
    };
  }
  async getPageList(url) {
    const html = await this.get(this.pathOf(url));
    const doc = new Document(html);
    const pages = [];
    for (const img of doc.select("img.chapter-img, .page-break img, .reading-content img")) {
      const src = (img.attr("data-src") || img.attr("src") || "").trim();
      if (src && !/^data:|logo|banner/.test(src) && !pages.includes(src)) pages.push(src);
    }
    if (!pages.length) throw new Error("SayHentai: không tìm thấy ảnh của chương.");
    return pages.map((u) => ({ url: u, headers: { "Referer": this.base() + "/" } }));
  }
  getFilterList() { return [yhHeader("Bộ lọc dùng khi ô tìm kiếm trống"), yhSelect("genre", "Thể loại", SH_GENRES)]; }
  getSourcePreferences() { return [yhDomainPref("https://sayhentai.cx", "phụ: sayhentais.com, sayhentaii.art")]; }
}
