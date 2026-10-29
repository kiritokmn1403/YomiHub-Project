import 'package:mangayomi/utils/log/logger.dart';
import 'package:mangayomi/yomihub/prefs/yomi_hive.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:mangayomi/providers/storage_provider.dart';
import 'package:mangayomi/yomihub/vpn/vpn_state.dart';
import 'package:path/path.dart' as p;

/// YomiHub 0.1.5 "Savior": grab the video / audio / file a web page plays and
/// save it with the app's own downloader.
///
/// Cốc Cốc's Savior is closed-source (the coccoc GitHub org only publishes
/// unrelated libraries), so this is an independent implementation of the
/// same idea: the in-app browser watches every media request a page makes
/// (network + <video>/<audio> + fetch/XHR hooks), lists them with their
/// qualities, and downloads direct files (MP4, WebM, MP3, M4A, …, with
/// resume) and HLS streams (master → chosen quality → segments, AES-128
/// decrypted, joined into one .ts) into `<thư mục tải>/Savior/`.
/// DRM-protected streams (Widevine, SAMPLE-AES) are not touched.
enum SaviorKind { file, hls, dash }

class SaviorMedia {
  final String url;
  final String page;
  final SaviorKind kind;
  final String label;
  const SaviorMedia(this.url, this.page, this.kind, this.label);

  static final _media = RegExp(
    r'(\.m3u8|\.mpd|\.mp4|\.m4v|\.webm|\.mkv|\.mov|\.flv|\.mp3|\.m4a|\.aac|\.ogg|\.opus|\.wav|\.flac)(\?|#|$)|mime=video|mime=audio|/hls/.*\.m3u8',
    caseSensitive: false,
  );
  static final _ignore = RegExp(
    r'(doubleclick|googlesyndication|google-analytics|googletagmanager|/ads?/|vast|preroll|\.ts(\?|$)|\.m4s(\?|$)|seg-\d+|segment\d|chunk-?\d|init\.mp4|range=)',
    caseSensitive: false,
  );

  /// Null when [url] is not a downloadable media resource.
  static SaviorMedia? classify(String url, String page) {
    if (!url.startsWith('http')) return null;
    if (!_media.hasMatch(url) || _ignore.hasMatch(url)) return null;
    final l = url.toLowerCase();
    final kind = l.contains('.m3u8')
        ? SaviorKind.hls
        : l.contains('.mpd')
        ? SaviorKind.dash
        : SaviorKind.file;
    final ext = RegExp(r'\.([a-z0-9]{2,4})(\?|#|$)').firstMatch(l)?.group(1) ?? '';
    final label = switch (kind) {
      SaviorKind.hls => tr('Luồng HLS (m3u8)'),
      SaviorKind.dash => tr('Luồng DASH (mpd) – chưa hỗ trợ tải'),
      SaviorKind.file => const {'mp3', 'm4a', 'aac', 'ogg', 'opus', 'wav', 'flac'}.contains(ext)
          ? tr('Âm thanh .{p0}', {'p0': ext})
          : 'Video .${ext.isEmpty ? 'mp4' : ext}',
    };
    return SaviorMedia(url, page, kind, label);
  }
}

class SaviorVariant {
  final String url;
  final int bandwidth;
  final String resolution;
  const SaviorVariant(this.url, this.bandwidth, this.resolution);
  String get label =>
      '${resolution.isEmpty ? '' : '${resolution.split('x').last}p · '}${(bandwidth / 1e6).toStringAsFixed(1)} Mbps';
}

class SaviorTask extends ChangeNotifier {
  final String id;
  final String url;
  final String title;
  final SaviorKind kind;
  final Map<String, String> headers;
  String status = 'queued'; // queued, running, done, error, cancelled
  int received = 0;
  int total = 0; // bytes, or segments for HLS
  int segDone = 0;
  String? path;
  String? error;
  bool _cancel = false;
  SaviorTask({
    required this.id,
    required this.url,
    required this.title,
    required this.kind,
    required this.headers,
  });

  double? get progress => kind == SaviorKind.hls
      ? (total > 0 ? segDone / total : null)
      : (total > 0 ? received / total : null);

  void _set(void Function() f) {
    f();
    notifyListeners();
    Savior.instance.changed();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'url': url,
    'title': title,
    'kind': kind.index,
    'status': status,
    'path': path,
    'error': error,
    'received': received,
  };

