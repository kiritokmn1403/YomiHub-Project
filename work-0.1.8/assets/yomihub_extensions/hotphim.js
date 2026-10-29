// HotPhim (hotphim.org). Bundled with YomiHub.
const HP_GENRES = [["Tất cả",""],["Phim bộ","phim-bo"],["Phim lẻ","phim-le"],["Phim chiếu rạp","phim-chieu-rap"],["Phim đang chiếu","phim-dang-chieu"],["Phim sắp chiếu","phim-sap-chieu"],["TV Show","tv-show"],["Anime","anime"],["Hoạt hình","hoat-hinh"],["Hành động","hanh-dong"],["Chính kịch","chinh-kich"],["Cổ trang","co-trang"],["Gia đình","gia-dinh"],["Hài hước","hai-huoc"],["Hình sự","hinh-su"],["Khoa học","khoa-hoc"],["Kinh dị","kinh-di"],["Phiêu lưu","phieu-luu"],["Tâm lý","tam-ly"],["Thần thoại","than-thoai"],["Tình cảm","tinh-cam"],["Viễn tưởng","vien-tuong"],["Võ thuật","vo-thuat"]];
const HP_COUNTRIES = [["Tất cả",""],["Việt Nam","viet-nam"],["Trung Quốc","trung-quoc"],["Hàn Quốc","han-quoc"],["Nhật Bản","nhat-ban"],["Thái Lan","thai-lan"],["Âu Mỹ","au-my"],["Anh","anh"],["Đài Loan","dai-loan"],["Hồng Kông","hong-kong"],["Singapore","singapore"],["Indonesia","indonesia"],["Canada","canada"],["Brazil","brazil"],["Mexico","mexico"],["Iran","iran"]];

class DefaultExtension extends MProvider {
  constructor() { super(); this.client = new Client(); }
  get supportsLatest() { return true; }
  base() { return yhBase(this); }
  getHeaders(url) { return { "User-Agent": YH_UA, "Referer": this.base() + "/" }; }
  async doc(url) {
    const res = await this.client.get(url, this.getHeaders(url));
    return new Document(res.body);
  }
  pageUrl(path, page, query) {
    let u = this.base() + path.replace(/\/?$/, "/");
    if (page > 1) u += `page/${page}/`;
    if (query) u += `?s=${encodeURIComponent(query)}`;
    return u;
  }
  parse(doc) {
    const list = [];
    const seen = {};
    for (const it of doc.select(".sw-item, .item")) {
      const a = it.selectFirst(".item-title a") || it.selectFirst("a.v-thumbnail");
      if (!a) continue;
      const link = a.getHref;
      if (!link || seen[link] || !/hotphim|^\//.test(link)) continue;
      seen[link] = 1;
      const img = it.selectFirst("img");
      list.push({
        name: yhText(a.attr("title") || a.text || (img ? img.attr("alt") : "")),
        link,
        imageUrl: img ? (img.attr("data-src") || img.attr("src") || "") : "",
      });
    }
    const hasNextPage = doc.select("a.next, a.next.page-numbers, .pagination a[rel=next]").length > 0 ||
      doc.outerHtml.indexOf("/page/") >= 0 && list.length >= 20;
    return { list, hasNextPage };
  }
  async getPopular(page) { return this.parse(await this.doc(this.pageUrl("/the-loai/phim-chieu-rap", page))); }
  async getLatestUpdates(page) { return this.parse(await this.doc(this.pageUrl("/the-loai/phim-dang-chieu", page))); }
  async search(query, page, filters) {
    if (query && query.trim()) return this.parse(await this.doc(this.pageUrl("", page, query.trim())));
    const g = yhF(filters, "genre") || "";
    const c = yhF(filters, "country") || "";
    if (g) return this.parse(await this.doc(this.pageUrl(`/the-loai/${g}`, page)));
    if (c) return this.parse(await this.doc(this.pageUrl(`/quoc-gia/${c}`, page)));
    return this.getLatestUpdates(page);
  }
  async getDetail(url) {
    const full = yhAbs(this.base(), url);
    const doc = await this.doc(full);
    const meta = (p) => { const e = doc.selectFirst(`meta[property="${p}"]`) || doc.selectFirst(`meta[name="${p}"]`); return e ? e.attr("content") : ""; };
    const name = yhText((meta("og:title") || "").replace(/\s*[-|]\s*Hot\s*Phim.*$/i, "").replace(/^Xem\s+Phim\s+/i, ""));
    const lines = [];
    let author = "";
    for (const l of doc.select(".detail-line")) {
      const k = yhText((l.selectFirst(".de-title") || {}).text);
      const v = yhText((l.selectFirst(".de-value") || {}).text);
      if (!k) continue;
      if (/Đạo diễn/i.test(k)) author = v;
      lines.push(k + " " + v);
    }
    const genre = doc.select(".hl-tags a.tag-topic, a[href*='/the-loai/']").map((e) => yhText(e.text)).filter((v, i, a) => v && a.indexOf(v) === i).slice(0, 15);
    const descEl = doc.selectFirst(".description") || doc.selectFirst(".de-description");
    const description = yhText(descEl ? descEl.text : meta("description")) + (lines.length ? "\n\n" + lines.join("\n") : "");
    const eps = [];
    const seen = {};
    for (const a of doc.select(".de-eps a.item, .de-eps a, a[href*='/tap-']")) {
      const href = a.getHref;
      if (!href || seen[href]) continue;
      seen[href] = 1;
      const num = (href.match(/\/(\d+)\/?$/) || [])[1];
      eps.push({ name: yhText(a.text) || (num ? "Tập " + num : "Xem"), url: href });
    }
    if (!eps.length) eps.push({ name: "Xem phim", url: full.replace(/\/?$/, "/") + "1/" });
    eps.reverse();
    return { name, imageUrl: meta("og:image"), description, author, genre, status: 5, link: full, episodes: eps };
  }
  async getVideoList(url) {
    const full = yhAbs(this.base(), url);
    const res = await this.client.get(full, this.getHeaders(full));
    const html = res.body;
    const out = [];
    const re = /(?:videoSource|source|file)\s*[:=]\s*['"]([^'"]+\.m3u8[^'"]*)['"]/g;
    let m;
    while ((m = re.exec(html)) !== null) {
      if (!out.some((v) => v.url === m[1])) out.push({ url: m[1], originalUrl: m[1], quality: "HotPhim HLS", headers: this.getHeaders(m[1]) });
    }
    return out;
  }
  getFilterList() {
    return [
      yhHeader("Bộ lọc dùng khi ô tìm kiếm trống"),
      yhSelect("genre", "Thể loại / danh sách", HP_GENRES),
      yhSelect("country", "Quốc gia", HP_COUNTRIES),
    ];
  }
  getSourcePreferences() { return [yhDomainPref("https://hotphim.org")]; }
}
