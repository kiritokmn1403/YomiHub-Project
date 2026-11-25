import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:mangayomi/services/http/m_client.dart';
import 'package:mangayomi/utils/log/logger.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';
import 'package:url_launcher/url_launcher.dart';

/// YomiHub 0.6.5 (sheet "YomiHub Update": Google Lens + SauceNAO Project →
/// "tìm kiếm bằng hình ảnh"): reverse image search from a reader page.
///
/// * Google Lens: opens `lens.google.com/uploadbyurl?url=…` in the browser
///   when the page has a public http(s) address (no upload of private data).
/// * SauceNAO: uploads the page image to saucenao.com (JSON API,
///   output_type=2) and lists the matches with their similarity. An API key is
///   optional (anonymous searches have a lower daily quota); it is kept in the
///   app preferences and never written to the log.
class YomiReverseImageSearch {
  YomiReverseImageSearch._();

  static const keyPref = 'saucenaoApiKey';

  static Uri? lensUrlFor(String? imageUrl) {
    if (imageUrl == null) return null;
    final u = Uri.tryParse(imageUrl.trim());
    if (u == null || !(u.scheme == 'http' || u.scheme == 'https') || u.host.isEmpty) return null;
    return Uri.https('lens.google.com', '/uploadbyurl', {'url': u.toString()});
  }

  static Future<bool> openLens(String? imageUrl) async {
    final uri = lensUrlFor(imageUrl);
    if (uri == null) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Parses a SauceNAO JSON answer (output_type=2) into matches, best first.
  static List<SauceMatch> parseSauce(String body) {
    final j = jsonDecode(body);
    if (j is! Map) return const [];
    final header = j['header'];
    if (header is Map && (header['status'] is num) && (header['status'] as num) < 0) {
      throw Exception('SauceNAO: ${header['message'] ?? 'status ${header['status']}'}');
    }
    final out = <SauceMatch>[];
    for (final r in (j['results'] as List? ?? const [])) {
      if (r is! Map) continue;
      final h = r['header'] as Map? ?? const {};
      final d = r['data'] as Map? ?? const {};
      final sim = double.tryParse('${h['similarity'] ?? ''}') ?? 0;
      final urls = [for (final u in (d['ext_urls'] as List? ?? const [])) '$u'];
      final title = '${d['title'] ?? d['source'] ?? d['eng_name'] ?? d['jp_name'] ?? h['index_name'] ?? ''}'.trim();
      out.add(SauceMatch(
        similarity: sim,
        title: title,
        thumbnail: '${h['thumbnail'] ?? ''}',
        urls: urls,
        index: '${h['index_name'] ?? ''}',
      ));
    }
    out.sort((a, b) => b.similarity.compareTo(a.similarity));
    return out;
  }

  static Future<List<SauceMatch>> sauceNao(Uint8List image, {http.Client? client}) async {
    final key = YomiPrefs.get<String>(keyPref, '').trim();
    final c = client ?? IOClient(yomiDartHttpClient());
    try {
      final req = http.MultipartRequest(
        'POST',
        Uri.https('saucenao.com', '/search.php', {
          'output_type': '2',
          'numres': '8',
          'db': '999',
          if (key.isNotEmpty) 'api_key': key,
        }),
      )..files.add(http.MultipartFile.fromBytes('file', image, filename: 'page.jpg'));
      final res = await http.Response.fromStream(
        await c.send(req).timeout(const Duration(seconds: 40)),
      );
      if (res.statusCode == 429) {
        throw Exception(tr('SauceNAO: đã hết lượt tìm trong khoảng thời gian này – thử lại sau hoặc nhập API key riêng.'));
      }
      if (res.statusCode != 200) throw Exception('SauceNAO HTTP ${res.statusCode}');
      return parseSauce(res.body);
    } catch (e) {
      // Never let the API key reach the log or the UI (network errors carry the URI).
      final msg = '$e'
          .replaceFirst(RegExp(r'^Exception: '), '')
          .replaceAll(RegExp(r'api_key=[^&\s]+'), 'api_key=***');
      AppLogger.log('[Tìm ảnh] SauceNAO thất bại: $msg', logLevel: LogLevel.warning);
      throw Exception(msg);
    } finally {
      if (client == null) c.close();
    }
  }

  /// Bottom sheet with the two engines.
  static Future<void> show(BuildContext context, {required Uint8List image, String? imageUrl}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _SearchSheet(image: image, imageUrl: imageUrl),
    );
  }
}

