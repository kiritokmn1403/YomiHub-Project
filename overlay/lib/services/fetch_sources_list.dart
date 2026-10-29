import 'dart:async';
import 'package:mangayomi/yomihub/extensions/ext_errors.dart';
import 'package:mangayomi/yomihub/ireader/ireader_bridge.dart';
import 'package:mangayomi/yomihub/net/gh_mirror.dart';
import 'package:mangayomi/yomihub/mes/yomi_mes.dart';
import 'package:mangayomi/yomihub/extensions/url_override.dart';
import 'dart:convert';
import 'dart:io';

import 'package:http_interceptor/http_interceptor.dart';
import 'package:mangayomi/eval/model/filter.dart';
import 'package:mangayomi/eval/model/source_preference.dart';
import 'package:mangayomi/repositories/source_repository.dart';
import 'package:mangayomi/eval/aidoku/service.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/models/settings.dart';
import 'package:mangayomi/models/source.dart';
import 'package:mangayomi/services/http/m_client.dart';
import 'package:mangayomi/services/isolate_service.dart';
import 'package:mangayomi/services/extension_store_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:mangayomi/utils/log/logger.dart';

Future<void> fetchSourcesList({
  int? id,
  required bool refresh,
  required String androidProxyServer,
  required bool autoUpdateExtensions,
  required ItemType itemType,
  required Repo? repo,
}) async {
  final http = MClient.init(reqcopyWith: {'useDartHttpClient': true});
  final url = repo?.jsonUrl;
  if (repo == null || url == null || url.trim().isEmpty) return;

  if ((repo.name == null ||
          repo.name!.isEmpty ||
          repo.name == '.dist' ||
          repo.name == 'dist')) {
    final uri = Uri.tryParse(url);
    if (uri != null &&
        uri.host == 'raw.githubusercontent.com' &&
        uri.pathSegments.length >= 2) {
      repo.name = uri.pathSegments[1];
    }
  }

  final info = await PackageInfo.fromPlatform();

  List<Source> sourceList = [];

  // Try parsing with ExtensionStoreService (.pb, NetworkExtensionStore JSON, or legacy min.json)
  final storeResult = await ExtensionStoreService.fetchStore(url, http);
  if (storeResult != null && storeResult.sources.isNotEmpty) {
    sourceList = storeResult.sources
        .where(
          (source) =>
              source.itemType == itemType &&
              (source.sourceCodeLanguage == SourceCodeLanguage.aidoku ||
                  source.sourceCodeLanguage == SourceCodeLanguage.lnreader ||
                  source.appMinVerReq == null ||
                  source.appMinVerReq!.isEmpty ||
                  compareVersions(yomiEngineVersion(info.version), source.appMinVerReq!) > -1),
        )
        .toList();
  } else {
    // Fallback parsing for non-Mihon direct JSON lists (LNReader or custom format)
    try {
      final req = await GhMirror.get(http, Uri.parse(url));
      if (req.statusCode == 200 && req.bodyBytes.isNotEmpty) {
        dynamic decoded;
        final bytes = req.bodyBytes;
        if (url.toLowerCase().endsWith('.pb')) {
          decoded = null;
        } else if (bytes.length >= 2 && bytes[0] == 0x1F && bytes[1] == 0x8B) {
          try {
            final uncompressed = gzip.decode(bytes);
            decoded = jsonDecode(utf8.decode(uncompressed));
          } catch (_) {
            decoded = null;
          }
        } else {
          try {
            decoded = jsonDecode(req.body);
          } catch (_) {
            decoded = null;
          }
        }
        if (decoded is List) {
          sourceList = decoded
              .expand((e) sync* {
                if (e['id'] is String &&
                    e['name'] != null &&
                    e['site'] != null &&
                    e['lang'] != null &&
                    e['version'] != null &&
                    e['url'] != null &&
                    e['iconUrl'] != null) {
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
                    ..isNsfw = false
                    ..isPinned = false
                    ..lastUsed = false
                    ..sourceCode = ''
                    ..typeSource = ''
                    ..versionLast = e['version'] ?? '0.0.1'
                    ..isObsolete = false
                    ..isLocal = false
                    ..lang = _convertLang(e)
                    ..baseUrl = e['site']
                    ..sourceCodeUrl = e['url']
                    ..sourceCodeLanguage = SourceCodeLanguage.lnreader
                    ..itemType = ItemType.novel
                    ..notes = "Performance might be poor due to limited engine";
                  src.id =
                      'lnreader-plugin-"${src.name}"."${src.lang}"'.hashCode;
                  yield src;
                } else if (e is Map<String, dynamic>) {
                  try {
                    yield Source.fromJson(e);
                  } catch (_) {}
                }
              })
              .where(
                (source) =>
                    source.itemType == itemType &&
                    (source.appMinVerReq == null ||
                        source.appMinVerReq!.isEmpty ||
                        compareVersions(yomiEngineVersion(info.version), source.appMinVerReq!) >
                            -1),
              )
              .toList();
        }
      }
    } catch (e, st) {
      // A failure here drops sources from the list with no sign of why.
      final t = e.toString().toLowerCase();
      if (t.contains('host lookup') || t.contains('socketexception') ||
          t.contains('timeout') || t.contains('connection')) {
        // offline / DNS: not an app error, once per repo is enough
        AppLogger.logOnce('repo-net:$url', 'fetchSourcesList: $url unreachable: ${YomiExtErrors.short(e)}');
      } else {
        AppLogger.log(
          'fetchSourcesList: filtering sources failed ($url): $e\n$st',
          logLevel: LogLevel.error,
        );
      }
    }
  }
  // YomiHub 0.2.2: some repos (kegareta-sauces) publish URLs with an
  // unexpanded branch placeholder ("…/bbranchNamee/…") – icons failed to load.
  for (final s in sourceList) {
    s.iconUrl = yomiFixRepoUrl(s.iconUrl);
    s.sourceCodeUrl = yomiFixRepoUrl(s.sourceCodeUrl);
  }

  // YomiHub 0.1.9: entries without an id / version (some Aidoku, LNReader and
  // hand-made repos) used to hit `source.id!` / `version!` and abort the whole
  // repo with "Null check operator used on a null value" (44x in logs.txt).
  sourceList = sourceList
      .where((s) => s.id != null && (s.name ?? '').isNotEmpty)
      .toList();
  if (id != null) {
    var matchingSource = sourceList.firstWhere(
      (source) => source.id == id,
      orElse: () => Source(),
    );
    if (matchingSource.id == null) {
      // 0.2.0: installed under an older id (see stableSourceId)
      final inst = sourceRepository.getById(id);
      if (inst != null) {
        matchingSource = sourceList.firstWhere(
          (s) =>
              s.sourceCodeLanguage == inst.sourceCodeLanguage &&
              s.lang == inst.lang &&
              (s.name ?? '').toLowerCase() == (inst.name ?? '').toLowerCase(),
          orElse: () => Source(),
        );
        if (matchingSource.id != null) matchingSource.id = id;
      }
    }
    if (matchingSource.id != null &&
        (matchingSource.sourceCodeUrl ?? '').isNotEmpty) {
      if (IReaderBridge.isIReaderSource(matchingSource)) {
        // APK of the IReader bridge, not a script to download
        final row = sourceRepository.getById(matchingSource.id!) ?? matchingSource;
        row
          ..additionalParams = matchingSource.additionalParams
          ..versionLast = matchingSource.versionLast;
        await IReaderBridge.installSource(row);
      } else {
        try {
          await _updateSource(matchingSource, androidProxyServer, repo, itemType);
        } catch (e, st) {
          _logUpdateFailure(matchingSource, repo, e, st);
          // 0.2.2: already in the app log – callers must not log it again
          // as "repo fetch failed" with the whole stack a second time
          throw YomiLoggedError(e);
        }
      }
    }
  } else {
    // YomiHub 0.2.0: Aidoku / LNReader ids were String.hashCode values that
    // can change between app versions – find an installed copy by
    // name + language and keep its id, so it is updated instead of being
    // shown as a second, never-updating source.
    final byName = <String, Source>{};
    for (final s in sourceRepository.getInstalled()) {
      if (s.itemType == itemType &&
          (s.sourceCodeLanguage == SourceCodeLanguage.aidoku ||
              s.sourceCodeLanguage == SourceCodeLanguage.lnreader)) {
        byName['${s.sourceCodeLanguage.index}|${s.lang}|${(s.name ?? '').toLowerCase()}'] = s;
      }
    }
    final pendingNew = <Source>[];
    for (var source in sourceList) {
      try {
        var existingSource = await sourceRepository.findByIdAsync(
          source.id!,
        );
        if (existingSource == null &&
            (source.sourceCodeLanguage == SourceCodeLanguage.aidoku ||
                source.sourceCodeLanguage == SourceCodeLanguage.lnreader)) {
          final old = byName['${source.sourceCodeLanguage.index}|${source.lang}|${(source.name ?? '').toLowerCase()}'];
          if (old != null && old.id != null) {
            source.id = old.id;
            existingSource = old;
          }
        }
        if (existingSource == null) {
          await _addNewSource(source, repo, itemType, pendingNew);
          continue;
        }
        if ((existingSource.iconUrl ?? '').contains('ranchName')) {
          await sourceRepository.save(existingSource..iconUrl = source.iconUrl);
        }
        final shouldUpdate =
            (existingSource.isAdded ?? false) &&
            compareVersions(
                  existingSource.version ?? '0',
                  source.version ?? '0',
                ) <
                0;
        if (!shouldUpdate) continue;
        if (autoUpdateExtensions &&
            (source.sourceCodeUrl ?? '').isNotEmpty &&
            !IReaderBridge.isIReaderSource(source)) {
          try {
            await _updateSource(source, androidProxyServer, repo, itemType);
          } catch (e, st) {
            // YomiHub 0.2.1: a failed automatic update is an error in the
            // app log (it used to be a one-line "skipped" warning at most)
            _logUpdateFailure(source, repo, e, st, from: existingSource.version);
            await sourceRepository.save(existingSource..versionLast = source.version);
          }
        } else {
          await sourceRepository.save(
            existingSource..versionLast = source.version,
          );
        }
      } catch (e) {
        // one broken entry must not hide the rest of the repo
        AppLogger.logOnce(
          'src:${source.id}',
          'fetchSourcesList: skipped "${source.name}" (${repo.name}): $e',
        );
      }
    }
    await _flushNew(pendingNew);
  }

  await checkIfSourceIsObsolete(sourceList, repo, itemType);
}

