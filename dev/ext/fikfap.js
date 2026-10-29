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
    let url = `${this.api()}${path}${path.includes("?") ? "&" : "?"}amount=24`;
    if (page > 1) {
      const after = sp.getString(`ff_after_${key}_${page}`, "");
      if (!after) return { list: [], hasNextPage: false };
      url += "&afterId=" + after;
    }
    const res = await this.client.get(url, this.getHeaders(url));
    if (res.statusCode >= 400) throw new Error("FikFap: HTTP " + res.statusCode);
    let arr = JSON.parse(res.body);
    if (!Array.isArray(arr)) arr = arr.posts || arr.data || [];
    const orient = yhPref("ff_orient", "");
    if (orient) arr = arr.filter((p) => !p.sexualOrientation || p.sexualOrientation === orient);
    const list = arr.map((p) => ({
      name: yhText(p.label || "Video") + (p.author && p.author.username ? " · @" + p.author.username : ""),
      imageUrl: p.thumbnailStreamUrl || "",
      link: JSON.stringify({ id: p.postId, u: p.author ? p.author.username : "" }),
    }));
    if (arr.length) sp.setString(`ff_after_${key}_${page + 1}`, "" + arr[arr.length - 1].postId);
    return { list, hasNextPage: arr.length > 0 };
  }
  async getPopular(page) { return this.posts("/posts?sort=trending", page, "pop"); }
  async getLatestUpdates(page) { return this.posts("/posts", page, "new"); }
  async search(query, page, filters) {
    const q = (query || "").trim().replace(/^#/, "");
    const mode = yhF(filters, "mode") || "tag";
    if (!q) return this.getLatestUpdates(page);
    if (mode === "user" || q.startsWith("@")) return this.posts(`/profile/username/${encodeURIComponent(q.replace(/^@/, ""))}/posts`, page, "u_" + q);
    return this.posts(`/hashtags/label/${encodeURIComponent(q)}/posts`, page, "t_" + q);
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
    const res = await this.client.get(`${this.api()}/posts/${url}`, this.getHeaders());
    const p = JSON.parse(res.body);
    const v = p.videoStreamUrl;
    if (!v) throw new Error("Video chưa sẵn sàng.");
    return [{ url: v, originalUrl: v, quality: "FikFap HLS", headers: { "User-Agent": YH_UA, "Referer": yhBase(this) + "/" } }];
  }
  getFilterList() {
    return [yhSelect("mode", "Tìm theo", [["Hashtag", "tag"], ["Tên người dùng", "user"]])];
  }
  getSourcePreferences() {
    return [
      yhDomainPref("https://fikfap.com"),
      { key: "yh_api", editTextPreference: { title: "Địa chỉ API", summary: "Mặc định https://api.fikfap.com", value: "https://api.fikfap.com", dialogTitle: "API", dialogMessage: "", text: "https://api.fikfap.com" } },
      { key: "ff_orient", listPreference: { title: "Xu hướng nội dung", summary: "", valueIndex: 0, entries: FF_ORIENT.map((o) => o[0]), entryValues: FF_ORIENT.map((o) => o[1]) } },
    ];
  }
}
