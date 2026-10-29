// HayChill (phimhaychill.org → phimhaychill.top) – phim bộ, phim lẻ Vietsub / thuyết minh. Bundled with YomiHub.
// 0.3.6: rewritten for the current site (WordPress VidoRev theme). Episodes
// are "?video_index=N" links; the HLS link of each one is in the page
// ("single_video_url" / "contentUrl").
const HC_MIRRORS = ["https://phimhaychill.top", "https://phimhaychill.org"];
const HC_LISTS = [
  ["Phim bộ hay", "phim-bo-hay"], ["Phim lẻ hay", "phim-le-hay"], ["Phim chiếu rạp", "phim-chieu-rap-hay"], ["Hoạt hình", "phim-hoat-hinh-hay"],
  ["Netflix", "phim-netflix"], ["TV Shows", "tv-shows"],
];
const HC_GENRES = [
  ["Tất cả", ""], ["Hành động", "phim-hanh-dong"], ["Cổ trang", "phim-co-trang"], ["Tình cảm", "phim-tinh-cam"], ["Hài", "phim-hai"],
  ["Kinh dị", "phim-kinh-di"], ["Viễn tưởng", "phim-vien-tuong"], ["Võ thuật", "phim-vo-thuat"], ["Hình sự", "phim-hinh-su"],
  ["Phiêu lưu", "phim-phieu-luu"], ["Tâm lý", "phim-tam-ly"], ["Thần thoại", "phim-than-thoai"],
];
const HC_COUNTRIES = [
  ["Tất cả", ""], ["Hàn Quốc", "phim-han-quoc"], ["Trung Quốc", "phim-trung-quoc"], ["Âu Mỹ", "phim-au-my"], ["Nhật Bản", "phim-nhat-ban"],
  ["Thái Lan", "phim-thai-lan"], ["Hồng Kông", "phim-hong-kong"], ["Đài Loan", "phim-dai-loan"], ["Việt Nam", "phim-viet-nam"],
];

