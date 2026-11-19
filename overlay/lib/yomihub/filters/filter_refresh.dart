import 'dart:async';
import 'dart:convert';

import 'package:mangayomi/eval/lib.dart';
import 'package:mangayomi/eval/model/filter.dart';
import 'package:mangayomi/eval/model/m_pages.dart';
import 'package:mangayomi/models/source.dart';
import 'package:mangayomi/repositories/source_repository.dart';
import 'package:mangayomi/services/fetch_sources_list.dart';
import 'package:mangayomi/services/http/m_client.dart';
import 'package:mangayomi/services/isolate_service.dart';
import 'package:mangayomi/utils/log/logger.dart';
import 'package:mangayomi/yomihub/mes/yomi_mes.dart';

/// YomiHub 0.2.1: Aniyomi / Nekoyomi / Mihon extensions whose filters say
/// "Tap 'Reset' to load filters" (genres are fetched from the site after
/// the first request). Mangayomi stored the filter list once, at install
/// time, so the hint stayed there forever and Reset only restored it.
///
/// Now the filters are fetched again from the extension (warming it up with
/// a popular-page request first) and stored – without the user pressing
/// Reset. Reset still works and also reloads them.
class YomiFilterRefresh {
  YomiFilterRefresh._();

  static final RegExp _hint = RegExp(
    r'''((tap|press|click|hit|nhấn|bấm|toque|appuyez|tippe)\W{0,3}(on\W{0,3})?['"“”‘’]?\s*(reset|đặt lại|redefinir|réinitialiser)|'''
    r'''reset['"“”‘’]?\s*(to|để|para|pour)\s*(load|show|get|tải|hiện|carregar|cargar)|'''
    r'''(load|loading) (the )?(filters|genres|tags)|tải bộ lọc|filters? (are )?not loaded|'''
    r'''search (once|first)|(try|press) (searching|reset))''',
    caseSensitive: false,
  );

  static final Map<int, Future<List<dynamic>?>> _running = {};
  static final Map<int, DateTime> _failedAt = {};
  /// 0.2.3: why the last load failed (shown in the app log), and sources
  /// whose extension really has no filters (not an error).
  static final Map<int, String> lastError = {};
  static final Set<int> noFilters = {};
  /// 0.6.2: tiện ích chỉ trả bộ lọc một phần (thể loại vẫn là dòng "Tap Reset").
  static final Set<int> partialOnly = {};

  static String _names(List<dynamic> filters) {
    try {
      return jsonEncode(FilterList(filters).toJson());
    } catch (_) {
      return filters.map((e) {
        try {
          return '${(e as dynamic).name}';
        } catch (_) {
          return '';
        }
      }).join('|');
    }
  }

  /// true when the filter list only carries the "tap Reset" placeholder.
  static bool needsLoad(List<dynamic> filters) =>
      filters.isNotEmpty && _hint.hasMatch(_names(filters));

  static bool supports(Source s) =>
      s.sourceCodeLanguage == SourceCodeLanguage.mihon;

  /// Fetches the real filters; null when they could not be loaded.
  static Future<List<dynamic>?> load(Source source, {bool force = false}) {
    final id = source.id;
    if (id == null || !supports(source)) return Future.value(null);
    final f = _failedAt[id];
    if (!force && f != null && DateTime.now().difference(f) < const Duration(minutes: 5)) {
      return Future.value(null);
    }
    return _running[id] ??= _load(source).whenComplete(() => _running.remove(id));
  }

  static Future<List<dynamic>?> _load(Source source) async {
    try {
      final mes = await YomiMes.ensure() ?? '';
      final client = MClient.init(reqcopyWith: {'useDartHttpClient': true});
      FilterList? lastFl;
      for (var attempt = 0; attempt < 3; attempt++) {
        yomiLastFilterFetchError = null;
        final fl = await fetchFilterListDalvik(client, source, mes).timeout(
          const Duration(seconds: 20),
          onTimeout: () {
            yomiLastFilterFetchError = 'hết thời gian chờ 20 giây';
            return null;
          },
        );
        if (fl != null && fl.filters.isEmpty) {
          // 0.5.7 (S1): the extension answered, with no filters at all: that
          // is a valid answer, not a failure - no retry (logs 7: VinaHentai
          // was asked 3 times and then logged as an error).
          noFilters.add(source.id!);
          lastError.remove(source.id);
          return const [];
        }
        if (fl != null && fl.filters.isNotEmpty) lastFl = fl;
        if (fl == null && yomiLastFilterFetchError != null) {
          lastError[source.id!] = 'lỗi khi tải bộ lọc: $yomiLastFilterFetchError';
        }
        if (fl != null && fl.filters.isNotEmpty && !needsLoad(fl.filters)) {
          source.filterList = jsonEncode(fl.toJson());
          lastError.remove(source.id);
          final row = sourceRepository.getById(source.id!);
          if (row != null) {
            row.filterList = source.filterList;
            await sourceRepository.save(row);
          }
          invalidateExtensionService(source.id);
          _failedAt.remove(source.id);
          partialOnly.remove(source.id);
          return fl.filters;
        }
        // most extensions fetch their genre list during the first
        // popular / search request: make one, then ask again
        try {
          // 0.6.2: lượt 2 làm nóng bằng tìm kiếm rỗng – nhiều tiện ích (Madara,
          // Comick, MeHentai…) chỉ nạp thể loại khi tìm kiếm, không phải ở
          // trang phổ biến (log 19/11 21:51–21:56: 3 tiện ích "không trả về
          // danh sách bộ lọc (sau 3 lần thử)").
          if (attempt == 1) {
            await getIsolateService
                .get<MPages?>(
                  source: source,
                  page: 1,
                  query: '',
                  filterList: lastFl?.filters ?? const [],
                  serviceType: 'search',
                )
                .timeout(const Duration(seconds: 25));
          } else {
            await getIsolateService
                .get<MPages?>(source: source, page: 1, serviceType: 'getPopular')
                .timeout(const Duration(seconds: 25));
          }
        } catch (e) {
          lastError[source.id!] = 'trang nguồn không tải được (${'$e'.split('\n').first})';
        }
        await Future.delayed(Duration(milliseconds: 400 * (attempt + 1)));
      }
      // 0.6.2: tiện ích vẫn chỉ có dòng "Tap Reset…" nhưng còn các bộ lọc khác
      // dùng được (Sắp xếp, Trạng thái…) → trả về để người dùng vẫn lọc được;
      // loadAll ghi cảnh báo "thể loại chưa tải" thay vì báo hỏng cả bộ lọc.
      final partial = lastFl?.filters.where((f) => !needsLoad([f])).toList();
      if (partial != null && partial.isNotEmpty) {
        _failedAt[source.id!] = DateTime.now();
        partialOnly.add(source.id!);
        lastError[source.id!] ??= 'tiện ích chưa nạp được danh sách thể loại từ trang nguồn';
        return lastFl!.filters;
      }
    } catch (e) {
      AppLogger.logOnce('filters:${source.id}', 'Filters of "${source.name}" could not be loaded: $e');
    }
    _failedAt[source.id!] = DateTime.now();
    // Fallback: if previously cached filters exist in db/source, use them
    final cached = source.filterList;
    if (cached != null && cached.isNotEmpty) {
      try {
        final decoded = jsonDecode(cached);
        final list = (decoded is List ? decoded : (decoded is Map ? decoded['filters'] : null)) as List<dynamic>?;
        if (list != null && list.isNotEmpty && !needsLoad(list)) {
          return list;
        }
      } catch (_) {}
    }
    return null;
  }
}
