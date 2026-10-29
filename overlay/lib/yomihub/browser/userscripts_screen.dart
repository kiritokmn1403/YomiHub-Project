import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mangayomi/yomihub/browser/adblock.dart';

/// Tampermonkey AdBlock site configs + user scripts (YomiHub 0.1.4).
class UserScriptsScreen extends StatefulWidget {
  const UserScriptsScreen({super.key});

  @override
  State<UserScriptsScreen> createState() => _UserScriptsScreenState();
}

class _UserScriptsScreenState extends State<UserScriptsScreen> {
  Future<void> _save() async {
    await YomiAdBlock.save();
    if (mounted) setState(() {});
  }

  Future<void> _editSite(String? key) async {
    final domain = TextEditingController(text: key ?? '');
    final cfg = key == null
        ? <String, dynamic>{'remove': <String>[], 'click': <String>[], 'interval': 4000}
        : Map<String, dynamic>.from(YomiAdBlock.tmSites[key] as Map);
    final remove = TextEditingController(
      text: ((cfg['remove'] as List?) ?? const []).join('\n'),
    );
    final click = TextEditingController(
      text: ((cfg['click'] as List?) ?? const []).join('\n'),
    );
    final timeout = TextEditingController(text: '${cfg['timeout'] ?? 0}');
    final interval = TextEditingController(text: '${cfg['interval'] ?? 0}');
    final background = TextEditingController(text: '${cfg['background'] ?? ''}');
    var interaction = cfg['interaction'] == true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(key == null ? tr('Thêm trang') : tr('Cấu hình {p0}', {'p0': key})),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: domain,
                    enabled: key == null,
                    decoration: InputDecoration(
                      labelText: tr('Tên miền (vd. www.a-website.com, * = mọi trang)'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: remove,
                    minLines: 3,
                    maxLines: 8,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    decoration: InputDecoration(
                      labelText: tr('remove – ẩn phần tử (mỗi dòng một CSS selector)'),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: click,
                    minLines: 2,
                    maxLines: 6,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    decoration: InputDecoration(
                      labelText: tr('click – bấm tự động (nút đóng, cookie…)'),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(tr('interaction – giả lập di chuột')),
                    value: interaction,
                    onChanged: (v) => setD(() => interaction = v),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: timeout,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'timeout (ms)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: interval,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'interval (ms)'),
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: background,
                    decoration: InputDecoration(
                      labelText: tr('background (vd. #ffffff, để trống nếu không cần)'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            if (key != null)
              TextButton(
                onPressed: () {
                  YomiAdBlock.tmSites.remove(key);
                  Navigator.pop(ctx, true);
                },
                child: Text(tr('Xoá'), style: TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('Huỷ')),
            ),
            FilledButton(
              onPressed: () {
                final d = domain.text.trim().toLowerCase();
                if (d.isEmpty) return;
                List<String> lines(TextEditingController c) => c.text
                    .split('\n')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();
                YomiAdBlock.tmSites[d] = {
                  'remove': lines(remove),
                  'click': lines(click),
                  'interaction': interaction,
                  'timeout': int.tryParse(timeout.text.trim()) ?? 0,
                  'interval': int.tryParse(interval.text.trim()) ?? 0,
                  if (background.text.trim().isNotEmpty)
                    'background': background.text.trim(),
                };
                Navigator.pop(ctx, true);
              },
              child: Text(tr('Lưu')),
            ),
          ],
        ),
      ),
    );
    if (ok == true) await _save();
  }

  Future<void> _editScript(int? index) async {
    final code = TextEditingController(
      text: index == null
          ? tr("// ==UserScript==\n// @name         Script mới\n// @match        https://*/*\n// ==/UserScript==\n\n(function() {\n  \'use strict\';\n\n})();\n")
          : '${YomiAdBlock.userScripts[index]['code']}',
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(index == null ? tr('Thêm userscript') : tr('Sửa userscript')),
        content: SizedBox(
          width: 520,
          child: TextField(
            controller: code,
            minLines: 12,
            maxLines: 24,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('Huỷ')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('Lưu')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final parsed = YomiAdBlock.parseUserScript(code.text);
    if (index == null) {
      YomiAdBlock.userScripts.add(parsed);
    } else {
      parsed['enabled'] = YomiAdBlock.userScripts[index]['enabled'] ?? true;
      YomiAdBlock.userScripts[index] = parsed;
    }
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    final sites = YomiAdBlock.tmSites.keys.toList()..sort();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tampermonkey AdBlock'),
        actions: [
          PopupMenuButton<int>(
            itemBuilder: (_) => [
              PopupMenuItem(value: 0, child: Text(tr('Khôi phục cấu hình mặc định'))),
              PopupMenuItem(value: 1, child: Text(tr('Chép cấu hình (JSON)'))),
            ],
            onSelected: (v) async {
              if (v == 0) {
                YomiAdBlock.tmSites = Map.of(YomiAdBlock.tmDefaultSites);
                await _save();
              } else {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    content: SelectableText(
                      const JsonEncoder.withIndent('  ').convert(YomiAdBlock.tmSites),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text(tr('Bật Tampermonkey AdBlock')),
            subtitle: Text(
              tr('Ẩn quảng cáo theo cấu hình từng trang mà không chặn request, nên không làm trang phát hiện trình chặn quảng cáo.'),
            ),
            value: YomiAdBlock.tampermonkey,
            onChanged: (v) async {
              YomiAdBlock.tampermonkey = v;
              await _save();
            },
          ),
          const Divider(),
          ListTile(
            title: Text(tr('Cấu hình theo trang')),
            trailing: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _editSite(null),
            ),
          ),
          for (final k in sites)
            ListTile(
              dense: true,
              leading: Icon(k == '*' ? Icons.public : Icons.language),
              title: Text(k == '*' ? tr('* (mọi trang)') : k),
              subtitle: Text(
                tr('{p0} ẩn • {p1} bấm • lặp {p2} ms', {'p0': ((YomiAdBlock.tmSites[k] as Map)['remove'] as List?)?.length ?? 0, 'p1': ((YomiAdBlock.tmSites[k] as Map)['click'] as List?)?.length ?? 0, 'p2': (YomiAdBlock.tmSites[k] as Map)['interval'] ?? 0}),
              ),
              onTap: () => _editSite(k),
            ),
          const Divider(),
          ListTile(
            title: Text(tr('Userscript (kiểu Tampermonkey)')),
            subtitle: Text(tr('Chạy trong trình duyệt YomiHub theo @match')),
            trailing: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _editScript(null),
            ),
          ),
          for (var i = 0; i < YomiAdBlock.userScripts.length; i++)
            SwitchListTile(
              title: Text('${YomiAdBlock.userScripts[i]['name']}'),
              subtitle: Text(
                ((YomiAdBlock.userScripts[i]['match'] as List?) ?? const []).join(', '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              value: YomiAdBlock.userScripts[i]['enabled'] != false,
              onChanged: (v) async {
                YomiAdBlock.userScripts[i]['enabled'] = v;
                await _save();
              },
              secondary: PopupMenuButton<int>(
                itemBuilder: (_) => [
                  PopupMenuItem(value: 0, child: Text(tr('Sửa'))),
                  PopupMenuItem(value: 1, child: Text(tr('Xoá'))),
                ],
                onSelected: (v) async {
                  if (v == 0) {
                    await _editScript(i);
                  } else {
                    YomiAdBlock.userScripts.removeAt(i);
                    await _save();
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}