/// YomiHub 0.2.1: every failed extension update is written to the app log
/// (Settings › About › App log) with the extension, repo, versions and cause.
void _logUpdateFailure(
  Source source,
  Repo? repo,
  Object e,
  StackTrace st, {
  String? from,
}) {
  final installed = from ?? (source.id == null ? null : sourceRepository.getById(source.id!)?.version);
  final msg = e.toString().replaceAll(RegExp(r'\s*statusCode:\s*\d+\s*$'), '').trim();
  AppLogger.log(
    '[Cập nhật tiện ích] "${source.name}" (${source.lang}, ${source.sourceCodeLanguage.name}) '
    '${installed != null && installed == source.version ? 'cài lại ${source.version}' : '${installed ?? '?'} → ${source.version ?? '?'}'}'
    ' • kho: ${repo?.name ?? repo?.jsonUrl ?? '?'}\n'
    'URL: ${source.sourceCodeUrl ?? ''}\n'
    'Lỗi: $msg${e is TimeoutException || YomiExtErrors.isNetworkError(e) ? '' : '\n$st'}',
    logLevel: LogLevel.error,
  );
}

Future<void> _updateSource(
  Source source,
  String androidProxyServer,
  Repo? repo,
  ItemType itemType,
) async {
  final http = MClient.init(reqcopyWith: {'useDartHttpClient': true});
  final req = await GhMirror.getValid(
    http,
    Uri.parse(source.sourceCodeUrl!),
    isValid: (r) => yomiLooksLikeExtensionCode(source.sourceCodeLanguage, r.bodyBytes, () => r.body),
  );
  // YomiHub 0.2.1: never install a 404 page / empty body as the extension
  // (it replaced a working extension with a broken one)
  if (req.statusCode != 200 || req.bodyBytes.isEmpty) {
    throw Exception('Tải mã tiện ích thất bại: HTTP ${req.statusCode} (${req.bodyBytes.length} byte)');
  }
  final isBinary = source.sourceCodeLanguage == SourceCodeLanguage.mihon ||
      source.sourceCodeLanguage == SourceCodeLanguage.aidoku;
  if (isBinary && !(req.bodyBytes.length > 4 && req.bodyBytes[0] == 0x50 && req.bodyBytes[1] == 0x4b)) {
    throw Exception('Tệp tải về không phải gói APK/AIX hợp lệ (${req.bodyBytes.length} byte)');
  }
  if (!isBinary && req.body.trimLeft().toLowerCase().startsWith('<!doctype html')) {
    throw Exception('Máy chủ trả về trang HTML thay vì mã tiện ích');
  }
  // 0.2.2: the body must really be extension code (see GhMirror.getValid)
  if (!yomiLooksLikeExtensionCode(source.sourceCodeLanguage, req.bodyBytes, () => req.body)) {
    throw Exception(
      'Nội dung tải về không phải mã tiện ích (có thể bị nhà mạng/DNS chặn hoặc chuyển hướng): '
      '"${GhMirror.preview(req)}" – bản đã cài được giữ nguyên',
    );
  }
  final sourceCode =
      (source.sourceCodeLanguage == SourceCodeLanguage.mihon ||
          source.sourceCodeLanguage == SourceCodeLanguage.aidoku)
      ? base64.encode(req.bodyBytes)
      : req.body;

  Map<String, String> headers = {};
  bool? supportLatest;
  FilterList? filterList;
  List<SourcePreference>? preferenceList;
  source.sourceCode = sourceCode;
  if (source.sourceCodeLanguage == SourceCodeLanguage.mihon) {
    androidProxyServer = (await YomiMes.ensure()) ?? androidProxyServer;
    headers = await fetchHeadersDalvik(http, source, androidProxyServer);
    supportLatest = await fetchSupportLatestDalvik(
      http,
      source,
      androidProxyServer,
    );
    filterList = await fetchFilterListDalvik(http, source, androidProxyServer);
    preferenceList = await fetchPreferencesDalvik(
      http,
      source,
      androidProxyServer,
    );
  } else if (source.sourceCodeLanguage == SourceCodeLanguage.aidoku) {
    final service = AidokuExtensionService(source);
    try {
      headers = service.getHeaders();
      supportLatest = service.supportsLatest;
      filterList = await service.fetchFilterList();
    } finally {
      service.dispose();
    }
  } else {
    headers = await getIsolateService.get<Map<String, String>>(
      source: source,
      serviceType: 'getHeaders',
    );
  }

  final existing =
      source.id != null ? sourceRepository.getById(source.id!) : null;
  final updatedSource = Source()
    ..headers = jsonEncode(headers)
    ..supportLatest = supportLatest
    ..filterList = filterList != null ? jsonEncode(filterList.toJson()) : null
    ..preferenceList = preferenceList != null
        ? jsonEncode(preferenceList.map((e) => e.toJson()).toList())
        : null
    ..isAdded = true
    ..isPinned = existing?.isPinned ?? false
    ..lastUsed = existing?.lastUsed ?? false
    ..sourceCode = sourceCode
    ..sourceCodeUrl = source.sourceCodeUrl
    ..id = source.id
    ..apiUrl = source.apiUrl
    // YomiHub 0.1.7: keep a user's "Đổi URL" across updates
    ..baseUrl = YomiUrlOverride.baseUrlFor(source.id, source.baseUrl)
    ..dateFormat = source.dateFormat
    ..dateFormatLocale = source.dateFormatLocale
    ..hasCloudflare = source.hasCloudflare
    ..iconUrl = source.iconUrl
    ..typeSource = source.typeSource
    ..lang = source.lang
    ..isNsfw = source.isNsfw
    ..name = source.name
    ..version = source.version
    ..versionLast = source.version
    ..itemType = itemType
    ..isFullData = source.isFullData ?? false
    ..appMinVerReq = source.appMinVerReq
    ..sourceCodeLanguage = source.sourceCodeLanguage
    ..additionalParams = source.additionalParams ?? ""
    ..isObsolete = false
    ..notes = source.notes
    ..repo = repo
    ..updatedAt = DateTime.now().millisecondsSinceEpoch;

  await sourceRepository.save(updatedSource);
}

