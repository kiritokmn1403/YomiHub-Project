import 'package:mangayomi/yomihub/prefs/yomi_hive.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mangayomi/yomihub/ui/liquid_glass.dart';
import 'package:hive/hive.dart';
import 'package:mangayomi/eval/model/filter.dart';
import 'package:mangayomi/eval/model/m_manga.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/models/source.dart';
import 'package:mangayomi/modules/manga/home/widget/filter_widget.dart';
import 'package:mangayomi/yomihub/filters/filter_profiles.dart';

/// YomiHub filter helpers that work for every extension (JavaScript, Dart,
/// Mihon/Aniyomi APK, Aidoku, LNReader…), taken from Aniyomi / Nekoyomi:
///  * search inside long filter lists (Nekoyomi's filter search),
///  * saved filter presets per source (Komikku / Nekoyomi saved searches),
///  * result filters applied on the client: hide titles already in the
///    library and hide titles containing excluded words.
class YomiFilterStore {
  static const _box = 'yomihub_filters';

  static Box? _b;
  static Future<Box> open() async =>
      _b ??= Hive.isBoxOpen(_box) ? Hive.box(_box) : await YomiHive.open(_box);

  static Map<String, String> presets(int sourceId) {
    final raw = _b?.get('presets_$sourceId');
    if (raw is Map) return raw.map((k, v) => MapEntry('$k', '$v'));
    return {};
  }

  static Future<void> savePreset(int sourceId, String name, List<dynamic> filters) async {
    final b = await open();
    final p = presets(sourceId)..[name] = jsonEncode(FilterList(filters).toJson());
    await b.put('presets_$sourceId', p);
  }

  static Future<void> deletePreset(int sourceId, String name) async {
    final b = await open();
    final p = presets(sourceId)..remove(name);
    await b.put('presets_$sourceId', p);
  }

  static List<dynamic>? loadPreset(int sourceId, String name) {
    final j = presets(sourceId)[name];
    if (j == null) return null;
    try {
      return FilterList.fromJson(jsonDecode(j) as Map<String, dynamic>).filters;
    } catch (_) {
      return null;
    }
  }

  // Result filters are stored per source; when "global" is on for a
  // source, the shared settings under id 0 are used instead (Aniyomi-style
  // filters that follow you to every extension).
  static bool isGlobal(int sourceId) => (_b?.get('global_$sourceId') ?? false) as bool;
  static Future<void> setGlobal(int sourceId, bool v) async => (await open()).put('global_$sourceId', v);
  static int _k(int sourceId) => isGlobal(sourceId) ? 0 : sourceId;

  static bool hideLibrary(int sourceId) => (_b?.get('hidelib_${_k(sourceId)}') ?? false) as bool;
  static bool hideRead(int sourceId) => (_b?.get('hideread_${_k(sourceId)}') ?? false) as bool;
  static bool needCover(int sourceId) => (_b?.get('cover_${_k(sourceId)}') ?? false) as bool;
  static String excluded(int sourceId) => (_b?.get('exclude_${_k(sourceId)}') ?? '') as String;
  static String included(int sourceId) => (_b?.get('include_${_k(sourceId)}') ?? '') as String;

  static Future<void> setHideLibrary(int sourceId, bool v) async =>
      (await open()).put('hidelib_${_k(sourceId)}', v);
  static Future<void> setHideRead(int sourceId, bool v) async =>
      (await open()).put('hideread_${_k(sourceId)}', v);
  static Future<void> setNeedCover(int sourceId, bool v) async =>
      (await open()).put('cover_${_k(sourceId)}', v);
  static Future<void> setExcluded(int sourceId, String v) async =>
      (await open()).put('exclude_${_k(sourceId)}', v);
  static Future<void> setIncluded(int sourceId, String v) async =>
      (await open()).put('include_${_k(sourceId)}', v);

  /// Saved preset applied automatically when the source is opened
  /// (Komikku / Nekoyomi "default saved search").
  static String? defaultPreset(int sourceId) => _b?.get('default_$sourceId') as String?;
  static Future<void> setDefaultPreset(int sourceId, String? name) async {
    final b = await open();
    if (name == null) {
      await b.delete('default_$sourceId');
    } else {
      await b.put('default_$sourceId', name);
    }
  }

