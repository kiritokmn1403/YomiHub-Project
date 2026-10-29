// Phimmoi (phimmoii.mom) – phim bộ, phim lẻ, chiếu rạp Vietsub. Bundled with YomiHub.
// 0.3.6: rewritten for the current site (WordPress + OPhim). Mirrors from the
// "Website Extension" sheet: phimmoii.mom, messiahelartista.com, phimmois.sh.
const PM_LISTS = [["Phim bộ", "categories/phim-bo"], ["Phim lẻ", "categories/phim-le"], ["Phim chiếu rạp", "categories/phim-chieu-rap"], ["Mới cập nhật", "movie"]];
const PM_GENRES = [
  ["Tất cả", ""], ["Hành động", "genres/hanh-dong"], ["Cổ trang", "genres/co-trang"], ["Tình cảm", "genres/tinh-cam"], ["Hài hước", "genres/hai-huoc"],
  ["Kinh dị", "genres/kinh-di"], ["Viễn tưởng", "genres/vien-tuong"], ["Tâm lý", "genres/tam-ly"], ["Võ thuật", "genres/vo-thuat"],
  ["Hình sự", "genres/hinh-su"], ["Phiêu lưu", "genres/phieu-luu"], ["Hoạt hình", "genres/hoat-hinh"], ["Chính kịch", "genres/chinh-kich"],
];
const PM_MIRRORS = ["https://phimmoii.mom", "https://messiahelartista.com", "https://phimmois.sh"];

