from ed import *

# ---------- FC37: nguon de doc sau khi hop nhat (nho theo tung bo) ----------
rel = 'lib/yomihub/merge/chapter_origins.dart'
sub(rel, """  static Source? sourceFor(Chapter chapter) {""", """  // ---- 0.5.7 (sheet "Merge" / Feature Check 37) -------------------------
  // "Thêm cài đặt chọn nguồn để đọc sau khi hợp nhất": the source picked
  // under "Đề xuất / Liên quan" is remembered per title (backed-up
  // preferences box) and decides which copy of a chapter the reader opens
  // when several merged sources carry the same chapter number.
  static const _readKey = 'mergedReadSource';

  /// The remembered source key ([sourceKey]) of a merged title, or null
  /// ("Tất cả": no preference).
  static String? preferredSource(int? mangaId) {
    if (mangaId == null || !YomiPrefs.isOpen) return null;
    final v = YomiPrefs.get<Map>(_readKey, const {})['$mangaId'];
    return v is String && v.isNotEmpty ? v : null;
  }

  static Future<void> setPreferredSource(int? mangaId, String? key) async {
    if (mangaId == null || !YomiPrefs.isOpen) return;
    final all = Map<String, dynamic>.from(YomiPrefs.get<Map>(_readKey, const {}));
    if (key == null || key.isEmpty) {
      if (!all.containsKey('$mangaId')) return;
      all.remove('$mangaId');
    } else {
      if (all['$mangaId'] == key) return;
      all['$mangaId'] = key;
    }
    await YomiPrefs.set(_readKey, all);
  }

  /// One chapter per chapter number for sequential reading. [chapters] is in
  /// reading order, [numberOf] gives the chapter number (null = no number:
  /// never collapsed). Without a preference the first copy wins (the old
  /// behaviour); with one, the copy of the preferred source wins and the
  /// other sources only fill in the chapters the preferred source lacks, so
  /// a source that stopped updating never hides newer chapters.
  static List<Chapter> pickForReading(
    List<Chapter> chapters,
    double? Function(Chapter c) numberOf, {
    Manga? owner,
    String? preferred,
  }) {
    final chosen = <double, Chapter>{};
    final preferredHit = <double>{};
    for (final c in chapters) {
      final n = numberOf(c);
      if (n == null) continue;
      if (!chosen.containsKey(n)) {
        chosen[n] = c;
        if (preferred != null && sourceKey(c, owner) == preferred) preferredHit.add(n);
      } else if (preferred != null && !preferredHit.contains(n) && sourceKey(c, owner) == preferred) {
        chosen[n] = c;
        preferredHit.add(n);
      }
    }
    return [
      for (final c in chapters)
        if (numberOf(c) == null || identical(chosen[numberOf(c)], c)) c,
    ];
  }

  static Source? sourceFor(Chapter chapter) {""")

rel = 'lib/utils/extensions/manga_extensions.dart'
sub(rel, """import 'package:mangayomi/utils/chapter_recognition.dart';
""", """import 'package:mangayomi/utils/chapter_recognition.dart';
import 'package:mangayomi/yomihub/merge/chapter_origins.dart';
""")
sub(rel, """    final list = getFilteredChapters();
    final sortKeys = _chapterSortKeys(name ?? '', list);
    final seen = <double>{};
    return list.where((c) {
      final key = sortKeys[c.id];
      return key == null || seen.add(key);
    }).toList();
  }
""", """    final list = getFilteredChapters();
    final sortKeys = _chapterSortKeys(name ?? '', list);
    // 0.5.7 (Feature Check 37): a merged title with a remembered read source
    // opens that source's copy of each chapter; other sources fill the gaps.
    final preferred = ChapterOrigins.preferredSource(id);
    if (preferred != null) {
      return ChapterOrigins.pickForReading(
        list,
        (c) => sortKeys[c.id],
        owner: this,
        preferred: preferred,
      );
    }
    final seen = <double>{};
    return list.where((c) {
      final key = sortKeys[c.id];
      return key == null || seen.add(key);
    }).toList();
  }
""")

rel = 'lib/modules/manga/detail/manga_detail_view.dart'
sub(rel, """    _scrollController = ScrollController()
      ..addListener(() {
        ref.read(offetProvider.notifier).state = _scrollController.offset;
      });
  }
""", """    _scrollController = ScrollController()
      ..addListener(() {
        ref.read(offetProvider.notifier).state = _scrollController.offset;
      });
    // 0.5.7 (Feature Check 37): the read source chosen for this merged title
    // is remembered (it used to be forgotten when the screen closed)
    _selectedMergedSource = ChapterOrigins.preferredSource(widget.manga?.id);
  }
""")
sub(rel, """    if (sources.length < 2) return const SizedBox.shrink();
    return Padding(""", """    if (sources.length < 2) return const SizedBox.shrink();
    // a remembered source that is gone (un-merged, chapters removed) no
    // longer filters the list
    if (_selectedMergedSource != null && !sources.containsKey(_selectedMergedSource)) {
      _selectedMergedSource = null;
    }
    return Padding(""")
sub(rel, """          labelText: tr('Chọn nguồn'),
          border: const OutlineInputBorder(),
        ),""", """          labelText: tr('Chọn nguồn'),
          helperText: tr('Nguồn để đọc sau khi hợp nhất – được nhớ cho bộ này'),
          helperMaxLines: 2,
          border: const OutlineInputBorder(),
        ),""")
sub(rel, """        onChanged: (value) =>
            setState(() => _selectedMergedSource = value == '' ? null : value),
      ),""", """        onChanged: (value) {
          final picked = value == null || value == '' ? null : value;
          setState(() => _selectedMergedSource = picked);
          ChapterOrigins.setPreferredSource(widget.manga?.id, picked);
        },
      ),""")
sub(rel, """            if (_selectedMergedSource != null) {
              chapters = chapters""", """            if (_selectedMergedSource != null &&
                _mergedSources().containsKey(_selectedMergedSource)) {
              chapters = chapters""")
print('P1 patch part 2 OK')