/// YomiHub 0.2.1: new rows of a repository refresh are written in batches
/// (keiyoushi / Kotatsu add 1 000+ rows; one write transaction per row on
/// the UI isolate made the app stutter for several seconds).
Future<void> _flushNew(List<Source> pending) async {
  for (var i = 0; i < pending.length; i += 150) {
    final end = i + 150 < pending.length ? i + 150 : pending.length;
    await sourceRepository.putAll(pending.sublist(i, end));
    await Future<void>.delayed(Duration.zero); // let a frame through
  }
  pending.clear();
}

Future<void> _addNewSource(Source source, Repo? repo, ItemType itemType, [List<Source>? pending]) async {
  final newSource = Source()
    ..sourceCodeUrl = source.sourceCodeUrl
    ..id = source.id
    ..sourceCode = source.sourceCode
    ..apiUrl = source.apiUrl
    // YomiHub 0.1.7: keep a user's "Đổi URL" across updates
    ..baseUrl = YomiUrlOverride.baseUrlFor(source.id, source.baseUrl)
    ..dateFormat = source.dateFormat
    ..dateFormatLocale = source.dateFormatLocale
    ..hasCloudflare = source.hasCloudflare
    ..iconUrl = source.iconUrl
    ..typeSource = source.typeSource
    ..lang = source.lang
    ..isNsfw = source.isNsfw
    ..name = source.name
    ..version = source.version
    ..versionLast = source.version
    ..itemType = itemType
    ..sourceCodeLanguage = source.sourceCodeLanguage
    ..isFullData = source.isFullData ?? false
    ..appMinVerReq = source.appMinVerReq
    ..isObsolete = false
    ..notes = source.notes
    ..additionalParams = source.additionalParams
    ..repo = repo
    ..updatedAt = DateTime.now().millisecondsSinceEpoch;
  if (pending != null) {
    pending.add(newSource);
    if (pending.length >= 150) await _flushNew(pending);
    return;
  }
  await sourceRepository.save(newSource);
}

