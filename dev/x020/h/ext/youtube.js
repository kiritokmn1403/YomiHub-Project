// YouTube – NewPipe × Pure Tuber. Bundled with YomiHub.
// Không quảng cáo, không cần tài khoản Google: dùng InnerTube API như NewPipe.
// Hỗ trợ video, kênh, danh sách phát, phụ đề, chọn chất lượng và tải xuống.
const YT_SORT = [["Liên quan nhất", 0], ["Ngày tải lên", 2], ["Lượt xem", 3], ["Đánh giá", 1]];
const YT_TYPE = [["Tất cả", 0], ["Video", 1], ["Kênh", 2], ["Danh sách phát", 3], ["Phim", 4]];
const YT_DATE = [["Bất kỳ lúc nào", 0], ["1 giờ qua", 1], ["Hôm nay", 2], ["Tuần này", 3], ["Tháng này", 4], ["Năm nay", 5]];
const YT_DUR = [["Bất kỳ", 0], ["Dưới 4 phút", 1], ["4–20 phút", 3], ["Trên 20 phút", 2]];
const YT_FEAT = [["HD", 4], ["Phụ đề", 5], ["Trực tiếp", 8], ["4K", 14], ["HDR", 25], ["360°", 15]];
const YT_WEB = { clientName: "WEB", clientVersion: "2.20260930.00.00", hl: "vi", gl: "VN" };
const YT_VR = { clientName: "ANDROID_VR", clientVersion: "1.62.27", deviceMake: "Oculus", deviceModel: "Quest 3", androidSdkVersion: 32, osName: "Android", osVersion: "12L", hl: "vi", gl: "VN" };
const YT_VR_UA = "com.google.android.apps.youtube.vr.oculus/1.62.27 (Linux; U; Android 12L; eureka-user Build/SQ3A.220605.009.A1) gzip";
const YT_IOS = { clientName: "IOS", clientVersion: "20.10.4", deviceMake: "Apple", deviceModel: "iPhone16,2", osName: "iPhone", osVersion: "18.3.2.22D82", hl: "vi", gl: "VN" };
const YT_IOS_UA = "com.google.ios.youtube/20.10.4 (iPhone16,2; U; CPU iOS 18_3_2 like Mac OS X;)";
// YomiHub 0.1.9: ANDROID client as second choice – ANDROID_VR now often answers
// LOGIN_REQUIRED ("not a robot"); ANDROID still returns direct, range-able URLs
const YT_ANDROID = { clientName: "ANDROID", clientVersion: "20.10.38", androidSdkVersion: 30, osName: "Android", osVersion: "11", hl: "vi", gl: "VN" };
const YT_ANDROID_UA = "com.google.android.youtube/20.10.38 (Linux; U; Android 11) gzip";

