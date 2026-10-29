import 'package:http/http.dart';
import 'package:mangayomi/services/http/rhttp/rhttp.dart';
import 'package:mangayomi/src/rust/api/rhttp/http.dart' as rust;
import 'package:mangayomi/yomihub/extensions/url_override.dart';

/// An HTTP client that is compatible with the `http` package.
/// This minimizes the changes needed to switch from `http` to `rhttp`
/// and also avoids vendor lock-in.
///
/// This comes with some downsides, such as:
/// - inferior type safety due to the flaw that `body` is of type `Object?`
///   instead of a sane supertype.
/// - body of type [Map] is implicitly interpreted as `x-www-form-urlencoded`
///   that is only documented in StackOverflow (as of writing this).
/// - no support for cancellation
/// - no out-of-the-box support for multipart requests
class RhttpCompatibleClient with BaseClient {
  /// The actual client that is used to make requests.
  RhttpClient client;
  final ClientSettings? _settings;

  RhttpCompatibleClient._(this.client, [this._settings]);

  /// Use this method if your app is starting up to simplify the code
  /// that might arise by using async/await.
  ///
  /// Note:
  /// This method crashes when configured to use HTTP/3.
  /// See: https://github.com/Tienisto/rhttp/issues/10
  factory RhttpCompatibleClient.createSync({ClientSettings? settings}) {
    final client = RhttpClient.createSync(
      settings: (settings ?? const ClientSettings()).digest(),
    );
    return RhttpCompatibleClient._(client, settings);
  }

  void _ensureActive() {
    if (client.ref.isDisposed) {
      client = RhttpClient.createSync(
        settings: (_settings ?? const ClientSettings()).digest(),
      );
    }
  }

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    _ensureActive();
    final CancelToken? cancelToken;
    switch (request) {
      case Abortable(abortTrigger: final trigger?):
        cancelToken = CancelToken();
        trigger.then((_) {
          cancelToken?.cancel();
        });
        break;
      case _:
        cancelToken = null;
    }
    final targetUrl = YomiUrlOverride.sanitizeUrl(
      request.url.toString(),
      headers: request.headers,
    );
    try {
      final response = await client.requestStream(
        method: switch (request.method) {
          'GET' => rust.HttpMethod.get_,
          'POST' => rust.HttpMethod.post,
          'PUT' => rust.HttpMethod.put,
          'PATCH' => rust.HttpMethod.patch,
          'DELETE' => rust.HttpMethod.delete,
          'HEAD' => rust.HttpMethod.head,
          'OPTIONS' => rust.HttpMethod.options,
          'TRACE' => rust.HttpMethod.trace,
          'CONNECT' => rust.HttpMethod.connect,
          _ => throw ArgumentError('Unsupported method: ${request.method}'),
        },
        url: targetUrl,
        headers: rust.HttpHeaders.map(request.headers),
        body: await request.finalize().toBytes(),
        cancelToken: cancelToken,
      );

      final responseHeaderMap = response.headerMap;

      return StreamedResponse(
        response.body.handleError((e, st) {
          if (e is RhttpException) {
            if (e is RhttpCancelException) {
              Error.throwWithStackTrace(
                RhttpWrappedRequestAbortedException(request.url, e),
                st,
              );
            }
            Error.throwWithStackTrace(
              RhttpWrappedClientException(e.toString(), request.url, e),
              st,
            );
          }
          Error.throwWithStackTrace(
            ClientException(e.toString(), request.url),
            st,
          );
        }),
        response.statusCode,
        contentLength: switch (responseHeaderMap['content-length']) {
          String s => int.parse(s),
          null => null,
        },
        request: request,
        headers: responseHeaderMap,
        isRedirect: false,
        persistentConnection: true,
        reasonPhrase: null,
      );
    } on RhttpException catch (e, st) {
      if (e is RhttpCancelException) {
        Error.throwWithStackTrace(
          RhttpWrappedRequestAbortedException(request.url, e),
          st,
        );
      }
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('brotli')) {
        try {
          final fallbackClient = Client();
          final fallbackReq = Request(request.method, Uri.parse(targetUrl))
            ..headers.addAll(request.headers);
          fallbackReq.headers['accept-encoding'] = 'gzip, deflate';
          return await fallbackClient.send(fallbackReq);
        } catch (_) {}
      }
      Error.throwWithStackTrace(
        RhttpWrappedClientException(e.toString(), request.url, e),
        st,
      );
    } catch (e, st) {
      Error.throwWithStackTrace(ClientException(e.toString(), request.url), st);
    }
  }

  @override
  void close() {
    // Keep client alive for connection reuse across shared requests
  }
}

/// Every exception must be a subclass of [ClientException]
/// as per contract of [BaseClient].
class RhttpWrappedClientException extends ClientException {
  /// YomiHub 0.2.7: store string details instead of raw RhttpException to prevent
  /// unsendable RustArc objects from leaking into isolate SendPort messages.
  final String _errorDetails;

  RhttpWrappedClientException(super.message, super.uri, [RhttpException? ex])
      : _errorDetails = ex != null ? ex.toString() : '';

  @override
  String toString() => _errorDetails.isNotEmpty ? _errorDetails : message;
}

class RhttpWrappedRequestAbortedException extends RequestAbortedException {
  final String _errorDetails;

  RhttpWrappedRequestAbortedException(super.uri, [RhttpException? ex])
      : _errorDetails = ex != null ? ex.toString() : '';

  @override
  String toString() => _errorDetails.isNotEmpty ? _errorDetails : 'Request was aborted';
}

extension on ClientSettings {
  /// Makes sure that the settings conform to the requirements of [BaseClient].
  ClientSettings digest() {
    ClientSettings settings = this;
    if (throwOnStatusCode) {
      settings = settings.copyWith(throwOnStatusCode: false);
    }

    return settings;
  }
}
