// FikFap (18+). Bundled with YomiHub, đánh dấu NSFW.
// Lưu ý: nhà mạng Việt Nam chặn tên miền này – bật DNS-over-HTTPS hoặc mục VPN.
const FF_ORIENT = [["Tất cả",""],["Straight","STRAIGHT"],["Gay","GAY"],["Lesbian","LESBIAN"],["Trans","TRANS"]];

class DefaultExtension extends MProvider {
  constructor() { super(); this.client = new Client(); }
  get supportsLatest() { return true; }
  api() { return ("" + yhPref("yh_api", "https://api.fikfap.com")).replace(/\/+$/, ""); }
  anon() {
    const sp = new SharedPreferences();
    let id = sp.getString("ff_anon", "");
    if (!id) {
      id = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, (c) => { const r = (Math.random() * 16) | 0; return (c === "x" ? r : (r & 0x3) | 0x8).toString(16); });
      sp.setString("ff_anon", id);
    }
    return id;
  }
  getHeaders(url) {
    return { "User-Agent": YH_UA, "Origin": yhBase(this), "Referer": yhBase(this) + "/", "Authorization-Anonymous": this.anon(), "isLoggedIn": "false", "isPWA": "false" };
  }
  async posts(path, page, key) {
    const sp = new SharedPreferences();
    let pq = `${path}${path.includes("?") ? "&" : "?"}amount=24`;
    if (page > 1) {
      const after = sp.getString(`ff_after_${key}_${page}`, "");
      if (!after) return { list: [], hasNextPage: false };
      pq += "&afterId=" + after;
    }
    let arr = await this.getJsonAny(pq);
    if (!Array.isArray(arr)) arr = arr.posts || arr.data || [];
    return this.mapPosts(arr, key, page, arr.length > 0);
  }
  mapPosts(arr, key, page, hasNext) {
    const sp = new SharedPreferences();
    if (arr.length) sp.setString(`ff_after_${key}_${page + 1}`, "" + arr[arr.length - 1].postId);
    const orient = yhPref("ff_orient", "");
    if (orient) arr = arr.filter((p) => !p.sexualOrientation || p.sexualOrientation === orient);
    const list = arr.map((p) => ({
      name: yhText(p.label || "Video") + (p.author && p.author.username ? " · @" + p.author.username : ""),
      imageUrl: p.thumbnailStreamUrl || "",
      link: JSON.stringify({ id: p.postId, u: p.author ? p.author.username : "" }),
    }));
    return { list, hasNextPage: hasNext };
  }
  async getPopular(page) { return this.posts("/posts?sort=trending", page, "pop"); }
  async getLatestUpdates(page) { return this.posts("/posts", page, "new"); }
  // 0.4.3: tries the configured API host, then the official one; an HTML
  // answer (block page / Cloudflare) is reported instead of a JSON SyntaxError.
  async getJsonAny(pq) {
    const hosts = [...new Set([this.api(), "https://api.fikfap.com"])];
    let last = null;
    for (const h of hosts) {
      const url = h + pq;
      try {
        const res = await this.client.get(url, this.getHeaders(url));
        const b = ("" + (res.body || "")).trimStart();
        if (res.statusCode < 400 && (b.startsWith("[") || b.startsWith("{"))) return JSON.parse(b);
        last = new Error("FikFap: " + (b.startsWith("<") ? "máy chủ trả về trang HTML (bị chặn hoặc Cloudflare)" : "HTTP " + res.statusCode) + " – " + h);
      } catch (e) { last = e; }
    }
    throw last || new Error("FikFap: không tải được dữ liệu");
  }
  async apiJson(path) {
    const url = this.api() + path;
    const res = await this.client.get(url, this.getHeaders(url));
    if (res.statusCode >= 400) return null;
    try { return JSON.parse(res.body); } catch (e) { return null; }
  }
  async search(query, page, filters) {
    const q = (query || "").trim().replace(/^#/, "");
    const mode = yhF(filters, "mode") || "tag";
    const sort = yhF(filters, "sort") || "";
    if (!q) return sort ? this.posts(`/posts?sort=${sort}`, page, "s_" + sort) : this.getLatestUpdates(page);
    const sp = new SharedPreferences();
    if (mode === "user" || q.startsWith("@")) {
      let u = q.replace(/^@/, "");
      const ck = "ff_user_" + u.toLowerCase();
      if (page === 1) {
        const r = await this.apiJson(`/profile/username/${encodeURIComponent(u)}/posts?amount=1`);
        if (!r) {
          const f = await this.apiJson(`/search/profiles?q=${encodeURIComponent(u)}`);
          const list = (f && (f.users || f.profiles || (Array.isArray(f) ? f : []))) || [];
          if (list.length && list[0].username) u = list[0].username;
        }
        sp.setString(ck, u);
      } else u = sp.getString(ck, u);
      return this.posts(`/profile/username/${encodeURIComponent(u)}/posts`, page, "u_" + u);
    }
    if (mode === "text") {
      if (page > 1) return { list: [], hasNextPage: false };
      const r = await this.apiJson(`/search/posts?q=${encodeURIComponent(q)}`);
      return this.mapPosts((r && r.posts) || [], "x", 1, false);
    }
    // hashtag: resolve to an existing label first (labels are case-sensitive)
    const ck = "ff_tag_" + q.toLowerCase();
    let tag = page === 1 ? "" : sp.getString(ck, "");
    if (!tag) {
      const h = await this.apiJson(`/hashtags/label/${encodeURIComponent(q)}`);
      if (h && h.label) tag = h.label;
      else {
        const f = await this.apiJson(`/search/hashtags?q=${encodeURIComponent(q)}`);
        const hs = (f && f.hashtags) || [];
        const exact = hs.find((x) => (x.labelLower || "").toLowerCase() === q.toLowerCase());
        if (exact || hs.length) tag = (exact || hs[0]).label;
      }
      if (!tag) {
        // no such hashtag: fall back to a plain text search
        const r = await this.apiJson(`/search/posts?q=${encodeURIComponent(q)}`);
        return this.mapPosts((r && r.posts) || [], "x", 1, false);
      }
      sp.setString(ck, tag);
    }
    return this.posts(`/hashtags/label/${encodeURIComponent(tag)}/posts${sort ? "?sort=" + sort : ""}`, page, "t_" + tag + sort);
  }
  async getDetail(url) {
    const o = JSON.parse(url);
    const res = await this.client.get(`${this.api()}/posts/${o.id}`, this.getHeaders());
    const p = JSON.parse(res.body);
    const a = p.author || {};
    return {
      name: yhText(p.label || "FikFap video"),
      imageUrl: p.thumbnailStreamUrl || "",
      author: a.username ? "@" + a.username : "",
      description: [p.label, a.description, (p.hashtags || []).map((h) => "#" + (h.label || h)).join(" ")].filter(Boolean).join("\n\n"),
      genre: (p.hashtags || []).map((h) => h.label || h).slice(0, 20),
      status: 1,
      link: `${yhBase(this)}/post/${o.id}`,
      episodes: [{ name: "Xem video", url: "" + o.id }],
    };
  }
  async getVideoList(url) {
    // 0.1.8: a list item link ({"id":…}) works too (Short Video feed)
    if (("" + url).startsWith("{")) url = "" + JSON.parse(url).id;
    const res = await this.client.get(`${this.api()}/posts/${url}`, this.getHeaders());
    const p = JSON.parse(res.body);
    const v = p.videoStreamUrl;
    if (!v) throw new Error("Video chưa sẵn sàng.");
    return [{ url: v, originalUrl: v, quality: "FikFap HLS", headers: { "User-Agent": YH_UA, "Referer": yhBase(this) + "/" } }];
  }
  getFilterList() {
    return [
      yhSelect("mode", "Tìm theo", [["Hashtag", "tag"], ["Tên người dùng", "user"], ["Nội dung (1 trang)", "text"]]),
      yhSelect("sort", "Sắp xếp", [["Mặc định", ""], ["Mới nhất", "new"], ["Thịnh hành", "trending"], ["Hàng đầu", "top"], ["Ngẫu nhiên", "random"]]),
    ];
  }
  getSourcePreferences() {
    return [
      yhDomainPref("https://fikfap.com"),
      { key: "yh_api", editTextPreference: { title: "Địa chỉ API", summary: "Mặc định https://api.fikfap.com", value: "https://api.fikfap.com", dialogTitle: "API", dialogMessage: "", text: "https://api.fikfap.com" } },
      { key: "ff_orient", listPreference: { title: "Xu hướng nội dung", summary: "", valueIndex: 0, entries: FF_ORIENT.map((o) => o[0]), entryValues: FF_ORIENT.map((o) => o[1]) } },
    ];
  }
}
