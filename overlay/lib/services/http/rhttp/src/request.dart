import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mangayomi/services/http/rhttp/src/model/exception.dart';
import 'package:mangayomi/services/http/rhttp/src/model/request.dart';
import 'package:mangayomi/services/http/rhttp/src/model/response.dart';
import 'package:mangayomi/services/http/rhttp/src/model/settings.dart';
import 'package:mangayomi/src/rust/api/rhttp/error.dart' as rust_error;
import 'package:mangayomi/src/rust/api/rhttp/http.dart' as rust;
import 'package:mangayomi/src/rust/lib.dart' as rust_lib;

/// Non-Generated helper function that is used by
/// the client and also by the static class.

Future<HttpResponse> requestInternalGeneric(HttpRequest request) async {
  if (request.client?.ref.isDisposed ?? false) {
    throw RhttpClientDisposedException(request);
  }

  var url = switch (request.settings?.baseUrl) {
    String baseUrl => baseUrl + request.url,
    null => request.url,
  };

  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    if (url.startsWith('//')) {
      url = 'https:$url';
    } else {
      String fallback = 'https://hentaivn.gold';
      String? findHeader(String key) {
        final k = key.toLowerCase();
        if (request.headers is rust.HttpHeaders_Map) {
          final m = (request.headers as rust.HttpHeaders_Map).field0;
          for (final entry in m.entries) {
            if (entry.key.toLowerCase() == k && entry.value.trim().isNotEmpty) return entry.value.trim();
          }
        } else if (request.headers is rust.HttpHeaders_List) {
          final list = (request.headers as rust.HttpHeaders_List).field0;
          for (final item in list) {
            if (item.$1.toLowerCase() == k && item.$2.trim().isNotEmpty) return item.$2.trim();
          }
        }
        return null;
      }
      final hostHeader = findHeader('host');
      final refererHeader = findHeader('referer') ?? findHeader('origin');
      if (hostHeader != null && hostHeader.isNotEmpty) {
        fallback = 'https://$hostHeader';
      } else if (refererHeader != null && refererHeader.isNotEmpty) {
        final uri = Uri.tryParse(refererHeader);
        if (uri != null && uri.host.isNotEmpty) {
          fallback = '${uri.scheme.isNotEmpty ? uri.scheme : "https"}://${uri.host}';
        }
      }
      url = '$fallback${url.startsWith('/') ? '' : '/'}$url';
    }
  }

  try {
    final cancelRefCompleter = Completer<rust_lib.CancellationToken>();
    final responseCompleter = Completer<rust.HttpResponse>();
    Stream<Uint8List> stream = rust.makeHttpRequestReceiveStream(
      client: request.client?.ref,
      settings: request.settings?.toRustType(),
      method: request.method,
      url: url,
      query: request.query?.entries.map((e) => (e.key, e.value)).toList(),
      headers: request.headers,
      body: request.body,
      onResponse: (r) => responseCompleter.complete(r),
      onError: (e) => responseCompleter.completeError(e),
      onCancelToken: (cancelRef) => cancelRefCompleter.complete(cancelRef),
      cancelable: request.cancelToken != null,
    );

    final cancelToken = request.cancelToken;
    if (cancelToken != null) {
      final cancelRef = await cancelRefCompleter.future;
      cancelToken.setRef(cancelRef);
    }

    final rustResponse = await responseCompleter.future;

    HttpResponse response = parseHttpResponse(
      request,
      rustResponse,
      bodyStream: stream,
    );

    return response;
  } catch (e, st) {
    if (e is rust_error.RhttpError) {
      RhttpException exception = parseError(request, e);
      Error.throwWithStackTrace(exception, st);
    } else {
      rethrow;
    }
  }
}
