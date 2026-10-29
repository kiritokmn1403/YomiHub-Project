// HiHiPhim (hihiphim.com) – phim bộ, phim lẻ, anime Vietsub. Bundled with YomiHub.
// 0.3.6: rewritten for the current site (Next.js + /baseapi JSON API).
// Video: the site's own player (api.hihiphim.com/embed/<id>, link encrypted
// with a fixed XOR key) plus the KKPhim catalogue as a second direct server.
const HH_LISTS = [
  ["Phim bộ", "phim-bo"], ["Phim lẻ", "phim-le"], ["Chiếu rạp", "the-loai/chieu-rap"], ["Hoạt hình", "the-loai/hoat-hinh"],
];
const HH_GENRES = [
  ["Tất cả", ""], ["Hành động", "the-loai/hanh-djong"], ["Cổ trang", "the-loai/co-trang"], ["Tình cảm", "the-loai/tinh-cam"],
  ["Tâm lý", "the-loai/tam-ly"], ["Hài hước", "the-loai/hai-huoc"], ["Kinh dị", "the-loai/kinh-di"], ["Viễn tưởng", "the-loai/vien-tuong"],
  ["Võ thuật", "the-loai/vo-thuat"], ["Hình sự", "the-loai/hinh-su"], ["Phiêu lưu", "the-loai/phieu-luu"], ["Bí ẩn", "the-loai/bi-an"],
  ["Gia đình", "the-loai/gia-djinh"], ["Học đường", "the-loai/hoc-djuong"], ["Chiến tranh", "the-loai/chien-tranh"], ["Thần thoại", "the-loai/than-thoai"],
  ["Tài liệu", "the-loai/tai-lieu"], ["Hoạt hình", "the-loai/hoat-hinh"], ["Chiếu rạp", "the-loai/chieu-rap"],
];
const HH_COUNTRIES = [
  ["Tất cả", ""], ["Hàn Quốc", "quoc-gia/han-quoc"], ["Trung Quốc", "quoc-gia/trung-quoc"], ["Nhật Bản", "quoc-gia/nhat-ban"],
  ["Âu Mỹ", "quoc-gia/au-my"], ["Thái Lan", "quoc-gia/thai-lan"], ["Hồng Kông", "quoc-gia/hong-kong"],
];
const HH_KEYS = ["mySecretKey2024", "mySecretKey2025", "mySecretKey2026", "mySecretKey"];

