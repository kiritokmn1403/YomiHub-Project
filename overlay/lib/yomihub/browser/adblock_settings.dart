import 'package:flutter/material.dart';
import 'package:mangayomi/yomihub/browser/adblock.dart';
import 'package:mangayomi/yomihub/browser/userscripts_screen.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';
import 'package:mangayomi/yomihub/ui/liquid_glass.dart';

/// YomiHub 0.2.0: "Chặn quảng cáo (AdBlock)" in the app Settings – the
/// same engine as the in-app browser (uBlock Origin / AdGuard / EasyList /
/// ABPVN lists, Tampermonkey cleaner, user rules, user scripts), now also
/// reachable without opening the browser, and applied to the extension
/// WebViews and the web player.
class AdBlockSettingsScreen extends StatefulWidget {
  const AdBlockSettingsScreen({super.key});

  @override
  State<AdBlockSettingsScreen> createState() => _AdBlockSettingsScreenState();
}

class _AdBlockSettingsScreenState extends State<AdBlockSettingsScreen> {
  bool _loaded = false;
  bool _updating = false;
  late final TextEditingController _rules = TextEditingController();

  @override
  void initState() {
    super.initState();
    YomiAdBlock.load().then((_) {
      if (!mounted) return;
      _rules.text = YomiAdBlock.userRules.join('\n');
      setState(() => _loaded = true);
    });
  }

  @override
  void dispose() {
    _rules.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    YomiAdBlock.userRules = _rules.text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    await YomiAdBlock.save();
  }

  Future<void> _updateLists() async {
    setState(() => _updating = true);
    try {
      final n = await YomiAdBlock.updateLists();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('Đã cập nhật {p0} tên miền quảng cáo', {'p0': '$n'}))),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final upd = YomiAdBlock.listUpdated == 0
        ? (YomiAdBlock.listHosts.isEmpty ? tr('Chưa tải') : tr('Nên cập nhật lại'))
        : tr('Lần cuối: {p0}', {
            'p0': DateTime.fromMillisecondsSinceEpoch(YomiAdBlock.listUpdated).toString().substring(0, 16),
          });
    return PopScope(
      onPopInvokedWithResult: (_, _) => _save(),
      child: Scaffold(
        appBar: AppBar(title: Text(tr('Chặn quảng cáo (AdBlock)'))),
        body: !_loaded
            ? const Center(child: CircularProgressIndicator())
            : LiquidGlassBackdrop(
                child: ListView(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.shield_outlined),
                      title: Text(tr('Bật chặn quảng cáo')),
                      subtitle: Text(tr('Trình duyệt, WebView của tiện ích, trình phát web và luồng HLS')),
                      value: YomiAdBlock.enabled,
                      onChanged: (v) {
                        setState(() => YomiAdBlock.enabled = v);
                        _save();
                      },
                    ),
                    SwitchListTile(
                      secondary: const Icon(Icons.cleaning_services_outlined),
                      title: Text(tr('Dọn quảng cáo kiểu Tampermonkey')),
                      subtitle: Text(tr('Ẩn khung quảng cáo, chặn pop-up và lớp phủ trên các trang phim/truyện quen thuộc')),
                      value: YomiAdBlock.tampermonkey,
                      onChanged: YomiAdBlock.enabled
                          ? (v) {
                              setState(() => YomiAdBlock.tampermonkey = v);
                              _save();
                            }
                          : null,
                    ),
                    SwitchListTile(
                      secondary: const Icon(Icons.ondemand_video_outlined),
                      title: Text(tr('Lọc quảng cáo chèn trong video (HLS)')),
                      subtitle: Text(tr('Bỏ các đoạn quảng cáo cài trong danh sách phát m3u8')),
                      value: YomiPrefs.get<bool>('hlsAdFilter', true),
                      onChanged: YomiAdBlock.enabled
                          ? (v) async {
                              await YomiPrefs.set('hlsAdFilter', v);
                              setState(() {});
                            }
                          : null,
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.playlist_add_check),
                      title: Text(tr('Danh sách lọc ({p0} tên miền)', {'p0': '${YomiAdBlock.listHosts.length}'})),
                      subtitle: Text('${YomiAdBlock.lists.keys.join(', ')}\n$upd'),
                      isThreeLine: true,
                      trailing: _updating
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                          : IconButton(
                              tooltip: tr('Cập nhật'),
                              icon: const Icon(Icons.refresh),
                              onPressed: _updateLists,
                            ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.code),
                      title: Text(tr('Kịch bản người dùng (user scripts)')),
                      subtitle: Text(tr('{p0} kịch bản', {'p0': '${YomiAdBlock.userScripts.length}'})),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => const UserScriptsScreen()))
                          .then((_) => setState(() {})),
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text(tr('Quy tắc riêng (cú pháp uBlock / Adblock Plus)'),
                          style: Theme.of(context).textTheme.titleSmall),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _rules,
                        minLines: 4,
                        maxLines: 10,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '||ads.example.com^\nexample.com##.banner',
                        ),
                        onEditingComplete: _save,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: const Icon(Icons.do_not_disturb_off_outlined),
                      title: Text(tr('Trang được bỏ qua')),
                      subtitle: Text(YomiAdBlock.allowed.isEmpty
                          ? tr('Không có – bỏ qua một trang bằng nút khiên trong trình duyệt')
                          : YomiAdBlock.allowed.join(', ')),
                    ),
                    for (final h in YomiAdBlock.allowed.toList())
                      ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.only(left: 72, right: 8),
                        title: Text(h),
                        trailing: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() => YomiAdBlock.allowed.remove(h));
                            _save();
                          },
                        ),
                      ),
                    ListTile(
                      leading: const Icon(Icons.bar_chart),
                      title: Text(tr('Đã chặn trong phiên này: {p0}', {'p0': '${YomiAdBlock.blockedCount}'})),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
