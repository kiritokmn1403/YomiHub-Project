import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_interceptor/http_interceptor.dart';
import 'package:mangayomi/eval/model/source_preference.dart';
import 'package:mangayomi/models/source.dart';
import 'package:mangayomi/modules/browse/extension/providers/extension_preferences_providers.dart';
import 'package:mangayomi/repositories/source_repository.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';

/// YomiHub 0.1.7 – "Đổi URL" / "Cưỡng chế đổi URL" for any extension.
///
/// * **Đổi URL**: writes the new address into the extension's own domain
///   setting when it has one (Mihon "Override BaseUrl", Mangayomi
///   "domain_url"…), and into the source's base URL – kept across extension
///   updates.
/// * **Cưỡng chế đổi URL**: on top of that, every request YomiHub makes to
///   the old host (pages, covers, chapter links already saved in the
///   library, downloads) is sent to the new host instead – for extensions
///   that hard-code their domain.
class YomiUrlOverride {
  YomiUrlOverride._();

  static const _key = 'urlOverrides';
  static Map<String, dynamic>? _cache;

  /// sourceId → {from, to, force}
  static Map<String, dynamic> get _all {
    _ensureLoaded();
    return _cache ?? <String, dynamic>{};
  }

  static void _ensureLoaded() {
    if (_cache != null) return;
    if (!YomiPrefs.isOpen) return; // not ready yet: try again next time
    try {
      final raw = YomiPrefs.get<String>(_key, '');
      _cache = raw.isEmpty ? <String, dynamic>{} : Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      _cache = <String, dynamic>{};
    }
    _rebuild();
  }

  static Map<String, Uri> _forced = {};

  static void _rebuild() {
    final m = <String, Uri>{};
    for (final v in (_cache ?? const {}).values) {
      if (v is! Map || v['force'] != true) continue;
      final from = Uri.tryParse('${v['from']}');
      final to = Uri.tryParse('${v['to']}');
      if (from == null || to == null || from.host.isEmpty || to.host.isEmpty) continue;
      m[from.host.toLowerCase()] = to;
    }
    _forced = m;
  }

  static Future<void> _save() async {
    _rebuild();
    await YomiPrefs.set(_key, jsonEncode(_cache));
  }

  static Map<String, dynamic>? of(int? sourceId) {
    if (sourceId == null) return null;
    final v = _all['$sourceId'];
    return v is Map ? Map<String, dynamic>.from(v) : null;
  }

  /// Base URL to keep for [sourceId] after an extension update.
  static String? baseUrlFor(int? sourceId, String? fromRepo) {
    final o = of(sourceId);
    return o == null ? fromRepo : '${o['to']}';
  }

  /// "https://example.org/" → "https://example.org"; null when invalid.
  static String? normalise(String input) {
    var t = input.trim();
    if (t.isEmpty) return null;
    if (!t.contains('://')) t = 'https://$t';
    final u = Uri.tryParse(t);
    if (u == null || u.host.isEmpty || !(u.scheme == 'http' || u.scheme == 'https')) return null;
    var s = '${u.scheme}://${u.host}${u.hasPort ? ':${u.port}' : ''}${u.path}';
    while (s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }

  /// Preferences that look like the extension's own domain setting.
  static List<SourcePreference> domainPrefs(List<SourcePreference>? prefs) {
    if (prefs == null) return const [];
    final re = RegExp(r'domain|base_?url|baseurl|mirror|tên miền|url', caseSensitive: false);
    return prefs.where((p) {
      final t = p.editTextPreference?.title ?? p.listPreference?.title ?? '';
      return (p.editTextPreference != null || p.listPreference != null) &&
          (re.hasMatch(p.key ?? '') || re.hasMatch(t));
    }).toList();
  }

  static Future<void> apply(Source source, String newUrl, {required bool force, List<SourcePreference>? prefs}) async {
    _ensureLoaded();
    _cache ??= <String, dynamic>{};
    final to = normalise(newUrl)!;
    final previous = of(source.id);
    final from = '${previous?['from'] ?? source.baseUrl ?? ''}';
    _all['${source.id}'] = {'from': from, 'to': to, 'force': force};
    await _save();
    // the extension's own setting
    for (final p in domainPrefs(prefs)) {
      if (p.editTextPreference != null) {
        p.editTextPreference!.value = to;
        p.editTextPreference!.text = to;
        setPreferenceSetting(p, source);
      } else if (p.listPreference != null) {
        final vals = p.listPreference!.entryValues ?? const [];
        final i = vals.indexWhere((v) => normalise(v) == to);
        if (i >= 0) {
          p.listPreference!.valueIndex = i;
          setPreferenceSetting(p, source);
        }
      }
    }
    source.baseUrl = to;
    await sourceRepository.save(source);
  }

  static Future<void> clear(Source source) async {
    final o = of(source.id);
    if (o == null) return;
    _all.remove('${source.id}');
    await _save();
    final from = '${o['from']}';
    if (from.isNotEmpty) {
      source.baseUrl = from;
      await sourceRepository.save(source);
    }
  }

  /// Forced rewrite of [url] (old host → new host), or null.
  static Uri? rewrite(Uri url) {
    _ensureLoaded();
    if (_forced.isEmpty) return null;
    final to = _forced[url.host.toLowerCase()];
    if (to == null) return null;
    return url.replace(scheme: to.scheme, host: to.host, port: to.hasPort ? to.port : null);
  }

  /// Quick check that the new address answers.
  static Future<String> test(String url) async {
    try {
      final r = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      return r.statusCode < 400
          ? 'Trang trả lời HTTP ${r.statusCode} – dùng được'
          : (r.statusCode == 403 || r.statusCode == 503
              ? 'HTTP ${r.statusCode} – có thể là Cloudflare (dùng Cloudflare Bypass hoặc WebView)'
              : 'HTTP ${r.statusCode}');
    } catch (e) {
      return 'Không kết nối được: $e';
    }
  }
}

/// MClient interceptor for "Cưỡng chế đổi URL".
class YomiUrlRewriteInterceptor extends InterceptorContract {
  @override
  Future<BaseRequest> interceptRequest({required BaseRequest request}) async {
    final to = YomiUrlOverride.rewrite(request.url);
    if (to == null || request is! Request) return request;
    final r = Request(request.method, to)
      ..headers.addAll(request.headers)
      ..followRedirects = request.followRedirects
      ..maxRedirects = request.maxRedirects
      ..persistentConnection = request.persistentConnection;
    if (request.bodyBytes.isNotEmpty) r.bodyBytes = request.bodyBytes;
    // the Host / Referer headers of the old domain would be rejected
    r.headers.removeWhere((k, _) => k.toLowerCase() == 'host');
    for (final h in ['referer', 'origin']) {
      final k = r.headers.keys.where((e) => e.toLowerCase() == h).firstOrNull;
      if (k != null) {
        final u = Uri.tryParse(r.headers[k]!);
        if (u != null && YomiUrlOverride.rewrite(u) != null) {
          r.headers[k] = YomiUrlOverride.rewrite(u).toString();
        }
      }
    }
    return r;
  }

