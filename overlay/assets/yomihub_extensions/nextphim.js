// NextPhim (nextphim.net) – phim chiếu rạp: thông tin, review, trailer. Bundled with YomiHub.
// 0.3.6: rewritten for nextphim.net (the address in the "Website Extension"
// sheet). The site is a film magazine: every film has its page with poster,
// synopsis and the official YouTube trailer; when the same film is in the
// KKPhim catalogue it is offered as a full-length server too.
const NP_LISTS = [["Tất cả phim", "phim"], ["Phim điểm cao", "phim/?sort=diem"], ["Đánh giá phim", "danh-gia-phim"], ["Tin tức", "tin-tuc"]];

class DefaultExtension extends MProvider {
  constructor() { super(); this.client = new Client(); }
  get supportsLatest() { return true; }
  base() { return yhBase(this); }
  getHeaders(url) { return { "User-Agent": YH_UA, "Referer": this.base() + "/" }; }
  async get(url) {
    const r = await this.client.get(url, this.getHeaders(url));
    if (r.statusCode >= 400) throw new Error("NextPhim: HTTP " + r.statusCode + " – " + url);
    return r.body || "";
  }
  pathOf(u) { return ("" + u).replace(/^https?:\/\/[^/]+/, ""); }
  parse(html) {
    const doc = new Document(html);
    const list = [];
    const seen = {};
    for (const a of doc.select("a.mf-card, article a[href], .post-item a[href]")) {
      const href = a.getHref || "";
      if (!/nextphim\.net\/|^\//.test(href) || /\/(page|tag|category|author)\//.test(href) || seen[href]) continue;
      const img = a.selectFirst("img");
      const t = a.selectFirst(".mf-card__title, .entry-title, h2, h3");
      const name = yhText((t && t.text) || a.attr("title") || (img ? img.attr("alt") : ""));
      if (!name || !img) continue;
      seen[href] = 1;
      list.push({ name, link: this.pathOf(href), imageUrl: img.attr("data-lazy-src") || img.attr("data-src") || ((img.attr("src") || "").startsWith("data:") ? "" : img.attr("src")) });
    }
    return { list, hasNextPage: /\/page\/\d+\//.test(html) && list.length >= 10 };
  }
  async listing(path, page) {
    const [p, q] = path.split("?");
    return this.parse(await this.get(`${this.base()}/${p.replace(/\/+$/, "")}/${page > 1 ? "page/" + page + "/" : ""}${q ? "?" + q : ""}`));
  }
  async getPopular(page) { return this.listing("phim/?sort=diem", page); }
  async getLatestUpdates(page) { return this.listing("phim", page); }
  async search(query, page, filters) {
    query = (query || "").trim();
    if (query) return this.parse(await this.get(`${this.base()}/${page > 1 ? "page/" + page + "/" : ""}?s=${encodeURIComponent(query)}`));
    return this.listing(yhF(filters, "list") || "phim", page);
  }
  async getDetail(url) {
    const path = this.pathOf(url);
    const html = await this.get(this.base() + path);
    const doc = new Document(html);
    const meta = (p) => { const e = doc.selectFirst(`meta[property="${p}"], meta[name="${p}"]`); return e ? e.attr("content") : ""; };
    const h1 = doc.selectFirst("h1");
    const trailer = (html.match(/data-video="([A-Za-z0-9_-]{11})"/) || html.match(/(?:youtube(?:-nocookie)?\.com\/embed\/|youtu\.be\/|watch\?v=)([A-Za-z0-9_-]{11})/) || [])[1] || "";
    const slug = path.replace(/\/+$/, "").split("/").pop().replace(/^review-phim-/, "");
    const content = doc.selectFirst(".entry-content, .mv-synopsis, .mv-content");
    const genres = doc.select('a[href*="/the-loai/"], a[href*="/genre/"], .mv-genres a').map((a) => yhText(a.text)).filter(Boolean);
    return {
      name: h1 ? yhText(h1.text) : meta("og:title"),
      imageUrl: meta("og:image"),
      description: yhText(meta("og:description") || (content ? content.text.slice(0, 1500) : "")),
      genre: [...new Set(genres)],
      status: 1,
      link: this.base() + path,
      episodes: [{ name: trailer ? "Trailer & phim" : "Xem", url: slug + "|" + trailer }],
    };
  }
  async getVideoList(url) {
    const [slug, yt] = ("" + url).split("|");
    const videos = [];
    try { for (const v of await yhKKVideos(this.client, slug, "Full", this.base() + "/")) videos.push(v); } catch (e) {}
    if (yt) {
      const e = "https://www.youtube.com/embed/" + yt + "?autoplay=1";
      videos.push({ url: "yhweb:" + e, originalUrl: "https://www.youtube.com/watch?v=" + yt, quality: "Trailer (YouTube)", headers: { "User-Agent": YH_UA } });
    }
    if (!videos.length) throw new Error("NextPhim: phim này chưa có trailer hoặc nguồn phát.");
    return videos;
  }
  getFilterList() { return [yhHeader("Bộ lọc dùng khi ô tìm kiếm trống"), yhSelect("list", "Danh sách", NP_LISTS)]; }
  getSourcePreferences() { return [yhDomainPref("https://nextphim.net")]; }
}
