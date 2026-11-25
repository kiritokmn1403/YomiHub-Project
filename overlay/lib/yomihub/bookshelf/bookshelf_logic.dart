/// YomiHub 0.6.3 – "Tủ Sách Cá Nhân" (Personal Bookshelf): pure helpers.
///
/// Everything here is side-effect free so it can be unit tested without
/// Hive/Flutter: text normalisation for instant search (no diacritics, đ→d,
/// aliases, "One Piece 105"), ISBN handling, gap detection (FN-06), fuzzy
/// title matching for barcode → series (FN-19) and CSV import/export (FN-30).
/// Plan: `Ke_Hoach_App_Quan_Ly_Tu_Sach_Ca_Nhan.xlsx` (FN-01 … FN-30).
library;

import 'dart:math' as math;

const _vnFrom = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
const _vnTo = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';

/// Lower-case, strip Vietnamese/Latin diacritics, collapse whitespace and
/// punctuation. "Chú Thuật Hồi Chiến!" → "chu thuat hoi chien".
String bsNormalize(String s) {
  final lower = s.toLowerCase();
  final b = StringBuffer();
  for (final r in lower.runes) {
    final ch = String.fromCharCode(r);
    final i = _vnFrom.indexOf(ch);
    if (i >= 0) {
      b.write(_vnTo[i]);
    } else if (r >= 0x300 && r <= 0x36f) {
      // combining marks (NFD input)
      continue;
    } else if (RegExp(r'[a-z0-9]').hasMatch(ch)) {
      b.write(ch);
    } else {
      b.write(' ');
    }
  }
  return b.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Initials of a title: "Jujutsu Kaisen" → "jk", "Spy x Family" → "sxf".
String bsInitials(String s) =>
    bsNormalize(s).split(' ').where((w) => w.isNotEmpty).map((w) => w[0]).join();

/// A parsed search query: "one piece 105" → (text: "one piece", volume: 105).
class BsQuery {
  final String text;
  final double? volume;
  const BsQuery(this.text, this.volume);
}

final _volWords = RegExp(r'\b(tap|vol|volume|t|q|quyen|so|chap)\s*$');

/// Splits a trailing volume number off a query. Words like "tập", "vol",
/// "quyển" before the number are dropped. A query that is only a number
/// keeps it as text (a series may be called "86").
BsQuery bsParseQuery(String raw) {
  final n = bsNormalize(raw);
  final m = RegExp(r'^(.*?)\s*(\d+(?:\.\d+)?)$').firstMatch(n);
  if (m == null) return BsQuery(n, null);
  var text = m.group(1)!.trim();
  if (text.isEmpty) return BsQuery(n, null);
  text = text.replaceAll(_volWords, '').trim();
  if (text.isEmpty) return BsQuery(n, null);
  return BsQuery(text, double.tryParse(m.group(2)!));
}

/// Score how well [query] (already normalised) matches a series given its
/// title + aliases. 0 = no match. Higher is better.
int bsMatchScore(String query, String title, Iterable<String> aliases) {
  if (query.isEmpty) return 1;
  var best = 0;
  for (final cand in [title, ...aliases]) {
    final c = bsNormalize(cand);
    if (c.isEmpty) continue;
    if (c == query) {
      best = math.max(best, 100);
    } else if (c.startsWith(query)) {
      best = math.max(best, 80);
    } else if (c.contains(query)) {
      best = math.max(best, 60);
    } else if (query.split(' ').every((w) => c.contains(w))) {
      best = math.max(best, 45);
    } else if (!query.contains(' ') && query.length >= 2 && bsInitials(cand) == query) {
      best = math.max(best, 70);
    }
  }
  return best;
}

// ───────────────────────── ISBN ─────────────────────────

/// Digits (and a final X) only.
String bsCleanIsbn(String raw) => raw.toUpperCase().replaceAll(RegExp(r'[^0-9X]'), '');

bool bsIsValidIsbn13(String s) {
  if (!RegExp(r'^\d{13}$').hasMatch(s)) return false;
  var sum = 0;
  for (var i = 0; i < 12; i++) {
    sum += int.parse(s[i]) * (i.isEven ? 1 : 3);
  }
  return (10 - sum % 10) % 10 == int.parse(s[12]);
}

bool bsIsValidIsbn10(String s) {
  if (!RegExp(r'^\d{9}[\dX]$').hasMatch(s)) return false;
  var sum = 0;
  for (var i = 0; i < 10; i++) {
    final v = s[i] == 'X' ? 10 : int.parse(s[i]);
    sum += v * (10 - i);
  }
  return sum % 11 == 0;
}

/// Normalises any ISBN-10/13 (with dashes) to ISBN-13, or null if invalid.
String? bsToIsbn13(String raw) {
  final s = bsCleanIsbn(raw);
  if (bsIsValidIsbn13(s)) return s;
  if (bsIsValidIsbn10(s)) {
    final core = '978${s.substring(0, 9)}';
    var sum = 0;
    for (var i = 0; i < 12; i++) {
      sum += int.parse(core[i]) * (i.isEven ? 1 : 3);
    }
    return '$core${(10 - sum % 10) % 10}';
  }
  return null;
}

/// Volume number in a book title from an online catalogue:
/// "One Piece - Tập 105" / "Vol. 12" / "Conan 104".
double? bsVolumeFromTitle(String title) {
  final n = bsNormalize(title);
  final m = RegExp(r'\b(?:tap|vol|volume|quyen|so|book|t)\s*(\d+(?:\.\d+)?)\b').firstMatch(n) ??
      RegExp(r'(\d+(?:\.\d+)?)\s*$').firstMatch(n);
  return m == null ? null : double.tryParse(m.group(1)!);
}

/// Series name from a book title: drops "Tập 105", "Vol. 3", trailing numbers
/// and edition words, normalised. Used to match a scanned book to a series.
String bsSeriesKey(String title) {
  var n = bsNormalize(title);
  n = n.replaceAll(RegExp(r'\b(?:tap|vol|volume|quyen|so|book)\s*\d+(?:\.\d+)?\b.*$'), '');
  n = n.replaceAll(RegExp(r'\b(?:ban dac biet|ban gioi han|limited|special|ban thuong)\b'), '');
  n = n.replaceAll(RegExp(r'\s*\d+(?:\.\d+)?\s*$'), '');
  return n.replaceAll(RegExp(r'\s+'), ' ').trim();
}

Set<String> _trigrams(String s) {
  final t = '  $s ';
  return {for (var i = 0; i + 3 <= t.length; i++) t.substring(i, i + 3)};
}

/// Trigram (Jaccard) similarity of two strings after normalisation, 0..1.
double bsSimilarity(String a, String b) {
  final x = bsNormalize(a), y = bsNormalize(b);
  if (x.isEmpty || y.isEmpty) return 0;
  if (x == y) return 1;
  final tx = _trigrams(x), ty = _trigrams(y);
  final inter = tx.intersection(ty).length;
  return inter / (tx.length + ty.length - inter);
}

// ───────────────────────── volumes ─────────────────────────

/// FN-06: whole volume numbers missing between the first and the highest
/// owned volume (series that start at 0 count from 0, otherwise from 1).
List<int> bsGaps(Iterable<num> owned) {
  final whole = owned.where((v) => v == v.roundToDouble()).map((v) => v.toInt()).toSet();
  if (whole.isEmpty) return const [];
  final maxV = whole.reduce(math.max);
  final start = whole.contains(0) ? 0 : 1;
  return [for (var i = start; i <= maxV; i++) if (!whole.contains(i)) i];
}

/// "1-5, 7, 9-10" style range text (used on cards and in CSV export).
String bsRangeText(Iterable<num> values) {
  final v = values.map((e) => e.toDouble()).toSet().toList()..sort();
  if (v.isEmpty) return '';
  String f(double d) => d == d.roundToDouble() ? d.toInt().toString() : d.toString();
  final parts = <String>[];
  var start = v.first, prev = v.first;
  for (final x in v.skip(1)) {
    if (x == prev + 1) {
      prev = x;
      continue;
    }
    parts.add(start == prev ? f(start) : '${f(start)}-${f(prev)}');
    start = prev = x;
  }
  parts.add(start == prev ? f(start) : '${f(start)}-${f(prev)}');
  return parts.join(', ');
}

/// Parses "1-5, 7, 10" into numbers (bulk select, FN-12 / import).
List<double> bsParseRange(String s) {
  final out = <double>{};
  for (final part in s.split(RegExp(r'[,;]'))) {
    final p = part.trim();
    if (p.isEmpty) continue;
    final r = RegExp(r'^(\d+)\s*[-–]\s*(\d+)$').firstMatch(p);
    if (r != null) {
      final a = int.parse(r.group(1)!), b = int.parse(r.group(2)!);
      final lo = math.min(a, b), hi = math.max(a, b);
      if (hi - lo > 2000) continue;
      for (var i = lo; i <= hi; i++) {
        out.add(i.toDouble());
      }
    } else {
      final d = double.tryParse(p.replaceAll(',', '.'));
      if (d != null) out.add(d);
    }
  }
  return out.toList()..sort();
}

// ───────────────────────── CSV ─────────────────────────

/// Quotes cells with `,` `;` tab or line breaks (Excel in Vietnamese locales
/// uses `;`) and neutralises spreadsheet formulas (`=`, `+`, `@`, `-x`) with a
/// leading `'` that [bsCsvUnguard] removes again on import.
String bsCsvEscape(String v) {
  if (RegExp(r'^(?:[=+@]|-(?!\d))').hasMatch(v)) v = "'$v";
  return RegExp(r'[",;\t\n\r]').hasMatch(v) ? '"${v.replaceAll('"', '""')}"' : v;
}

String bsCsvUnguard(String v) =>
    RegExp(r"^'(?:[=+@]|-(?!\d))").hasMatch(v) ? v.substring(1) : v;

/// Picks `,` `;` or tab from the first line (outside quotes) – the most
/// frequent one wins, `,` on a tie / no delimiter.
String bsDetectCsvDelimiter(String text) {
  var inQ = false;
  final count = {',': 0, ';': 0, '\t': 0};
  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if (c == '"') {
      inQ = !inQ;
    } else if (!inQ) {
      if (c == '\n' || c == '\r') break;
      if (count.containsKey(c)) count[c] = count[c]! + 1;
    }
  }
  var best = ',';
  for (final e in count.entries) {
    if (e.value > count[best]!) best = e.key;
  }
  return best;
}

