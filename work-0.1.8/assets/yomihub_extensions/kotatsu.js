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
    const f = {};
    const tags = [], exclude = [], states = [], ratings = [];
    for (const g of filters || []) {
      if (g.type === "sort" && g.type_name === "SelectFilter") {
        const v = g.values[g.state];
        if (v && v.value) f.sort = v.value;
      } else if (g.type_name === "GroupFilter") {
        for (const c of g.state || []) {
          const on = c.type_name === "TriState" ? c.state : (c.state === true ? 1 : 0);
          if (!on) continue;
          if (g.type === "tags") (on === 2 ? exclude : tags).push(JSON.parse(c.value));
          else if (g.type === "states") states.push(c.value);
          else if (g.type === "ratings") ratings.push(c.value);
        }
      }
    }
    if (tags.length) f.tags = tags;
    if (exclude.length) f.exclude = exclude;
    if (states.length) f.states = states;
    if (ratings.length) f.ratings = ratings;
    const params = { kind: query ? "search" : "popular", page, filter: JSON.stringify(f) };
    if (query) params.query = query;
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
    const SORT_VI = { UPDATED: "Mới cập nhật", POPULARITY: "Phổ biến", RATING: "Đánh giá", NEWEST: "Mới nhất", ALPHABETICAL: "A-Z", ALPHABETICAL_DESC: "Z-A", RELEVANCE: "Liên quan", POPULARITY_ASC: "Ít phổ biến", RATING_ASC: "Đánh giá thấp", NEWEST_ASC: "Cũ nhất", UPDATED_ASC: "Cập nhật cũ", POPULARITY_TODAY: "Hôm nay", POPULARITY_WEEK: "Tuần này", POPULARITY_MONTH: "Tháng này", POPULARITY_YEAR: "Năm nay", ADDED: "Mới thêm", ADDED_ASC: "Thêm cũ" };
    if ((F.sort || []).length) {
      out.push({ type_name: "SelectFilter", type: "sort", name: "Sắp xếp", state: 0,
        values: [{ type_name: "SelectOption", name: "Mặc định", value: "" }].concat(F.sort.map((s) => ({ type_name: "SelectOption", name: SORT_VI[s] || s, value: s }))) });
    }
    if ((F.tags || []).length) {
      out.push({ type_name: "GroupFilter", type: "tags", name: "Thể loại",
        state: F.tags.map((t) => F.excludeTag
          ? { type_name: "TriState", type: "tags", name: t.title, value: JSON.stringify(t), state: 0 }
          : { type_name: "CheckBox", type: "tags", name: t.title, value: JSON.stringify(t), state: false }) });
    }
    const ST = { ONGOING: "Đang tiến hành", FINISHED: "Hoàn thành", ABANDONED: "Bỏ dở", PAUSED: "Tạm ngưng", UPCOMING: "Sắp ra", RESTRICTED: "Hạn chế" };
    if ((F.states || []).length) {
      out.push({ type_name: "GroupFilter", type: "states", name: "Tình trạng",
        state: F.states.map((s) => ({ type_name: "CheckBox", type: "states", name: ST[s] || s, value: s, state: false })) });
    }
    const RT = { SAFE: "An toàn", SUGGESTIVE: "Gợi cảm", ADULT: "18+" };
    if ((F.ratings || []).length) {
      out.push({ type_name: "GroupFilter", type: "ratings", name: "Phân loại nội dung",
        state: F.ratings.map((s) => ({ type_name: "CheckBox", type: "ratings", name: RT[s] || s, value: s, state: false })) });
    }
    return out;
  }
  getSourcePreferences() { return []; }
}
