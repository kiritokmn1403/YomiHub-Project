// SexVietTop (18+) – phim sex Việt Nam, clip ngắn. Bundled with YomiHub.
// 0.3.6: rewritten for the current site (top1sexvn.com now redirects to
// phimsexviet113.com): cards "li.item-movie", pages "/trang/N/", search
// "/search/<từ khoá>/", video from POST /api/player {id, server}.
const SVT_MIRRORS = ["https://phimsexviet113.com", "https://top1sexvn.com", "https://sexviettop.com"];
const SVT_CATS = [
  ["Mới nhất", ""], ["Sex Việt", "phim-sex-viet-nam"], ["Sex Nhật", "phim-sex-nhat-ban"], ["Sex Trung", "phim-sex-trung-quoc"],
  ["Sex Âu", "phim-sex-chau-au"], ["Vietsub", "phim-sex-vietsub"],
];

class DefaultExtension extends MProvider {
  constructor() { super(); this.client = new Client(); }
  get supportsLatest() { return true; }
  base() { return yhBase(this); }
  getHeaders(url) { return { "User-Agent": YH_UA, "Referer": this.base() + "/" }; }
  async get(path) {
    const first = this.base();
    let err = null;
    for (const h of [first].concat(SVT_MIRRORS.filter((m) => m !== first))) {
      try {
        const r = await this.client.get(h + path, this.getHeaders(h + path));
        if (r.statusCode < 400 && r.body) { this.host = ((r.request && r.request.url) || h + path).replace(/^(https?:\/\/[^/]+).*$/, "$1"); return r.body; }
        err = new Error("HTTP " + r.statusCode);
      } catch (e) { err = e; }
    }
    throw new Error("SexVietTop: không tải được trang (" + (err && err.message || err) + ") – bật DNS/VPN nếu nhà mạng chặn.");
  }
  pathOf(u) { return ("" + u).replace(/^https?:\/\/[^/]+/, ""); }
  parse(html) {
    const doc = new Document(html);
    const list = [];
    const seen = {};
    for (const it of doc.select("li.item-movie, .item-movie")) {
      const a = it.selectFirst("a[href]");
      if (!a) continue;
      const href = this.pathOf(a.getHref);
      if (!/\.html$/.test(href) || seen[href]) continue;
      seen[href] = 1;
      const img = it.selectFirst("img");
      list.push({ name: yhText(a.attr("title") || (img ? img.attr("alt") : "")), link: href, imageUrl: img ? (img.attr("data-original") || img.attr("data-src") || img.attr("src")) : "" });
    }
    return { list, hasNextPage: /\/trang\/\d+\//.test(html) && list.length >= 10 };
  }
  async listing(cat, page) {
    const p = (cat ? "/" + cat : "") + (page > 1 ? "/trang/" + page + "/" : "/");
    return this.parse(await this.get(p.replace(/\/\/+/g, "/")));
  }
  async getPopular(page) { return this.listing("phim-sex-viet-nam", page); }
  async getLatestUpdates(page) { return this.listing("", page); }
  async search(query, page, filters) {
    query = (query || "").trim();
    if (query) return this.parse(await this.get(`/search/${encodeURIComponent(query.replace(/\s+/g, "-"))}/${page > 1 ? "trang/" + page + "/" : ""}`));
    return this.listing(yhF(filters, "cat") || "", page);
  }
  async getDetail(url) {
    const path = this.pathOf(url);
    const html = await this.get(path);
    const doc = new Document(html);
    const meta = (p) => { const e = doc.selectFirst(`meta[property="${p}"], meta[name="${p}"]`); return e ? e.attr("content") : ""; };
    const h1 = doc.selectFirst("h1");
    const info = doc.selectFirst("article.infobv p, .infobv");
    const thumb = doc.selectFirst("img.thumb-bv");
    return {
      name: h1 ? yhText(h1.text) : meta("og:title"),
      imageUrl: (thumb && thumb.attr("src")) || meta("og:image"),
      description: yhText(info ? info.text : meta("description")),
      genre: doc.select("#extras a").map((a) => yhText(a.text)).filter(Boolean).slice(0, 10),
      status: 1,
      link: this.base() + path,
      episodes: [{ name: "Xem video", url: path }],
    };
  }
  async getVideoList(url) {
    const html = await this.get(this.pathOf(url));
    const id = (html.match(/data-video-id="(\d+)"/) || [])[1];
    if (!id) throw new Error("SexVietTop: không thấy mã video.");
    const servers = [...new Set((html.match(/data-server-id="(\d+)"/g) || []).map((x) => x.match(/\d+/)[0]))];
    if (!servers.length) servers.push("1");
    const host = this.host || this.base();
    const hdr = { "User-Agent": YH_UA, "Referer": host + "/" };
    const videos = [];
    for (const sv of servers) {
      try {
        const r = await this.client.post(host + "/api/player", Object.assign({ "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8", "X-Requested-With": "XMLHttpRequest", "Origin": host }, hdr), "id=" + id + "&server=" + sv);
        const d = JSON.parse(r.body || "{}").data || {};
        if (d.type === "jwplayer") {
          for (const s of [].concat(d.sources || [])) {
            const f = typeof s === "string" ? s : s.file;
            if (f) videos.push({ url: f, originalUrl: f, quality: "Server " + sv + (s.label ? " · " + s.label : ""), headers: hdr });
          }
        } else if (d.source) {
          const src = (("" + d.source).match(/src=["']([^"']+)/) || [])[1] || d.source;
          if (/\.m3u8|\.mp4/i.test(src)) videos.push({ url: src, originalUrl: src, quality: "Server " + sv, headers: hdr });
          else if (/^https?:/.test(src)) videos.push({ url: "yhweb:" + src, originalUrl: src, quality: "Server " + sv + " (web)", headers: hdr });
        }
      } catch (e) {}
    }
    if (!videos.length) throw new Error("SexVietTop: không lấy được link phát.");
    return videos;
  }
  getFilterList() { return [yhHeader("Bộ lọc dùng khi ô tìm kiếm trống"), yhSelect("cat", "Danh mục", SVT_CATS)]; }
  getSourcePreferences() { return [yhDomainPref("https://phimsexviet113.com", "địa chỉ trong danh sách: top1sexvn.com (chuyển hướng tới đây)")]; }
}