  static SaviorTask fromJson(Map m) =>
      SaviorTask(
          id: m['id'],
          url: m['url'],
          title: m['title'],
          kind: SaviorKind.values[(m['kind'] as int).clamp(0, 2)],
          headers: const {},
        )
        ..status = m['status'] == 'running' || m['status'] == 'queued'
            ? 'error'
            : m['status']
        ..path = m['path']
        ..error = m['status'] == 'running' ? tr('Bị dừng khi đóng ứng dụng') : m['error']
        ..received = m['received'] ?? 0;
}

class Savior extends ChangeNotifier {
  Savior._();
  static final instance = Savior._();

  final tasks = <SaviorTask>[];
  final _queue = Queue<SaviorTask>();
  int _running = 0;
  static const _maxParallel = 2;
  Box? _box;

  Future<void> init() async {
    if (_box != null) return;
    try {
      _box = await YomiHive.open('yomihub_savior');
      final raw = (_box!.get('tasks', defaultValue: '[]') as String);
      for (final m in (jsonDecode(raw) as List)) {
        tasks.add(SaviorTask.fromJson(m as Map));
      }
    } catch (_) {}
  }

  void _save() {
    try {
      _box?.put('tasks', jsonEncode(tasks.map((t) => t.toJson()).toList()));
    } catch (_) {}
  }

  void changed() => notifyListeners();

