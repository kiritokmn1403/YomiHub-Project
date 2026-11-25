import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:mangayomi/utils/log/logger.dart';
import 'package:mangayomi/yomihub/bookshelf/bookshelf_logic.dart';
import 'package:mangayomi/yomihub/bookshelf/bookshelf_models.dart';
import 'package:mangayomi/yomihub/prefs/yomi_hive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// YomiHub 0.6.3 – "Tủ Sách Cá Nhân" store (YomiHub Update, mục 14).
///
/// Hive box `yomihub_bookshelf` (JSON maps) – listed in
/// `YomiBackupExtras.boxes`, so app backup/restore/cloud sync carry it.
/// Works 100 % offline (bookshop basements, FN-01); online catalogues are
/// only used for ISBN look-ups and cached in the scan history.
/// Not available in the Android TV build ("YumiHub Android TV").
class BookshelfStore extends ChangeNotifier {
  BookshelfStore._();
  static final BookshelfStore instance = BookshelfStore._();

  static const boxName = 'yomihub_bookshelf';
  static const route = '/bookshelf';
  static const maxRecent = 6;
  static const maxScans = 300;

  Box? _box;
  bool get ready => _box != null;

  // in-memory copies (the box holds lists of JSON maps)
  final Map<String, BsSeries> _series = {};
  final Map<String, BsVolume> _volumes = {};
  final Map<String, BsFolder> _folders = {};
  final Map<String, BsWish> _wishes = {};
  List<BsScan> _scans = [];
  List<String> _recent = [];

  /// For tests: use an already opened box.
  @visibleForTesting
  Future<void> initWithBox(Box box) async {
    _box = box;
    _load();
  }

  Future<void> init() async {
    if (_box != null) return;
    try {
      _box = Hive.isBoxOpen(boxName) ? Hive.box(boxName) : await YomiHive.open(boxName);
      _load();
    } catch (e) {
      AppLogger.log('[Tủ Sách] Không mở được dữ liệu tủ sách: $e', logLevel: LogLevel.error);
    }
  }

  /// Called after a backup restore replaced the box contents.
  void onRestored() {
    if (_box == null) {
      unawaited(init().then((_) => restorePhotoFiles()));
      return;
    }
    _load();
    unawaited(restorePhotoFiles());
  }

  // ───────────────── photos in the app backup (0.6.6, FN-14 / FN-18) ─────────────────
  // Item photos and local covers are files outside the Hive box; a backup of
  // the box alone restored dead paths on another device. They travel as
  // base64 under the box key `photoFiles` (name → data), capped in size.

  static const maxBackupPhotoBytes = 32 * 1024 * 1024;

  static bool _isLocalPath(String s) => s.trim().isNotEmpty && !RegExp(r'^[a-z][a-z0-9+.\-]*://', caseSensitive: false).hasMatch(s.trim());
  static String _baseName(String s) => s.split(RegExp(r'[\\/]')).last;

  Iterable<String> _localImagePaths() sync* {
    for (final s in _series.values) {
      if (_isLocalPath(s.cover)) yield s.cover;
    }
    for (final f in _folders.values) {
      for (final i in f.items) {
        for (final ph in i.photos) {
          if (_isLocalPath(ph)) yield ph;
        }
      }
    }
  }

  /// Existing local images by file name, stopping at [maxBackupPhotoBytes].
  Future<Map<String, String>> photoFilesForBackup() async {
    await init();
    final out = <String, String>{};
    var total = 0;
    for (final path in _localImagePaths()) {
      final name = _baseName(path);
      if (name.isEmpty || out.containsKey(name)) continue;
      try {
        final f = File(path);
        if (!await f.exists()) continue;
        final len = await f.length();
        if (total + len > maxBackupPhotoBytes) continue;
        out[name] = base64Encode(await f.readAsBytes());
        total += len;
      } catch (_) {}
    }
    return out;
  }

