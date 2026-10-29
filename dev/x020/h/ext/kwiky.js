// Kwiky (18+) – clip ngắn dọc của các cam model. YomiHub 0.2.0, có Short Video.
// API của trang qua cổng /api/v1/gateway (cần mã _xsrf của phiên + header
// x-gateway): getKwikiesFromOnlinePerformers (bảng tin), keywordSearch (tìm),
// quickies/metadata (ảnh, mp4).
const KW_GATEWAY = "76d59e04-97fa-4ced-aa99-b86ffaf756a2";
const KW_GENDER = [["Nữ", "f"], ["Nam", "m"], ["Cặp đôi", "c"], ["Trans", "t"]];
class DefaultExtension extends MProvider {
  constructor() { super(); this.client = new Client(); }
  get supportsLatest() { return true; }
  base() { return yhBase(this); }
  afno() { return ("" + yhPref("yh_afno", "2-162764.38182")).trim(); }
  getHeaders(url) { return { "User-Agent": YH_UA, "Referer": this.base() + "/" }; }
  async session(force) {
    let s = {};
    try { s = JSON.parse(yhJarGet("yh_kw_sess") || "{}"); } catch (e) {}
    if (!force && s.x && s.t && Date.now() - s.t < 30 * 60 * 1000) return s;
    const res = await this.client.get(this.base() + "/api/state/v1/preload" + (this.afno() ? "?AFNO=" + encodeURIComponent(this.afno()) : ""), this.getHeaders());
    const x = ((res.body || "").match(/meta\.content = '([^']+)'/) || [])[1] || "";
    if (!x) throw new Error("Kwiky: không lấy được phiên (HTTP " + res.statusCode + ") – trang bị chặn? bật DoH hoặc VPN");
    s = { x: x, c: yhJarMerge("yh_kw_jar", res, ""), t: Date.now() };
    try { new SharedPreferences().setString("yh_kw_sess", JSON.stringify(s)); } catch (e) {}
    return s;
  }
  async api(path, retry) {
    const s = await this.session(!!retry);
    const h = this.getHeaders();
    h["Accept"] = "application/json";
    h["x-xsrf-token"] = s.x;
    h["x-gateway"] = KW_GATEWAY;
    if (s.c) h["Cookie"] = s.c;
    const res = await this.client.get(this.base() + "/api/v1/gateway" + path, h);
    if ((res.statusCode === 401 || res.statusCode === 403) && !retry) return await this.api(path, true);
    try { return JSON.parse(res.body); } catch (e) { throw new Error("Kwiky: HTTP " + res.statusCode); }
  }
  async meta(ids) {
    if (!ids.length) return [];
    const j = await this.api("/v1/quickies/metadata?quickieIds=" + encodeURIComponent(ids.join(",")) + "&pagetype=feed&init=true");
    const out = [];
    for (const id of ids) {
      const q = j[id];
      if (!q || !q.media || !q.media.url) continue;
      out.push(q);
    }
    return out;
  }
  item(q) {
    const m = q.media, c = q.creator || {};
    return {
      name: yhText((c.name || "Kwiky") + (m.description ? " – " + m.description : "")),
      imageUrl: m.thumbUrl || "",
      link: "/videos?kwikyId=" + m.quickieId + (this.afno() ? "&AFNO=" + this.afno() : ""),
    };
  }
  async feed(page, gender) {
    const ids = await this.api(`/v1/quickies/getKwikiesFromOnlinePerformers?page=${page}&size=20&gender=${gender}`);
    const list = (await this.meta(Array.isArray(ids) ? ids : [])).map((q) => this.item(q));
    return { list, hasNextPage: Array.isArray(ids) && ids.length >= 20 };
  }
  async getPopular(page) { return await this.feed(page, "f"); }
  async getLatestUpdates(page) { return await this.feed(page, "f"); }
  async search(query, page, filters) {
    const g = yhF(filters, "gender") || "f";
    const tag = yhF(filters, "tag") || "";
    const q = (query && query.trim()) || tag;
    if (!q) return await this.feed(page, g);
    if (page > 1) return { list: [], hasNextPage: false };
    const j = await this.api(`/v1/quickies/keywordSearch?keyword=${encodeURIComponent(q)}&gender=${g}`);
    const ids = ((j && j.recommended) || []).map((x) => x.id).filter((x) => x).slice(0, 60);
    const list = [];
    for (let i = 0; i < ids.length; i += 20) for (const m of await this.meta(ids.slice(i, i + 20))) list.push(this.item(m));
    return { list, hasNextPage: false };
  }
  idOf(url) { return (("" + url).match(/kwikyId=([0-9a-f-]+)/i) || ("" + url).match(/([0-9a-f]{8}-[0-9a-f-]{27})/i) || [])[1]; }
  async getDetail(url) {
    const id = this.idOf(url);
    const q = (await this.meta([id]))[0];
    if (!q) throw new Error("Kwiky: clip không còn tồn tại");
    const it = this.item(q), c = q.creator || {};
    return {
      name: it.name, imageUrl: it.imageUrl, author: c.name || "",
      description: [q.media.description || "", c.name ? "Cam model: " + c.name : "", q.media.duration ? q.media.duration + " giây" : ""].filter((x) => x).join("\n"),
      genre: (q.media.tags || []).slice(0, 20), status: 1,
      link: this.base() + it.link,
      episodes: [{ name: "Xem clip", url: it.link }],
    };
  }
  async getVideoList(url) {
    const q = (await this.meta([this.idOf(url)]))[0];
    if (!q) return [];
    const headers = { "User-Agent": YH_UA, "Referer": this.base() + "/" };
    const out = [{ url: q.media.url, originalUrl: q.media.url, quality: (q.media.height ? Math.min(q.media.width || 0, q.media.height) + "p " : "") + "MP4", headers }];
    if (q.media.previewUrl) out.push({ url: q.media.previewUrl, originalUrl: q.media.previewUrl, quality: "MP4 nhẹ (xem trước)", headers });
    return out;
  }
  getFilterList() {
    return [
      yhSelect("feed", "Nguồn video", [["Clip dọc (Short Video)", "shorts"]]),
      yhSelect("gender", "Giới tính", KW_GENDER),
      yhSelect("tag", "Thẻ (khi không tìm kiếm)", [["Tất cả", ""], ["latina", "latina"], ["sexy", "sexy"], ["milf", "milf"], ["tease", "tease"], ["brunette", "brunette"], ["blonde", "blonde"], ["petite", "petite"], ["curvy", "curvy"], ["dance", "dance"], ["asian", "asian"], ["ebony", "ebony"], ["pov", "pov"]]),
    ];
  }
  getSourcePreferences() {
    return [
      yhDomainPref("https://kwiky.com"),
      { key: "yh_afno", editTextPreference: { title: "Mã giới thiệu (AFNO)", summary: "Gắn vào link chia sẻ", value: "2-162764.38182", dialogTitle: "AFNO", dialogMessage: "", text: "2-162764.38182" } },
    ];
  }
}
