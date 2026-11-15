// 0.5.7 (S1): repository index (.pb) download - HTML/Cloudflare detection,
// one retry after a timeout, readable failure reason (logs 7: x.noz.one).
import 'dart:async';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart' as fixnum;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:http_interceptor/http_interceptor.dart';
import 'package:mangayomi/models/proto/mihon_extension_store.pb.dart';
import 'package:mangayomi/services/extension_store_service.dart';

List<int> _validIndex() => NetworkExtensionStore(
      name: 'Test Repo',
      extensionList: ExtensionStoreExtensionList(extensions: [
        ExtensionStoreItem(
          name: 'Tachiyomi: Test',
          packageName: 'eu.kanade.tachiyomi.extension.en.test',
          versionName: '1.4.1',
          sources: [
            ExtensionStoreSource(
              id: fixnum.Int64(42),
              name: 'Test',
              language: 'en',
              homeUrl: 'https://example.org',
            ),
          ],
        ),
      ]),
    ).writeToBuffer();

InterceptedClient _client(Future<http.Response> Function(http.Request) h) =>
    InterceptedClient.build(interceptors: const [], client: MockClient(h));

void main() {
  const url = 'https://mirror.example/yuzono/cursed/index.pb';
  setUp(() {
    ExtensionStoreService.lastFailure.clear();
    ExtensionStoreService.indexTimeout = const Duration(milliseconds: 120);
    ExtensionStoreService.indexRetryTimeout = const Duration(milliseconds: 300);
  });

  test('looksLikeHtml: Cloudflare / HTML pages yes, protobuf and JSON no', () {
    expect(ExtensionStoreService.looksLikeHtml('<!DOCTYPE html><html><head><title>Just a moment...</title>'.codeUnits), isTrue);
    expect(ExtensionStoreService.looksLikeHtml('  \n<html><body>x</body></html>'.codeUnits), isTrue);
    expect(ExtensionStoreService.looksLikeHtml(_validIndex()), isFalse);
    expect(ExtensionStoreService.looksLikeHtml('[{"a":1}]'.codeUnits), isFalse);
    expect(ExtensionStoreService.looksLikeHtml(const []), isFalse);
  });

  test('valid index.pb fixture parses (control)', () async {
    final r = await ExtensionStoreService.fetchStore(
      url,
      _client((_) async => http.Response.bytes(_validIndex(), 200)),
    );
    expect(r, isNotNull);
    expect(r!.sources.length, 1);
    expect(r.name, 'Test Repo');
    expect(ExtensionStoreService.lastFailure.containsKey(url), isFalse);
  });

  test('Cloudflare page: null + readable reason, not a parse error', () async {
    final page = '<!DOCTYPE html><html><head><title>Just a moment...</title></head>'
        '<body>Checking your browser (cloudflare)</body></html>';
    final r = await ExtensionStoreService.fetchStore(
      url,
      _client((_) async => http.Response(page, 200)),
    );
    expect(r, isNull);
    final f = ExtensionStoreService.lastFailure[url]!;
    expect(f.message, contains('Cloudflare'));
    expect(f.logged, isTrue);
  });

  test('plain HTML page (redirect / ISP block) gets the HTML reason', () async {
    final r = await ExtensionStoreService.fetchStore(
      url,
      _client((_) async => http.Response('<html><body>Blocked</body></html>', 200)),
    );
    expect(r, isNull);
    expect(ExtensionStoreService.lastFailure[url]!.message, contains('HTML'));
  });

  test('first attempt times out, the single retry succeeds', () async {
    var calls = 0;
    final r = await ExtensionStoreService.fetchStore(
      url,
      _client((_) {
        calls++;
        if (calls == 1) return Completer<http.Response>().future; // hangs
        return Future.value(http.Response.bytes(_validIndex(), 200));
      }),
    );
    expect(calls, 2);
    expect(r, isNotNull);
    expect(r!.sources, isNotEmpty);
  });

  test('both attempts time out: null, reason says it was retried', () async {
    var calls = 0;
    final r = await ExtensionStoreService.fetchStore(
      url,
      _client((_) {
        calls++;
        return Completer<http.Response>().future;
      }),
    );
    expect(calls, 2);
    expect(r, isNull);
    expect(ExtensionStoreService.lastFailure[url]!.message, contains('thử lại'));
  });

  test('garbage bytes (not protobuf): null with a reason', () async {
    final r = await ExtensionStoreService.fetchStore(
      url,
      _client((_) async => http.Response.bytes(Uint8List.fromList(List.filled(32, 0xFF)), 200)),
    );
    expect(r, isNull);
    expect(ExtensionStoreService.lastFailure[url], isNotNull);
  });

  test('HTTP 503 is reported with its status', () async {
    final r = await ExtensionStoreService.fetchStore(
      url,
      _client((_) async => http.Response('x', 404)),
    );
    expect(r, isNull);
    expect(ExtensionStoreService.lastFailure[url]!.message, contains('404'));
  });
}
