// ---- YomiHub 0.4.9: vBook extension runtime ----------------------------------
// Runs vBook extensions (Darkrai9x/vbook-extensions, duongden/vbook, every repo
// of vbookext.me) inside YomiHub's JavaScript engine (QuickJS).
//
// vBook scripts are written for Rhino, where fetch() blocks. QuickJS only has
// asynchronous HTTP, so each script is rewritten once per session:
//   * functions that (transitively) perform network work become `async`,
//   * every such call is wrapped in `(await …)`,
//   * Array/Elements iteration with an async callback (forEach/map/filter…)
//     uses sequential async helpers (__aforEach, __amap…).
// The rewrite works on a token stream (strings, template literals, regex
// literals and comments are skipped correctly), so no third-party parser is
// bundled. VB_PLUGIN (plugin.json) and VB_SCRIPTS (src/*.js) are injected by
// lib/yomihub/vbook/vbook_bridge.dart when the extension is installed.
// -----------------------------------------------------------------------------

/* ============================== tokenizer ================================= */
const __VB_KW = new Set(["return", "typeof", "instanceof", "in", "of", "new", "delete", "void", "throw", "case",
  "do", "else", "yield", "await", "if", "while", "for", "switch", "catch", "with", "function", "var", "let", "const",
  "try", "finally", "break", "continue", "default", "export", "import", "class", "extends", "super", "this",
  "true", "false", "null", "undefined", "debugger"]);
const __VB_REGEX_AFTER_KW = new Set(["return", "typeof", "instanceof", "in", "of", "new", "delete", "void", "throw",
  "case", "do", "else", "yield", "await"]);

function __vbTokenize(src) {
  const T = [];
  const n = src.length;
  let i = 0;
  const isIdStart = (c) => /[A-Za-z_$À-￿]/.test(c);
  const isId = (c) => /[A-Za-z0-9_$À-￿]/.test(c);
  function lastSig() { return T.length ? T[T.length - 1] : null; }
  function regexAllowed() {
    const p = lastSig();
    if (!p) return true;
    if (p.t === "num" || p.t === "str" || p.t === "tpl" || p.t === "regex") return false;
    if (p.t === "id") return __VB_REGEX_AFTER_KW.has(p.v);
    if (p.t === "punc") return !(p.v === ")" || p.v === "]" || p.v === "}" || p.v === "++" || p.v === "--");
    return true;
  }
  while (i < n) {
    const c = src[i];
    if (c === " " || c === "\t" || c === "\n" || c === "\r" || c === "﻿" || c === " " || c === " " || c === " ") { i++; continue; }
    if (c === "/" && src[i + 1] === "/") { while (i < n && src[i] !== "\n") i++; continue; }
    if (c === "/" && src[i + 1] === "*") { const e = src.indexOf("*/", i + 2); i = e < 0 ? n : e + 2; continue; }
    const s = i;
    if (c === "\"" || c === "'") {
      i++;
      while (i < n && src[i] !== c) { if (src[i] === "\\") i++; if (src[i] === "\n") break; i++; }
      i++;
      T.push({ t: "str", v: src.slice(s, i), s, e: i });
      continue;
    }
    if (c === "`") {
      // template literal, nested ${ … } skipped by brace depth
      i++;
      let depth = 0;
      while (i < n) {
        const d = src[i];
        if (d === "\\") { i += 2; continue; }
        if (depth === 0 && d === "`") { i++; break; }
        if (d === "$" && src[i + 1] === "{") { depth++; i += 2; continue; }
        if (depth > 0) {
          if (d === "{") depth++;
          else if (d === "}") depth--;
          else if (d === "\"" || d === "'" ) { const q = d; i++; while (i < n && src[i] !== q) { if (src[i] === "\\") i++; i++; } }
        }
        i++;
      }
      T.push({ t: "tpl", v: src.slice(s, i), s, e: i });
      continue;
    }
    if (/[0-9]/.test(c) || (c === "." && /[0-9]/.test(src[i + 1] || ""))) {
      i++;
      while (i < n && /[0-9A-Za-z_.]/.test(src[i])) {
        if ((src[i] === "e" || src[i] === "E") && (src[i + 1] === "+" || src[i + 1] === "-")) i++;
        i++;
      }
      T.push({ t: "num", v: src.slice(s, i), s, e: i });
      continue;
    }
    if (isIdStart(c) || c === "\\") {
      i++;
      while (i < n && isId(src[i])) i++;
      T.push({ t: "id", v: src.slice(s, i), s, e: i });
      continue;
    }
    if (c === "/" && regexAllowed()) {
      i++;
      let cls = false;
      while (i < n) {
        const d = src[i];
        if (d === "\\") { i += 2; continue; }
        if (d === "\n") break;
        if (cls) { if (d === "]") cls = false; }
        else if (d === "[") cls = true;
        else if (d === "/") { i++; break; }
        i++;
      }
      while (i < n && /[a-z]/i.test(src[i])) i++;
      T.push({ t: "regex", v: src.slice(s, i), s, e: i });
      continue;
    }
    const three = src.substr(i, 4);
    const ops = [">>>=", "===", "!==", "**=", "<<=", ">>=", ">>>", "...", "&&=", "||=", "??=",
      "=>", "==", "!=", "<=", ">=", "&&", "||", "??", "?.", "++", "--", "+=", "-=", "*=", "/=", "%=", "&=", "|=", "^=", "**", "<<", ">>"];
    let op = null;
    for (const o of ops) { if (three.startsWith(o)) { op = o; break; } }
    if (op === "?." && /[0-9]/.test(src[i + 2] || "")) op = null; // a ?.5 : b
    if (!op) op = c;
    i += op.length;
    T.push({ t: "punc", v: op, s, e: i });
  }
  return T;
}

/* ============================== transpiler ================================ */
const __VB_ARRAY_ASYNC = { forEach: "__aforEach", map: "__amap", filter: "__afilter", some: "__asome",
  every: "__aevery", find: "__afind", findIndex: "__afindIndex", reduce: "__areduce", flatMap: "__aflatMap" };
const __VB_HTTP_TERMINAL = new Set(["string", "html", "blob", "json", "text", "binary", "base64"]);
const __VB_BROWSER_ASYNC = new Set(["launch", "launchAsync", "callJs", "loadHtml", "waitUrl"]);

