// VTVgo (vtvgo.vn) – truyền hình trực tiếp miễn phí của Đài THVN. Bundled with YomiHub.
// Chỉ phát các kênh miễn phí không có DRM; kênh trả phí/có DRM sẽ báo không hỗ trợ.
class DefaultExtension extends MProvider {
  constructor() { super(); this.client = new Client(); }
  get supportsLatest() { return false; }
  api() { return ("" + yhPref("yh_api", "https://api.vtvdigital.org")).replace(/\/+$/, ""); }
  getHeaders(url) {
    return { "User-Agent": YH_UA, "Origin": yhBase(this), "Referer": yhBase(this) + "/", "Content-Type": "application/json", "accept-language": "vi-VN,vi" };
  }
  async catalogs() {
    const res = await this.client.get(`${this.api()}/display/v21.0/catalogs/with-channels?platform=web`, this.getHeaders());
    const d = JSON.parse(res.body);
    return d.data || d.result || [];
  }
  channelItem(c, catName) {
    return {
      name: c.name + (catName ? "" : ""),
      imageUrl: c.thumbnail || c.logo || "",
      link: "channel:" + c.id,
    };
  }
  async all(filterCat) {
    const cats = await this.catalogs();
    const list = [];
    const seen = {};
    for (const cat of cats) {
      if (filterCat && cat.id !== filterCat) continue;
      for (const c of cat.channels || []) {
        if (!c.enabled || seen[c.id]) continue;
        seen[c.id] = 1;
        list.push(this.channelItem(c, cat.name));
      }
    }
    return list;
  }
  async getPopular(page) {
    if (page > 1) return { list: [], hasNextPage: false };
    return { list: await this.all(), hasNextPage: false };
  }
  async getLatestUpdates(page) { return this.getPopular(page); }
  async search(query, page, filters) {
    if (page > 1) return { list: [], hasNextPage: false };
    const cat = yhF(filters, "catalog") || "";
    let list = await this.all(cat);
    if (query && query.trim()) {
      const q = query.trim().toLowerCase();
      list = list.filter((i) => i.name.toLowerCase().includes(q));
    }
    return { list, hasNextPage: false };
  }
  async getDetail(url) {
    const id = url.replace("channel:", "");
    let ch = null, catName = "";
    for (const cat of await this.catalogs()) {
      for (const c of cat.channels || []) if (("" + c.id) === id) { ch = c; catName = cat.name; }
    }
    ch = ch || { id, name: "Kênh " + id };
    return {
      name: ch.name,
      imageUrl: ch.thumbnail || ch.logo || "",
      description: `Truyền hình trực tiếp ${ch.name}${catName ? " – " + catName : ""} trên VTVgo.` +
        (ch.mustLogin ? "\nKênh này yêu cầu đăng nhập VTVgo." : ""),
      genre: [catName || "Truyền hình"],
      status: 0,
      link: `${yhBase(this)}/channel/${id}`,
      episodes: [{ name: "Trực tiếp", url: "live:" + id }],
    };
  }
  async getVideoList(url) {
    const id = url.replace("live:", "");
    const res = await this.client.post(`${this.api()}/live-channel/v21.0/playback/source`, this.getHeaders(), { channelId: id, platform: "web" });
    const d = JSON.parse(res.body);
    const data = d.data || d.result || {};
    const videos = [];
    for (const mode of data.sourceModes || []) {
      if (mode.isVip) continue;
      for (const ms of mode.multiSource || []) {
        const drm = ((ms.drmInfo || {}).drmType || ms.drmTypeID || "none").toLowerCase();
        if (drm !== "none") continue;
        (ms.sources || []).forEach((s, i) => {
          if (s.url) videos.push({ url: s.url, originalUrl: s.url, quality: `${data.channelName || "VTVgo"} – nguồn ${videos.length + 1}`, headers: { "User-Agent": YH_UA, "Referer": yhBase(this) + "/", "Origin": yhBase(this) } });
        });
      }
    }
    if (!videos.length) throw new Error(d.message || "Kênh này cần tài khoản trả phí hoặc có DRM nên YomiHub không phát được.");
    return videos;
  }
  getFilterList() {
    return [yhSelect("catalog", "Nhóm kênh", [["Tất cả", ""], ["Kênh VTV", "6a95b9e9cc5bb9fa8eeac4db"], ["Kênh thiết yếu và địa phương", "6a95b9e9cc5bb9fa8eeac4da"], ["Gói kênh VTVcab", "6a95b9e9cc5bb9fa8eeac4d9"], ["Kênh SCTV", "6a95b9e9cc5bb9fa8eeac4e1"], ["ONE VTV Sport", "6a95b9e9cc5bb9fa8eeac4e4"], ["Kênh Msky", "6a97d6c0eeb3bc80433dea5f"], ["Phim, giải trí", "6aa12ca6505b0f966e27c5ea"], ["Tin tức, thiếu nhi, khoa giáo", "6aa13a6d1dc7eae6da6d2210"]])];
  }
  getSourcePreferences() {
    return [
      yhDomainPref("https://vtvgo.vn"),
      { key: "yh_api", editTextPreference: { title: "Địa chỉ API", summary: "Mặc định https://api.vtvdigital.org", value: "https://api.vtvdigital.org", dialogTitle: "API", dialogMessage: "", text: "https://api.vtvdigital.org" } },
    ];
  }
}
