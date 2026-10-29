import 'package:flutter/material.dart';
import 'package:mangayomi/eval/model/filter.dart';
import 'package:mangayomi/models/source.dart';
import 'package:mangayomi/modules/manga/home/widget/filter_widget.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:mangayomi/yomihub/kotatsu/kotatsu_bridge.dart';

/// YomiHub 0.1.9: which app's filter UI an extension uses.
///
///  * Kotatsu parsers → Kotatsu's filter sheet: sort order and every option
///    as chips, tags cycling include → exclude → off.
///  * Mihon / Aniyomi / Nekoyomi (APK) and Tachiyomi-format sources →
///    Aniyomi / Nekoyomi sheet: collapsible groups with the number of active
///    options, sort with direction arrow, tri-state boxes and a search box
///    inside long groups (Nekoyomi's genre search).
///  * everything else keeps Mangayomi's list.
enum YomiFilterProfile { kotatsu, aniyomi, mangayomi }

YomiFilterProfile filterProfileOf(Source s) {
  if (KotatsuBridge.isKotatsuSource(s)) return YomiFilterProfile.kotatsu;
  if (s.sourceCodeLanguage == SourceCodeLanguage.mihon) {
    return YomiFilterProfile.aniyomi;
  }
  return YomiFilterProfile.mangayomi;
}

String filterProfileLabel(YomiFilterProfile p) => switch (p) {
  YomiFilterProfile.kotatsu => tr('Bộ lọc kiểu Kotatsu'),
  YomiFilterProfile.aniyomi => tr('Bộ lọc kiểu Aniyomi / Nekoyomi'),
  YomiFilterProfile.mangayomi => tr('Bộ lọc của tiện ích'),
};

/// Body of the filter sheet for [profile].
Widget filterBodyFor(
  YomiFilterProfile profile,
  List<dynamic> filters,
  void Function() onChanged, {
  Key? key,
}) {
  switch (profile) {
    case YomiFilterProfile.kotatsu:
      return KotatsuFilterView(key: key, filters: filters, onChanged: onChanged);
    case YomiFilterProfile.aniyomi:
      return AniyomiFilterView(key: key, filters: filters, onChanged: onChanged);
    case YomiFilterProfile.mangayomi:
      return FilterWidget(
        key: key,
        filterList: filters,
        onChanged: (_) => onChanged(),
      );
  }
}

int _activeCount(dynamic f) {
  if (f is GroupFilter) {
    return f.state.fold<int>(0, (a, e) => a + _activeCount(e));
  }
  if (f is CheckBoxFilter) return f.state ? 1 : 0;
  if (f is TriStateFilter) return f.state == 0 ? 0 : 1;
  if (f is TextFilter) return f.state.trim().isEmpty ? 0 : 1;
  return 0;
}

// ───────────────────────── Kotatsu ─────────────────────────

class KotatsuFilterView extends StatefulWidget {
  final List<dynamic> filters;
  final VoidCallback onChanged;
  const KotatsuFilterView({super.key, required this.filters, required this.onChanged});

  @override
  State<KotatsuFilterView> createState() => _KotatsuFilterViewState();
}

class _KotatsuFilterViewState extends State<KotatsuFilterView> {
  final Map<int, bool> _showAll = {};

  void _changed() {
    setState(() {});
    widget.onChanged();
  }

