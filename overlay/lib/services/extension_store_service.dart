import 'dart:async';
import 'package:mangayomi/yomihub/ireader/ireader_bridge.dart';
import 'package:mangayomi/yomihub/net/gh_mirror.dart';

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:http_interceptor/http_interceptor.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/models/proto/mihon_extension_store.pb.dart';
import 'package:mangayomi/models/source.dart';
import 'package:mangayomi/utils/log/logger.dart';
import 'package:mangayomi/yomihub/extensions/ext_errors.dart';
import 'package:fixnum/fixnum.dart' as fixnum;

class ExtensionStoreFetchResult {
  final String name;
  final String? website;
  final String indexUrl;
  final List<Source> sources;

  ExtensionStoreFetchResult({
    required this.name,
    this.website,
    required this.indexUrl,
    required this.sources,
  });
}

class ExtensionStoreService {
  /// 0.4.3: large indexes (keiyoushi, aniyomi…) are decoded off the UI isolate.
  static Future<dynamic> _decodeJsonBytes(List<int> bytes) {
    if (bytes.length < 64 * 1024) {
      return Future.value(jsonDecode(utf8.decode(bytes, allowMalformed: true)));
    }
    final copy = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    return Isolate.run(() => jsonDecode(utf8.decode(copy, allowMalformed: true)));
  }

  static List<int> _decompressIfGzipped(List<int> bytes) {
    if (bytes.length >= 2 && bytes[0] == 0x1F && bytes[1] == 0x8B) {
      try {
        return gzip.decode(bytes);
      } catch (_) {
        return bytes;
      }
    }
    return bytes;
  }

