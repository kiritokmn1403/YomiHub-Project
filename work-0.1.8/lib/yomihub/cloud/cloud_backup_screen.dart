import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mangayomi/modules/more/data_and_storage/providers/backup.dart';
import 'package:mangayomi/modules/more/data_and_storage/widgets/unified_restore.dart';
import 'package:mangayomi/utils/share.dart';
import 'package:mangayomi/yomihub/cloud/cloud_backup_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// YomiHub: "Sao lưu đám mây" — connect cloud targets, upload, restore.
class CloudBackupScreen extends ConsumerStatefulWidget {
  const CloudBackupScreen({super.key});

  @override
  ConsumerState<CloudBackupScreen> createState() => _CloudBackupScreenState();
}

class _CloudBackupScreenState extends ConsumerState<CloudBackupScreen> {
  final svc = CloudBackupService.instance;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    svc.load().then((_) => mounted ? setState(() => _loading = false) : null);
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<T?> _guard<T>(Future<T> Function() f) async {
    setState(() => _busy = true);
    try {
      return await f();
    } catch (e) {
      _toast('Lỗi: $e');
      return null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Full backup (every section) into a temp folder.
  Future<String> _makeBackup() async {
    final dir = await svc.tempDir();
    return writeMangayomiBackupZip(
      list: List.generate(11, (i) => i),
      directory: dir.path,
    );
  }

  Future<void> _connect(CloudProvider pr) async {
    final ctrls = {
      for (final f in pr.fields) f.key: TextEditingController(text: pr.config[f.key] ?? ''),
    };
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Kết nối ${pr.displayName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(pr.help, style: Theme.of(ctx).textTheme.bodySmall),
              const SizedBox(height: 12),
              for (final f in pr.fields)
                TextField(
                  controller: ctrls[f.key],
                  obscureText: f.secret,
                  decoration: InputDecoration(labelText: f.label, hintText: f.hint),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Tiếp tục')),
        ],
      ),
    );
    if (ok != true) return;
    for (final e in ctrls.entries) {
      pr.config[e.key] = e.value.text.trim();
    }
    await _guard(() async {
      final prompt = await pr.beginAuth();
      if (prompt == null) {
        await pr.completeAuth();
      } else if (pr.authKind == CloudAuthKind.deviceCode) {
        if (prompt.url != null) {
          launchUrl(Uri.parse(prompt.url!), mode: LaunchMode.externalApplication);
        }
        if (prompt.userCode != null) {
          Clipboard.setData(ClipboardData(text: prompt.userCode!));
        }
        if (mounted) _showDeviceCode(prompt);
        try {
          await pr.completeAuth();
        } finally {
          if (mounted) Navigator.of(context, rootNavigator: true).maybePop();
        }
      } else {
        if (prompt.url != null) {
          await launchUrl(Uri.parse(prompt.url!), mode: LaunchMode.externalApplication);
        }
        if (!mounted) return;
        final code = await _askCode(prompt.message);
        if (code == null || code.isEmpty) return;
        await pr.completeAuth(pastedCode: code);
      }
      await svc.save(pr);
      _toast('Đã kết nối ${pr.displayName}');
    });
    if (mounted) setState(() {});
  }

  void _showDeviceCode(CloudAuthPrompt prompt) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng nhập'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(prompt.message),
            const SizedBox(height: 16),
            SelectableText(prompt.userCode ?? '',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 3)),
            const SizedBox(height: 8),
            const Text('(Mã đã được chép vào bộ nhớ tạm)', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Future<String?> _askCode(String message) {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dán mã xác nhận'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(message),
          TextField(controller: c, autofocus: true),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _uploadNow() async {
    await _guard(() async {
      final path = await _makeBackup();
      final res = await svc.uploadInBackground(path, onlyAuto: false);
      if (res.isEmpty) {
        _toast('Chưa kết nối dịch vụ nào.');
      } else {
        _toast(res.map((r) => '${r.provider}: ${r.error == null ? 'OK' : 'lỗi'}').join(' • '));
      }
    });
  }

  Future<void> _shareToApps() async {
    final path = await _guard(_makeBackup);
    if (path == null) return;
    await shareOrCopy(ShareParams(
      files: [XFile(path)],
      subject: 'YomiHub backup',
      title: 'Gửi bản sao lưu YomiHub',
    ));
  }

  Future<void> _restore(CloudProvider pr) async {
    final files = await _guard(pr.list);
    if (files == null || !mounted) return;
    if (files.isEmpty) {
      _toast('Không có bản sao lưu nào trên ${pr.displayName}.');
      return;
    }
    final pick = await showModalBottomSheet<CloudFile>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(title: Text('Chọn bản sao lưu (${pr.displayName})')),
            for (final f in files)
              ListTile(
                leading: const Icon(Icons.backup_outlined),
                title: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${(f.size / 1024).toStringAsFixed(0)} KB'
                    '${f.modified == null ? '' : ' • ${f.modified!.toLocal().toString().substring(0, 16)}'}'),
                onTap: () => Navigator.pop(ctx, f),
              ),
          ],
        ),
      ),
    );
    if (pick == null) return;
    final file = await _guard(() async => pr.download(pick, await svc.tempDir()));
    if (file == null || !mounted) return;
    await performRestore(context, ref, presetPath: file.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sao lưu đám mây')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : AbsorbPointer(
              absorbing: _busy,
              child: ListView(
                children: [
                  if (_busy) const LinearProgressIndicator(),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Mỗi khi tạo bản sao lưu (thủ công hoặc tự động), YomiHub sẽ tải nó lên các dịch vụ đã kết nối. '
                      'Bản sao lưu gồm thư viện, lịch sử đọc/xem, lịch sử trình duyệt, cài đặt và tiện ích.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  for (final pr in svc.providers) _tile(pr),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.cloud_upload_outlined),
                    title: const Text('Sao lưu và tải lên ngay'),
                    subtitle: const Text('Tạo bản sao lưu đầy đủ và gửi lên mọi dịch vụ đã kết nối'),
                    onTap: _uploadNow,
                  ),
                  ListTile(
                    leading: const Icon(Icons.share_outlined),
                    title: const Text('Gửi sang ứng dụng khác'),
                    subtitle: const Text(
                        'Telegram, Zalo, TeraBox, Fshare, MediaFire, Gmail… (qua bảng chia sẻ của Android)'),
                    onTap: _shareToApps,
                  ),
                  ValueListenableBuilder(
                    valueListenable: svc.lastResults,
                    builder: (_, res, __) => res.isEmpty
                        ? const SizedBox.shrink()
                        : ListTile(
                            dense: true,
                            leading: const Icon(Icons.history),
                            title: const Text('Lần tải lên gần nhất'),
                            subtitle: Text(res
                                .map((r) => '${r.provider}: ${r.error == null ? 'thành công' : 'lỗi – ${r.error}'}')
                                .join('\n')),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _tile(CloudProvider pr) {
    final connected = pr.isConnected;
    return ExpansionTile(
      leading: Icon(connected ? Icons.cloud_done : Icons.cloud_off_outlined,
          color: connected ? Colors.green : null),
      title: Text(pr.displayName),
      subtitle: Text(connected ? 'Đã kết nối' : 'Chưa kết nối'),
      children: [
        if (!connected)
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('Kết nối'),
            onTap: () => _connect(pr),
          ),
        if (connected) ...[
          SwitchListTile(
            secondary: const Icon(Icons.autorenew),
            title: const Text('Tự động tải lên khi sao lưu'),
            value: svc.autoUpload(pr),
            onChanged: (v) async {
              await svc.setAutoUpload(pr, v);
              setState(() {});
            },
          ),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Tải bản sao lưu mới lên'),
            onTap: () => _guard(() async {
              final path = await _makeBackup();
              await pr.upload(File(path));
              _toast('Đã tải lên ${pr.displayName}');
            }),
          ),
          if (pr.canRestore)
            ListTile(
              leading: const Icon(Icons.settings_backup_restore),
              title: const Text('Khôi phục từ đám mây'),
              onTap: () => _restore(pr),
            ),
          ListTile(
            leading: const Icon(Icons.link_off),
            title: const Text('Ngắt kết nối'),
            onTap: () async {
              await svc.disconnect(pr);
              setState(() {});
            },
          ),
        ],
      ],
    );
  }
}
