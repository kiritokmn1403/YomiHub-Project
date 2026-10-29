import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mangayomi/modules/more/settings/browse/providers/browse_state_provider.dart';
import 'package:mangayomi/modules/more/settings/reader/providers/reader_state_provider.dart';
import 'package:mangayomi/yomihub/booru/booru_models.dart';
import 'package:mangayomi/yomihub/booru/booru_store.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:url_launcher/url_launcher.dart';

/// YomiHub 0.4.4 – entry in Settings (next to Google Play Books).
class BooruSettingTile extends ConsumerWidget {
  const BooruSettingTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = !ref.watch(hideItemsStateProvider).contains(BooruStore.route);
    return ListTile(
      leading: const Icon(Icons.photo_library_outlined, color: Colors.deepPurple),
      title: const Text('Booru App'),
      subtitle: Text(on
          ? tr('Đang bật – duyệt ảnh từ Danbooru, Safebooru, Gelbooru, Yande.re, Konachan, e621…')
          : tr('Đang tắt – ẩn nút Booru khỏi thanh điều hướng')),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      onTap: () => context.push('/booruSettings'),
    );
  }
}

class BooruSettingsScreen extends ConsumerStatefulWidget {
  const BooruSettingsScreen({super.key});

  @override
  ConsumerState<BooruSettingsScreen> createState() => _BooruSettingsScreenState();
}

class _BooruSettingsScreenState extends ConsumerState<BooruSettingsScreen> {
  final store = BooruStore.instance;

  /// Booru projects of the "Project GitHub" sheet (section XXI).
  static const projects = <List<String>>[
    ['BooruHub', 'https://github.com/TheRealTRYZER/BooruHub'],
    ['BooruHubI18n', 'https://github.com/onlymash/BooruHubI18n'],
    ['BooruHubDocs', 'https://github.com/onlymash/BooruHubDocs'],
    ['Boorusama', 'https://github.com/khoadng/Boorusama'],
    ['boorusama-ts', 'https://github.com/sanfangx/boorusama-ts'],
    ['boorusama-qt', 'https://github.com/1Git2Clone/boorusama-qt'],
    ['Booru-Studio', 'https://github.com/SaltedShroom/Booru-Studio'],
    ['danbooru', 'https://github.com/danbooru/danbooru'],
    ['boorusphere', 'https://github.com/nullxception/boorusphere'],
    ['Rule-34 App', 'https://github.com/Rule-34/App'],
    ['Hybooru', 'https://github.com/funmaker/Hybooru'],
    ['monbooru', 'https://github.com/monbooru/monbooru'],
  ];

  @override
  void initState() {
    super.initState();
    store.addListener(_onStore);
    store.init();
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    store.removeListener(_onStore);
    super.dispose();
  }

  void _setEnabled(bool on) {
    final hidden = [...ref.read(hideItemsStateProvider)];
    hidden.remove(BooruStore.route);
    if (!on) hidden.add(BooruStore.route);
    ref.read(hideItemsStateProvider.notifier).set(hidden);
  }

