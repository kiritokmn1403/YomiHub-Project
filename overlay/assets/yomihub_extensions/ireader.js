// IReader – nguồn được YomiHub tạo tự động từ tiện ích APK của IReader.
// Mã của nguồn chạy trong thư viện source-api của IReader (Kotlin) nhúng sẵn
// trong YomiHub; tiện ích này chỉ gọi cầu nối nội bộ http://127.0.0.1:47360.
// Các hằng IR_ID / IR_FILTERS được chèn khi cài đặt.
const IR_HOST = "http://127.0.0.1:47360/ireader";

class DefaultExtension extends MProvider {
  constructor() { super(); this.client = new Client(); this._filters = null; }
  get supportsLatest() { return true; }
  getHeaders(url) { return {}; }
  async call(path, params) {
    const q = Object.assign({ source: IR_ID }, params || {});
    const qs = Object.keys(q).map((k) => k + "=" + encodeURIComponent(q[k])).join("&");
    let res;
    try {
      res = await this.client.get(`${IR_HOST}/${path}?${qs}`);
    } catch (e) {
      throw new Error("Cầu nối IReader chưa chạy. Mở lại YomiHub rồi thử lại. (" + e + ")");
    }
    const j = JSON.parse(res.body || "{}");
    if (j && j.error && !Array.isArray(j)) throw new Error("IReader: " + j.error);
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
  // Mangayomi filter list → IReader filter values (same order as /filters)
  toIReader(f) {
    if (f.type_name === "TextFilter") return { value: f.state || "" };
    if (f.type_name === "SelectFilter") return { value: f.state || 0 };
    if (f.type_name === "TriState") return { value: f.state === 1 ? 1 : (f.state === 2 ? 2 : 0) };
    if (f.type_name === "CheckBox") return { value: f.state ? 1 : 0 };
    if (f.type_name === "SortFilter") return { index: (f.state || {}).index || 0, ascending: !!(f.state || {}).ascending };
    if (f.type_name === "GroupFilter") return { filters: (f.state || []).map((c) => this.toIReader(c)) };
    return {};
  }
  async search(query, page, filters) {
    // same order and length as IR_FILTERS (notes included), applied by index
    const params = { kind: "search", page, filters: JSON.stringify((filters || []).map((f) => this.toIReader(f))) };
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
      artist: d.artist,
      status: d.status,
      genre: d.genre || [],
      link: url,
      chapters: (d.chapters || []).map((c) => ({ name: c.name, url: c.url, dateUpload: c.dateUpload, scanlator: c.scanlator })),
    };
  }
  async getHtmlContent(name, url) {
    const c = await this.call("content", { url, name });
    let html = c.html || "";
    for (const img of c.images || []) html += `<p><img src="${img}"></p>\n`;
    return html;
  }
  async cleanHtmlContent(html) { return html; }
  async getPageList(url) {
    const c = await this.call("content", { url });
    return c.images || [];
  }
  convert(f) {
    switch (f.type) {
      case "text": return { type_name: "TextFilter", type: "ir_text", name: f.name, state: f.value || "" };
      case "select": return { type_name: "SelectFilter", type: "ir_select", name: f.name, state: f.value || 0,
        values: (f.options || []).map((o, i) => ({ type_name: "SelectOption", name: o, value: "" + i })) };
      case "sort": return { type_name: "SortFilter", type: "ir_sort", name: f.name, state: { type_name: "SortState", index: f.index || 0, ascending: !!f.ascending },
        values: (f.options || []).map((o, i) => ({ type_name: "SelectOption", name: o, value: "" + i })) };
      case "check": return f.tri
        ? { type_name: "TriState", type: "ir_tri", name: f.name, value: f.name, state: f.value || 0 }
        : { type_name: "CheckBox", type: "ir_check", name: f.name, value: f.name, state: f.value === 1 };
      case "group": return { type_name: "GroupFilter", type: "ir_group", name: f.name, state: (f.filters || []).map((c) => this.convert(c)) };
      default: return { type_name: "HeaderFilter", type: "ir_note", name: f.name };
    }
  }
  getFilterList() {
    return (typeof IR_FILTERS === "undefined" ? [] : IR_FILTERS).map((f) => this.convert(f));
  }
  getSourcePreferences() { return []; }
}