  HttpClient _client() {
    final c = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20)
      ..userAgent =
          'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Mobile Safari/537.36';
    // Follow "VPN & DNS" for downloads too (HTTP proxies only).
    final proxy = YomiVpnState.proxyFor(null);
    if (proxy != null && proxy.startsWith('http')) {
      final u = Uri.parse(proxy);
      c.findProxy = (_) => 'PROXY ${u.host}:${u.port}';
    }
    c.badCertificateCallback = (_, _, _) => true;
    return c;
  }

  Future<HttpClientResponse> _get(
    HttpClient c,
    String url,
    Map<String, String> headers, {
    int? from,
  }) async {
    final req = await c.getUrl(Uri.parse(url));
    headers.forEach(req.headers.set);
    if (from != null && from > 0) req.headers.set('Range', 'bytes=$from-');
    return req.close();
  }

  Future<String> _text(String url, Map<String, String> h) async {
    final c = _client();
    try {
      final r = await _get(c, url, h);
      return await r.transform(utf8.decoder).join();
    } finally {
      c.close(force: true);
    }
  }

  /// Qualities of an HLS master playlist (empty for a media playlist).
  Future<List<SaviorVariant>> variants(String url, Map<String, String> h) async {
    final body = await _text(url, h);
    final out = <SaviorVariant>[];
    final lines = const LineSplitter().convert(body);
    for (var i = 0; i < lines.length; i++) {
      final l = lines[i];
      if (!l.startsWith('#EXT-X-STREAM-INF')) continue;
      final bw = int.tryParse(RegExp(r'BANDWIDTH=(\d+)').firstMatch(l)?.group(1) ?? '') ?? 0;
      final res = RegExp(r'RESOLUTION=(\d+x\d+)').firstMatch(l)?.group(1) ?? '';
      for (var j = i + 1; j < lines.length; j++) {
        final u = lines[j].trim();
        if (u.isEmpty || u.startsWith('#')) continue;
        out.add(SaviorVariant(Uri.parse(url).resolve(u).toString(), bw, res));
        break;
      }
    }
    out.sort((a, b) => b.bandwidth.compareTo(a.bandwidth));
    return out;
  }

  static String _safe(String s) {
    final t = s.replaceAll(RegExp(r'[\\/:*?"<>|\n\r\t]'), '_').trim();
    return (t.isEmpty ? 'savior' : t).substring(0, t.length.clamp(1, 120));
  }

  Future<Directory> _dir() async {
    final base = await StorageProvider().getDirectory();
    final d = Directory(p.join(base!.path, 'Savior'));
    await d.create(recursive: true);
    return d;
  }

  SaviorTask add({
    required String url,
    required String title,
    required SaviorKind kind,
    String? page,
    Map<String, String>? headers,
  }) {
    final h = <String, String>{
      if (page != null && page.startsWith('http')) 'Referer': page,
      if (page != null && page.startsWith('http'))
        'Origin': Uri.parse(page).origin,
      ...?headers,
    };
    final t = SaviorTask(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      url: url,
      title: title,
      kind: kind,
      headers: h,
    );
    tasks.insert(0, t);
    _queue.add(t);
    _save();
    notifyListeners();
    _pump();
    return t;
  }

  void cancel(SaviorTask t) {
    t._cancel = true;
    if (t.status == 'queued') {
      _queue.remove(t);
      t._set(() => t.status = 'cancelled');
      _save();
    }
  }

  void remove(SaviorTask t, {bool deleteFile = false}) {
    cancel(t);
    tasks.remove(t);
    if (deleteFile && t.path != null) {
      try {
        File(t.path!).deleteSync();
      } catch (_) {}
    }
    _save();
    notifyListeners();
  }

  void retry(SaviorTask t) {
    if (t.status == 'running' || t.status == 'queued') return;
    t._cancel = false;
    t._set(() {
      t.status = 'queued';
      t.error = null;
    });
    _queue.add(t);
    _pump();
  }

  void _pump() {
    while (_running < _maxParallel && _queue.isNotEmpty) {
      final t = _queue.removeFirst();
      _running++;
      unawaited(_run(t).whenComplete(() {
        _running--;
        _save();
        _pump();
      }));
    }
  }

  Future<void> _run(SaviorTask t) async {
    t._set(() => t.status = 'running');
    try {
      final dir = await _dir();
      if (t.kind == SaviorKind.hls) {
        await _hls(t, dir);
      } else if (t.kind == SaviorKind.file) {
        await _file(t, dir);
      } else {
        throw tr('Luồng DASH (.mpd) chưa tải được – hãy chọn luồng HLS hoặc MP4 nếu trang có');
      }
      t._set(() => t.status = t._cancel ? 'cancelled' : 'done');
    } catch (e) {
      t._set(() {
        t.status = t._cancel ? 'cancelled' : 'error';
        t.error = '$e';
      });
      // 0.2.3: download errors go to the app log
      if (!t._cancel) {
        AppLogger.log('[Tải xuống] Trình tải video (Savior) thất bại: "${t.title}" • URL: ${t.url} • lỗi: $e',
            logLevel: LogLevel.error);
      }
    }
  }

  Future<void> _file(SaviorTask t, Directory dir) async {
    final ext = RegExp(r'\.([a-z0-9]{2,4})(\?|#|$)', caseSensitive: false)
            .firstMatch(t.url)
            ?.group(1) ??
        'mp4';
    final f = File(t.path ?? p.join(dir.path, '${_safe(t.title)}.$ext'));
    t.path = f.path;
    final have = await f.exists() ? await f.length() : 0;
    final c = _client();
    try {
      var r = await _get(c, t.url, t.headers, from: have);
      final resumed = r.statusCode == 206 && have > 0;
      if (r.statusCode >= 400) throw 'HTTP ${r.statusCode}';
      final len = r.contentLength;
      t._set(() {
        t.received = resumed ? have : 0;
        t.total = len > 0 ? len + (resumed ? have : 0) : 0;
      });
      final sink = f.openWrite(mode: resumed ? FileMode.append : FileMode.write);
      var tick = DateTime.now();
      try {
        await for (final chunk in r) {
          if (t._cancel) break;
          sink.add(chunk);
          t.received += chunk.length;
          if (DateTime.now().difference(tick).inMilliseconds > 300) {
            tick = DateTime.now();
            t._set(() {});
          }
        }
      } finally {
        await sink.close();
      }
      t._set(() {});
    } finally {
      c.close(force: true);
    }
  }

  Future<void> _hls(SaviorTask t, Directory dir) async {
    var url = t.url;
    // master → highest quality when the task was created from a master link
    final vs = await variants(url, t.headers);
    if (vs.isNotEmpty) url = vs.first.url;
    final body = await _text(url, t.headers);
    if (body.contains('METHOD=SAMPLE-AES') || body.contains('KEYFORMAT="com.widevine')) {
      throw tr('Luồng có DRM – không thể tải');
    }
    final base = Uri.parse(url);
    final segs = <(String, Uint8List?, Uint8List?)>[]; // url, key, iv
    Uint8List? key;
    Uint8List? iv;
    var seq = int.tryParse(RegExp(r'#EXT-X-MEDIA-SEQUENCE:(\d+)').firstMatch(body)?.group(1) ?? '') ?? 0;
    String? init;
    final keyCache = <String, Uint8List>{};
    for (final raw in const LineSplitter().convert(body)) {
      final l = raw.trim();
      if (l.startsWith('#EXT-X-KEY')) {
        final method = RegExp(r'METHOD=([A-Z0-9-]+)').firstMatch(l)?.group(1);
        if (method == 'NONE') {
          key = null;
          iv = null;
          continue;
        }
        final uri = RegExp(r'URI="([^"]+)"').firstMatch(l)?.group(1);
        if (uri != null) {
          final ku = base.resolve(uri).toString();
          key = keyCache[ku] ??= await _bytes(ku, t.headers);
        }
        final ivHex = RegExp(r'IV=0x([0-9a-fA-F]+)').firstMatch(l)?.group(1);
        iv = ivHex == null ? null : _hex(ivHex.padLeft(32, '0'));
      } else if (l.startsWith('#EXT-X-MAP')) {
        final uri = RegExp(r'URI="([^"]+)"').firstMatch(l)?.group(1);
        if (uri != null) init = base.resolve(uri).toString();
      } else if (l.isNotEmpty && !l.startsWith('#')) {
        segs.add((
          base.resolve(l).toString(),
          key,
          key == null ? null : (iv ?? _seqIv(seq)),
        ));
        seq++;
      }
    }
    if (segs.isEmpty) throw tr('Danh sách phát không có đoạn video');
    final ext = init != null ? 'mp4' : 'ts';
    final out = File(t.path ?? p.join(dir.path, '${_safe(t.title)}.$ext'));
    t.path = out.path;
    t._set(() {
      t.total = segs.length;
      t.segDone = 0;
      t.received = 0;
    });
    final sink = out.openWrite();
    try {
      if (init != null) sink.add(await _bytes(init, t.headers));
      // 4 segments in flight, written strictly in order
      const window = 4;
      final pending = <int, Future<Uint8List>>{};
      Future<Uint8List> fetch(int i) async {
        final (u, k, v) = segs[i];
        for (var attempt = 0; ; attempt++) {
          try {
            var data = await _bytes(u, t.headers);
            if (k != null) {
              data = Uint8List.fromList(
                enc.Encrypter(enc.AES(enc.Key(k), mode: enc.AESMode.cbc, padding: null))
                    .decryptBytes(enc.Encrypted(data), iv: enc.IV(v!)),
              );
              data = _unpad(data);
            }
            return data;
          } catch (e) {
            if (attempt >= 3 || t._cancel) rethrow;
            await Future<void>.delayed(Duration(milliseconds: 600 * (attempt + 1)));
          }
        }
      }

      for (var i = 0; i < segs.length && i < window; i++) {
        pending[i] = fetch(i);
      }
      for (var i = 0; i < segs.length; i++) {
        if (t._cancel) break;
        final data = await pending.remove(i)!;
        final next = i + window;
        if (next < segs.length) pending[next] = fetch(next);
        sink.add(data);
        t.received += data.length;
        t._set(() => t.segDone = i + 1);
      }
      for (final f in pending.values) {
        unawaited(f.then((_) {}, onError: (_) {}));
      }
    } finally {
      await sink.close();
    }
  }

  static Uint8List _unpad(Uint8List d) {
    if (d.isEmpty) return d;
    final n = d.last;
    if (n < 1 || n > 16 || n > d.length) return d;
    for (var i = d.length - n; i < d.length; i++) {
      if (d[i] != n) return d;
    }
    return Uint8List.sublistView(d, 0, d.length - n);
  }

  static Uint8List _seqIv(int seq) {
    final b = Uint8List(16);
    for (var i = 0; i < 8; i++) {
      b[15 - i] = (seq >> (8 * i)) & 0xff;
    }
    return b;
  }

  static Uint8List _hex(String h) => Uint8List.fromList([
    for (var i = 0; i + 1 < h.length; i += 2) int.parse(h.substring(i, i + 2), radix: 16),
  ]);

  Future<Uint8List> _bytes(String url, Map<String, String> h) async {
    final c = _client();
    try {
      final r = await _get(c, url, h);
      if (r.statusCode >= 400) throw 'HTTP ${r.statusCode} – $url';
      final b = BytesBuilder(copy: false);
      await for (final chunk in r) {
        b.add(chunk);
      }
      return b.takeBytes();
    } finally {
      c.close(force: true);
    }
  }
}
