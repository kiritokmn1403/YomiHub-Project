import 'dart:isolate';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mangayomi/yomihub/apk/apk_inspector.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';

/// YomiHub 0.5.1: Cài đặt › Duyệt › "Kiểm tra tệp APK tiện ích".
/// Reads a Mihon / Aniyomi / IReader extension APK (package, version,
/// extension classes, NSFW, lib version, manifest, source classes) without
/// installing it. Parsing runs in a background isolate.
/// Top-level: the isolate closure must capture only [bytes] (a closure made
/// inside a State method captures the widget tree and cannot be sent).
Future<ApkInfo> inspectApkInBackground(String path) =>
    Isolate.run(() => ApkInspector.inspectFile(path)).timeout(const Duration(minutes: 3));

class ApkInspectorScreen extends StatefulWidget {
  const ApkInspectorScreen({super.key});
  @override
  State<ApkInspectorScreen> createState() => _ApkInspectorScreenState();
}

class _ApkInspectorScreenState extends State<ApkInspectorScreen> {
  ApkInfo? _info;
  String? _file;
  String? _error;
  bool _busy = false;

  Future<void> _pick() async {
    final files = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['apk']);
    final f = files.isEmpty ? null : files.first;
    if (f == null || f.path == null) return;
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
      _file = f.name;
    });
    try {
      final info = await inspectApkInBackground(f.path!);
      if (mounted) setState(() => _info = info);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _row(String k, String v) => ListTile(
        dense: true,
        title: Text(k),
        subtitle: SelectableText(v.isEmpty ? '—' : v),
      );

  @override
  Widget build(BuildContext context) {
    final i = _info;
    return Scaffold(
      appBar: AppBar(title: Text(tr('Kiểm tra tệp APK tiện ích'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : _pick,
        icon: const Icon(Icons.file_open_outlined),
        label: Text(tr('Chọn tệp APK')),
      ),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(tr('Đọc AndroidManifest.xml và classes.dex của tiện ích Mihon / Aniyomi / IReader mà không cần cài. Dựa trên dự án "Decode & Extract".')),
                ),
                if (_error != null)
                  ListTile(leading: const Icon(Icons.error_outline, color: Colors.red), title: Text(_error!)),
                if (i != null) ...[
                  _row(tr('Tệp'), _file ?? ''),
                  _row(tr('Loại'), tr(i.kind)),
                  _row(tr('Gói'), i.package),
                  _row(tr('Phiên bản'), '${i.versionName} (${i.versionCode})'),
                  if (i.libVersion != null) _row(tr('Phiên bản thư viện tiện ích'), i.libVersion!),
                  if (i.nsfw != null) _row('NSFW (18+)', i.nsfw! ? tr('Có') : tr('Không')),
                  _row('minSdk / targetSdk', '${i.minSdk} / ${i.targetSdk}'),
                  _row(tr('Lớp tiện ích'), i.extensionClasses.join('\n')),
                  _row('classes*.dex', '${i.dexFiles} • ${i.classCount} ${tr('lớp')}'),
                  for (final w in i.warnings)
                    ListTile(dense: true, leading: const Icon(Icons.warning_amber, color: Colors.orange), title: Text(w)),
                  ExpansionTile(
                    title: Text('${tr('Lớp nguồn')} (${i.sourceClasses.length})'),
                    children: [
                      for (final c in i.sourceClasses)
                        ExpansionTile(
                          title: Text(c.simpleName),
                          subtitle: Text(c.superclass ?? ''),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: SelectableText(c.outline(), style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                            ),
                          ],
                        ),
                    ],
                  ),
                  ExpansionTile(
                    title: Text('<meta-data> (${i.metaData.length})'),
                    children: [for (final e in i.metaData.entries) _row(e.key, e.value)],
                  ),
                  ExpansionTile(
                    title: const Text('AndroidManifest.xml'),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () => Clipboard.setData(ClipboardData(text: i.manifestXml)),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: SelectableText(i.manifestXml, style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}
