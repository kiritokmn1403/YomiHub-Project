// RoPhim (rophimhd.com) – phim Việt sub / thuyết minh. Dữ liệu lấy từ API phimapi.com
// mà chính trang RoPhim dùng. Bundled with YomiHub.
const RP_TYPES = [["Tất cả",""],["Phim bộ","phim-bo"],["Phim lẻ","phim-le"],["TV Shows","tv-shows"],["Hoạt hình","hoat-hinh"],["Phim Vietsub","phim-vietsub"],["Phim thuyết minh","phim-thuyet-minh"],["Phim lồng tiếng","phim-long-tieng"]];
const RP_GENRES = [["Tất cả",""],["Hành Động","hanh-dong"],["Miền Tây","mien-tay"],["Trẻ Em","tre-em"],["Lịch Sử","lich-su"],["Cổ Trang","co-trang"],["Chiến Tranh","chien-tranh"],["Viễn Tưởng","vien-tuong"],["Kinh Dị","kinh-di"],["Tài Liệu","tai-lieu"],["Bí Ẩn","bi-an"],["Phim 18+","phim-18"],["Tình Cảm","tinh-cam"],["Tâm Lý","tam-ly"],["Thể Thao","the-thao"],["Phiêu Lưu","phieu-luu"],["Âm Nhạc","am-nhac"],["Gia Đình","gia-dinh"],["Học Đường","hoc-duong"],["Hài Hước","hai-huoc"],["Võ Thuật","vo-thuat"],["Khoa Học","khoa-hoc"],["Thần Thoại","than-thoai"],["Chính Kịch","chinh-kich"],["Kinh Điển","kinh-dien"]];
const RP_COUNTRIES = [["Tất cả",""],["Việt Nam","viet-nam"],["Trung Quốc","trung-quoc"],["Hàn Quốc","han-quoc"],["Nhật Bản","nhat-ban"],["Thái Lan","thai-lan"],["Âu Mỹ","au-my"],["Đài Loan","dai-loan"],["Hồng Kông","hong-kong"],["Ấn Độ","an-do"],["Anh","anh"],["Pháp","phap"],["Canada","canada"],["Đức","duc"],["Tây Ban Nha","tay-ban-nha"],["Thổ Nhĩ Kỳ","tho-nhi-ky"],["Hà Lan","ha-lan"],["Indonesia","indonesia"],["Nga","nga"],["Mexico","mexico"],["Ba Lan","ba-lan"],["Úc","uc"],["Thụy Điển","thuy-dien"],["Malaysia","malaysia"],["Brazil","brazil"],["Philippines","philippines"],["Bồ Đào Nha","bo-dao-nha"],["Ý","y"],["Đan Mạch","dan-mach"],["UAE","uae"],["Na Uy","na-uy"],["Thụy Sĩ","thuy-si"],["Châu Phi","chau-phi"],["Nam Phi","nam-phi"],["Ukraina","ukraina"],["Ả Rập Xê Út","a-rap-xe-ut"],["Quốc Gia Khác","quoc-gia-khac"]];
const RP_SORT = [["Mới cập nhật","modified.time"],["Năm phát hành","year"],["Mới thêm","_id"]];
const RP_LANG = [["Tất cả",""],["Vietsub","vietsub"],["Thuyết minh","thuyet-minh"],["Lồng tiếng","long-tieng"]];
const RP_YEARS = [["Tất cả",""]].concat(Array.from({ length: 40 }, (_, i) => { const y = "" + (new Date().getFullYear() - i); return [y, y]; }));