  /// Writes the images of a restored backup to the photo folder and points
  /// covers / item photos at the new files; then drops `photoFiles`.
  Future<void> restorePhotoFiles() async {
    final box = _box;
    final raw = box?.get('photoFiles');
    if (box == null || !box.isOpen || raw is! Map || raw.isEmpty) return;
    try {
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(docs.path, 'yomihub_bookshelf', 'photos'));
      if (!await dir.exists()) await dir.create(recursive: true);
      final moved = <String, String>{};
      for (final e in raw.entries) {
        final name = _baseName('${e.key}');
        if (name.isEmpty) continue;
        final dest = p.join(dir.path, name);
        if (!await File(dest).exists()) await File(dest).writeAsBytes(base64Decode('${e.value}'));
        moved[name] = dest;
      }
      String fix(String s) => _isLocalPath(s) ? (moved[_baseName(s)] ?? s) : s;
      for (final s in _series.values) {
        s.cover = fix(s.cover);
      }
      for (final f in _folders.values) {
        for (final i in f.items) {
          i.photos = [for (final ph in i.photos) fix(ph)];
        }
      }
      if (await _save(['series', 'folders'])) await box.delete('photoFiles');
    } catch (e) {
      AppLogger.log('[Tủ Sách] Không khôi phục được ảnh từ bản sao lưu: $e', logLevel: LogLevel.error);
    }
  }

  void _load() {
    List<Map> list(String k) => [for (final e in (_box?.get(k) as List? ?? const [])) if (e is Map) e];
    _series
      ..clear()
      ..addEntries(list('series').map(BsSeries.fromJson).map((s) => MapEntry(s.id, s)));
    _volumes
      ..clear()
      ..addEntries(list('volumes').map(BsVolume.fromJson).map((v) => MapEntry(v.id, v)));
    _folders
      ..clear()
      ..addEntries(list('folders').map(BsFolder.fromJson).map((f) => MapEntry(f.id, f)));
    _wishes
      ..clear()
      ..addEntries(list('wishes').map(BsWish.fromJson).map((w) => MapEntry(w.id, w)));
    _scans = list('scans').map(BsScan.fromJson).toList();
    _recent = [for (final r in (_box?.get('recent') as List? ?? const [])) r.toString()];
    notifyListeners();
  }

  /// Last write error (null = the last save reached the box).
  String? lastSaveError;

  /// Writes [keys] to the Hive box. Returns false (and logs) when the box is
  /// closed/missing or the write throws – 0.6.3 review: callers that report
  /// success (CSV import) must not claim data was stored when it was not.
  Future<bool> _save(Iterable<String> keys) async {
    final box = _box;
    if (box == null || !box.isOpen) {
      lastSaveError = 'box ${box == null ? 'chưa mở' : 'đã đóng'}';
      AppLogger.log('[Tủ Sách] Không lưu được dữ liệu ($keys): $lastSaveError', logLevel: LogLevel.error);
      notifyListeners();
      return false;
    }
    var ok = true;
    try {
      for (final k in keys) {
        final v = switch (k) {
          'series' => [for (final s in _series.values) s.toJson()],
          'volumes' => [for (final v in _volumes.values) v.toJson()],
          'folders' => [for (final f in _folders.values) f.toJson()],
          'wishes' => [for (final w in _wishes.values) w.toJson()],
          'scans' => [for (final s in _scans) s.toJson()],
          'recent' => _recent,
          _ => null,
        };
        if (v != null) await box.put(k, v);
      }
      lastSaveError = null;
    } catch (e) {
      ok = false;
      lastSaveError = '$e';
      AppLogger.log('[Tủ Sách] Không lưu được dữ liệu ($keys): $e', logLevel: LogLevel.error);
    }
    notifyListeners();
    return ok;
  }

  /// 0.6.4: raw values kept in the same box (publisher feed FN-16/29, cover
  /// hashes FN-22) – so backups / cloud sync carry them with the bookshelf.
  Object? raw(String key) => _box?.get(key);

  Future<bool> putRaw(String key, Object? value) async {
    final box = _box;
    if (box == null || !box.isOpen) return false;
    try {
      await box.put(key, value);
      return true;
    } catch (e) {
      AppLogger.log('[Tủ Sách] Không lưu được dữ liệu ($key): $e', logLevel: LogLevel.error);
      return false;
    }
  }

  static int _seq = 0;
  static String newId(String p) =>
      '$p${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${(_seq++ % 1296).toRadixString(36)}';

  // ───────────────────────── read ─────────────────────────

  List<BsSeries> get series => _series.values.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  BsSeries? seriesById(String id) => _series[id];
  List<BsVolume> volumesOf(String seriesId) =>
      _volumes.values.where((v) => v.seriesId == seriesId).toList()..sort((a, b) => a.number.compareTo(b.number));
  List<BsFolder> foldersOf(String seriesId) => _folders.values.where((f) => f.seriesId == seriesId).toList();
  List<BsWish> get wishes => _wishes.values.toList();
  List<BsScan> get scans => List.unmodifiable(_scans);
  List<BsSeries> get recent => [for (final id in _recent) if (_series[id] != null) _series[id]!];

  /// Highest owned volume of a series (any edition), FN-05.
  double? latestOf(String seriesId) {
    double? m;
    for (final v in _volumes.values) {
      if (v.seriesId == seriesId && (m == null || v.number > m)) m = v.number;
    }
    return m;
  }

  /// FN-06 gap detection on regular-edition volumes.
  List<int> gapsOf(String seriesId) => bsGaps(
      _volumes.values.where((v) => v.seriesId == seriesId && v.edition == BsEdition.regular).map((v) => v.number));

  bool owns(String seriesId, double number, [BsEdition? edition]) => _volumes.values
      .any((v) => v.seriesId == seriesId && v.number == number && (edition == null || v.edition == edition));

  BsVolume? findVolume(String seriesId, double number, BsEdition edition) {
    for (final v in _volumes.values) {
      if (v.seriesId == seriesId && v.number == number && v.edition == edition) return v;
    }
    return null;
  }

  /// FN-21: volumes already on the shelf that carry this ISBN.
  List<BsVolume> volumesByIsbn(String isbn) {
    final i = bsToIsbn13(isbn) ?? bsCleanIsbn(isbn);
    if (i.isEmpty) return const [];
    return _volumes.values.where((v) => v.isbn.isNotEmpty && (bsToIsbn13(v.isbn) ?? bsCleanIsbn(v.isbn)) == i).toList();
  }

  BsOwnership ownership(String seriesId, double? number) {
    if (number == null) {
      return _volumes.values.any((v) => v.seriesId == seriesId) ? BsOwnership.owned : BsOwnership.missing;
    }
    final reg = owns(seriesId, number, BsEdition.regular);
    final lim = owns(seriesId, number, BsEdition.limited) || owns(seriesId, number, BsEdition.special);
    if (lim || (reg && !_hasAnyLimited(seriesId))) return BsOwnership.owned;
    if (reg) return BsOwnership.regularOnly;
    return BsOwnership.missing;
  }

  bool _hasAnyLimited(String seriesId) =>
      _volumes.values.any((v) => v.seriesId == seriesId && v.edition != BsEdition.regular) ||
      _folders.values.any((f) => f.seriesId == seriesId && f.items.isNotEmpty);

  /// FN-01/02/23: instant search – "one piece 105", "jjk", "chu thuat 19".
  List<BsHit> search(String raw, {int limit = 30}) {
    final q = bsParseQuery(raw);
    final hits = <BsHit>[];
    for (final s in _series.values) {
      var score = bsMatchScore(q.text, s.title, [s.original, ...s.aliases]);
      var vol = q.volume;
      if (score == 0 && q.volume != null) {
        // the number may belong to the title ("86", "Kaiju No. 8")
        score = bsMatchScore(bsNormalize(raw), s.title, [s.original, ...s.aliases]);
        if (score > 0) vol = null;
      }
      if (score == 0) continue;
      hits.add(BsHit(s, vol, ownership(s.id, vol), score, latestOf(s.id)));
    }
    hits.sort((a, b) => b.score != a.score ? b.score.compareTo(a.score) : b.series.updatedAt.compareTo(a.series.updatedAt));
    return hits.take(limit).toList();
  }

  /// FN-05: (series, latest owned volume) newest first.
  List<(BsSeries, double)> latestList() {
    final out = <(BsSeries, double)>[];
    for (final s in series) {
      final l = latestOf(s.id);
      if (l != null) out.add((s, l));
    }
    return out;
  }

  /// FN-25: what to buy – gaps, next volume of ongoing series, wishes.
  List<({BsSeries series, double? volume, String reason, String? wishId})> shoppingList() {
    final out = <({BsSeries series, double? volume, String reason, String? wishId})>[];
    for (final s in series) {
      for (final g in gapsOf(s.id)) {
        out.add((series: s, volume: g.toDouble(), reason: 'gap', wishId: null));
      }
      final l = latestOf(s.id);
      if (s.status == BsStatus.ongoing && l != null) {
        final next = l.floorToDouble() + 1;
        if ((s.totalVolumes == null || next <= s.totalVolumes!) && !owns(s.id, next)) {
          out.add((series: s, volume: next, reason: 'next', wishId: null));
        }
      }
    }
    for (final w in _wishes.values) {
      final s = _series[w.seriesId];
      if (s != null) out.add((series: s, volume: w.volume, reason: 'wish', wishId: w.id));
    }
    return out;
  }

  /// FN-28 (0.6.6): volumes currently lent out, earliest due date first
  /// (no due date last).
  List<({BsSeries series, BsVolume volume})> loans() {
    final out = <({BsSeries series, BsVolume volume})>[];
    for (final v in _volumes.values) {
      final s = _series[v.seriesId];
      if (s != null && (v.borrower ?? '').trim().isNotEmpty) out.add((series: s, volume: v));
    }
    out.sort((a, b) {
      final x = a.volume.loanDue, y = b.volume.loanDue;
      if (x == null || y == null) return x == y ? 0 : (x == null ? 1 : -1);
      return x.compareTo(y);
    });
    return out;
  }

  /// Marks a lent volume as returned.
  Future<void> returnLoan(String volumeId) async {
    final v = _volumes[volumeId];
    if (v == null) return;
    v.borrower = null;
    v.loanDue = null;
    await _save(['volumes']);
  }

  /// FN-24 statistics.
  Map<String, Object> stats() {
    var books = 0, limited = 0;
    var spent = 0.0;
    final byPublisher = <String, int>{};
    final byMonth = <String, double>{};
    for (final v in _volumes.values) {
      books += v.copies;
      if (v.edition != BsEdition.regular) limited++;
      if (v.price != null) {
        spent += v.price! * v.copies;
        if (v.purchaseDate != null) {
          final d = DateTime.fromMillisecondsSinceEpoch(v.purchaseDate!);
          final k = '${d.year}-${d.month.toString().padLeft(2, '0')}';
          byMonth[k] = (byMonth[k] ?? 0) + v.price! * v.copies;
        }
      }
      final pub = _series[v.seriesId]?.publisher ?? '';
      byPublisher[pub.isEmpty ? '?' : pub] = (byPublisher[pub.isEmpty ? '?' : pub] ?? 0) + v.copies;
    }
    for (final f in _folders.values) {
      limited += f.items.length;
      for (final i in f.items) {
        if (i.price != null) spent += i.price!;
      }
    }
    final missing = series.where((s) => gapsOf(s.id).isNotEmpty).length;
    return {
      'series': _series.length,
      'books': books,
      'limited': limited,
      'spent': spent,
      'missingSeries': missing,
      'byPublisher': byPublisher,
      'byMonth': byMonth,
    };
  }

  // ───────────────────────── write ─────────────────────────

  Future<void> touchRecent(String seriesId) async {
    _recent
      ..remove(seriesId)
      ..insert(0, seriesId);
    if (_recent.length > maxRecent) _recent = _recent.sublist(0, maxRecent);
    await _save(['recent']);
  }

  Future<BsSeries> saveSeries(BsSeries s) async {
    s.updatedAt = DateTime.now().millisecondsSinceEpoch;
    _series[s.id] = s;
    await _save(['series']);
    return s;
  }

  Future<BsSeries> createSeries(String title,
      {String publisher = '', String author = '', String cover = '', String synopsis = '', List<String>? aliases}) {
    return saveSeries(BsSeries(
        id: newId('s'),
        title: title.trim(),
        publisher: publisher,
        author: author,
        cover: cover,
        synopsis: synopsis,
        aliases: aliases));
  }

  Future<void> deleteSeries(String id) async {
    _series.remove(id);
    _volumes.removeWhere((_, v) => v.seriesId == id);
    _folders.removeWhere((_, f) => f.seriesId == id);
    _wishes.removeWhere((_, w) => w.seriesId == id);
    _recent.remove(id);
    await _save(['series', 'volumes', 'folders', 'wishes', 'recent']);
  }

  /// Adds one volume. Returns the existing volume (not added) when the same
  /// (series, number, edition) is already owned and [allowExtraCopy] is false
  /// (FN-26 duplicate warning); with [allowExtraCopy] the copy count goes up.
  Future<({BsVolume volume, bool duplicate})> addVolume(String seriesId, double number,
      {BsEdition edition = BsEdition.regular,
      String isbn = '',
      double? price,
      String place = '',
      bool allowExtraCopy = false}) async {
    final ex = findVolume(seriesId, number, edition);
    if (ex != null) {
      if (!allowExtraCopy) return (volume: ex, duplicate: true);
      ex.copies++;
      await _save(['volumes']);
      return (volume: ex, duplicate: false);
    }
    final v = BsVolume(
      id: newId('v'),
      seriesId: seriesId,
      number: number,
      edition: edition,
      isbn: bsToIsbn13(isbn) ?? bsCleanIsbn(isbn),
      price: price,
      place: place,
      purchaseDate: DateTime.now().millisecondsSinceEpoch,
    );
    _volumes[v.id] = v;
    // bought → drop matching wishes (FN-25 "mua xong tick là chuyển vào tủ")
    _wishes.removeWhere((_, w) => w.seriesId == seriesId && w.volume == number && w.edition == edition);
    final s = _series[seriesId];
    if (s != null) s.updatedAt = DateTime.now().millisecondsSinceEpoch;
    await _save(['volumes', 'wishes', 'series']);
    return (volume: v, duplicate: false);
  }

  /// FN-12 bulk select: adds every number not yet owned, returns how many.
  Future<int> addVolumes(String seriesId, Iterable<double> numbers, {BsEdition edition = BsEdition.regular}) async {
    var n = 0;
    for (final x in numbers) {
      if (findVolume(seriesId, x, edition) != null) continue;
      final v = BsVolume(id: newId('v'), seriesId: seriesId, number: x, edition: edition);
      _volumes[v.id] = v;
      // 0.6.3 review: same rule as addVolume – a bought volume leaves the wish list
      _wishes.removeWhere((_, w) => w.seriesId == seriesId && w.volume == x && w.edition == edition);
      n++;
    }
    final s = _series[seriesId];
    if (s != null) s.updatedAt = DateTime.now().millisecondsSinceEpoch;
    await _save(['volumes', 'wishes', 'series']);
    return n;
  }

  Future<void> saveVolume(BsVolume v) async {
    _volumes[v.id] = v;
    await _save(['volumes']);
  }

  Future<void> removeVolume(String id) async {
    _volumes.remove(id);
    await _save(['volumes']);
  }

  Future<BsFolder> addFolder(String seriesId, String name) async {
    final f = BsFolder(id: newId('f'), seriesId: seriesId, name: name.trim());
    _folders[f.id] = f;
    await _save(['folders']);
    return f;
  }

  Future<void> saveFolder(BsFolder f) async {
    _folders[f.id] = f;
    await _save(['folders']);
  }

  Future<void> removeFolder(String id) async {
    _folders.remove(id);
    await _save(['folders']);
  }

  Future<BsWish> addWish(String seriesId, {double? volume, BsEdition edition = BsEdition.regular, String note = ''}) async {
    final w = BsWish(id: newId('w'), seriesId: seriesId, volume: volume, edition: edition, note: note);
    _wishes[w.id] = w;
    await _save(['wishes']);
    return w;
  }

  Future<void> removeWish(String id) async {
    _wishes.remove(id);
    await _save(['wishes']);
  }

  Future<void> recordScan(BsScan s) async {
    _scans.insert(0, s);
    if (_scans.length > maxScans) _scans = _scans.sublist(0, maxScans);
    await _save(['scans']);
  }

  // ───────────────────────── barcode / ISBN ─────────────────────────

  /// FN-19: best matching series for a catalogue title (fuzzy, ≥ 0.55).
  BsSeries? matchSeries(String title) {
    final key = bsSeriesKey(title);
    if (key.isEmpty) return null;
    BsSeries? best;
    var bestScore = 0.0;
    for (final s in _series.values) {
      for (final cand in [s.title, s.original, ...s.aliases]) {
        if (cand.trim().isEmpty) continue;
        final c = bsSeriesKey(cand);
        final sc = c == key ? 1.0 : (key.contains(c) || c.contains(key)) && c.length >= 3 ? 0.9 : bsSimilarity(c, key);
        if (sc > bestScore) {
          bestScore = sc;
          best = s;
        }
      }
    }
    return bestScore >= 0.55 ? best : null;
  }

  /// FN-08: ISBN → book info. Own shelf first, then the scan cache, then
  /// Google Books and Open Library (8 s each). Failures go to the app log.
  Future<BsLookup?> lookupIsbn(String raw, {http.Client? client}) async {
    final isbn = bsToIsbn13(raw);
    if (isbn == null) return null;
    final own = volumesByIsbn(isbn);
    if (own.isNotEmpty) {
      final s = _series[own.first.seriesId];
      if (s != null) {
        return BsLookup(isbn: isbn, title: s.title, author: s.author, publisher: s.publisher, cover: s.cover,
            volume: own.first.number, source: 'shelf');
      }
    }
    for (final sc in _scans) {
      if (sc.isbn == isbn && sc.title.isNotEmpty) {
        return BsLookup(isbn: isbn, title: sc.title, volume: bsVolumeFromTitle(sc.title), source: 'cache');
      }
    }
    final c = client ?? http.Client();
    try {
      try {
        final r = await c
            .get(Uri.parse('https://www.googleapis.com/books/v1/volumes?q=isbn:$isbn'))
            .timeout(const Duration(seconds: 8));
        if (r.statusCode == 200) {
          final j = jsonDecode(r.body);
          final items = j is Map ? j['items'] : null;
          if (items is List && items.isNotEmpty && items.first is Map) {
            final info = (items.first as Map)['volumeInfo'];
            if (info is Map) {
              final title = [info['title'], info['subtitle']].whereType<String>().join(' – ');
              final img = info['imageLinks'];
              return BsLookup(
                isbn: isbn,
                title: title,
                author: (info['authors'] as List?)?.join(', ') ?? '',
                publisher: info['publisher']?.toString() ?? '',
                cover: (img is Map ? (img['thumbnail'] ?? img['smallThumbnail']) : null)?.toString().replaceFirst('http:', 'https:') ?? '',
                synopsis: info['description']?.toString() ?? '',
                volume: bsVolumeFromTitle(title),
                source: 'google',
              );
            }
          }
        } else {
          AppLogger.log('[Tủ Sách] Google Books trả HTTP ${r.statusCode} khi tra ISBN $isbn', logLevel: LogLevel.warning);
        }
      } catch (e) {
        AppLogger.log('[Tủ Sách] Không tra được ISBN $isbn trên Google Books: $e', logLevel: LogLevel.warning);
      }
      try {
        final r = await c
            .get(Uri.parse('https://openlibrary.org/api/books?bibkeys=ISBN:$isbn&format=json&jscmd=data'))
            .timeout(const Duration(seconds: 8));
        if (r.statusCode == 200) {
          final j = jsonDecode(r.body);
          final b = j is Map ? j['ISBN:$isbn'] : null;
          if (b is Map) {
            final title = b['title']?.toString() ?? '';
            final cover = b['cover'];
            return BsLookup(
              isbn: isbn,
              title: title,
              author: [for (final a in (b['authors'] as List? ?? const [])) if (a is Map) a['name']].join(', '),
              publisher: [for (final p in (b['publishers'] as List? ?? const [])) if (p is Map) p['name']].join(', '),
              cover: cover is Map ? (cover['medium'] ?? cover['small'] ?? '').toString() : '',
              volume: bsVolumeFromTitle(title),
              source: 'openlibrary',
            );
          }
        }
      } catch (e) {
        AppLogger.log('[Tủ Sách] Không tra được ISBN $isbn trên Open Library: $e', logLevel: LogLevel.warning);
      }
      return null;
    } finally {
      if (client == null) c.close();
    }
  }

  // ───────────────────────── CSV (FN-30) ─────────────────────────

  static const csvHeader = [
    'Tên bộ', 'Tập', 'Phiên bản', 'ISBN', 'Giá', 'Ngày mua', 'Nơi mua', 'NXB', 'Trạng thái đọc',
    'Số bản', 'Người mượn', 'Hạn trả', 'Tác giả', 'Trạng thái bộ',
  ];

  static String _dateText(int? ms) =>
      ms == null ? '' : DateTime.fromMillisecondsSinceEpoch(ms).toIso8601String().substring(0, 10);

  /// Exports every series – also those without a volume yet (empty "Tập") –
  /// with copies, loan and series columns (0.6.6, FN-30 / FN-28 / FN-26).
  String exportCsv() {
    final b = StringBuffer('﻿${csvHeader.map(bsCsvEscape).join(',')}\r\n');
    for (final s in series) {
      final vols = volumesOf(s.id);
      if (vols.isEmpty) {
        b.write([s.title, '', '', '', '', '', '', s.publisher, '', '', '', '', s.author, s.status.name]
            .map(bsCsvEscape)
            .join(','));
        b.write('\r\n');
      }
      for (final v in vols) {
        b.write([
          s.title,
          v.numberText,
          v.edition.name,
          v.isbn,
          v.price == null ? '' : v.price!.toStringAsFixed(0),
          _dateText(v.purchaseDate),
          v.place,
          s.publisher,
          v.readStatus.name,
          '${v.copies}',
          v.borrower ?? '',
          _dateText(v.loanDue),
          s.author,
          s.status.name,
        ].map(bsCsvEscape).join(','));
        b.write('\r\n');
      }
    }
    return b.toString();
  }

  static BsStatus _statusOf(String raw) {
    final n = bsNormalize(raw);
    for (final e in BsStatus.values) {
      if (n == e.name.toLowerCase()) return e;
    }
    if (n.contains('hoan thanh') || n.contains('tron bo')) return BsStatus.completed;
    if (n.contains('tam ngung') || n.contains('tam dung')) return BsStatus.paused;
    return BsStatus.ongoing;
  }

  /// Imports rows "Tên bộ, Tập (1-20 allowed), Phiên bản, ISBN, Giá, Ngày mua,
  /// Nơi mua, NXB, Trạng thái đọc, Số bản, Người mượn, Hạn trả, Tác giả,
  /// Trạng thái bộ" (columns after NXB are optional). A row with a title and
  /// an empty "Tập" cell only creates the series. Returns (added volumes,
  /// created series, skipped rows).
  Future<({int volumes, int series, int skipped})> importCsv(String text) async {
    final rows = bsParseCsv(text);
    // 0.6.3 review: restore memory if the write fails, so the screen never
    // shows rows that were not stored
    final seriesBefore = Map<String, BsSeries>.of(_series);
    final volumesBefore = Map<String, BsVolume>.of(_volumes);
    var addedV = 0, addedS = 0, skipped = 0;
    for (var i = 0; i < rows.length; i++) {
      final r = rows[i];
      if (i == 0 && r.isNotEmpty && bsNormalize(r.first).startsWith('ten bo')) continue;
      String col(int k) => k < r.length ? bsCsvUnguard(r[k].trim()) : '';
      final title = col(0);
      final nums = bsParseRange(col(1));
      final seriesOnly = title.isNotEmpty && col(1).isEmpty && r.length >= 9;
      if (title.isEmpty || (nums.isEmpty && !seriesOnly)) {
        skipped++;
        continue;
      }
      // 0.6.3 review: CSV rows join a series only on an exact (accent-free)
      // title/original/alias match – fuzzy matching merged "Solaris" and
      // "Solaris Plus"
      final key = bsNormalize(title);
      var s = _series.values
          .where((e) => [e.title, e.original, ...e.aliases].any((c) => c.trim().isNotEmpty && bsNormalize(c) == key))
          .firstOrNull;
      if (s == null) {
        s = BsSeries(
            id: newId('s'),
            title: title,
            publisher: col(7),
            author: col(12),
            status: col(13).isEmpty ? BsStatus.ongoing : _statusOf(col(13)));
        _series[s.id] = s;
        addedS++;
      }
      if (seriesOnly) continue;
      final ed = BsEdition.values.where((e) => bsNormalize(col(2)).contains(e.name) ||
              (e == BsEdition.limited && bsNormalize(col(2)).contains('gioi han')) ||
              (e == BsEdition.special && bsNormalize(col(2)).contains('dac biet'))).firstOrNull ??
          BsEdition.regular;
      final price = bsParseMoney(col(4));
      final date = bsParseDate(col(5));
      for (final n in nums) {
        if (findVolume(s.id, n, ed) != null) continue;
        final v = BsVolume(
          id: newId('v'),
          seriesId: s.id,
          number: n,
          edition: ed,
          isbn: nums.length == 1 ? (bsToIsbn13(col(3)) ?? bsCleanIsbn(col(3))) : '',
          price: nums.length == 1 ? price : null,
          purchaseDate: date?.millisecondsSinceEpoch,
          place: col(6),
          readStatus: _readStatusOf(col(8)),
          copies: math.max(1, int.tryParse(col(9)) ?? 1),
          borrower: col(10).isEmpty ? null : col(10),
          loanDue: col(10).isEmpty ? null : bsParseDate(col(11))?.millisecondsSinceEpoch,
        );
        _volumes[v.id] = v;
        addedV++;
      }
    }
    if (!await _save(['series', 'volumes'])) {
      _series
        ..clear()
        ..addAll(seriesBefore);
      _volumes
        ..clear()
        ..addAll(volumesBefore);
      notifyListeners();
      throw StateError('Không lưu được dữ liệu Tủ Sách: $lastSaveError');
    }
    return (volumes: addedV, series: addedS, skipped: skipped);
  }

  /// Column 9 of the CSV ("Trạng thái đọc"): enum name written by
  /// [exportCsv] or the Vietnamese words; old files without it → unread.
  static BsReadStatus _readStatusOf(String raw) {
    final n = bsNormalize(raw);
    if (n.isEmpty) return BsReadStatus.unread;
    for (final e in BsReadStatus.values) {
      if (n == e.name.toLowerCase()) return e;
    }
    if (n.contains('dang doc')) return BsReadStatus.reading;
    if (n.contains('chua doc')) return BsReadStatus.unread;
    if (n.contains('da doc')) return BsReadStatus.read;
    return BsReadStatus.unread;
  }

  /// Number formatting shared by the UI ("105", "10.5").
  static String fmt(double? v) =>
      v == null ? '' : (v == v.roundToDouble() ? v.toInt().toString() : v.toString());

  /// Max of two nullable numbers.
  static double? maxOf(double? a, double? b) => a == null ? b : (b == null ? a : math.max(a, b));
}