Future<void> checkIfSourceIsObsolete(
  List<Source> sourceList,
  Repo repo,
  ItemType itemType,
) async {
  if (sourceList.isEmpty) return;

  final sources = await sourceRepository.getNonLocalByItemType(itemType);

  if (sources.isEmpty) return;

  final sourceIds = sourceList
      .where((e) => e.id != null)
      .map((e) => e.id!)
      .toSet();

  if (sourceIds.isEmpty) return;

  final toUpdate = <Source>[];
  final toDelete = <int>[];
  for (var source in sources) {
    final isNowObsolete =
        !sourceIds.contains(source.id) && source.repo?.jsonUrl == repo.jsonUrl;

    if (!(source.isAdded ?? false) && isNowObsolete) {
      // Not installed and gone from the repo: nothing to install, so
      // remove the dead row instead of leaving it in the browse list.
      toDelete.add(source.id!);
      continue;
    }
    if (source.isObsolete != isNowObsolete) {
      source.isObsolete = isNowObsolete;
      source.updatedAt = DateTime.now().millisecondsSinceEpoch;
      toUpdate.add(source);
    }
  }
  if (toUpdate.isNotEmpty) {
    await sourceRepository.putAll(toUpdate);
  }
  if (toDelete.isNotEmpty) {
    await sourceRepository.deleteAll(toDelete);
  }
}