  /// Fetches store info and extension sources from [indexUrl].
  /// Supports:
  /// 1. Protobuf (.pb) binary index payloads.
  /// 2. JSON index payloads (NetworkExtensionStore or NetworkLegacyExtensionRepo).
  /// 3. Legacy index.min.json payloads.
  static Future<ExtensionStoreFetchResult?> fetchStore(
    String indexUrl,
    InterceptedClient client, {
    Set<String>? visited,
  }) async {
    try {
      visited ??= <String>{};
      if (visited.length >= 8 || !visited.add(indexUrl)) {
        throw StateError('Extension repository redirect loop: $indexUrl');
      }
      var currentUrl = indexUrl;
      final response = await GhMirror.get(client, Uri.parse(currentUrl));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        return null;
      }

      var bytes = _decompressIfGzipped(response.bodyBytes);
      if (bytes.isEmpty) return null;

      // JSON may contain a UTF-8 BOM or leading whitespace. Do not strip
      // arbitrary protobuf bytes (its first tag can also be a newline).
      // 0.4.3: only the first bytes are inspected – decoding a multi-MB
      // protobuf index as text on the UI isolate caused visible stalls.
      var start = 0;
      if (bytes.length >= 3 &&
          bytes[0] == 0xEF &&
          bytes[1] == 0xBB &&
          bytes[2] == 0xBF) {
        start = 3;
      }
      var j = start;
      while (j < bytes.length &&
          (bytes[j] == 0x20 ||
              bytes[j] == 0x0A ||
              bytes[j] == 0x0D ||
              bytes[j] == 0x09)) {
        j++;
      }
      if (j < bytes.length && (bytes[j] == 0x5B || bytes[j] == 0x7B)) {
        if (j > 0) bytes = bytes.sublist(j);
      }
      if (bytes.isEmpty) return null;

      final firstByte = bytes[0];

      // 1. Legacy JSON array: Starts with '[' (0x5B)
      if (firstByte == 0x5B) {
        String? repoName;
        String? repoWebsite;
        final baseUrlMatch = RegExp(r'^(.*)/[^/]+\.json$')
            .firstMatch(currentUrl);
        final baseUrl = baseUrlMatch != null
            ? baseUrlMatch.group(1)!
            : currentUrl;
        try {
          final repoRes = await GhMirror.get(
            client,
            Uri.parse('$baseUrl/repo.json'),
          );
          if (repoRes.statusCode == 200) {
            final repoJson = jsonDecode(repoRes.body);
            if (repoJson is Map) {
              if (repoJson['index_v2'] != null &&
                  (repoJson['index_v2'] as String).isNotEmpty) {
                // Redirect to V2 index (.pb or JSON store)
                final redirected = await fetchStore(
                  Uri.parse(currentUrl)
                      .resolve(repoJson['index_v2'] as String)
                      .toString(),
                  client,
                  visited: visited,
                );
                if (redirected != null && redirected.sources.isNotEmpty)
                  return redirected;
              }
              repoName =
                  (repoJson['meta']?['name'] ?? repoJson['name']) as String?;
              repoWebsite =
                  (repoJson['meta']?['website'] ?? repoJson['website'])
                      as String?;
            }
          }
        } catch (e, st) {
          // Falls through to the legacy parser, so a broken v2 redirect or repo.json
          // lookup just falls back to default inference.
          // 0.4.4: a dropped connection here is not an app fault (it falls
          // back to the legacy parser): one warning line, no stack.
          final net = YomiExtErrors.isNetworkError(e) || e is TimeoutException;
          AppLogger.log(
            net
                ? 'fetchStore: repo.json không tải được (${YomiExtErrors.short(e)}) – dùng chỉ mục thường'
                : 'fetchStore: repo.json check failed: $e\n$st',
            logLevel: net ? LogLevel.warning : LogLevel.error,
          );
        }
        return await _parseLegacyJsonStore(
          currentUrl,
          bytes,
          name: repoName,
          website: repoWebsite,
        );
      }

      // 2. JSON object: Starts with '{' (0x7B)
      if (firstByte == 0x7B) {
        final jsonMap = await _decodeJsonBytes(bytes);
        if (jsonMap is Map<String, dynamic>) {
          // Check for index_v2 redirect in legacy repo JSON
          if (jsonMap['index_v2'] != null &&
              (jsonMap['index_v2'] as String).isNotEmpty) {
            return await fetchStore(
              Uri.parse(currentUrl)
                  .resolve(jsonMap['index_v2'] as String)
                  .toString(),
              client,
              visited: visited,
            );
          }

          // Try parsing JSON NetworkExtensionStore
          return await _parseJsonNetworkStore(currentUrl, jsonMap, client);
        }
      }

      // 3. Binary Protobuf: NetworkExtensionStore
      return await _parseProtobufStore(currentUrl, bytes, client);
    } catch (error) {
      final e = '$error';
      if (e.contains('Failed host lookup') || e.contains('SocketException')) {
        // 0.4.3: no network / DNS blocked – one short line per host and
        // session instead of an error for every repository.
        final host = Uri.tryParse(indexUrl)?.host ?? indexUrl;
        AppLogger.logOnce(
          'store-offline:$host',
          '[Kho tiện ích] Không kết nối được $host (không có mạng hoặc DNS bị chặn) – sẽ thử lại khi có mạng',
          logLevel: LogLevel.warning,
        );
      } else {
        // 0.4.3: once per repository and session (the same failure used to
        // be written 3× per start-up: store refresh, source list, badge).
        // 0.4.4: a dropped connection (kohiden.xyz "Connection closed before
        // full header", 29/10) is the server's problem: warning, not error.
        final net = YomiExtErrors.isNetworkError(error) || e.contains('Connection closed');
        AppLogger.logOnce(
          'store-fail:$indexUrl',
          '[Kho tiện ích] Không tải được kho $indexUrl: ${e.length > 200 ? e.substring(0, 200) : e}',
          logLevel: net ? LogLevel.warning : LogLevel.error,
        );
      }
      return null;
    }
  }

  static Future<ExtensionStoreFetchResult?> _parseProtobufStore(
    String indexUrl,
    List<int> bytes,
    InterceptedClient client,
  ) async {
    try {
      final store = NetworkExtensionStore.fromBuffer(bytes);
      final repoName = store.name.isNotEmpty ? store.name : 'Mihon Repo';
      final website = store.hasField(4) && store.contact.website.isNotEmpty
          ? store.contact.website
          : null;

      List<ExtensionStoreItem> extensionItems = [];

      if (store.hasField(101) && store.extensionList.extensions.isNotEmpty) {
        extensionItems = store.extensionList.extensions;
      } else if (store.extensionListUrl.isNotEmpty) {
        final resolvedListUrl = Uri.parse(indexUrl)
            .resolve(store.extensionListUrl)
            .toString();
        final listRes = await GhMirror.get(client, Uri.parse(resolvedListUrl));
        if (listRes.statusCode == 200 && listRes.bodyBytes.isNotEmpty) {
          final listBytes = _decompressIfGzipped(listRes.bodyBytes);
          if (listBytes.isNotEmpty && listBytes[0] == 0x7B) {
            // JSON extension list
            final jsonList = await _decodeJsonBytes(listBytes);
            if (jsonList is Map && jsonList['extensions'] is List) {
              for (final extJson in jsonList['extensions']) {
                extensionItems.add(_extensionItemFromJson(extJson));
              }
            }
          } else if (listBytes.isNotEmpty) {
            // Protobuf ExtensionStoreExtensionList
            final extListProto = ExtensionStoreExtensionList.fromBuffer(
              listBytes,
            );
            extensionItems = extListProto.extensions;
          }
        }
      }

      final sources = _convertProtobufExtensionsToSources(
        indexUrl,
        extensionItems,
      );

      return ExtensionStoreFetchResult(
        name: repoName,
        website: website,
        indexUrl: indexUrl,
        sources: sources,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<ExtensionStoreFetchResult?> _parseJsonNetworkStore(
    String indexUrl,
    Map<String, dynamic> jsonMap,
    InterceptedClient client,
  ) async {
    try {
      // 1. Check if it's an Aidoku format repository index (e.g. index.min.json with "sources": [...])
      if (jsonMap['sources'] is List) {
        final aidokuResult = _parseAidokuJsonStore(indexUrl, jsonMap);
        if (aidokuResult != null && aidokuResult.sources.isNotEmpty) {
          return aidokuResult;
        }
      }

      final meta = jsonMap['meta'] as Map<String, dynamic>?;
      final repoName =
          (meta?['name'] as String?) ??
          (jsonMap['name'] as String?) ??
          'Mihon Repo';
      final website =
          (meta?['website'] as String?) ??
          (jsonMap['contact']?['website'] as String?);

      List<dynamic> rawExtensions = [];

      if (jsonMap['extensionList']?['extensions'] is List) {
        rawExtensions = jsonMap['extensionList']['extensions'] as List;
      } else if (jsonMap['extensionListUrl'] is String &&
          (jsonMap['extensionListUrl'] as String).isNotEmpty) {
        final listUrl = Uri.parse(indexUrl)
            .resolve(jsonMap['extensionListUrl'] as String)
            .toString();
        final listRes = await GhMirror.get(client, Uri.parse(listUrl));
        if (listRes.statusCode == 200) {
          final listBytes = _decompressIfGzipped(listRes.bodyBytes);
          final jsonList = await _decodeJsonBytes(listBytes);
          if (jsonList is Map && jsonList['extensions'] is List) {
            rawExtensions = jsonList['extensions'] as List;
          }
        }
      }

      final sources = _convertJsonExtensionsToSources(indexUrl, rawExtensions);

      return ExtensionStoreFetchResult(
        name: repoName,
        website: website,
        indexUrl: indexUrl,
        sources: sources,
      );
    } catch (_) {
      return null;
    }
  }

  static ExtensionStoreFetchResult? _parseAidokuJsonStore(
    String indexUrl,
    Map<String, dynamic> jsonMap,
  ) {
    try {
      final rawSources = jsonMap['sources'];
      if (rawSources is! List) return null;

      final repoName = (jsonMap['name'] as String?) ?? 'Aidoku Sources';
      final baseUri = Uri.parse(indexUrl);
      final sources = <Source>[];

      for (final e in rawSources) {
        if (e is! Map<String, dynamic>) continue;
        final rawDownloadUrl =
            (e['downloadURL'] as String?) ?? (e['file'] as String?);
        final rawIconUrl = (e['iconURL'] as String?) ?? (e['icon'] as String?);

        final downloadUrl = rawDownloadUrl != null && rawDownloadUrl.isNotEmpty
            ? baseUri.resolve(rawDownloadUrl).toString()
            : '';
        final iconUrl = rawIconUrl != null && rawIconUrl.isNotEmpty
            ? baseUri.resolve(rawIconUrl).toString()
            : (e['id'] != null
                  ? baseUri.resolve('icons/${e['id']}.png').toString()
                  : '');

        final langs = aidokuLanguages(
          (e['languages'] as List?)?.map((l) => l.toString()).toList() ??
              [(e['lang'] as String?) ?? 'all'],
        );

        final rating = e['contentRating'] ?? e['nsfw'] ?? 0;
        final isNsfw = rating is int
            ? rating >= 2
            : (rating == true || rating == 1);
        final baseUrl =
            (e['baseURL'] as String?) ?? (e['url'] as String?) ?? '';
        final name = (e['name'] as String?) ?? (e['id'] as String?) ?? 'Source';
        final version = e['version'] != null ? '${e['version']}.0.0' : '1.0.0';

        for (final lang in langs) {
          final src = Source()
            ..apiUrl = ''
            ..appMinVerReq = ''
            ..dateFormat = ''
            ..dateFormatLocale = ''
            ..hasCloudflare = false
            ..headers = ''
            ..isActive = true
            ..isAdded = false
            ..isFullData = false
            ..isNsfw = isNsfw
            ..isPinned = false
            ..lastUsed = false
            ..sourceCode = ''
            ..typeSource = ''
            ..version = version
            ..versionLast = version
            ..isObsolete = false
            ..isLocal = false
            ..name = name
            ..lang = lang
            ..baseUrl = baseUrl
            ..sourceCodeUrl = downloadUrl
            ..sourceCodeLanguage = SourceCodeLanguage.aidoku
            ..itemType = ItemType.manga
            ..iconUrl = iconUrl
            ..notes = null;
          src.id = stableSourceId('aidoku-${e['id']}-$lang');
          sources.add(src);
        }
      }

      return ExtensionStoreFetchResult(
        name: repoName,
        website: indexUrl,
        indexUrl: indexUrl,
        sources: sources,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<ExtensionStoreFetchResult?> _parseLegacyJsonStore(
    String indexUrl,
    List<int> bytes, {
    String? name,
    String? website,
  }) async {
    try {
      final jsonList = await _decodeJsonBytes(bytes);
      if (jsonList is! List) return null;

      final repoBaseUrl = indexUrl.replaceAll(RegExp(r'/[^/]+\.json$'), '');
      final sources = <Source>[];

      for (final e in jsonList) {
        if (e is! Map<String, dynamic>) continue;
        if (e['file'] != null && (e['file'] as String).endsWith('.aix')) {
          final langs = aidokuLanguages(
            (e['languages'] as List?)?.map((l) => l.toString()).toList() ??
                [(e['lang'] as String?) ?? 'all'],
          );
          final isNsfw = (e['nsfw'] ?? 0) != 0;
          final icon = e['icon'] != null
              ? (e['icon'] as String).startsWith('http')
                    ? e['icon'] as String
                    : '$repoBaseUrl/${e['icon']}'
              : '$repoBaseUrl/icons/${e['id']}.png';
          final sourceUrl = (e['file'] as String).startsWith('http')
              ? e['file'] as String
              : '$repoBaseUrl/${e['file']}';
          final urls = (e['urls'] as List?)?.map((u) => u.toString()).toList();
          final baseUrl = urls?.firstOrNull ?? (e['url'] as String?) ?? '';

          for (final lang in langs) {
            final src = Source()
              ..apiUrl = ''
              ..appMinVerReq = (e['min_app_version'] as String?) ?? ''
              ..dateFormat = ''
              ..dateFormatLocale = ''
              ..hasCloudflare = false
              ..headers = ''
              ..isActive = true
              ..isAdded = false
              ..isFullData = false
              ..isNsfw = isNsfw
              ..isPinned = false
              ..lastUsed = false
              ..sourceCode = ''
              ..typeSource = ''
              ..version = '${e['version'] ?? 1}.0.0'
              ..versionLast = '${e['version'] ?? 1}.0.0'
              ..isObsolete = false
              ..isLocal = false
              ..name = e['name']
              ..lang = lang
              ..baseUrl = baseUrl
              ..sourceCodeUrl = sourceUrl
              ..sourceCodeLanguage = SourceCodeLanguage.aidoku
              ..itemType = ItemType.manga
              ..iconUrl = icon
              ..notes = null;
            src.id = stableSourceId('aidoku-${e['id']}-$lang');
            sources.add(src);
          }
          continue;
        }
        // YomiHub 0.1.9: IReader extension APKs run through the built-in
        // IReader bridge (Android) as Novel extensions.
        if (e['pkg'] is String &&
            (e['pkg'] as String).startsWith('ireader.') &&
            e['apk'] is String) {
          if (IReaderBridge.supported) {
            sources.add(IReaderBridge.fromIndex(e, repoBaseUrl));
          }
          continue;
        }
        // other non-Tachiyomi APK repositories list packages YomiHub cannot
        // run: skip them instead of creating broken "Comic" entries.
        if (e['pkg'] is String &&
            !(e['pkg'] as String).startsWith('eu.kanade.tachiyomi') &&
            !(e['pkg'] as String).startsWith('tachiyomix') &&
            e['apk'] != null) {
          continue;
        }
        if (e['name'] != null &&
            e['pkg'] != null &&
            e['version'] != null &&
            e['code'] != null &&
            e['lang'] != null &&
            e['nsfw'] != null &&
            e['sources'] != null &&
            e['apk'] != null) {
          final subSources = e['sources'] as List;
          for (final source in subSources) {
            final src = Source.fromJson(e)
              ..apiUrl = ''
              ..appMinVerReq = ''
              ..dateFormat = ''
              ..dateFormatLocale = ''
              ..hasCloudflare = false
              ..headers = ''
              ..isActive = true
              ..isAdded = false
              ..isFullData = false
              ..isNsfw = e['nsfw'] == 1
              ..isPinned = false
              ..lastUsed = false
              ..sourceCode = ''
              ..typeSource = ''
              ..versionLast = (e['version'] as String?) ?? '0.0.1'
              ..isObsolete = false
              ..isLocal = false
              ..name = source['name']
              ..lang = source['lang']
              ..baseUrl = source['baseUrl']
              ..sourceCodeUrl = '$repoBaseUrl/apk/${e['apk']}'
              ..sourceCodeLanguage = SourceCodeLanguage.mihon
              ..itemType =
                  (e['pkg'] as String).startsWith(
                    'eu.kanade.tachiyomi.animeextension',
                  )
                  ? ItemType.anime
                  : ItemType.manga
              ..iconUrl = '$repoBaseUrl/icon/${e['pkg']}.png'
              ..notes = null;
            src.id = 'mihon-${source['id']}'.hashCode;
            sources.add(src);
          }
          continue;
        }

        if (e['id'] is String &&
            e['name'] != null &&
            e['site'] != null &&
            e['lang'] != null &&
            e['version'] != null &&
            e['url'] != null &&
            e['iconUrl'] != null) {
          final lang = convertLnreaderLang(e['lang']);
          final src = Source()
            ..apiUrl = ''
            ..appMinVerReq = ''
            ..dateFormat = ''
            ..dateFormatLocale = ''
            ..hasCloudflare = false
            ..headers = ''
            ..isActive = true
            ..isAdded = false
            ..isFullData = false
            ..isNsfw = false
            ..isPinned = false
            ..lastUsed = false
            ..sourceCode = ''
            ..typeSource = ''
            ..version = (e['version'] as String?) ?? '0.0.1'
            ..versionLast = (e['version'] as String?) ?? '0.0.1'
            ..isObsolete = false
            ..isLocal = false
            ..name = e['name'] as String?
            ..lang = lang
            ..baseUrl = (e['site'] as String?) ?? ''
            ..sourceCodeUrl = (e['url'] as String?) ?? ''
            ..sourceCodeLanguage = SourceCodeLanguage.lnreader
            ..itemType = ItemType.novel
            ..iconUrl = (e['iconUrl'] as String?) ?? ''
            ..notes = "Performance might be poor due to limited engine";
          src.id = 'lnreader-plugin-"${src.name}"."$lang"'.hashCode;
          sources.add(src);
          continue;
        }

        // Native Mangayomi source or other supported JSON source
        try {
          final src = Source.fromJson(e);
          src.sourceCodeUrl = src.sourceCodeUrl?.trim();
          src.iconUrl = src.iconUrl?.trim();
          src.baseUrl = src.baseUrl?.trim();
          final code = src.sourceCodeUrl ?? '';
          // Entries pointing at a folder instead of a file can't be installed.
          if (code.isNotEmpty && code.endsWith('/')) continue;
          if (src.name != null && src.name!.isNotEmpty) {
            sources.add(src);
          }
        } catch (_) {}
      }

      String defaultRepoName = 'Extension Repo';
      String? defaultRepoWebsite = website;
      final uri = Uri.tryParse(indexUrl);
      if (uri != null) {
        if (uri.host == 'raw.githubusercontent.com' &&
            uri.pathSegments.length >= 2) {
          defaultRepoName = uri.pathSegments[1];
          defaultRepoWebsite ??=
              'https://github.com/${uri.pathSegments[0]}/${uri.pathSegments[1]}';
        } else {
          final segments = uri.pathSegments
              .where(
                (s) =>
                    s.isNotEmpty &&
                    !s.endsWith('.json') &&
                    s != '.dist' &&
                    s != 'dist' &&
                    s != 'build' &&
                    s != '.build',
              )
              .toList();
          defaultRepoName = segments.lastOrNull ?? uri.host;
        }
      }

      final repoName =
          (name != null &&
              name.isNotEmpty &&
              !name.endsWith('.json') &&
              name != '.dist' &&
              name != 'dist')
          ? name
          : defaultRepoName;
      final repoWebsite =
          (defaultRepoWebsite != null && defaultRepoWebsite.isNotEmpty)
          ? defaultRepoWebsite
          : repoBaseUrl;

      return ExtensionStoreFetchResult(
        name: repoName,
        website: repoWebsite,
        indexUrl: indexUrl,
        sources: sources,
      );
    } catch (_) {
      return null;
    }
  }

  static List<Source> _convertProtobufExtensionsToSources(
    String indexUrl,
    List<ExtensionStoreItem> extensions,
  ) {
    final sources = <Source>[];
    final baseUri = Uri.parse(indexUrl);

    for (final ext in extensions) {
      final pkgName = ext.packageName;
      final versionName = ext.versionName;
      final isNsfw = ext.contentWarning >= 2; // 2 = MIXED, 3 = NSFW

      final apkUrl = ext.hasField(3) && ext.resources.apkUrl.isNotEmpty
          ? baseUri.resolve(ext.resources.apkUrl).toString()
          : '';
      final iconUrl = ext.hasField(3) && ext.resources.iconUrl.isNotEmpty
          ? baseUri.resolve(ext.resources.iconUrl).toString()
          : '';

      final itemType = pkgName.startsWith('eu.kanade.tachiyomi.animeextension')
          ? ItemType.anime
          : ItemType.manga;

      for (final src in ext.sources) {
        final source = Source()
          ..apiUrl = ''
          ..appMinVerReq = ''
          ..dateFormat = ''
          ..dateFormatLocale = ''
          ..hasCloudflare = false
          ..headers = ''
          ..isActive = true
          ..isAdded = false
          ..isFullData = false
          ..isNsfw = isNsfw
          ..isPinned = false
          ..lastUsed = false
          ..sourceCode = ''
          ..typeSource = ''
          ..version = versionName
          ..versionLast = versionName
          ..isObsolete = false
          ..isLocal = false
          ..name = src.name
          ..lang = src.language
          ..baseUrl = src.homeUrl
          ..sourceCodeUrl = apkUrl
          ..iconUrl = iconUrl
          ..sourceCodeLanguage = SourceCodeLanguage.mihon
          ..itemType = itemType
          ..notes = null;

        source.id = 'mihon-${src.id}'.hashCode;
        sources.add(source);
      }
    }

    return sources;
  }

  static List<Source> _convertJsonExtensionsToSources(
    String indexUrl,
    List<dynamic> rawExtensions,
  ) {
    final sources = <Source>[];
    final baseUri = Uri.parse(indexUrl);

    for (final e in rawExtensions) {
      if (e is! Map<String, dynamic>) continue;
      final pkgName =
          (e['packageName'] as String?) ?? (e['pkg'] as String?) ?? '';
      final versionName =
          (e['versionName'] as String?) ?? (e['version'] as String?) ?? '0.0.1';
      final contentWarning = e['contentWarning'];
      final isNsfw = contentWarning is int
          ? contentWarning >= 2
          : (e['nsfw'] == 1 || e['nsfw'] == true);

      final resources = e['resources'] as Map<String, dynamic>?;
      final rawApkUrl =
          (resources?['apkUrl'] as String?) ??
          (e['apk'] != null ? 'apk/${e['apk']}' : '');
      final rawIconUrl =
          (resources?['iconUrl'] as String?) ??
          (pkgName.isNotEmpty ? 'icon/$pkgName.png' : '');

      final apkUrl = rawApkUrl.isNotEmpty
          ? baseUri.resolve(rawApkUrl).toString()
          : '';
      final iconUrl = rawIconUrl.isNotEmpty
          ? baseUri.resolve(rawIconUrl).toString()
          : '';

      final itemType = pkgName.startsWith('eu.kanade.tachiyomi.animeextension')
          ? ItemType.anime
          : ItemType.manga;

      final srcList = e['sources'] as List?;
      if (srcList != null) {
        for (final srcJson in srcList) {
          if (srcJson is! Map<String, dynamic>) continue;
          final srcName = (srcJson['name'] as String?) ?? '';
          final srcLang =
              (srcJson['language'] as String?) ??
              (srcJson['lang'] as String?) ??
              'all';
          final srcBaseUrl =
              (srcJson['homeUrl'] as String?) ??
              (srcJson['baseUrl'] as String?) ??
              '';
          final srcId = srcJson['id'];

          final source = Source()
            ..apiUrl = ''
            ..appMinVerReq = ''
            ..dateFormat = ''
            ..dateFormatLocale = ''
            ..hasCloudflare = false
            ..headers = ''
            ..isActive = true
            ..isAdded = false
            ..isFullData = false
            ..isNsfw = isNsfw
            ..isPinned = false
            ..lastUsed = false
            ..sourceCode = ''
            ..typeSource = ''
            ..version = versionName
            ..versionLast = versionName
            ..isObsolete = false
            ..isLocal = false
            ..name = srcName
            ..lang = srcLang
            ..baseUrl = srcBaseUrl
            ..sourceCodeUrl = apkUrl
            ..iconUrl = iconUrl
            ..sourceCodeLanguage = SourceCodeLanguage.mihon
            ..itemType = itemType
            ..notes = null;

          source.id = 'mihon-$srcId'.hashCode;
          sources.add(source);
        }
      }
    }

    return sources;
  }

  static ExtensionStoreItem _extensionItemFromJson(Map<String, dynamic> json) {
    final resourcesJson = json['resources'] as Map<String, dynamic>?;
    final sourcesList = (json['sources'] as List?) ?? [];

    return ExtensionStoreItem(
      name: json['name'] as String?,
      packageName: json['packageName'] as String?,
      resources: ExtensionStoreResources(
        apkUrl: resourcesJson?['apkUrl'] as String?,
        iconUrl: resourcesJson?['iconUrl'] as String?,
      ),
      extensionLib: json['extensionLib'] as String?,
      versionName: json['versionName'] as String?,
      contentWarning: json['contentWarning'] as int?,
      sources: sourcesList.map((s) {
        final srcMap = s as Map<String, dynamic>;
        final rawId = srcMap['id'];
        return ExtensionStoreSource(
          id: rawId is int
              ? fixnum.Int64(rawId)
              : rawId is String
              ? fixnum.Int64.tryParseInt(rawId)
              : null,
          name: srcMap['name'] as String?,
          language:
              (srcMap['language'] as String?) ?? (srcMap['lang'] as String?),
          homeUrl:
              (srcMap['homeUrl'] as String?) ?? (srcMap['baseUrl'] as String?),
        );
      }),
    );
  }

  static String convertLnreaderLang(dynamic langOrMap) {
    final lang = langOrMap is Map ? langOrMap['lang'] : langOrMap;
    if (lang is String) {
      final clean = lang.replaceAll('\u200e', '').trim();
      switch (clean) {
        case "العربية":
          return "ar";
        case "中文, 汉语, 漢語":
          return "zh";
        case "English":
          return "en";
        case "Français":
          return "fr";
        case "Bahasa Indonesia":
          return "id";
        case "日本語":
          return "ja";
        case "조선말, 한국어":
          return "ko";
        case "Polski":
          return "pl";
        case "Português":
          return "pt";
        case "Русский":
          return "ru";
        case "Español":
          return "es";
        case "ไทย":
          return "th";
        case "Türkçe":
          return "tr";
        case "Українська":
          return "uk";
        case "Tiếng Việt":
          return "vi";
        case "Multi":
          return "all";
        default:
          return "all";
      }
    }
    return "all";
  }
}

/// YomiHub 0.2.0: id of an Aidoku source that stays the same across app
/// versions and platforms (FNV-1a, 31 bits). The two index parsers used
/// `String.hashCode` – once with `.abs()`, once without – so the same
/// source could get two ids, and an installed Aidoku source was no longer
/// recognised by its repository ("không cập nhật được") after the hash
/// changed. Installed sources keep their old id (matched by name/language
/// in fetchSourcesList).
int stableSourceId(String key) {
  var h = 0x811c9dc5;
  for (final c in key.codeUnits) {
    h ^= c;
    h = (h * 0x01000193) & 0xffffffff;
  }
  return h & 0x7fffffff;
}

/// YomiHub 0.2.0: an Aidoku source made one Mangayomi source per language,
/// so "multi" sources such as XCOMIC (110 languages) filled the list with
/// 110 entries – most of them empty (Abkhazian, Afrikaans…), which looked
/// like the source "did not work". Sources with many languages keep the
/// common reading languages only.
const _aidokuMainLanguages = [
  'en',
  'vi',
  'ja',
  'ko',
  'zh',
  'zh-hans',
  'zh-hant',
  'es',
  'es-419',
  'pt',
  'pt-br',
  'fr',
  'de',
  'it',
  'id',
  'ru',
  'th',
  'tr',
  'ar',
];

List<String> aidokuLanguages(List<String> langs) {
  if (langs.length <= 6) return langs;
  final keep = langs
      .where((l) => _aidokuMainLanguages.contains(l.toLowerCase()))
      .toList();
  return keep.isEmpty ? [langs.first] : keep;
}
