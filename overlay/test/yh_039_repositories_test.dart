import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:http_interceptor/http_interceptor.dart';
import 'package:mangayomi/services/extension_store_service.dart';

void main() {
  test('empty v2 keeps usable legacy sources, including a UTF-8 BOM', () async {
    final client = InterceptedClient.build(
      interceptors: [],
      client: MockClient((r) async {
        if (r.url.path.endsWith('/repo.json')) {
          return http.Response(
            '{"name":"Fixture", "index_v2":"empty.json"}',
            200,
          );
        }
        if (r.url.path.endsWith('/empty.json')) {
          return http.Response(
            '{"name":"Empty","extensionList":{"extensions":[]}}',
            200,
          );
        }
        return http.Response(
          '\uFEFF  ${jsonEncode([
            {
              'name': 'Fixture',
              'pkg': 'eu.kanade.tachiyomi.extension.en.fixture',
              'version': '1.0',
              'code': 1,
              'lang': 'en',
              'nsfw': 0,
              'apk': 'fixture.apk',
              'sources': [
                {'id': '42', 'name': 'Fixture', 'lang': 'en', 'baseUrl': 'https://fixture.example'},
              ],
            },
          ])}',
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    addTearDown(client.close);
    final result = await ExtensionStoreService.fetchStore(
      'https://fixture.example/index.json',
      client,
    );
    expect(result?.sources, hasLength(1));
    expect(result?.sources.single.name, 'Fixture');
    expect(
      result?.sources.single.sourceCodeUrl,
      'https://fixture.example/apk/fixture.apk',
    );
  });

  test('cyclic repository redirects stop with no sources', () async {
    var requests = 0;
    final client = InterceptedClient.build(
      interceptors: [],
      client: MockClient((r) async {
        requests++;
        return http.Response('{"index_v2":"index.json"}', 200);
      }),
    );
    addTearDown(client.close);
    expect(
      await ExtensionStoreService.fetchStore(
        'https://fixture.example/index.json',
        client,
      ),
      isNull,
    );
    expect(requests, 1);
  });
}