int compareVersions(String version1, String version2) {
  final clean1 = version1
      .trim()
      .replaceFirst(RegExp(r'^[vV]'), '')
      .split(RegExp(r'[-+]'))
      .first;
  final clean2 = version2
      .trim()
      .replaceFirst(RegExp(r'^[vV]'), '')
      .split(RegExp(r'[-+]'))
      .first;

  final v1Parts = clean1.split('.');
  final v2Parts = clean2.split('.');
  final maxLength = v1Parts.length > v2Parts.length
      ? v1Parts.length
      : v2Parts.length;

  for (var i = 0; i < maxLength; i++) {
    final v1Value = i < v1Parts.length ? (int.tryParse(v1Parts[i]) ?? 0) : 0;
    final v2Value = i < v2Parts.length ? (int.tryParse(v2Parts[i]) ?? 0) : 0;

    final comparison = v1Value.compareTo(v2Value);
    if (comparison != 0) return comparison;
  }

  return 0;
}

Future<Map<String, String>> fetchHeadersDalvik(
  InterceptedClient client,
  Source source,
  String androidProxyServer,
) async {
  try {
    final name = source.itemType == ItemType.anime ? "Anime" : "Manga";
    final res = await YomiMes.dalvik(
      androidProxyServer,
      jsonEncode({
        "method": "headers$name",
        "data": source.sourceCode,
        "lang": source.lang,
        "sourceId": source.id?.toString(),
      }),
    );
    final data = jsonDecode(res.body) as List;
    final Map<String, String> headers = {};
    for (var i = 0; i + 1 < data.length; i += 2) {
      headers[data[i]] = data[i + 1];
    }
    return headers;
  } catch (_) {
    return {};
  }
}