function __vbTranspile(src) {
  const T = __vbTokenize(src);
  const N = T.length;
  const isP = (k, v) => k >= 0 && k < N && T[k].t === "punc" && T[k].v === v;
  const isId = (k, v) => k >= 0 && k < N && T[k].t === "id" && (v === undefined || T[k].v === v);
  // bracket matching
  const match = new Array(N).fill(-1);
  const stack = [];
  for (let k = 0; k < N; k++) {
    if (T[k].t !== "punc") continue;
    const v = T[k].v;
    if (v === "(" || v === "[" || v === "{") stack.push(k);
    else if (v === ")" || v === "]" || v === "}") {
      const o = stack.pop();
      if (o !== undefined) { match[o] = k; match[k] = o; }
    }
  }

  // ---- functions
  const fns = []; // {head, insertAt, bodyOpen, bodyClose, exprEnd, name, async, canAsync}
  function exprEnd(k) { // first token index after an arrow expression body
    let d = 0;
    for (; k < N; k++) {
      const t = T[k];
      if (t.t === "punc") {
        if (t.v === "(" || t.v === "[" || t.v === "{") { k = match[k] >= 0 ? match[k] : k; continue; }
        if (t.v === ")" || t.v === "]" || t.v === "}" || t.v === "," || t.v === ";") return k;
      }
    }
    return N;
  }
  function assignedName(k) { // name in `x = function` / `var x = (…) =>` / `x: function`
    if (isP(k - 1, "=") && isId(k - 2)) return T[k - 2].v;
    if (isP(k - 1, ":") && (isId(k - 2) || (k - 2 >= 0 && T[k - 2].t === "str"))) return null;
    return null;
  }
  for (let k = 0; k < N; k++) {
    const t = T[k];
    if (t.t === "id" && t.v === "function" && !isP(k - 1, ".")) {
      let j = k + 1;
      if (isP(j, "*")) j++;
      let name = null;
      if (isId(j)) { name = T[j].v; j++; }
      if (!isP(j, "(") || match[j] < 0) continue;
      const b = match[j] + 1;
      if (!isP(b, "{")) continue;
      fns.push({ head: k, insertAt: t.s, bodyOpen: b, bodyClose: match[b], name: name || assignedName(k), decl: !!name, canAsync: !isP(k + 1, "*") });
    } else if (t.t === "punc" && t.v === "=>") {
      let ps;
      if (isP(k - 1, ")")) ps = match[k - 1];
      else if (isId(k - 1)) ps = k - 1;
      else continue;
      if (ps < 0) continue;
      let bodyOpen, bodyClose;
      if (isP(k + 1, "{")) { bodyOpen = k + 1; bodyClose = match[k + 1]; }
      else { bodyOpen = k; bodyClose = exprEnd(k + 1); }
      fns.push({ head: ps, insertAt: T[ps].s, bodyOpen, bodyClose, name: assignedName(ps), arrow: true, canAsync: true });
    } else if (t.t === "id" && !__VB_KW.has(t.v) && isP(k + 1, "(") && match[k + 1] > 0 && isP(match[k + 1] + 1, "{") &&
      (isP(k - 1, "{") || isP(k - 1, ",") || isId(k - 1, "get") || isId(k - 1, "set") || isId(k - 1, "static")) &&
      !isP(k - 1, ".")) {
      // method shorthand `name(args) { … }` in an object literal
      const getter = isId(k - 1, "get") || isId(k - 1, "set");
      const b = match[k + 1] + 1;
      fns.push({ head: k, insertAt: t.s, bodyOpen: b, bodyClose: match[b], name: null, method: true, canAsync: !getter });
    }
  }
  // innermost function owning each token
  const owner = new Int32Array(N).fill(-1);
  const order = fns.map((f, i) => i).sort((a, b) => (fns[b].bodyClose - fns[b].bodyOpen) - (fns[a].bodyClose - fns[a].bodyOpen));
  for (const fi of order) {
    const f = fns[fi];
    for (let k = f.bodyOpen; k < Math.min(f.bodyClose + 1, N); k++) owner[k] = fi;
  }
  const fnAtHead = new Map();
  fns.forEach((f, i) => fnAtHead.set(f.head, i));

  // ---- chain helpers
  function chainStart(k) { // k = index of the first token of a callee member chain tail, walk left
    let j = k;
    for (;;) {
      const p = j - 1;
      if (isP(p, ".") || isP(p, "?.")) {
        const q = p - 1;
        if (q < 0) return j;
        if (isP(q, ")") || isP(q, "]")) {
          let o = match[q];
          if (o < 0) return j;
          // walk over call/index groups and their callee
          for (;;) {
            const before = o - 1;
            if (isId(before) && !__VB_KW.has(T[before].v)) { j = before; break; }
            if (isP(before, ")") || isP(before, "]")) { o = match[before]; if (o < 0) return j; continue; }
            if (before >= 0 && (T[before].t === "str" || T[before].t === "tpl")) { j = before; break; }
            j = o; // parenthesised / array literal expression
            return j;
          }
          continue;
        }
        if (isId(q) || T[q].t === "str" || T[q].t === "tpl" || T[q].t === "num" || T[q].t === "regex") { j = q; continue; }
        return j;
      }
      return j;
    }
  }

  // ---- call sites: {fi (owner), start (token), end (token of closing paren), kind, nameDep, cbFn, propTok}
  const calls = [];
  for (let k = 0; k < N; k++) {
    if (!isP(k, "(") || match[k] < 0) continue;
    const prev = k - 1;
    if (prev < 0) continue;
    const pt = T[prev];
    if (pt.t === "id") {
      if (__VB_KW.has(pt.v) && pt.v !== "this") continue;
      if (fnAtHead.has(prev) && fns[fnAtHead.get(prev)].method) continue; // method definition
      if (isId(prev - 1, "function")) continue;
      const isMember = isP(prev - 1, ".") || isP(prev - 1, "?.");
      const close = match[k];
      if (!isMember) {
        if (pt.v === "fetch" || pt.v === "sleep") calls.push({ fi: owner[k], start: prev, end: close, kind: "prim" });
        else calls.push({ fi: owner[k], start: prev, end: close, kind: "name", name: pt.v });
        continue;
      }
      const start = chainStart(prev);
      // Http.get(…)…string()
      if (__VB_HTTP_TERMINAL.has(pt.v) && isId(start, "Http")) {
        calls.push({ fi: owner[k], start, end: close, kind: "prim" });
        continue;
      }
      if (__VB_BROWSER_ASYNC.has(pt.v)) {
        calls.push({ fi: owner[k], start, end: close, kind: "prim" });
        continue;
      }
      if (__VB_ARRAY_ASYNC[pt.v]) {
        // first argument is an inline function?
        const a = k + 1;
        let cb = -1;
        if (fnAtHead.has(a)) cb = fnAtHead.get(a);
        else if (isId(a, "function") && fnAtHead.has(a)) cb = fnAtHead.get(a);
        calls.push({ fi: owner[k], start, end: close, kind: "array", cb, prop: prev, cbName: cb < 0 && isId(a) && isP(a + 1, ")") ? T[a].v : null });
        continue;
      }
      // obj.method(...) where method is a known async function name (e.g. this.helper)
      calls.push({ fi: owner[k], start, end: close, kind: "member", name: pt.v });
    } else if (pt.t === "punc" && pt.v === ")" && match[prev] >= 0) {
      // IIFE: (function(){…})()
      const o = match[prev];
      const inner = o + 1;
      if (fnAtHead.has(inner)) calls.push({ fi: owner[k], start: o, end: match[k], kind: "iife", cb: fnAtHead.get(inner) });
    }
  }

  // ---- fixpoint: which functions are async
  const asyncFn = new Array(fns.length).fill(false);
  const asyncNames = new Set();
  const callAsync = new Array(calls.length).fill(false);
  let changed = true, guard = 0;
  while (changed && guard++ < 50) {
    changed = false;
    for (let c = 0; c < calls.length; c++) {
      if (callAsync[c]) continue;
      const cl = calls[c];
      let a = false;
      if (cl.kind === "prim") a = true;
      else if (cl.kind === "name") a = asyncNames.has(cl.name);
      else if (cl.kind === "member") a = asyncNames.has(cl.name) && false;
      else if (cl.kind === "array") a = (cl.cb >= 0 && asyncFn[cl.cb]) || (cl.cbName != null && asyncNames.has(cl.cbName));
      else if (cl.kind === "iife") a = asyncFn[cl.cb];
      if (a) { callAsync[c] = true; changed = true; }
    }
    for (let c = 0; c < calls.length; c++) {
      if (!callAsync[c]) continue;
      const fi = calls[c].fi;
      if (fi >= 0 && !asyncFn[fi] && fns[fi].canAsync) {
        asyncFn[fi] = true; changed = true;
        if (fns[fi].name) asyncNames.add(fns[fi].name);
      }
    }
  }

  // ---- edits
  const ins = []; // {pos, text, w}  w: ordering weight for equal positions
  for (let f = 0; f < fns.length; f++) {
    if (!asyncFn[f]) continue;
    ins.push({ pos: fns[f].insertAt, text: "async ", w: 1e9 });
  }
  const repl = [];
  for (let c = 0; c < calls.length; c++) {
    if (!callAsync[c]) continue;
    const cl = calls[c];
    if (cl.fi < 0 || !asyncFn[cl.fi]) {
      // top-level async call: cannot await, leave as is (top-level code runs at load time)
      continue;
    }
    const sPos = T[cl.start].s, ePos = T[cl.end].e;
    ins.push({ pos: sPos, text: "(await ", w: -(ePos - sPos) });
    ins.push({ pos: ePos, text: ")", w: 0 });
    if (cl.kind === "array") repl.push({ s: T[cl.prop].s, e: T[cl.prop].e, text: __VB_ARRAY_ASYNC[T[cl.prop].v] });
  }
  // apply from the end; at the same position: "async " innermost, wider "(await " first in output
  const edits = [];
  for (const r of repl) edits.push({ pos: r.s, end: r.e, text: r.text, w: 2e9 });
  for (const x of ins) edits.push({ pos: x.pos, end: x.pos, text: x.text, w: x.w });
  edits.sort((a, b) => b.pos - a.pos || b.w - a.w);
  let out = src;
  for (const e of edits) out = out.slice(0, e.pos) + e.text + out.slice(e.end);
  return { code: out, asyncNames: [...asyncNames], executeAsync: asyncNames.has("execute") };
}

