// Dâm Cô Nương (18+) – truyện tranh 18+, manhwa. Bundled with YomiHub.
// 0.3.6: rewritten for the current site (damconuong.pet / .name now move to
// damconuong.win). Note: the site now draws many chapters as scrambled
// images on <canvas> with an obfuscated decoder; such chapters are read
// through the extension's WebView (open the chapter in WebView).
const DCN_MIRRORS = ["https://damconuong.win", "https://damconuong.pet", "https://damconuong.name"];
const DCN_GENRES = [
  ["Tất cả", ""], ["Manhwa", "manhwa"], ["Manga", "manga"], ["Màu", "full-color"], ["NTR", "ntr"], ["Học đường", "school-life"],
  ["Milf", "milf"], ["Harem", "harem"], ["Romance", "romance"], ["Drama", "drama"], ["Action", "action"], ["3D", "3d-hentai"],
];

class DefaultExtension extends MProvider {
  constructor() { super(); this.client = new Client(); }
  get supportsLatest() { return true; }
  base() { return yhBase(this); }
  getHeaders(url) { return { "User-Agent": YH_UA, "Referer": this.base() + "/" }; }
  async get(path) {
    const first = this.base();
    let err = null;
    for (const h of [first].concat(DCN_MIRRORS.filter((m) => m !== first))) {
      try {
        const r = await this.client.get(h + path, this.getHeaders(h + path));
        if (r.statusCode < 400 && r.body) return r.body;
        err = new Error("HTTP " + r.statusCode);
      } catch (e) { err = e; }
    }
    throw new Error("Dâm Cô Nương: không tải được trang (" + (err && err.message || err) + ") – thử bật DNS/VPN hoặc đổi tên miền.");
  }
  pathOf(u) { return ("" + u).replace(/^https?:\/\/[^/]+/, ""); }
  parse(html) {
    const doc = new Document(html);
    const list = [];
    const seen = {};
    for (const a of doc.select('a[href*="/truyen/"]')) {
      const href = this.pathOf(a.getHref || "");
      if (!/^\/truyen\/[^/]+\/?$/.test(href) || seen[href]) continue;
      const img = a.selectFirst("img");
      if (!img) continue;
      seen[href] = 1;
      list.push({ name: yhText(a.attr("title") || img.attr("alt")), link: href, imageUrl: img.attr("data-src") || img.attr("src") || "" });
    }
    return { list, hasNextPage: /[?&]page=\d+/.test(html) && list.length >= 12 };
  }
  async getPopular(page) { return this.parse(await this.get(`/danh-sach?sort=views&page=${page}`)); }
  async getLatestUpdates(page) { return this.parse(await this.get(`/danh-sach?page=${page}`)); }
  async search(query, page, filters) {
    query = (query || "").trim();
    if (query) {
      // the site's own live search (JSON) – the /tim-kiem page ignores the keyword
      try {
        const r = await this.client.get(`${this.base()}/live-search?q=${encodeURIComponent(query)}`, Object.assign({ "Accept": "application/json", "X-Requested-With": "XMLHttpRequest" }, this.getHeaders()));
        const d = JSON.parse(r.body || "{}");
        const arr = d.data || d.results || d.mangas || (Array.isArray(d) ? d : []);
        if (arr.length) return { list: arr.map((m) => ({ name: m.name || m.title, link: "/truyen/" + (m.slug || ""), imageUrl: m.cover_full_url || m.cover_url || m.cover || m.thumbnail || "" })), hasNextPage: false };
      } catch (e) {}
      const res = this.parse(await this.get(`/tim-kiem?keyword=${encodeURIComponent(query)}&page=${page}`));
      const qn = query.toLowerCase();
      res.list = res.list.filter((m) => m.name.toLowerCase().includes(qn));
      return res;
    }
    const g = yhF(filters, "genre");
    return g ? this.parse(await this.get(`/the-loai/${g}?page=${page}`)) : this.getLatestUpdates(page);
  }
  async getDetail(url) {
    const path = this.pathOf(url).replace(/\/+$/, "");
    const html = await this.get(path);
    const doc = new Document(html);
    const meta = (p) => { const e = doc.selectFirst(`meta[property="${p}"], meta[name="${p}"]`); return e ? e.attr("content") : ""; };
    const h1 = doc.selectFirst("h1.md-title, h1");
    const chapters = [];
    const seen = {};
    for (const a of doc.select("a.md-ch, a[href*='/chapter-']")) {
      const href = this.pathOf(a.getHref || "");
      if (!href.startsWith(path + "/") || seen[href]) continue;
      seen[href] = 1;
      const t = a.selectFirst(".md-ch-title");
      chapters.push({ name: yhText(t ? t.text : a.text).replace(/\s+·.*$/, ""), url: href });
    }
    const genres = doc.select('a[href*="/the-loai/"]').map((a) => yhText(a.text)).filter((x) => x && x.length < 30);
    return {
      name: h1 ? yhText(h1.text) : meta("og:title").replace(/\s*-\s*Dâm Cô Nương.*$/, ""),
      imageUrl: meta("og:image"),
      description: yhText(meta("og:description")),
      genre: [...new Set(genres)].slice(0, 12),
      status: yhStatus(html.match(/Hoàn thành|Đang tiến hành|Đang cập nhật/) ? (html.match(/Hoàn thành|Đang tiến hành|Đang cập nhật/)[0]) : ""),
      chapters,
    };
  }
  async getPageList(url) {
    const html = await this.get(this.pathOf(url));
    const doc = new Document(html);
    const pages = [];
    for (const img of doc.select("#chapter-content img, img.chapter-img")) {
      const src = img.attr("data-src") || img.attr("data-original") || img.attr("src") || "";
      if (src && !/^data:|default\/|ads\//.test(src) && !pages.includes(src)) pages.push(src);
    }
    if (pages.length) return pages.map((u) => ({ url: u, headers: { "Referer": this.base() + "/" } }));
    if (/data-cipher-path/.test(html)) {
      throw new Error("Chương này dùng ảnh mã hoá của Dâm Cô Nương – mở chương bằng WebView (biểu tượng quả địa cầu) để đọc.");
    }
    throw new Error("Dâm Cô Nương: không tìm thấy ảnh của chương.");
  }
  getFilterList() { return [yhHeader("Bộ lọc dùng khi ô tìm kiếm trống"), yhSelect("genre", "Thể loại", DCN_GENRES)]; }
  getSourcePreferences() { return [yhDomainPref("https://damconuong.win", "cũ: damconuong.pet, damconuong.name")]; }
}
