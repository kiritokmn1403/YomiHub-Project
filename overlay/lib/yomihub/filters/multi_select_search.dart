import 'package:mangayomi/eval/model/filter.dart';
import 'package:mangayomi/eval/model/m_manga.dart';
import 'package:mangayomi/eval/model/m_pages.dart';
import 'package:mangayomi/utils/log/logger.dart';

/// YomiHub 0.6.1 (yêu cầu chủ dự án 19/11/2026 17:29): mọi mục lựa chọn trong
/// bộ lọc là ô chọn và chọn được NHIỀU ô cùng lúc.
///
/// Giao thức tiện ích (Mihon/Aniyomi `Filter.Select`, Mangayomi `SelectFilter`,
/// Kotatsu, LNReader `Picker`, Aidoku `Select`) chỉ nhận MỘT chỉ số. Khi người
/// dùng chọn nhiều ô của một SelectFilter, YomiHub tìm lần lượt với từng ô
/// (tối đa [kYomiMultiMaxVariants] lượt) rồi gộp kết quả, bỏ trùng theo link –
/// tức phép "HOẶC" giữa các ô đã chọn. Nhóm ô chọn/ba trạng thái (Group) vốn đã
/// chọn nhiều ở phía tiện ích nên không cần tách.

/// Số lượt tìm tối đa cho một trang khi chọn nhiều.
const int kYomiMultiMaxVariants = 6;

final RegExp _sortLike = RegExp(
  r'(sort|order|ordenar|trier|tri |sắp xếp|sap xep|xếp theo|thứ tự|sırala|sortieren|ordina|並べ|排序|정렬|'
  r'search (by|type)|tìm theo|tìm kiếm theo|kiểu tìm|buscar por|rechercher par)',
  caseSensitive: false,
);

final RegExp _allLike = RegExp(
  r'^\s*(all|any|none|default|tất cả|tat ca|mọi|bất kỳ|todos?|todas?|tous|toutes|alle|tutti|全部|すべて|전체|все|hepsi|semua|ทั้งหมด|-+|—|\*)\s*$',
  caseSensitive: false,
);

String _label(dynamic o) {
  try {
    return '${o.name}';
  } catch (_) {
    return '$o';
  }
}

/// Bộ lọc kiểu sắp xếp / "tìm theo" chỉ chọn một (gộp kết quả vô nghĩa).
bool yomiSelectMultiAllowed(SelectFilter f) => f.values.length > 2 && !_sortLike.hasMatch(f.name);

/// Ô [i] là lựa chọn "Tất cả / Mặc định".
bool yomiSelectIsAll(SelectFilter f, int i) =>
    i >= 0 && i < f.values.length && _allLike.hasMatch(_label(f.values[i]));

/// Các ô đang chọn (luôn ≥ 1 phần tử).
List<int> yomiSelectChosen(SelectFilter f) {
  final n = f.values.length;
  final out = f.multi.where((i) => i >= 0 && i < n).toSet().toList()..sort();
  if (out.length > 1) return out;
  final s = (f.state >= 0 && f.state < n) ? f.state : 0;
  return [s];
}

/// Bấm ô [i]: chọn nhiều nếu được phép, nếu không thì chọn một.
/// Trả về true nếu có thay đổi.
bool yomiSelectToggle(SelectFilter f, int i) {
  final n = f.values.length;
  if (i < 0 || i >= n) return false;
  final before = '${f.state}|${f.multi}';
  if (!yomiSelectMultiAllowed(f)) {
    f.multi = <int>[];
    f.state = i;
    return before != '${f.state}|${f.multi}';
  }
  final cur = yomiSelectChosen(f).toSet();
  if (yomiSelectIsAll(f, i)) {
    cur
      ..clear()
      ..add(i);
  } else if (cur.contains(i)) {
    cur.remove(i);
  } else {
    cur.removeWhere((k) => yomiSelectIsAll(f, k));
    cur.add(i);
  }
  if (cur.isEmpty) {
    // bỏ hết → quay về ô "Tất cả" nếu có, không thì ô đầu
    var d = 0;
    for (var k = 0; k < n; k++) {
      if (yomiSelectIsAll(f, k)) {
        d = k;
        break;
      }
    }
    cur.add(d);
  }
  final list = cur.toList()..sort();
  f.state = list.first;
  f.multi = list.length > 1 ? list : <int>[];
  return before != '${f.state}|${f.multi}';
}

/// Tách danh sách bộ lọc có SelectFilter chọn nhiều thành các bản chọn một.
/// Trả về `[filters]` khi không có chọn nhiều.
List<List<dynamic>> yomiExpandMultiSelect(List<dynamic> filters) {
  List<List<dynamic>> variants = [filters];
  for (var idx = 0; idx < filters.length; idx++) {
    final f = filters[idx];
    if (f is! SelectFilter || f.multi.length < 2) continue;
    final chosen = yomiSelectChosen(f);
    final next = <List<dynamic>>[];
    for (final v in variants) {
      for (final c in chosen) {
        if (next.length >= kYomiMultiMaxVariants) break;
        final copy = _copy(v);
        final sf = copy[idx] as SelectFilter;
        sf.state = c;
        sf.multi = <int>[];
        next.add(copy);
      }
    }
    variants = next;
  }
  if (variants.length > 1) {
    // các SelectFilter chọn nhiều còn lại (khi đã chạm trần) → chỉ ô đầu
    for (final v in variants) {
      for (final f in v) {
        if (f is SelectFilter) f.multi = <int>[];
      }
    }
  }
  return variants;
}

List<dynamic> _copy(List<dynamic> filters) =>
    FilterList.fromJson(FilterList(filters).toJson()).filters;

/// Gộp kết quả nhiều lượt tìm, bỏ trùng theo link (hoặc tên khi thiếu link).
MPages yomiMergePages(List<MPages?> pages) {
  final seen = <String>{};
  final list = <MManga>[];
  var hasNext = false;
  for (final p in pages) {
    if (p == null) continue;
    hasNext = hasNext || p.hasNextPage;
    for (final m in p.list) {
      final key = (m.link?.isNotEmpty ?? false) ? m.link! : '${m.name}';
      if (seen.add(key)) list.add(m);
    }
  }
  return MPages(list: list, hasNextPage: hasNext);
}

/// Chạy [run] cho từng bản bộ lọc và gộp; lỗi của một lượt được ghi nhật ký,
/// chỉ ném lỗi khi mọi lượt đều lỗi.
Future<MPages?> yomiSearchMulti(
  List<dynamic> filters,
  Future<MPages?> Function(List<dynamic> filters) run, {
  String sourceName = '',
}) async {
  final variants = yomiExpandMultiSelect(filters);
  if (variants.length <= 1) return run(variants.first);
  Object? lastErr;
  final results = await Future.wait(
    variants.map((v) async {
      try {
        return await run(v);
      } catch (e) {
        lastErr = e;
        AppLogger.logOnce(
          'multi_sel:$sourceName:$e',
          '[Bộ lọc] Chọn nhiều – một lượt tìm của "$sourceName" lỗi: $e',
          logLevel: LogLevel.warning,
        );
        return null;
      }
    }),
  );
  if (results.every((r) => r == null) && lastErr != null) throw lastErr!;
  return yomiMergePages(results);
}