  Future<void> _editBlacklist() async {
    final c = TextEditingController(text: store.blacklist.join(' '));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Thẻ bị chặn')),
        content: TextField(
          controller: c,
          maxLines: 5,
          decoration: InputDecoration(helperText: tr('Cách nhau bằng dấu cách. Ảnh có một trong các thẻ này sẽ bị ẩn.')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Huỷ'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Lưu'))),
        ],
      ),
    );
    if (ok == true) await store.setBlacklist(c.text.split(RegExp(r'\s+')));
  }

  Future<void> _editCreds(BooruSite s) async {
    final l = TextEditingController(text: store.login(s.id));
    final k = TextEditingController(text: store.apiKey(s.id));
    final idLabel = s.type == BooruType.gelbooru ? 'User ID' : tr('Tên đăng nhập');
    final keyLabel = s.type == BooruType.moebooru ? 'Password hash' : 'API key';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.name),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: l, decoration: InputDecoration(labelText: idLabel)),
          TextField(controller: k, obscureText: true, decoration: InputDecoration(labelText: keyLabel)),
          const SizedBox(height: 8),
          Text(tr('Lấy trong trang tài khoản của {p0}. Được lưu trên máy và chỉ đưa vào bản sao lưu khi chọn "gồm cài đặt nhạy cảm".', {'p0': s.host}),
              style: Theme.of(ctx).textTheme.bodySmall),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Huỷ'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Lưu'))),
        ],
      ),
    );
    if (ok == true) await store.setCreds(s.id, l.text, k.text);
  }

  Future<void> _addSite() async {
    final name = TextEditingController();
    final url = TextEditingController(text: 'https://');
    var type = BooruType.danbooru;
    var nsfw = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(tr('Thêm trang Booru')),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: name, decoration: InputDecoration(labelText: tr('Tên'))),
            TextField(controller: url, decoration: const InputDecoration(labelText: 'URL')),
            DropdownButton<BooruType>(
              value: type,
              isExpanded: true,
              items: [
                for (final t in BooruType.values)
                  DropdownMenuItem(value: t, child: Text(switch (t) {
                    BooruType.danbooru => 'Danbooru 2',
                    BooruType.gelbooru => 'Gelbooru 0.2 (Safebooru, Rule34…)',
                    BooruType.moebooru => 'Moebooru (Yande.re, Konachan…)',
                    BooruType.e621 => 'e621 / e926',
                  })),
              ],
              onChanged: (v) => setD(() => type = v ?? type),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: nsfw,
              title: Text(tr('Trang chỉ có nội dung 18+')),
              onChanged: (v) => setD(() => nsfw = v ?? false),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Huỷ'))),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Thêm'))),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final s = BooruSite.fromJson({
      'id': 'custom_${DateTime.now().millisecondsSinceEpoch}',
      'name': name.text.trim().isEmpty ? (Uri.tryParse(url.text)?.host ?? url.text) : name.text.trim(),
      'type': type.name,
      'baseUrl': url.text.trim(),
      'nsfwOnly': nsfw,
    });
    if (s != null && Uri.tryParse(s.baseUrl)?.hasScheme == true) await store.addSite(s);
  }

  @override
  Widget build(BuildContext context) {
    final on = !ref.watch(hideItemsStateProvider).contains(BooruStore.route);
    final nsfw = ref.watch(showNSFWStateProvider);
    final keySites = store.allSites.where((s) => s.needsKey || s.custom || s.type == BooruType.danbooru || s.type == BooruType.e621).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Booru App')),
      body: ListView(children: [
        SwitchListTile(
          secondary: const Icon(Icons.photo_library_outlined),
          title: Text(tr('Bật Booru App')),
          subtitle: Text(tr('Hiện nút Booru bên phải Play Books trên thanh điều hướng')),
          value: on,
          onChanged: _setEnabled,
        ),
        ListTile(
          leading: Icon(nsfw ? Icons.no_adult_content : Icons.child_care_outlined),
          title: Text(tr('Nội dung 18+')),
          subtitle: Text(nsfw
              ? tr('Đang hiện (theo cài đặt NSFW của ứng dụng: Cài đặt › Duyệt)')
              : tr('Đang ẩn: chỉ ảnh phổ thông, ẩn các trang 18+ (theo cài đặt NSFW của ứng dụng)')),
        ),
        const Divider(),
        _header(tr('Hiển thị')),
        ListTile(
          leading: const Icon(Icons.grid_view),
          title: Text(tr('Số cột lưới')),
          trailing: DropdownButton<int>(
            value: store.columns,
            items: [for (var i = 2; i <= 6; i++) DropdownMenuItem(value: i, child: Text('$i'))],
            onChanged: (v) => store.setColumns(v ?? 3),
          ),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.high_quality_outlined),
          title: Text(tr('Mở ảnh gốc')),
          subtitle: Text(tr('Tắt: dùng ảnh thu nhỏ của trang (nhanh, tiết kiệm dữ liệu)')),
          value: store.fullQuality,
          onChanged: store.setFullQuality,
        ),
        SwitchListTile(
          secondary: const Icon(Icons.play_circle_outline),
          title: Text(tr('Tự phát video')),
          value: store.autoplayVideo,
          onChanged: store.setAutoplayVideo,
        ),
        ListTile(
          leading: const Icon(Icons.block),
          title: Text(tr('Thẻ bị chặn')),
          subtitle: Text(store.blacklist.isEmpty ? tr('Không có') : store.blacklist.join(', '), maxLines: 2, overflow: TextOverflow.ellipsis),
          onTap: _editBlacklist,
        ),
        const Divider(),
        _header(tr('Trang & tài khoản')),
        for (final s in keySites)
          ListTile(
            leading: Icon(store.apiKey(s.id).isNotEmpty ? Icons.key : Icons.key_off_outlined),
            title: Text(s.name),
            subtitle: Text('${s.host}${s.needsKey ? ' · ${tr('cần API key')}' : ''}${s.nsfwOnly ? ' · 18+' : ''}'),
            onTap: () => _editCreds(s),
            trailing: s.custom
                ? IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => store.removeSite(s.id))
                : null,
          ),
        ListTile(
          leading: const Icon(Icons.add),
          title: Text(tr('Thêm trang Booru')),
          onTap: _addSite,
        ),
        const Divider(),
        _header(tr('Dữ liệu')),
        ListTile(
          leading: const Icon(Icons.backup_outlined),
          title: Text(tr('Sao lưu')),
          subtitle: Text(tr('Yêu thích ({p0}), lịch sử và cài đặt Booru App được sao lưu cùng ứng dụng (Cài đặt › Dữ liệu và bộ nhớ, đồng bộ đám mây).',
              {'p0': '${store.favourites.length}'})),
        ),
        ListTile(
          leading: const Icon(Icons.folder_outlined),
          title: Text(tr('Đã tải xuống')),
          subtitle: Text(tr('{p0} tệp – thư mục "Booru" trong thư mục tải xuống của ứng dụng', {'p0': '${store.downloads}'})),
        ),
        ListTile(
          leading: const Icon(Icons.delete_sweep_outlined),
          title: Text(tr('Xoá lịch sử tìm kiếm')),
          onTap: store.clearHistory,
        ),
        const Divider(),
        _header(tr('Dự án mã nguồn mở')),
        for (final p in projects)
          ListTile(
            dense: true,
            leading: const Icon(Icons.code),
            title: Text(p[0]),
            subtitle: Text(p[1]),
            onTap: () => launchUrl(Uri.parse(p[1]), mode: LaunchMode.externalApplication),
          ),
      ]),
    );
  }

  Widget _header(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(t, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
      );
}