/// VND / plain amounts: "120.000đ", "120,000", "1.200.000 VNĐ", "45000",
/// "12.5", "12,50". Returns null when no number is found.
double? bsParseMoney(String raw) {
  final s = raw.replaceAll(RegExp(r'[^0-9.,]'), '');
  if (s.isEmpty || !RegExp(r'\d').hasMatch(s)) return null;
  if (RegExp(r'^\d{1,3}([.,]\d{3})+$').hasMatch(s)) {
    return double.tryParse(s.replaceAll(RegExp(r'[.,]'), ''));
  }
  final m = RegExp(r'^(\d+)[.,](\d{1,2})$').firstMatch(s);
  if (m != null) return double.tryParse('${m.group(1)}.${m.group(2)}');
  return double.tryParse(s.replaceAll(RegExp(r'[.,]'), ''));
}

/// "2026-11-25", "25/11/2026", "25-11-2026", "25.11.2026" (day first).
DateTime? bsParseDate(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return null;
  final iso = DateTime.tryParse(s);
  if (iso != null) return iso;
  final m = RegExp(r'^(\d{1,2})[/.\-](\d{1,2})[/.\-](\d{4})$').firstMatch(s);
  if (m == null) return null;
  final d = int.parse(m.group(1)!), mo = int.parse(m.group(2)!), y = int.parse(m.group(3)!);
  if (mo < 1 || mo > 12 || d < 1 || d > 31) return null;
  final out = DateTime(y, mo, d);
  return out.month == mo ? out : null;
}

/// RFC 4180-ish CSV parser (quotes, doubled quotes, CRLF, BOM). The
/// delimiter is detected from the first line ([bsDetectCsvDelimiter]) so a
/// `;` inside a title of a comma file no longer splits the cell.
List<List<String>> bsParseCsv(String text, {String? delimiter}) {
  if (text.startsWith('﻿')) text = text.substring(1);
  final delim = delimiter ?? bsDetectCsvDelimiter(text);
  final rows = <List<String>>[];
  var row = <String>[];
  final cell = StringBuffer();
  var inQ = false;
  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if (inQ) {
      if (c == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          cell.write('"');
          i++;
        } else {
          inQ = false;
        }
      } else {
        cell.write(c);
      }
    } else if (c == '"') {
      inQ = true;
    } else if (c == delim) {
      row.add(cell.toString());
      cell.clear();
    } else if (c == '\n' || c == '\r') {
      if (c == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
      row.add(cell.toString());
      cell.clear();
      if (row.any((e) => e.trim().isNotEmpty)) rows.add(row);
      row = <String>[];
    } else {
      cell.write(c);
    }
  }
  row.add(cell.toString());
  if (row.any((e) => e.trim().isNotEmpty)) rows.add(row);
  return rows;
}
