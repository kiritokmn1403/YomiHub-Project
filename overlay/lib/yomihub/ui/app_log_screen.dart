import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mangayomi/utils/log/logger.dart';

/// YomiHub 0.1.8: "Nhật ký ứng dụng" - the application log (logs.txt) inside
/// the app. Every error report is written here, on Android and Windows.
/// 0.5.1: top-level so the isolate closure captures only [paths] (a closure
/// made inside the State method also captured the widget tree: "object is
/// unsendable – _AsyncCompleter", seen on the Note 9).
Future<List<String>> parseAppLogInBackground(List<String> paths) =>
    Isolate.run(() => _AppLogScreenState.parseLog(paths));

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
    var lines = <String>[];
    // 0.5.1: the screen spun for minutes on the Note 9: every continuation
    // line was appended with `entries[last] += line` (quadratic on long
    // stack traces / big logs) on the UI isolate, and any exception left
    // `_loading` true forever. Now: bounded waits, parsing in a background
    // isolate with linear joins, newest 3000 entries, spinner always ends.
    try {
      await AppLogger.flush();
      final f = await AppLogger.logFile().timeout(const Duration(seconds: 5));
      final paths = <String>[if (f != null) '${f.path}.old', if (f != null) f.path];
      lines = await parseAppLogInBackground(paths).timeout(const Duration(seconds: 20));
    } catch (e) {
      lines = ['[${DateTime.now()}][WARNING] Không đọc được nhật ký: $e'];
    } finally {
      if (mounted) {
        setState(() {
          _lines = lines;
          _loading = false;
        });
      }
    }
  }

  /// Newest-first entries ("[date][LEVEL]" header + its continuation lines).
  static List<String> parseLog(List<String> paths) {
    final text = StringBuffer();
    for (final p in paths) {
      try {
        final file = File(p);
        if (file.existsSync()) text.write(file.readAsStringSync());
      } catch (_) {}
    }
    final entries = <String>[];
    StringBuffer? cur;
    for (final l in text.toString().split('\n')) {
      if ((l.startsWith('[') && l.contains('][')) || cur == null) {
        if (cur != null && cur.toString().trim().isNotEmpty) entries.add(cur.toString());
        cur = StringBuffer(l);
      } else if (l.trim().isNotEmpty) {
        cur..write('\n')..write(l);
      }
    }
    if (cur != null && cur.toString().trim().isNotEmpty) entries.add(cur.toString());
    final newest = entries.reversed.take(3000).toList();
    return newest;
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
