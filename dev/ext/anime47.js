// Anime47 (anime47.best) – anime Vietsub. Bundled with YomiHub.
// Danh sách và tìm kiếm không cần tài khoản; trang tập phim yêu cầu đăng nhập
// (nhập email + mật khẩu Anime47 trong cài đặt tiện ích).
const A47_SORT = [["Mới cập nhật","latest"],["Xem nhiều","views"],["Đánh giá","rating"],["Tên A-Z","title"],["Cũ nhất","oldest"]];
const A47_TYPE = [["Tất cả",""],["TV","tv"],["Movie","movie"],["OVA","ova"],["ONA","ona"],["Special","special"]];
const A47_STATUS = [["Tất cả",""],["Đang chiếu","airing"],["Hoàn thành","completed"],["Sắp chiếu","upcoming"]];
const A47_SEASON = [["Tất cả",""],["Đông","winter"],["Xuân","spring"],["Hạ","summer"],["Thu","fall"]];
const A47_YEARS = [["Tất cả",""]].concat(Array.from({ length: 45 }, (_, i) => { const y = "" + (new Date().getFullYear() + 1 - i); return [y, y]; }));
const A47_GENRES = [["Tất cả",""],["Action","action"],["Adventure","adventure"],["Avant Garde","avant-garde"],["Award Winning","award-winning"],["Boys Love","boys-love"],["Comedy","comedy"],["Drama","drama"],["Fantasy","fantasy"],["Girls Love","girls-love"],["Gourmet","gourmet"],["Horror","horror"],["Mystery","mystery"],["Romance","romance"],["Sci-Fi","sci-fi"],["Slice of Life","slice-of-life"],["Sports","sports"],["Supernatural","supernatural"],["Suspense","suspense"],["Ecchi","ecchi"],["Isekai","isekai"],["Mecha","mecha"],["Music","music"],["Psychological","psychological"],["School","school"],["Shounen","shounen"],["Seinen","seinen"],["Shoujo","shoujo"],["Josei","josei"],["Historical","historical"],["Martial Arts","martial-arts"],["Military","military"],["Super Power","super-power"],["Vampire","vampire"]];

