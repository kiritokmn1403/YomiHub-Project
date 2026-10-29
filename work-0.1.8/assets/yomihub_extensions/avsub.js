// AVSub – AnimeVietsub (animevietsub.nl). Bundled with YomiHub 0.1.4.
const AVS_GENRES = [["Tất cả",""],["Hành động","hanh-dong"],["Phiêu lưu","phieu-luu"],["Hài hước","hai-huoc"],["Tình cảm","tinh-cam"],["Học đường","truong-hoc"],["Siêu nhiên","sieu-nhien"],["Phép thuật","phep-thuat"],["Ma thuật","ma-thuat"],["Kinh dị","kinh-di"],["Bí ẩn","mystery"],["Tâm lý","psychological"],["Drama","drama"],["Đời thường","doi-thuong"],["Thể thao","the-thao"],["Âm nhạc","am-nhac"],["Mecha","mecha"],["Sci-Fi","sci-fi"],["Shounen","shounen"],["Seinen","seinen"],["Shoujo","shoujo"],["Josei","josei"],["Harem","harem"],["Ecchi","ecchi"],["Isekai / Trò chơi","tro-choi"],["Lịch sử","lich-su"],["Quân đội","quan-doi"],["Samurai","samurai"],["Võ thuật","martial-arts"],["Vampire","vampire"],["Demons","demons"],["Siêu năng lực","super-power"],["Không gian","space"],["Thriller","thriller"],["Hồi hộp","hoi-hop"],["Cartoon","cartoon"],["Trẻ em","tre-em"],["Live Action","live-action"],["Tokusatsu","tokusatsu"]];
const AVS_LISTS = [["Anime mới cập nhật","/anime-moi/"],["Đang chiếu","/danh-sach/list-dang-chieu/"],["Trọn bộ","/danh-sach/list-tron-bo/"],["Anime bộ","/anime-bo/"],["Anime lẻ (movie)","/anime-le/"],["Sắp chiếu","/anime-sap-chieu/"],["Hoạt hình Trung Quốc","/hoat-hinh-trung-quoc/"],["Xếp hạng ngày","/bang-xep-hang/day.html"],["Xếp hạng tháng","/bang-xep-hang/month.html"],["Xếp hạng mùa","/bang-xep-hang/season.html"],["Xếp hạng năm","/bang-xep-hang/year.html"],["Được bình chọn","/bang-xep-hang/voted.html"]];
const AVS_SEASONS = [["Không chọn",""],["Xuân","spring"],["Hạ","summer"],["Thu","autumn"],["Đông","winter"]];

