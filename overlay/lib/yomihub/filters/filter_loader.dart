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
          // 0.2.3: the extension has no filters. 0.5.7: INFO line, not a failure.
          AppLogger.logOnce(
            'filter_none:${source.id}',
            '[Bộ lọc] "${source.name}" (${source.lang}, ${source.sourceCodeLanguage.name}) không có bộ lọc',
            logLevel: LogLevel.info,
          );
          return (filters: null, error: null);
        }
        if (out == null) {
          // 0.5.7: only a real failure (exception / timeout) reaches the WARNING
          // 0.6.1: tiện ích tải Thể loại từ chính trang nguồn (KeiSource
          // fetchFilterData) – trang bị nhà mạng chặn (DamCoNuong 19/11:
          // DNS NXDOMAIN + TLS bị cắt) thì không nạp được → nói rõ cách xử lý.
          err = YomiFilterRefresh.lastError[source.id] ??
              'tiện ích không trả về danh sách bộ lọc (sau 3 lần thử) – danh sách thể loại được tải từ trang nguồn, '
                  'nếu trang không vào được (bị chặn/lỗi mạng) hãy bật VPN/Tor cho tiện ích này rồi bấm "Đặt lại"';
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
      // 0.6.2: còn bộ lọc khác dùng được → hiện chúng + cảnh báo thể loại
      final usable = out.where((f) => !YomiFilterRefresh.needsLoad([f])).isNotEmpty;
      if (usable) {
        final why = YomiFilterRefresh.lastError[source.id] ?? 'thể loại chưa tải';
        AppLogger.logOnce(
          'filter_partial:${source.id}',
          '[Bộ lọc] "${source.name}" (${source.lang}, ${source.sourceCodeLanguage.name}): '
          'dùng bộ lọc hiện có, danh sách thể loại chưa tải được ($why)',
          logLevel: LogLevel.warning,
        );
        return (
          filters: out,
          error: tr(
            'Chưa tải được danh sách Thể loại từ trang nguồn – các bộ lọc khác vẫn dùng được. Nếu trang bị chặn hãy bật VPN/Tor cho tiện ích này rồi bấm "Nạp bộ lọc".',
          ),
        );
      }
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
