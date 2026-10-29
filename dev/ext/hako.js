// Hako – light novel tiếng Việt. Bundled with YomiHub.
// Two official addresses: ln.hako.vn and docln.sbs (docln.net is an older
// mirror). In "auto" mode every request falls back to the next mirror when
// one is blocked (ln.hako.vn is often blocked by Vietnamese ISPs).
const HAKO_MIRRORS = ["https://ln.hako.vn", "https://docln.sbs", "https://docln.net"];
const HAKO_HOST_RE = /^https?:\/\/(?:www\.)?(?:ln\.hako\.vn|docln\.sbs|docln\.net|hako\.vn|hako\.vip)(?=\/|$)/i;
const HAKO_GENRES = [["Tất cả",""],["Action","action"],["Adapted to Anime","adapted-to-anime"],["Adapted to Drama CD","adapted-to-drama-cd"],["Adapted to Manga","adapted-to-manga"],["Adapted to Manhua","adapted-to-manhua"],["Adapted to Manhwa","adapted-to-manhwa"],["Adventure","adventure"],["Age Gap","age-gap"],["Boys Love","boys-love"],["Character Growth","character-growth"],["Chinese Novel","chinese-novel"],["Comedy","comedy"],["Cooking","cooking"],["Different Social Status","different-social-status"],["Drama","drama"],["Ecchi","ecchi"],["English Novel","english-novel"],["Fanfiction","fanfiction"],["Fantasy","fantasy"],["Female Protagonist","female-protagonist"],["Game","game"],["Gender Bender","gender-bender"],["Harem","harem"],["Historical","historical"],["Horror","horror"],["Isekai","isekai"],["Josei","josei"],["Korean Novel","korean-novel"],["Magic","magic"],["Martial Arts","martial-arts"],["Mecha","mecha"],["Military","military"],["Misunderstanding","misunderstanding"],["Mystery","mystery"],["Netorare","netorare"],["Obsession","obsession"],["One shot","one-shot"],["Otome Game","otome-game"],["Parody","parody"],["Psychological","psychological"],["Reverse Harem","reverse-harem"],["Romance","romance"],["Satire","satire"],["School Life","school-life"],["Science Fiction","science-fiction"],["Seinen","seinen"],["Shoujo","shoujo"],["Shoujo ai","shoujo-ai"],["Shounen","shounen"],["Shounen ai","shounen-ai"],["Slice of Life","slice-of-life"],["Slow Life","slow-life"],["Sports","sports"],["Super Power","super-power"],["Supernatural","supernatural"],["Suspense","suspense"],["Tragedy","tragedy"],["Wars","wars"],["Web Novel","web-novel"],["Workplace","workplace"],["Wuxia","wuxia"],["Xianxia","xianxia"],["Yandere","yandere"],["Yuri","yuri"]];
const HAKO_SORT = [["Cập nhật","capnhat"],["Truyện mới","truyenmoi"],["Theo dõi","theodoi"],["Top toàn thời gian","top"],["Top tháng","topthang"],["A-Z","tentruyen"],["Z-A","tentruyenza"]];
const HAKO_LETTERS = [["Tất cả",""],["#","khac"]].concat("abcdefghijklmnopqrstuvwxyz".split("").map((c) => [c.toUpperCase(), c]));