Future<bool> fetchSupportLatestDalvik(
  InterceptedClient client,
  Source source,
  String androidProxyServer,
) async {
  try {
    final name = source.itemType == ItemType.anime ? "Anime" : "Manga";
    final res = await YomiMes.dalvik(
      androidProxyServer,
      jsonEncode({
        "method": "supportLatest$name",
        "data": source.sourceCode,
        "lang": source.lang,
        "sourceId": source.id?.toString(),
      }),
    );
    return res.body.trim() == "true";
  } catch (_) {
    return false;
  }
}

Future<FilterList?> fetchFilterListDalvik(
  InterceptedClient client,
  Source source,
  String androidProxyServer,
) async {
  try {
    final name = source.itemType == ItemType.anime ? "Anime" : "Manga";
    final res = await YomiMes.dalvik(
      androidProxyServer,
      jsonEncode({
        "method": "filters$name",
        "data": source.sourceCode,
        "lang": source.lang,
        "sourceId": source.id?.toString(),
      }),
    );
    final data = jsonDecode(res.body) as List;

    return FilterList(filtersFromJson(data));
  } catch (_) {
    return null;
  }
}

List<dynamic> filtersFromJson(List<dynamic> json) {
  return json.expand((e) sync* {
    if (e['name'] is String &&
        e['state'] is Map<String, dynamic> &&
        e['values'] is List) {
      yield SortFilter(
        "${e['name']}Filter",
        e['name'],
        SortState(e['state']['index'], e['state']['ascending'], null),
        (e['values'] as List)
            .map((e) => SelectFilterOption(e, e, null))
            .toList(),
        null,
      );
    } else if (e['name'] is String &&
        e['state'] is int &&
        (e['values'] is List || e['vals'] is List)) {
      yield SelectFilter(
        "${e['name']}Filter",
        e['name'],
        e['state'],
        e['vals'] is List
            ? (e['vals'] as List)
                  .map((e) => SelectFilterOption(e['first'], e['second'], null))
                  .toList()
            : e['values'] is List
            ? (e['values'] as List)
                  .map(
                    (e) => (e is Map)
                        ? SelectFilterOption(e['value'], e['value'], null)
                        : SelectFilterOption(e, e, null),
                  )
                  .toList()
            : [],
        "SelectFilter",
      );
    } else if (e['name'] is String && e['state'] is bool) {
      yield CheckBoxFilter(
        null,
        e['name'],
        e['id'] ?? e['name'],
        null,
        state: e['state'],
      );
    } else if (e['included'] is bool &&
        e['ignored'] is bool &&
        e['excluded'] is bool) {
      yield TriStateFilter(
        null,
        e['name'],
        e['id'] ?? e['name'],
        null,
        state: e['state'],
      );
    } else if (e['name'] is String && e['state'] is List) {
      yield GroupFilter(
        "${e['name']}Filter",
        e['name'],
        filtersFromJson((e['state'] as List)),
        "GroupFilter",
      );
    } else if (e['name'] is String && e['state'] is String) {
      yield TextFilter(
        "${e['name']}Filter",
        e['name'],
        null,
        state: e['state'],
      );
    } else if (e['name'] is String && e['state'] is int) {
      yield HeaderFilter(e['name'], "${e['name']}Filter");
    }
  }).toList();
}

