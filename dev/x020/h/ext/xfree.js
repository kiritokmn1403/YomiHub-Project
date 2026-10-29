// xFree (18+) – "porn reels" dọc. YomiHub 0.2.0, có Short Video.
// Đọc dữ liệu trang dựng sẵn (window.__NUXT__): trang chủ, /tag/<thẻ>,
// /search?q=, /video?id=. Video ở cdn.xfree.com/xfree-prod/<a>/<b>/<c>/<media>/full.mp4.
const XF_LGBT = [["Nữ (straight)", "1"], ["Gay", "2"], ["Trans", "3"]];
class DefaultExtension extends MProvider {
  constructor() { super(); this.client = new Client(); }
  get supportsLatest() { return true; }
  base() { return yhBase(this); }
  cdn() { return yhPref("yh_cdn", "https://cdn.xfree.com/xfree-prod/").replace(/\/?$/, "/"); }
  getHeaders(url) { return { "User-Agent": YH_UA, "Referer": this.base() + "/", "Accept": "application/json, text/plain, */*" }; }
  media(m, file) { const n = (m && m.name) || ""; return n.length > 3 ? `${this.cdn()}${n[0]}/${n[1]}/${n[2]}/${n}/${file}` : ""; }
  thumb(m) { const n = (m && m.name) || ""; return n ? `https://thumbs.xfree.com/listing/small/${n}_${m.listingSuffix || 0}.webp` : ""; }
  item(p) {
    if (!p || !p.id || !p.media) return null;
    if (!/^video\//.test(p.media.mimeType || "video/")) return null;
    const u = p.user || {};
    return {
      name: yhText(p.title || ((u.displayName || u.username || "xFree") + " #" + p.id)),
      link: "/video?id=" + p.id,
      imageUrl: this.thumb(p.media),
    };
  }
  // The JSON API refuses non-browser clients, so everything is read from
  // the server-rendered pages (window.__NUXT__ state).
  async nuxt(url) {
    const res = await this.client.get(url, this.getHeaders(url));
    const html = res.body || "";
    const m = html.match(/<script>(window\.__NUXT__=[\s\S]*?)<\/script>/);
    if (!m) throw new Error("xFree: HTTP " + res.statusCode + " – không đọc được trang (bị chặn? bật DoH hoặc VPN)");
    try { const w = {}; new Function("window", m[1])(w); return w.__NUXT__ || {}; }
    catch (e) { throw new Error("xFree: lỗi đọc dữ liệu trang – " + e); }
  }
  collect(n) {
    const out = [], seen = {};
    const visit = (o, d) => {
      if (!o || typeof o !== "object" || d > 7) return;
      if (Array.isArray(o)) { for (const x of o) visit(x, d + 1); return; }
      if (o.id && o.media && o.media.name && /^video\//.test(o.media.mimeType || "")) {
        if (!seen[o.id]) { seen[o.id] = 1; out.push(o); }
        return;
      }
      for (const k in o) if (k !== "user" && k !== "playlists") visit(o[k], d + 1);
    };
    visit((n.state || {}).post, 0);
    visit((n.state || {}).search, 0);
    visit(n.data, 0);
    return out;
  }
  async listFrom(url) {
    const n = await this.nuxt(url);
    const list = this.collect(n).map((p) => this.item(p)).filter((x) => x);
    return { list, hasNextPage: list.length > 0 };
  }
  async feed(page, lgbt) {
    // page 1 = home feed; next pages = popular tags in turn (the home feed
    // itself is not paged without the API)
    const tags = ["amateur", "blonde", "brunette", "asian", "latina", "teen", "milf", "cosplay", "hentai", "bigtits", "ass", "solo", "couple", "lesbian", "redhead", "petite", "ebony", "pov", "outdoor", "dance"];
    const pfx = lgbt === "2" ? "-gay" : lgbt === "3" ? "-trans" : "";
    const url = page <= 1 ? this.base() + (pfx ? "/" + pfx.slice(1) : "/") : `${this.base()}/tag${pfx}/${tags[(page - 2) % tags.length]}`;
    const r = await this.listFrom(url);
    r.hasNextPage = page < tags.length + 1;
    return r;
  }
  async getPopular(page) { return await this.feed(page, "1"); }
  async getLatestUpdates(page) { return await this.feed(page, "1"); }
  async search(query, page, filters) {
    const lgbt = yhF(filters, "lgbt") || "1";
    if (!(query && query.trim())) return await this.feed(page, lgbt);
    if (page > 1) return { list: [], hasNextPage: false };
    const q = query.trim();
    const r = await this.listFrom(`${this.base()}/search${lgbt === "2" ? "-gay" : ""}?q=${encodeURIComponent(q)}`);
    if (!r.list.length) return await this.listFrom(`${this.base()}/tag/${encodeURIComponent(q.toLowerCase().replace(/\s+/g, ""))}`);
    r.hasNextPage = false;
    return r;
  }
  async post(url) {
    const id = (("" + url).match(/id=(\d+)/) || ("" + url).match(/(\d+)\/?$/) || [])[1];
    const n = await this.nuxt(`${this.base()}/video?id=${id}`);
    const pd = ((n.state || {}).post || {}).postDetail || {};
    const p = pd[id] || this.collect(n).find((x) => "" + x.id === "" + id);
    if (!p) throw new Error("xFree: không đọc được bài đăng " + id);
    return p;
  }
  async getDetail(url) {
    const p = await this.post(url);
    const it = this.item(p) || { name: "xFree " + p.id, imageUrl: "" };
    const u = p.user || {};
    return {
      name: it.name, imageUrl: it.imageUrl, author: u.displayName || u.username || "",
      description: [p.title || "", p.viewCount ? "👁 " + p.viewCount : "", p.likesCount ? "❤ " + p.likesCount : ""].filter((x) => x).join("\n"),
      genre: (p.tags || []).map((t) => t.tag).filter((x) => x).slice(0, 25),
      status: 1, link: this.base() + "/video?id=" + p.id,
      episodes: [{ name: "Xem video", url: "/video?id=" + p.id }],
    };
  }
  async getVideoList(url) {
    const p = await this.post(url);
    const headers = { "User-Agent": YH_UA, "Referer": this.base() + "/" };
    const out = [];
    const full = this.media(p.media, "full.mp4");
    if (full) out.push({ url: full, originalUrl: full, quality: (p.media.height ? p.media.height + "p " : "") + "MP4", headers });
    const lst = this.media(p.media, "listing7.mp4");
    if (lst) out.push({ url: lst, originalUrl: lst, quality: "MP4 nhẹ (dự phòng)", headers });
    return out;
  }
  getFilterList() {
    return [
      yhSelect("feed", "Nguồn video", [["Bảng tin (video dọc)", "shorts"]]),
      yhSelect("lgbt", "Nội dung", XF_LGBT),
    ];
  }
  getSourcePreferences() { return [yhDomainPref("https://www.xfree.com")]; }
}
