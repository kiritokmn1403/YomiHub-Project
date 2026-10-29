// FapReel (18+) – "porn reels" dọc. YomiHub 0.2.0, có Short Video.
// Trang dựng sẵn: /?page=N, /reels/<chủ đề>?page=N, /shorts. Mỗi reel không
// có trang riêng nên dữ liệu reel (id, mp4, ảnh, tên) nằm trong link.
const FR_TOPICS = [["Trang chủ", ""], ["Shorts", "shorts"], ["Amateur", "amateur"], ["Anal", "anal"], ["Babe", "babe"], ["Big Ass", "big-ass"], ["Big Boobs", "big-boobs"], ["Blonde", "blonde"], ["Blowjob", "blowjob"], ["Brunette", "brunette"], ["Hardcore", "hardcore"], ["Lesbian", "lesbian"], ["Masturbation", "masturbation"], ["MILF", "milf"], ["Natural Tits", "natural-tits"], ["OnlyFans", "onlyfans"], ["Petite", "petite"], ["Small Boobs", "small-boobs"], ["Solo", "solo-action"], ["Teen 18+", "teen-18"]];
class DefaultExtension extends MProvider {
  constructor() { super(); this.client = new Client(); }
  get supportsLatest() { return true; }
  base() { return yhBase(this); }
  getHeaders(url) { return { "User-Agent": YH_UA, "Referer": this.base() + "/", "Cookie": "fr_age_ok=1" }; }
  async page(url) {
    const res = await this.client.get(url, this.getHeaders(url));
    if (res.statusCode >= 400) throw new Error("FapReel: HTTP " + res.statusCode + " (trang bị chặn? bật DoH hoặc VPN)");
    const html = res.body || "";
    // names from the schema.org VideoObject blocks, keyed by video file
    const names = {};
    for (const m of html.matchAll(/<script type="application\/ld\+json">([\s\S]*?)<\/script>/g)) {
      try {
        const j = JSON.parse(m[1]);
        for (const o of Array.isArray(j) ? j : [j]) if (o && o["@type"] === "VideoObject" && o.contentUrl) names[o.contentUrl.replace(/^https?:\/\/[^/]+/, "").split("?")[0]] = o.name;
      } catch (e) {}
    }
    const doc = new Document(html);
    const list = [];
    const seen = {};
    for (const r of doc.select("article.reel")) {
      const id = (r.attr("id") || "").replace("reel-", "");
      const src = r.attr("data-src");
      if (!id || !src || seen[id]) continue;
      seen[id] = 1;
      const img = r.selectFirst("img.reel-poster");
      const who = yhText((r.selectFirst(".reel-name") || r.selectFirst(".reel-studio span") || {}).text);
      const tags = r.select(".reel-topniche").map((a) => yhText(a.text)).filter((x) => x);
      const v = yhAbs(this.base(), src);
      const name = names[src.split("?")[0]] || (who ? who + (tags.length ? " – " + tags.slice(0, 2).join(", ") : "") : "Reel " + id);
      const i = img ? yhAbs(this.base(), img.attr("src")) : "";
      list.push({
        name: yhText(name),
        imageUrl: i,
        link: JSON.stringify({ id: id, v: v, i: i, n: yhText(name), w: who, t: tags, url: this.base() + "/#reel-" + id }),
      });
    }
    return list;
  }
  listUrl(topic, page) {
    const p = page > 1 ? `?page=${page}` : "";
    if (!topic) return this.base() + "/" + p;
    if (topic === "shorts") return this.base() + "/shorts" + p;
    return `${this.base()}/reels/${topic}${p}`;
  }
  async getPopular(page) { const list = await this.page(this.listUrl("", page)); return { list, hasNextPage: list.length > 0 }; }
  async getLatestUpdates(page) { return await this.getPopular(page); }
  async search(query, page, filters) {
    if (query && query.trim()) {
      const slug = query.trim().toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "").replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
      let list = [];
      try { list = await this.page(`${this.base()}/reels/${slug}` + (page > 1 ? `?page=${page}` : "")); } catch (e) {}
      if (!list.length) try { list = await this.page(`${this.base()}/reels/creator/${slug}` + (page > 1 ? `?page=${page}` : "")); } catch (e) {}
      return { list, hasNextPage: list.length > 0 };
    }
    const list = await this.page(this.listUrl(yhF(filters, "topic") || "", page));
    return { list, hasNextPage: list.length > 0 };
  }
  data(url) { try { return JSON.parse(url); } catch (e) { return { v: url }; } }
  async getDetail(url) {
    const d = this.data(url);
    return {
      name: d.n || "FapReel", imageUrl: d.i || "", author: d.w || "",
      description: (d.n || "") + (d.t && d.t.length ? "\n" + d.t.join(" · ") : ""),
      genre: d.t || [], status: 1, link: d.url || this.base(),
      episodes: [{ name: "Xem reel", url: url }],
    };
  }
  async getVideoList(url) {
    const d = this.data(url);
    const v = d.v || "";
    if (!v) return [];
    return [{ url: v, originalUrl: v, quality: "MP4", headers: { "User-Agent": YH_UA, "Referer": this.base() + "/" } }];
  }
  getFilterList() {
    return [
      yhSelect("feed", "Nguồn video", [["Reels (video dọc)", "shorts"]]),
      yhSelect("topic", "Chủ đề (khi không tìm kiếm)", FR_TOPICS),
    ];
  }
  getSourcePreferences() { return [yhDomainPref("https://fapreel.com")]; }
}
