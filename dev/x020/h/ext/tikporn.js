// Tik.Porn (18+) – video dọc kiểu TikTok. YomiHub 0.2.0, có Short Video.
// Nguồn: API công khai của trang (apiv2.tik.porn/getnextvideos) + trang
// /video/<id> (dữ liệu Next.js) cho chi tiết và luồng phát.
class DefaultExtension extends MProvider {
  constructor() { super(); this.client = new Client(); }
  get supportsLatest() { return true; }
  base() { return yhBase(this); }
  api() { return yhPref("yh_api", "https://apiv2.tik.porn").replace(/\/+$/, ""); }
  getHeaders(url) { return { "User-Agent": YH_UA, "Referer": this.base() + "/", "Origin": this.base() }; }
  // two shapes: page data (id, texts, thumbnails) and the feed API
  // (video_id, video_text, medium_thumb)
  item(v) {
    const id = v && (v.id || v.video_id);
    if (!id) return null;
    const vt = v.video_text || {};
    const t = (v.texts && v.texts.video && (v.texts.video.parsed_text || v.texts.video.text)) ||
      (vt.description && vt.description.default && vt.description.default.text) ||
      (vt.meta_title && vt.meta_title.default && vt.meta_title.default.text) ||
      (v.metadata && v.metadata.title) ||
      [v.user_name, v.action_name].filter((x) => x).join(" – ") || ("Video " + id);
    const th = v.thumbnails || {};
    return {
      name: yhText(("" + t).replace(/\s*\|\s*Tik\.Porn\s*$/i, "")),
      link: "/video/" + id,
      imageUrl: th.md || th.sm || v.medium_thumb || v.small_thumb || (v.metadata && v.metadata.thumbnail) || v.poster_url || "",
    };
  }
  async feed(page, rand) {
    let seen = [];
    try { seen = JSON.parse(yhJarGet("yh_tp_seen") || "[]"); } catch (e) {}
    if (page <= 1) seen = [];
    const body = { amount: 20, filter: seen.slice(-300), sfw_mode: false, forcerand: !!rand, first_chunk: page <= 1, recomm_id: null };
    const h = this.getHeaders(); h["Content-Type"] = "application/json"; h["Accept"] = "application/json";
    const res = await this.client.post(this.api() + "/getnextvideos", h, body);
    let j = {};
    try { j = JSON.parse(res.body); } catch (e) { throw new Error("Tik.Porn: HTTP " + res.statusCode + " (trang bị chặn? bật DoH hoặc VPN)"); }
    const list = (j.data || []).map((v) => this.item(v)).filter((x) => x);
    for (const it of list) seen.push(+it.link.split("/").pop());
    try { new SharedPreferences().setString("yh_tp_seen", JSON.stringify(seen.slice(-300))); } catch (e) {}
    return { list, hasNextPage: list.length > 0 };
  }
  nextData(html) {
    const m = (html || "").match(/<script id="__NEXT_DATA__" type="application\/json">([\s\S]*?)<\/script>/);
    if (!m) return {};
    try { return JSON.parse(m[1]).props.pageProps || {}; } catch (e) { return {}; }
  }
  async getPopular(page) { return await this.feed(page, false); }
  async getLatestUpdates(page) { return await this.feed(page, true); }
  async search(query, page, filters) {
    const tag = yhF(filters, "tag") || "";
    if (!(query && query.trim()) && !tag) return await this.feed(page, (yhF(filters, "order") || "") === "rand");
    const q = (query && query.trim()) || tag;
    const url = `${this.base()}/?s=${encodeURIComponent(q)}` + (page > 1 ? `&page=${page}` : "");
    const res = await this.client.get(url, this.getHeaders(url));
    const pp = this.nextData(res.body);
    const box = pp.videos || pp.searchVideos || pp.initialVideos || {};
    let arr = box.data || [];
    if (!arr.length) for (const k in pp) if (pp[k] && Array.isArray(pp[k].data) && pp[k].data.length && pp[k].data[0].sources) { arr = pp[k].data; break; }
    const list = arr.map((v) => this.item(v)).filter((x) => x);
    const pg = box.pagination || {};
    return { list, hasNextPage: !!pg.hasMore || (list.length >= 10 && pg.hasMore !== false) };
  }
  async video(url) {
    const full = yhAbs(this.base(), url);
    const res = await this.client.get(full, this.getHeaders(full));
    const pp = this.nextData(res.body);
    const vs = pp.videos;
    const v = pp.firstVideo || (vs && Array.isArray(vs.data) ? vs.data[0] : (Array.isArray(vs) ? vs[0] : null));
    if (!v) throw new Error("Tik.Porn: không đọc được video (HTTP " + res.statusCode + ")");
    return { v, full };
  }
  async getDetail(url) {
    const { v, full } = await this.video(url);
    const it = this.item(v);
    const tags = (v.tags || []).map((t) => yhText(t.name || t.title || "")).filter((x) => x);
    if (v.action && v.action.name) tags.unshift(v.action.name);
    const stars = (v.pornstars || []).map((p) => p.name).filter((x) => x).join(", ");
    return {
      name: it.name, imageUrl: it.imageUrl, author: stars || ((v.user || {}).username || ""),
      description: [(v.metadata || {}).description || "", v.views ? "👁 " + v.views : ""].filter((x) => x).join("\n"),
      genre: tags, status: 1, link: full,
      episodes: [{ name: "Xem video", url: full }],
    };
  }
  async getVideoList(url) {
    const { v } = await this.video(url);
    const headers = { "User-Agent": YH_UA, "Referer": this.base() + "/" };
    const out = [];
    for (const s of v.sources || []) {
      if (!s.src) continue;
      if (/mpegurl/i.test(s.type || "") || /\.m3u8/.test(s.src)) out.unshift({ url: s.src, originalUrl: s.src, quality: "HLS (tự chọn)", headers });
      else if (/mp4/i.test(s.type || "") || /\.mp4/.test(s.src)) out.push({ url: s.src, originalUrl: s.src, quality: "MP4 " + ((s.src.match(/_(\d{3,4})\.mp4/) || [])[1] || "") + "p (tải xuống)", headers });
    }
    if (!out.length && v.source && v.source.src) out.push({ url: v.source.src, originalUrl: v.source.src, quality: "MP4", headers });
    return out;
  }
  getFilterList() {
    return [
      yhSelect("feed", "Nguồn video", [["Bảng tin (video dọc)", "shorts"]]),
      yhSelect("order", "Thứ tự bảng tin", [["Đề xuất", ""], ["Ngẫu nhiên", "rand"]]),
      yhSelect("tag", "Thẻ (khi không tìm kiếm)", [["Tất cả", ""], ["Amateur", "amateur"], ["Asian", "asian"], ["Big Ass", "big-ass"], ["Big Boobs", "big-boobs"], ["Blowjob", "blowjob"], ["Cosplay", "cosplay"], ["Hentai", "hentai"], ["Latina", "latina"], ["Lesbian", "lesbian"], ["MILF", "milf"], ["Redhead", "redhead"], ["Solo", "solo"], ["Teen (18+)", "teen"]]),
    ];
  }
  getSourcePreferences() { return [yhDomainPref("https://tik.porn")]; }
}
