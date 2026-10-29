// XemPhimGi (xemphimgi.com) – phim bộ, phim lẻ, chiếu rạp. Bundled with YomiHub.
// 0.3.6: rewritten for the current site (WordPress "movie-theme": poster
// cards .movie-item, episodes /<phim>/tap-N/, HLS list `var all_sources`).
const XG_LISTS = [["Phim bộ", "phim-bo"], ["Phim lẻ", "phim-le"], ["Phim chiếu rạp", "phim-chieu-rap"], ["Hoạt hình", "hoat-hinh"]];
const XG_GENRES = [
  ["Tất cả", ""], ["Hành động", "hanh-dong"], ["Hài hước", "hai-huoc"], ["Viễn tưởng", "vien-tuong"], ["Cổ trang", "co-trang"],
  ["Tình cảm", "tinh-cam"], ["Chính kịch", "chinh-kich"], ["Khoa học", "khoa-hoc"], ["Tâm lý", "tam-ly"], ["Kinh dị", "kinh-di"],
  ["Phiêu lưu", "phieu-luu"], ["Bí ẩn", "bi-an"],
];
const XG_COUNTRIES = [["Tất cả", ""], ["Trung Quốc", "trung-quoc"], ["Hàn Quốc", "han-quoc"], ["Âu Mỹ", "au-my"], ["Nhật Bản", "nhat-ban"], ["Thái Lan", "thai-lan"]];

class DefaultExtension extends MProvider {
  constructor() { super(); this.client = new Client(); }
  get supportsLatest() { return true; }
  base() { return yhBase(this); }
  getHeaders(url) { return { "User-Agent": YH_UA, "Referer": this.base() + "/" }; }
  async get(url) {
    const r = await this.client.get(url, this.getHeaders(url));
    if (r.statusCode >= 400) throw new Error("XemPhimGi: HTTP " + r.statusCode + " – " + url);
    return r.body || "";
  }
  slugOf(u) { return ("" + u).replace(/^https?:\/\/[^/]+\//, "").replace(/\/tap-[^/]+\/?$/, "").replace(/\/+$/, ""); }
  parse(html) {
    const doc = new Document(html);
    const list = [];
    const seen = {};
    // item-4 = the "most viewed" sidebar shown on every page
    const cards = doc.select("[class*=movie-item]").filter((e) => !/\bitem-4\b|\bitem-2\b/.test(e.attr("class") || ""));
    for (const it of cards) {
      const a = it.selectFirst("a.movie-link, .movie-title a, a");
      if (!a) continue;
      const link = a.getHref;
      if (!link || seen[link]) continue;
      seen[link] = 1;
      const img = it.selectFirst("img");
      const t = it.selectFirst(".movie-title");
      const name = yhText((t && t.text) || a.attr("title") || (img ? img.attr("alt") : ""));
      if (!name) continue;
      list.push({ name, link: this.slugOf(link), imageUrl: img ? (img.attr("data-lazy-src") || img.attr("data-src") || img.attr("src")) : "" });
    }
    return { list, hasNextPage: /\/page\/\d+\//.test(html) && /class="[^"]*next/.test(html) || (list.length >= 20 && /\/page\/\d+\//.test(html)) };
  }
  async listing(path, page) { return this.parse(await this.get(`${this.base()}/${path}/${page > 1 ? "page/" + page + "/" : ""}`)); }
  async getPopular(page) { return this.listing("phim-chieu-rap", page); }
  async getLatestUpdates(page) { return this.listing("phim-bo", page); }
  async search(query, page, filters) {
    query = (query || "").trim();
    if (query) return this.parse(await this.get(`${this.base()}/${page > 1 ? "page/" + page + "/" : ""}?s=${encodeURIComponent(query)}`));
    return this.listing(yhF(filters, "country") || yhF(filters, "genre") || yhF(filters, "list") || "phim-bo", page);
  }
  async getDetail(url) {
    const slug = this.slugOf(url);
    const html = await this.get(`${this.base()}/${slug}/`);
    const doc = new Document(html);
    const meta = (p) => { const e = doc.selectFirst(`meta[property="${p}"], meta[name="${p}"]`); return e ? e.attr("content") : ""; };
    const eps = [];
    const seen = {};
    for (const a of doc.select("a")) {
      const href = a.getHref || "";
      if (!href.includes("/" + slug + "/tap-") || seen[href]) continue;
      const label = yhText(a.text);
      if (!/tập|^\d|full/i.test(label)) continue;
      seen[href] = 1;
      eps.push({ name: label.replace(/\s*\/.*$/, ""), url: href });
    }
    eps.sort((x, y) => yhEpNo(y.name) - yhEpNo(x.name));
    const t = (meta("og:title") || "").replace(/\s*[|–]\s.*$/, "").replace(/^Phim\s+/i, "").replace(/\s+(Vietsub|Thuyết Minh|Lồng Tiếng)(\s.*)?$/i, "");
    const genres = [];
    const crumb = doc.select(".rank-math-breadcrumb a").map((a) => yhText(a.text)).filter((x) => x && x !== "Home");
    for (const g of crumb) genres.push(g);
    return {
      name: t || slug,
      imageUrl: meta("og:image"),
      description: yhText(meta("description") || meta("og:description")),
      genre: genres,
      status: eps.length > 1 ? 0 : 1,
      link: `${this.base()}/${slug}/`,
      episodes: eps.length ? eps : [{ name: "Full", url: `${this.base()}/${slug}/tap-1/` }],
    };
  }
  async getVideoList(url) {
    const html = await this.get(url);
    const videos = [];
    const hdr = { "User-Agent": YH_UA, "Referer": this.base() + "/" };
    const block = (html.match(/all_sources\s*=\s*\[([\s\S]*?)\]/) || [])[1] || "";
    const subsBlock = (html.match(/all_subtitles\s*=\s*\[([\s\S]*?)\]/) || [])[1] || "";
    const subs = (subsBlock.match(/"([^"]*)"/g) || []).map((x) => x.slice(1, -1));
    (block.match(/"([^"]+)"/g) || []).map((x) => yhJsonStr(x.slice(1, -1))).forEach((u, i) => {
      const sub = subs[i] ? [{ file: subs[i], label: "Tiếng Việt" }] : [];
      if (/\.m3u8|\.mp4/i.test(u)) videos.push({ url: u, originalUrl: u, quality: "Server " + (i + 1), headers: hdr, subtitles: sub });
      else if (/^https?:/.test(u)) videos.push({ url: "yhweb:" + u, originalUrl: u, quality: "Server " + (i + 1) + " (web)", headers: hdr });
    });
    if (!videos.length) {
      const ep = (url.match(/\/tap-([^/]+)/) || [])[1] || "1";
      try { for (const v of await yhKKVideos(this.client, this.slugOf(url), ep, this.base() + "/")) videos.push(v); } catch (e) {}
    }
    if (!videos.length) throw new Error("XemPhimGi: tập này chưa có link phát.");
    return videos;
  }
  getFilterList() {
    return [
      yhHeader("Bộ lọc dùng khi ô tìm kiếm trống (Quốc gia > Thể loại > Danh sách)"),
      yhSelect("list", "Danh sách", XG_LISTS),
      yhSelect("genre", "Thể loại", XG_GENRES),
      yhSelect("country", "Quốc gia", XG_COUNTRIES),
    ];
  }
  getSourcePreferences() { return [yhDomainPref("https://xemphimgi.com")]; }
}
