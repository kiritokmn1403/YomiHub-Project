import 'dart:convert';
import 'dart:io';

import 'package:flutter_qjs/flutter_qjs.dart';
import 'package:http_interceptor/http_interceptor.dart';
import 'package:mangayomi/eval/http_response_extensions.dart';
import 'package:mangayomi/services/http/m_client.dart';
import 'package:mangayomi/yomihub/vpn/vpn_state.dart';
import 'package:mangayomi/repositories/source_repository.dart';
import 'package:http/http.dart' as http;
import 'package:mangayomi/yomihub/extensions/url_override.dart';

class JsHttpClient {
  late JavascriptRuntime runtime;
  // YomiHub: lets MClient apply the per-source Tor setting.
  final int? sourceId;
  final String? fallbackBaseUrl;
  JsHttpClient(this.runtime, {this.sourceId, this.fallbackBaseUrl});

  void init() {
    // MClient.init reads the settings row and builds a new interceptor stack;
    // doing that per request added measurable overhead to every source call.
    // Reuse one client per distinct request options for this runtime's life.
    final clientCache = <String, InterceptedClient>{};
    InterceptedClient client(dynamic reqcopyWith) {
      final map = <String, dynamic>{
        ...?(reqcopyWith as Map?)?.toMapStringDynamic,
        if (sourceId != null) 'yomihubSourceId': sourceId,
      };
      return clientCache.putIfAbsent(
        '${YomiVpnState.revision}|${jsonEncode(map)}',
        () => MClient.init(reqcopyWith: map),
      );
    }

    runtime.onMessage('http_head', (dynamic args) async {
      return await _toHttpResponse(client(args[1]), "HEAD", args, sourceId, fallbackBaseUrl);
    });
    runtime.onMessage('http_get', (dynamic args) async {
      return await _toHttpResponse(client(args[1]), "GET", args, sourceId, fallbackBaseUrl);
    });
    runtime.onMessage('http_post', (dynamic args) async {
      return await _toHttpResponse(client(args[1]), "POST", args, sourceId, fallbackBaseUrl);
    });
    runtime.onMessage('http_put', (dynamic args) async {
      return await _toHttpResponse(client(args[1]), "PUT", args, sourceId, fallbackBaseUrl);
    });
    runtime.onMessage('http_delete', (dynamic args) async {
      return await _toHttpResponse(client(args[1]), "DELETE", args, sourceId, fallbackBaseUrl);
    });
    runtime.onMessage('http_patch', (dynamic args) async {
      return await _toHttpResponse(client(args[1]), "PATCH", args, sourceId, fallbackBaseUrl);
    });
    runtime.evaluate('''
class Client {
    constructor(reqcopyWith) {
        this.reqcopyWith = reqcopyWith;
    }
    async head(url, headers) {
        headers = headers;
        const result = await sendMessage(
            "http_head",
            JSON.stringify([null, this.reqcopyWith, url, headers])
        );
        return JSON.parse(result);
    }
    async get(url, headers) {
        headers = headers;
        const result = await sendMessage(
            "http_get",
            JSON.stringify([null, this.reqcopyWith, url, headers])
        );
        return JSON.parse(result);
    }
    async post(url, headers, body) {
        headers = headers;
        const result = await sendMessage(
            "http_post",
            JSON.stringify([null, this.reqcopyWith, url, headers, body])
        );
        return JSON.parse(result);
    }
    async put(url, headers, body) {
        headers = headers;
        const result = await sendMessage(
            "http_post",
            JSON.stringify([null, this.reqcopyWith, url, headers, body])
        );
        return JSON.parse(result);
    }
    async delete(url, headers, body) {
        headers = headers;
        const result = await sendMessage(
            "http_post",
            JSON.stringify([null, this.reqcopyWith, url, headers, body])
        );
        return JSON.parse(result);
    }
    async patch(url, headers, body) {
        headers = headers;
        const result = await sendMessage(
            "http_post",
            JSON.stringify([null, this.reqcopyWith, url, headers, body])
        );
        return JSON.parse(result);
    }
}
''');
  }
}

Future<String> _toHttpResponse(Client client, String method, List args, [int? sourceId, String? fallbackBaseUrl]) async {
  var rawUrl = (args[2] as String? ?? '').trim();
  final rawHeaders = args.length > 3 ? args[3] : null;

  String? base;
  if (sourceId != null) {
    final s = sourceRepository.getById(sourceId);
    base = s?.baseUrl;
  }
  if ((base == null || base.isEmpty) && fallbackBaseUrl != null && fallbackBaseUrl.isNotEmpty) {
    base = fallbackBaseUrl;
  }

  final url = YomiUrlOverride.sanitizeUrl(
    rawUrl,
    baseUrl: base,
    headers: rawHeaders is Map ? rawHeaders : null,
  );
  // YomiHub 0.2.0: header values may arrive as arrays (set-cookie copied
  // from a response) – join them instead of sending "[a, b]".
  final headers = rawHeaders is Map
      ? <String, String>{
          for (final e in rawHeaders.entries)
            if (e.key != null && e.value != null)
              '${e.key}': e.value is List
                  ? (e.value as List).join(
                      '${e.key}'.toLowerCase() == 'cookie' ? '; ' : ', ')
                  : '${e.value}',
        }
      : null;
  final body = args.length >= 5
      ? args[4] is List
            ? args[4] as List
            : args[4] is String
            ? args[4] as String
            : (args[4] as Map?)?.toMapStringDynamic
      : null;
  var request = http.Request(method, Uri.parse(url));
  request.headers.addAll(headers ?? {});
  final isJson = (headers?.entries.any((e) =>
          e.key.toLowerCase() == 'content-type' &&
          e.value.toLowerCase().contains('application/json')) ??
      false) ||
      (request.headers[HttpHeaders.contentTypeHeader]?.contains(
            'application/json',
          ) ??
          false);
  if (isJson) {
    request.body = body is String ? body : json.encode(body);
    request.headers.addAll(headers ?? {});
    http.StreamedResponse response = await client.send(request);
    final res = Response(
      "",
      response.statusCode,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
    Map<String, dynamic> resMap = res.toJson();
    resMap["body"] = await response.stream.bytesToString();
    return jsonEncode(resMap);
  }
  final future = switch (method) {
    "HEAD" => client.head(Uri.parse(url), headers: headers),
    "GET" => client.get(Uri.parse(url), headers: headers),
    "POST" => client.post(Uri.parse(url), headers: headers, body: body),
    "PUT" => client.put(Uri.parse(url), headers: headers, body: body),
    "DELETE" => client.delete(Uri.parse(url), headers: headers, body: body),
    _ => client.patch(Uri.parse(url), headers: headers, body: body),
  };
  return jsonEncode((await future).toJson());
}
