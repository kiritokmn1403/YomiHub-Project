// HihiSex (18+). Bundled with YomiHub, đánh dấu NSFW.
// Trang WordPress: danh sách .video-item, tìm kiếm /search/<từ khoá>/page/N/,
// video là HLS (fqcdn) phát bằng Artplayer. Một số máy chủ gắn tiền tố ảnh
// vào đoạn TS; khi trình phát gốc không đọc được, YomiHub tự chuyển sang
// trình phát web của trang (mục "web").
const HH_CATS = [
  ["Mới nhất", ""],
  ["Phim hay", "page:phim-sex-hay"],
  ["Vietsub", "phim-sex-vietsub"],
  ["JAV", "phim-sex-jav"],
  ["Trung Quốc", "phim-sex-trung-quoc"],
  ["Mỹ – Châu Âu", "phim-sex-chau-au"],
  ["Không che", "phim-sex-khong-che"],
  ["HD", "phim-sex-hd"],
];

class DefaultExtension extends MProvider {
  constructor() { super(); this.client = new Client(); }
  get supportsLatest() { return true; }
  base() { return yhBase(this); }
  getHeaders(url) { return { "User-Agent": YH_UA, "Referer": this.base() + "/" }; }
  async doc(url) {
    const res = await this.client.get(url, this.getHeaders(url));
    if (res.statusCode === 404) return new Document("<html></html>");
    return new Document(res.body);
  }
  // [path] = "" (trang chủ), "page:<slug>", "<category slug>", "tag:<slug>"
  listUrl(path, page) {
    const b = this.base();
    let u = b + "/";
    if (path.startsWith("page:")) u = `${b}/${path.substring(5)}/`;
    else if (path.startsWith("tag:")) u = `${b}/tag/${path.substring(4)}/`;
    else if (path) u = `${b}/category/${path}/`;
    return page > 1 ? `${u}page/${page}/` : u;
  }
  parse(doc) {
    const list = [];
    const seen = {};
    for (const it of doc.select(".video-item")) {
      const a = it.selectFirst("a[href]");
      if (!a) continue;
      const link = a.getHref;
      if (!link || seen[link]) continue;
      seen[link] = 1;
      const img = it.selectFirst("img");
      const name = yhText(a.attr("title") || (img ? img.attr("alt") : "") || (it.selectFirst(".video-name") || {}).text);
      list.push({
        name,
        link,
        imageUrl: img ? (img.attr("data-src") || img.attr("data-lazy-src") || img.attr("src")) : "",
      });
    }
    const hasNextPage = doc.selectFirst(".pagenavi a.active + a") != null ||
      doc.select(".pagenavi a").some((x) => (x.text || "").includes("→"));
    return { list, hasNextPage };
  }
  async getPopular(page) { return this.parse(await this.doc(this.listUrl("page:phim-sex-hay", page))); }
  async getLatestUpdates(page) { return this.parse(await this.doc(this.listUrl("", page))); }
  async search(query, page, filters) {
    const q = (query || "").trim();
    if (q) {
      const u = `${this.base()}/search/${encodeURIComponent(q)}/` + (page > 1 ? `page/${page}/` : "");
      return this.parse(await this.doc(u));
    }
    const tag = ("" + (yhF(filters, "tag") || "")).trim().toLowerCase().replace(/\s+/g, "-");
    if (tag) return this.parse(await this.doc(this.listUrl("tag:" + tag, page)));
    return this.parse(await this.doc(this.listUrl(yhF(filters, "cat") || "", page)));
  }
  async getDetail(url) {
    const full = yhAbs(this.base(), url);
    const doc = await this.doc(full);
    const meta = (p) => { const e = doc.selectFirst(`meta[property="${p}"]`) || doc.selectFirst(`meta[name="${p}"]`); return e ? e.attr("content") : ""; };
    const name = yhText(meta("og:title").replace(/\s*[-|–]\s*Phim Sex HD\s*$/i, "")) ||
      yhText((doc.selectFirst("#video-player meta[itemprop=name], .video-name") || {}).text);
    const desc = doc.selectFirst(".video-description");
    const actors = doc.select(".category-tag a[rel=tag]").map((e) => yhText(e.text));
    const cats = doc.select(".category-tag a[rel='category tag']").map((e) => yhText(e.text));
    return {
      name,
      imageUrl: meta("og:image"),
      author: actors.join(", "),
      description: desc ? yhText(desc.text) : meta("og:description"),
      genre: cats.concat(actors),
      status: 1,
      link: full,
      episodes: [{ name: "Xem video", url: full }],
    };
  }
  async getVideoList(url) {
    const full = yhAbs(this.base(), url);
    const res = await this.client.get(full, this.getHeaders(full));
    const html = res.body || "";
    const headers = { "User-Agent": YH_UA, "Referer": this.base() + "/", "Origin": this.base() };
    const out = [];
    const seen = {};
    const add = (u, q) => {
      if (!u) return;
      u = u.replace(/\\\//g, "/");
      if (seen[u]) return;
      seen[u] = 1;
      out.push({ url: u, originalUrl: u, quality: q, headers });
    };
    let m = html.match(/new\s+Artplayer\(\{[\s\S]*?url:\s*['"]([^'"]+)['"]/);
    if (m) add(m[1], "Máy chủ 1 (HLS)");
    for (const x of html.matchAll(/itemprop="contentUrl"\s+content="([^"]+)"/g)) add(x[1], "Máy chủ 1 (HLS)");
    for (const x of html.matchAll(/"contentUrl":"([^"]+)"/g)) add(x[1], "Máy chủ 1 (HLS)");
    // site player as the last resort (handles the disguised TS segments)
    out.push({ url: "yhweb:" + full, originalUrl: full, quality: "Trình phát của trang (web)", headers });
    return out;
  }
  getFilterList() {
    return [
      yhHeader("Bộ lọc dùng khi ô tìm kiếm trống"),
      yhSelect("cat", "Danh mục", HH_CATS),
      yhText_("tag", "Diễn viên / thẻ (vd. yua-mikami)"),
    ];
  }
  getSourcePreferences() { return [yhDomainPref("https://hihisex.men")]; }
}
