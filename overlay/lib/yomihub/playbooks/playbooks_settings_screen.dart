import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mangayomi/modules/more/settings/reader/providers/reader_state_provider.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';
import 'package:mangayomi/yomihub/playbooks/playbooks_toggle.dart';
import 'package:url_launcher/url_launcher.dart';

class PlayBooksSettingsScreen extends ConsumerStatefulWidget {
  const PlayBooksSettingsScreen({super.key});

  @override
  ConsumerState<PlayBooksSettingsScreen> createState() => _PlayBooksSettingsScreenState();
}

class _PlayBooksSettingsScreenState extends ConsumerState<PlayBooksSettingsScreen> {
  static const List<Map<String, String>> playBooksProjects = [
    {
      'name': 'Google-Play-Books-Desktop',
      'author': 'TheLox95',
      'url': 'https://github.com/TheLox95/Google-Play-Books-Desktop',
      'desc': 'Trình đọc sách Google Play Books độc lập đa nền tảng',
    },
    {
      'name': 'openshelf',
      'author': 'SanHsien',
      'url': 'https://github.com/SanHsien/openshelf',
      'desc': 'Thư viện sách mở tương thích kệ sách Google Play Books',
    },
    {
      'name': 'Stop-reading-from-Google-Books',
      'author': 'seanpm2001',
      'url': 'https://github.com/seanpm2001/Stop-reading-from-Google-Books',
      'desc': 'Công cụ trích xuất và đồng bộ tiến độ đọc sách cá nhân',
    },
    {
      'name': 'highlights-convert',
      'author': 't27',
      'url': 'https://github.com/t27/highlights-convert',
      'desc': 'Chuyển đổi và xuất các trích dẫn, đánh dấu từ Play Books',
    },
    {
      'name': 'ABC (Audiobook & Book Client)',
      'author': 'TwoSolutions',
      'url': 'https://github.com/TwoSolutions/ABC',
      'desc': 'Trình đọc và phát sách nói thông minh đồng bộ đám mây',
    },
    {
      'name': 'google-play-books',
      'author': 'murazor97dicaprio',
      'url': 'https://github.com/murazor97dicaprio/google-play-books',
      'desc': 'Giao diện đọc sách phong cách Material 3 của Google',
    },
    {
      'name': 'Playbook-Analytics',
      'author': 'Brandon123b',
      'url': 'https://github.com/Brandon123b/Playbook-Analytics',
      'desc': 'Thống kê thời lượng và thói quen đọc sách',
    },
    {
      'name': 'yomirin',
      'author': 'yukik8',
      'url': 'https://github.com/yukik8/yomirin',
      'desc': 'Tích hợp từ điển tra từ trực tiếp trong trình đọc sách',
    },
    {
      'name': 'google-play-books',
      'author': 'smokehost24k',
      'url': 'https://github.com/smokehost24k/google-play-books',
      'desc': 'Trình hiển thị sách web mượt mà cho thiết bị di động',
    },
    {
      'name': 'play-books-frankenstein',
      'author': 'crxssed7',
      'url': 'https://github.com/crxssed7/play-books-frankenstein',
      'desc': 'Tùy biến bộ khung đọc và trích xuất sách',
    },
    {
      'name': 'google-play-books-downloader',
      'author': '1905',
      'url': 'https://github.com/1905/google-play-books-downloader',
      'desc': 'Tải tệp EPUB / PDF từ thư viện Play Books',
    },
    {
      'name': 'FewType',
      'author': 'Ray1979ANYWAY',
      'url': 'https://github.com/Ray1979ANYWAY/FewType',
      'desc': 'Kiểu chữ và dàn trang công thái học cho sách điện tử',
    },
    {
      'name': 'Adaptive-Theme',
      'author': 'xLexip',
      'url': 'https://github.com/xLexip/Adaptive-Theme',
      'desc': 'Tự động thích ứng màu sắc nền trang theo ánh sáng xung quanh',
    },
    {
      'name': 'playbook-android-reader',
      'author': 'laduygaga',
      'url': 'https://github.com/laduygaga/playbook-android-reader',
      'desc': 'Bộ dựng đọc sách Android Play Books tối ưu hóa cho màn hình cảm ứng',
    },
    {
      'name': 'google-playbook',
      'author': 'bradlegge',
      'url': 'https://github.com/bradlegge/google-playbook',
      'desc': 'API kết nối kệ sách và danh mục yêu thích',
    },
    {
      'name': 'books',
      'author': 'liyasthomas',
      'url': 'https://github.com/liyasthomas/books',
      'desc': 'Giao diện khám phá sách hiện đại, tối giản',
    },
    {
      'name': 'Google Books API Client',
      'author': 'Google Developers',
      'url': 'https://developers.google.com/books?hl=vi',
      'desc': 'API chính thức tìm kiếm thông tin và xem trước sách Google Books',
    },
    {
      'name': 'google-play-book-downloader',
      'author': 'devnoname120',
      'url': 'https://github.com/devnoname120/google-play-book-downloader',
      'desc': 'Công cụ hỗ trợ tải về và sao lưu sách ngoại tuyến',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hidden = ref.watch(hideItemsStateProvider);
    final enabled = YomiPlayBooks.enabled && !hidden.contains(YomiPlayBooks.route);
    final desktopMode = YomiPrefs.get<bool>('playBooksDesktop', true);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Cài đặt Google Play Books')),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.withValues(alpha: 0.15),
                  Colors.lightBlueAccent.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.blue.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_stories_rounded, color: Colors.blue, size: 32),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Google Play Books',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tr('Tích hợp đầy đủ trình đọc Google Play Books cùng toàn bộ hệ sinh thái dự án mở liên quan.'),
                        style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          SwitchListTile(
            secondary: const Icon(Icons.power_settings_new_rounded, color: Colors.blue),
            title: Text(tr('Kích hoạt Google Play Books')),
            subtitle: Text(enabled
                ? tr('Đang bật – hiển thị tab Play Books trên thanh điều hướng')
                : tr('Đang tắt – ẩn toàn bộ chức năng Google Play Books')),
            value: enabled,
            onChanged: (v) async {
              await YomiPrefs.set('playBooksEnabled', v);
              final list = [...ref.read(hideItemsStateProvider)]..remove(YomiPlayBooks.route);
              if (!v) list.add(YomiPlayBooks.route);
              ref.read(hideItemsStateProvider.notifier).set(list);
              setState(() {});
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.desktop_windows_outlined, color: Colors.indigoAccent),
            title: Text(tr('Chế độ trình đọc máy tính (Desktop Reader)')),
            subtitle: Text(tr('Tải giao diện web đầy đủ hỗ trợ highlights, ghi chú và định dạng phong phú')),
            value: desktopMode,
            onChanged: (v) async {
              await YomiPrefs.set('playBooksDesktop', v);
              setState(() {});
            },
          ),
          const Divider(),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.code_rounded, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Text(
                  tr('Dự án GitHub Google Play Books đã tích hợp ({p0})', {'p0': '${playBooksProjects.length}'}),
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: cs.primary),
                ),
              ],
            ),
          ),

          ...playBooksProjects.map((p) {
            return Card(
              elevation: 0,
              color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                dense: true,
                title: Text('${p['name']} • ${p['author']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p['desc'] ?? '', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                    Text(p['url'] ?? '', style: const TextStyle(fontSize: 10, color: Colors.blueAccent)),
                  ],
                ),
                trailing: const Icon(Icons.open_in_new_rounded, size: 16),
                onTap: () async {
                  final u = Uri.tryParse(p['url'] ?? '');
                  if (u != null) await launchUrl(u, mode: LaunchMode.externalApplication);
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
