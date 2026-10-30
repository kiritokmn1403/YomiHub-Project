// Pornhub (18+). Bundled with YomiHub, đánh dấu NSFW.
// 0.2.0: "Shorties" (video dọc, https://www.pornhub.com/shorties) cho Video
// Short Scroll – bộ lọc "Nguồn video" = Shorties.
// Lưu ý: nhà mạng Việt Nam chặn tên miền này – bật DNS-over-HTTPS (Cài đặt > Chung)
// hoặc mục VPN (Tor/WARP) để truy cập.
const PH_ORDER = [["Mới nhất","cm"],["Xem nhiều","mv"],["Đánh giá cao","tr"],["Dài nhất","lg"],["Nổi bật","ht"]];
const PH_SORT_SEARCH = [["Liên quan nhất",""],["Mới nhất","mr"],["Xem nhiều","mv"],["Đánh giá cao","tr"],["Dài nhất","lg"]];
const PH_PERIOD = [["Mọi lúc",""],["Hôm nay","t"],["Tuần này","w"],["Tháng này","m"],["Năm nay","y"]];
const PH_DUR = [["Bất kỳ",""],["0–10 phút","0-10"],["10–20 phút","10-20"],["20–30 phút","20-30"],["Trên 30 phút","30-"]];
const PH_CATS = [["Tất cả",""],["Amateur","3"],["Anal","35"],["Asian","1"],["Babe","5"],["Big Ass","4"],["Big Tits","8"],["Blonde","9"],["Brunette","11"],["Compilation","57"],["Cosplay","241"],["Creampie","15"],["Ebony","17"],["Hardcore","21"],["Hentai","36"],["Japanese","111"],["Latina","26"],["Lesbian","27"],["MILF","29"],["POV","41"],["Public","24"],["Teen (18+)","37"],["Threesome","65"],["Vietnamese","105"],["Webcam","61"]];

