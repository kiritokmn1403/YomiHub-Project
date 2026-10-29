// Pornhub (18+). Bundled with YomiHub, đánh dấu NSFW.
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
  async search(query, page, filters) {
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
