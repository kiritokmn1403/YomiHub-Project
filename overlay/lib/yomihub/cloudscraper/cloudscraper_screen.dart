import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mangayomi/yomihub/cloudflare/cloak_solver.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:mangayomi/repositories/settings_repository.dart';
import 'package:mangayomi/services/http/cf_proxy_store.dart';
import 'package:mangayomi/yomihub/cloudflare/cf_challenge.dart';
import 'package:mangayomi/yomihub/cloudscraper/cloudscraper.dart';

/// YomiHub 0.1.6: Settings › Cloudflare Bypass Setting.
///
/// One place for everything that used to be split between
/// Settings › CloudScraper and Settings › Chung › "Cloudflare bypass proxy":
/// how challenges are passed, the optional FlareSolverr/Byparr server, the
/// browser identity, retries and the list of verified sites.
class CloudScraperScreen extends StatefulWidget {
  const CloudScraperScreen({super.key});

  @override
  State<CloudScraperScreen> createState() => _CloudScraperScreenState();
}

class _CloudScraperScreenState extends State<CloudScraperScreen> {
  final _proxy = TextEditingController(text: CfProxyStore.url);
  String? _test;
  String? _cloak;

  @override
  void initState() {
    super.initState();
    YomiCloak.findBinary().then((v) {
      if (mounted) setState(() => _cloak = v);
    });
  }

  Future<void> _set(VoidCallback f) async {
    setState(f);
    await CloudScraper.save();
  }