class DefaultExtension extends MProvider {
  constructor() { super(); this.client = new Client(); }
  get supportsLatest() { return true; }
  base() { return yhBase(this); }
  cookie() {
    try { return new SharedPreferences().getString("yh_avs_cookie", ""); } catch (e) { return ""; }
  }
  saveCookie(c) {
    try { new SharedPreferences().setString("yh_avs_cookie", c); } catch (e) {}
  }
  getHeaders(url) {
    const h = { "User-Agent": YH_UA, "Referer": this.base() + "/", "Accept-Language": "vi-VN,vi;q=0.9" };
    const c = this.cookie();
    if (c) h["Cookie"] = c;
    return h;
  }
  // The site answers the first visit with 403 + a cookie, then serves pages
  // to clients that send that cookie back.
  mergeCookies(res) {
    const raw = (res.headers && (res.headers["set-cookie"] || res.headers["Set-Cookie"])) || "";
    if (!raw) return false;
    const jar = {};
    for (const part of this.cookie().split(";")) {
      const i = part.indexOf("=");
      if (i > 0) jar[part.slice(0, i).trim()] = part.slice(i + 1).trim();
    }
    const re = /(?:^|,\s*)([A-Za-z0-9_\-]+)=([^;,]*)/g;
    let m, changed = false;
    while ((m = re.exec(raw)) !== null) {
      if (/^(expires|path|domain|max-age)$/i.test(m[1])) continue;
      if (jar[m[1]] !== m[2]) { jar[m[1]] = m[2]; changed = true; }
    }
    if (changed) this.saveCookie(Object.keys(jar).map((k) => k + "=" + jar[k]).join("; "));
    return changed;
  }
  async get(url) {
    let res = await this.client.get(url, this.getHeaders(url));
    if (res.statusCode === 403 && this.mergeCookies(res)) res = await this.client.get(url, this.getHeaders(url));
    else this.mergeCookies(res);
    // Cloudflare challenge (e.g. through Tor/VPN): let a WebView pass it and
    // hand back the rendered page.
    const b = res.body || "";
    if (/<title>\s*Just a moment|challenge-platform/i.test(b) || (res.statusCode >= 400 && b.length < 5000)) {
      const script = `(function(){var n=0;var t=setInterval(function(){n++;
        var ok=!/Just a moment/i.test(document.title)&&document.querySelector('body')&&document.body.innerHTML.length>2000;
        if(ok||n>120){clearInterval(t);window.flutter_inappwebview.callHandler('setResponse',ok?document.documentElement.outerHTML:'');}},250);})();`;
      try {
        const html = await evaluateJavascriptViaWebview(url, this.getHeaders(url), [script]);
        if (html) return { statusCode: 200, body: html, headers: {} };
      } catch (e) {}
    }
    return res;
  }
  async post(url, body) {
    const h = this.getHeaders(url);
    h["X-Requested-With"] = "XMLHttpRequest";
    h["Content-Type"] = "application/x-www-form-urlencoded; charset=UTF-8";
    let res = await this.client.post(url, h, body);
    if (res.statusCode === 403 && this.mergeCookies(res)) res = await this.client.post(url, this.getHeaders(url), body);
    return res;
  }
  async doc(url) {
    const res = await this.get(url);
    this._last = `HTTP ${res.statusCode}, ${(res.body || "").length} byte`;
    return new Document(res.body);
  }
  // An empty first page means the site did not serve the list (blocked, new
  // domain…): report what came back instead of a silent "no results".
  checked(r, page) {
    if (!r.list.length && (page || 1) === 1) throw new Error("AVSub không trả về danh sách (" + this._last + "). Thử mở WebView của tiện ích, hoặc đổi Tên miền trong cài đặt.");
    return r;
  }
  listUrl(path, page, sort) {
    let p = path;
    if (p.endsWith(".html")) return this.base() + p; // rankings have one page
    p = p.replace(/\/?$/, "/");
    return this.base() + p + (page > 1 ? `trang-${page}.html` : "") + (sort ? `?sort=${sort}` : "");
  }
  parse(doc, page) {
    const list = [];
    const seen = {};
    for (const it of doc.select("article.TPost.C, li.TPostMv .TPost")) {
      const a = it.selectFirst("a");
      if (!a) continue;
      const link = a.getHref;
      if (!link || seen[link] || link.indexOf("/phim/") < 0) continue;
      seen[link] = 1;
      const img = it.selectFirst("img");
      const t = it.selectFirst(".Title");
      list.push({
        name: yhText(t ? t.text : (img ? img.attr("title") || img.attr("alt") : "")),
        link: link.replace(/^https?:\/\/[^/]+/, ""),
        imageUrl: img ? (img.attr("data-src") || img.attr("src") || "") : "",
      });
    }
    // ranking pages (bang-xep-hang) use a different card
    if (!list.length) {
      for (const it of doc.select(".e-item")) {
        const a = it.selectFirst("a[href*='/phim/']");
        if (!a) continue;
        const link = a.getHref;
        if (!link || seen[link]) continue;
        seen[link] = 1;
        const img = it.selectFirst("img");
        const t = it.selectFirst(".title-item");
        list.push({
          name: yhText(t ? t.text : (a.attr("title") || "").replace(/^Phim\s+/, "").split(" - ")[0]),
          link: link.replace(/^https?:\/\/[^/]+/, ""),
          imageUrl: img ? (img.attr("data-src") || img.attr("src") || "") : "",
        });
      }
    }
    const pages = doc.select(".wp-pagenavi a, .pagination a").map((a) => a.getHref).join(" ");
    const hasNextPage = list.length > 0 && pages.indexOf(`trang-${(page || 1) + 1}.html`) >= 0;
    return { list, hasNextPage };
  }
  async getPopular(page) { return this.checked(this.parse(await this.doc(this.listUrl("/anime-moi/", page, "view")), page), page); }
  async getLatestUpdates(page) { return this.checked(this.parse(await this.doc(this.listUrl("/anime-moi/", page)), page), page); }
  async search(query, page, filters) {
    if (query && query.trim()) {
      const q = encodeURIComponent(query.trim().replace(/\s+/g, "+")).replace(/%2B/g, "+");
      return this.parse(await this.doc(this.base() + `/tim-kiem/${q}/` + (page > 1 ? `trang-${page}.html` : "")), page);
    }
    const g = yhF(filters, "genre") || "";
    const season = yhF(filters, "season") || "";
    const year = (yhF(filters, "year") || "").trim();
    const sort = yhF(filters, "sort") || "";
    if (season && /^\d{4}$/.test(year)) return this.parse(await this.doc(this.listUrl(`/season/${season}/${year}/`, page, sort)), page);
    if (g) return this.parse(await this.doc(this.listUrl(`/the-loai/${g}/`, page, sort)), page);
    const l = yhF(filters, "list") || "/anime-moi/";
    return this.parse(await this.doc(this.listUrl(l, page, yhF(filters, "sort") || "")), page);
  }
  async getDetail(url) {
    const full = yhAbs(this.base(), url).replace(/xem-phim\.html$|tap-[^/]+\.html$/, "");
    const doc = await this.doc(full);
    const meta = (p) => { const e = doc.selectFirst(`meta[property="${p}"]`); return e ? e.attr("content") : ""; };
    const name = yhText((doc.selectFirst("h1.Title") || {}).text) || meta("og:title");
    const sub = yhText((doc.selectFirst("h2.SubTitle") || {}).text);
    const info = doc.select(".InfoList li").map((l) => yhText(l.text)).filter((t) => t && !/^Tập mới/.test(t));
    let status = 5, author = "";
    for (const t of info) {
      if (/^Trạng thái/i.test(t)) status = /hoàn|full|trọn/i.test(t) ? 1 : (/đang|cập nhật/i.test(t) ? 0 : 5);
      if (/^Đạo diễn|^Studio/i.test(t) && !author) author = t.replace(/^[^:]*:\s*/, "");
    }
    const genre = doc.select(".InfoList a[href*='/the-loai/']").map((a) => yhText(a.text)).filter((v, i, a) => v && a.indexOf(v) === i);
    const img = doc.selectFirst(".Image img.wp-post-image, .TPost .Image img");
    const description = yhText((doc.selectFirst(".Description") || {}).text) +
      (sub ? "\n\nTên khác: " + sub : "") + (info.length ? "\n\n" + info.join("\n") : "");
    // the episode list lives on the watch page
    const watch = await this.doc(full.replace(/\/?$/, "/") + "xem-phim.html");
    const eps = [];
    const seen = {};
    const groups = watch.select(".server.server-group");
    const multi = groups.length > 1;
    for (const g of groups.length ? groups : [watch]) {
      const label = multi ? yhText((g.selectFirst(".server-name") || {}).text) : "";
      for (const a of g.select("a.episode-link")) {
        const href = a.getHref;
        if (!href || seen[href]) continue;
        seen[href] = 1;
        const t = yhText(a.attr("title") || a.text);
        eps.push({ name: (label ? `[${label}] ` : "") + (/^\d/.test(t) ? "Tập " + t : t), url: href.replace(/^https?:\/\/[^/]+/, "") });
      }
    }
    eps.reverse();
    return {
      name, imageUrl: (img && !/logo/.test(img.attr("src") || "")) ? img.attr("src") : meta("og:image"),
      description, author, genre, status, link: full.replace(this.base(), ""), episodes: eps,
    };
  }
  // Every server becomes one entry; servers that only exist as the site's
  // own web player are flagged "yhweb:" so YomiHub opens them in its web
  // player and the automatic server switch can fall back to them.
  addResult(out, f, label) {
    if (!f || f.success != 1) return;
    const ref = { "Referer": this.base() + "/", "User-Agent": YH_UA };
    if ((f.playTech === "api" || f.playTech === "all") && Array.isArray(f.link)) {
      for (const x of f.link) {
        const file = ("" + (x.file || "")).replace("&http", "http");
        if (!file) continue;
        out.push({ url: file, originalUrl: file, quality: `${label} ${x.label || ""}`.trim(), headers: ref });
      }
    } else if (typeof f.link === "string" && /^https?:/.test(f.link)) {
      if (/\.(m3u8|mp4)(\?|$)/.test(f.link)) out.push({ url: f.link, originalUrl: f.link, quality: label, headers: ref });
      else out.push({ url: "yhweb:" + f.link, originalUrl: f.link, quality: label + " (web)", headers: ref });
    }
  }
  async getVideoList(url) {
    const full = yhAbs(this.base(), url);
    const res = await this.get(full);
    const html = res.body;
    const doc = new Document(html);
    const out = [];
    const film = (full.match(/-a(\d+)\//) || [])[1] || "";
    const active = doc.selectFirst("a.episode-link.active") || doc.selectFirst(`a.episode-link[href="${full}"]`);
    const epId = active ? active.attr("data-id") : ((html.match(/"episode_id"\s*:\s*"(\d+)"/) || [])[1] || "");
    // 1) the default server
    try {
      const m = html.match(/window\.PLAYER_DATA\s*=\s*(\{[\s\S]*?\});/);
      if (m) this.addResult(out, JSON.parse(m[1]), "DU");
      else if (active) {
        const r = await this.post(this.base() + "/ajax/player", `link=${encodeURIComponent(active.attr("data-hash"))}&id=${film}`);
        this.addResult(out, JSON.parse(r.body), "DU");
      }
    } catch (e) {}
    // 2) backup servers
    try {
      if (epId) {
        const r = await this.post(this.base() + "/ajax/player", `episodeId=${epId}&backup=1`);
        const j = JSON.parse(r.body);
        const sv = new Document("<div>" + (j.html || "") + "</div>");
        for (const a of sv.select("a.btn3dsv")) {
          const label = yhText(a.text);
          if (label === "DU" && out.length) continue;
          try {
            const rr = await this.post(this.base() + "/ajax/player",
              `link=${encodeURIComponent(a.attr("data-href"))}&play=${a.attr("data-play")}&id=${a.attr("data-id")}&backuplinks=1`);
            this.addResult(out, JSON.parse(rr.body), label);
          } catch (e) {}
        }
      }
    } catch (e) {}
    // direct streams first, web players last
    out.sort((a, b) => (a.url.startsWith("yhweb:") ? 1 : 0) - (b.url.startsWith("yhweb:") ? 1 : 0));
    return out;
  }
  getFilterList() {
    return [
      yhHeader("Bộ lọc dùng khi ô tìm kiếm trống"),
      yhSelect("list", "Danh sách", AVS_LISTS.map((x) => [x[0], x[1]])),
      yhSelect("sort", "Sắp xếp", [["Mặc định", ""], ["Mới cập nhật", "latest"], ["Xem nhiều", "view"], ["Đánh giá", "rating"], ["Tên A-Z", "nameaz"], ["Tên Z-A", "nameza"]]),
      yhSelect("genre", "Thể loại", AVS_GENRES),
      yhSelect("season", "Mùa", AVS_SEASONS),
      yhText_("year", "Năm (dùng cùng Mùa, vd. 2026)"),
    ];
  }
  getSourcePreferences() { return [yhDomainPref("https://animevietsub.nl", "AnimeVietsub hay đổi tên miền")]; }
}
