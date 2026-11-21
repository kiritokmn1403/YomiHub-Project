/// YomiHub 0.6.4 – YomiHub Update R7: "Frank Yomik" integration.
///
/// FrankYomik (github.com/akitaonrails/FrankYomik) is a self-hosted manga /
/// webtoon reader helper: a Go API + Python workers (manga-ocr, a local LLM
/// through Ollama – ~9 GB VRAM) detect speech bubbles, read and translate
/// them (or add furigana) and return the processed page. It cannot run inside
/// a phone app, so YomiHub talks to the user's own server through its HTTP
/// API (default http://localhost:8080, `Authorization: Bearer <token>`):
///   POST /api/v1/jobs (multipart: image, pipeline, priority) → job id
///   GET  /api/v1/jobs/:id         → status
///   GET  /api/v1/jobs/:id/image   → processed image
///   GET  /api/v1/health
/// Used by the reader's "Dịch ảnh" when the engine "Frank Yomik" is chosen;
/// if the server fails, the built-in OCR + translation is used and the error
/// is written to the app log.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';

class FrankYomikException implements Exception {
  final String message;
  FrankYomikException(this.message);
  @override
  String toString() => 'Frank Yomik: $message';
}

class FrankYomikClient {
  static const pipelines = {
    'manga_translate': 'Dịch truyện tranh (Nhật → ngôn ngữ của máy chủ)',
    'manga_furigana': 'Thêm furigana (truyện tranh tiếng Nhật)',
    'webtoon': 'Webtoon (tiếng Hàn)',
  };

  static bool get selected => YomiPrefs.get<String>('imgTranslateEngine', 'builtin') == 'frank';
  static String get baseUrl => YomiPrefs.get<String>('frankYomikUrl', 'http://localhost:8080');
  static String get token => YomiPrefs.get<String>('frankYomikToken', '');
  static String get pipeline {
    final p = YomiPrefs.get<String>('frankYomikPipeline', 'manga_translate');
    return pipelines.containsKey(p) ? p : 'manga_translate';
  }

  final String base;
  final String bearer;
  final http.Client _c;
  final Duration pollEvery;
  final Duration timeout;

  FrankYomikClient({
    String? base,
    String? bearer,
    http.Client? client,
    this.pollEvery = const Duration(milliseconds: 1500),
    this.timeout = const Duration(seconds: 150),
  })  : base = (base ?? baseUrl).trim().replaceAll(RegExp(r'/+$'), ''),
        bearer = bearer ?? token,
        _c = client ?? http.Client();

  Map<String, String> get _auth => bearer.isEmpty ? const {} : {'Authorization': 'Bearer $bearer'};
  Uri _u(String p) => Uri.parse('$base/api/v1$p');

  void close() => _c.close();

  /// Server reachable + workers status (for "Kiểm tra kết nối").
  Future<String> health() async {
    final r = await _c.get(_u('/health'), headers: _auth).timeout(const Duration(seconds: 10));
    if (r.statusCode != 200) throw FrankYomikException('HTTP ${r.statusCode} ở /health');
    return r.body.length > 300 ? '${r.body.substring(0, 300)}…' : r.body;
  }

  /// Uploads a page and waits for the processed image.
  Future<Uint8List> process(Uint8List image, {String? pipelineName}) async {
    final req = http.MultipartRequest('POST', _u('/jobs'))
      ..headers.addAll(_auth)
      ..fields['pipeline'] = pipelineName ?? pipeline
      ..fields['priority'] = 'high'
      ..files.add(http.MultipartFile.fromBytes('image', image, filename: 'page.png'));
    final sent = await http.Response.fromStream(await _c.send(req).timeout(const Duration(seconds: 30)));
    if (sent.statusCode == 401 || sent.statusCode == 403) {
      throw FrankYomikException('máy chủ từ chối token (HTTP ${sent.statusCode})');
    }
    if (sent.statusCode >= 300) throw FrankYomikException('tải ảnh lên thất bại (HTTP ${sent.statusCode})');
    final id = jobIdOf(sent.body);
    if (id == null) throw FrankYomikException('máy chủ không trả mã công việc');
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      final s = await _c.get(_u('/jobs/$id'), headers: _auth).timeout(const Duration(seconds: 15));
      if (s.statusCode == 200) {
        final st = statusOf(s.body);
        if (st == FrankJobState.failed) {
          throw FrankYomikException('máy chủ xử lý thất bại: ${_short(s.body)}');
        }
        if (st == FrankJobState.done) {
          final img = await _c.get(_u('/jobs/$id/image'), headers: _auth).timeout(const Duration(seconds: 30));
          if (img.statusCode == 200 && img.bodyBytes.isNotEmpty) return img.bodyBytes;
          throw FrankYomikException('không tải được ảnh kết quả (HTTP ${img.statusCode})');
        }
      } else if (s.statusCode == 404) {
        throw FrankYomikException('công việc $id không còn trên máy chủ');
      }
      await Future.delayed(pollEvery);
    }
    throw FrankYomikException('quá ${timeout.inSeconds} giây chưa xử lý xong (máy chủ đang bận?)');
  }

  static String _short(String b) => b.length > 160 ? '${b.substring(0, 160)}…' : b;

  /// Job id from the POST reply (`job_id`, `id` or `{job: {id}}`). Public for tests.
  static String? jobIdOf(String body) {
    try {
      final j = jsonDecode(body);
      if (j is Map) {
        final v = j['job_id'] ?? j['jobId'] ?? j['id'] ?? (j['job'] is Map ? (j['job'] as Map)['id'] : null);
        final s = v?.toString() ?? '';
        return s.isEmpty ? null : s;
      }
    } catch (_) {}
    return null;
  }

  /// Job state from a status reply (field `status` / `state`). Public for tests.
  static FrankJobState statusOf(String body) {
    try {
      final j = jsonDecode(body);
      if (j is Map) {
        final m = j['job'] is Map ? j['job'] as Map : j;
        final s = '${m['status'] ?? m['state'] ?? ''}'.toLowerCase();
        if (const {'done', 'completed', 'complete', 'finished', 'success', 'succeeded', 'ready'}.contains(s)) {
          return FrankJobState.done;
        }
        if (const {'failed', 'error', 'errored', 'cancelled', 'canceled'}.contains(s)) return FrankJobState.failed;
      }
    } catch (_) {}
    return FrankJobState.pending;
  }
}

enum FrankJobState { pending, done, failed }
