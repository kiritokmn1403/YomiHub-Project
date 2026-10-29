import 'package:flutter/material.dart';
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
            title: const Text('Tự xử lý thử thách Cloudflare'),
            subtitle: const Text(
              'Khi tiện ích gặp trang "Just a moment…", app tự xác minh rồi tải lại',
            ),
            value: on,
            onChanged: (v) => _set(() => CloudScraper.enabled = v),
          ),
          if (on) ...[
            _header('Cách xác minh'),
            RadioGroup<String>(
              groupValue: CloudScraper.solver,
              onChanged: (v) =>
                  v == null ? null : _set(() => CloudScraper.solver = v),
              child: const Column(
                children: [
                  RadioListTile(
                    value: 'webview',
                    title: Text('WebView tích hợp (khuyên dùng)'),
                    subtitle: Text('Mở trang ẩn trong nhân trình duyệt rồi lưu cookie'),
                  ),
                  RadioListTile(
                    value: 'flaresolverr',
                    title: Text('Máy chủ FlareSolverr / Byparr của bạn'),
                    subtitle: Text('Dùng cả cho tiện ích APK (M-Extension-Server)'),
                  ),
                  RadioListTile(value: 'off', title: Text('Không tự xác minh')),
                ],
              ),
            ),
            SwitchListTile(
              title: const Text('Hiện trang xác minh khi cần'),
              subtitle: const Text(
                'Nếu WebView ẩn không qua được (ô "Xác minh bạn là con người"), '
                'mở trang để bạn bấm; tự đóng khi xong',
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
                      decoration: const InputDecoration(
                        labelText: 'Địa chỉ FlareSolverr / Byparr',
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
                              const SnackBar(content: Text('Đã lưu')),
                            );
                          },
                          child: const Text('Lưu'),
                        ),
                        TextButton(
                          onPressed: () async {
                            final r = await CloudScraper.testProxy(
                              _proxy.text.trim(),
                            );
                            if (mounted) setState(() => _test = r);
                          },
                          child: const Text('Kiểm tra'),
                        ),
                      ],
                    ),
                    if (_test != null) Text(_test!, style: small),
                  ],
                ),
              ),
            _header('Nhận diện trình duyệt'),
            SwitchListTile(
              title: const Text('Giả lập trình duyệt thật'),
              subtitle: const Text(
                'Bổ sung User-Agent, ngôn ngữ, client hints cho tiện ích không tự đặt',
              ),
              value: CloudScraper.emulateBrowser,
              onChanged: (v) => _set(() => CloudScraper.emulateBrowser = v),
            ),
            if (CloudScraper.emulateBrowser) ...[
              ListTile(
                title: const Text('Trình duyệt'),
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
                title: const Text('Nền tảng'),
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
            _header('Thử lại'),
            ListTile(
              title: Text('Số lần thử lại: ${CloudScraper.retries}'),
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
                'Chờ trước khi thử lại: ${(CloudScraper.delayMs / 1000).toStringAsFixed(1)} s',
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
          _header('Trang đã xác minh (${sites.length})'),
          if (sites.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Chưa có trang nào', style: small),
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
                tooltip: 'Xoá xác minh của trang này',
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  await YomiCf.forget(h);
                  if (mounted) setState(() {});
                },
              ),
            ),
          ListTile(
            leading: const Icon(Icons.cookie_outlined),
            title: const Text('Xoá toàn bộ cookie Cloudflare'),
            subtitle: const Text('Dùng khi một trang bị kẹt ở bước xác minh'),
            onTap: () async {
              await settingsRepository.update((s) => s.cookiesList = []);
              await YomiCf.forgetAll();
              try {
                await CookieManager.instance().deleteAllCookies();
              } catch (_) {}
              if (!context.mounted) return;
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xoá cookie')),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Cookie xác minh (cf_clearance) chỉ hợp lệ với đúng trình duyệt đã '
              'lấy nó, nên YomiHub nhớ User-Agent theo từng trang và tự dùng lại '
              'khi tiện ích gửi yêu cầu. Nếu vẫn bị chặn, mở trang trong WebView '
              'của tiện ích và xác minh thủ công.',
              style: small,
            ),
          ),
        ],
      ),
    );
  }
}
