// YomiHub 0.5.3 (sheet "YomiHub Update" mục 9 – Windows, AMD Ryzen 9: "không
// có đầy đủ tính năng"). 0.5.2 wrote the Windows diagnostics only to the app
// log; this screen shows them in Settings and runs them again on demand, so
// the user of any PC (Ryzen or not) sees which component is missing and which
// feature it switches off, without reading logs.txt.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:mangayomi/yomihub/win/win_diag.dart';
import 'package:mangayomi/yomihub/win/win_render.dart';
import 'package:path/path.dart' as p;

class WinDiagScreen extends StatefulWidget {
  const WinDiagScreen({super.key});

  @override
  State<WinDiagScreen> createState() => _WinDiagScreenState();
}

class _WinDiagScreenState extends State<WinDiagScreen> {
  bool _busy = false;
  // 0.5.7 (R21): render mode read by the native runner at the next start.
  WinRenderConfig _render = WinRender.readConfig();

  void _setRender(WinRenderConfig cfg) {
    if (WinRender.writeConfig(cfg)) setState(() => _render = cfg);
  }

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
              leading: const Icon(Icons.monitor),
              title: Text(tr('Chế độ GPU (khi cửa sổ trắng)')),
              subtitle: Text(
                '${tr('Có hiệu lực từ lần mở YomiHub kế tiếp.')}'
                '${WinRender.describe(WinRender.readState()).isEmpty ? '' : '\n${WinRender.describe(WinRender.readState())}'}',
              ),
              trailing: DropdownButton<String>(
                value: _render.mode,
                onChanged: (v) {
                  if (v != null) _setRender(_render.copyWith(mode: v));
                },
                items: [
                  DropdownMenuItem(value: 'auto', child: Text(tr('Tự động'))),
                  DropdownMenuItem(value: 'igpu', child: Text(tr('GPU tích hợp'))),
                  DropdownMenuItem(value: 'dgpu', child: Text(tr('GPU rời'))),
                ],
              ),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.restart_alt),
              title: Text(tr('Tự mở lại bằng chế độ khác khi cửa sổ chỉ một màu')),
              value: _render.autoRecover,
              onChanged: (v) => _setRender(_render.copyWith(autoRecover: v)),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.brush_outlined),
              title: const Text('Impeller'),
              value: _render.impeller,
              onChanged: (v) => _setRender(_render.copyWith(impeller: v)),
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
              title: Text(tr('Gói Setup.exe và portable .zip đã có sẵn VC++ runtime, Java và M-Extension-Server. Nếu thiếu thành phần, hãy cài lại bằng Setup.exe của bản mới nhất.')),
            ),
          ],
        ),
      ),
    );
  }
}
