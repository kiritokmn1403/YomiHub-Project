// CBHentai (HentaiCube) – manga 18+ Vietsub. Bundled with YomiHub.
// 0.3.6: rewritten as a proper WordPress "Madara" source (the theme the site
// uses): paged lists /manga/page/N/?m_orderby=…, chapter list through
// /manga/<slug>/ajax/chapters/, images .page-break img. Both addresses from
// the "Website Extension" sheet (hentaicube.xyz, 2tencb.pro) are behind a
// Cloudflare check: solve it once in the extension's WebView.
const CB_MIRRORS = ["https://hentaicube.xyz", "https://2tencb.pro"];
const CB_SORT = [["Mới cập nhật", "latest"], ["Xem nhiều", "views"], ["Thịnh hành", "trending"], ["Đánh giá", "rating"], ["Mới", "new-manga"], ["A-Z", "alphabet"]];
const CB_GENRES = [
  ["Tất cả", ""], ["Manhwa", "manhwa"], ["Manga", "manga"], ["Full color", "full-color"], ["NTR", "ntr"], ["Học đường", "school-uniform"],
  ["Milf", "milf"], ["Harem", "harem"], ["Ngực lớn", "big-boobs"], ["Không che", "uncensored"], ["Romance", "romance"], ["Vanilla", "vanilla"],
];