class DefaultExtension extends MProvider {
  constructor() { super(); this.client = new Client(); }
  get supportsLatest() { return true; }
  api() { return ("" + yhPref("yh_api", "https://phimapi.com")).replace(/\/+$/, ""); }
  cdn() { return ("" + yhPref("yh_cdn", "https://phimimg.com")).replace(/\/+$/, ""); }
  getHeaders(url) { return { "User-Agent": YH_UA, "Referer": yhBase(this) + "/" }; }
  async json(url) {
    const res = await this.client.get(url, this.getHeaders(url));
    if (res.statusCode >= 400) throw new Error("HTTP " + res.statusCode + " – " + url);
    return JSON.parse(res.body);
  }
  img(u) { return !u ? "" : (/^https?:/i.test(u) ? u : this.cdn() + "/" + u.replace(/^\/+/, "")); }
  toList(items) {
    return (items || []).map((m) => ({
      name: m.name + (m.episode_current ? ` (${m.episode_current})` : ""),
      imageUrl: this.img(m.poster_url || m.thumb_url),
      link: m.slug,
    }));
  }
  page(d) {
    const data = d.data || d;
    const p = (data.params && data.params.pagination) || data.pagination || {};
    return { list: this.toList(data.items), hasNextPage: (p.currentPage || 1) < (p.totalPages || 1) };
  }
  async getPopular(page) {
    return this.page(await this.json(`${this.api()}/v1/api/danh-sach/phim-bo?page=${page}&limit=24&sort_field=year&sort_type=desc`));
  }
  async getLatestUpdates(page) {
    return this.page(await this.json(`${this.api()}/danh-sach/phim-moi-cap-nhat?page=${page}`));
  }
  async search(query, page, filters) {
    const sortField = yhF(filters, "sort") || "modified.time";
    const common = `page=${page}&limit=24&sort_field=${sortField}&sort_type=desc`;
    const lang = yhF(filters, "lang") || "";
    const extra = lang ? `&sort_lang=${lang}` : "";
    if (query && query.trim()) {
      return this.page(await this.json(`${this.api()}/v1/api/tim-kiem?keyword=${encodeURIComponent(query.trim())}&${common}${extra}`));
    }
    const type = yhF(filters, "type") || "";
    const genre = yhF(filters, "genre") || "";
    const country = yhF(filters, "country") || "";
    const year = yhF(filters, "year") || "";
    const q = `${common}${extra}${genre ? "&category=" + genre : ""}${country ? "&country=" + country : ""}${year ? "&year=" + year : ""}`;
    let path;
    if (type) path = `/v1/api/danh-sach/${type}`;
    else if (genre) path = `/v1/api/the-loai/${genre}`;
    else if (country) path = `/v1/api/quoc-gia/${country}`;
    else if (year) path = `/v1/api/nam/${year}`;
    else return this.getLatestUpdates(page);
    return this.page(await this.json(`${this.api()}${path}?${q}`));
  }
  async getDetail(url) {
    const slug = url.replace(/^.*\/phim\//, "").replace(/[/?#].*$/, "");
    const d = await this.json(`${this.api()}/phim/${slug}`);
    const m = d.movie || {};
    const eps = new Map();
    for (const sv of d.episodes || []) {
      for (const e of sv.server_data || []) {
        if (!e.link_m3u8 && !e.link_embed) continue;
        const key = e.slug || e.name;
        if (!eps.has(key)) eps.set(key, e.name);
      }
    }
    const episodes = [...eps.entries()].map(([k, n]) => ({
      name: /^\d+$/.test(n) ? "Tập " + n : n,
      url: slug + "|" + k,
    }));
    episodes.reverse();
    const info = [
      m.origin_name ? "Tên gốc: " + m.origin_name : "",
      m.year ? "Năm: " + m.year : "",
      m.time ? "Thời lượng: " + m.time : "",
      m.quality ? "Chất lượng: " + m.quality + (m.lang ? " • " + m.lang : "") : "",
      (m.country || []).length ? "Quốc gia: " + m.country.map((c) => c.name).join(", ") : "",
      (m.actor || []).filter((a) => a && a !== "Đang cập nhật").length ? "Diễn viên: " + m.actor.join(", ") : "",
    ].filter(Boolean).join("\n");
    return {
      name: m.name,
      imageUrl: this.img(m.poster_url || m.thumb_url),
      description: yhText((m.content || "").replace(/<[^>]+>/g, " ")) + (info ? "\n\n" + info : ""),
      author: (m.director || []).filter((x) => x && x !== "Đang cập nhật").join(", "),
      genre: (m.category || []).map((c) => c.name),
      status: m.status === "completed" ? 1 : (m.status === "ongoing" ? 0 : 5),
      link: `${yhBase(this)}/phim/${slug}`,
      episodes,
    };
  }
  async getVideoList(url) {
    const [slug, key] = url.split("|");
    const d = await this.json(`${this.api()}/phim/${slug}`);
    const videos = [];
    for (const sv of d.episodes || []) {
      for (const e of sv.server_data || []) {
        if ((e.slug || e.name) !== key || !e.link_m3u8) continue;
        videos.push({ url: e.link_m3u8, originalUrl: e.link_m3u8, quality: sv.server_name || "HLS", headers: this.getHeaders(e.link_m3u8) });
      }
    }
    return videos;
  }
  getFilterList() {
    return [
      yhHeader("Bộ lọc dùng khi ô tìm kiếm trống (trừ Sắp xếp và Ngôn ngữ)"),
      yhSelect("type", "Danh sách", RP_TYPES),
      yhSelect("genre", "Thể loại", RP_GENRES),
      yhSelect("country", "Quốc gia", RP_COUNTRIES),
      yhSelect("year", "Năm", RP_YEARS),
      yhSelect("sort", "Sắp xếp", RP_SORT),
      yhSelect("lang", "Ngôn ngữ", RP_LANG),
    ];
  }
  getSourcePreferences() {
    return [
      yhDomainPref("https://www.rophimhd.com"),
      { key: "yh_api", editTextPreference: { title: "Máy chủ dữ liệu (API)", summary: "Mặc định https://phimapi.com", value: "https://phimapi.com", dialogTitle: "API", dialogMessage: "", text: "https://phimapi.com" } },
      { key: "yh_cdn", editTextPreference: { title: "Máy chủ ảnh", summary: "Mặc định https://phimimg.com", value: "https://phimimg.com", dialogTitle: "Ảnh", dialogMessage: "", text: "https://phimimg.com" } },
    ];
  }
}
