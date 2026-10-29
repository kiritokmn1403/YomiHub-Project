// AnimeVN (animevn.net) – anime / hoạt hình 3D Vietsub. Bundled with YomiHub.
const AVN_GENRES = [["Tất cả",""],["Anime","anime"],["CN Animation (Hoạt hình TQ)","cn-animation"],["Hành động","hanh-dong"],["Huyền ảo","huyen-ao"],["Tiên hiệp","tien-hiep"],["Kiếm hiệp","kiem-hiep"],["Võ hiệp","vo-hiep"],["Võ thuật","vo-thuat"],["Xuyên không","xuyen-khong"],["Trùng sinh","trung-sinh"],["Dị giới","di-gioi"],["Hài hước","hai-huoc"],["[CNA] Hài hước","cna-hai-huoc"],["[CNA] Ngôn tình","cna-ngon-tinh"],["Tình cảm","tinh-cam"],["Học đường","hoc-duong"],["Đời thường","doi-thuong"],["Phiêu lưu","phieu-luu"],["Giả tưởng","gia-tuong"],["Khoa huyễn","khoa-huyen"],["Viễn tưởng","vien-tuong"],["Siêu nhiên","sieu-nhien"],["Siêu năng lực","sieu-nang-luc"],["Bí ẩn","bi-an"],["Thám tử","tham-tu"],["Kinh dị","kinh-di"],["Thriller","thriller"],["Psychological","psychological"],["Drama","drama"],["Bi kịch","bi-kich"],["Lịch sử","lich-su"],["Quân đội","quan-doi"],["Samurai","samurai"],["Mecha","mecha"],["Thể thao","the-thao"],["Trò chơi","tro-choi"],["Âm nhạc","am-nhac"],["Demon","demon"],["Ma cà rồng","ma-ca-rong"],["Harem","harem"],["Ecchi","ecchi"],["Shounen","shounen"],["Shoujo","shoujo"],["Seinen","seinen"],["Shounen AI","shounen-ai"],["Shoujo AI","shoujo-ai"],["Đam mỹ","dam-my"],["Tokusatsu","tokusatsu"],["Live Action","live-action"],["Manga","manga"],["Manhwa","manhwa"]];
const AVN_LISTS = [["Mới cập nhật",""],["Top Anime","top-anime"],["Đang chiếu","phim-dang-chieu"],["Hoàn thành","phim-hoan-thanh"],["Sắp chiếu","phim-sap-chieu"]];