  @override
  Future<BaseResponse> interceptResponse({required BaseResponse response}) async => response;
}

/// Card on the extension detail page.
class YomiUrlOverrideCard extends StatefulWidget {
  final Source source;
  final List<SourcePreference>? prefs;
  final VoidCallback? onChanged;
  const YomiUrlOverrideCard({super.key, required this.source, this.prefs, this.onChanged});

  @override
  State<YomiUrlOverrideCard> createState() => _YomiUrlOverrideCardState();
}

class _YomiUrlOverrideCardState extends State<YomiUrlOverrideCard> {
  Future<void> _edit({required bool force}) async {
    final o = YomiUrlOverride.of(widget.source.id);
    final ctrl = TextEditingController(text: '${o?['to'] ?? widget.source.baseUrl ?? ''}');
    String? err;
    String? test;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: Text(force ? 'Cưỡng chế đổi URL' : 'Đổi URL'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: ctrl,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Địa chỉ mới',
                  hintText: 'https://ten-mien-moi.com',
                  errorText: err,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                force
                    ? 'Mọi request tới “${Uri.tryParse('${o?['from'] ?? widget.source.baseUrl}')?.host ?? ''}” '
                        '(trang, ảnh, chương đã lưu, tải xuống) đều được chuyển sang địa chỉ mới – dùng khi tiện ích '
                        'ghi cứng tên miền. Tiện ích APK Mihon/Aniyomi chỉ đổi được qua cài đặt riêng của tiện ích.'
                    : 'Ghi vào cài đặt tên miền của tiện ích (nếu có) và URL gốc của nguồn; giữ nguyên khi tiện ích cập nhật.',
                style: const TextStyle(fontSize: 12),
              ),
              if (test != null) ...[
                const SizedBox(height: 8),
                Text(test!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final n = YomiUrlOverride.normalise(ctrl.text);
                if (n == null) {
                  set(() => err = 'URL không hợp lệ');
                  return;
                }
                set(() => test = 'Đang kiểm tra…');
                final t = await YomiUrlOverride.test(n);
                set(() => test = t);
              },
              child: const Text('Kiểm tra'),
            ),
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
            FilledButton(
              onPressed: () {
                if (YomiUrlOverride.normalise(ctrl.text) == null) {
                  set(() => err = 'URL không hợp lệ');
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    await YomiUrlOverride.apply(widget.source, ctrl.text, force: force, prefs: widget.prefs);
    widget.onChanged?.call();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final o = YomiUrlOverride.of(widget.source.id);
    final cs = Theme.of(context).colorScheme;
    final hasPref = YomiUrlOverride.domainPrefs(widget.prefs).isNotEmpty;
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.link, color: cs.primary),
                const SizedBox(width: 8),
                const Expanded(child: Text('URL của tiện ích', style: TextStyle(fontWeight: FontWeight.bold))),
                if (o != null)
                  Chip(
                    label: Text(o['force'] == true ? 'Cưỡng chế' : 'Đã đổi'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            SelectableText(widget.source.baseUrl ?? '', style: const TextStyle(fontSize: 12)),
            if (o != null)
              Text('Gốc: ${o['from']}', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            if (hasPref)
              Text('Tiện ích có cài đặt tên miền riêng – sẽ được cập nhật cùng.',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () => _edit(force: false),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Đổi URL'),
                ),
                TextButton.icon(
                  onPressed: () => _edit(force: true),
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Cưỡng chế đổi URL'),
                ),
                if (o != null)
                  TextButton.icon(
                    onPressed: () async {
                      await YomiUrlOverride.clear(widget.source);
                      widget.onChanged?.call();
                      if (mounted) setState(() {});
                    },
                    icon: const Icon(Icons.undo),
                    label: const Text('Khôi phục'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
