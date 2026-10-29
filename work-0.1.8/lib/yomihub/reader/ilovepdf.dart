import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// iLovePDF REST API client (https://www.iloveapi.com, API v1).
///
/// Flow: auth (public key → JWT) → start/{tool} → upload → process → download.
/// The user supplies their own project public key (free plan available).
class ILovePdf {
  ILovePdf._();
  static const _api = 'https://api.ilovepdf.com/v1';
  static const keyPref = 'ilovepdfPublicKey';
  static String? _token;
  static DateTime? _tokenAt;

  static String get publicKey => YomiPrefs.get<String>(keyPref, '');
  static bool get configured => publicKey.trim().isNotEmpty;

  static Future<String> _auth() async {
    if (_token != null && _tokenAt != null && DateTime.now().difference(_tokenAt!) < const Duration(minutes: 90)) {
      return _token!;
    }
    final r = await http.post(
      Uri.parse('$_api/auth'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'public_key': publicKey.trim()}),
    );
    if (r.statusCode != 200) throw Exception('iLovePDF: xác thực thất bại (${r.statusCode}) – kiểm tra Public key');
    _token = (jsonDecode(r.body) as Map)['token'] as String;
    _tokenAt = DateTime.now();
    return _token!;
  }

  static String _err(http.BaseResponse r, String body) {
    try {
      final j = jsonDecode(body);
      final e = j is Map ? (j['error'] ?? j) : j;
      if (e is Map) return '${e['message'] ?? ''} ${e['param'] ?? ''}'.trim();
      return '$e';
    } catch (_) {
      return 'HTTP ${r.statusCode}';
    }
  }

  /// Runs [tool] on [files] and writes the result to [outDir].
  /// Returns the output file (a .pdf, or a .zip when the tool yields several files).
  static Future<File> run({
    required String tool,
    required List<File> files,
    required Directory outDir,
    Map<String, dynamic> params = const {},
    Map<String, dynamic> fileParams = const {},
    void Function(String step)? onStep,
  }) async {
    final token = await _auth();
    final auth = {'Authorization': 'Bearer $token'};
    onStep?.call('Khởi tạo tác vụ…');
    var r = await http.get(Uri.parse('$_api/start/$tool'), headers: auth);
    if (r.statusCode != 200) throw Exception('iLovePDF start: ${_err(r, r.body)}');
    final start = jsonDecode(r.body) as Map;
    final server = 'https://${start['server']}/v1';
    final task = '${start['task']}';
    final uploaded = <Map<String, dynamic>>[];
    for (var i = 0; i < files.length; i++) {
      onStep?.call('Tải lên ${i + 1}/${files.length}…');
      final req = http.MultipartRequest('POST', Uri.parse('$server/upload'))
        ..headers.addAll(auth)
        ..fields['task'] = task
        ..files.add(await http.MultipartFile.fromPath('file', files[i].path));
      final sr = await req.send();
      final body = await sr.stream.bytesToString();
      if (sr.statusCode != 200) throw Exception('iLovePDF upload: ${_err(sr, body)}');
      uploaded.add({
        'server_filename': (jsonDecode(body) as Map)['server_filename'],
        'filename': p.basename(files[i].path),
        ...fileParams,
      });
    }
    onStep?.call('Đang xử lý…');
    r = await http.post(
      Uri.parse('$server/process'),
      headers: {...auth, 'Content-Type': 'application/json'},
      body: jsonEncode({'task': task, 'tool': tool, 'files': uploaded, ...params}),
    );
    if (r.statusCode != 200) throw Exception('iLovePDF process: ${_err(r, r.body)}');
    final proc = jsonDecode(r.body) as Map;
    onStep?.call('Tải kết quả…');
    final d = await http.get(Uri.parse('$server/download/$task'), headers: auth);
    if (d.statusCode != 200) throw Exception('iLovePDF download: HTTP ${d.statusCode}');
    var name = '${proc['download_filename'] ?? ''}';
    if (name.isEmpty) {
      final cd = d.headers['content-disposition'] ?? '';
      name = RegExp(r'filename="?([^";]+)').firstMatch(cd)?.group(1) ?? '${tool}_$task.pdf';
    }
    final base = p.basenameWithoutExtension(files.first.path);
    final ext = p.extension(name).isEmpty ? '.pdf' : p.extension(name);
    var out = File(p.join(outDir.path, '${base}_$tool$ext'));
    var n = 1;
    while (await out.exists()) {
      out = File(p.join(outDir.path, '${base}_$tool($n)$ext'));
      n++;
    }
    await out.writeAsBytes(d.bodyBytes);
    return out;
  }

  /// A writable folder next to [source] when possible, else app documents.
  static Future<Directory> outputDirFor(String source) async {
    final dir = Directory(p.dirname(source));
    try {
      final probe = File(p.join(dir.path, '.yh_write_test'));
      await probe.writeAsString('1');
      await probe.delete();
      return dir;
    } catch (_) {
      final d = Directory(p.join((await getApplicationDocumentsDirectory()).path, 'YomiHub PDF'));
      await d.create(recursive: true);
      return d;
    }
  }
}

class _Tool {
  final String id;
  final String label;
  final IconData icon;
  const _Tool(this.id, this.label, this.icon);
}