  static bool hasResultFilters(int sourceId) =>
      hideLibrary(sourceId) ||
      hideRead(sourceId) ||
      needCover(sourceId) ||
      excluded(sourceId).trim().isNotEmpty ||
      included(sourceId).trim().isNotEmpty;

  static List<String> _words(String s) =>
      s.split(',').map((e) => e.trim().toLowerCase()).where((e) => e.isNotEmpty).toList();

  /// Number of filters that differ from the extension's defaults, shown as
  /// a badge like Aniyomi's filter button.
  static int activeCount(List<dynamic> current, List<dynamic> defaults) {
    try {
      final a = FilterList(current).toJson().toString();
      final b = FilterList(defaults).toJson().toString();
      if (a == b) return 0;
      var n = 0;
      for (var i = 0; i < current.length && i < defaults.length; i++) {
        if (FilterList([current[i]]).toJson().toString() != FilterList([defaults[i]]).toJson().toString()) n++;
      }
      return n == 0 ? 1 : n;
    } catch (_) {
      return 0;
    }
  }

  /// Applies the client-side result filters to one page of results.
  static List<MManga> apply(
    List<MManga> list,
    Source source,
    Map<String, Manga> library,
  ) {
    final id = source.id ?? 0;
    if (!hasResultFilters(id)) return list;
    final hide = hideLibrary(id);
    final read = hideRead(id);
    final cover = needCover(id);
    final words = _words(excluded(id));
    final must = _words(included(id));
    return list.where((m) {
      final name = (m.name ?? '').toLowerCase();
      final genres = (m.genre ?? const []).map((g) => g.toLowerCase()).toList();
      final lib = library[m.name];
      if (hide && (lib?.favorite ?? false)) return false;
      if (read && (lib?.lastRead ?? 0) > 0) return false;
      if (cover && (m.imageUrl ?? '').trim().isEmpty) return false;
      for (final w in words) {
        if (name.contains(w)) return false;
        if (genres.any((g) => g == w)) return false;
      }
      if (must.isNotEmpty &&
          !must.any((w) => name.contains(w) || genres.any((g) => g.contains(w)))) {
        return false;
      }
      return true;
    }).toList();
  }
}

int _leafCount(List<dynamic> list) {
  var n = 0;
  for (final f in list) {
    if (f is GroupFilter) {
      n += _leafCount(f.state);
    } else if (f is HeaderFilter || f is SeparatorFilter) {
      continue;
    } else {
      n++;
    }
  }
  return n;
}

String _nameOf(dynamic f) {
  try {
    return (f.name ?? '').toString();
  } catch (_) {
    return '';
  }
}

/// Bottom-sheet body replacing the plain filter list.
class YomiFilterSheet extends StatefulWidget {
  final Source source;
  final List<dynamic> filters;
  final void Function(List<dynamic>) onChanged;
  final VoidCallback onReset;
  final VoidCallback onFilter;
  final Future<void> Function()? onLoadFilter;
  final String filterLabel;
  final String resetLabel;

  /// YomiHub 0.2.2: the sheet opens at once; while the extension's real
  /// filters are still being fetched a progress bar + note is shown.
  final bool loading;
  final String? loadError;
  const YomiFilterSheet({
    this.loading = false,
    this.loadError,
    this.onLoadFilter,
    super.key,
    required this.source,
    required this.filters,
    required this.onChanged,
    required this.onReset,
    required this.onFilter,
    required this.filterLabel,
    required this.resetLabel,
  });

  @override
  State<YomiFilterSheet> createState() => _YomiFilterSheetState();
}

class _YomiFilterSheetState extends State<YomiFilterSheet> {
  String _query = '';
  bool _ready = false;
  late final TextEditingController _exclude;
  late final TextEditingController _include;

  int get _id => widget.source.id ?? 0;

  @override
  void initState() {
    super.initState();
    _exclude = TextEditingController();
    _include = TextEditingController();
    YomiFilterStore.open().then((_) {
      if (!mounted) return;
      setState(() {
        _exclude.text = YomiFilterStore.excluded(_id);
        _include.text = YomiFilterStore.included(_id);
        _ready = true;
      });
    });
  }