class DefaultExtension extends MProvider {
  constructor() { super(); this.client = new Client(); }
  get supportsLatest() { return true; }
  base() { return yhBase(this); }
  getHeaders(url) { return { "User-Agent": YH_UA, "Referer": this.base() + "/" }; }
  async doc(url) {
    const res = await this.client.get(url, this.getHeaders(url));
    return new Document(res.body);
  }
  listUrl(path, page) {
    const u = this.base() + "/" + (path || "").replace(/^\/+/, "");
    return page > 1 ? `${u}${u.indexOf("?") >= 0 ? "&" : "?"}page=${page}` : u;
  }
  parse(doc) {
    const list = [];
    const seen = {};
    for (const li of doc.select(".list_wrap li")) {
      const a = li.selectFirst(".main_text .title a") || li.selectFirst(".anime-cover a");
      if (!a) continue;
      const link = (a.attr("href") || "").replace(/^https?:\/\/[^/]+/, "");
      if (!/^\/anime\/[^/]+\/?$/.test(link) || seen[link]) continue;
      seen[link] = 1;
      const img = li.selectFirst("img");
      list.push({
        name: yhText(a.attr("title") || a.text || (img ? img.attr("alt") : "")),
        link,
        imageUrl: img ? (img.attr("data-original") || img.attr("src") || "") : "",
      });
    }
    const hasNextPage = doc.select('.pagination a[aria-label="Next"]').length > 0;
    return { list, hasNextPage };
  }
  async getPopular(page) { return this.parse(await this.doc(this.listUrl("top-anime", page))); }
  async getLatestUpdates(page) { return this.parse(await this.doc(this.listUrl("", page))); }
  async search(query, page, filters) {
    query = (query || "").trim();
    if (query) {
      if (page > 1) return { list: [], hasNextPage: false };
      const res = await this.client.post(`${this.base()}/search/html/1`,
        { "User-Agent": YH_UA, "Referer": this.base() + "/", "X-Requested-With": "XMLHttpRequest",
          "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8" },
        "keyword=" + encodeURIComponent(query.toLowerCase()));
      const doc = new Document(res.body || "");
      const list = [];
      for (const a of doc.select("a.item")) {
        const img = a.selectFirst("img");
        const name = img ? img.attr("alt") : yhText(a.text);
        list.push({ name: yhText(name), link: (a.attr("href") || "").replace(/^https?:\/\/[^/]+/, ""), imageUrl: img ? img.attr("src") : "" });
      }
      return { list, hasNextPage: false };
    }
    const genre = yhF(filters, "genre") || "";
    const listPath = yhF(filters, "list") || "";
    if (genre) return this.parse(await this.doc(this.listUrl(`the-loai/${genre}`, page)));
    return this.parse(await this.doc(this.listUrl(listPath, page)));
  }
  async getDetail(url) {
    const full = yhAbs(this.base(), url);
    const doc = await this.doc(full);
    const name = yhText((doc.selectFirst(".main-head h1") || doc.selectFirst("h1") || {}).text);
    const cover = doc.selectFirst(".comic-thumb-detail img") || doc.selectFirst(".anime-cover img");
    let imageUrl = cover ? (cover.attr("data-original") || cover.attr("src") || "") : "";
    const og = doc.selectFirst('meta[property="og:image"]');
    if (!imageUrl && og) imageUrl = og.attr("content");
    const genre = doc.select(".anime-info a.item-tag:not(.itm-eps)").map((e) => yhText(e.text));
    let statusText = "", year = "", length = "";
    for (const l of doc.select(".anime-info .line")) {
      const k = yhText((l.selectFirst(".line-text") || {}).text);
      const v = yhText((l.selectFirst(".line-content") || {}).text);
      if (/Trạng thái/i.test(k)) statusText = v;
      else if (/Phát hành/i.test(k)) year = v;
      else if (/Thời lượng/i.test(k)) length = v;
    }
    const alt = yhText((doc.selectFirst(".alternative") || {}).text).replace(/^Tên khác:\s*/i, "");
    const descEl = doc.selectFirst(".desc");
    let description = descEl ? yhText(descEl.text) : "";
    const extra = [alt ? "Tên khác: " + alt : "", year ? "Phát hành: " + year : "", length ? "Thời lượng: " + length : ""].filter(Boolean).join("\n");
    if (extra) description = extra + "\n\n" + description;
    const chapters = [];
    const seen = {};
    for (const a of doc.select("#chapter-list li a, ul.chapter-list li a")) {
      const href = (a.attr("href") || "").replace(/^https?:\/\/[^/]+/, "");
      if (!href || seen[href]) continue;
      seen[href] = 1;
      const n = yhText(a.text);
      chapters.push({ name: /^\d/.test(n) ? `Tập ${n}` : n, url: href });
    }
    // The site lists the newest episode first, which is what the app expects.
    return { name, imageUrl, genre, description, status: yhStatus(statusText), link: full, episodes: chapters };
  }
  async getVideoList(url) {
    const full = yhAbs(this.base(), url);
    const res = await this.client.get(full, this.getHeaders(full));
    const html = res.body || "";
    const servers = {};
    const re = /case\s*'(\w+)'\s*:\s*_video_player\.innerHTML\s*=\s*'<iframe[^>]*?src="([^"]*)"/g;
    let m;
    while ((m = re.exec(html)) !== null) servers[m[1]] = m[2];
    const listed = [];
    const re2 = /id="sv_(\w+)"/g;
    while ((m = re2.exec(html)) !== null) listed.push(m[1]);
    const videos = [];
    // 1) Site's own HLS player (AHS) – only usable when it carries a stream key.
    const ahs = servers["AHS"] || "";
    if (/[?&]s=[^&"]+/.test(ahs) || /\/player\/v\/u=[^&]+&s=[A-Za-z0-9]/.test(ahs)) {
      try {
        const p = await this.client.get(ahs, { "User-Agent": YH_UA, "Referer": full });
        const sm = (p.body || "").match(/<source[^>]+src="([^"]+)"/) || (p.body || "").match(/file\s*:\s*["']([^"']+\.m3u8[^"']*)/);
        if (sm && sm[1]) videos.push({ url: sm[1], originalUrl: sm[1], quality: "AnimeVN HLS", headers: { "User-Agent": YH_UA, "Referer": this.base() + "/" } });
      } catch (e) {}
    }
    // 2) Embedded players (Hydrax/Abyss, hh3d…): let a hidden WebView play
    //    the episode page and pick up the real stream.
    const usable = listed.filter((k) => servers[k] && !/[?=\/]$/.test(servers[k]));
    if (!videos.length && usable.length) {
      try {
        // Hydrax/Abyss serves a plain <video> (no Service Worker) to UC Browser.
        const out = await evaluateJavascriptViaWebview(full, { "User-Agent": YH_UA, "Referer": this.base() + "/" },
          ["__yh_sniff__", "", "UCBrowser/13.4.0.1306"]);
        const r = JSON.parse(out || "{}");
        for (const it of (r.all || []).slice(0, 4)) {
          const h = Object.assign({ "User-Agent": YH_UA }, it.headers || {});
          const isPl = /\.m3u8|\.mpd/i.test(it.url);
          videos.push({ url: it.url, originalUrl: it.url, quality: `${usable.join("/")} ${isPl ? "HLS" : "MP4"}`, headers: h });
        }
      } catch (e) {}
    }
    // 3) Every embed server as the site's own web player: YomiHub opens these
    //    in its web player, and the automatic server switch falls back to them.
    const ref = { "User-Agent": YH_UA, "Referer": this.base() + "/" };
    for (const k of usable) {
      const e = yhAbs(this.base(), servers[k]);
      videos.push({ url: "yhweb:" + e, originalUrl: e, quality: k + " (web)", headers: ref });
    }
    if (usable.length) videos.push({ url: "yhweb:" + full, originalUrl: full, quality: "Trang AnimeVN (web)", headers: ref });
    if (!videos.length) throw new Error("Tập này chưa có link phát trên AnimeVN.");
    return videos;
  }
  getFilterList() {
    return [
      yhHeader("Bộ lọc chỉ dùng khi ô tìm kiếm để trống"),
      yhSelect("list", "Danh sách", AVN_LISTS),
      yhSelect("genre", "Thể loại (ưu tiên hơn Danh sách)", AVN_GENRES),
    ];
  }
  getSourcePreferences() { return [yhDomainPref("https://animevn.net")]; }
}
