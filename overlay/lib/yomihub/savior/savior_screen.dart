import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mangayomi/yomihub/savior/savior.dart';
import 'package:share_plus/share_plus.dart';

/// Savior downloads list (Tải xuống › Savior).
class SaviorScreen extends StatefulWidget {
  const SaviorScreen({super.key});

  @override
  State<SaviorScreen> createState() => _SaviorScreenState();
}

class _SaviorScreenState extends State<SaviorScreen> {
  final s = Savior.instance;

  @override
  void initState() {
    super.initState();
    s.addListener(_r);
    s.init().then((_) => _r());
  }

  @override
  void dispose() {
    s.removeListener(_r);
    super.dispose();
  }

  void _r() {
    if (mounted) setState(() {});
  }

  String _size(int b) => b > 1 << 30
      ? '${(b / (1 << 30)).toStringAsFixed(2)} GB'
      : b > 1 << 20
      ? '${(b / (1 << 20)).toStringAsFixed(1)} MB'
      : '${(b / 1024).toStringAsFixed(0)} KB';

  Future<void> _addLink() async {
    final url = TextEditingController();
    final name = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Tải bằng link')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: url,
              decoration: InputDecoration(labelText: tr('Link video / âm thanh / m3u8')),
            ),
            TextField(
              controller: name,
              decoration: InputDecoration(labelText: tr('Tên tệp (không bắt buộc)')),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Huỷ'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Tải'))),
        ],
      ),
    );
    if (ok != true || url.text.trim().isEmpty) return;
    final u = url.text.trim();
    final m = SaviorMedia.classify(u, '') ??
        SaviorMedia(u, '', u.contains('.m3u8') ? SaviorKind.hls : SaviorKind.file, '');
    s.add(
      url: u,
      title: name.text.trim().isEmpty
          ? Uri.tryParse(u)?.pathSegments.lastOrNull?.split('.').first ?? 'savior'
          : name.text.trim(),
      kind: m.kind,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Savior – tải video từ trang web')),
        actions: [
          IconButton(
            tooltip: tr('Tải bằng link'),
            icon: const Icon(Icons.add_link),
            onPressed: _addLink,
          ),
        ],
      ),
      body: s.tasks.isEmpty
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  tr('Mở trang có video/nhạc trong Trình duyệt của YomiHub, nút Savior (biểu tượng tải xuống) sẽ hiện khi trang có tệp tải được. Hoặc bấm + để dán link.'),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              itemCount: s.tasks.length,
              itemBuilder: (_, i) {
                final t = s.tasks[i];
                final pr = t.progress;
                final sub = switch (t.status) {
                  'queued' => tr('Đang chờ'),
                  'running' => t.kind == SaviorKind.hls
                      ? tr('Đoạn {p0}/{p1} • {p2}', {'p0': t.segDone, 'p1': t.total, 'p2': _size(t.received)})
                      : '${_size(t.received)}${t.total > 0 ? ' / ${_size(t.total)}' : ''}',
                  'done' => 'Xong • ${_size(t.received)}\n${t.path ?? ''}',
                  'cancelled' => tr('Đã huỷ'),
                  _ => tr('Lỗi: {p0}', {'p0': t.error ?? ''}),
                };
                return ListTile(
                  leading: Icon(
                    t.status == 'done'
                        ? Icons.check_circle
                        : t.status == 'error'
                        ? Icons.error_outline
                        : t.kind == SaviorKind.hls
                        ? Icons.stream
                        : Icons.movie_outlined,
                    color: t.status == 'done'
                        ? Colors.green
                        : t.status == 'error'
                        ? Colors.red
                        : null,
                  ),
                  title: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (t.status == 'running')
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: LinearProgressIndicator(value: pr),
                        ),
                      Text(sub, maxLines: 3, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                  trailing: PopupMenuButton<int>(
                    itemBuilder: (_) => [
                      if (t.status == 'running' || t.status == 'queued')
                        PopupMenuItem(value: 0, child: Text(tr('Huỷ'))),
                      if (t.status == 'error' || t.status == 'cancelled')
                        PopupMenuItem(value: 1, child: Text(tr('Thử lại / tải tiếp'))),
                      if (t.status == 'done')
                        PopupMenuItem(value: 2, child: Text(tr('Chia sẻ / mở bằng app khác'))),
                      PopupMenuItem(value: 3, child: Text(tr('Sao chép link gốc'))),
                      PopupMenuItem(value: 4, child: Text(tr('Xoá khỏi danh sách'))),
                      if (t.path != null)
                        PopupMenuItem(value: 5, child: Text(tr('Xoá cả tệp'))),
                    ],
                    onSelected: (v) {
                      switch (v) {
                        case 0:
                          s.cancel(t);
                        case 1:
                          s.retry(t);
                        case 2:
                          SharePlus.instance.share(ShareParams(files: [XFile(t.path!)]));
                        case 3:
                          Clipboard.setData(ClipboardData(text: t.url));
                        case 4:
                          s.remove(t);
                        case 5:
                          s.remove(t, deleteFile: true);
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