  Widget _header(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
    child: Text(
      t,
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  @override
  void dispose() {
    _proxy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final small = Theme.of(context).textTheme.bodySmall;
    final sites = YomiCf.all.keys.toList()..sort();
    final on = CloudScraper.enabled;
    return Scaffold(
      appBar: AppBar(title: const Text('Cloudflare Bypass Setting')),
      body: ListView(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.shield_outlined),
            title: Text(tr('Tự xử lý thử thách Cloudflare')),
            subtitle: Text(
              tr('Khi tiện ích gặp trang "Just a moment…", app tự xác minh rồi tải lại'),
            ),
            value: on,
            onChanged: (v) => _set(() => CloudScraper.enabled = v),
          ),
          if (on) ...[
            _header(tr('Cách xác minh')),
            RadioGroup<String>(
              groupValue: CloudScraper.solver,
              onChanged: (v) =>
                  v == null ? null : _set(() => CloudScraper.solver = v),
              child: Column(
                children: [
                  RadioListTile(
                    value: 'webview',
                    title: Text(tr('WebView tích hợp (khuyên dùng)')),
                    subtitle: Text(tr('Mở trang ẩn trong nhân trình duyệt rồi lưu cookie')),
                  ),
                  // 0.1.8: CloakBrowser (CloakHQ) – stealth Chromium solver
                  if (Platform.isWindows)
                    RadioListTile(
                      value: 'cloak',
                      title: Text(tr('CloakBrowser (Chromium chống nhận diện)')),
                      subtitle: Text(_cloak == null
                          ? tr('Chưa thấy CloakBrowser – cài bằng "pip install cloakbrowser" rồi "python -m cloakbrowser install", hoặc chọn chrome.exe bên dưới')
                          : tr('Đã thấy: {p0}', {'p0': _cloak})),
                    ),
                  RadioListTile(
                    value: 'flaresolverr',
                    title: Text(tr('Máy chủ FlareSolverr / Byparr của bạn')),
                    subtitle: Text(tr('Dùng cả cho tiện ích APK (M-Extension-Server)')),
                  ),
                  RadioListTile(value: 'off', title: Text(tr('Không tự xác minh'))),
                ],
              ),
            ),
            if (Platform.isWindows && CloudScraper.solver == 'cloak')
              ListTile(
                leading: const Icon(Icons.folder_open),
                title: Text(tr('Đường dẫn chrome.exe của CloakBrowser')),
                subtitle: Text(YomiCloak.customPath.isEmpty ? tr('Tự tìm trong %USERPROFILE%\\.cloakbrowser') : YomiCloak.customPath),
                onTap: () async {
                  final f = (await FilePicker.pickFiles()).firstOrNull;
                  if (f?.path == null) return;
                  await YomiPrefs.set('cloakPath', f!.path!);
                  _cloak = await YomiCloak.findBinary();
                  if (mounted) setState(() {});
                },
              ),
            SwitchListTile(
              title: Text(tr('Tự bấm ô xác minh như người thật')),
              subtitle: Text(
                tr('Theo CloakBrowser (humanize): đường chuột cong, tốc độ tự nhiên, bấm vào ô Turnstile trên trang xác minh bằng thao tác thật của hệ thống'),
              ),
              value: YomiCloak.humanize,
              onChanged: (v) async {
                await YomiPrefs.set('cfHumanize', v);
                setState(() {});
              },
            ),
            SwitchListTile(
              title: Text(tr('Hiện trang xác minh khi cần')),
              subtitle: Text(
                tr('Nếu WebView ẩn không qua được (ô "Xác minh bạn là con người"), mở trang để bạn bấm; tự đóng khi xong'),
              ),
              value: CloudScraper.interactive,
              onChanged: (v) => _set(() => CloudScraper.interactive = v),
            ),
            if (CloudScraper.solver == 'flaresolverr')
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _proxy,
                      keyboardType: TextInputType.url,
                      decoration: InputDecoration(
                        labelText: tr('Địa chỉ FlareSolverr / Byparr'),
                        hintText: 'http://192.168.1.10:8191/v1',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (v) => CfProxyStore.setUrl(v.trim()),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            CfProxyStore.setUrl(_proxy.text.trim());
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(tr('Đã lưu'))),
                            );
                          },
                          child: Text(tr('Lưu')),
                        ),
                        TextButton(
                          onPressed: () async {
                            final r = await CloudScraper.testProxy(
                              _proxy.text.trim(),
                            );
                            if (mounted) setState(() => _test = r);
                          },
                          child: Text(tr('Kiểm tra')),
                        ),
                      ],
                    ),
                    if (_test != null) Text(_test!, style: small),
                  ],
                ),
              ),
            _header(tr('Nhận diện trình duyệt')),
            SwitchListTile(
              title: Text(tr('Giả lập trình duyệt thật')),
              subtitle: Text(
                tr('Bổ sung User-Agent, ngôn ngữ, client hints cho tiện ích không tự đặt'),
              ),
              value: CloudScraper.emulateBrowser,
              onChanged: (v) => _set(() => CloudScraper.emulateBrowser = v),
            ),
            if (CloudScraper.emulateBrowser) ...[
              ListTile(
                title: Text(tr('Trình duyệt')),
                trailing: DropdownButton<String>(
                  value: CloudScraper.browser,
                  items: [
                    for (final e in CloudScraper.browsers.entries)
                      DropdownMenuItem(value: e.key, child: Text(e.value)),
                  ],
                  onChanged: (v) =>
                      v == null ? null : _set(() => CloudScraper.browser = v),
                ),
              ),
              ListTile(
                title: Text(tr('Nền tảng')),
                trailing: DropdownButton<String>(
                  value: CloudScraper.platform,
                  items: [
                    for (final e in CloudScraper.platforms.entries)
                      DropdownMenuItem(value: e.key, child: Text(e.value)),
                  ],
                  onChanged: (v) =>
                      v == null ? null : _set(() => CloudScraper.platform = v),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SelectableText(CloudScraper.userAgent, style: small),
              ),
            ],
            _header(tr('Thử lại')),
            ListTile(
              title: Text(tr('Số lần thử lại: {p0}', {'p0': CloudScraper.retries})),
              subtitle: Slider(
                value: CloudScraper.retries.toDouble(),
                min: 0,
                max: 5,
                divisions: 5,
                label: '${CloudScraper.retries}',
                onChanged: (v) => _set(() => CloudScraper.retries = v.round()),
              ),
            ),
            ListTile(
              title: Text(
                tr('Chờ trước khi thử lại: {p0} s', {'p0': (CloudScraper.delayMs / 1000).toStringAsFixed(1)}),
              ),
              subtitle: Slider(
                value: CloudScraper.delayMs.toDouble(),
                min: 0,
                max: 10000,
                divisions: 20,
                onChanged: (v) =>
                    _set(() => CloudScraper.delayMs = v.round()),
              ),
            ),
          ],
          _header(tr('Trang đã xác minh ({p0})', {'p0': sites.length})),
          if (sites.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(tr('Chưa có trang nào'), style: small),
            ),
          for (final h in sites)
            ListTile(
              dense: true,
              leading: const Icon(Icons.verified_outlined, size: 20),
              title: Text(h),
              subtitle: Text(
                YomiCf.all[h]!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: small,
              ),
              trailing: IconButton(
                tooltip: tr('Xoá xác minh của trang này'),
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  await YomiCf.forget(h);
                  if (mounted) setState(() {});
                },
              ),
            ),
          ListTile(
            leading: const Icon(Icons.cookie_outlined),
            title: Text(tr('Xoá toàn bộ cookie Cloudflare')),
            subtitle: Text(tr('Dùng khi một trang bị kẹt ở bước xác minh')),
            onTap: () async {
              await settingsRepository.update((s) => s.cookiesList = []);
              await YomiCf.forgetAll();
              try {
                await CookieManager.instance().deleteAllCookies();
              } catch (_) {}
              if (!context.mounted) return;
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(tr('Đã xoá cookie'))),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              tr('Cookie xác minh (cf_clearance) chỉ hợp lệ với đúng trình duyệt đã lấy nó, nên YomiHub nhớ User-Agent theo từng trang và tự dùng lại khi tiện ích gửi yêu cầu. Nếu vẫn bị chặn, mở trang trong WebView của tiện ích và xác minh thủ công.'),
              style: small,
            ),
          ),
        ],
      ),
    );
  }
}