class DefaultExtension extends MProvider {
  constructor() { super(); this.client = new Client(); }
  get supportsLatest() { return true; }
  base() { return yhBase(this); }
  getHeaders(url) { return { "User-Agent": YH_UA, "Referer": this.base() + "/" }; }
  async api(path) {
    const r = await this.client.get(this.base() + "/baseapi/api/v1/" + path, { "User-Agent": YH_UA, "Referer": this.base() + "/", "Accept": "application/json" });
    const b = (r.body || "").trim();
    if (!b.startsWith("{") && !b.startsWith("[")) throw new Error("HiHiPhim: máy chủ không trả dữ liệu (HTTP " + r.statusCode + ")");
    return JSON.parse(b);
  }
  item(m) {
    return { name: m.name + (m.episode_current ? " (" + m.episode_current + ")" : ""), link: m.slug, imageUrl: m.thumbnail || m.poster || "" };
  }
  async page(path, page) {
    const r = await this.client.get(this.base() + "/" + path + (path.includes("?") ? "&" : "?") + "page=" + page, this.getHeaders());
    if (r.statusCode >= 400) throw new Error("HiHiPhim: HTTP " + r.statusCode);
    const f = yhFlight(r.body);
    const mv = yhJsonAt(f, "movies", (v) => v && Array.isArray(v.result));
    if (mv) {
      const meta = mv.meta || mv;
      return { list: mv.result.map((m) => this.item(m)), hasNextPage: (meta.totalPages || 1) > page };
    }
    // category pages: one {"item":{…movie…}} per card + {"totalPages":N}
    const list = [];
    const seen = {};
    const re = /"item":\{"id":/g;
    let m;
    while ((m = re.exec(f)) !== null) {
      const it = yhJsonAt(f.slice(m.index), "item", (v) => v && v.slug && v.name);
      if (it && !seen[it.slug]) { seen[it.slug] = 1; list.push(this.item(it)); }
    }
    const tp = parseInt((f.match(/"totalPages":(\d+)/) || [])[1] || "1");
    return { list, hasNextPage: tp > page };
  }
  async getPopular(page) { return this.page("phim-bo", page); }
  async getLatestUpdates(page) {
    const d = await this.api("lists/homepageLists?page=" + page);
    const res = d.result || {};
    const list = [];
    const seen = {};
    for (const c of res.collections || []) for (const m of c.movies || []) if (!seen[m.slug]) { seen[m.slug] = 1; list.push(this.item(m)); }
    return { list, hasNextPage: (parseInt(res.totalPages) || 1) > page };
  }
  async search(query, page, filters) {
    query = (query || "").trim();
    if (query) {
      const d = await this.api("movies/search?keyword=" + encodeURIComponent(query) + "&page=" + page + "&limit=30");
      const meta = d.meta || {};
      return { list: (d.result || []).map((m) => this.item(m)), hasNextPage: (meta.totalPages || 1) > page };
    }
    const path = yhF(filters, "genre") || yhF(filters, "country") || yhF(filters, "list") || "phim-bo";
    return this.page(path, page);
  }
  async movieOf(slug) {
    const r = await this.client.get(this.base() + "/phim/" + slug, this.getHeaders());
    const f = yhFlight(r.body);
    return yhJsonAt(f, "movie", (v) => v && v.id && v.slug === slug) || yhJsonAt(f, "movie", (v) => v && v.id) || null;
  }
  async getDetail(url) {
    const slug = ("" + url).replace(/^.*\/phim\//, "").replace(/[/?#].*$/, "");
    const m = await this.movieOf(slug);
    if (!m) throw new Error("HiHiPhim: không đọc được thông tin phim");
    let eps = [];
    try { eps = await this.api("episodes/by-idMovie/" + m.id); } catch (e) {}
    const seasons = {};
    for (const e of eps) seasons[e.season_number || 1] = 1;
    const multiSeason = Object.keys(seasons).length > 1;
    const episodes = eps.map((e) => ({
      name: (multiSeason ? "Phần " + (e.season_number || 1) + " – " : "") + (/^\d+$/.test("" + e.name) ? "Tập " + e.name : e.name) + (e.server ? " · " + e.server : ""),
      url: [m.id, e.id, e.name, slug].join("|"),
      scanlator: e.server || "",
    })).reverse();
    const names = (a) => (a || []).map((x) => x.name).filter(Boolean);
    return {
      name: m.name,
      imageUrl: m.thumbnail || m.poster || "",
      description: yhText((m.description || "").replace(/<[^>]+>/g, " ")) + (m.origin_name ? "\n\nTên gốc: " + m.origin_name : ""),
      genre: names(m.categories).concat(names(m.regions)),
      author: names(m.directors).join(", "),
      status: yhStatus(m.episode_current || ""),
      link: this.base() + "/phim/" + slug,
      episodes,
    };
  }
  decrypt(hex) {
    if (!hex || !/^[0-9a-f]+$/i.test(hex)) return "";
    const bytes = [];
    for (let i = 0; i + 1 < hex.length; i += 2) bytes.push(parseInt(hex.substr(i, 2), 16));
    for (const key of HH_KEYS) {
      let s = "";
      for (let i = 0; i < bytes.length; i++) s += String.fromCharCode(bytes[i] ^ key.charCodeAt(i % key.length));
      if (/^https?:\/\/[\x21-\x7e]+$/.test(s)) return s;
    }
    return "";
  }
  async getVideoList(url) {
    const [movieId, epId, epName, slug] = ("" + url).split("|");
    const videos = [];
    const ref = { "User-Agent": YH_UA, "Referer": "https://api.hihiphim.com/" };
    let embed = "https://api.hihiphim.com/embed/" + epId;
    try {
      const r = await this.client.get(embed, { "User-Agent": YH_UA, "Referer": this.base() + "/" });
      const body = r.body || "";
      const ep = body.match(/var\s+episode\s*=\s*(\{.*?\});\s*\n/);
      let e = null;
      if (ep) { try { e = JSON.parse(ep[1]); } catch (_) {} }
      const enc = e ? e.encrypted_url : (body.match(/"encrypted_url"\s*:\s*"([0-9a-f]+)"/i) || [])[1];
      const link = this.decrypt(enc);
      if (link) videos.push({ url: link, originalUrl: link, quality: "HiHiPhim · " + ((e && e.server) || "Phụ đề"), headers: ref });
      else if (e && e.link && /^https?:/.test(e.link)) videos.push({ url: e.link, originalUrl: e.link, quality: "HiHiPhim · " + (e.server || "Server"), headers: ref });
      const other = body.match(/var\s+otherServer\s*=\s*(\{.*?\});/);
      if (other) {
        try {
          const o = JSON.parse(other[1]);
          const l2 = this.decrypt(o.encrypted_url) || o.link || "";
          if (l2) videos.push({ url: l2, originalUrl: l2, quality: "HiHiPhim · " + (o.server || "Server 2"), headers: ref });
        } catch (_) {}
      }
    } catch (err) {}
    try { for (const v of await yhKKVideos(this.client, slug, epName, this.base() + "/")) videos.push(v); } catch (e) {}
    videos.push({ url: "yhweb:" + embed, originalUrl: embed, quality: "Trình phát HiHiPhim (web)", headers: { "User-Agent": YH_UA, "Referer": this.base() + "/" } });
    return videos;
  }
  getFilterList() {
    return [
      yhHeader("Bộ lọc dùng khi ô tìm kiếm trống (Quốc gia > Thể loại > Danh sách)"),
      yhSelect("list", "Danh sách", HH_LISTS),
      yhSelect("genre", "Thể loại", HH_GENRES),
      yhSelect("country", "Quốc gia", HH_COUNTRIES),
    ];
  }
  getSourcePreferences() { return [yhDomainPref("https://hihiphim.com")]; }
}
