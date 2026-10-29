import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mangayomi/utils/url_protocol/api.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';
import 'package:http/http.dart' as http;
import 'package:mangayomi/models/custom_button.dart';
import 'package:mangayomi/repositories/custom_button_repository.dart';

/// A button from Schnitzel5/mangayomi-custom-buttons.
class GalleryButton {
  final String title, description, codePress, codeLongPress, codeStartup;
  const GalleryButton({
    required this.title,
    required this.description,
    required this.codePress,
    this.codeLongPress = '',
    this.codeStartup = '',
  });
}

/// The buttons of Schnitzel5/mangayomi-custom-buttons, bundled so they work
/// offline; "Cập nhật" re-reads the repository.
const bundledButtons = <GalleryButton>[
  GalleryButton(
    title: '+85 s',
    description: 'The default button in the app.',
    codePress:
        'local intro_length = mp.get_property_native("user-data/current-anime/intro-length")\naniyomi.right_seek_by(intro_length)',
    codeLongPress:
        'aniyomi.int_picker("Change intro length", "%ds", 0, 255, 1, "user-data/current-anime/intro-length")',
    codeStartup: '''function update_button(_, length)
  if length ~= nil then
    if length == 0 then
	  aniyomi.hide_button()
	  return
	else
	  aniyomi.show_button()
	end
    aniyomi.set_button_title("+" .. length .. " s")
  end
end

if \$isPrimary then
  mp.observe_property("user-data/current-anime/intro-length", "number", update_button)
end''',
  ),
  GalleryButton(
    title: 'Smart Skip',
    description: 'Auto-detect and skip intro, outro and more!',
    codePress: 'mp.command("script-message skip-to-silence")',
  ),
  GalleryButton(
    title: 'Auto hide soft subs',
    description: 'Automatically hide soft subs!',
    codePress: '-- ignore this',
    codeStartup: "mp.set_property('sub-visibility', 'no')",
  ),
];

class CustomButtonsGallery {
  static const _base =
      'https://raw.githubusercontent.com/Schnitzel5/mangayomi-custom-buttons/main/buttons';

  static String? _field(String src, String name) {
    final m = RegExp(
      '$name:\\s*("""|\'\'\'|"|\')([\\s\\S]*?)\\1',
    ).firstMatch(src);
    return m?.group(2)?.replaceAll(r'\$', r'$');
  }

  /// Reads buttons/button_list.dart and each button file of the repo.
  static Future<List<GalleryButton>> fetch() async {
    final list = await http.get(Uri.parse('$_base/button_list.dart'));
    if (list.statusCode != 200) return bundledButtons;
    final files = RegExp(r"import '([a-z0-9_]+\.dart)';")
        .allMatches(list.body)
        .map((m) => m.group(1)!)
        .where((f) => f != '../custom_button.dart')
        .toList();
    final out = <GalleryButton>[];
    for (final f in files) {
      try {
        final r = await http.get(Uri.parse('$_base/$f'));
        if (r.statusCode != 200) continue;
        final title = _field(r.body, 'title');
        final press = _field(r.body, 'codePress');
        if (title == null || press == null) continue;
        out.add(
          GalleryButton(
            title: title,
            description: _field(r.body, 'description') ?? '',
            codePress: press,
            codeLongPress: _field(r.body, 'codeLongPress') ?? '',
            codeStartup: _field(r.body, 'codeStartup') ?? '',
          ),
        );
      } catch (_) {}
    }
    return out.isEmpty ? bundledButtons : out;
  }

  /// YomiHub 0.1.7: a button shared as a link – `mangayomi://add-button?button=<base64 JSON>`
  /// (also `yomihub://…`, or the README's http-protocol-redirector link).
  static GalleryButton? fromLink(String text) {
    var t = text.trim();
    final r = Uri.tryParse(t);
    if (r != null && r.queryParameters['r'] != null) t = r.queryParameters['r']!;
    final u = Uri.tryParse(t);
    final raw = u?.queryParameters['button'];
    if (u == null || u.host != 'add-button' || raw == null) return null;
    try {
      var b64 = raw.replaceAll('-', '+').replaceAll('_', '/');
      while (b64.length % 4 != 0) {
        b64 += '=';
      }
      final j = jsonDecode(utf8.decode(base64.decode(b64))) as Map;
      final title = '${j['title'] ?? ''}';
      if (title.isEmpty) return null;
      return GalleryButton(
        title: title,
        description: 'Từ liên kết',
        codePress: '${j['codePress'] ?? ''}',
        codeLongPress: '${j['codeLongPress'] ?? ''}',
        codeStartup: '${j['codeStartup'] ?? ''}',
      );
    } catch (_) {
      return null;
    }
  }