  Widget _title(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
    child: Text(t, style: Theme.of(context).textTheme.titleSmall),
  );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final children = <Widget>[];
    for (var i = 0; i < widget.filters.length; i++) {
      final f = widget.filters[i];
      if (f is SelectFilter) {
        children.add(_title(f.name));
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var j = 0; j < f.values.length; j++)
                  ChoiceChip(
                    label: Text((f.values[j] as SelectFilterOption).name),
                    selected: f.state == j,
                    onSelected: (_) {
                      f.state = j;
                      _changed();
                    },
                  ),
              ],
            ),
          ),
        );
      } else if (f is GroupFilter) {
        final items = f.state;
        final many = items.length > 24;
        final all = _showAll[i] ?? false;
        final shown = many && !all
            ? [
                ...items.where((e) => _activeCount(e) > 0),
                ...items.where((e) => _activeCount(e) == 0).take(24),
              ]
            : items;
        final n = _activeCount(f);
        children.add(_title(n > 0 ? '${f.name} ($n)' : f.name));
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final e in shown)
                  if (e is TriStateFilter)
                    FilterChip(
                      label: Text(e.name),
                      selected: e.state != 0,
                      showCheckmark: false,
                      avatar: e.state == 0
                          ? null
                          : Icon(e.state == 1 ? Icons.check : Icons.remove, size: 18),
                      selectedColor: e.state == 2 ? cs.errorContainer : cs.secondaryContainer,
                      onSelected: (_) {
                        // Kotatsu: include → exclude → off
                        e.state = (e.state + 1) % 3;
                        _changed();
                      },
                    )
                  else if (e is CheckBoxFilter)
                    FilterChip(
                      label: Text(e.name),
                      selected: e.state,
                      onSelected: (v) {
                        e.state = v;
                        _changed();
                      },
                    ),
              ],
            ),
          ),
        );
        if (many) {
          children.add(
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() => _showAll[i] = !all),
                child: Text(all ? tr('Thu gọn') : tr('Xem tất cả ({p0})', {'p0': items.length})),
              ),
            ),
          );
        }
      } else if (f is TextFilter) {
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: TextFormField(
              initialValue: f.state,
              keyboardType: f.type?.startsWith('year') == true ? TextInputType.number : null,
              decoration: InputDecoration(isDense: true, labelText: f.name, border: const OutlineInputBorder()),
              onChanged: (v) {
                f.state = v;
                widget.onChanged();
              },
            ),
          ),
        );
      } else {
        children.add(FilterWidget(filterList: [f], onChanged: (_) => widget.onChanged()));
      }
    }
    children.add(const SizedBox(height: 16));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }
}

// ───────────────────── Aniyomi / Nekoyomi ─────────────────────

class AniyomiFilterView extends StatefulWidget {
  final List<dynamic> filters;
  final VoidCallback onChanged;
  const AniyomiFilterView({super.key, required this.filters, required this.onChanged});

  @override
  State<AniyomiFilterView> createState() => _AniyomiFilterViewState();
}

class _AniyomiFilterViewState extends State<AniyomiFilterView> {
  final Map<int, String> _q = {};

  void _changed() {
    setState(() {});
    widget.onChanged();
  }

  Widget _tri(TriStateFilter e) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      leading: Icon(
        switch (e.state) {
          1 => Icons.check_box,
          2 => Icons.disabled_by_default,
          _ => Icons.check_box_outline_blank,
        },
        color: switch (e.state) {
          1 => cs.primary,
          2 => cs.error,
          _ => null,
        },
      ),
      title: Text(e.name),
      onTap: () {
        e.state = (e.state + 1) % 3;
        _changed();
      },
    );
  }

  List<Widget> _items(List<dynamic> list, {String q = ''}) {
    final out = <Widget>[];
    for (final e in list) {
      if (q.isNotEmpty && !_nameOf(e).toLowerCase().contains(q)) continue;
      if (e is TriStateFilter) {
        out.add(_tri(e));
      } else if (e is CheckBoxFilter) {
        out.add(
          CheckboxListTile(
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            value: e.state,
            title: Text(e.name),
            onChanged: (v) {
              e.state = v ?? false;
              _changed();
            },
          ),
        );
      } else {
        out.add(FilterWidget(filterList: [e], onChanged: (_) => _changed()));
      }
    }
    return out;
  }

  static String _nameOf(dynamic e) {
    try {
      return '${e.name}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < widget.filters.length; i++) {
      final f = widget.filters[i];
      if (f is GroupFilter) {
        final n = _activeCount(f);
        final long = f.state.length > 15;
        final q = (_q[i] ?? '').trim().toLowerCase();
        children.add(
          ExpansionTile(
            title: Text(f.name, style: const TextStyle(fontSize: 14)),
            trailing: n > 0
                ? Badge(label: Text('$n'), child: const Icon(Icons.expand_more))
                : null,
            children: [
              if (long)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                  child: TextField(
                    decoration: InputDecoration(
                      isDense: true,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      hintText: tr('Tìm trong {p0}…', {'p0': f.name}),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => _q[i] = v),
                  ),
                ),
              ..._items(f.state, q: q),
            ],
          ),
        );
      } else if (f is TriStateFilter) {
        children.add(_tri(f));
      } else {
        children.add(FilterWidget(filterList: [f], onChanged: (_) => _changed()));
      }
    }
    return Column(children: children);
  }
}