class DefaultExtension extends MProvider {
  constructor() { super(); this.client = new Client(); }
  get supportsLatest() { return true; }
  base() { return yhBase(this); }
  getHeaders(url) { return { "User-Agent": YH_UA, "Referer": this.base() + "/" }; }
  async get(url) {
    let lastErr = null;
    const tried = [url];
    try {
      const r = await this.client.get(url, this.getHeaders(url));
      if (r.statusCode < 400 && r.body) return r.body;
      lastErr = new Error("HTTP " + r.statusCode);
    } catch (e) { lastErr = e; }
    // the site moves often: try the other known addresses with the same path
    const path = url.replace(/^https?:\/\/[^/]+/, "");
    for (const m of PM_MIRRORS) {
      const alt = m + path;
      if (tried.includes(alt)) continue;
      tried.push(alt);
      try { const r = await this.client.get(alt, this.getHeaders(alt)); if (r.statusCode < 400 && r.body) return r.body; } catch (e) {}
    }
    throw new Error("Phimmoi: không tải được " + url + " (" + (lastErr && lastErr.message || lastErr) + ")");
  }
  slugOf(u) { return ("" + u).replace(/\/+$/, "").split("/").pop(); }
  parse(html) {
    const doc = new Document(html);
    const list = [];
    const seen = {};
    for (const it of doc.select(".flw-item")) {
      const a = it.selectFirst("a.film-poster-ahref, .film-name a, a");
      if (!a) continue;
      const link = a.getHref;
      if (!link || seen[link] || !/\/movie\//.test(link)) continue;
      seen[link] = 1;
      const img = it.selectFirst("img");
      const name = yhText(a.attr("title") || (it.selectFirst(".film-name, h4") || a).text || (img ? img.attr("alt") : ""));
      const badge = it.selectFirst(".tick-rate, .fn-badge");
      list.push({ name: name + (badge && yhText(badge.text) ? " (" + yhText(badge.text) + ")" : ""), link: this.slugOf(link), imageUrl: img ? (img.attr("data-src") || img.attr("src") || img.attr("data-fallback")) : "" });
    }
    const hasNextPage = /class="[^"]*next[^"]*"|\/page\/\d+\//.test(html) && list.length >= 10;
    return { list, hasNextPage };
  }
  async listing(path, page) {
    return this.parse(await this.get(`${this.base()}/${path}/${page > 1 ? "page/" + page + "/" : ""}`));
  }
  async getPopular(page) { return this.listing("categories/phim-bo", page); }
  async getLatestUpdates(page) { return this.listing("movie", page); }
  async search(query, page, filters) {
    query = (query || "").trim();
    if (query) return this.parse(await this.get(`${this.base()}/${page > 1 ? "page/" + page + "/" : ""}?s=${encodeURIComponent(query)}`));
    return this.listing(yhF(filters, "genre") || yhF(filters, "list") || "categories/phim-bo", page);
  }
  // all episodes of every server: { "sv-0": [[label, url]…], … }
  async episodesOf(slug, detailHtml) {
    const links = [...new Set((detailHtml.match(/https?:\/\/[^"'\s]+\/xem-phim\/[^"'\s]+?-sv-\d+\/?/g) || []))];
    const servers = {};
    for (const l of links) { const sv = (l.match(/-sv-(\d+)/) || [])[1]; if (sv !== undefined && !servers[sv]) servers[sv] = l; }
    // the detail page does not always link every server: probe sv-0 / sv-1 too
    const any = Object.values(servers)[0];
    if (any) for (const sv of ["0", "1"]) if (!servers[sv]) servers[sv] = any.replace(/-sv-\d+/, "-sv-" + sv);
    const out = {};
    for (const sv of Object.keys(servers).sort()) {
      try {
        const html = await this.get(servers[sv]);
        const doc = new Document(html);
        const eps = [];
        const seen = {};
        for (const a of doc.select('a[href*="/xem-phim/"]')) {
          const href = a.getHref;
          if (!new RegExp("-sv-" + sv + "/?$").test(href) || seen[href]) continue;
          const label = yhText(a.text);
          if (!label || /tiếp|trước|next|prev/i.test(label)) continue;
          seen[href] = 1;
          const fromUrl = (href.match(/\/tap-(?:tap-)?([^/]+?)-sv-\d+/) || [])[1];
          eps.push([fromUrl ? fromUrl.replace(/^0+(?=\d)/, "").replace(/-/g, " ") : label, href]);
        }
        out[sv] = { name: (html.match(/data-sv(?:name)?="([^"]+)"/) || [])[1] || (sv === "0" ? "Vietsub" : "Server " + (parseInt(sv) + 1)), eps };
      } catch (e) {}
    }
    return out;
  }
  async getDetail(url) {
    const slug = this.slugOf(url);
    const html = await this.get(`${this.base()}/movie/${slug}/`);
    const doc = new Document(html);
    const meta = (p) => { const e = doc.selectFirst(`meta[property="${p}"], meta[name="${p}"]`); return e ? e.attr("content") : ""; };
    const h1 = doc.selectFirst("h1.film-name, h1");
    const servers = await this.episodesOf(slug, html);
    // one entry per episode number; other servers are offered in the player
    const byNo = {};
    const order = [];
    for (const sv of Object.keys(servers)) {
      for (const [label, href] of servers[sv].eps) {
        const no = yhEpNo(label);
        const key = no >= 0 ? "n" + no : label;
        if (!byNo[key]) { byNo[key] = { label, urls: [] }; order.push(key); }
        byNo[key].urls.push(href);
      }
    }
    const episodes = order.map((k) => ({
      name: (/^\d+$/.test(byNo[k].label) ? "Tập " + byNo[k].label : byNo[k].label),
      url: slug + "|" + byNo[k].label + "|" + byNo[k].urls.join(","),
    }));
    episodes.sort((a, b) => yhEpNo(b.name) - yhEpNo(a.name));
    const genres = doc.select('a[href*="/genres/"]').map((a) => yhText(a.text).replace(/^Phim\s+/, "")).filter(Boolean);
    return {
      name: h1 ? yhText(h1.text) : meta("og:title"),
      imageUrl: meta("og:image"),
      description: yhText(meta("description")),
      genre: [...new Set(genres)].slice(0, 8),
      status: yhStatus((html.match(/Trạng thái[^<]*<[^>]*>([^<]+)/) || [])[1] || ""),
      link: `${this.base()}/movie/${slug}/`,
      episodes,
    };
  }
  async getVideoList(url) {
    const [slug, label, list] = ("" + url).split("|");
    const videos = [];
    const web = [];
    const hdr = { "User-Agent": YH_UA, "Referer": this.base() + "/" };
    for (const watch of (list || "").split(",").filter(Boolean)) {
      try {
        const html = await this.get(watch);
        const sv = (watch.match(/-sv-(\d+)/) || [])[1] || "0";
        const doc = new Document(html);
        for (const b of doc.select("[data-link]")) {
          const link = b.attr("data-link");
          const type = (b.attr("data-type") || "").toLowerCase();
          const name = (sv === "0" ? "Vietsub" : sv === "1" ? "Thuyết minh" : "Server " + (parseInt(sv) + 1)) + " · " + (yhText(b.text) || type.toUpperCase());
          const m3u8 = /\.m3u8|\.mp4/i.test(link) && type !== "embed" ? link : yhInnerM3u8(link);
          if (m3u8) { if (!videos.some((v) => v.url === m3u8)) videos.push({ url: m3u8, originalUrl: m3u8, quality: name, headers: hdr }); }
          else if (/^https?:/.test(link)) web.push({ url: "yhweb:" + link, originalUrl: link, quality: name + " (web)", headers: hdr });
        }
      } catch (e) {}
    }
    if (!videos.length) { try { for (const v of await yhKKVideos(this.client, slug, label, this.base() + "/")) videos.push(v); } catch (e) {} }
    const all = videos.concat(web);
    if (!all.length) throw new Error("Phimmoi: tập này chưa có link phát.");
    return all;
  }
  getFilterList() {
    return [
      yhHeader("Bộ lọc dùng khi ô tìm kiếm trống (Thể loại > Danh sách)"),
      yhSelect("list", "Danh sách", PM_LISTS),
      yhSelect("genre", "Thể loại", PM_GENRES),
    ];
  }
  getSourcePreferences() { return [yhDomainPref("https://phimmoii.mom", "dự phòng: messiahelartista.com, phimmois.sh")]; }
}
