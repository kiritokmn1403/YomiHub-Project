import 'package:mangayomi/eval/model/filter.dart';

/// YomiHub 0.1.8: every source page has the three buttons Popular · Latest ·
/// Filter. Sources that don't implement "latest" get it from their own
/// filters: the sort / order option meaning "newest / recently updated" is
/// selected and the source is searched with it.
class YomiLatestEmulation {
  static final _latest = RegExp(
    r'(latest|newest|recent|update|updated|last ?update|date added|added|new|'
    r'mới|cập nhật|最新|更新|新|novo|novos|nuevo|recientes|récent|nouveau|neu|aktual|'
    r'последн|новы|обновл|ล่าสุด|ใหม่|terbaru|baru|yeni|son|최신|업데이트|nuovi|recenti)',
    caseSensitive: false,
  );

  static String _name(dynamic o) =>
      o is SelectFilterOption ? '${o.name} ${o.value}' : '$o';

  static int _best(List<dynamic> values) {
    var best = -1;
    var bestScore = 0;
    for (var i = 0; i < values.length; i++) {
      final n = _name(values[i]).toLowerCase();
      if (!_latest.hasMatch(n)) continue;
      var score = 1;
      if (RegExp(r'update|cập nhật|更新|обновл|업데이트').hasMatch(n)) score += 2;
      if (RegExp(r'latest|newest|mới nhất|最新|최신').hasMatch(n)) score += 2;
      if (RegExp(r'old|cũ|asc').hasMatch(n)) score -= 3;
      if (score > bestScore) {
        bestScore = score;
        best = i;
      }
    }
    return best;
  }

  /// A copy of [filters] sorted by "latest", or null if the source has no
  /// such option.
  static List<dynamic>? apply(List<dynamic> filters) {
    if (filters.isEmpty) return null;
    List<dynamic> copy;
    try {
      copy = FilterList.fromJson(FilterList(filters).toJson()).filters;
    } catch (_) {
      return null;
    }
    bool walk(List<dynamic> list) {
      for (final f in list) {
        if (f is SortFilter) {
          final i = _best(f.values);
          if (i >= 0) {
            f.state = SortState(i, false, "SortState");
            return true;
          }
        } else if (f is GroupFilter) {
          if (walk(f.state)) return true;
        }
      }
      for (final f in list) {
        if (f is SelectFilter &&
            RegExp(r'sort|order|sắp|xếp|排序|順|정렬|ordenar|trier|sortieren|сорт|เรียง|urut|sırala', caseSensitive: false)
                .hasMatch(f.name)) {
          final i = _best(f.values);
          if (i >= 0) {
            f.state = i;
            return true;
          }
        }
      }
      return false;
    }

    return walk(copy) ? copy : null;
  }
}
