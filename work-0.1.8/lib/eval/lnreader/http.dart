import 'dart:convert';
import 'dart:io';

import 'package:flutter_qjs/flutter_qjs.dart';
import 'package:http_interceptor/http_interceptor.dart';
import 'package:mangayomi/services/http/m_client.dart';
import 'package:http/http.dart' as http;

/// LNReader `@libs/fetch` for YomiHub.
///
/// LNReader plugins call `fetchApi`, `fetchText` and (rarely) `fetchProto`.
/// Only `fetchApi` existed before and its Response had no `headers.get()`,
/// `arrayBuffer()` or `clone()`, so plugins using any of those failed before
/// they could return a chapter.
class JsHttpClient {
  late JavascriptRuntime runtime;
  final int? sourceId;
  final String? site;
  JsHttpClient(this.runtime, {this.sourceId, this.site});

  void init() {
    InterceptedClient client() {
      return MClient.init(
        reqcopyWith: sourceId == null ? null : {'yomihubSourceId': sourceId},
      );
    }

    for (final m in const ['HEAD', 'GET', 'POST', 'PUT', 'DELETE', 'PATCH']) {
      runtime.onMessage('http_${m.toLowerCase()}', (dynamic args) async {
        return await _toHttpResponse(client(), m, args, site);
      });
    }
    runtime.onMessage('yh_sleep', (dynamic args) async {
      final ms = (args is List && args.isNotEmpty ? args[0] : 0) as num? ?? 0;
      await Future.delayed(Duration(milliseconds: ms.toInt().clamp(0, 30000)));
      return true;
    });
    runtime.evaluate('''
class Headers {
  constructor(init) {
    this.map = {};
    if (init) {
      if (init instanceof Headers) init = init.map;
      if (Array.isArray(init)) { for (const [k, v] of init) this.map[String(k).toLowerCase()] = String(v); }
      else for (const k in init) this.map[k.toLowerCase()] = String(init[k]);
    }
    // Older plugins read headers like a plain object (res.headers['set-cookie']).
    for (const k in this.map) if (!(k in this)) this[k] = this.map[k];
  }
  get(k) { const v = this.map[String(k).toLowerCase()]; return v === undefined ? null : v; }
  has(k) { return String(k).toLowerCase() in this.map; }
  set(k, v) { this.map[String(k).toLowerCase()] = String(v); }
  append(k, v) { const key = String(k).toLowerCase(); this.map[key] = key in this.map ? this.map[key] + ', ' + v : String(v); }
  delete(k) { delete this.map[String(k).toLowerCase()]; }
  forEach(cb) { for (const k in this.map) cb(this.map[k], k, this); }
  entries() { return Object.entries(this.map)[Symbol.iterator](); }
  keys() { return Object.keys(this.map)[Symbol.iterator](); }
  values() { return Object.values(this.map)[Symbol.iterator](); }
  [Symbol.iterator]() { return this.entries(); }
  toJSON() { return this.map; }
}
class Response {
  constructor(url, result) {
    this.response = typeof result === 'string' ? JSON.parse(result) : result;
    this.url = this.response.url || url;
    this.headers = new Headers(this.response.headers || {});
  }
  get status() { return this.response.statusCode; }
  get statusText() { return this.response.reasonPhrase || ''; }
  get ok() { return this.status >= 200 && this.status <= 299; }
  get redirected() { return !!this.response.isRedirect; }
  get body() { return this.response.body; }
  get bodyUsed() { return false; }
  clone() { return new Response(this.url, this.response); }
  json() { const b = this.body; return new Promise(function (resolve, reject) { try { resolve(JSON.parse(b)); } catch (e) { reject(e); } }); }
  text() { const b = this.body; return Promise.resolve(b == null ? '' : b); }
  arrayBuffer() {
    const b64 = this.response.bodyBase64;
    if (b64) { const s = atob(b64); const u = new Uint8Array(s.length); for (let i = 0; i < s.length; i++) u[i] = s.charCodeAt(i); return Promise.resolve(u.buffer); }
    return Promise.resolve(new TextEncoder().encode(this.body || '').buffer);
  }
}
function __yhInit(init) {
  init = init || {};
  let headers = init.headers;
  if (headers instanceof Headers) headers = headers.map;
  let body = init.body;
  if (body instanceof FormData) body = { __form: body.entries_ };
  else if (body instanceof URLSearchParams) body = body.toString();
  return [headers || {}, body === undefined ? null : body, !!init.__binary];
}
async function fetchApi(url, init) {
  const method = init && init.method ? String(init.method).toLowerCase() : "get";
  const [headers, body, binary] = __yhInit(init);
  const result = await sendMessage("http_" + method, JSON.stringify([String(url), headers, body, binary]));
  return new Response(url, result);
}
async function fetchText(url, init, encoding) {
  const res = await fetchApi(url, init);
  if (!res.ok) return '';
  return await res.text();
}
async function fetchProto(protoInit, url, init) {
  throw new Error('fetchProto is not supported in YomiHub');
}
function setTimeout(fn, ms) {
  const args = Array.prototype.slice.call(arguments, 2);
  sendMessage("yh_sleep", JSON.stringify([ms || 0])).then(function () { try { fn.apply(null, args); } catch (e) { console.log(String(e)); } });
  return 1;
}
function clearTimeout() {}
''');
  }
}