class SauceMatch {
  final double similarity;
  final String title;
  final String thumbnail;
  final List<String> urls;
  final String index;
  const SauceMatch({
    required this.similarity,
    required this.title,
    required this.thumbnail,
    required this.urls,
    required this.index,
  });
}

class _SearchSheet extends StatefulWidget {
  final Uint8List image;
  final String? imageUrl;
  const _SearchSheet({required this.image, this.imageUrl});

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  bool _busy = false;
  String? _error;
  List<SauceMatch>? _results;
  late final _key = TextEditingController(text: YomiPrefs.get<String>(YomiReverseImageSearch.keyPref, ''));

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  Future<void> _sauce() async {
    await YomiPrefs.set(YomiReverseImageSearch.keyPref, _key.text.trim());
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await YomiReverseImageSearch.sauceNao(widget.image);
      if (mounted) setState(() => _results = r);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lens = YomiReverseImageSearch.lensUrlFor(widget.imageUrl);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(12),
            children: [
              Text(tr('Tìm kiếm bằng hình ảnh'), style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.travel_explore),
                title: const Text('Google Lens'),
                subtitle: Text(lens == null
                    ? tr('Trang này không có địa chỉ ảnh công khai – dùng SauceNAO bên dưới.')
                    : tr('Mở Google Lens trong trình duyệt với địa chỉ ảnh của trang này.')),
                enabled: lens != null,
                onTap: lens == null ? null : () => YomiReverseImageSearch.openLens(widget.imageUrl),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.image_search_outlined),
                title: const Text('SauceNAO'),
                subtitle: Text(tr('Gửi ảnh trang này lên saucenao.com để tìm nguồn gốc (truyện, artbook, anime).')),
              ),
              TextField(
                controller: _key,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: tr('API key SauceNAO (không bắt buộc)'),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _busy ? null : _sauce,
                icon: _busy
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.search),
                label: Text(tr('Tìm bằng SauceNAO')),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              if (_results != null && _results!.isEmpty)
                Padding(padding: const EdgeInsets.all(8), child: Text(tr('Không có kết quả'))),
              for (final m in _results ?? const <SauceMatch>[])
                ListTile(
                  leading: m.thumbnail.isEmpty
                      ? const Icon(Icons.image_outlined)
                      : _SauceThumb(key: ValueKey(m.thumbnail), url: m.thumbnail),
                  title: Text(m.title.isEmpty ? m.index : m.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${m.similarity.toStringAsFixed(1)}% • ${m.index}', maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: m.urls.isEmpty ? null : const Icon(Icons.open_in_new, size: 18),
                  onTap: m.urls.isEmpty
                      ? null
                      : () {
                          final u = Uri.tryParse(m.urls.first);
                          if (u != null && (u.scheme == 'http' || u.scheme == 'https') && u.host.isNotEmpty) {
                            launchUrl(u, mode: LaunchMode.externalApplication);
                          }
                        },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 0.6.6: result thumbnails go through the same HTTP client as the upload
/// (VPN/Tor aware) instead of Image.network, which bypasses it.
class _SauceThumb extends StatefulWidget {
  final String url;
  const _SauceThumb({required this.url});

  @override
  State<_SauceThumb> createState() => _SauceThumbState();
}

class _SauceThumbState extends State<_SauceThumb> {
  Uint8List? _bytes;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _SauceThumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _bytes = null;
      _failed = false;
      _load();
    }
  }

  Future<void> _load() async {
    final u = Uri.tryParse(widget.url);
    if (u == null || !(u.scheme == 'http' || u.scheme == 'https') || u.host.isEmpty) {
      if (mounted) setState(() => _failed = true);
      return;
    }
    final c = IOClient(yomiDartHttpClient());
    try {
      final r = await c.get(u).timeout(const Duration(seconds: 20));
      if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
      if (mounted) setState(() => _bytes = r.bodyBytes);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      c.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_bytes == null || _failed) return const SizedBox(width: 48, height: 48, child: Icon(Icons.image_outlined));
    return Image.memory(_bytes!, width: 48, height: 48, fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Icon(Icons.image_outlined));
  }
}
