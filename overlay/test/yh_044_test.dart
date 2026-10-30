import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mangayomi/yomihub/app_identity.dart';
import 'package:mangayomi/yomihub/booru/booru_api.dart';
import 'package:mangayomi/yomihub/booru/booru_models.dart';
import 'package:mangayomi/yomihub/extensions/ext_errors.dart';
import 'package:mangayomi/yomihub/extensions/url_override.dart';
import 'package:mangayomi/yomihub/vpn/vpn_state.dart';

BooruSite site(String id) => BooruSite.builtIn.firstWhere((s) => s.id == id);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('YomiHub 0.4.4', () {
    test('AppIdentity reports a 0.4.x version', () {
      expect(AppIdentity.userAgent, startsWith('YomiHub/0.4.'));
    });

    // ── log fixes (logs 1.txt) ──
    test('rhttp connection / proxy errors are network errors (no stack, warning)', () {
      const tunnel = 'RhttpConnectionException: Connection error. URL: https://www.pornhub.com/video '
          '(hyper_util::client::legacy::Error(Connect, TunnelUnsuccessful))';
      const refused = 'RhttpConnectionException: Connection error. URL: https://x '
          '(ConnectFailed(ConnectError("tcp connect error", 127.0.0.1:9, Os { code: 111 })))';
      expect(YomiExtErrors.isNetworkError(tunnel), isTrue);
      expect(YomiExtErrors.isNetworkError(refused), isTrue);
      expect(YomiExtErrors.hint(refused), contains('Tor'));
      expect(YomiExtErrors.hint(tunnel), contains('proxy'));
    });

    test('short() drops the native Dart stack dump embedded in toString()', () {
      const e = 'Connection error. URL: https://a\n*** *** *** *** ***\npid: 1, tid: 2, name 1.ui\n'
          'build_id: abc\n    #00 abs 0000006e1faca5db virt 0000000000cb65db';
      expect(YomiExtErrors.short(e), 'Connection error. URL: https://a');
    });

    test('kill switch still blocks while Tor is enabled but not running', () {
      YomiVpnState.torEnabled = true;
      YomiVpnState.torRunning = false;
      YomiVpnState.killSwitch = true;
      YomiVpnState.scopeAllSources = true;
      expect(YomiVpnState.proxyFor(1), 'http://127.0.0.1:9');
      YomiVpnState.torRunning = true;
      YomiVpnState.torHttpPort = 8118;
      expect(YomiVpnState.proxyFor(1), 'http://127.0.0.1:8118');
      YomiVpnState.torEnabled = false;
      YomiVpnState.torRunning = false;
    });

    test('Website Extension mirrors cover every URL of Phimmoi and MotPhim', () {
      expect(YomiUrlOverride.getMirrorsFor('https://phimmois.sh/phim/x'),
          containsAll(['https://phimmoii.mom', 'https://messiahelartista.com']));
      expect(YomiUrlOverride.getMirrorsFor('https://motchill10.io/phim-bo'),
          containsAll(['https://motphimc.my', 'https://motphim.website']));
    });

    // ── Booru App ──
    test('Booru: safe mode adds the right rating tag per API family', () {
      expect(BooruApi(MockClient((_) async => http.Response('[]', 200)))
          .postsUri(site('danbooru'), 'scenery', 1, safe: true).queryParameters['tags'], 'scenery rating:g');
      expect(BooruApi(MockClient((_) async => http.Response('[]', 200)))
          .postsUri(site('yandere'), '', 2, safe: true).queryParameters['tags'], 'rating:s');
      expect(BooruApi(MockClient((_) async => http.Response('[]', 200)))
          .postsUri(site('safebooru_org'), 'cat', 3, safe: true).queryParameters, containsPair('pid', '2'));
      expect(BooruApi(MockClient((_) async => http.Response('[]', 200)))
          .postsUri(site('danbooru'), 'cat rating:e', 1, safe: true).queryParameters['tags'], 'cat rating:e');
    });

    test('Booru: Danbooru JSON parses, gold-only posts without file_url are skipped', () {
      final posts = BooruApi.parsePosts(site('danbooru'), [
        {
          'id': 10, 'file_url': 'https://cdn.donmai.us/original/a.jpg', 'large_file_url': 'https://cdn.donmai.us/sample/a.jpg',
          'preview_file_url': 'https://cdn.donmai.us/preview/a.jpg', 'tag_string': 'cat 1girl', 'rating': 'g',
          'score': 5, 'image_width': 800, 'image_height': 600, 'source': 'https://pixiv.net/1',
        },
        {'id': 11, 'tag_string': 'banned'},
      ]);
      expect(posts, hasLength(1));
      expect(posts.first.tags, ['cat', '1girl']);
      expect(posts.first.rating, BooruRating.general);
      expect(posts.first.postUrl, 'https://danbooru.donmai.us/posts/10');
    });

    test('Booru: Safebooru JSON without file_url builds image + thumbnail URLs', () {
      final posts = BooruApi.parsePosts(site('safebooru_org'), [
        {'id': 7, 'directory': '4321', 'image': 'abc.png', 'hash': 'abc', 'tags': 'sky cloud', 'rating': 'safe', 'width': 10, 'height': 20},
      ]);
      expect(posts.single.fileUrl, 'https://safebooru.org/images/4321/abc.png');
      expect(posts.single.previewUrl, 'https://safebooru.org/thumbnails/4321/thumbnail_abc.jpg');
      expect(posts.single.isNsfw, isFalse);
    });

    test('Booru: Gelbooru {"post": [...]} wrapper and Moebooru / e621 shapes', () {
      final g = BooruApi.parsePosts(site('gelbooru'), {
        '@attributes': {'count': 1},
        'post': [
          {'id': 1, 'file_url': 'https://img.gelbooru.com/a.mp4', 'preview_url': 'https://img/p.jpg', 'tags': 'a b', 'rating': 'explicit'},
        ],
      });
      expect(g.single.isVideo, isTrue);
      expect(g.single.isNsfw, isTrue);
      final m = BooruApi.parsePosts(site('yandere'), [
        {'id': 2, 'file_url': 'https://files.yande.re/a.png', 'jpeg_url': 'https://files.yande.re/a.jpg', 'preview_url': 'https://p', 'tags': 'x', 'rating': 's'},
      ]);
      expect(m.single.sampleUrl, 'https://files.yande.re/a.jpg');
      final e = BooruApi.parsePosts(site('e926'), {
        'posts': [
          {
            'id': 3, 'file': {'url': 'https://static1.e926.net/a.webm', 'width': 1, 'height': 1},
            'preview': {'url': 'https://p'}, 'sample': {'url': null},
            'tags': {'general': ['fox'], 'species': ['canine']}, 'rating': 's', 'score': {'total': 9}, 'sources': ['https://s'],
          },
        ],
      });
      expect(e.single.tags, ['fox', 'canine']);
      expect(e.single.score, 9);
      expect(e.single.isVideo, isTrue);
    });

    test('Booru: HTML / auth pages become typed errors, JSON list works end-to-end', () async {
      final api = BooruApi(MockClient((r) async {
        if (r.url.host.contains('gelbooru')) return http.Response('<?xml version="1.0"?><response success="false" reason="Missing authentication"/>', 200);
        return http.Response(jsonEncode([
          {'id': 1, 'file_url': 'https://f/a.jpg', 'tag_string': 'a', 'rating': 'g'},
        ]), 200);
      }));
      expect(await api.posts(site('danbooru'), '', 1), hasLength(1));
      final cf = BooruApi(MockClient((r) async => r.url.host.contains('rule34')
          ? http.Response('"Missing authentication. Go to api.rule34.xxx for more information"', 200)
          : http.Response('<!DOCTYPE html><html><head><title>Just a moment...</title>', 403)));
      await expectLater(cf.posts(site('danbooru'), '', 1),
          throwsA(isA<BooruException>().having((e) => e.kind, 'kind', BooruError.cloudflare)));
      await expectLater(cf.posts(site('rule34'), '', 1),
          throwsA(isA<BooruException>().having((e) => e.kind, 'kind', BooruError.needsKey)));
      await expectLater(api.posts(site('gelbooru'), '', 1),
          throwsA(isA<BooruException>().having((e) => e.kind, 'kind', BooruError.needsKey)));
    });

    test('Booru: client filter hides 18+ when NSFW is off and blacklisted tags', () {
      BooruPost p(int id, String r, String tags) => BooruPost(
          siteId: 's', id: id, previewUrl: '', sampleUrl: '', fileUrl: 'u', tags: tags.split(' '),
          rating: parseBooruRating(r), score: 0, width: 0, height: 0, source: '', postUrl: '');
      final list = [p(1, 'g', 'a'), p(2, 'e', 'a'), p(3, 's', 'gore')];
      expect(BooruFilter.apply(list, showNsfw: false, blacklist: {'gore'}).map((e) => e.id), [1]);
      expect(BooruFilter.apply(list, showNsfw: true, blacklist: {}).length, 3);
    });

    test('Booru: favourites round-trip through JSON (backup format)', () {
      final post = BooruApi.parsePosts(site('danbooru'), [
        {'id': 5, 'file_url': 'https://f/x.gif', 'tag_string': 'a b', 'rating': 'q', 'score': 2},
      ]).single;
      final back = BooruPost.fromJson(jsonDecode(jsonEncode(post.toJson())) as Map);
      expect(back.id, 5);
      expect(back.tags, ['a', 'b']);
      expect(back.rating, BooruRating.questionable);
      expect(back.isGif, isTrue);
    });

    test('Booru: tag autocomplete parsers (Danbooru / Gelbooru / e621)', () {
      expect(BooruApi.parseTags([
        {'value': 'cat_ears', 'post_count': 10},
        {'value': 'cat', 'post_count': 99},
      ]).first.name, 'cat');
      expect(BooruApi.parseTags({'tag': [{'name': 'sky', 'count': 3}]}).single.count, 3);
      // safebooru.org autocomplete.php (real response shape, 29/10/2026)
      final sb = BooruApi.parseTags([
        {'label': 'scene_reference (6196)', 'value': 'scene_reference'},
        {'label': 'scenery (65943)', 'value': 'scenery'},
      ]);
      expect(sb.first.name, 'scenery');
      expect(sb.first.count, 65943);
    });

    test('Booru: NSFW-only boards are hidden from the default site list', () {
      final safe = BooruSite.builtIn.where((s) => !s.nsfwOnly).map((s) => s.id);
      expect(safe, isNot(contains('rule34')));
      expect(safe.first, 'safebooru_org');
    });
  });
}