Future<List<SourcePreference>?> fetchPreferencesDalvik(
  InterceptedClient client,
  Source source,
  String androidProxyServer,
) async {
  try {
    final name = source.itemType == ItemType.anime ? "Anime" : "Manga";
    final res = await YomiMes.dalvik(
      androidProxyServer,
      jsonEncode({
        "method": "preferences$name",
        "data": source.sourceCode,
        "lang": source.lang,
        "sourceId": source.id?.toString(),
      }),
    );
    final data = jsonDecode(res.body) as List;
    return data
        .map(
          (e) => SourcePreference.fromJson(e)
            ..id = null
            ..sourceId = source.id,
        )
        .toList();
  } catch (_) {
    return null;
  }
}

String _convertLang(dynamic e) {
  return ExtensionStoreService.convertLnreaderLang(e);
}


/// YomiHub keeps its own version number (0.1.x) but runs the Mangayomi 0.9.7
/// extension engine. Repositories state "min app version" against
/// Mangayomi, so comparing with YomiHub's own number hid almost every
/// extension of Mangayomi-format repositories.
const String kYomiEngineVersion = '0.9.7';
String yomiEngineVersion(String appVersion) =>
    compareVersions(appVersion, kYomiEngineVersion) > 0 ? appVersion : kYomiEngineVersion;


/// YomiHub 0.2.2: sanity check of a downloaded extension before it replaces
/// the installed one.
bool yomiLooksLikeExtensionCode(
  SourceCodeLanguage lang,
  List<int> bytes,
  String Function() body,
) {
  if (bytes.length < 16) return false;
  switch (lang) {
    case SourceCodeLanguage.mihon:
    case SourceCodeLanguage.aidoku:
      return bytes[0] == 0x50 && bytes[1] == 0x4b;
    case SourceCodeLanguage.javascript:
      final b = body();
      return b.contains('DefaultExtension') || b.contains('mangayomiSources');
    case SourceCodeLanguage.dart:
      final b = body();
      return b.contains('class ') || b.contains('getSource');
    case SourceCodeLanguage.lnreader:
      final b = body();
      return !b.trimLeft().startsWith('<');
  }
}


/// YomiHub 0.2.2: an error that has already been written to the app log.
class YomiLoggedError implements Exception {
  final Object inner;
  YomiLoggedError(this.inner);
  @override
  String toString() => inner.toString();
}


String? yomiFixRepoUrl(String? u) {
  if (u == null || !u.contains('ranchName')) return u;
  return u
      .replaceAll('/bbranchNamee/', '/main/')
      .replaceAll('/{branchName}/', '/main/')
      .replaceAll('/\${branchName}/', '/main/')
      .replaceAll('/branchName/', '/main/');
}
