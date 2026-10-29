import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:mangayomi/models/manga.dart';

/// Library tag/genre filter from Nekoyomi (GenreFilterSection): each tag
/// cycles neutral → included (✓) → excluded (✕) → neutral.
class GenreFilterState {
  final Map<ItemType, Set<String>> include;
  final Map<ItemType, Set<String>> exclude;
  const GenreFilterState(this.include, this.exclude);

  Set<String> inc(ItemType t) => include[t] ?? const {};
  Set<String> exc(ItemType t) => exclude[t] ?? const {};

  bool matches(Manga m) {
    final t = m.itemType;
    final i = inc(t), e = exc(t);
    if (i.isEmpty && e.isEmpty) return true;
    final g = (m.genre ?? const <String>[]).map((x) => x.trim().toLowerCase()).toSet();
    if (i.isNotEmpty && !i.every(g.contains)) return false;
    if (e.any(g.contains)) return false;
    return true;
  }
}

class GenreFilterNotifier extends Notifier<GenreFilterState> {
  static const _box = 'yomihub_filters';

  @override
  GenreFilterState build() {
    final inc = <ItemType, Set<String>>{};
    final exc = <ItemType, Set<String>>{};
    if (Hive.isBoxOpen(_box)) {
      final b = Hive.box(_box);
      for (final t in ItemType.values) {
        inc[t] = Set<String>.from((b.get('gi_${t.name}') ?? const []) as List);
        exc[t] = Set<String>.from((b.get('ge_${t.name}') ?? const []) as List);
      }
    } else {
      Hive.openBox(_box).then((_) => ref.invalidateSelf());
    }
    return GenreFilterState(inc, exc);
  }

  Future<void> _persist(ItemType t) async {
    final b = Hive.isBoxOpen(_box) ? Hive.box(_box) : await Hive.openBox(_box);
    await b.put('gi_${t.name}', state.inc(t).toList());
    await b.put('ge_${t.name}', state.exc(t).toList());
  }

  void cycle(ItemType t, String genre) {
    final g = genre.toLowerCase();
    final inc = {...state.include}..[t] = {...state.inc(t)};
    final exc = {...state.exclude}..[t] = {...state.exc(t)};
    if (inc[t]!.contains(g)) {
      inc[t]!.remove(g);
      exc[t]!.add(g);
    } else if (exc[t]!.contains(g)) {
      exc[t]!.remove(g);
    } else {
      inc[t]!.add(g);
    }
    state = GenreFilterState(inc, exc);
    _persist(t);
  }

  void clear(ItemType t) {
    state = GenreFilterState({...state.include}..[t] = {}, {...state.exclude}..[t] = {});
    _persist(t);
  }
}

final yomiGenreFilterProvider =
    NotifierProvider<GenreFilterNotifier, GenreFilterState>(GenreFilterNotifier.new);

class GenreFilterSection extends ConsumerStatefulWidget {
  final ItemType itemType;
  final List<Manga> entries;
  const GenreFilterSection({super.key, required this.itemType, required this.entries});

  @override
  ConsumerState<GenreFilterSection> createState() => _GenreFilterSectionState();
}

class _GenreFilterSectionState extends ConsumerState<GenreFilterSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final f = ref.watch(yomiGenreFilterProvider);
    final counts = <String, int>{};
    final display = <String, String>{};
    for (final m in widget.entries) {
      for (final g in m.genre ?? const <String>[]) {
        final k = g.trim().toLowerCase();
        if (k.isEmpty) continue;
        counts[k] = (counts[k] ?? 0) + 1;
        display.putIfAbsent(k, () => g.trim());
      }
    }
    if (counts.isEmpty) return const SizedBox.shrink();
    final genres = counts.keys.toList()..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    final inc = f.inc(widget.itemType), exc = f.exc(widget.itemType);
    final active = inc.length + exc.length;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          dense: true,
          title: Text('Thể loại${active > 0 ? ' ($active)' : ''}',
              style: TextStyle(color: active > 0 ? scheme.primary : null, fontWeight: FontWeight.w600)),
          trailing: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
          onTap: () => setState(() => _expanded = !_expanded),
        ),
        if (_expanded)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final g in genres)
                    FilterChip(
                      label: Text('${display[g]} (${counts[g]})'),
                      selected: inc.contains(g) || exc.contains(g),
                      avatar: inc.contains(g)
                          ? const Icon(Icons.check, size: 16)
                          : exc.contains(g)
                          ? const Icon(Icons.close, size: 16)
                          : null,
                      showCheckmark: false,
                      selectedColor: exc.contains(g) ? scheme.errorContainer : null,
                      onSelected: (_) =>
                          ref.read(yomiGenreFilterProvider.notifier).cycle(widget.itemType, g),
                    ),
                  if (active > 0)
                    ActionChip(
                      avatar: const Icon(Icons.close, size: 16),
                      label: const Text('Đặt lại'),
                      onPressed: () => ref.read(yomiGenreFilterProvider.notifier).clear(widget.itemType),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