Future<String> _toHttpResponse(
  Client client,
  String method,
  List args,
  String? site,
) async {
  final url = args[0] as String;
  final headers = <String, String>{};
  final rawHeaders = args.length > 1 ? args[1] : null;
  if (rawHeaders is Map) {
    rawHeaders.forEach((k, v) {
      if (k != null && v != null) headers['$k'] = '$v';
    });
  }
  final hasReferer = headers.keys.any((k) => k.toLowerCase() == 'referer');
  if (!hasReferer && site != null && site.isNotEmpty) headers['Referer'] = site;
  final rawBody = args.length > 2 ? args[2] : null;

  final request = http.Request(method, Uri.parse(url));
  request.headers.addAll(headers);
  final contentType = headers.entries
      .firstWhere(
        (e) => e.key.toLowerCase() == HttpHeaders.contentTypeHeader,
        orElse: () => const MapEntry('', ''),
      )
      .value;
  if (rawBody != null) {
    if (rawBody is Map && rawBody['__form'] is List) {
      // FormData → application/x-www-form-urlencoded (what the LNReader app
      // sends for plain text fields).
      final pairs = (rawBody['__form'] as List)
          .whereType<List>()
          .where((e) => e.length >= 2)
          .map(
            (e) =>
                '${Uri.encodeQueryComponent('${e[0]}')}=${Uri.encodeQueryComponent('${e[1]}')}',
          )
          .join('&');
      request.body = pairs;
      if (contentType.isEmpty) {
        request.headers['content-type'] =
            'application/x-www-form-urlencoded; charset=UTF-8';
      }
    } else if (rawBody is String) {
      request.body = rawBody;
    } else {
      request.body = jsonEncode(rawBody);
      if (contentType.isEmpty) {
        request.headers['content-type'] = 'application/json';
      }
    }
  }
  final response = await client.send(request);
  final bytes = await response.stream.toBytes();
  String body;
  try {
    body = utf8.decode(bytes);
  } catch (_) {
    body = latin1.decode(bytes);
  }
  final ct = response.headers['content-type'] ?? '';
  final isBinary = ct.startsWith('image/') ||
      ct.contains('octet-stream') ||
      ct.contains('protobuf');
  return jsonEncode({
    'url': response.request?.url.toString() ?? url,
    'statusCode': response.statusCode,
    'reasonPhrase': response.reasonPhrase,
    'isRedirect': response.isRedirect,
    'headers': response.headers,
    'body': isBinary ? '' : body,
    if (isBinary) 'bodyBase64': base64Encode(bytes),
  });
}