const _tools = <_Tool>[
  _Tool('compress', 'Nén PDF', Icons.compress),
  _Tool('merge', 'Ghép với PDF khác', Icons.merge_type),
  _Tool('split', 'Tách trang', Icons.call_split),
  _Tool('rotate', 'Xoay trang', Icons.rotate_right),
  _Tool('pdfocr', 'OCR (nhận dạng chữ)', Icons.document_scanner_outlined),
  _Tool('pdfjpg', 'PDF → JPG', Icons.image_outlined),
  _Tool('pagenumbers', 'Đánh số trang', Icons.format_list_numbered),
  _Tool('watermark', 'Chèn watermark chữ', Icons.water_drop_outlined),
  _Tool('repair', 'Sửa PDF lỗi', Icons.build_outlined),
  _Tool('pdfa', 'Chuyển sang PDF/A', Icons.archive_outlined),
];

/// Bottom sheet with the iLovePDF tools for one PDF file.
class ILovePdfSheet {
  static Future<void> show(BuildContext context, String path, {void Function(File out)? onOpen}) async {
    final tool = await showModalBottomSheet<_Tool>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              leading: const Icon(Icons.key_outlined),
              title: const Text('iLovePDF – Public key'),
              subtitle: Text(ILovePdf.configured ? 'Đã thiết lập' : 'Chưa thiết lập (miễn phí tại iloveapi.com)'),
              onTap: () => Navigator.pop(ctx, const _Tool('_key', '', Icons.key)),
            ),
            const Divider(height: 1),
            for (final t in _tools)
              ListTile(
                leading: Icon(t.icon),
                title: Text(t.label),
                enabled: ILovePdf.configured,
                onTap: () => Navigator.pop(ctx, t),
              ),
          ],
        ),
      ),
    );
    if (tool == null || !context.mounted) return;
    if (tool.id == '_key') {
      await _keyDialog(context);
      if (context.mounted && ILovePdf.configured) return show(context, path, onOpen: onOpen);
      return;
    }
    final files = [File(path)];
    Map<String, dynamic> params = {};
    Map<String, dynamic> fileParams = {};
    switch (tool.id) {
      case 'compress':
        final lvl = await _choose(context, 'Mức nén', {'low': 'Nhẹ', 'recommended': 'Khuyên dùng', 'extreme': 'Tối đa'});
        if (lvl == null) return;
        params = {'compression_level': lvl};
      case 'merge':
        final List<PlatformFile> picked = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
        files.addAll(picked.where((f) => f.path != null).map((f) => File(f.path!)));
        if (files.length < 2) return;
      case 'split':
        final ranges = await _ask(context, 'Khoảng trang (vd. 1-3,5,8-10)');
        if (ranges == null || ranges.isEmpty) return;
        params = {'split_mode': 'ranges', 'ranges': ranges, 'merge_after': false};
      case 'rotate':
        final deg = await _choose(context, 'Xoay', {'90': '90° phải', '180': '180°', '270': '90° trái'});
        if (deg == null) return;
        fileParams = {'rotate': int.parse(deg)};
      case 'pdfocr':
        final lang = await _choose(context, 'Ngôn ngữ', {'vie': 'Tiếng Việt', 'eng': 'English', 'jpn': '日本語', 'chi_sim': '中文 (giản thể)', 'kor': '한국어'});
        if (lang == null) return;
        params = {'ocr_languages': [lang]};
      case 'pdfjpg':
        params = {'pdfjpg_mode': 'pages'};
      case 'pagenumbers':
        params = {'vertical_position': 'bottom', 'horizontal_position': 'center', 'starting_number': 1};
      case 'watermark':
        final text = await _ask(context, 'Chữ watermark');
        if (text == null || text.isEmpty) return;
        params = {'mode': 'text', 'text': text, 'transparency': 50, 'rotation': 45};
      case 'pdfa':
        params = {'conformance': 'pdfa-2b'};
    }
    if (!context.mounted) return;
    final step = ValueNotifier<String>('Bắt đầu…');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: ValueListenableBuilder<String>(valueListenable: step, builder: (_, v, __) => Text(v))),
          ],
        ),
      ),
    );
    try {
      final out = await ILovePdf.run(
        tool: tool.id,
        files: files,
        outDir: await ILovePdf.outputDirFor(path),
        params: params,
        fileParams: fileParams,
        onStep: (s) => step.value = s,
      );
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      final isPdf = out.path.toLowerCase().endsWith('.pdf');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã lưu: ${p.basename(out.path)}'),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'Mở',
            onPressed: () => isPdf && onOpen != null ? onOpen(out) : launchUrl(Uri.file(out.path)),
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  static Future<void> _keyDialog(BuildContext context) async {
    final c = TextEditingController(text: ILovePdf.publicKey);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('iLovePDF Public key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tạo dự án miễn phí tại iloveapi.com (Developer) rồi dán "Public key" '
              'của dự án vào đây. Tệp PDF được gửi lên máy chủ iLovePDF để xử lý.',
              style: TextStyle(fontSize: 12),
            ),
            TextField(controller: c, decoration: const InputDecoration(labelText: 'project_public_…')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => launchUrl(Uri.parse('https://www.iloveapi.com/signup'), mode: LaunchMode.externalApplication),
            child: const Text('Đăng ký'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lưu')),
        ],
      ),
    );
    if (ok == true) await YomiPrefs.set(ILovePdf.keyPref, c.text.trim());
  }

  static Future<String?> _ask(BuildContext context, String label) async {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(label),
        content: TextField(controller: c, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('OK')),
        ],
      ),
    );
  }

  static Future<String?> _choose(BuildContext context, String title, Map<String, String> opts) =>
      showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: Text(title),
          children: [
            for (final e in opts.entries)
              SimpleDialogOption(onPressed: () => Navigator.pop(ctx, e.key), child: Text(e.value)),
          ],
        ),
      );
}
