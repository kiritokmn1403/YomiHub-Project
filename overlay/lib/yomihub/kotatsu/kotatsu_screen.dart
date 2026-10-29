import 'dart:io';
import 'package:mangayomi/yomihub/win/jvm_bridge.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mangayomi/modules/more/settings/browse/providers/browse_state_provider.dart';
import 'package:mangayomi/yomihub/kotatsu/kotatsu_bridge.dart';

/// Browse / enable the Kotatsu Multi Parsers sources (YomiHub 0.1.4).
class KotatsuScreen extends ConsumerStatefulWidget {
  const KotatsuScreen({super.key});

  @override
  ConsumerState<KotatsuScreen> createState() => _KotatsuScreenState();
}

class _KotatsuScreenState extends ConsumerState<KotatsuScreen> {
  List<KotatsuSource>? _all;
  String? _error;
  String _query = '';
  String _lang = '';
  bool _installedOnly = false;
  // YomiHub 0.2.0: Kotatsu's 18+ switch is the app-wide NSFW setting
  // (Cài đặt > Duyệt > Hiện nội dung NSFW), off on a fresh install.
  bool get _showNsfw => ref.watch(showNSFWStateProvider);
  final _busy = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _all = null;
      _error = null;
    });
    if (!KotatsuBridge.supported) {
      setState(() => _error = tr('Kotatsu Multi Parsers chỉ chạy trên Android và Windows.'));
      return;
    }
    try {
      final list = await KotatsuBridge.sources();
      if (!mounted) return;
      setState(() {
        _all = list;
        if (list.isEmpty) {
          _error = Platform.isWindows && YomiJvmBridge.lastError.isNotEmpty
              ? YomiJvmBridge.lastError
              : tr('Không khởi động được cầu nối Kotatsu.');
        }
      });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _toggle(KotatsuSource s, bool on) async {
    setState(() => _busy.add(s.id));
    try {
      if (on) {
        await KotatsuBridge.install(s);
      } else {
        await KotatsuBridge.uninstall(s);
      }
    } catch (e) {
      _toast('$e');
    }
    if (mounted) setState(() => _busy.remove(s.id));
  }

  Future<void> _forksDialog() async {
    final name = TextEditingController();
    final url = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) {
          final forks = KotatsuBridge.forks();
          return AlertDialog(
            title: Text(tr('Bản fork kotatsu-parsers')),
            content: SizedBox(
              width: 460,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('Dán link tệp .jar (đã qua d8/dex) của một bản fork kotatsu-parsers, ví dụ từ mục Releases trên GitHub. Nguồn của fork sẽ hiện thêm trong danh sách.'),
                      style: TextStyle(fontSize: 12),
                    ),
                    for (final f in forks)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text('${f['name']}'),
                        subtitle: Text('${f['url']}', maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await KotatsuBridge.removeFork('${f['name']}');
                            setD(() {});
                          },
                        ),
                      ),
                    TextField(
                      controller: name,
                      decoration: InputDecoration(labelText: tr('Tên (vd. shebyyy)')),
                    ),
                    TextField(
                      controller: url,
                      decoration: const InputDecoration(labelText: 'Link .jar'),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('Đóng'))),
              FilledButton(
                onPressed: () async {
                  if (url.text.trim().isEmpty) return;
                  Navigator.pop(ctx);
                  _toast(tr('Đang tải bản fork…'));
                  try {
                    final n = await KotatsuBridge.addFork(name.text, url.text);
                    _toast(tr('Đã nạp {p0} nguồn từ bản fork', {'p0': n}));
                    _load();
                  } catch (e) {
                    _toast(tr('Lỗi: {p0}', {'p0': e}));
                  }
                },
                child: Text(tr('Thêm')),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = _all ?? const <KotatsuSource>[];
    final langs = {for (final s in all) s.lang}.toList()..sort();
    final q = _query.toLowerCase();
    final shown = all.where((s) {
      if (!s.readable) return false;
      if (s.nsfw && !_showNsfw) return false;
      if (_lang.isNotEmpty && s.lang != _lang) return false;
      if (_installedOnly && !KotatsuBridge.isInstalled(s)) return false;
      return q.isEmpty || s.title.toLowerCase().contains(q) || s.id.toLowerCase().contains(q);
    }).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kotatsu Multi Parsers'),
        actions: [
          IconButton(
            tooltip: tr('Bản fork'),
            icon: const Icon(Icons.call_split),
            onPressed: _forksDialog,
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _error != null
          ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
          : _all == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: tr('Tìm nguồn'),
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      FilterChip(
                        label: Text(tr('Đã bật')),
                        selected: _installedOnly,
                        onSelected: (v) => setState(() => _installedOnly = v),
                      ),
                      const SizedBox(width: 6),
                      FilterChip(
                        label: const Text('18+'),
                        selected: _showNsfw,
                        onSelected: (v) => ref.read(showNSFWStateProvider.notifier).set(v),
                      ),
                      const SizedBox(width: 6),
                      DropdownButton<String>(
                        value: _lang,
                        underline: const SizedBox(),
                        items: [
                          DropdownMenuItem(value: '', child: Text(tr('Mọi ngôn ngữ'))),
                          for (final l in langs)
                            DropdownMenuItem(value: l, child: Text(l.isEmpty ? tr('đa ngữ') : l)),
                        ],
                        onChanged: (v) => setState(() => _lang = v ?? ''),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(tr('{p0}/{p1} nguồn', {'p0': shown.length, 'p1': all.length}), style: const TextStyle(fontSize: 12)),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: shown.length,
                    itemBuilder: (_, i) {
                      final s = shown[i];
                      final on = KotatsuBridge.isInstalled(s);
                      return SwitchListTile(
                        dense: true,
                        title: Text(s.title),
                        subtitle: Text(
                          [
                            s.lang.isEmpty ? tr('đa ngữ') : s.lang,
                            s.type,
                            s.repo,
                            if (s.broken) tr('có thể lỗi'),
                          ].join(' • '),
                        ),
                        secondary: _busy.contains(s.id)
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : null,
                        value: on,
                        onChanged: _busy.contains(s.id) ? null : (v) => _toggle(s, v),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