  @override
  void dispose() {
    _exclude.dispose();
    _include.dispose();
    super.dispose();
  }

  /// When searching, show matching options under their group's name.
  List<dynamic> _visible() {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.filters;
    final out = <dynamic>[];
    for (final f in widget.filters) {
      if (f is GroupFilter) {
        final hits = f.state.where((e) => _nameOf(e).toLowerCase().contains(q)).toList();
        if (hits.isNotEmpty) {
          out.add(HeaderFilter(f.name, 'HeaderFilter'));
          out.addAll(hits);
        }
      } else if (f is HeaderFilter || f is SeparatorFilter) {
        continue;
      } else if (_nameOf(f).toLowerCase().contains(q)) {
        out.add(f);
      }
    }
    return out;
  }

  Future<void> _presets() async {
    final names = YomiFilterStore.presets(_id).keys.toList();
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('Bộ lọc đã lưu', style: TextStyle(fontWeight: FontWeight.bold))),
            if (widget.onLoadFilter != null)
              ListTile(
                leading: const Icon(Icons.refresh),
                title: Text(tr('Nạp lại bộ lọc (Load Filter)')),
                subtitle: Text(tr('Tải lại toàn bộ danh mục bộ lọc từ nguồn')),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onLoadFilter!();
                },
              ),
            ListTile(
              leading: const Icon(Icons.save_outlined),
              title: Text(tr('Lưu bộ lọc hiện tại…')),
              onTap: () => Navigator.pop(ctx, '\u0000save'),
            ),
            for (final n in names)
              ListTile(
                leading: Icon(
                  YomiFilterStore.defaultPreset(_id) == n ? Icons.star : Icons.bookmark_outline,
                ),
                title: Text(n),
                subtitle: YomiFilterStore.defaultPreset(_id) == n
                    ? Text(tr('Mặc định khi mở nguồn'))
                    : null,
                onTap: () => Navigator.pop(ctx, n),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: tr('Đặt làm mặc định'),
                      icon: Icon(YomiFilterStore.defaultPreset(_id) == n ? Icons.star : Icons.star_border),
                      onPressed: () => Navigator.pop(ctx, '\u0000def$n'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => Navigator.pop(ctx, '\u0000del$n'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;
    if (action == '\u0000save') {
      final ctrl = TextEditingController();
      final name = await showDialog<String>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(tr('Tên bộ lọc')),
          content: TextField(controller: ctrl, autofocus: true),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: Text(tr('Hủy'))),
            FilledButton(onPressed: () => Navigator.pop(c, ctrl.text.trim()), child: Text(tr('Lưu'))),
          ],
        ),
      );
      if (name != null && name.isNotEmpty) {
        await YomiFilterStore.savePreset(_id, name, widget.filters);
        if (mounted) setState(() {});
      }
    } else if (action.startsWith('\u0000def')) {
      final n = action.substring(4);
      await YomiFilterStore.setDefaultPreset(_id, YomiFilterStore.defaultPreset(_id) == n ? null : n);
      if (mounted) setState(() {});
    } else if (action.startsWith('\u0000del')) {
      final n = action.substring(4);
      await YomiFilterStore.deletePreset(_id, n);
      if (YomiFilterStore.defaultPreset(_id) == n) await YomiFilterStore.setDefaultPreset(_id, null);
      if (mounted) setState(() {});
    } else {
      final loaded = YomiFilterStore.loadPreset(_id, action);
      if (loaded != null) {
        widget.onChanged(loaded);
        widget.onFilter();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final showSearch = _leafCount(widget.filters) >= 10;
    final visible = _visible();
    final body = SafeArea(
      top: false,
      child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              TextButton(onPressed: widget.onReset, child: Text(widget.resetLabel)),
              if (widget.onLoadFilter != null)
                TextButton.icon(
                  icon: const Icon(Icons.refresh, size: 16),
                  label: Text(tr('Nạp bộ lọc')),
                  onPressed: widget.onLoadFilter,
                ),
              IconButton(
                tooltip: tr('Bộ lọc đã lưu'),
                icon: const Icon(Icons.bookmarks_outlined),
                onPressed: _presets,
              ),
              const Spacer(),
              FilledButton(onPressed: widget.onFilter, child: Text(widget.filterLabel)),
            ],
          ),
        ),
        if (showSearch)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: Icon(Icons.search),
                hintText: tr('Tìm trong bộ lọc…'),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
        if (widget.loading) ...[
          const LinearProgressIndicator(minHeight: 2),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: Text(
              tr('Đang tải toàn bộ bộ lọc của tiện ích…'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ] else if (widget.loadError != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 16, color: Theme.of(context).colorScheme.error),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.loadError!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            children: [
              if (_ready && _query.isEmpty)
                ExpansionTile(
                  leading: const Icon(Icons.filter_alt_outlined),
                  title: Text(tr('Lọc kết quả (mọi tiện ích)'), style: TextStyle(fontSize: 13)),
                  subtitle: YomiFilterStore.hasResultFilters(_id)
                      ? Text(tr('Đang bật'), style: TextStyle(fontSize: 11))
                      : null,
                  children: [
                    SwitchListTile(
                      dense: true,
                      title: Text(tr('Dùng chung cho mọi tiện ích')),
                      subtitle: Text(tr('Các lựa chọn bên dưới áp dụng cho tất cả nguồn bật mục này')),
                      value: YomiFilterStore.isGlobal(_id),
                      onChanged: (v) async {
                        await YomiFilterStore.setGlobal(_id, v);
                        setState(() {
                          _exclude.text = YomiFilterStore.excluded(_id);
                          _include.text = YomiFilterStore.included(_id);
                        });
                      },
                    ),
                    SwitchListTile(
                      dense: true,
                      title: Text(tr('Ẩn mục đã xem / đã đọc')),
                      value: YomiFilterStore.hideRead(_id),
                      onChanged: (v) async {
                        await YomiFilterStore.setHideRead(_id, v);
                        setState(() {});
                      },
                    ),
                    SwitchListTile(
                      dense: true,
                      title: Text(tr('Ẩn mục không có ảnh bìa')),
                      value: YomiFilterStore.needCover(_id),
                      onChanged: (v) async {
                        await YomiFilterStore.setNeedCover(_id, v);
                        setState(() {});
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: TextField(
                        controller: _include,
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: tr('Chỉ hiện mục chứa từ khóa / thể loại (dấu phẩy)'),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => YomiFilterStore.setIncluded(_id, v),
                      ),
                    ),
                    SwitchListTile(
                      dense: true,
                      title: Text(tr('Ẩn mục đã có trong thư viện')),
                      value: YomiFilterStore.hideLibrary(_id),
                      onChanged: (v) async {
                        await YomiFilterStore.setHideLibrary(_id, v);
                        setState(() {});
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: TextField(
                        controller: _exclude,
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: tr('Loại trừ từ khóa / thể loại (cách nhau bởi dấu phẩy)'),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => YomiFilterStore.setExcluded(_id, v),
                      ),
                    ),
                  ],
                ),
              if (_query.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(
                    filterProfileLabel(filterProfileOf(widget.source)),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              // YomiHub 0.1.9: Kotatsu sources use Kotatsu's filter sheet,
              // APK (Mihon/Aniyomi/Nekoyomi) sources the Aniyomi/Nekoyomi one
              if (_query.isEmpty)
                filterBodyFor(
                  filterProfileOf(widget.source),
                  widget.filters,
                  () => widget.onChanged(widget.filters),
                  key: ValueKey('profile-${widget.filters.length}'),
                )
              else
                FilterWidget(
                  key: ValueKey('$_query-${visible.length}'),
                  filterList: visible,
                  onChanged: (_) => widget.onChanged(widget.filters),
                ),
            ],
          ),
        ),
      ],
    ));
    // YomiHub 0.1.8: Liquid Glass on the filter of every extension
    return Consumer(
      builder: (context, ref, _) {
        final g = ref.watch(liquidGlassProvider);
        if (!g.enabled) return body;
        return LiquidGlassSurface(
          cfg: g,
          borderRadius: BorderRadius.vertical(top: Radius.circular(g.radius + 6)),
          child: Material(type: MaterialType.transparency, child: body),
        );
      },
    );
  }
}
