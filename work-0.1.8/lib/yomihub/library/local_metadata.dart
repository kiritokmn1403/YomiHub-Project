import 'dart:convert';

import 'package:mangayomi/models/manga.dart';

/// YomiHub 0.1.7: metadata for a local title, read from whichever side-car
/// file the folder came with:
///  * Mangayomi / YomiHub `*.json` (`name`, `status` = index of [Status]),
///  * Mihon / Aniyomi / Nekoyomi local source `details.json`
///    (`title`, `status` = 0..6 in Tachiyomi's SManga numbering),
///  * Kotatsu `index.json` (`title`, `state`, `tags` [{title}], `authors`),
///  * `ComicInfo.xml` (Series, Writer, Penciller, Summary, Genre, Tags).
///
/// The old scanner assumed the Mangayomi shape only: a Mihon `details.json`
/// wiped the title (`name` = null) and an out-of-range status threw.
class LocalMeta {
  String? title;
  String? author;
  String? artist;
  String? description;
  List<String>? genre;
  Status? status;

  bool get isEmpty =>
      (title ?? '').isEmpty &&
      (author ?? '').isEmpty &&
      (artist ?? '').isEmpty &&
      (description ?? '').isEmpty &&
      (genre ?? const []).isEmpty &&
      status == null;

  /// Copies the non-empty fields onto [m]. Returns true when [m] changed.
  bool applyTo(Manga m) {
    var changed = false;
    void set<T>(T? v, T? Function() get, void Function(T) put) {
      if (v == null) return;
      if (v is String && v.trim().isEmpty) return;
      if (v is List && v.isEmpty) return;
      if (get() == v) return;
      put(v);
      changed = true;
    }

    set<String>(title?.trim(), () => m.name, (v) => m.name = v);
    set<String>(author?.trim(), () => m.author, (v) => m.author = v);
    set<String>(artist?.trim(), () => m.artist, (v) => m.artist = v);
    set<String>(description?.trim(), () => m.description, (v) => m.description = v);
    if (genre != null && genre!.isNotEmpty && (m.genre == null || m.genre!.join('|') != genre!.join('|'))) {
      m.genre = genre;
      changed = true;
    }
    if (status != null && m.status != status) {
      m.status = status!;
      changed = true;
    }
    return changed;
  }
}

/// Tachiyomi / Mihon / Aniyomi SManga.status numbering.
Status _tachiStatus(Object? v) {
  final i = v is num ? v.toInt() : int.tryParse('$v');
  return switch (i) {
    1 => Status.ongoing,
    2 => Status.completed,
    3 => Status.unknown, // licensed
    4 => Status.publishingFinished,
    5 => Status.canceled,
    6 => Status.onHiatus,
    _ => Status.unknown,
  };
}

Status? _statusFromText(String? s) {
  final t = (s ?? '').toLowerCase().trim();
  if (t.isEmpty) return null;
  if (t.contains('hiatus') || t.contains('tạm ngưng')) return Status.onHiatus;
  if (t.contains('cancel') || t.contains('abandon') || t.contains('drop')) return Status.canceled;
  if (t.contains('ongoing') || t.contains('publishing') || t.contains('đang')) return Status.ongoing;
  if (t.contains('finish') || t.contains('complete') || t.contains('end') || t.contains('hoàn')) {
    return Status.completed;
  }
  return null;
}

List<String>? _strings(Object? v) {
  if (v is List) {
    final out = <String>[];
    for (final e in v) {
      if (e is String && e.trim().isNotEmpty) out.add(e.trim());
      if (e is Map && e['title'] is String) out.add((e['title'] as String).trim());
      if (e is Map && e['name'] is String) out.add((e['name'] as String).trim());
    }
    return out.isEmpty ? null : out;
  }
  if (v is String && v.trim().isNotEmpty) {
    return v.split(RegExp(r'[,;]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }
  return null;
}

String? _str(Object? v) {
  if (v == null) return null;
  if (v is List) return _strings(v)?.join(', ');
  final s = '$v'.trim();
  return s.isEmpty ? null : s;
}

/// Parses a side-car JSON file; returns null when it is not metadata.
LocalMeta? parseLocalJson(String text) {
  Object? data;
  try {
    data = jsonDecode(text);
  } catch (_) {
    return null;
  }
  if (data is! Map) return null;
  final m = LocalMeta();
  if (data.containsKey('name') && !data.containsKey('title')) {
    // Mangayomi / YomiHub export
    m.title = _str(data['name']);
    final s = data['status'];
    if (s is num && s >= 0 && s < Status.values.length) {
      m.status = Status.values[s.toInt()];
    } else if (s is String) {
      m.status = _statusFromText(s);
    }
  } else {
    // Mihon / Aniyomi / Nekoyomi details.json, Kotatsu index.json
    m.title = _str(data['title']);
    final s = data['status'] ?? data['state'];
    // Mihon's details.json writes the number as a string ("1")
    if (s is num || (s is String && int.tryParse(s.trim()) != null)) {
      m.status = _tachiStatus(s is String ? int.parse(s.trim()) : s);
    } else if (s is String) {
      m.status = _statusFromText(s);
    }
  }
  m.author = _str(data['author'] ?? data['authors']);
  m.artist = _str(data['artist']);
  m.description = _str(data['description']);
  m.genre = _strings(data['genre'] ?? data['genres'] ?? data['tags']);
  return m.isEmpty ? null : m;
}

/// Parses `ComicInfo.xml` (Anansi schema used by Mihon, Komga, Kavita…).
LocalMeta? parseComicInfo(String xml) {
  String? tag(String name) {
    final r = RegExp('<$name>([\\s\\S]*?)</$name>', caseSensitive: false).firstMatch(xml);
    if (r == null) return null;
    final v = r
        .group(1)!
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&amp;', '&')
        .trim();
    return v.isEmpty ? null : v;
  }

  final m = LocalMeta()
    ..title = tag('Series') ?? tag('Title')
    ..author = tag('Writer')
    ..artist = tag('Penciller') ?? tag('Artist')
    ..description = tag('Summary')
    ..genre = _strings([
      ...?_strings(tag('Genre')),
      ...?_strings(tag('Tags')),
    ]);
  final st = tag('ty:PublishingStatusTachiyomi') ?? tag('PublishingStatus');
  m.status = _statusFromText(st);
  return m.isEmpty ? null : m;
}