/* =========================== async array helpers =========================== */
(function () {
  const def = (proto, name, fn) => { try { Object.defineProperty(proto, name, { value: fn, writable: true, configurable: true, enumerable: false }); } catch (e) {} };
  const P = Array.prototype;
  def(P, "__aforEach", async function (cb, self) { for (let i = 0; i < this.length; i++) await cb.call(self, this[i], i, this); });
  def(P, "__amap", async function (cb, self) { const r = []; for (let i = 0; i < this.length; i++) r.push(await cb.call(self, this[i], i, this)); return r; });
  def(P, "__afilter", async function (cb, self) { const r = []; for (let i = 0; i < this.length; i++) if (await cb.call(self, this[i], i, this)) r.push(this[i]); return r; });
  def(P, "__asome", async function (cb, self) { for (let i = 0; i < this.length; i++) if (await cb.call(self, this[i], i, this)) return true; return false; });
  def(P, "__aevery", async function (cb, self) { for (let i = 0; i < this.length; i++) if (!(await cb.call(self, this[i], i, this))) return false; return true; });
  def(P, "__afind", async function (cb, self) { for (let i = 0; i < this.length; i++) if (await cb.call(self, this[i], i, this)) return this[i]; return undefined; });
  def(P, "__afindIndex", async function (cb, self) { for (let i = 0; i < this.length; i++) if (await cb.call(self, this[i], i, this)) return i; return -1; });
  def(P, "__areduce", async function (cb, init) { let i = 0, acc = init; if (arguments.length < 2) { acc = this[0]; i = 1; } for (; i < this.length; i++) acc = await cb(acc, this[i], i, this); return acc; });
  def(P, "__aflatMap", async function (cb, self) { const r = []; for (let i = 0; i < this.length; i++) { const v = await cb.call(self, this[i], i, this); if (Array.isArray(v)) r.push(...v); else r.push(v); } return r; });
  // Rhino / jsoup habits
  def(P, "size", function () { return this.length; });
  def(P, "get", function (i) { return this[i]; });
  def(P, "isEmpty", function () { return this.length === 0; });
  def(P, "add", function (v) { this.push(v); return true; });
  if (!String.prototype.contains) def(String.prototype, "contains", function (s) { return this.indexOf(s) >= 0; });
})();

