// Wire-serialization helpers shared by the eval backends' JS-bridge HTTP
// glue (eval/javascript/http.dart, eval/lnreader/http.dart): turning a
// package:http Response into the JSON shape the JS side expects, and
// normalizing whatever key/value types come back from the JS runtime's
// maps. Pure data mapping, so unlike the rest of that glue - which differs
// per backend in argument order and client-caching strategy - this part is
// safe to share.
import 'package:http/http.dart';

extension ResponseExtexsion on Response {
  Map<String, dynamic> toJson() => {
    'body': body,
    'headers': headers,
    'isRedirect': isRedirect,
    'persistentConnection': persistentConnection,
    'reasonPhrase': reasonPhrase,
    'statusCode': statusCode,
    'request': {
      'contentLength': request?.contentLength,
      'finalized': request?.finalized,
      'followRedirects': request?.followRedirects,
      'headers': request?.headers,
      'maxRedirects': request?.maxRedirects,
      'method': request?.method,
      'persistentConnection': request?.persistentConnection,
      'url': request?.url.toString(),
    },
  };
}

extension ToMapExtension on Map? {
  Map<String, dynamic>? get toMapStringDynamic {
    return this?.map((key, value) => MapEntry(key.toString(), value));
  }

  /// YomiHub 0.2.2: list values (e.g. several cookies / set-cookie copied
  /// from a response) are joined instead of becoming "[a, b]" or failing a
  /// lazy `cast<String, String>()` later ("type 'List<dynamic>' is not a
  /// subtype of type 'String'").
  Map<String, String>? get toMapStringString {
    final m = this;
    if (m == null) return null;
    final out = <String, String>{};
    m.forEach((key, value) {
      if (key == null || value == null) return;
      final k = key.toString();
      out[k] = value is List
          ? value.join(k.toLowerCase() == 'cookie' ? '; ' : ', ')
          : value.toString();
    });
    return out;
  }
}
