// Minimal Mangayomi JS runtime for testing bundled extensions offline.
const fs = require('fs'), path = require('path'), cp = require('child_process'), crypto = require('crypto');
const FIX = path.join(__dirname, 'fx');
const map = fs.existsSync(path.join(__dirname, 'fixtures.json')) ? JSON.parse(fs.readFileSync(path.join(__dirname, 'fixtures.json'), 'utf8').replace(/^\uFEFF/, '')) : {};
const missing = new Set();
const FIN = '/tmp/yh_dom_in_' + process.pid, FOUT = '/tmp/yh_dom_out_' + process.pid;
cp.execSync(`mkfifo ${FIN} ${FOUT}`);
const pyp = cp.spawn('python3', [path.join(__dirname, 'dom_server.py'), FIN, FOUT], { stdio: 'inherit' });
const fdIn = fs.openSync(FIN, 'w'), fdOut = fs.openSync(FOUT, 'r');
let pend = '';
function dom(ops) {
  fs.writeSync(fdIn, JSON.stringify(ops) + '\n');
  const buf = Buffer.alloc(1 << 20);
  while (!pend.includes('\n')) { const n = fs.readSync(fdOut, buf, 0, buf.length, null); pend += buf.slice(0, n).toString('utf8'); }
  const i = pend.indexOf('\n'); const line = pend.slice(0, i); pend = pend.slice(i + 1);
  return JSON.parse(line);
}
process.on('exit', () => { try { pyp.kill(); fs.unlinkSync(FIN); fs.unlinkSync(FOUT); } catch (e) {} });
class Element {
  constructor(html) { this.html = html; }
  one(kind, arg) { return dom([{ html: this.html, kind, arg, el: true }])[0]; }
  get text() { return this.one('text'); }
  get innerHtml() { return this.one('inner'); }
  get outerHtml() { return this.html; }
  attr(a) { const v = this.one('attr', a); return v == null ? '' : v; }
  get getHref() { return this.attr('href'); }
  get getSrc() { return this.attr('src'); }
  selectFirst(s) { const h = this.one('selectFirst', s); return h ? new Element(h) : null; }
  select(s) { return this.one('select', s).map((h) => new Element(h)); }
}
class Document extends Element {
  one(kind, arg) { return dom([{ html: this.html, kind, arg }])[0]; }
  get body() { return this; }
}
globalThis.Document = Document;
function key(method, url, body) { return method + ' ' + url + (body ? ' ' + JSON.stringify(body) : ''); }
class Client {
  async _req(method, url, headers, body) {
    const k = key(method, url, method === 'POST' ? body : null);
    let f = map[k];
    if (f && !fs.existsSync(path.join(FIX, f.file))) f = null;
    if (!f) { missing.add(JSON.stringify({ key: k, method, url, bodyText: body ? JSON.stringify(body) : null, headers })); return { statusCode: 599, body: '{}', headers: {} }; }
    return { statusCode: f.status || 200, body: fs.readFileSync(path.join(FIX, f.file), 'utf8'), headers: {} };
  }
  get(u, h) { return this._req('GET', u, h); }
  post(u, h, b) { return this._req('POST', u, h, b); }
}
globalThis.Client = Client;
const prefs = {};
globalThis.SharedPreferences = class { get(k) { return prefs[k]; } getString(k, d) { return prefs['s_' + k] ?? d; } setString(k, v) { prefs['s_' + k] = v; } };
globalThis.MProvider = class {};
globalThis.evaluateJavascriptViaWebview = async () => '';
const [file, baseUrl] = process.argv.slice(2);
const code = fs.readFileSync(path.join(__dirname, 'ext/_common.js'), 'utf8') + '\n' + fs.readFileSync(file, 'utf8') + '\nglobalThis.DefaultExtension = DefaultExtension;';
(0, eval)(code);
const ext = new DefaultExtension();
Object.defineProperty(ext, 'source', { get: () => ({ baseUrl }) });
for (const p of ext.getSourcePreferences()) {
  const v = p.editTextPreference ? p.editTextPreference.value : p.listPreference ? p.listPreference.entryValues[p.listPreference.valueIndex] : undefined;
  prefs[p.key] = v;
}
const plan = JSON.parse(process.argv[4] || '[]');
(async () => {
  const filters = ext.getFilterList();
  let last = null;
  for (const step of plan) {
    try {
      let r;
      if (step[0] === 'popular') r = await ext.getPopular(step[1] || 1);
      else if (step[0] === 'latest') r = await ext.getLatestUpdates(step[1] || 1);
      else if (step[0] === 'search') r = await ext.search(step[1], step[2] || 1, filters);
      else if (step[0] === 'detail') r = await ext.getDetail(step[1] === '$first' ? last.list[0].link : step[1]);
      else if (step[0] === 'videos') r = await ext.getVideoList(step[1] === '$firstEp' ? last.episodes[0].url : step[1]);
      else if (step[0] === 'html') r = await ext.getHtmlContent('x', step[1] === '$firstCh' ? last.chapters[0].url : step[1]);
      last = r;
      const s = JSON.stringify(r);
      console.log('### ' + step.join(' ') + ' => ' + (r && r.list ? `list=${r.list.length} next=${r.hasNextPage} first=${JSON.stringify(r.list[0])}` : s.slice(0, 900)));
      if (r && (r.episodes || r.chapters)) console.log('    eps=' + (r.episodes || r.chapters).length + ' first=' + JSON.stringify((r.episodes || r.chapters)[0]));
    } catch (e) { console.log('### ' + step.join(' ') + ' ERROR ' + e.message); }
  }
  fs.writeFileSync(path.join(__dirname, 'missing.txt'), [...missing].join('\n'));
  console.log('missing requests:', missing.size); process.exit(0);
})();
