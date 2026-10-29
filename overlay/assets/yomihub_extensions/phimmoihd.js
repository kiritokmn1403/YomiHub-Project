// PhimMoiHD (phimmoihd.online) – phim HD Vietsub, thuyết minh. Bundled with YomiHub.
// 0.3.6: rewritten for the current Next.js site (episodes and HLS links are
// read from the page data; embed-only servers open in the web player).
const PMHD_LISTS = [["Phim bộ", "phim-bo"], ["Phim lẻ", "phim-le"], ["Phim chiếu rạp", "phim-chieu-rap"], ["Hoạt hình – Anime", "hoat-hinh-anime"], ["Thịnh hành", "phim-thinh-hanh"]];
const PMHD_GENRES = [
  ["Tất cả", ""], ["Hành động", "the-loai/hanh-dong"], ["Cổ trang", "the-loai/co-trang"], ["Tình cảm", "the-loai/tinh-cam"],
  ["Hài hước", "the-loai/hai-huoc"], ["Kinh dị", "the-loai/kinh-di"], ["Viễn tưởng", "the-loai/vien-tuong"], ["Tâm lý", "the-loai/tam-ly"],
  ["Võ thuật", "the-loai/vo-thuat"], ["Hình sự", "the-loai/hinh-su"], ["Phiêu lưu", "the-loai/phieu-luu"], ["Học đường", "the-loai/hoc-duong"],
];
const PMHD_COUNTRIES = [
  ["Tất cả", ""], ["Việt Nam", "quoc-gia/viet-nam"], ["Trung Quốc", "quoc-gia/trung-quoc"], ["Hàn Quốc", "quoc-gia/han-quoc"],
  ["Nhật Bản", "quoc-gia/nhat-ban"], ["Âu Mỹ", "quoc-gia/au-my"], ["Thái Lan", "quoc-gia/thai-lan"], ["Đài Loan", "quoc-gia/dai-loan"], ["Hồng Kông", "quoc-gia/hong-kong"],
];

class DefaultExtension extends MProvider {
  constructor() { super(); this.client = new Client(); }
  get supportsLatest() { return true; }
  base() { return yhBase(this); }
  getHeaders(url) { return { "User-Agent": YH_UA, "Referer": this.base() + "/" }; }
  async get(url) {
    const r = await this.client.get(url, this.getHeaders(url));
    if (r.statusCode >= 400) throw new Error("PhimMoiHD: HTTP " + r.statusCode + " – " + url);
    return r.body || "";
  }
  img(src) {
    if (!src) return "";
    const m = src.match(/[?&]url=([^&]+)/);
    if (m) { try { return decodeURIComponent(m[1]); } catch (e) {} }
    return yhAbs(this.base(), src);
  }
  parse(html, page) {
    const doc = new Document(html);
    const list = [];
    const seen = {};
    for (const a of doc.select('a[href^="/phim/"]')) {
      const href = a.getHref;
      const img = a.selectFirst("img");
      if (!img || seen[href]) continue;
      const name = yhText(img.attr("alt") || a.attr("title") || a.text);
      if (!name) continue;
      seen[href] = 1;
      const srcset = img.attr("srcset") || img.attr("srcSet") || "";
      list.push({ name, link: href.replace(/^\/phim\//, ""), imageUrl: this.img(img.attr("src") || srcset.split(" ")[0]) });
    }
    const tp = parseInt((html.match(/totalPages\\?"?:(\d+)/) || [])[1] || "0");
    return { list, hasNextPage: tp ? tp > page : list.length >= 20 };
  }
  async listing(path, page) { return this.parse(await this.get(`${this.base()}/${path}?page=${page}`), page); }
  async getPopular(page) { return this.listing("phim-thinh-hanh", page); }
  async getLatestUpdates(page) { return this.listing("phim-bo", page); }
  async search(query, page, filters) {
    query = (query || "").trim();
    if (query) return this.parse(await this.get(`${this.base()}/tim-kiem?q=${encodeURIComponent(query)}&page=${page}`), page);
    return this.listing(yhF(filters, "country") || yhF(filters, "genre") || yhF(filters, "list") || "phim-bo", page);
  }
  async data(slug) {
    const html = await this.get(`${this.base()}/phim/${slug}`);
    const f = yhFlight(html);
    return { html, f, eps: yhJsonAt(f, "episodes", (v) => Array.isArray(v) && (!v.length || v[0].servers)) || [] };
  }
  async getDetail(url) {
    const slug = ("" + url).replace(/^.*\/phim\//, "").replace(/[/?#].*$/, "");
    const { html, eps } = await this.data(slug);
    const doc = new Document(html);
    const meta = (p) => { const e = doc.selectFirst(`meta[property="${p}"], meta[name="${p}"]`); return e ? e.attr("content") : ""; };
    const h1 = doc.selectFirst("h1");
    const genres = doc.select('a[href^="/the-loai/"]').map((a) => yhText(a.text)).filter(Boolean);
    const episodes = eps.map((e, i) => ({
      name: (/^\d+$/.test("" + e.title) ? "Tập " + e.title : (e.title || "Tập " + (i + 1))),
      url: slug + "|" + i + "|" + (e.title || ""),
    })).reverse();
    return {
      name: h1 ? yhText(h1.text) : meta("og:title"),
      imageUrl: this.img(meta("og:image")),
      description: yhText(meta("description") || meta("og:description")),
      genre: [...new Set(genres)],
      status: episodes.length > 1 ? 0 : 1,
      link: `${this.base()}/phim/${slug}`,
      episodes,
    };
  }
  async getVideoList(url) {
    const [slug, idx, label] = ("" + url).split("|");
    const { eps } = await this.data(slug);
    const ep = eps[parseInt(idx)] || eps.find((e) => ("" + e.title) === label) || {};
    const videos = [];
    const web = [];
    const hdr = { "User-Agent": YH_UA, "Referer": this.base() + "/" };
    for (const s of ep.servers || []) {
      const m3u8 = s.linkM3u8 || yhInnerM3u8(s.linkEmbed);
      if (m3u8) videos.push({ url: m3u8, originalUrl: m3u8, quality: s.serverName || "Server", headers: hdr });
      else if (s.linkEmbed) web.push({ url: "yhweb:" + s.linkEmbed, originalUrl: s.linkEmbed, quality: (s.serverName || "Server") + " (web)", headers: hdr });
    }
    if (!videos.length) { try { for (const v of await yhKKVideos(this.client, slug, label, this.base() + "/")) videos.push(v); } catch (e) {} }
    const all = videos.concat(web);
    if (!all.length) throw new Error("PhimMoiHD: tập này chưa có link phát.");
    return all;
  }
  getFilterList() {
    return [
      yhHeader("Bộ lọc dùng khi ô tìm kiếm trống (Quốc gia > Thể loại > Danh sách)"),
      yhSelect("list", "Danh sách", PMHD_LISTS),
      yhSelect("genre", "Thể loại", PMHD_GENRES),
      yhSelect("country", "Quốc gia", PMHD_COUNTRIES),
    ];
  }
  getSourcePreferences() { return [yhDomainPref("https://phimmoihd.online")]; }
}
