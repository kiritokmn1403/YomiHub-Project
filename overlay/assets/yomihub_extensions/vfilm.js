// vFilm (vfilm.vn) – phim lẻ, phim bộ, phim Việt. Bundled with YomiHub.
// 0.3.6: rewritten for vfilm.vn (the address in the "Website Extension"
// sheet; vfilm.tv no longer exists). Full episodes on vFilm need a vFilm /
// VinaPhone account: log in once in the extension's WebView, the session
// cookie is then used here. Trailers play without an account.
const VF_LISTS = [
  ["Phim lẻ", "phim-le.html"], ["Phim bộ", "phim-bo.html"], ["Phim chiếu rạp", "phim-le/phim-chieu-rap.htm"], ["Hành động", "phim-le/phim-hanh-dong.htm"],
  ["Hài", "phim-le/phim-hai.htm"], ["Hoạt hình", "phim-le/phim-hoat-hinh.htm"], ["Kinh dị", "phim-le/phim-kinh-di.htm"], ["Tâm lý", "phim-le/phim-tam-ly.htm"],
  ["Viễn tưởng", "phim-le/phim-vien-tuong.htm"], ["Võ thuật", "phim-le/phim-vo-thuat.htm"], ["Kiếm hiệp", "phim-le/phim-kiem-hiep.htm"], ["Cách mạng", "phim-le/phim-cach-mang.htm"],
];

class DefaultExtension extends MProvider {
  constructor() { super(); this.client = new Client(); }
  get supportsLatest() { return true; }
  base() { return yhBase(this); }
  getHeaders(url) { return { "User-Agent": YH_UA, "Referer": this.base() + "/" }; }
  async get(url) {
    const r = await this.client.get(url, this.getHeaders(url));
    if (r.statusCode >= 400) throw new Error("vFilm: HTTP " + r.statusCode + " – " + url);
    return r.body || "";
  }
  parse(html) {
    const doc = new Document(html);
    const list = [];
    const seen = {};
    for (const it of doc.select(".content-film-item, .item-film, .film-item")) {
      const a = it.selectFirst("h3 a, a");
      if (!a) continue;
      const href = a.getHref;
      if (!href || seen[href] || !/\.html$/.test(href) || /\/(phim-le|phim-bo)\.html$/.test(href)) continue;
      seen[href] = 1;
      const img = it.selectFirst("img");
      const name = yhText((img && img.attr("alt")) || a.text);
      list.push({ name, link: href.replace(/^https?:\/\/[^/]+/, ""), imageUrl: img ? (img.attr("data-src") || img.attr("src")) : "" });
    }
    return { list, hasNextPage: false };
  }
  async getPopular(page) { return page > 1 ? { list: [], hasNextPage: false } : this.parse(await this.get(this.base() + "/phim-le.html")); }
  async getLatestUpdates(page) { return page > 1 ? { list: [], hasNextPage: false } : this.parse(await this.get(this.base() + "/phim-bo.html")); }
  async search(query, page, filters) {
    if (page > 1) return { list: [], hasNextPage: false };
    query = (query || "").trim();
    if (query) return this.parse(await this.get(`${this.base()}/Home/filter?keyword=${encodeURIComponent(query)}`));
    return this.parse(await this.get(`${this.base()}/${yhF(filters, "list") || "phim-le.html"}`));
  }
  async getDetail(url) {
    const html = await this.get(this.base() + url);
    const doc = new Document(html);
    const meta = (p) => { const e = doc.selectFirst(`meta[property="${p}"], meta[name="${p}"]`); return e ? e.attr("content") : ""; };
    const h1 = doc.selectFirst("h1.title-film, h1");
    const episodes = [];
    const seen = {};
    for (const a of doc.select("a.play-video")) {
      const key = a.attr("data-key"), item = a.attr("data-item");
      if (!key || seen[key + item]) continue;
      seen[key + item] = 1;
      const lb = yhText(a.text);
      episodes.push({ name: /^\d+$/.test(lb) ? "Tập " + lb : (lb || "Tập " + (parseInt(item) + 1)), url: url + "|" + key + "|" + item });
    }
    if (!episodes.length) episodes.push({ name: "Phim", url: url + "||" });
    episodes.reverse();
    const genres = doc.select('a[href$=".htm"]').map((a) => yhText(a.text)).filter((x) => /^Phim/i.test(x)).slice(0, 5);
    let name = h1 ? yhText(h1.text) : meta("og:title");
    return {
      name,
      imageUrl: meta("og:image"),
      description: yhText(meta("og:description")),
      genre: [...new Set(genres)],
      status: 1,
      link: this.base() + url,
      episodes,
    };
  }
  async getVideoList(url) {
    const [path, key, item] = ("" + url).split("|");
    const videos = [];
    const hdr = { "User-Agent": YH_UA, "Referer": this.base() + path };
    if (key) {
      try {
        const r = await this.client.post(this.base() + "/Films/ajaxChooseFilm", Object.assign({ "X-Requested-With": "XMLHttpRequest", "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8" }, hdr), "key=" + encodeURIComponent(key) + "&item=" + encodeURIComponent(item));
        const d = JSON.parse(r.body || "{}");
        const ls = d.linkStreaming && typeof d.linkStreaming === "object" ? Object.values(d.linkStreaming) : [];
        for (const s of ls) if (s && s.file) videos.push({ url: s.file, originalUrl: s.file, quality: "vFilm " + (s.label || ""), headers: hdr });
      } catch (e) {}
    }
    const html = await this.get(this.base() + path);
    const tr = html.match(/var\s+b\s*=\s*'(\{[\s\S]*?\})';/);
    if (tr) {
      try {
        const b = JSON.parse(tr[1]);
        for (const k of Object.keys(b)) if (b[k].file) videos.push({ url: b[k].file, originalUrl: b[k].file, quality: "Trailer " + (b[k].label || ""), headers: hdr });
      } catch (e) {}
    }
    if (!videos.some((v) => !/^Trailer/.test(v.quality))) {
      videos.push({ url: "yhweb:" + this.base() + path, originalUrl: this.base() + path, quality: "Trang vFilm (cần đăng nhập để xem trọn bộ)", headers: hdr });
    }
    return videos;
  }
  getFilterList() { return [yhHeader("Bộ lọc dùng khi ô tìm kiếm trống"), yhSelect("list", "Danh sách", VF_LISTS)]; }
  getSourcePreferences() { return [yhDomainPref("http://vfilm.vn")]; }
}
