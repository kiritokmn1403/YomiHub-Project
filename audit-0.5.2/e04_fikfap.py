import sys; sys.path.insert(0,'.')
from edit import edit
F='assets/yomihub_extensions/fikfap.js'
edit(F,"""  async getDetail(url) {
    const o = JSON.parse(url);
    const res = await this.client.get(`${this.api()}/posts/${o.id}`, this.getHeaders());
    const p = JSON.parse(res.body);""","""  // 0.5.2: the app stores the detail `link` (https://fikfap.com/post/<id>) as
  // the entry's URL, so the next library update called JSON.parse on a URL:
  // "SyntaxError: unexpected token: 'https'" (logs 2, 04/11 09:48:58).
  // Accept the JSON link, a /post/<id> URL or a bare id.
  postId(url) {
    const s = ("" + (url || "")).trim();
    if (s.startsWith("{")) { try { return "" + JSON.parse(s).id; } catch (e) { } }
    const m = s.match(/\\/post\\/(\\d+)/) || s.match(/^(\\d+)$/);
    if (m) return m[1];
    throw new Error("FikFap: không nhận ra mã video trong \\"" + s + "\\"");
  }
  async getDetail(url) {
    const o = { id: this.postId(url) };
    const p = await this.getJsonAny(`/posts/${o.id}`);""")
edit(F,"""    if (("" + url).startsWith("{")) url = "" + JSON.parse(url).id;
    const res = await this.client.get(`${this.api()}/posts/${url}`, this.getHeaders());
    const p = JSON.parse(res.body);""","""    url = this.postId(url);
    const p = await this.getJsonAny(`/posts/${url}`);""")
F2='lib/yomihub/extensions/builtin_extensions.dart'
edit(F2,"""      asset: 'fikfap.js',
      baseUrl: 'https://fikfap.com',
      itemType: ItemType.anime,
      version: '0.4.3',""","""      asset: 'fikfap.js',
      baseUrl: 'https://fikfap.com',
      itemType: ItemType.anime,
      version: '0.5.2',""")
