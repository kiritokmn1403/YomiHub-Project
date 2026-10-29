import 'dart:async';

import 'package:mangayomi/eval/lib.dart';
import 'package:mangayomi/models/source.dart';
import 'package:mangayomi/services/get_filter_list.dart';
import 'package:mangayomi/utils/log/logger.dart';
import 'package:mangayomi/yomihub/filters/filter_refresh.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';

/// YomiHub 0.2.2: loads the complete filter list of any extension while the
/// filter menu is already on screen (YomiHub Update: "khi ấn vào vẫn phải
/// hiển thị menu Bộ Lọc ra trước, rồi mới bắt đầu tự động load toàn bộ
/// filter; nếu không load được hãy ghi lỗi này vào Nhật Ký Ứng Dụng").
class YomiFilterLoader {
  YomiFilterLoader._();

  /// The list is empty or only the "Tap 'Reset' to load filters" placeholder.
  static bool needsLoad(Source source, List<dynamic> filters) =>
      (filters.isEmpty && !YomiFilterRefresh.noFilters.contains(source.id)) ||
      YomiFilterRefresh.needsLoad(filters);

  static Future<({List<dynamic>? filters, String? error})> loadAll(
    Source source,
    List<dynamic> current,
  ) async {
    Object? err;
    List<dynamic>? out;
    try {
      if (YomiFilterRefresh.supports(source)) {
        out = await YomiFilterRefresh.load(source, force: true)
            .timeout(const Duration(seconds: 90), onTimeout: () => null);
        if (out != null && out.isEmpty) {
          return (filters: null, error: null); // 0.2.3: the extension has no filters
        }
        if (out == null) {
          err = 'tiện ích không trả về danh sách bộ lọc (sau 3 lần thử)'
              '${YomiFilterRefresh.lastError[source.id] != null ? ' – ${YomiFilterRefresh.lastError[source.id]}' : ''}';
        }
      } else {
        // JS / Dart / Aidoku / LNReader: build the list again from a fresh
        // service (a cached one may hold a list made before the site answered)
        invalidateExtensionService(source.id);
        await Future<void>.delayed(Duration.zero);
        out = await Future(() => getFilterList(source: source))
            .timeout(const Duration(seconds: 30));
        if (out.isEmpty) out = null; // the extension has no filters
      }
    } on TimeoutException {
      err = 'hết thời gian chờ';
    } catch (e) {
      err = e;
    }
    if (out != null && YomiFilterRefresh.needsLoad(out)) {
      err ??= 'bộ lọc vẫn chỉ là dòng "Tap Reset to load filters"';
      out = null;
    }
    if (out == null && current.isNotEmpty && !YomiFilterRefresh.needsLoad(current)) {
      AppLogger.logOnce(
        'filter_fallback:${source.id}',
        '[Bộ lọc] "${source.name}" sử dụng bộ lọc đã lưu (tải mới không thành công: $err)',
        logLevel: LogLevel.info,
      );
      return (filters: current, error: null);
    }
    if (err != null) {
      AppLogger.logOnce(
        'filter_err:${source.id}',
        '[Bộ lọc] Không tải được bộ lọc của "${source.name}" '
        '(${source.lang}, ${source.sourceCodeLanguage.name}): $err',
        logLevel: LogLevel.warning,
      );
      return (
        filters: null,
        error: tr('Không tải được bộ lọc – đã ghi vào Nhật ký ứng dụng. Bấm "Đặt lại" để thử lại.'),
      );
    }
    return (filters: out, error: null);
  }
}
