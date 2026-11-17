import sys; sys.path.insert(0,'audit-0.5.1'); from edit import edit
F='assets/yomihub_extensions/vbook.js'
edit(F, """  const client = new Client();
  let res = null;
  try {
    if (method === "GET" || method === "HEAD" || method === "OPTIONS") res = await client.get(url, headers);
    else res = await client.post(url, headers, body === undefined ? "" : body);
  } catch (e) {
    __vbLog("fetch " + url + ": " + e);
    res = null;
  }
  return new VbResponse(res, url);""", """  const client = new Client();
  let res = null;
  // 0.5.1: one retry on a network failure (logs 03/11 14:17: "Hướng dẫn sử
  // dụng VBook" chapters failed right after the connection came back) and
  // remember why, so the error shown/logged says what really happened
  // instead of only the extension's own "check your connection" text.
  for (let attempt = 0; attempt < 2 && res === null; attempt++) {
    try {
      if (method === "GET" || method === "HEAD" || method === "OPTIONS") res = await client.get(url, headers);
      else res = await client.post(url, headers, body === undefined ? "" : body);
    } catch (e) {
      __vbLog("fetch " + url + " (lần " + (attempt + 1) + "): " + e);
      __vbLastFetchError = url + ": " + ("" + e).slice(0, 160);
      res = null;
      if (attempt === 0) await new Promise((r) => setTimeout(r, 800));
    }
  }
  if (res && !(res.statusCode >= 200 && res.statusCode < 300)) __vbLastFetchError = url + ": HTTP " + res.statusCode;
  return new VbResponse(res, url);""")
edit(F, """async function __vbRun(key, args) {
  const sc = VB_PLUGIN.script || {};""", """let __vbLastFetchError = "";
async function __vbRun(key, args) {
  __vbLastFetchError = "";
  const sc = VB_PLUGIN.script || {};""")
edit(F, """  if (r.code !== 0 && r.code !== undefined) throw new Error("" + (r.data || ("vBook: lỗi " + file)));""", """  if (r.code !== 0 && r.code !== undefined) {
    const why = __vbLastFetchError ? " [" + __vbLastFetchError + "]" : "";
    throw new Error("" + (r.data || ("vBook: lỗi " + file)) + why);
  }""")