  /// Windows: open `mangayomi://` links (custom buttons, repos) with YomiHub.
  static bool get handlesMangayomiLinks => YomiPrefs.get('handleMangayomiLinks', false);
  static Future<void> setHandlesMangayomiLinks(bool v) async {
    await YomiPrefs.set('handleMangayomiLinks', v);
    if (!Platform.isWindows) return;
    try {
      v ? registerProtocolHandler('mangayomi') : unregisterProtocolHandler('mangayomi');
    } catch (_) {}
  }

  static Future<void> add(GalleryButton b) async {
    final all = customButtonRepository.getAll();
    final pos = all.isEmpty
        ? 0
        : all.map((e) => e.pos ?? 0).reduce((a, c) => a > c ? a : c) + 1;
    await customButtonRepository.save(
      CustomButton(
        title: b.title,
        codePress: b.codePress,
        codeLongPress: b.codeLongPress,
        codeStartup: b.codeStartup,
        pos: pos,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}

/// Mangayomi Custom Buttons gallery (Settings › Player › Custom buttons).
class CustomButtonsGalleryScreen extends StatefulWidget {
  const CustomButtonsGalleryScreen({super.key});

  @override
  State<CustomButtonsGalleryScreen> createState() =>
      _CustomButtonsGalleryScreenState();
}

class _CustomButtonsGalleryScreenState extends State<CustomButtonsGalleryScreen> {
  List<GalleryButton> _items = bundledButtons;
  bool _loading = false;

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      _items = await CustomButtonsGallery.fetch();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pasteLink() async {
    final ctrl = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Liên kết nút tuỳ chỉnh'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'mangayomi://add-button?button=…', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Thêm')),
        ],
      ),
    );
    if (text == null || text.trim().isEmpty) return;
    final b = CustomButtonsGallery.fromLink(text);
    if (!mounted) return;
    if (b == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Liên kết không hợp lệ')));
      return;
    }
    await CustomButtonsGallery.add(b);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã thêm nút “${b.title}”')));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final installed = customButtonRepository
        .getAll()
        .map((e) => e.title)
        .toSet();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mangayomi Custom Buttons'),
        actions: [
          _loading
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  tooltip: 'Cập nhật từ GitHub',
                  icon: const Icon(Icons.refresh),
                  onPressed: _refresh,
                ),
        ],
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Nút tuỳ chỉnh cho trình phát (Lua/mpv) từ kho '
              'Schnitzel5/mangayomi-custom-buttons. Bấm Thêm để đưa vào danh sách nút. '
              'Dùng được trên Android và Windows.',
              style: TextStyle(fontSize: 12),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add_link),
            title: const Text('Thêm từ liên kết'),
            subtitle: const Text('Dán link mangayomi://add-button?button=… (hoặc link trong README của kho)'),
            onTap: _pasteLink,
          ),
          if (Platform.isWindows)
            SwitchListTile(
              secondary: const Icon(Icons.link),
              title: const Text('Mở liên kết mangayomi:// bằng YomiHub'),
              subtitle: const Text('Bấm nút “Add” trên trang GitHub là thêm thẳng vào YomiHub (tắt nếu bạn còn dùng Mangayomi)'),
              value: CustomButtonsGallery.handlesMangayomiLinks,
              onChanged: (v) async {
                await CustomButtonsGallery.setHandlesMangayomiLinks(v);
                if (mounted) setState(() {});
              },
            ),
          const Divider(),
          for (final b in _items)
            ListTile(
              leading: const Icon(Icons.smart_button_outlined),
              title: Text(b.title),
              subtitle: Text(b.description),
              trailing: installed.contains(b.title)
                  ? const Icon(Icons.check, color: Colors.green)
                  : FilledButton.tonal(
                      onPressed: () async {
                        await CustomButtonsGallery.add(b);
                        if (mounted) setState(() {});
                      },
                      child: const Text('Thêm'),
                    ),
            ),
        ],
      ),
    );
  }
}
