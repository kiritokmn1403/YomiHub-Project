import 'package:flutter/material.dart';
import 'package:mangayomi/services/http/cf_proxy_store.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:mangayomi/repositories/settings_repository.dart';
import 'package:mangayomi/yomihub/cloudscraper/cloudscraper.dart';

/// Settings › CloudScraper (vượt Cloudflare).
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

  @override
  Widget build(BuildContext context) {
    final small = Theme.of(context).textTheme.bodySmall;
    return Scaffold(
      appBar: AppBar(title: const Text('CloudScraper')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Bật CloudScraper'),
            subtitle: const Text(
              'Giả lập trình duyệt thật và tự giải thử thách Cloudflare cho mọi tiện ích',
            ),
            value: CloudScraper.enabled,
            onChanged: (v) => _set(() => CloudScraper.enabled = v),
          ),
          const Divider(),
          const ListTile(title: Text('Cách giải thử thách')),
          RadioGroup<String>(
            groupValue: CloudScraper.solver,
            onChanged: (v) => v == null ? null : _set(() => CloudScraper.solver = v),
            child: const Column(
              children: [
                RadioListTile(
                  value: 'webview',
                  title: Text('Nhân trình duyệt tích hợp (WebView)'),
                  subtitle: Text('Giải JS challenge / Turnstile như trình thông dịch của cloudscraper'),
                ),
                RadioListTile(
                  value: 'flaresolverr',
                  title: Text('Máy chủ FlareSolverr / Byparr'),
                  subtitle: Text('Dùng cả cho tiện ích APK (M-Extension-Server)'),
                ),
                RadioListTile(
                  value: 'off',
                  title: Text('Không tự giải'),
                ),
              ],
            ),
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
                          final r = await CloudScraper.testProxy(_proxy.text.trim());
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
          const Divider(),
          const ListTile(title: Text('Giả lập trình duyệt')),
          ListTile(
            title: const Text('Trình duyệt'),
            trailing: DropdownButton<String>(
              value: CloudScraper.browser,
              items: [
                for (final e in CloudScraper.browsers.entries)
                  DropdownMenuItem(value: e.key, child: Text(e.value)),
              ],
              onChanged: (v) => v == null ? null : _set(() => CloudScraper.browser = v),
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
              onChanged: (v) => v == null ? null : _set(() => CloudScraper.platform = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SelectableText(CloudScraper.userAgent, style: small),
          ),
          const Divider(),
          ListTile(
            title: const Text('Số lần thử lại'),
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
            title: Text('Chờ trước khi thử lại: ${(CloudScraper.delayMs / 1000).toStringAsFixed(1)} s'),
            subtitle: Slider(
              value: CloudScraper.delayMs.toDouble(),
              min: 0,
              max: 10000,
              divisions: 20,
              onChanged: (v) => _set(() => CloudScraper.delayMs = v.round()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.cookie_outlined),
            title: const Text('Xoá cookie Cloudflare đã lưu'),
            subtitle: const Text('Dùng khi một trang bị kẹt ở bước xác minh'),
            onTap: () async {
              await settingsRepository.update((s) => s.cookiesList = []);
              try {
                await CookieManager.instance().deleteAllCookies();
              } catch (_) {}
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xoá cookie')),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Thử thách JavaScript cũ của Cloudflare được giải như cloudscraper; thử thách mới '
              '(Turnstile, "Managed Challenge") cần nhân trình duyệt hoặc FlareSolverr/Byparr. '
              'Nếu vẫn bị chặn, mở trang trong WebView của tiện ích và xác minh thủ công.',
              style: small,
            ),
          ),
        ],
      ),
    );
  }
}
