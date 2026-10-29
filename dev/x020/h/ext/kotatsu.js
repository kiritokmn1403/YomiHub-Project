// Kotatsu Multi Parsers – nguồn được YomiHub tạo tự động.
// Mã phân tích trang chạy trong thư viện kotatsu-parsers (Kotlin) nhúng sẵn
// trong YomiHub; tiện ích này chỉ gọi cầu nối nội bộ http://127.0.0.1:47350.
// Các hằng KT_ID / KT_FILTERS được chèn khi cài đặt.
const KT_HOST = "http://127.0.0.1:47350/kotatsu";

class DefaultExtension extends MProvider {
  constructor() { super(); this.client = new Client(); }
  get supportsLatest() { return true; }
  getHeaders(url) { return {}; }
  async call(path, params) {
    const q = Object.assign({ source: KT_ID }, params || {});
    const qs = Object.keys(q).map((k) => k + "=" + encodeURIComponent(q[k])).join("&");
    let res;
    try {
      res = await this.client.get(`${KT_HOST}/${path}?${qs}`);
    } catch (e) {
      throw new Error("Cầu nối Kotatsu chưa chạy. Mở YomiHub > Duyệt > Extensions Repo > Kotatsu một lần rồi thử lại. (" + e + ")");
    }
    const j = JSON.parse(res.body || "{}");
    if (j && j.cloudflare) throw new Error("Failed to bypass Cloudflare.\n\nMở WebView của nguồn để vượt Cloudflare thủ công rồi thử lại.\n\nstatusCode: 403\n" + (j.url || ""));
    if (j && j.error && !Array.isArray(j)) throw new Error("Kotatsu: " + j.error);
    return j;
  }
  toPage(j) {
    return {
      list: (j.list || []).map((m) => ({ name: m.name, imageUrl: m.imageUrl, link: m.link })),
      hasNextPage: !!j.hasNextPage,
    };
  }
  async getPopular(page) { return this.toPage(await this.call("list", { kind: "popular", page })); }
  async getLatestUpdates(page) { return this.toPage(await this.call("list", { kind: "latest", page })); }
  async search(query, page, filters) {
    // YomiHub 0.1.9: Kotatsu's own filter model (same options as the filter
    // sheet of the Kotatsu app): tags (+exclude), states, content rating,
    // content type, demographic, language, original language, year, author.
    const F = KT_FILTERS || {};
    const f = {};
    const tags = [], exclude = [], states = [], ratings = [], types = [], demos = [];
    for (const g of filters || []) {
      if (g.type_name === "SelectFilter") {
        const v = (g.values || [])[g.state];
        if (!v || !v.value) continue;
        if (g.type === "sort") f.sort = v.value;
        else if (g.type === "locale") f.locale = v.value;
        else if (g.type === "originalLocale") f.originalLocale = v.value;
      } else if (g.type_name === "TextFilter") {
        const t = (g.state || "").trim();
        if (!t) continue;
        if (g.type === "year" || g.type === "yearFrom" || g.type === "yearTo") {
          const y = parseInt(t, 10);
          if (y > 1900 && y < 2100) f[g.type] = y;
        } else if (g.type === "author") f.author = t;
      } else if (g.type_name === "GroupFilter") {
        for (const c of g.state || []) {
          const on = c.type_name === "TriState" ? c.state : (c.state === true ? 1 : 0);
          if (!on) continue;
          if (g.type === "tags") (on === 2 ? exclude : tags).push(JSON.parse(c.value));
          else if (g.type === "states") states.push(c.value);
          else if (g.type === "ratings") ratings.push(c.value);
          else if (g.type === "types") types.push(c.value);
          else if (g.type === "demographics") demos.push(c.value);
        }
      }
    }
    if (tags.length) f.tags = F.multiTag === false ? tags.slice(0, 1) : tags;
    if (exclude.length && F.excludeTag) f.exclude = exclude;
    if (states.length) f.states = states;
    if (ratings.length) f.ratings = ratings;
    if (types.length) f.types = types;
    if (demos.length) f.demographics = demos;
    const hasFilter = Object.keys(f).some((k) => k !== "sort");
    const params = { kind: query ? "search" : "popular", page, filter: JSON.stringify(f) };
    // a parser that can't combine search + filters gets the query alone
    if (query && (!hasFilter || F.searchWithFilters !== false)) params.query = query;
    else if (query && !hasFilter) params.query = query;
    else if (query) params.query = query, params.filter = JSON.stringify(f.sort ? { sort: f.sort } : {});
    return this.toPage(await this.call("list", params));
  }
  async getDetail(url) {
    const d = await this.call("details", { url });
    return {
      name: d.name,
      imageUrl: d.imageUrl,
      description: d.description,
      author: d.author,
      status: d.status,
      genre: d.genre || [],
      link: url,
      chapters: (d.chapters || []).map((c) => ({ name: c.name, url: c.url, dateUpload: c.dateUpload, scanlator: c.scanlator })),
    };
  }
  async getPageList(url) {
    const pages = await this.call("pages", { url });
    return Array.isArray(pages) ? pages : [];
  }
  getFilterList() {
    const out = [];
    const F = KT_FILTERS || {};
    const VI = (typeof KT_LANG === "undefined" ? "vi" : KT_LANG) === "vi";
    const L = (vi, en) => (VI ? vi : en);
    const SORT_VI = { UPDATED: "Mới cập nhật", POPULARITY: "Phổ biến", RATING: "Đánh giá", NEWEST: "Mới nhất", ALPHABETICAL: "A-Z", ALPHABETICAL_DESC: "Z-A", RELEVANCE: "Liên quan", POPULARITY_ASC: "Ít phổ biến", RATING_ASC: "Đánh giá thấp", NEWEST_ASC: "Cũ nhất", UPDATED_ASC: "Cập nhật cũ", POPULARITY_TODAY: "Hôm nay", POPULARITY_WEEK: "Tuần này", POPULARITY_MONTH: "Tháng này", POPULARITY_YEAR: "Năm nay", ADDED: "Mới thêm", ADDED_ASC: "Thêm cũ" };
    if ((F.sort || []).length) {
      out.push({ type_name: "SelectFilter", type: "sort", name: L("Sắp xếp", "Sort by"), state: 0,
        values: [{ type_name: "SelectOption", name: L("Mặc định", "Default"), value: "" }].concat(F.sort.map((s) => ({ type_name: "SelectOption", name: (VI ? (SORT_VI[s] || s) : s.charAt(0) + s.slice(1).toLowerCase().replace(/_/g, " ")), value: s }))) });
    }
    if ((F.tags || []).length) {
      out.push({ type_name: "GroupFilter", type: "tags", name: L("Thể loại", "Genres"),
        state: F.tags.map((t) => F.excludeTag
          ? { type_name: "TriState", type: "tags", name: t.title, value: JSON.stringify(t), state: 0 }
          : { type_name: "CheckBox", type: "tags", name: t.title, value: JSON.stringify(t), state: false }) });
    }
    const ST = { ONGOING: "Đang tiến hành", FINISHED: "Hoàn thành", ABANDONED: "Bỏ dở", PAUSED: "Tạm ngưng", UPCOMING: "Sắp ra", RESTRICTED: "Hạn chế" };
    if ((F.states || []).length) {
      out.push({ type_name: "GroupFilter", type: "states", name: L("Tình trạng", "State"),
        state: F.states.map((s) => ({ type_name: "CheckBox", type: "states", name: (VI ? (ST[s] || s) : s.charAt(0) + s.slice(1).toLowerCase()), value: s, state: false })) });
    }
    const RT = { SAFE: "An toàn", SUGGESTIVE: "Gợi cảm", ADULT: "18+" };
    if ((F.ratings || []).length) {
      out.push({ type_name: "GroupFilter", type: "ratings", name: L("Phân loại nội dung", "Content rating"),
        state: F.ratings.map((s) => ({ type_name: "CheckBox", type: "ratings", name: (VI ? (RT[s] || s) : s.charAt(0) + s.slice(1).toLowerCase()), value: s, state: false })) });
    }
    const TY = { MANGA: "Manga", MANHWA: "Manhwa", MANHUA: "Manhua", COMICS: "Comics", HENTAI: "Hentai", ONE_SHOT: "Oneshot", DOUJINSHI: "Doujinshi", IMAGE_SET: "Bộ ảnh", ARTIST_CG: "Artist CG", GAME_CG: "Game CG", NOVEL: "Novel", OTHER: "Khác" };
    if ((F.types || []).length) {
      out.push({ type_name: "GroupFilter", type: "types", name: L("Loại", "Type"),
        state: F.types.map((s) => ({ type_name: "CheckBox", type: "types", name: (VI ? (TY[s] || s) : s.charAt(0) + s.slice(1).toLowerCase().replace(/_/g, " ")), value: s, state: false })) });
    }
    const DM = { SHOUNEN: "Shounen", SHOUJO: "Shoujo", SEINEN: "Seinen", JOSEI: "Josei", KODOMO: "Kodomo", NONE: "Không" };
    if ((F.demographics || []).length) {
      out.push({ type_name: "GroupFilter", type: "demographics", name: L("Đối tượng", "Demographic"),
        state: F.demographics.map((s) => ({ type_name: "CheckBox", type: "demographics", name: (VI ? (DM[s] || s) : s.charAt(0) + s.slice(1).toLowerCase()), value: s, state: false })) });
    }
    if ((F.locales || []).length) {
      const opts = [{ type_name: "SelectOption", name: L("Tất cả", "All"), value: "" }].concat(F.locales.map((l) => ({ type_name: "SelectOption", name: l.title, value: l.key })));
      out.push({ type_name: "SelectFilter", type: "locale", name: L("Ngôn ngữ", "Language"), state: 0, values: opts });
      if (F.originalLocale) out.push({ type_name: "SelectFilter", type: "originalLocale", name: L("Ngôn ngữ gốc", "Original language"), state: 0, values: opts });
    }
    if (F.yearRange) {
      out.push({ type_name: "TextFilter", type: "yearFrom", name: L("Từ năm", "Year from"), state: "" });
      out.push({ type_name: "TextFilter", type: "yearTo", name: L("Đến năm", "Year to"), state: "" });
    } else if (F.year) {
      out.push({ type_name: "TextFilter", type: "year", name: L("Năm", "Year"), state: "" });
    }
    if (F.author) out.push({ type_name: "TextFilter", type: "author", name: L("Tác giả", "Author"), state: "" });
    return out;
  }
  getSourcePreferences() { return []; }
}