class DefaultExtension extends MProvider {
  constructor() { super(); this.client = new Client(); }
  get supportsLatest() { return true; }
  base() { return yhBase(this); }
  getHeaders(url) { return { "User-Agent": YH_UA, "Referer": this.base() + "/", "Accept": "text/html,application/xhtml+xml,*/*;q=0.8" }; }
  async get(url) {
    let err = null;
    const path = url.replace(/^https?:\/\/[^/]+/, "");
    const first = url.replace(path, "");
    for (const h of [first].concat(CB_MIRRORS.filter((m) => m !== first))) {
      try {
        const r = await this.client.get(h + path, this.getHeaders(h + path));
        if (r.statusCode < 400 && r.body && !/<title>Just a moment/i.test(r.body)) return r.body;
        err = new Error("HTTP " + r.statusCode);
      } catch (e) { err = e; }
    }
    throw new Error("CBHentai: không tải được trang (" + (err && err.message || err) + "). Trang dùng Cloudflare: mở WebView của tiện ích, xác minh rồi thử lại.");
  }
  parse(html) {
    const doc = new Document(html);
    const list = [];
    const seen = {};
    for (const it of doc.select(".page-item-detail, .c-tabs-item__content, .manga-item")) {
      const a = it.selectFirst(".post-title a, h3 a, h4 a, .item-thumb a, a[href*='/manga/'], a[href*='/read/']");
      if (!a) continue;
      const link = a.getHref;
      if (!link || seen[link] || (!/\/manga\//.test(link) && !/\/read\//.test(link))) continue;
      seen[link] = 1;
      const img = it.selectFirst("img");
      const ch = it.selectFirst(".chapter a, .chapter-item a");
      const name = yhText(a.text || a.attr("title") || (img ? img.attr("alt") : ""));
      if (!name) continue;
      const src = img ? (img.attr("data-src") || img.attr("data-lazy-src") || img.attr("srcset").split(" ")[0] || img.attr("src")) : "";
      list.push({ name: name + (ch ? " (" + yhText(ch.text) + ")" : ""), link: link.replace(/^https?:\/\/[^/]+/, ""), imageUrl: (src || "").trim() });
    }
    const hasNextPage = doc.selectFirst(".nav-previous a, a.nextpostslink, .wp-pagenavi a.next, a.next, .pagination .next") != null;
    return { list, hasNextPage };
  }
  async listing(sort, page, genre) {
    const p = genre ? `/manga-genre/${genre}/` : "/manga/";
    return this.parse(await this.get(`${this.base()}${p}${page > 1 ? "page/" + page + "/" : ""}?m_orderby=${sort}`));
  }
  async getPopular(page) { return this.listing("views", page); }
  async getLatestUpdates(page) { return this.listing("latest", page); }
  async search(query, page, filters) {
    const q = (query || "").trim();
    if (q) return this.parse(await this.get(`${this.base()}/${page > 1 ? "page/" + page + "/" : ""}?s=${encodeURIComponent(q)}&post_type=wp-manga`));
    return this.listing(yhF(filters, "sort") || "latest", page, yhF(filters, "genre") || "");
  }
  async getDetail(url) {
    const path = ("" + url).replace(/^https?:\/\/[^/]+/, "");
    const html = await this.get(this.base() + path);
    const doc = new Document(html);
    const title = yhText((doc.selectFirst(".post-title h1, h1") || { text: "" }).text);
    const desc = yhText((doc.selectFirst(".description-summary, .summary__content, .manga-excerpt") || { text: "" }).text);
    const img = doc.selectFirst(".summary_image img, .tab-summary img");
    const cover = img ? (img.attr("data-src") || img.attr("data-lazy-src") || img.attr("src") || "").trim() : "";
    const genre = doc.select(".genres-content a").map((a) => yhText(a.text)).filter(Boolean);
    const author = doc.select(".author-content a").map((a) => yhText(a.text)).join(", ");
    const statusEl = doc.select(".post-status .summary-content, .post-content_item").map((e) => yhText(e.text)).join(" ");
    const collect = (d) => d.select("li.wp-manga-chapter a, .wp-manga-chapter > a, ul.main.version-chap li a, .chapter-list a, .listing-chapters_wrap a").map((a) => ({ name: yhText(a.text), url: (a.getHref || "").replace(/^https?:\/\/[^/]+/, "") })).filter((c) => c.url && c.name);
    let chapters = collect(doc);
    if (!chapters.length) {
      // Madara: chapters come from an AJAX endpoint
      try {
        const slugUrl = this.base() + path.replace(/\/?$/, "/");
        const r = await this.client.post(slugUrl + "ajax/chapters/", Object.assign({ "X-Requested-With": "XMLHttpRequest", "Content-Type": "application/x-www-form-urlencoded" }, this.getHeaders()), "");
        chapters = collect(new Document(r.body || ""));
      } catch (e) {}
      if (!chapters.length) {
        const id = (html.match(/data-id="(\d+)"/) || html.match(/"manga_id"\s*:\s*"?(\d+)/) || html.match(/data-post="(\d+)"/) || html.match(/data-post-id="(\d+)"/) || html.match(/post_id\s*=\s*"?(\d+)"?/) || html.match(/class="[^"]*rating-post-id[^"]*"[^>]*value="(\d+)"/) || html.match(/id="manga-chapters-holder"[^>]*data-id="(\d+)"/) || html.match(/input[A-Za-z0-9_\-\s]+value="(\d+)"[^>]*name="manga_id"/) || html.match(/postid-(\d+)/) || html.match(/id="post-(\d+)"/) || [])[1];
        if (id) {
          try {
            const r = await this.client.post(this.base() + "/wp-admin/admin-ajax.php", Object.assign({ "X-Requested-With": "XMLHttpRequest", "Content-Type": "application/x-www-form-urlencoded" }, this.getHeaders()), "action=manga_get_chapters&manga=" + id);
            chapters = collect(new Document(r.body || ""));
          } catch (e) {}
        }
      }
    }
    return { name: title || "CBHentai", description: desc, imageUrl: cover, genre, author, status: yhStatus(statusEl), chapters };
  }
  async getPageList(url) {
    const path = ("" + url).replace(/^https?:\/\/[^/]+/, "");
    const html = await this.get(this.base() + path);
    const doc = new Document(html);
    const pages = [];
    for (const img of doc.select(".reading-content img, .page-break img, img.wp-manga-chapter-img")) {
      const src = (img.attr("data-src") || img.attr("data-lazy-src") || img.attr("src") || "").trim();
      if (src && !/^data:/.test(src) && !pages.includes(src)) pages.push(src);
    }
    if (!pages.length) throw new Error("CBHentai: không tìm thấy ảnh của chương.");
    return pages.map((u) => ({ url: u, headers: { "Referer": this.base() + "/" } }));
  }
  getFilterList() {
    return [yhHeader("Bộ lọc dùng khi ô tìm kiếm trống"), yhSelect("sort", "Sắp xếp", CB_SORT), yhSelect("genre", "Thể loại", CB_GENRES)];
  }
  getSourcePreferences() { return [yhDomainPref("https://hentaicube.xyz", "phụ: 2tencb.pro")]; }
}
