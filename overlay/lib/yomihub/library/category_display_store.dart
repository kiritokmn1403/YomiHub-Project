// YomiHub 0.6.6 (A7, phần dở 0.6.5 – sheet YomiHub Update "cách hiển thị /
// cách sắp xếp từng mục trong Danh Mục"): per-category display type, sort and
// order, kept in the yomihub_prefs Hive box under `categoryDisplay` so it is
// part of every app backup / cloud sync without a schema change.
//
// Keyed by "<ItemType.index>|<category name>" (stable across a merge restore,
// which gives categories new ids – design: audit/audit-0.6.5/copilot/
// A7_category_display_backup.md). Missing values = the global library setting.
import 'package:flutter/foundation.dart';
import 'package:mangayomi/models/manga.dart' show ItemType;
import 'package:mangayomi/models/settings.dart' show DisplayType;
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';

class CategoryDisplay {
  const CategoryDisplay({this.display, this.sort, this.reverse});
  final DisplayType? display;
  final int? sort;
  final bool? reverse;

  bool get isEmpty => display == null && sort == null && reverse == null;

  Map<String, dynamic> toJson() => {
        if (display != null) 'display': display!.index,
        if (sort != null) 'sort': sort,
        if (reverse != null) 'reverse': reverse,
      };

  static CategoryDisplay? fromJson(Object? v) {
    if (v is! Map) return null;
    final d = v['display'];
    final s = v['sort'];
    final r = v['reverse'];
    final out = CategoryDisplay(
      display: d is int && d >= 0 && d < DisplayType.values.length ? DisplayType.values[d] : null,
      sort: s is int && s >= 0 && s <= 6 ? s : null,
      reverse: r is bool ? r : null,
    );
    return out.isEmpty ? null : out;
  }
}

class CategoryDisplayStore {
  static const key = 'categoryDisplay';

  static String keyOf(ItemType t, String name) => '${t.index}|$name';

  static Map<String, dynamic> _items() {
    if (!YomiPrefs.isOpen) return <String, dynamic>{};
    final raw = YomiPrefs.get<Object?>(key, null);
    final items = raw is Map ? raw['items'] : null;
    return items is Map ? items.map((k, v) => MapEntry('$k', v)) : <String, dynamic>{};
  }

  static CategoryDisplay? of(ItemType t, String? name) {
    if (name == null || name.isEmpty) return null;
    return CategoryDisplay.fromJson(_items()[keyOf(t, name)]);
  }

  /// Saves [value] for the category; an empty value removes the entry.
  static Future<void> put(ItemType t, String name, CategoryDisplay value) async {
    final items = _items();
    if (value.isEmpty) {
      items.remove(keyOf(t, name));
    } else {
      items[keyOf(t, name)] = value.toJson();
    }
    await YomiPrefs.set(key, {'v': 1, 'items': items});
  }

  /// Keeps the setting when a category is renamed.
  static Future<void> rename(ItemType t, String oldName, String newName) async {
    final items = _items();
    final v = items.remove(keyOf(t, oldName));
    if (v == null) return;
    items[keyOf(t, newName)] = v;
    await YomiPrefs.set(key, {'v': 1, 'items': items});
  }

  /// Merge restore: entries of this device win, the backup adds the others.
  @visibleForTesting
  static Map<String, dynamic> merge(Map current, Map incoming) {
    final out = <String, dynamic>{for (final e in incoming.entries) '${e.key}': e.value};
    for (final e in current.entries) {
      out['${e.key}'] = e.value;
    }
    return out;
  }
}