function ytVarint(n) { const b = []; do { let x = n & 0x7f; n = Math.floor(n / 128); if (n) x |= 0x80; b.push(x); } while (n); return b; }
function ytB64(bytes) {
  const c = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
  let s = "";
  for (let i = 0; i < bytes.length; i += 3) {
    const n = (bytes[i] << 16) | ((bytes[i + 1] || 0) << 8) | (bytes[i + 2] || 0);
    s += c[(n >> 18) & 63] + c[(n >> 12) & 63] + (i + 1 < bytes.length ? c[(n >> 6) & 63] : "=") + (i + 2 < bytes.length ? c[n & 63] : "=");
  }
  return s;
}
// protobuf SearchParams { sort=1; filters=2 { date=1; type=2; duration=3; features… } }
function ytParams(sort, type, date, dur, feats) {
  const inner = [];
  if (date) inner.push(0x08, ...ytVarint(date));
  if (type) inner.push(0x10, ...ytVarint(type));
  if (dur) inner.push(0x18, ...ytVarint(dur));
  for (const f of feats || []) inner.push(...ytVarint(f << 3), 1);
  const out = [];
  if (sort) out.push(0x08, ...ytVarint(sort));
  if (inner.length) out.push(0x12, ...ytVarint(inner.length), ...inner);
  return out.length ? ytB64(out) : "";
}
function ytTxt(t) { if (!t) return ""; if (typeof t === "string") return t; if (t.simpleText) return t.simpleText; if (t.content) return t.content; if (t.runs) return t.runs.map((r) => r.text).join(""); return ""; }
function ytThumb(t) { const a = (t && (t.thumbnails || t.sources)) || []; return a.length ? a[a.length - 1].url.replace(/^\/\//, "https://") : ""; }

// PureTuber-style home tabs: Đặc sắc, Xu hướng, Âm nhạc, Trò chơi, Phim ảnh…
const YT_CATS = [["Đặc sắc (từ khóa trang chủ)", ""], ["Shorts", "shorts"], ["Xu hướng", "trend"], ["Âm nhạc", "UC-9-kyTW8ZkZNDHQJ6FgpwQ"], ["Trò chơi", "UCOpNcN46UbXVtpKMrmU4Abg"], ["Phim ảnh", "UClgRkhTL3_hImCAmdLfDE4g"], ["Tin tức", "UCYfdidRxbB8Qhf0Nx7ioOYw"], ["Thể thao", "UCEgdi0XIXXZ-qJOFPf4JSKw"], ["Học tập", "UCtFRv9O2AHqOZjjynzrv-xg"]];

class DefaultExtension extends MProvider {
  constructor() { super(); this.client = new Client(); }
  get supportsLatest() { return true; }
  getHeaders(url) { return { "User-Agent": YH_UA, "Referer": "https://www.youtube.com/" }; }
  async it(endpoint, body, client, ua) {
    const sp = new SharedPreferences();
    const visitor = sp.getString("yt_visitor", "");
    const cl = Object.assign({}, client || YT_WEB);
    const headers = { "Content-Type": "application/json", "User-Agent": ua || YH_UA, "X-Goog-Api-Format-Version": "2", "Origin": "https://www.youtube.com" };
    if (visitor && client) { cl.visitorData = visitor; headers["X-Goog-Visitor-Id"] = visitor; }
    const res = await this.client.post(`https://www.youtube.com/youtubei/v1/${endpoint}?prettyPrint=false`, headers,
      Object.assign({ context: { client: cl } }, body));
    const o = JSON.parse(res.body);
    const vd = o && o.responseContext && o.responseContext.visitorData;
    if (vd && !visitor) sp.setString("yt_visitor", vd);
    return o;
  }
  collect(o) {
    const items = [];
    let token = null;
    const seen = {};
    const add = (link, name, img, extra) => { if (!seen[link] && name) { seen[link] = 1; items.push({ name: name + (extra ? " · " + extra : ""), link, imageUrl: img }); } };
    const walk = (x) => {
      if (!x || typeof x !== "object") return;
      if (Array.isArray(x)) { x.forEach(walk); return; }
      if (x.videoRenderer || x.gridVideoRenderer || x.compactVideoRenderer) {
        const v = x.videoRenderer || x.gridVideoRenderer || x.compactVideoRenderer;
        add("v:" + v.videoId, ytTxt(v.title), ytThumb(v.thumbnail), [ytTxt(v.ownerText || v.shortBylineText), ytTxt(v.lengthText)].filter(Boolean).join(" · "));
        return;
      }
      if (x.playlistPanelVideoRenderer) { const v = x.playlistPanelVideoRenderer; add("v:" + v.videoId, ytTxt(v.title), ytThumb(v.thumbnail), [ytTxt(v.shortBylineText), ytTxt(v.lengthText)].filter(Boolean).join(" · ")); return; }
      if (x.playlistVideoRenderer) { const v = x.playlistVideoRenderer; add("v:" + v.videoId, ytTxt(v.title), ytThumb(v.thumbnail), ytTxt(v.lengthText)); return; }
      if (x.channelRenderer) { const c = x.channelRenderer; add("c:" + c.channelId, ytTxt(c.title), ytThumb(c.thumbnail), "Kênh"); return; }
      if (x.playlistRenderer) { const p = x.playlistRenderer; add("p:" + p.playlistId, ytTxt(p.title), ytThumb((p.thumbnails || [])[0]), "Danh sách phát"); return; }
      if (x.lockupViewModel) {
        const l = x.lockupViewModel;
        const md = ((l.metadata || {}).lockupMetadataViewModel) || {};
        const ci = l.contentImage || {};
        const img = ytThumb(((ci.thumbnailViewModel || (ci.collectionThumbnailViewModel || {}).primaryThumbnail || {}).thumbnailViewModel || ci.thumbnailViewModel || {}).image);
        const kind = l.contentType || "";
        const prefix = /PLAYLIST|PODCAST|ALBUM/.test(kind) ? "p:" : "v:";
        add(prefix + l.contentId, ytTxt(md.title), img, prefix === "p:" ? "Danh sách phát" : "");
        return;
      }
      if (x.reelItemRenderer) {
        const r = x.reelItemRenderer;
        if (r.videoId) add("v:" + r.videoId, ytTxt(r.headline), ytThumb(r.thumbnail), "Shorts");
        return;
      }
      if (x.shortsLockupViewModel) {
        const s = x.shortsLockupViewModel;
        const id = (((s.onTap || {}).innertubeCommand || {}).reelWatchEndpoint || {}).videoId;
        if (id) add("v:" + id, ytTxt((s.overlayMetadata || {}).primaryText), ytThumb((s.thumbnail || {})), "Shorts");
        return;
      }
      if (x.continuationCommand && x.continuationCommand.token) token = x.continuationCommand.token;
      for (const k in x) walk(x[k]);
    };
    walk(o);
    return { items, token };
  }
  tokKey(key, page) { return "yt_tok_" + key.replace(/[^a-zA-Z0-9]/g, "_").slice(0, 80) + "_" + page; }
  async paged(key, page, first, cont) {
    const sp = new SharedPreferences();
    let r;
    if (page <= 1) r = this.collect(await first());
    else {
      const tok = sp.getString(this.tokKey(key, page), "");
      if (!tok) return { list: [], hasNextPage: false };
      r = this.collect(await cont(tok));
    }
    if (r.token) sp.setString(this.tokKey(key, page + 1), r.token);
    return { list: r.items, hasNextPage: !!r.token };
  }
  async searchRaw(query, params, page) {
    const key = query + "|" + params;
    return this.paged(key, page,
      () => this.it("search", params ? { query, params } : { query }),
      (tok) => this.it("search", { continuation: tok }));
  }
  async category(cat, page) {
    // 0.1.8: Shorts feed (search filter type 9 = Shorts), used by Short Video
    if (cat === "shorts") {
      return this.searchRaw(yhPref("yt_shorts_kw", "#shorts"), ytParams(0, 9, 0, 0, []), page);
    }
    if (cat === "trend") {
      // FEtrending is gone for logged-out clients; use this week's most viewed.
      return this.searchRaw(yhPref("yt_trend_kw", "thịnh hành"), ytParams(3, 1, 3, 0, []), page);
    }
    return this.paged("cat_" + cat, page,
      () => this.it("browse", { browseId: cat }),
      (tok) => this.it("browse", { continuation: tok }));
  }
  async getPopular(page) {
    const cat = yhPref("yt_tab", "");
    if (cat) {
      const r = await this.category(cat, page);
      if (r.list.length || page > 1) return r;
    }
    const r = await this.paged("trending", page,
      () => this.it("browse", { browseId: "FEtrending" }),
      (tok) => this.it("browse", { continuation: tok }));
    if (page === 1 && r.list.length === 0) return this.searchRaw(yhPref("yt_home", "nhạc Việt mới"), ytParams(3, 1, 4, 0, []), page);
    return r;
  }
  async getLatestUpdates(page) {
    return this.searchRaw(yhPref("yt_home", "nhạc Việt mới"), ytParams(2, 1, 0, 0, []), page);
  }
  async search(query, page, filters) {
    query = (query || "").trim();
    const url = query.match(/(?:v=|youtu\.be\/|shorts\/|embed\/)([A-Za-z0-9_-]{11})/);
    if (url) return { list: [{ name: "Mở video " + url[1], link: "v:" + url[1], imageUrl: `https://i.ytimg.com/vi/${url[1]}/hqdefault.jpg` }], hasNextPage: false };
    const pl = query.match(/[?&]list=([A-Za-z0-9_-]+)/);
    if (pl) return { list: [{ name: "Mở danh sách phát", link: "p:" + pl[1], imageUrl: "" }], hasNextPage: false };
    const cat = yhF(filters, "cat") || "";
    if (!query && cat) return this.category(cat, page);
    const params = ytParams(+(yhF(filters, "sort") || 0), +(yhF(filters, "type") || 0), +(yhF(filters, "date") || 0), +(yhF(filters, "dur") || 0), (yhF(filters, "feat") || []).map(Number));
    return this.searchRaw(query || yhPref("yt_home", "nhạc Việt mới"), params, page);
  }
  // Return YouTube Dislike (as in NewPipe / Pure Tuber forks).
  async votes(id) {
    const on = yhPref("yt_dislike", true);
    if (on === false || on === "false") return "";
    try {
      const r = await this.client.get(`https://returnyoutubedislikeapi.com/votes?videoId=${id}`, { "User-Agent": YH_UA });
      const v = JSON.parse(r.body);
      if (v && v.likes !== undefined) return ` • 👍 ${v.likes} • 👎 ${v.dislikes}`;
    } catch (e) {}
    return "";
  }
  async player(id) {
    // a visitor id makes the bot check far less likely (same trick as NewPipe)
    if (!new SharedPreferences().getString("yt_visitor", "")) {
      try { await this.it("visitor_id", {}); } catch (e) {}
    }
    const body = { videoId: id, contentCheckOk: true, racyCheckOk: true };
    let last = null;
    for (const [c, ua] of [[YT_VR, YT_VR_UA], [YT_ANDROID, YT_ANDROID_UA], [YT_IOS, YT_IOS_UA]]) {
      try {
        const p = await this.it("player", body, c, ua);
        p._ua = ua;
        if (!last || (p.playabilityStatus || {}).status) last = p;
        const st = (p.playabilityStatus || {}).status;
        if (st === "OK" || st === "LIVE_STREAM_OFFLINE") return p;
      } catch (e) {}
    }
    return last || {};
  }
  async getDetail(url) {
    const [kind, id] = [url.slice(0, 1), url.slice(2)];
    if (kind === "v") {
      const p = await this.player(id);
      const vd = p.videoDetails || {};
      const mf = ((p.microformat || {}).playerMicroformatRenderer) || {};
      return {
        name: vd.title || id,
        imageUrl: `https://i.ytimg.com/vi/${id}/hqdefault.jpg`,
        author: vd.author || "",
        description: (vd.shortDescription || "") + `\n\n👁 ${vd.viewCount || "?"} lượt xem • ⏱ ${Math.round((+vd.lengthSeconds || 0) / 60)} phút${mf.publishDate ? " • " + mf.publishDate : ""}` + (await this.votes(id)),
        genre: (vd.keywords || []).slice(0, 12),
        status: 1,
        link: `https://www.youtube.com/watch?v=${id}`,
        episodes: [{ name: vd.title || "Video", url: id, dateUpload: mf.publishDate ? "" + Date.parse(mf.publishDate) : null }],
      };
    }
    let data, name = "", img = "", desc = "", link = "";
    if (kind === "c") {
      data = await this.it("browse", { browseId: id, params: "EgZ2aWRlb3PyBgQKAjoA" });
      const md = ((data.metadata || {}).channelMetadataRenderer) || {};
      name = md.title || id; img = ytThumb(md.avatar); desc = md.description || ""; link = `https://www.youtube.com/channel/${id}`;
    } else if (id.startsWith("RD")) {
      // YouTube Mix: not browsable, read it from the watch-next panel
      data = await this.it("next", { playlistId: id });
      const pl = ((((data.contents || {}).twoColumnWatchNextResults || {}).playlist || {}).playlist) || {};
      name = ytTxt(pl.title) || pl.title || "Mix"; desc = "Danh sách phát tự động (Mix)";
      link = `https://www.youtube.com/playlist?list=${id}`;
      data = pl.contents || [];
    } else {
      data = await this.it("browse", { browseId: id.startsWith("VL") ? id : "VL" + id });
      const al = (data.alerts || []).map((a) => ytTxt((a.alertRenderer || {}).text)).filter(Boolean);
      if (al.length && !data.contents) throw new Error("YouTube: " + al.join(" "));
      const hd = ((data.header || {}).playlistHeaderRenderer) || {};
      const md = ((data.metadata || {}).playlistMetadataRenderer) || {};
      name = ytTxt(hd.title) || md.title || "Danh sách phát"; desc = ytTxt(hd.descriptionText) || md.description || "";
      link = `https://www.youtube.com/playlist?list=${id}`;
    }
    let r = this.collect(data);
    let all = r.items.filter((i) => i.link.startsWith("v:"));
    // one more page of videos
    if (r.token) {
      try {
        const more = this.collect(await this.it("browse", { continuation: r.token }));
        all = all.concat(more.items.filter((i) => i.link.startsWith("v:")));
      } catch (e) {}
    }
    if (!img && all.length) img = all[0].imageUrl;
    const episodes = all.map((v) => ({ name: v.name, url: v.link.slice(2), thumbnailUrl: v.imageUrl }));
    if (kind === "p" && !id.startsWith("RD")) episodes.reverse();
    return { name, imageUrl: img, description: desc, author: kind === "c" ? name : "", status: 0, link, episodes };
  }
  async getVideoList(url) {
    const id = url.replace(/^v:/, "");
    const p = await this.player(id);
    const ps = p.playabilityStatus || {};
    if (ps.status && ps.status !== "OK") throw new Error("YouTube: " + (ps.reason || ps.status));
    const sd = p.streamingData || {};
    const headers = { "User-Agent": p._ua || YT_VR_UA };
    const ad = sd.adaptiveFormats || [];
    // YomiHub 0.1.9: AAC (m4a) first – it decodes everywhere; original
    // language before dubbed tracks; then by bitrate
    const audios = ad.filter((f) => f.url && /^audio\//.test(f.mimeType))
      .sort((a, b) => ((/mp4/.test(b.mimeType) ? 1 : 0) - (/mp4/.test(a.mimeType) ? 1 : 0))
        || (((b.audioTrack || {}).audioIsDefault ? 1 : 0) - ((a.audioTrack || {}).audioIsDefault ? 1 : 0))
        || ((b.bitrate || 0) - (a.bitrate || 0)))
      .map((f) => ({ file: f.url, label: `${(f.audioTrack && f.audioTrack.displayName) || "Âm thanh"} ${Math.round((f.bitrate || 0) / 1000)}kbps ${/mp4/.test(f.mimeType) ? "m4a" : "opus"}` }));
    const caps = ((((p.captions || {}).playerCaptionsTracklistRenderer) || {}).captionTracks || [])
      .map((c) => ({ file: c.baseUrl + "&fmt=vtt", label: ytTxt(c.name) || c.languageCode }));
    const videos = [];
    const pref = yhPref("yt_codec", "avc1");
    const vids = ad.filter((f) => f.url && /^video\//.test(f.mimeType));
    const byQ = {};
    for (const f of vids) {
      const q = f.qualityLabel || (f.height + "p");
      const score = (f.mimeType.includes(pref) ? 2 : (f.mimeType.includes("avc1") ? 1 : 0));
      if (!byQ[q] || score > byQ[q].score) byQ[q] = { f, score };
    }
    Object.keys(byQ).sort((a, b) => parseInt(b) - parseInt(a)).forEach((q) => {
      const f = byQ[q].f;
      videos.push({ url: f.url, originalUrl: f.url, quality: `${q} ${(f.mimeType.match(/codecs="([a-z0-9]+)/) || [])[1] || ""}`, headers, audios, subtitles: caps });
    });
    for (const f of sd.formats || []) {
      if (f.url) videos.push({ url: f.url, originalUrl: f.url, quality: `${f.qualityLabel || "360p"} (có tiếng – tải nhanh)`, headers, subtitles: caps });
    }
    // YouTube Vanced: SponsorBlock segments travel with the video (the
    // player reads them from the "yh_sb" header and skips them)
    const sbOn = yhPref("yt_sponsorblock", true);
    if (sbOn !== false && sbOn !== "false") {
      try {
        const r = await this.client.get(`https://sponsor.ajay.app/api/skipSegments?videoID=${id}&categories=${encodeURIComponent('["sponsor","selfpromo","interaction","intro","outro","preview","music_offtopic"]')}`, { "User-Agent": YH_UA });
        if (r.statusCode === 200) {
          const segs = JSON.parse(r.body).map((x) => x.segment[0].toFixed(1) + "-" + x.segment[1].toFixed(1) + "~" + x.category).join("|");
          if (segs) headers["yh_sb"] = segs;
        }
      } catch (e) {}
    }
    if (sd.hlsManifestUrl) videos.unshift({ url: sd.hlsManifestUrl, originalUrl: sd.hlsManifestUrl, quality: (p.videoDetails || {}).isLive ? "Trực tiếp (HLS)" : "Tự động (HLS)", headers });
    const maxQ = parseInt(yhPref("yt_max", "1080"));
    const ok = videos.filter((v) => !/^\d+p/.test(v.quality) || parseInt(v.quality) <= maxQ || v.quality.includes("có tiếng"));
    return ok.length ? ok : videos;
  }
  getFilterList() {
    return [
      yhHeader("Danh mục chỉ dùng khi ô tìm kiếm để trống"),
      yhSelect("cat", "Danh mục", YT_CATS),
      yhSelect("sort", "Sắp xếp", YT_SORT.map((o) => [o[0], "" + o[1]])),
      yhSelect("type", "Loại", YT_TYPE.map((o) => [o[0], "" + o[1]])),
      yhSelect("date", "Ngày tải lên", YT_DATE.map((o) => [o[0], "" + o[1]])),
      yhSelect("dur", "Thời lượng", YT_DUR.map((o) => [o[0], "" + o[1]])),
      yhGroup("feat", "Tính năng", YT_FEAT.map((o) => [o[0], "" + o[1]])),
    ];
  }
  getSourcePreferences() {
    return [
      yhDomainPref("https://www.youtube.com", "dùng cho nút mở trên web"),
      { key: "yt_home", editTextPreference: { title: "Từ khóa trang chủ", summary: "Dùng khi YouTube không trả về mục Thịnh hành", value: "nhạc Việt mới", dialogTitle: "Từ khóa", dialogMessage: "", text: "nhạc Việt mới" } },
      { key: "yt_tab", listPreference: { title: "Tab mặc định ở mục Phổ biến", summary: "Giống các tab của Pure Tuber", valueIndex: 0, entries: YT_CATS.map((c) => c[0]), entryValues: YT_CATS.map((c) => c[1]) } },
      { key: "yt_shorts_kw", editTextPreference: { title: "Từ khóa Short Video", summary: "Chủ đề của nút Short (vd. #shorts, hài, âm nhạc)", value: "#shorts", dialogTitle: "Từ khóa", dialogMessage: "", text: "#shorts" } },
      { key: "yt_sponsorblock", switchPreferenceCompat: { title: "SponsorBlock (như YouTube Vanced)", summary: "Tự bỏ qua đoạn quảng cáo tài trợ, tự quảng bá, nhắc đăng ký… do cộng đồng đánh dấu", value: true } },
      { key: "yt_dislike", switchPreferenceCompat: { title: "Hiện lượt không thích", summary: "Lấy từ Return YouTube Dislike", value: true } },
      { key: "yt_max", listPreference: { title: "Chất lượng tối đa", summary: "", valueIndex: 1, entries: ["2160p (4K)", "1080p", "720p", "480p", "360p"], entryValues: ["2160", "1080", "720", "480", "360"] } },
      { key: "yt_codec", listPreference: { title: "Codec ưu tiên", summary: "AVC1 tương thích nhất, VP9/AV1 nét hơn ở cùng dung lượng", valueIndex: 0, entries: ["H.264 (avc1)", "VP9", "AV1"], entryValues: ["avc1", "vp9", "av01"] } },
    ];
  }
}