class DefaultExtension extends MProvider {
  constructor() { super(); this.client = new Client(); }
  get supportsLatest() { return true; }
  base() { return yhBase(this); }
  getHeaders(url) { return { "User-Agent": YH_UA, "Referer": this.base() + "/" }; }
  async get(url) {
    let err = null;
    const path = url.replace(/^https?:\/\/[^/]+/, "");
    const hosts = [url.replace(path, "")].concat(HC_MIRRORS.filter((m) => !url.startsWith(m)));
    for (const h of hosts) {
      try {
        const r = await this.client.get(h + path, this.getHeaders(h + path));
        if (r.statusCode < 400 && r.body) return r.body;
        err = new Error("HTTP " + r.statusCode);
      } catch (e) { err = e; }
    }
    throw new Error("HayChill: không tải được " + url + " (" + (err && err.message || err) + ")");
  }
  pathOf(u) { return ("" + u).replace(/^https?:\/\/[^/]+/, "").replace(/\?.*$/, ""); }
  parse(html) {
    const doc = new Document(html);
    let items = doc.select(".main-content .blog-items-control article, main .blog-items-control article");
    if (!items.length) items = doc.select(".blog-items-control article");
    const list = [];
    const seen = {};
    for (const it of items) {
      const a = it.selectFirst(".entry-title a, a.blog-img");
      if (!a) continue;
      const href = a.getHref;
      if (!href || seen[href]) continue;
      seen[href] = 1;
      const img = it.selectFirst("img");
      const ep = it.selectFirst(".duration-text");
      const name = yhText(a.text || a.attr("title")).replace(/\s+(Vietsub|Thuyết Minh|Lồng Tiếng)(\s.*)?$/i, "");
      list.push({ name: name + (ep && yhText(ep.text) ? " (" + yhText(ep.text) + ")" : ""), link: this.pathOf(href), imageUrl: img ? (img.attr("data-src") || img.attr("src")) : "" });
    }
    return { list, hasNextPage: /\/page\/\d+\//.test(html) && list.length >= 8 };
  }
  async listing(path, page) { return this.parse(await this.get(`${this.base()}/${path}/${page > 1 ? "page/" + page + "/" : ""}`)); }
  async getPopular(page) { return this.listing("phim-bo-hay", page); }
  async getLatestUpdates(page) { return this.listing("phim-le-hay", page); }
  async search(query, page, filters) {
    query = (query || "").trim();
    if (query) return this.parse(await this.get(`${this.base()}/${page > 1 ? "page/" + page + "/" : ""}?s=${encodeURIComponent(query)}`));
    return this.listing(yhF(filters, "country") || yhF(filters, "genre") || yhF(filters, "list") || "phim-bo-hay", page);
  }
  async getDetail(url) {
    const path = this.pathOf(url);
    const html = await this.get(this.base() + path);
    const doc = new Document(html);
    const meta = (p) => { const e = doc.selectFirst(`meta[property="${p}"], meta[name="${p}"]`); return e ? e.attr("content") : ""; };
    const h1 = doc.selectFirst("h1.entry-title, h1");
    const eps = [];
    const seen = {};
    for (const a of doc.select("a.series-item")) {
      const href = a.getHref;
      if (!href || seen[href]) continue;
      seen[href] = 1;
      const label = yhText(a.text);
      eps.push({ name: /^\d+$/.test(label) ? "Tập " + label : (label || "Tập " + (eps.length + 1)), url: this.pathOf(href) + (href.includes("?") ? "?" + href.split("?")[1] : "") });
    }
    eps.sort((x, y) => yhEpNo(y.name) - yhEpNo(x.name));
    const cats = doc.select('a[rel="category tag"], .categories-wrap a').map((a) => yhText(a.text)).filter(Boolean);
    return {
      name: h1 ? yhText(h1.text).replace(/\s+(Vietsub|Thuyết Minh|Lồng Tiếng)(\s.*)?$/i, "") : meta("og:title"),
      imageUrl: meta("og:image"),
      description: yhText(meta("description") || meta("og:description")),
      genre: [...new Set(cats)],
      status: eps.length > 1 ? 0 : 1,
      link: this.base() + path,
      episodes: eps.length ? eps : [{ name: "Full", url: path }],
    };
  }
  async getVideoList(url) {
    const html = await this.get(this.base() + url);
    const hdr = { "User-Agent": YH_UA, "Referer": this.base() + "/" };
    const found = [];
    for (const re of [/"single_video_url":"([^"]+)"/g, /"contentUrl":"([^"]+)"/g, /<source[^>]+src="([^"]+\.m3u8[^"]*)"/g]) {
      let m;
      while ((m = re.exec(html)) !== null) {
        const u = yhJsonStr(m[1]);
        if (/^https?:/.test(u) && !found.includes(u)) found.push(u);
      }
    }
    const videos = [];
    found.forEach((u, i) => {
      if (/\.m3u8|\.mp4/i.test(u)) videos.push({ url: u, originalUrl: u, quality: "HayChill " + (i + 1), headers: hdr });
      else if (/youtube\.com|youtu\.be/.test(u)) return;
      else videos.push({ url: "yhweb:" + u, originalUrl: u, quality: "HayChill " + (i + 1) + " (web)", headers: hdr });
    });
    if (!videos.length) throw new Error("HayChill: tập này chưa có link phát.");
    return videos;
  }
  getFilterList() {
    return [
      yhHeader("Bộ lọc dùng khi ô tìm kiếm trống (Quốc gia > Thể loại > Danh sách)"),
      yhSelect("list", "Danh sách", HC_LISTS),
      yhSelect("genre", "Thể loại", HC_GENRES),
      yhSelect("country", "Quốc gia", HC_COUNTRIES),
    ];
  }
  getSourcePreferences() { return [yhDomainPref("https://phimhaychill.top", "địa chỉ cũ: phimhaychill.org")]; }
}
