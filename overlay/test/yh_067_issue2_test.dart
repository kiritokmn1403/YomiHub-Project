import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/models/settings.dart';
import 'package:mangayomi/services/fetch_item_sources.dart';
import 'package:mangayomi/services/fetch_sources_list.dart';

void main() {
  group('Issue #2: sanitizeRepoUrl', () {
    test('strips user:pass, query, and fragment while keeping non-default port', () {
      expect(
        sanitizeRepoUrl('https://user:secret@example.com/repo/index.min.json?token=abc#section'),
        equals('https://example.com/repo/index.min.json'),
      );
      expect(
        sanitizeRepoUrl('https://user:pass@example.com/index.json'),
        equals('https://example.com/index.json'),
      );
      expect(
        sanitizeRepoUrl('https://example.com/index.json?foo=bar&x=1'),
        equals('https://example.com/index.json'),
      );
      expect(
        sanitizeRepoUrl('https://example.com/index.json#hash'),
        equals('https://example.com/index.json'),
      );
      expect(
        sanitizeRepoUrl('https://example.com:8443/index.json?a=1#b'),
        equals('https://example.com:8443/index.json'),
      );
      expect(
        sanitizeRepoUrl('https://example.com:443/index.json'),
        equals('https://example.com/index.json'),
      );
      expect(
        sanitizeRepoUrl('http://example.com:80/index.json'),
        equals('http://example.com/index.json'),
      );
    });

    test('handles clean URLs, null/empty inputs, and malformed URLs', () {
      expect(
        sanitizeRepoUrl('  https://raw.githubusercontent.com/org/ext/main/index.json  '),
        equals('https://raw.githubusercontent.com/org/ext/main/index.json'),
      );
      expect(sanitizeRepoUrl(null), equals(''));
      expect(sanitizeRepoUrl(''), equals(''));
      expect(sanitizeRepoUrl('   '), equals(''));
      expect(
        sanitizeRepoUrl('https://alice:pw@bad host/path?secret=1#frag'),
        equals('https://bad%20host/path'),
      );
    });
  });

  group('Issue #2: formatExtensionLogHeader', () {
    test('includes source id, version, and sanitized repo URL', () {
      final header = formatExtensionLogHeader(
        name: 'AVSub',
        id: 920260010,
        version: '1.2.3',
        lang: 'vi',
        engine: 'dart',
        repoName: 'YomiHub Extensions',
        repoUrl: 'https://user:pass@example.com/ext/index.min.json?key=123#top',
        serviceType: 'getVideoList',
        target: 'https://avsub.example/watch/1',
      );

      expect(header, contains('Extension "AVSub"'));
      expect(header, contains('id: 920260010'));
      expect(header, contains('v1.2.3'));
      expect(header, contains('vi'));
      expect(header, contains('engine: dart'));
      expect(header, contains('repo: YomiHub Extensions <https://example.com/ext/index.min.json>'));
      expect(header, isNot(contains('user:pass')));
      expect(header, isNot(contains('key=123')));
      expect(header, isNot(contains('#top')));
      expect(header, endsWith('getVideoList https://avsub.example/watch/1'));
    });

    test('falls back to Built-in/Local when repo is absent', () {
      final header = formatExtensionLogHeader(
        name: 'LocalSource',
        id: 42,
        version: 'v0.5.0',
        lang: 'en',
        engine: 'javascript',
        serviceType: 'search',
        target: 'one piece',
      );

      expect(header, contains('id: 42'));
      expect(header, contains('v0.5.0'));
      expect(header, isNot(contains('vv0.5.0')));
      expect(header, contains('repo: Built-in/Local'));
      expect(header, endsWith('search one piece'));
    });
  });

  group('Issue #2: classifyRepoError', () {
    test('classifies DNS, timeout, HTTP status, format, network, and other errors', () {
      final dns = classifyRepoError(const SocketException('Failed host lookup: repo.invalid'));
      expect(dns.kind, equals(RepoFailureKind.dns));
      expect(dns.shortReason, equals('DNS'));

      final timeout = classifyRepoError(TimeoutException('timed out after 25s'));
      expect(timeout.kind, equals(RepoFailureKind.timeout));
      expect(timeout.shortReason, equals('hết thời gian'));

      final http404 = classifyRepoError(const HttpException('Invalid repository response: HTTP 404'));
      expect(http404.kind, equals(RepoFailureKind.http));
      expect(http404.httpStatus, equals(404));
      expect(http404.shortReason, equals('HTTP 404'));

      final http451 = classifyRepoError(const HttpException('Repository removed: HTTP 451'));
      expect(http451.kind, equals(RepoFailureKind.http));
      expect(http451.httpStatus, equals(451));
      expect(http451.shortReason, equals('HTTP 451'));

      final http503 = classifyRepoError(Exception('statusCode: 503'));
      expect(http503.kind, equals(RepoFailureKind.http));
      expect(http503.httpStatus, equals(503));
      expect(http503.shortReason, equals('HTTP 503'));

      final fmt = classifyRepoError(const FormatException('Invalid repository index'));
      expect(fmt.kind, equals(RepoFailureKind.format));
      expect(fmt.shortReason, equals('định dạng sai'));

      final net = classifyRepoError(const SocketException('Connection refused'));
      expect(net.kind, equals(RepoFailureKind.network));
      expect(net.shortReason, equals('lỗi mạng'));

      final other = classifyRepoError(StateError('unexpected'));
      expect(other.kind, equals(RepoFailureKind.other));
      expect(other.shortReason, equals('StateError'));
    });
  });

  group('Issue #2: refreshExtensionReposDetailed & backwards compatibility', () {
    test('separates two failing repos on the same host with distinct labels and reasons', () async {
      final okRepo = Repo(
        name: 'Official',
        jsonUrl: 'https://good.example.com/index.min.json',
      );
      final sameHostA = Repo(
        name: 'Mirror A',
        jsonUrl: 'https://user:pw@raw.githubusercontent.com/alice/ext-a/main/index.min.json?t=1#a',
      );
      final sameHostB = Repo(
        name: 'Mirror B',
        jsonUrl: 'https://raw.githubusercontent.com/bob/ext-b/main/index.min.json?t=2#b',
      );

      Future<void> fetch(Repo repo) async {
        if (repo == sameHostA) {
          throw YomiLoggedError(const HttpException('Repository removed: HTTP 404'));
        }
        if (repo == sameHostB) {
          throw TimeoutException('Request timed out');
        }
      }

      final detailed = await refreshExtensionReposDetailed(
        [okRepo, sameHostA, sameHostB],
        fetch,
      );

      expect(detailed.ok, equals(1));
      expect(detailed.failed, equals(2));
      expect(detailed.failures.length, equals(2));

      final fA = detailed.failures[0];
      final fB = detailed.failures[1];

      expect(fA.repoLabel, isNot(equals(fB.repoLabel)));
      expect(fA.repoLabel, contains('alice/ext-a'));
      expect(fB.repoLabel, contains('bob/ext-b'));
      expect(fA.repoUrl, equals('https://raw.githubusercontent.com/alice/ext-a/main/index.min.json'));
      expect(fB.repoUrl, equals('https://raw.githubusercontent.com/bob/ext-b/main/index.min.json'));
      expect(fA.repoUrl, isNot(contains('user:pw')));
      expect(fA.shortReason, equals('HTTP 404'));
      expect(fA.httpStatus, equals(404));
      expect(fB.shortReason, equals('hết thời gian'));
      expect(fB.kind, equals(RepoFailureKind.timeout));

      final compat = await refreshExtensionRepos([okRepo, sameHostA, sameHostB], fetch);
      expect(compat, equals((ok: 1, failed: 2)));
    });
  });
}
