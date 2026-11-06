import sys; sys.path.insert(0,'.')
from edit import edit
F='assets/yomihub_extensions/anime47.js'
edit(F,"""  async getDetail(url) {
    const id = ("" + url).match(/(\\d+)(?:\\.html)?\\/?$/) ? ("" + url).match(/(\\d+)(?:\\.html)?\\/?$/)[1] : url;""","""  // 0.5.2: entries refreshed once were stored with the detail link
  // "/phim/<slug>" (no id), and the old trailing-digits rule read
  // ".../tensei-shitara-slime-datta-ken-4th-season-1" as id 1 → HTTP 404
  // HTML (logs 2, 04/11 12:15). Ids now come from "/m<id>.html", a bare id,
  // or – for those old slug links – the search API (cached per slug).
  async resolveId(url) {
    const s = ("" + url).trim();
    let m = s.match(/\\/m(\\d+)\\.html/);
    if (m) return m[1];
    if (/^\\d+$/.test(s)) return s;
    const sm = s.match(/\\/phim\\/([^\\/?#]+)/);
    const slug = sm ? sm[1].replace(/\\.html$/, "") : "";
    if (slug) {
      const sp = new SharedPreferences();
      const ck = "a47_slug_" + slug;
      const cached = sp.getString(ck, "");
      if (cached) return cached;
      try {
        const kw = slug.replace(/-\\d+$/, "").replace(/-/g, " ");
        const d = await this.json(`${this.api()}/search/full/?keyword=${encodeURIComponent(kw)}&page=1`);
        const arr = d.results || (d.data && (d.data.posts || d.data.results)) || [];
        const hit = arr.find((r) => {
          const l = "" + (r.link || "");
          return r.slug === slug || l.includes("/phim/" + slug + "/") || l.endsWith("/phim/" + slug) || l.endsWith("/phim/" + slug + "-" + r.id);
        });
        if (hit && hit.id) { sp.setString(ck, "" + hit.id); return "" + hit.id; }
      } catch (e) {}
      m = slug.match(/-(\\d{3,})$/); // list API link "/phim/<slug>-<id>"
      if (m) return m[1];
    }
    m = s.match(/(\\d+)(?:\\.html)?\\/?$/);
    if (m) return m[1];
    throw new Error("Anime47: không tìm được mã phim cho \\"" + s + "\\" – mở lại phim từ Duyệt/Tìm kiếm.");
  }
  async getDetail(url) {
    const id = await this.resolveId(url);""")
edit(F,"""      link: `${yhBase(this)}${a.link || "/phim/" + (a.slug || id)}`,""","""      link: `${yhBase(this)}/phim/${a.slug || "anime"}/m${id}.html`,""")
F2='lib/yomihub/extensions/builtin_extensions.dart'
edit(F2,"""      asset: 'anime47.js',
      baseUrl: 'https://anime47.best',
      itemType: ItemType.anime,
      version: '0.1.4',""","""      asset: 'anime47.js',
      baseUrl: 'https://anime47.best',
      itemType: ItemType.anime,
      version: '0.5.2',""")
