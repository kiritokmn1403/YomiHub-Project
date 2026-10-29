// Xôi Lạc TV – trực tiếp bóng đá, thể thao, xem lại trận đấu. Bundled with YomiHub.
// 0.3.6: rewritten for the current site (xoilacxxi.cc now redirects to
// xoilacvbt.tv). Live matches come from the home page grid; each match has
// several channels ("list_stream") played through the site's player –
// YomiHub sniffs the real HLS stream from it, or opens it in the web player.
const XL_MIRRORS = ["https://xoilacvbt.tv", "https://xoilacxxi.cc", "https://xoilacvb.cc", "https://xoilac32.org"];

class DefaultExtension extends MProvider {
  constructor() { super(); this.client = new Client(); }
  get supportsLatest() { return true; }
  base() { return yhBase(this); }
  getHeaders(url) { return { "User-Agent": YH_UA, "Referer": this.base() + "/" }; }
  async get(path) {
    const first = this.base();
    let err = null;
    for (const h of [first].concat(XL_MIRRORS.filter((m) => m !== first))) {
      try {
        const r = await this.client.get(h + path, this.getHeaders(h + path));
        if (r.statusCode < 400 && r.body) return r.body;
        err = new Error("HTTP " + r.statusCode);
      } catch (e) { err = e; }
    }
    throw new Error("Xôi Lạc: không tải được trang (" + (err && err.message || err) + ") – thử bật DNS/VPN hoặc đổi tên miền.");
  }
  pathOf(u) { return ("" + u).replace(/^https?:\/\/[^/]+/, ""); }
  matches(html) {
    const doc = new Document(html);
    const list = [];
    const seen = {};
    for (const it of doc.select(".grid-matches__item[data-fid]")) {
      const a = it.selectFirst('a[href*="/truc-tiep/"]') || (/\/truc-tiep\//.test(it.attr("href") || "") ? it : null);
      const href = a ? (a.getHref || a.attr("href")) : "";
      if (!href || seen[href]) continue;
      seen[href] = 1;
      const teams = it.select(".team-name-group p, .h-team .team-name, .h-team span").map((e) => yhText(e.text)).filter(Boolean);
      const league = it.attr("data-league") || yhText((it.selectFirst(".gmd-match-league span") || { text: "" }).text);
      const time = yhText((it.selectFirst(".grid-match__date, .h-time") || { text: "" }).text);
      const live = /Đang đá|is-live/.test(it.outerHtml) ? "🔴 " : "";
      const name = live + (teams.length >= 2 ? teams[0] + " vs " + teams[1] : yhText(it.text).slice(0, 80)) + (time ? " · " + time : "") + (league ? " · " + league : "");
      const img = it.selectFirst("img.team-logo-0, .team-logo-group img, img");
      list.push({ name, link: this.pathOf(href), imageUrl: img ? (img.attr("data-src") || img.attr("src")) : "" });
    }
    return list;
  }
  replays(html) {
    const doc = new Document(html);
    const list = [];
    const seen = {};
    for (const it of doc.select(".post-item")) {
      const a = it.selectFirst(".title_name a, a");
      if (!a) continue;
      const href = a.getHref;
      if (!href || seen[href]) continue;
      seen[href] = 1;
      const img = it.selectFirst("img");
      list.push({ name: yhText((it.selectFirst(".title_name") || a).text), link: this.pathOf(href), imageUrl: img ? (img.attr("data-src") || img.attr("src")) : "" });
    }
    return list;
  }
  async getPopular(page) {
    if (page > 1) return { list: [], hasNextPage: false };
    return { list: this.matches(await this.get("/")), hasNextPage: false };
  }
  async getLatestUpdates(page) {
    const html = await this.get(`/xem-lai-bong-da/${page > 1 ? "page/" + page + "/" : ""}`);
    const list = this.replays(html);
    return { list, hasNextPage: new RegExp("/page/" + (page + 1) + "/").test(html) };
  }
  async search(query, page, filters) {
    const q = (query || "").trim().toLowerCase();
    if (page > 1) return { list: [], hasNextPage: false };
    const all = this.matches(await this.get("/"));
    try { for (const x of this.replays(await this.get("/xem-lai-bong-da/"))) all.push(x); } catch (e) {}
    const norm = (s) => s.toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "").replace(/đ/g, "d");
    return { list: q ? all.filter((m) => norm(m.name).includes(norm(q))) : all, hasNextPage: false };
  }
  async getDetail(url) {
    const html = await this.get(url);
    const doc = new Document(html);
    const meta = (p) => { const e = doc.selectFirst(`meta[property="${p}"], meta[name="${p}"]`); return e ? e.attr("content") : ""; };
    const h1 = doc.selectFirst("h1");
    const live = /\/truc-tiep\//.test(url);
    return {
      name: h1 ? yhText(h1.text) : meta("og:title"),
      imageUrl: meta("og:image"),
      description: yhText(meta("description") || meta("og:description")),
      status: live ? 0 : 1,
      link: this.base() + url,
      episodes: [{ name: live ? "Trực tiếp" : "Xem lại", url }],
    };
  }
  async getVideoList(url) {
    const html = await this.get(url);
    const embeds = [];
    const ls = html.match(/var\s+list_stream\s*=\s*(\[[\s\S]*?\]);/);
    if (ls) { try { for (const g of JSON.parse(ls[1])) for (const u of [].concat(g)) if (u) embeds.push(u); } catch (e) {} }
    const ifr = html.match(/<iframe[^>]+src=["'](https?:[^"']+)["']/g) || [];
    for (const f of ifr) { const u = (f.match(/src=["']([^"']+)/) || [])[1]; if (u && !embeds.includes(u) && !/facebook|google|ads/i.test(u)) embeds.push(u); }
    for (const m of html.match(/https?:\/\/[^"'\s<>]+\.m3u8[^"'\s<>]*/g) || []) if (!embeds.includes(m)) embeds.unshift(m);
    const videos = [];
    const hdr = { "User-Agent": YH_UA, "Referer": this.base() + "/" };
    let sniffed = 0;
    for (let i = 0; i < embeds.length; i++) {
      const e = embeds[i].replace(/\\\//g, "/");
      const label = "Kênh " + (i + 1);
      if (/\.m3u8/i.test(e)) { videos.push({ url: e, originalUrl: e, quality: label, headers: hdr }); continue; }
      if (sniffed < 2) {
        sniffed++;
        try {
          const out = await evaluateJavascriptViaWebview(e, hdr, ["__yh_sniff__", ""]);
          const s = JSON.parse(out || "{}");
          for (const it of (s.all || []).slice(0, 2)) videos.push({ url: it.url, originalUrl: it.url, quality: label + " HLS", headers: Object.assign({ "User-Agent": YH_UA }, it.headers || {}) });
        } catch (_) {}
      }
      videos.push({ url: "yhweb:" + e, originalUrl: e, quality: label + " (web)", headers: hdr });
    }
    if (!videos.length) throw new Error("Xôi Lạc: trận này chưa có link phát (chưa tới giờ hoặc đã kết thúc).");
    return videos;
  }
  getFilterList() { return [yhHeader("Phổ biến = trận đang/sắp đá; Mới nhất = xem lại trận đấu")]; }
  getSourcePreferences() { return [yhDomainPref("https://xoilacvbt.tv", "địa chỉ trong danh sách: xoilacxxi.cc (chuyển hướng tới đây), xoilacvb.cc, xoilac32.org")]; }
}
