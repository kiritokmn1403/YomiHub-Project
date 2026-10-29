import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mangayomi/utils/log/logger.dart';

/// YomiHub 0.1.8: "Nhật ký ứng dụng" - the application log (logs.txt) inside
/// the app. Every error report is written here, on Android and Windows.
class AppLogScreen extends StatefulWidget {
  const AppLogScreen({super.key});
  @override
  State<AppLogScreen> createState() => _AppLogScreenState();
}

class _AppLogScreenState extends State<AppLogScreen> {
  List<String> _lines = [];
  bool _errorsOnly = false;
  String _q = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await AppLogger.flush();
    final f = await AppLogger.logFile();
    var text = '';
    if (f != null && await f.exists()) {
      final old = File('${f.path}.old');
      if (await old.exists()) text = await old.readAsString();
      text += await f.readAsString();
    }
    // one entry per "[date][LEVEL]" header, continuation lines kept with it
    final entries = <String>[];
    for (final l in text.split('\n')) {
      if (l.startsWith('[') && l.contains('][') || entries.isEmpty) {
        entries.add(l);
      } else if (l.trim().isNotEmpty) {
        entries[entries.length - 1] += '\n$l';
      }
    }
    if (!mounted) return;
    setState(() {
      _lines = entries.reversed.where((e) => e.trim().isNotEmpty).toList();
      _loading = false;
    });
  }

  Color? _color(String e, BuildContext c) {
    if (e.contains('[ERROR]')) return Colors.redAccent;
    if (e.contains('[WARNING]')) return Colors.orange;
    return Theme.of(c).textTheme.bodySmall?.color;
  }

  @override
  Widget build(BuildContext context) {
    final shown = _lines.where((e) {
      if (_errorsOnly && !e.contains('[ERROR]') && !e.contains('[WARNING]')) {
        return false;
      }
      return _q.isEmpty || e.toLowerCase().contains(_q.toLowerCase());
    }).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Nhật ký ứng dụng')),
        actions: [
          IconButton(
            tooltip: tr('Sao chép'),
            icon: const Icon(Icons.copy_all_outlined),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: shown.join('\n')));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(tr('Đã sao chép nhật ký'))),
              );
            },
          ),
          IconButton(
            tooltip: tr('Làm mới'),
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
          IconButton(
            tooltip: tr('Xoá nhật ký'),
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () async {
              await AppLogger.clear();
              await _load();
            },
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        isDense: true,
                        prefixIcon: Icon(Icons.search),
                        hintText: tr('Tìm trong nhật ký'),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) => setState(() => _q = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text(tr('Chỉ lỗi')),
                    selected: _errorsOnly,
                    onSelected: (v) => setState(() => _errorsOnly = v),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : shown.isEmpty
                  ? Center(child: Text(tr('Chưa có mục nào')))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: shown.length,
                      separatorBuilder: (_, _) => const Divider(height: 12),
                      itemBuilder: (c, i) => SelectableText(
                        shown[i],
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11.5,
                          color: _color(shown[i], c),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
