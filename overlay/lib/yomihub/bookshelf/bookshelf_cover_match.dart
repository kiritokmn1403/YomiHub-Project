/// YomiHub 0.6.4 – Tủ Sách Cá Nhân, FN-22 "Nhận diện bìa bằng ảnh khi không
/// có/không đọc được barcode": the user takes/picks a photo of a cover (old
/// book without barcode, goods without ISBN) and the app suggests the series
/// of the shelf whose cover looks most alike.
///
/// The plan named Perceptual Hash or a TFLite embedding + ML Kit OCR. ML Kit
/// and TFLite are Android-only and add tens of MB, so YomiHub uses a
/// difference hash (dHash, 64 bit) that runs everywhere (Android 6, TV build
/// excluded, Windows) on the series' own cover images. Hashes are cached in
/// the bookshelf box (key `coverHashes`), recomputed when a cover changes.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:mangayomi/yomihub/bookshelf/bookshelf_models.dart';
import 'package:mangayomi/yomihub/bookshelf/bookshelf_store.dart';

class BsCoverCandidate {
  final BsSeries series;
  final int distance; // 0 = identical … 64
  const BsCoverCandidate(this.series, this.distance);

  /// 0..100 % likeness for the UI.
  int get percent => ((64 - distance) * 100 / 64).round();
}

class BookshelfCoverMatch {
  /// Hamming distance accepted as "looks alike" (of 64 bits).
  static const threshold = 18;

  /// dHash of an encoded image (null when it cannot be decoded). Also returns
  /// the hash of the centre 80 % crop – photos of a book usually include a
  /// margin of table/hand around the cover.
  static List<int>? hashes(Uint8List bytes) {
    img.Image? decoded;
    try {
      decoded = img.decodeImage(bytes);
    } catch (_) {
      return null; // some decoders throw on garbage instead of returning null
    }
    if (decoded == null) return null;
    final full = dHash(decoded);
    final w = decoded.width, h = decoded.height;
    final crop = img.copyCrop(decoded, x: (w * 0.1).round(), y: (h * 0.1).round(), width: (w * 0.8).round(), height: (h * 0.8).round());
    return [full, dHash(crop)];
  }

  /// 64-bit difference hash: 9×8 grayscale, bit = left pixel brighter than right.
  static int dHash(img.Image image) {
    final small = img.copyResize(img.grayscale(image), width: 9, height: 8, interpolation: img.Interpolation.average);
    var hash = 0;
    for (var y = 0; y < 8; y++) {
      for (var x = 0; x < 8; x++) {
        final a = small.getPixel(x, y).luminance;
        final b = small.getPixel(x + 1, y).luminance;
        hash = (hash << 1) | (a > b ? 1 : 0);
      }
    }
    return hash;
  }

  static int distance(int a, int b) {
    var x = a ^ b, n = 0;
    while (x != 0) {
      x &= x - 1;
      n++;
    }
    return n;
  }

  /// Ranks [cached] cover hashes (seriesId → hash) against the photo's
  /// hashes. Pure – public for tests.
  static List<MapEntry<String, int>> rank(List<int> photo, Map<String, int> cached, {int limit = 3}) {
    final out = <MapEntry<String, int>>[];
    cached.forEach((id, h) {
      var best = 64;
      for (final p in photo) {
        final d = distance(p, h);
        if (d < best) best = d;
      }
      if (best <= threshold) out.add(MapEntry(id, best));
    });
    out.sort((a, b) => a.value.compareTo(b.value));
    return out.take(limit).toList();
  }

  // ───────────── store-backed ─────────────

  static Future<Uint8List?> _coverBytes(String cover, http.Client c) async {
    if (cover.isEmpty) return null;
    if (cover.startsWith('http')) {
      final r = await c.get(Uri.parse(cover)).timeout(const Duration(seconds: 20));
      return r.statusCode == 200 ? r.bodyBytes : null;
    }
    final f = File(cover);
    return await f.exists() ? await f.readAsBytes() : null;
  }

  /// Hashes of every series cover, computing the missing/changed ones.
  static Future<Map<String, int>> coverHashes({http.Client? client}) async {
    final store = BookshelfStore.instance;
    final saved = Map<String, dynamic>.from((store.raw('coverHashes') as Map?) ?? const {});
    final out = <String, int>{};
    final c = client ?? http.Client();
    var changed = false;
    try {
      for (final s in store.series) {
        if (s.cover.isEmpty) continue;
        final e = saved[s.id];
        if (e is Map && e['cover'] == s.cover && e['h'] is String) {
          final v = int.tryParse(e['h'] as String); // signed decimal (64 bit)
          if (v != null) {
            out[s.id] = v;
            continue;
          }
        }
        try {
          final bytes = await _coverBytes(s.cover, c);
          if (bytes == null) continue;
          final hs = await compute(hashes, bytes);
          if (hs == null) continue;
          out[s.id] = hs.first;
          saved[s.id] = {'cover': s.cover, 'h': '${hs.first}'};
          changed = true;
        } catch (_) {}
      }
      saved.removeWhere((k, _) => store.seriesById(k) == null);
      if (changed) await store.putRaw('coverHashes', saved);
    } finally {
      if (client == null) c.close();
    }
    return out;
  }

  /// Candidates for a photo of a cover.
  static Future<List<BsCoverCandidate>> match(Uint8List photo, {http.Client? client}) async {
    final hs = await compute(hashes, photo);
    if (hs == null) return const [];
    final cached = await coverHashes(client: client);
    final store = BookshelfStore.instance;
    return [
      for (final e in rank(hs, cached))
        if (store.seriesById(e.key) != null) BsCoverCandidate(store.seriesById(e.key)!, e.value)
    ];
  }
}
