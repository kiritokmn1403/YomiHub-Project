import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/yomihub/about/github_projects.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mangayomi/eval/model/filter.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/models/source.dart';
import 'package:mangayomi/yomihub/cloud/cloud_backup_service.dart';
import 'package:mangayomi/services/http/m_client.dart';
import 'package:mangayomi/yomihub/player/yomi_shorts.dart';
import 'package:mangayomi/yomihub/net/gh_mirror.dart';
import 'package:mangayomi/yomihub/cloudflare/clearance_cookie.dart';
import 'package:mangayomi/yomihub/player/rejected_seek.dart';

void main() {
  test('a Cloudflare challenge without a UI raises an error instead of returning HTML', () async {
    final response = http.Response('<title>Just a moment</title>', 403,
        headers: {'server': 'cloudflare', 'cf-mitigated': 'challenge'},
        request: http.Request('GET', Uri.parse('https://example.invalid/private')));
    await expectLater(LoggerInterceptor(true).interceptResponse(response: response),
        throwsA(isA<HttpException>()
            .having((e) => e.message, 'reason', contains('Giải CloudFlare thất bại'))
            .having((e) => e.message, 'status', contains('403'))
            .having((e) => e.toString(), 'sensitive URL', isNot(contains('/private')))));
    expect(await LoggerInterceptor(false).interceptResponse(response: response), same(response));
  });
  test('Telegram never substitutes another chat after the selected chat is rejected', () async {
    final methods = <String>[];
    final provider = TelegramProvider(client: MockClient((request) async {
      final method = request.url.pathSegments.last;
      methods.add(method);
      if (method == 'getMe') return http.Response('{"ok":true}', 200);
      expect(method, 'getChat');
      return http.Response('{"ok":false,"description":"Bad Request: chat not found"}', 400);
    }))..config = {'token': 'fixture', 'chat_id': 'selected'};
    await expectLater(provider.completeAuth(), throwsA(predicate(
        (e) => e.toString().contains('Chat ID') && e.toString().contains('/start'))));
    expect(methods, ['getMe', 'getChat']);
    expect(provider.config['chat_id'], 'selected');
    expect(provider.isConnected, isFalse);
  });
  testWidgets('a secondary project link can be found and selected', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: GithubProjectsScreen()));
    await tester.enterText(find.byType(TextField), 'kotatsu-syncserver');
    await tester.pumpAndSettle();
    final menu = find.byType(PopupMenuButton<String>);
    await tester.ensureVisible(menu);
    await tester.tap(menu);
    await tester.pumpAndSettle();
    final options = tester.widgetList<PopupMenuItem<String>>(find.byType(PopupMenuItem<String>));
    expect(options.map((o) => o.value), contains('https://github.com/KotatsuApp/kotatsu-syncserver'));
  });
  test('a mirror receives only headers appropriate to a public CDN', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      return requests.length == 1 ? http.Response('', 503) : http.Response('[]', 200);
    });
    final response = await GhMirror.get(client,
        Uri.parse('https://raw.githubusercontent.com/o/r/main/index.json'),
        headers: {'Cookie': 'lang=vi', 'Accept': 'application/json'});
    expect(response.statusCode, 200);
    expect(requests, hasLength(2));
    expect(requests.last.headers.containsKey('cookie'), isFalse);
    expect(requests.last.headers['accept'], 'application/json');
  });
  test('an unrecognized video extension can expose its Shorts search filter', () {
    final filter = SelectFilter('feed', 'Feed', 0, [
      SelectFilterOption('All', '0', null),
      SelectFilterOption('Shorts', '7', null),
    ], null);
    expect(YomiShorts.shortsOption(filter), 1);
    expect(YomiShorts.supports(Source(itemType: ItemType.anime), filters: [filter]), isTrue);
    expect(YomiShorts.supports(Source(itemType: ItemType.novel), filters: [filter]), isFalse);
    expect(YomiShorts.supports(Source(itemType: ItemType.anime)), isFalse);
  });
  test('Telegram validates an empty destination before opening the backup', () async {
    final provider = TelegramProvider()..config = {'token': 'fixture', 'chat_id': '  '};
    expect(provider.isConnected, isFalse);
    await expectLater(provider.upload(File('does-not-exist.backup')),
        throwsA(predicate((e) => e.toString().contains('Chat ID'))));
  });
  test('GitHub refs/heads links resolve to the same CDN file as raw links', () {
    final raw = Uri.parse('https://raw.githubusercontent.com/org/repo/main/a%23b');
    final github = Uri.parse('https://github.com/org/repo/raw/refs/heads/main/a%23b');
    expect(GhMirror.mirrorsOf(github), GhMirror.mirrorsOf(raw));
    expect(GhMirror.mirrorsOf(raw).first.pathSegments.last, 'a#b');
    expect(GhMirror.mirrorsOf(Uri.parse('https://github.com/o/r/raw/refs/heads')), isEmpty);
  });
  test('a retry replaces stale clearance and preserves the extension cookies', () {
    expect(mergeClearanceCookie('lang=vi; cf_clearance=old', 'cf_clearance=new'),
        'lang=vi; cf_clearance=new');
    expect(mergeClearanceCookie('lang=vi', 'a=b'), 'lang=vi');
    expect(mergeClearanceCookie('', 'a=b'), 'a=b');
  });
  group('rejected seek', () {
    test('recognizes the mpv stream diagnostic without logging media URLs', () {
      expect(
        rejectedSeekReason('mpv: CANNOT SEEK IN THIS STREAM. https://media.invalid/private'),
        'Cannot seek in this stream',
      );
    });
    test('recognizes shorter and force-seekable diagnostics', () {
      expect(rejectedSeekReason('Exception: cannot seek'), 'Cannot seek');
      expect(rejectedSeekReason('mpv: try --force-seekable'), 'force-seekable');
    });
    test('leaves decoder and network failures to their own handlers', () {
      expect(rejectedSeekReason('Could not open codec'), isNull);
      expect(rejectedSeekReason('Connection timed out'), isNull);
    });
  });
}
