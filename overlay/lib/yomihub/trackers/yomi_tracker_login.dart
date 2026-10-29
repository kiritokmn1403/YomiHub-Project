import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mangayomi/models/track_preference.dart';
import 'package:mangayomi/modules/more/settings/track/widgets/track_listile.dart';
import 'package:mangayomi/yomihub/trackers/yomi_trackers.dart';
import 'package:url_launcher/url_launcher.dart';

/// Login tiles for the YomiHub trackers, shown under the Mangayomi ones in
/// Settings › Tracking.
List<Widget> yomiTrackerTiles(
  BuildContext context,
  WidgetRef ref,
  List<TrackPreference> entries,
) {
  return [
    TrackListile(
      id: YomiTrackerIds.mangaUpdates,
      entries: entries,
      onTap: () => _form(
        context,
        title: 'MangaUpdates',
        fields: [
          _F('user', tr('Tên đăng nhập')),
          _F('pass', tr('Mật khẩu'), secret: true),
        ],
        submit: (v) => MangaUpdatesTracker.login(v['user']!, v['pass']!),
      ),
    ),
    TrackListile(
      id: YomiTrackerIds.shikimori,
      entries: entries,
      onTap: () => _shikimori(context),
    ),
    TrackListile(
      id: YomiTrackerIds.bangumi,
      entries: entries,
      onTap: () => _form(
        context,
        title: 'Bangumi',
        help:
            tr('Tạo "Access Token" tại next.bgm.tv/demo/access-token rồi dán vào đây.'),
        link: 'https://next.bgm.tv/demo/access-token',
        fields: const [_F('token', 'Access Token', secret: true)],
        submit: (v) => BangumiTracker.login(v['token']!),
      ),
    ),
    TrackListile(
      id: YomiTrackerIds.kavita,
      entries: entries,
      onTap: () => _form(
        context,
        title: 'Kavita',
        help:
            tr('Địa chỉ máy chủ Kavita (hoặc link OPDS) và API key (Kavita › Cài đặt người dùng › 3rd Party Clients).'),
        fields: [
          _F('url', 'https://kavita.example.com'),
          _F('key', tr('API key (bỏ trống nếu dán link OPDS)'), secret: true),
        ],
        submit: (v) => KavitaTracker.login(v['url']!, v['key']!),
      ),
    ),
    TrackListile(
      id: YomiTrackerIds.suwayomi,
      entries: entries,
      onTap: () => _form(
        context,
        title: 'Suwayomi',
        help: tr('Địa chỉ Suwayomi-Server; tài khoản chỉ cần khi bật Basic Auth.'),
        fields: [
          _F('url', 'http://192.168.1.10:4567'),
          _F('user', tr('Tài khoản (tuỳ chọn)'), optional: true),
          _F('pass', tr('Mật khẩu (tuỳ chọn)'), secret: true, optional: true),
        ],
        submit: (v) =>
            SuwayomiTracker.login(v['url']!, v['user'] ?? '', v['pass'] ?? ''),
      ),
    ),
  ];
}

class _F {
  final String key;
  final String hint;
  final bool secret;
  final bool optional;
  const _F(this.key, this.hint, {this.secret = false, this.optional = false});
}

Future<void> _form(
  BuildContext context, {
  required String title,
  required List<_F> fields,
  required Future<String?> Function(Map<String, String>) submit,
  String? help,
  String? link,
}) async {
  final ctrls = {for (final f in fields) f.key: TextEditingController()};
  String? error;
  var busy = false;
  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) => AlertDialog(
        title: Text(tr('Đăng nhập {p0}', {'p0': title})),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (help != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(help, style: const TextStyle(fontSize: 12)),
                ),
              if (link != null)
                TextButton.icon(
                  onPressed: () => launchUrl(
                    Uri.parse(link),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: Text(tr('Mở trang lấy mã')),
                ),
              for (final f in fields)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: TextField(
                    controller: ctrls[f.key],
                    obscureText: f.secret,
                    decoration: InputDecoration(
                      hintText: f.hint,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              if (error != null)
                Text(error!, style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('Huỷ')),
          ),
          FilledButton(
            onPressed: busy
                ? null
                : () async {
                    final values = {
                      for (final f in fields) f.key: ctrls[f.key]!.text.trim(),
                    };
                    final missing = fields.any(
                      (f) => !f.optional && values[f.key]!.isEmpty,
                    );
                    if (missing &&
                        !(title == 'Kavita' &&
                            values['url']!.contains('/api/opds/'))) {
                      setD(() => error = tr('Hãy điền đủ thông tin'));
                      return;
                    }
                    setD(() {
                      busy = true;
                      error = null;
                    });
                    final err = await submit(values);
                    if (err == null) {
                      if (ctx.mounted) Navigator.pop(ctx);
                    } else {
                      setD(() {
                        busy = false;
                        error = err;
                      });
                    }
                  },
            child: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(tr('Đăng nhập')),
          ),
        ],
      ),
    ),
  );
}

Future<void> _shikimori(BuildContext context) async {
  final id = TextEditingController();
  final secret = TextEditingController();
  final code = TextEditingController();
  String? error;
  var busy = false;
  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) => AlertDialog(
        title: Text(tr('Đăng nhập Shikimori')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('1. Tạo ứng dụng tại shikimori.one/oauth/applications với Redirect URI: urn:ietf:wg:oauth:2.0:oob\n2. Dán Client ID và Client Secret.\n3. Bấm "Lấy mã", cho phép, rồi dán mã vào ô cuối.'),
                style: TextStyle(fontSize: 12),
              ),
              TextButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse('${ShikimoriTracker.base}/oauth/applications'),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: Text(tr('Tạo ứng dụng')),
              ),
              TextField(
                controller: id,
                decoration: const InputDecoration(
                  hintText: 'Client ID',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: secret,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Client Secret',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  if (id.text.trim().isEmpty) {
                    setD(() => error = tr('Nhập Client ID trước'));
                    return;
                  }
                  launchUrl(
                    ShikimoriTracker.authorizeUrl(id.text.trim()),
                    mode: LaunchMode.externalApplication,
                  );
                },
                icon: const Icon(Icons.key, size: 16),
                label: Text(tr('Lấy mã')),
              ),
              TextField(
                controller: code,
                decoration: InputDecoration(
                  hintText: tr('Mã xác nhận'),
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(error!, style: const TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('Huỷ')),
          ),
          FilledButton(
            onPressed: busy
                ? null
                : () async {
                    if (id.text.trim().isEmpty ||
                        secret.text.trim().isEmpty ||
                        code.text.trim().isEmpty) {
                      setD(() => error = tr('Hãy điền đủ 3 ô'));
                      return;
                    }
                    setD(() => busy = true);
                    final err = await ShikimoriTracker.login(
                      id.text.trim(),
                      secret.text.trim(),
                      code.text.trim(),
                    );
                    if (err == null) {
                      if (ctx.mounted) Navigator.pop(ctx);
                    } else {
                      setD(() {
                        busy = false;
                        error = err;
                      });
                    }
                  },
            child: Text(tr('Đăng nhập')),
          ),
        ],
      ),
    ),
  );
}