class DefaultExtension extends MProvider {
  constructor() {
    super();
    this.client = new Client();
  }
  get supportsLatest() { return true; }
  base() {
    const custom = ("" + yhPref("hako_custom", "")).trim();
    if (custom) return (/^https?:\/\//i.test(custom) ? custom : "https://" + custom).replace(/\/+$/, "");
    const sel = yhPref("hako_mirror", "auto");
    if (sel && sel !== "auto") return sel;
    if (this._live) return this._live;
    try {
      const saved = new SharedPreferences().getString("hako_live", "");
      if (saved && HAKO_MIRRORS.includes(saved)) return (this._live = saved);
    } catch (e) {}
    return HAKO_MIRRORS[0];
  }
  mirrors() {
    const b = this.base();
    const auto = !("" + yhPref("hako_custom", "")).trim() && (yhPref("hako_mirror", "auto") || "auto") === "auto";
    return auto ? [b].concat(HAKO_MIRRORS.filter((m) => m !== b)) : [b];
  }
  // Points any Hako/DocLN address at mirror [m] (links saved in the library
  // keep working whichever mirror they were added from).
  onMirror(url, m) {
    url = yhAbs(m, url);
    return HAKO_HOST_RE.test(url) ? url.replace(HAKO_HOST_RE, m) : url;
  }
  getHeaders(url) {
    return { "Referer": this.base() + "/", "User-Agent": YH_UA };
  }
  async page(url) {
    let lastErr = null;
    for (const m of this.mirrors()) {
      const u = this.onMirror(url, m);
      try {
        const res = await this.client.get(u, { "Referer": m + "/", "User-Agent": YH_UA });
        const body = res.body || "";
        const blocked = res.statusCode >= 500 || res.statusCode === 403 || res.statusCode === 0 ||
          /<title>\s*Just a moment/i.test(body) || body.length < 500;
        if (blocked && res.statusCode !== 404) { lastErr = new Error(m + ": HTTP " + res.statusCode); continue; }
        if (m !== this._live) {
          this._live = m;
          try { new SharedPreferences().setString("hako_live", m); } catch (e) {}
        }
        return new Document(body);
      } catch (e) { lastErr = e; }
    }
    throw lastErr || new Error("Không kết nối được Hako");
  }
  parseList(doc) {
    const list = [];
    for (const it of doc.select("div.thumb-item-flow")) {
      const a = it.selectFirst(".series-title a");
      if (!a) continue;
      const cover = it.selectFirst(".img-in-ratio");
      let img = cover ? (cover.attr("data-bg") || "") : "";
      if (!img && cover) {
        const m = (cover.attr("style") || "").match(/url\(['"]?([^'")]+)/);
        if (m) img = m[1];
      }
      list.push({ name: yhText(a.attr("title") || a.text), link: a.getHref, imageUrl: yhAbs(this.base(), img) });
    }
    const hasNextPage = doc.select("a.paging_item.next:not(.disabled), a.paging_prevnext.next:not(.disabled)").length > 0;
    return { list, hasNextPage };
  }
  listUrl(page, sort, extra) {
    let q = `truyendich=1&sangtac=1&dangtienhanh=1&tamngung=1&hoanthanh=1&sapxep=${sort}&page=${page}`;
    if (extra) q += "&" + extra;
    return `${this.base()}/danh-sach?${q}`;
  }
  async getPopular(page) { return this.parseList(await this.page(this.listUrl(page, "top"))); }
  async getLatestUpdates(page) { return this.parseList(await this.page(this.listUrl(page, "capnhat"))); }
  async search(query, page, filters) {
    if (query && query.trim().length >= 2) {
      return this.parseList(await this.page(`${this.base()}/tim-kiem?keywords=${encodeURIComponent(query.trim())}&page=${page}`));
    }
    const genre = yhF(filters, "genre") || "";
    const sort = yhF(filters, "sort") || "top";
    const letter = yhF(filters, "letter") || "";
    const types = yhF(filters, "type") || ["truyendich"];
    const status = yhF(filters, "status") || ["dangtienhanh", "tamngung", "hoanthanh"];
    const params = [...types, ...status].map((v) => `${v}=1`).concat([`sapxep=${sort}`, `page=${page}`]).join("&");
    let path = "/danh-sach";
    if (genre) path = `/the-loai/${genre}`;
    else if (letter) path = `/danh-sach/${letter}`;
    return this.parseList(await this.page(`${this.base()}${path}?${params}`));
  }
  async getDetail(url) {
    const doc = await this.page(url);
    const full = this.onMirror(url, this.base());
    const name = yhText((doc.selectFirst(".series-name a") || doc.selectFirst(".series-name") || {}).text);
    let imageUrl = "";
    const cov = doc.selectFirst(".series-cover .img-in-ratio");
    if (cov) {
      const m = (cov.attr("style") || "").match(/url\(['"]?([^'")]+)/);
      imageUrl = m ? m[1] : (cov.attr("data-bg") || "");
    }
    const genre = doc.select(".series-gernes a").map((e) => yhText(e.text));
    let author = "", artist = "", statusText = "";
    for (const it of doc.select(".info-item")) {
      const k = yhText((it.selectFirst(".info-name") || {}).text);
      const v = yhText((it.selectFirst(".info-value") || {}).text);
      if (/Tác giả/i.test(k)) author = v;
      else if (/Họa sĩ/i.test(k)) artist = v;
      else if (/Tình trạng/i.test(k)) statusText = v;
    }
    const sum = doc.selectFirst(".summary-content");
    const description = sum ? sum.select("p").map((p) => yhText(p.text)).join("\n") : "";
    const chapters = [];
    for (const vol of doc.select("section.volume-list")) {
      const volName = yhText((vol.selectFirst(".sect-title") || {}).text);
      for (const li of vol.select("ul.list-chapters li")) {
        const a = li.selectFirst(".chapter-name a");
        if (!a) continue;
        const time = yhText((li.selectFirst(".chapter-time") || {}).text);
        let dateUpload = null;
        const m = time.match(/(\d{1,2})\/(\d{1,2})\/(\d{4})/);
        if (m) dateUpload = "" + new Date(+m[3], +m[2] - 1, +m[1]).valueOf();
        chapters.push({ name: yhText(a.attr("title") || a.text), url: a.getHref, dateUpload, scanlator: volName });
      }
    }
    chapters.reverse();
    return { name, imageUrl, author, artist, genre, description, status: yhStatus(statusText), link: full, chapters };
  }
  async getHtmlContent(name, url) {
    let full = this.onMirror(url, this.base());
    const diag = [];
    let doc = null;
    try { doc = await this.page(full); full = this.onMirror(full, this.base()); } catch (e) { diag.push("tải trang: " + e); }
    const el = doc ? doc.selectFirst("#chapter-content") : null;
    const prot = doc ? doc.selectFirst("#chapter-c-protected") : null;
    if (doc && !el) diag.push("không thấy #chapter-content");
    let html = "";
    if (prot) {
      // Text is shipped as base64 chunks (optionally XOR-ed with data-k) and
      // decoded by the site's script; do the same here.
      try {
        html = hakoDecode(prot.attr("data-c"), prot.attr("data-s") || "none", prot.attr("data-k") || "");
        if (!html) diag.push("giải mã rỗng (" + (prot.attr("data-s") || "?") + ", " + String(prot.attr("data-c") || "").length + " ký tự)");
      } catch (e) { diag.push("giải mã: " + e); }
      if (html) {
        html = html.replace(/\[note(\d+)\]/gi, "<sup>[$1]</sup>");
        const notes = doc.select(".note-content").map((n) => yhText(n.text)).filter(Boolean);
        if (notes.length) html += "<hr/>" + notes.map((n, i) => `<p><small>[${i + 1}] ${n}</small></p>`).join("");
      }
    }
    if (!html && el) {
      html = el.innerHtml.replace(/<p[^>]*display:\s*none[^>]*>.*?<\/p>/gi, "");
    }
    if (!html || html.replace(/<[^>]+>/g, "").trim().length < 30) {
      // Last resort: let a hidden WebView render the chapter.
      const script = `(function(){var n=0;var t=setInterval(function(){n++;var el=document.querySelector('#chapter-content');
        var prot=document.querySelector('#chapter-c-protected');
        if((el&&!prot)||n>60){clearInterval(t);var c=el?el.cloneNode(true):null;
        if(c){c.querySelectorAll('script,style,noscript').forEach(function(e){e.remove();});}
        window.flutter_inappwebview.callHandler('setResponse', c?c.innerHTML:'');}},250);})();`;
      try {
        const w = await evaluateJavascriptViaWebview(full, this.getHeaders(full), [script]);
        if (w && w.length > html.length) html = w;
      } catch (e) { diag.push("WebView: " + e); }
    }
    if (!html || html.replace(/<[^>]+>/g, "").trim().length < 30) {
      html = `<p>Không đọc được chương này.</p><p><small>${diag.join(" · ") || "trang không có nội dung"}</small></p><p><small>${full}</small></p>`;
    }
    return html;
  }
  async cleanHtmlContent(html) { return html; }
  getFilterList() {
    return [
      yhHeader("Bộ lọc chỉ dùng khi ô tìm kiếm để trống"),
      yhSelect("genre", "Thể loại", HAKO_GENRES),
      yhSelect("sort", "Sắp xếp", HAKO_SORT),
      yhSelect("letter", "Chữ cái", HAKO_LETTERS),
      yhGroup("type", "Phân loại", [["Truyện dịch", "truyendich"], ["Truyện sáng tác", "sangtac"], ["Truyện AI dịch", "convert"]], ["truyendich"]),
      yhGroup("status", "Tình trạng", [["Đang tiến hành", "dangtienhanh"], ["Tạm ngưng", "tamngung"], ["Đã hoàn thành", "hoanthanh"], ["Chưa duyệt", "chuaduyet"]], ["dangtienhanh", "tamngung", "hoanthanh"]),
    ];
  }
  getSourcePreferences() {
    return [
      {
        key: "hako_mirror",
        listPreference: {
          title: "Máy chủ Hako",
          summary: "Tự động: thử ln.hako.vn rồi docln.sbs, docln.net khi trang bị chặn",
          valueIndex: 0,
          entries: ["Tự động (khuyên dùng)", "ln.hako.vn", "docln.sbs", "docln.net"],
          entryValues: ["auto", "https://ln.hako.vn", "https://docln.sbs", "https://docln.net"],
        },
      },
      {
        key: "hako_custom",
        editTextPreference: {
          title: "Tên miền riêng",
          summary: "Để trống để dùng mục Máy chủ Hako. Điền khi Hako chuyển sang địa chỉ mới",
          value: "",
          dialogTitle: "Tên miền riêng",
          dialogMessage: "Ví dụ: https://docln.sbs",
          text: "",
        },
      },
    ];
  }
}

function hakoB64(str) {
  const A = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
  const map = {};
  for (let i = 0; i < 64; i++) map[A[i]] = i;
  const clean = str.replace(/[^A-Za-z0-9+/]/g, "");
  const out = [];
  let buf = 0, bits = 0;
  for (let i = 0; i < clean.length; i++) {
    buf = (buf << 6) | map[clean[i]];
    bits += 6;
    if (bits >= 8) { bits -= 8; out.push((buf >> bits) & 0xff); }
  }
  return out;
}
function hakoUtf8(bytes) {
  let s = "", i = 0;
  while (i < bytes.length) {
    const c = bytes[i++];
    let cp;
    if (c < 0x80) cp = c;
    else if (c < 0xe0) cp = ((c & 0x1f) << 6) | (bytes[i++] & 0x3f);
    else if (c < 0xf0) cp = ((c & 0x0f) << 12) | ((bytes[i++] & 0x3f) << 6) | (bytes[i++] & 0x3f);
    else cp = ((c & 0x07) << 18) | ((bytes[i++] & 0x3f) << 12) | ((bytes[i++] & 0x3f) << 6) | (bytes[i++] & 0x3f);
    s += String.fromCodePoint(cp);
  }
  return s;
}
function hakoDecode(dataC, mode, key) {
  let arr = JSON.parse(dataC || "[]");
  if (!Array.isArray(arr) || !arr.length) return "";
  arr.sort((a, b) => parseInt(a.substring(0, 4), 10) - parseInt(b.substring(0, 4), 10));
  return arr.map((chunk) => {
    let s = chunk.substring(4);
    if (mode === "base64_reverse") s = s.split("").reverse().join("");
    let b = hakoB64(s);
    if (mode === "xor_shuffle" && key) b = b.map((x, i) => x ^ key.charCodeAt(i % key.length));
    return hakoUtf8(b);
  }).join("");
}