class DefaultExtension extends MProvider {
  constructor() { super(); this.client = new Client(); }
  get supportsLatest() { return true; }
  api() { return ("" + yhPref("yh_api", "https://anime47.love/api")).replace(/\/+$/, ""); }
  getHeaders(url) {
    const h = { "User-Agent": YH_UA, "Origin": yhBase(this), "Referer": yhBase(this) + "/", "Accept": "application/json" };
    const tok = new SharedPreferences().getString("a47_token", "");
    if (tok) h["Authorization"] = "Bearer " + tok;
    return h;
  }
  async login() {
    const email = yhPref("a47_email", ""), pass = yhPref("a47_password", "");
    if (!email || !pass) return false;
    const res = await this.client.post(`${this.api()}/auth/login`,
      { "Content-Type": "application/json", "User-Agent": YH_UA, "Origin": yhBase(this), "Referer": yhBase(this) + "/" },
      { email: email, password: pass });
    try {
      const d = JSON.parse(res.body);
      const t = d.access_token || d.token || (d.data && (d.data.access_token || d.data.token));
      if (t) { new SharedPreferences().setString("a47_token", t); return true; }
    } catch (e) {}
    return false;
  }
  async json(url, retry) {
    let res = await this.client.get(url, this.getHeaders(url));
    if ((res.statusCode === 401 || res.statusCode === 403) && retry !== false) {
      if (await this.login()) res = await this.client.get(url, this.getHeaders(url));
    }
    const d = JSON.parse(res.body);
    if (d && d.success === false) {
      throw new Error(d.code === "PRIVATE_MODE"
        ? "Anime47 yêu cầu đăng nhập: nhập Email và Mật khẩu trong cài đặt của tiện ích này."
        : (d.message || "Lỗi Anime47"));
    }
    return d;
  }
  item(p) {
    const ep = p.current_episode ? ` (${p.current_episode}${p.episodes ? "/" + p.episodes : ""})` : "";
    return { name: (p.title || p.name) + ep, imageUrl: p.poster || p.image || p.thumbnail || "", link: "" + p.id };
  }
  async filter(page, opts) {
    const g = opts.genre || "";
    const o = Object.assign({ page: page }, opts);
    delete o.genre;
    const q = Object.entries(o).filter(([k, v]) => v !== "" && v !== null && v !== undefined)
      .map(([k, v]) => `${k}=${encodeURIComponent(v)}`).join("&");
    const d = await this.json(`${this.api()}/anime/filter${g ? "/" + g : ""}?${q}`);
    const data = d.data || {};
    const pg = data.pagination || {};
    return { list: (data.posts || []).map((p) => this.item(p)), hasNextPage: (pg.current_page || 1) < (pg.last_page || 1) };
  }
  async getPopular(page) { return this.filter(page, { sort: "views" }); }
  async getLatestUpdates(page) { return this.filter(page, { sort: "latest" }); }
  async search(query, page, filters) {
    if (query && query.trim()) {
      const d = await this.json(`${this.api()}/search/full/?keyword=${encodeURIComponent(query.trim())}&page=${page}`);
      const res = d.results || (d.data && d.data.results) || [];
      const pg = d.pagination || (d.data && d.data.pagination) || {};
      return {
        list: res.map((r) => ({ name: r.title, imageUrl: r.poster || r.image || r.thumbnail || "", link: "" + r.id })),
        hasNextPage: pg.last_page ? (pg.current_page || page) < pg.last_page : res.length >= 20,
      };
    }
    return this.filter(page, {
      sort: yhF(filters, "sort") || "latest",
      type: yhF(filters, "type") || "",
      status: yhF(filters, "status") || "",
      season: yhF(filters, "season") || "",
      year: yhF(filters, "year") || "",
      genre: yhF(filters, "genre") || "",
    });
  }
  async getDetail(url) {
    const id = ("" + url).match(/(\d+)(?:\.html)?\/?$/) ? ("" + url).match(/(\d+)(?:\.html)?\/?$/)[1] : url;
    const info = await this.json(`${this.api()}/anime/info/${id}`);
    const a = info.data || info;
    let episodes = [];
    try {
      const e = await this.json(`${this.api()}/anime/${id}/episodes`);
      const groups = e.groups || (e.data && e.data.groups) || [];
      for (const g of groups) {
        for (const ep of g.episodes || []) {
          episodes.push({
            name: (groups.length > 1 && g.name ? g.name + " – " : "") + (ep.title || ("Tập " + (ep.number || ep.sort_number || ""))),
            url: "" + ep.id,
            isFiller: ep.is_filler === true,
          });
        }
      }
    } catch (err) {
      if (!episodes.length) throw err;
    }
    episodes.reverse();
    const names = (arr) => (arr || []).map((x) => x.name || x.slug).filter(Boolean);
    return {
      name: a.title || a.name,
      imageUrl: a.poster || a.image || "",
      description: yhText(a.synopsis || a.description || "") +
        `\n\n${a.type || ""} • ${a.status || ""}${a.year ? " • " + a.year : ""}${a.season ? " • " + a.season : ""}`,
      author: names(a.studios).join(", "),
      genre: names(a.genres).concat(names(a.themes)),
      status: yhStatus(a.status),
      link: `${yhBase(this)}${a.link || "/phim/" + (a.slug || id)}`,
      episodes,
    };
  }
  async getVideoList(url) {
    const d = await this.json(`${this.api()}/anime/watch/episode/${url}`);
    const ep = d.data || d.episode || d;
    const streams = ep.streams || (ep.episode && ep.episode.streams) || [];
    const videos = [];
    streams.forEach((s, i) => {
      if (!s.url) return;
      const label = s.server_name || s.label || s.provider || `Server ${i + 1}`;
      const subs = (s.subtitles || []).map((t) => ({ file: t.file, label: t.label || "Phụ đề" }));
      if (s.player_type === "iframe" || !/\.m3u8|\.mp4/i.test(s.url)) {
        // embedded players (Google Drive, short links…) can't be played directly
        if (!/\.m3u8|\.mp4/i.test(s.url)) return;
      }
      videos.push({ url: s.url, originalUrl: s.url, quality: label, headers: { "Referer": yhBase(this) + "/", "User-Agent": YH_UA }, subtitles: subs });
    });
    return videos;
  }
  getFilterList() {
    return [
      yhHeader("Bộ lọc dùng khi ô tìm kiếm trống"),
      yhSelect("sort", "Sắp xếp", A47_SORT),
      yhSelect("genre", "Thể loại", A47_GENRES),
      yhSelect("type", "Loại", A47_TYPE),
      yhSelect("status", "Trạng thái", A47_STATUS),
      yhSelect("season", "Mùa", A47_SEASON),
      yhSelect("year", "Năm", A47_YEARS),
    ];
  }
  getSourcePreferences() {
    return [
      yhDomainPref("https://anime47.best"),
      { key: "yh_api", editTextPreference: { title: "Địa chỉ API", summary: "Mặc định https://anime47.love/api", value: "https://anime47.love/api", dialogTitle: "API", dialogMessage: "", text: "https://anime47.love/api" } },
      { key: "a47_email", editTextPreference: { title: "Email Anime47", summary: "Cần để xem tập phim", value: "", dialogTitle: "Email", dialogMessage: "", text: "" } },
      { key: "a47_password", editTextPreference: { title: "Mật khẩu Anime47", summary: "Chỉ lưu trên máy này", value: "", dialogTitle: "Mật khẩu", dialogMessage: "", text: "" } },
    ];
  }
}