class DefaultExtension extends MProvider {
  constructor() { super(); this.client = new Client(); }
  get supportsLatest() { return true; }
  base() { return yhBase(this); }
  getHeaders(url) {
    return { "User-Agent": YH_UA, "Referer": this.base() + "/", "Cookie": "accessAgeDisclaimerPH=1; accessAgeDisclaimerUK=1; platform=pc; age_verified=1" };
  }
  async doc(url) {
    const res = await this.client.get(url, this.getHeaders(url));
    return new Document(res.body);
  }
  parse(doc) {
    const list = [];
    const seen = {};
    for (const li of doc.select("li.pcVideoListItem, li.videoBox")) {
      const key = li.attr("data-video-vkey");
      const a = li.selectFirst("a.linkVideoThumb, a[href*='viewkey=']");
      if (!key || !a || seen[key]) continue;
      seen[key] = 1;
      const img = li.selectFirst("img");
      const dur = yhText((li.selectFirst(".duration") || {}).text);
      list.push({
        name: yhText(a.attr("title") || (img ? img.attr("alt") : "")) + (dur ? ` [${dur}]` : ""),
        link: "/view_video.php?viewkey=" + key,
        imageUrl: img ? (img.attr("data-image") || img.attr("data-mediumthumb") || img.attr("src")) : "",
      });
    }
    return { list, hasNextPage: doc.selectFirst("li.page_next a") != null };
  }
  async getPopular(page) { return this.parse(await this.doc(`${this.base()}/video?o=mv&t=w&page=${page}`)); }
  async getLatestUpdates(page) { return this.parse(await this.doc(`${this.base()}/video?o=cm&page=${page}`)); }
  // ---- Shorties feed (0.2.0) ----
  // Page 1 = /shorties (token + seed + first clips), later pages =
  // /shorties/get?token&offset&seed with the page's session cookies.
  shortItem(v) {
    const key = v.vkey || ((v.linkUrl || "").match(/viewkey=([a-z0-9]+)/i) || [])[1];
    if (!key) return null;
    return {
      name: yhText(v.videoTitle || v.metaTitle || v.name || key),
      link: "/view_video.php?viewkey=" + key,
      imageUrl: v.imageUrl || (v.thumbs && v.thumbs[0]) || "",
    };
  }
  async shorties(page) {
    const base = this.base();
    const ck = "accessAgeDisclaimerPH=1; accessAgeDisclaimerUK=1; age_verified=1";
    let st = {};
    try { st = JSON.parse(yhJarGet("yh_ph_short_state") || "{}"); } catch (e) {}
    // 0.4.5: the page token expires (it starts with a unix time). Short Video
    // opens the feed on a random page 1–3, so a token saved yesterday was
    // reused: /shorties/get answered 403 "Down for Maintenance" (HTML) and the
    // feed failed with "Pornhub Shorties: HTTP 403". A token older than 15
    // minutes, or one the API rejects, is now fetched again.
    const stale = !st.ts || (Date.now() - st.ts) > 15 * 60 * 1000;
    if (page <= 1 || !st.token || stale) {
      const res = await this.client.get(base + "/shorties", { "User-Agent": YH_UA, "Cookie": ck, "Referer": base + "/" });
      const html = res.body || "";
      const jar = yhJarMerge("yh_ph_short_jar", res, ck);
      st = {
        token: (html.match(/var token = "([^"]+)"/) || [])[1] || "",
        seed: (html.match(/ddSeed = (\d+)/) || [])[1] || "",
        next: +((html.match(/ddOffset = (\d+)/) || [])[1] || 10),
        ts: Date.now(),
      };
      new SharedPreferences().setString("yh_ph_short_state", JSON.stringify(st));
      const list = [];
      const seen = {};
      const parts = html.split(/"vkey":"/).slice(1);
      for (const part of parts) {
        const key = (part.match(/^([a-z0-9]+)"/) || [])[1];
        if (!key || seen[key]) continue;
        const seg = part.slice(0, 6000);
        const t = (seg.match(/"videoTitle":"((?:[^"\\]|\\.)*)"/) || [])[1];
        if (!t) continue;
        seen[key] = 1;
        const img = (seg.match(/"imageUrl":"((?:[^"\\]|\\.)*)"/) || [])[1] || "";
        list.push({ name: yhText(yhJsonStr(t)), link: "/view_video.php?viewkey=" + key, imageUrl: yhJsonStr(img) });
      }
      // first page: also pull one API page so the feed starts with enough clips
      if (st.token && page <= 1) {
        try { for (const it of (await this.shortiesApi(st, jar)).list) { const k = it.link.split('=').pop(); if (!seen[k]) { seen[k] = 1; list.push(it); } } } catch (e) {}
      }
      if (!list.length) throw new Error("Pornhub Shorties không trả về video (trang bị chặn? bật DoH hoặc VPN).");
      return { list, hasNextPage: !!st.token };
    }
    try {
      return await this.shortiesApi(st, yhJarGet("yh_ph_short_jar"));
    } catch (e) {
      // token rejected → start a new session once
      if (!/HTTP 40[13]|HTML/.test("" + e)) throw e;
      st.ts = 0;
      new SharedPreferences().setString("yh_ph_short_state", JSON.stringify(st));
      return await this.shorties(1);
    }
  }
  async shortiesApi(st, jar) {
    const base = this.base();
    const u = `${base}/shorties/get?token=${encodeURIComponent(st.token)}&offset=${st.next}&orientation=straight` + (st.seed ? `&seed=${st.seed}` : "");
    const res = await this.client.get(u, {
      "User-Agent": YH_UA, "Cookie": jar, "Referer": base + "/shorties",
      "X-Requested-With": "XMLHttpRequest", "Accept": "application/json",
    });
    let j = {};
    const body = (res.body || "").trim();
    if (res.statusCode >= 400 || body.startsWith("<")) throw new Error("Pornhub Shorties: HTTP " + res.statusCode + (body.startsWith("<") ? " (HTML)" : ""));
    try { j = JSON.parse(body); } catch (e) { throw new Error("Pornhub Shorties: HTTP " + res.statusCode); }
    const vids = j.videos || [];
    st.next = (+j.offset || st.next) + Math.max(vids.length, 5);
    new SharedPreferences().setString("yh_ph_short_state", JSON.stringify(st));
    yhJarMerge("yh_ph_short_jar", res, jar);
    return { list: vids.map((v) => this.shortItem(v)).filter((x) => x), hasNextPage: vids.length > 0 && !j.isEmpty };
  }
  async search(query, page, filters) {
    if ((yhF(filters, "feed") || "") === "shorts" && !(query && query.trim())) return await this.shorties(page);
    const p = [];
    const dur = yhF(filters, "dur") || "";
    if (dur) { const [mi, ma] = dur.split("-"); if (mi) p.push("min_duration=" + mi); if (ma) p.push("max_duration=" + ma); }
    if ((yhF(filters, "hd") || []).length) p.push("hd=1");
    const period = yhF(filters, "t") || "";
    if (query && query.trim()) {
      const o = yhF(filters, "sorts") || "";
      if (o) p.push("o=" + o);
      if (period && o) p.push("t=" + period);
      return this.parse(await this.doc(`${this.base()}/video/search?search=${encodeURIComponent(query.trim())}&page=${page}${p.length ? "&" + p.join("&") : ""}`));
    }
    const o = yhF(filters, "order") || "cm";
    p.push("o=" + o);
    if (period && o !== "cm") p.push("t=" + period);
    const c = yhF(filters, "cat") || "";
    if (c) p.push("c=" + c);
    return this.parse(await this.doc(`${this.base()}/video?${p.join("&")}&page=${page}`));
  }
  async getDetail(url) {
    const full = yhAbs(this.base(), url);
    const res = await this.client.get(full, this.getHeaders(full));
    const html = res.body;
    const doc = new Document(html);
    const meta = (p) => { const e = doc.selectFirst(`meta[property="${p}"]`) || doc.selectFirst(`meta[name="${p}"]`); return e ? e.attr("content") : ""; };
    const title = yhText(meta("og:title") || (doc.selectFirst("h1.title") || {}).text);
    const tags = doc.select(".categoriesWrapper a, .tagsWrapper a, .video-info-row a[href*='/categories/']").map((e) => yhText(e.text)).filter((t) => t && t !== "Suggest").slice(0, 20);
    const uploader = yhText((doc.selectFirst(".usernameBadgesWrapper a, .video-detailed-info .usernameWrap a") || {}).text);
    const views = yhText((doc.selectFirst(".count") || {}).text);
    return {
      name: title,
      imageUrl: meta("og:image"),
      author: uploader,
      description: `${title}\n${views ? "👁 " + views + " lượt xem" : ""}`,
      genre: tags,
      status: 1,
      link: full,
      episodes: [{ name: "Xem video", url: full }],
    };
  }
  async getVideoList(url) {
    const full = yhAbs(this.base(), url);
    const res = await this.client.get(full, this.getHeaders(full));
    const html = res.body;
    const m = html.match(/var\s+flashvars_\d+\s*=\s*(\{[\s\S]*?\});\s*\n/) || html.match(/flashvars_\d+\s*=\s*(\{[\s\S]*?\});/);
    if (!m) throw new Error("Không tìm thấy luồng video (có thể trang bị chặn – hãy bật DoH hoặc VPN).");
    const fv = JSON.parse(m[1]);
    const headers = { "User-Agent": YH_UA, "Referer": this.base() + "/" };
    const videos = [];
    for (const d of fv.mediaDefinitions || []) {
      if (d.format === "hls" && d.videoUrl) videos.push({ url: d.videoUrl, originalUrl: d.videoUrl, quality: (d.quality || d.height) + "p HLS", headers, _q: +d.height || 0 });
    }
    for (const d of fv.mediaDefinitions || []) {
      if (d.format === "mp4" && d.videoUrl && d.remote) {
        try {
          const r = await this.client.get(d.videoUrl, headers);
          for (const x of JSON.parse(r.body)) {
            if (x.videoUrl) videos.push({ url: x.videoUrl, originalUrl: x.videoUrl, quality: x.quality + "p MP4 (tải xuống)", headers, _q: +x.quality || 0 });
          }
        } catch (e) {}
      }
    }
    videos.sort((a, b) => b._q - a._q);
    return videos.map((v) => { delete v._q; return v; });
  }
  getFilterList() {
    return [
      yhSelect("feed", "Nguồn video", [["Video thường", ""], ["Shorties (video dọc – Short Video)", "shorts"]]),
      yhHeader("Khi tìm kiếm: dùng Sắp xếp kết quả. Khi duyệt: dùng Thứ tự và Danh mục"),
      yhSelect("sorts", "Sắp xếp kết quả", PH_SORT_SEARCH),
      yhSelect("order", "Thứ tự (duyệt)", PH_ORDER),
      yhSelect("cat", "Danh mục (duyệt)", PH_CATS),
      yhSelect("t", "Khoảng thời gian", PH_PERIOD),
      yhSelect("dur", "Thời lượng", PH_DUR),
      yhGroup("hd", "Chất lượng", [["Chỉ HD", "1"]]),
    ];
  }
  getSourcePreferences() { return [yhDomainPref("https://www.pornhub.com")]; }
}