/* ================================ vBook API ================================ */
const VB_SOURCE_DEFAULT = (VB_PLUGIN.metadata && VB_PLUGIN.metadata.source) || "";
let VB_HOST = VB_SOURCE_DEFAULT;          // replaced by the user's domain (Đổi tên miền) at runtime
const VB_KEY = "vb_" + ((VB_PLUGIN.metadata && VB_PLUGIN.metadata.name) || "x").replace(/[^A-Za-z0-9]/g, "_").slice(0, 40);

function __vbAbs(u, host) {
  if (u === undefined || u === null) return "";
  u = ("" + u).trim();
  if (!u) return "";
  if (/^https?:\/\//i.test(u) || u.startsWith("data:")) return u;
  if (u.startsWith("//")) return "https:" + u;
  const h = (host || VB_HOST || "").replace(/\/+$/, "");
  if (u.startsWith("/")) { const m = h.match(/^https?:\/\/[^\/]+/i); return (m ? m[0] : h) + u; }
  return h + "/" + u;
}

const Response = {
  success(data, data2) { return { code: 0, data: data, data2: data2 === undefined ? "" : data2 }; },
  error(msg) { return { code: 1, data: msg === undefined ? "" : "" + msg }; },
};

if (typeof console === "undefined") { globalThis.console = { log() {}, error() {}, warn() {} }; }
const Log = { log(m) { try { console.log("[vBook] " + m); } catch (e) {} } };

const UserAgent = {
  system() { return YH_UA; },
  android() { return YH_UA; },
  chrome() { return "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36"; },
  ios() { return "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1"; },
};

function __vbPrefStore(prefix) {
  return {
    getItem(k) { try { const v = new SharedPreferences().getString(prefix + k, ""); return v === "" ? null : v; } catch (e) { return null; } },
    setItem(k, v) { try { new SharedPreferences().setString(prefix + k, v === undefined || v === null ? "" : (typeof v === "string" ? v : JSON.stringify(v))); } catch (e) {} },
    removeItem(k) { try { new SharedPreferences().setString(prefix + k, ""); } catch (e) {} },
    clear() {},
  };
}
const localStorage = __vbPrefStore(VB_KEY + "_ls_");
const cacheStorage = __vbPrefStore(VB_KEY + "_cs_");
const localConfig = { getItem(k) { return __vbConfig(k, null); } };
const localCookie = {
  getCookie() { return localStorage.getItem("__cookie") || ""; },
  setCookie(c) { const old = localCookie.getCookie(); localStorage.setItem("__cookie", old ? old + "; " + ("" + c).split(";")[0] : ("" + c).split(";")[0]); },
};

function __vbConfig(k, def) {
  try {
    const v = new SharedPreferences().get("vbcfg_" + k);
    if (v !== undefined && v !== null && v !== "") return "" + v;
  } catch (e) {}
  return def;
}

function sleep(ms) { return new Promise((r) => setTimeout(r, Math.max(0, Math.min(parseInt(ms) || 0, 15000)))); }

const Script = {
  execute(code, fnName, input) {
    const f = (0, eval)("(function(){" + code + "\n;return typeof " + fnName + "==='function'?" + fnName + ":null;})()");
    return f ? f(input) : undefined;
  },
};

class Blob {
  constructor(b64, type) { this._b = b64 || ""; this.type = type || ""; this.size = Math.floor(this._b.length * 3 / 4); }
  base64() { return this._b; }
  static fromBase64(b, t) { return new Blob(b, t); }
}

/* ---------------------------------- HTML ---------------------------------- */
// Wraps the app's Document/Element (lib/eval/javascript/dom_selector.dart)
// with the jsoup-like API vBook scripts use.
class VbElements extends Array {
  static get [Symbol.species]() { return Array; }
  first() { return this.length ? this[0] : __vbEmptyEl(); }
  last() { return this.length ? this[this.length - 1] : __vbEmptyEl(); }
  get(i) { return i >= 0 && i < this.length ? this[i] : __vbEmptyEl(); }
  eq(i) { return this.get(i); }
  text() { return this.map((e) => e.text()).filter((s) => s !== "").join(" "); }
  html() { return this.map((e) => e.html()).join("\n"); }
  outerHtml() { return this.map((e) => e.outerHtml()).join("\n"); }
  attr(name) { for (const e of this) { const v = e.attr(name); if (v) return v; } return ""; }
  hasAttr(name) { return this.some((e) => e.hasAttr(name)); }
  absUrl(name) { for (const e of this) { const v = e.absUrl(name); if (v) return v; } return ""; }
  eachAttr(name) { return this.map((e) => e.attr(name)).filter((v) => v); }
  remove() { for (const e of this) e.remove(); return this; }
  select(css) { const r = new VbElements(); for (const e of this) for (const x of e.select(css)) r.push(x); return r; }
  not(css) { const drop = new Set(this.select(css).map((e) => e._outer())); const r = new VbElements(); for (const e of this) if (!drop.has(e._outer())) r.push(e); return r; }
  toString() { return this.html(); }
}

class VbElement {
  constructor(node, doc, base) { this._n = node; this._doc = doc; this._base = base || VB_HOST; }
  _outer() { try { return this._n ? (this._n.outerHtml || "") : ""; } catch (e) { return ""; } }
  _inner() {
    try {
      if (!this._n) return "";
      if (typeof Document !== "undefined" && this._n instanceof Document) return this._n.outerHtml || "";
      return this._n.innerHtml !== undefined && this._n.innerHtml !== null ? this._n.innerHtml : (this._n.outerHtml || "");
    } catch (e) { return ""; }
  }
  _clean(h) { // drop removed elements
    const rm = this._doc ? this._doc.removed : null;
    if (!rm || !rm.length || !h) return h;
    for (const r of rm) if (r) h = h.split(r).join("");
    return h;
  }
  select(css) {
    const r = new VbElements();
    if (!this._n) return r;
    let list = [];
    try { list = this._n.select(css) || []; } catch (e) { list = []; }
    const rm = this._doc && this._doc.removed.length ? new Set(this._doc.removed) : null;
    for (const x of list) {
      const el = new VbElement(x, this._doc, this._base);
      if (rm && rm.has(el._outer())) continue;
      r.push(el);
    }
    return r;
  }
  selectFirst(css) { const r = this.select(css); return r.length ? r[0] : null; }
  text() {
    if (!this._n) return "";
    try {
      if (this._doc && this._doc.removed.length) return yhText(__vbHtmlText(this._clean(this._inner())));
      return yhText(__vbNodeText(this._n));
    } catch (e) { return ""; }
  }
  ownText() { return this.text(); }
  wholeText() { return __vbNodeText(this._n); }
  data() { return this.html(); }
  html() { return this._clean(this._inner()); }
  outerHtml() { return this._clean(this._outer()); }
  val() { return this.attr("value"); }
  attr(name) {
    if (!this._n) return "";
    if (("" + name).startsWith("abs:")) return this.absUrl(("" + name).slice(4));
    try { const v = this._n.attr(name); return v === null || v === undefined ? "" : "" + v; } catch (e) { return ""; }
  }
  hasAttr(name) { try { return !!(this._n && this._n.hasAttr(name)); } catch (e) { return false; } }
  absUrl(name) { const v = this.attr(name); return v ? __vbAbs(v, this._base) : ""; }
  attributes() {
    const o = {};
    const m = this._outer().match(/^<[^>]+>/);
    if (m) for (const a of m[0].matchAll(/([^\s=<>"'\/]+)\s*=\s*("([^"]*)"|'([^']*)'|([^\s>]+))/g)) o[a[1]] = a[3] ?? a[4] ?? a[5] ?? "";
    return o;
  }
  id() { return this.attr("id"); }
  className() { return this.attr("class"); }
  hasClass(c) { return (" " + this.attr("class") + " ").indexOf(" " + c + " ") >= 0; }
  tagName() { try { return this._n ? (this._n.localName || "") : ""; } catch (e) { return ""; } }
  nodeName() { return this.tagName(); }
  children() { const r = new VbElements(); try { for (const c of (this._n.children || [])) r.push(new VbElement(c, this._doc, this._base)); } catch (e) {} return r; }
  child(i) { return this.children().get(i); }
  parent() { try { const p = this._n.parent; return p ? new VbElement(p, this._doc, this._base) : __vbEmptyEl(); } catch (e) { return __vbEmptyEl(); } }
  nextElementSibling() { try { const p = this._n.nextElementSibling; return p ? new VbElement(p, this._doc, this._base) : null; } catch (e) { return null; } }
  previousElementSibling() { try { const p = this._n.previousElementSibling; return p ? new VbElement(p, this._doc, this._base) : null; } catch (e) { return null; } }
  remove() { const o = this._outer(); if (o && this._doc) this._doc.removed.push(o); return this; }
  toString() { return this.html(); }
}
function __vbEmptyEl() { return new VbElement(null, null); }
// package:html Document.text is null (like DOM document.textContent): read the body.
function __vbNodeText(n) {
  if (!n) return "";
  try {
    if (typeof Document !== "undefined" && n instanceof Document) { const b = n.body; return b ? (b.text || "") : ""; }
    return n.text || "";
  } catch (e) { return ""; }
}
function __vbHtmlText(h) { try { return __vbNodeText(new Document("" + h)); } catch (e) { return ("" + h).replace(/<[^>]+>/g, " "); } }

const Html = {
  parse(str, base) {
    const doc = { removed: [] };
    let d = null;
    try { d = new Document("" + (str === undefined || str === null ? "" : str)); } catch (e) { d = null; }
    const root = new VbElement(d, doc, base || VB_HOST);
    return root;
  },
  clean(html) { return "" + html; },
};

/* ---------------------------------- HTTP ---------------------------------- */
function __vbQuery(url, q) {
  if (!q) return url;
  const parts = [];
  for (const k of Object.keys(q)) parts.push(encodeURIComponent(k) + "=" + encodeURIComponent(q[k] === undefined || q[k] === null ? "" : "" + q[k]));
  if (!parts.length) return url;
  return url + (url.indexOf("?") >= 0 ? "&" : "?") + parts.join("&");
}

class VbResponse {
  constructor(res, url) {
    this._r = res || null;
    this.status = res ? (res.statusCode || 0) : 504;
    this.statusText = res ? (res.reasonPhrase || "") : "";
    this.ok = this.status >= 200 && this.status < 300;
    this.url = res && res.request && res.request.url ? res.request.url : (res ? url : "");
    const h = {};
    if (res && res.headers) for (const k of Object.keys(res.headers)) h[k.toLowerCase()] = "" + res.headers[k];
    this.headers = h;
    this.request = { url: url, headers: {} };
    this._body = res ? (res.body || "") : "";
  }
  header(k) { return this.headers[("" + k).toLowerCase()] || ""; }
  text() { return this._body; }
  string() { return this._body; }
  json() { return JSON.parse(this._body); }
  html() { return Html.parse(this._body, this.url || VB_HOST); }
  base64() { try { return btoa(unescape(encodeURIComponent(this._body))); } catch (e) { return ""; } }
  blob() { return new Blob(this.base64(), this.header("content-type")); }
  readLine() { if (this._lines === undefined) this._lines = this._body.split("\n"); return this._lines.length ? this._lines.shift() : null; }
}

async function fetch(url, opt) {
  opt = opt || {};
  url = __vbAbs(url);
  url = __vbQuery(url, opt.queries || opt.params);
  const method = ("" + (opt.method || "GET")).toUpperCase();
  const headers = {};
  if (opt.headers) for (const k of Object.keys(opt.headers)) headers[k] = "" + opt.headers[k];
  if (!Object.keys(headers).some((k) => k.toLowerCase() === "user-agent")) headers["User-Agent"] = YH_UA;
  const ck = localCookie.getCookie();
  if (ck && !Object.keys(headers).some((k) => k.toLowerCase() === "cookie")) headers["Cookie"] = ck;
  let body = opt.body;
  if (body instanceof Blob) body = body.base64();
  else if (body && typeof body === "object") {
    if (!Object.keys(headers).some((k) => k.toLowerCase() === "content-type")) headers["Content-Type"] = "application/x-www-form-urlencoded";
    const isJson = Object.keys(headers).some((k) => k.toLowerCase() === "content-type" && ("" + headers[k]).indexOf("json") >= 0);
    body = isJson ? JSON.stringify(body) : Object.keys(body).map((k) => encodeURIComponent(k) + "=" + encodeURIComponent("" + body[k])).join("&");
  }
  const client = new Client();
  let res = null;
  try {
    if (method === "GET" || method === "HEAD" || method === "OPTIONS") res = await client.get(url, headers);
    else res = await client.post(url, headers, body === undefined ? "" : body);
  } catch (e) {
    __vbLog("fetch " + url + ": " + e);
    res = null;
  }
  return new VbResponse(res, url);
}

class VbHttp {
  constructor(method, url) { this._m = method; this._u = url; this._o = { method, headers: {}, queries: null }; }
  headers(h) { Object.assign(this._o.headers, h || {}); return this; }
  params(q) { this._o.queries = Object.assign(this._o.queries || {}, q || {}); return this; }
  queries(q) { return this.params(q); }
  body(b) { this._o.body = b; return this; }
  binary(b64, type) { this._o.body = new Blob(b64, type); return this; }
  timeout() { return this; }
  async _go() { return fetch(this._u, this._o); }
  async string() { return (await this._go()).text(); }
  async text() { return (await this._go()).text(); }
  async html() { return (await this._go()).html(); }
  async json() { return (await this._go()).json(); }
  async blob() { return (await this._go()).blob(); }
  async base64() { return (await this._go()).base64(); }
}
const Http = { get(u) { return new VbHttp("GET", u); }, post(u) { return new VbHttp("POST", u); } };

/* --------------------------- headless browser ---------------------------- */
class VbBrowser {
  constructor() { this._url = ""; this._html = ""; this._ua = YH_UA; }
  setUserAgent(ua) { this._ua = ua; }
  block() {}
  urls() { return "[]"; }
  waitUrl() { return null; }
  getVariable() { return undefined; }
  close() {}
  async _eval(url, js) {
    const s = "(function(){var go=function(){try{var v=(function(){return " + js + ";})();window.flutter_inappwebview.callHandler('setResponse',''+(v===undefined||v===null?'':v));}catch(e){window.flutter_inappwebview.callHandler('setResponse','');}};setTimeout(go,1500);})();";
    try { return (await evaluateJavascriptViaWebview(url, { "User-Agent": this._ua }, [s])) || ""; } catch (e) { __vbLog("browser " + url + ": " + e); return ""; }
  }
  async launch(url, timeout) { this._url = __vbAbs(url); this._html = await this._eval(this._url, "document.documentElement.outerHTML"); return Html.parse(this._html, this._url); }
  async launchAsync(url) { return this.launch(url); }
  async loadHtml(base, html) { this._url = base; this._html = html; return Html.parse(html, base); }
  html() { return Html.parse(this._html, this._url); }
  async callJs(js) { return Html.parse(await this._eval(this._url || VB_HOST, js), this._url); }
}
const Engine = { newBrowser() { return new VbBrowser(); } };

/* ============================ script loading ============================== */
function __vbLog(m) { try { console.log("[vBook " + ((VB_PLUGIN.metadata && VB_PLUGIN.metadata.name) || "") + "] " + m); } catch (e) {} }

function __vbConsts() {
  let s = "";
  const cfg = VB_PLUGIN.config || {};
  for (const k of Object.keys(cfg)) {
    if (!/^[A-Za-z_$][A-Za-z0-9_$]*$/.test(k)) continue;
    const c = cfg[k];
    let def;
    if (c && typeof c === "object") { if (c.mode === "database") continue; def = c.default === undefined ? "" : c.default; }
    else def = c;
    s += "const " + k + " = " + JSON.stringify("" + __vbConfig(k, def === undefined || def === null ? "" : (typeof def === "string" ? def : JSON.stringify(def)))) + ";\n";
  }
  return s;
}

function __vbExpandLoads(code) {
  return code.replace(/load\(\s*(['"])([^'"]+)\1\s*\)\s*;?/g, (m, q, file) => {
    if (file === "crypto.js") return typeof CryptoJS !== "undefined" ? "" : "";
    const inc = VB_SCRIPTS[file];
    return inc ? "\n" + inc + "\n" : "";
  });
}

function __vbRehost(code) {
  // "Đổi tên miền": a user domain replaces the plugin's own origin in the scripts.
  const orig = (VB_SOURCE_DEFAULT.match(/^https?:\/\/[^\/]+/i) || [""])[0];
  const now = (VB_HOST.match(/^https?:\/\/[^\/]+/i) || [""])[0];
  if (!orig || !now || orig === now) return code;
  return code.split(orig).join(now);
}

const __vbCompiled = {};
function __vbFn(file) {
  if (__vbCompiled[file] !== undefined) return __vbCompiled[file];
  const raw = VB_SCRIPTS[file];
  if (!raw) { __vbCompiled[file] = null; return null; }
  let code = __vbRehost(__vbExpandLoads(raw));
  let tr;
  try { tr = __vbTranspile(code); } catch (e) { __vbLog("transpile " + file + ": " + e); tr = { code }; }
  let fn = null;
  try {
    fn = (0, eval)("(function(){\n" + __vbConsts() + tr.code + "\n;return typeof execute === 'function' ? execute : null;\n})")();
  } catch (e) {
    __vbLog("compile " + file + ": " + e);
    throw new Error("vBook: không biên dịch được " + file + " (" + e + ")");
  }
  __vbCompiled[file] = fn;
  __vbIsAsync[file] = !!tr.executeAsync;
  return fn;
}
const __vbIsAsync = {};

async function __vbRun(key, args) {
  const sc = VB_PLUGIN.script || {};
  const file = sc[key] && VB_SCRIPTS[sc[key]] ? sc[key] : (VB_SCRIPTS[key] ? key : null);
  if (!file) throw new Error("vBook: tiện ích không có script " + key);
  const fn = __vbFn(file);
  if (!fn) throw new Error("vBook: " + file + " không có hàm execute");
  let r = await fn.apply(null, (args || []).map((a) => (a === undefined || a === null ? "" : "" + a)));
  if (typeof r === "string") { try { r = JSON.parse(r); } catch (e) { r = { code: 0, data: r }; } }
  if (!r || typeof r !== "object") throw new Error("vBook: " + file + " trả về kết quả rỗng");
  if (r.code !== 0 && r.code !== undefined) throw new Error("" + (r.data || ("vBook: lỗi " + file)));
  return r;
}
function __vbHas(key) { const sc = VB_PLUGIN.script || {}; return !!(sc[key] && VB_SCRIPTS[sc[key]]); }

/* ============================ YomiHub adapter ============================= */
function __vbType() { const t = ("" + ((VB_PLUGIN.metadata && VB_PLUGIN.metadata.type) || "novel")).toLowerCase(); return t.indexOf("comic") >= 0 ? "comic" : t.indexOf("video") >= 0 ? "video" : "novel"; }
function __vbPlain(h) {
  if (!h) return "";
  const t = __vbHtmlText("<div>" + ("" + h).replace(/<br\s*\/?>/gi, "\n").replace(/<\/p>/gi, "\n") + "</div>");
  return (t || ("" + h).replace(/<[^>]+>/g, " ")).replace(/[ \t]+/g, " ").replace(/\n\s*\n+/g, "\n").trim();
}

class DefaultExtension extends MProvider {
  constructor() { super(); this._tok = {}; this._tabs = null; }
  _host() { try { VB_HOST = yhBase(this) || VB_SOURCE_DEFAULT; } catch (e) { VB_HOST = VB_SOURCE_DEFAULT; } return VB_HOST; }
  get supportsLatest() { return this._tabsSync().length > 1; }
  getHeaders(url) { this._host(); return { "User-Agent": YH_UA, "Referer": VB_HOST.replace(/\/+$/, "") + "/" }; }

  // static (no network) home tabs, used for filters and popular/latest
  _tabsSync() {
    if (this._tabs) return this._tabs;
    this._tabs = [];
    try {
      const cached = new SharedPreferences().getString(VB_KEY + "_tabs", "");
      if (cached) this._tabs = JSON.parse(cached);
    } catch (e) {}
    if (!this._tabs.length && __vbHas("home")) {
      try {
        const hf = (VB_PLUGIN.script || {}).home;
        const fn = __vbFn(hf);
        const r = fn && !__vbIsAsync[hf] ? fn() : null;
        if (r && typeof r.then !== "function" && r.code === 0 && Array.isArray(r.data)) this._tabs = r.data;
      } catch (e) {}
    }
    return this._tabs;
  }
  async _tabsAsync() {
    let t = this._tabsSync();
    if (t.length || !__vbHas("home")) return t;
    try {
      const r = await __vbRun("home", []);
      if (Array.isArray(r.data)) { this._tabs = r.data; new SharedPreferences().setString(VB_KEY + "_tabs", JSON.stringify(r.data)); }
    } catch (e) { __vbLog("home: " + e); }
    return this._tabs || [];
  }
  async _genres() {
    if (!__vbHas("genre")) return [];
    try {
      const r = await __vbRun("genre", []);
      if (Array.isArray(r.data)) { new SharedPreferences().setString(VB_KEY + "_genres", JSON.stringify(r.data.slice(0, 300))); return r.data; }
    } catch (e) { __vbLog("genre: " + e); }
    return [];
  }

  async _list(script, input, page) {
    // vBook page tokens are opaque (data2 of the previous page); the app asks
    // for page numbers and may use a fresh engine for every call, so the
    // tokens are kept in the extension's preferences.
    const key = VB_KEY + "_tok_" + script + "|" + input;
    let toks = this._tok[key];
    if (!toks) { try { toks = JSON.parse(new SharedPreferences().getString(key, "") || "{}"); } catch (e) { toks = {}; } this._tok[key] = toks; }
    let token = page <= 1 ? "" : toks[page];
    if (token === undefined) token = "" + page;
    const r = await __vbRun(script, [input, token]);
    const next = r.data2 === undefined || r.data2 === null ? "" : "" + r.data2;
    if (next && toks[page + 1] !== next) { toks[page + 1] = next; try { new SharedPreferences().setString(key, JSON.stringify(toks)); } catch (e) {} }
    const seen = new Set();
    const list = [];
    for (const it of (Array.isArray(r.data) ? r.data : [])) {
      if (!it || !it.name) continue;
      const link = __vbAbs(it.link, it.host);
      if (!link || seen.has(link)) continue;
      seen.add(link);
      list.push({ name: yhText("" + it.name), imageUrl: __vbAbs(it.cover, it.host), link });
    }
    return { list, hasNextPage: !!next && list.length > 0 };
  }

  async getPopular(page) {
    this._host();
    const tabs = await this._tabsAsync();
    if (tabs.length) return this._list(tabs[0].script, tabs[0].input || "", page);
    if (__vbHas("search")) return this._list((VB_PLUGIN.script || {}).search, "", page);
    return { list: [], hasNextPage: false };
  }
  async getLatestUpdates(page) {
    this._host();
    const tabs = await this._tabsAsync();
    const t = tabs[1] || tabs[0];
    if (t) return this._list(t.script, t.input || "", page);
    return this.getPopular(page);
  }
  async search(query, page, filters) {
    this._host();
    const pick = yhF(filters, "vb_tab");
    const genre = yhF(filters, "vb_genre");
    if ((!query || !query.trim()) && genre) { const g = JSON.parse(genre); return this._list(g.script, g.input || "", page); }
    if ((!query || !query.trim()) && pick) { const g = JSON.parse(pick); return this._list(g.script, g.input || "", page); }
    if (!__vbHas("search")) return { list: [], hasNextPage: false };
    return this._list((VB_PLUGIN.script || {}).search, query || "", page);
  }

  async getDetail(url) {
    this._host();
    url = __vbAbs(url);
    const d = (await __vbRun("detail", [url.replace(/\/+$/, "")])).data || {};
    const link = d.url === undefined || d.url === null ? url : __vbAbs(d.url);
    let pages = [link];
    if (__vbHas("page")) {
      try { const p = (await __vbRun("page", [link.replace(/\/+$/, "")])).data; if (Array.isArray(p) && p.length) pages = p.map((x) => __vbAbs(x)); } catch (e) { __vbLog("page: " + e); }
    }
    const chapters = [];
    for (const pu of pages) {
      let list = [];
      try { list = (await __vbRun("toc", [("" + pu).replace(/\/+$/, "")])).data || []; } catch (e) { if (!chapters.length) throw e; __vbLog("toc " + pu + ": " + e); }
      for (const c of list) {
        if (!c || c.type === "section" || !c.url) continue;
        chapters.push({ name: yhText("" + (c.name || "")) + (c.pay || c.lock ? " 🔒" : ""), url: __vbAbs(c.url, c.host), dateUpload: "", scanlator: "" });
      }
    }
    chapters.reverse();
    const genre = (Array.isArray(d.genres) ? d.genres : []).map((g) => (g && g.title ? yhText("" + g.title) : "")).filter((g) => g);
    const desc = [__vbPlain(d.description), __vbPlain(d.detail)].filter((s) => s).join("\n\n");
    return {
      name: yhText("" + (d.name || "")), imageUrl: __vbAbs(d.cover), author: yhText("" + (d.author || "")), artist: "",
      description: desc, genre, status: d.ongoing === false ? 1 : 0, link, chapters,
    };
  }

  async getPageList(url) {
    this._host();
    const r = await __vbRun("chap", [__vbAbs(url).replace(/\/+$/, "")]);
    const out = [];
    for (const im of (Array.isArray(r.data) ? r.data : [])) {
      let link = typeof im === "string" ? im : (im && (im.link || im.url)) || "";
      if (!link) continue;
      let pol = (im && im.referrerpolicy) || "";
      const hash = link.indexOf("#referrerpolicy=");
      if (hash >= 0) { pol = pol || link.slice(hash + 16); link = link.slice(0, hash); }
      const headers = { "User-Agent": YH_UA };
      if (pol !== "no-referrer") headers["Referer"] = pol === "origin" ? VB_HOST.replace(/\/+$/, "") + "/" : __vbAbs(url);
      out.push({ url: __vbAbs(link), headers });
    }
    return out;
  }

  async getHtmlContent(name, url) {
    this._host();
    const r = await __vbRun("chap", [__vbAbs(url).replace(/\/+$/, "")]);
    const html = typeof r.data === "string" ? r.data : (Array.isArray(r.data) ? r.data.join("<br>") : "");
    const title = r.data2 ? "" + r.data2 : name;
    return (title ? "<h2>" + title + "</h2>" : "") + html;
  }
  async cleanHtmlContent(html) { return html; }

  async getVideoList(url) {
    this._host();
    const r = await __vbRun("chap", [__vbAbs(url).replace(/\/+$/, "")]);
    const tracks = Array.isArray(r.data) ? r.data : (r.data ? [r.data] : []);
    const out = [];
    for (const t of tracks) {
      const data = t && typeof t === "object" ? (t.data !== undefined ? t.data : t.link) : t;
      const title = (t && t.title) || ("Server " + (out.length + 1));
      try {
        let v = { type: "native", data: data };
        if (__vbHas("track")) v = (await __vbRun("track", [typeof data === "string" ? data : JSON.stringify(data)])).data || v;
        const vu = __vbAbs(v.data, v.host);
        if (!vu) continue;
        const headers = Object.assign({ "User-Agent": YH_UA, "Referer": __vbAbs(url) }, v.headers || {});
        const subtitles = (Array.isArray(v.subtitles) ? v.subtitles : []).filter((s) => s && s.data).map((s) => ({ file: __vbAbs(s.data), label: s.label || s.language || "Sub" }));
        const audios = (Array.isArray(v.audios) ? v.audios : []).filter((s) => s && s.data).map((s) => ({ file: __vbAbs(s.data), label: s.label || s.language || "Audio" }));
        out.push({ url: vu, originalUrl: vu, quality: "" + title, headers, subtitles, audios });
      } catch (e) { __vbLog("track " + title + ": " + e); }
    }
    if (!out.length) throw new Error("vBook: không lấy được luồng phát nào từ " + url);
    return out;
  }

  getFilterList() {
    const f = [];
    const tabs = this._tabsSync();
    if (tabs.length) f.push({ type_name: "SelectFilter", type: "vb_tab", name: "Danh mục", state: 0,
      values: [{ type_name: "SelectOption", name: "—", value: "" }].concat(tabs.map((t) => ({ type_name: "SelectOption", name: "" + (t.title || t.name || ""), value: JSON.stringify({ script: t.script, input: t.input || "" }) }))) });
    let genres = [];
    try { const c = new SharedPreferences().getString(VB_KEY + "_genres", ""); if (c) genres = JSON.parse(c); } catch (e) {}
    if (!genres.length && __vbHas("genre")) { this._genres(); }
    if (genres.length) f.push({ type_name: "SelectFilter", type: "vb_genre", name: "Thể loại", state: 0,
      values: [{ type_name: "SelectOption", name: "—", value: "" }].concat(genres.filter((g) => g && g.script).map((g) => ({ type_name: "SelectOption", name: "" + (g.title || ""), value: JSON.stringify({ script: g.script, input: g.input || "" }) }))) });
    if (f.length) f.unshift({ type_name: "HeaderFilter", name: "Bộ lọc chỉ dùng khi ô tìm kiếm để trống" });
    return f;
  }

  getSourcePreferences() {
    const prefs = [yhDomainPref(VB_SOURCE_DEFAULT, "tiện ích vBook")];
    const cfg = VB_PLUGIN.config || {};
    for (const k of Object.keys(cfg)) {
      const c = cfg[k];
      if (!c || typeof c !== "object" || !/^[A-Za-z_$][A-Za-z0-9_$]*$/.test(k)) continue;
      const title = "" + (c.title || k);
      const def = c.default === undefined || c.default === null ? "" : "" + c.default;
      if (c.mode === "select" && Array.isArray(c.values) && c.values.length) {
        const vals = c.values.map((v) => "" + v);
        prefs.push({ key: "vbcfg_" + k, listPreference: { title, summary: "", valueIndex: Math.max(0, vals.indexOf(def)), entries: vals, entryValues: vals } });
      } else if (c.mode === "toggle") {
        prefs.push({ key: "vbcfg_" + k, checkBoxPreference: { title, summary: "" + (c.subtitle || ""), value: def === "true" } });
      } else if (c.mode === "input" || c.mode === "list") {
        prefs.push({ key: "vbcfg_" + k, editTextPreference: { title, summary: "" + (c.subtitle || ""), value: def, dialogTitle: title, dialogMessage: "", text: def } });
      }
    }
    return prefs;
  }
}
