// YomiHub 0.5.3 (sheet "YomiHub Update" mục 9 – Windows, AMD Ryzen 9: "không
// có đầy đủ tính năng"). 0.5.2 wrote the Windows diagnostics only to the app
// log; this screen shows them in Settings and runs them again on demand, so
// the user of any PC (Ryzen or not) sees which component is missing and which
// feature it switches off, without reading logs.txt.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:mangayomi/yomihub/win/win_diag.dart';
import 'package:path/path.dart' as p;

class WinDiagScreen extends StatefulWidget {
  const WinDiagScreen({super.key});

  @override
  State<WinDiagScreen> createState() => _WinDiagScreenState();
}

class _WinDiagScreenState extends State<WinDiagScreen> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (WinDiag.summary.isEmpty) _run();
  }

  Future<void> _run() async {
    setState(() => _busy = true);
    await WinDiag.runOnce(force: true);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final problems = WinDiag.problems;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Chẩn đoán Windows')),
        actions: [
          IconButton(
            tooltip: tr('Kiểm tra lại'),
            onPressed: _busy ? null : _run,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          children: [
            if (_busy) const LinearProgressIndicator(),
            ListTile(
              leading: const Icon(Icons.computer),
              title: Text(tr('Máy tính này')),
              subtitle: SelectableText(WinDiag.summary.isEmpty ? '…' : WinDiag.summary),
            ),
            const Divider(),
            if (!_busy && problems.isEmpty)
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text(tr('Đủ thành phần – mọi tính năng đều có thể chạy')),
              ),
            for (final m in problems)
              ListTile(
                leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                title: Text(m),
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: Text(tr('Mở thư mục cài đặt')),
              subtitle: Text(p.dirname(Platform.resolvedExecutable)),
              onTap: () => Process.run('explorer.exe', [p.dirname(Platform.resolvedExecutable)]),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(tr('Gói Setup.exe và portable -full.zip đã có sẵn VC++ runtime, Java và M-Extension-Server. Nếu thiếu thành phần, hãy cài lại bằng Setup.exe của bản mới nhất.')),
            ),
          ],
        ),
      ),
    );
  }
}
