import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/models/settings.dart';
import 'package:mangayomi/modules/more/settings/browse/providers/browse_state_provider.dart';
import 'package:mangayomi/modules/more/settings/browse/source_repositories.dart';
import 'package:mangayomi/modules/more/settings/reader/providers/reader_state_provider.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:mangayomi/yomihub/repos/extensions_repo_screen.dart';
import 'package:mangayomi/yomihub/ui/liquid_glass.dart';

/// Screen allowing users to toggle features and extension repositories
/// for Comic (Manga), Film & Movie (Anime), and Novel.
class FeatureToggleScreen extends ConsumerWidget {
  const FeatureToggleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hideItems = ref.watch(hideItemsStateProvider);

    const mangaRoute = '/MangaLibrary';
    const animeRoute = '/AnimeLibrary';
    const novelRoute = '/NovelLibrary';

    bool isFeatureOn(String route) {
      final lower = route.toLowerCase();
      return !hideItems.any((h) => h.toLowerCase() == lower);
    }

    final comicFeatureOn = isFeatureOn(mangaRoute);
    final animeFeatureOn = isFeatureOn(animeRoute);
    final novelFeatureOn = isFeatureOn(novelRoute);

    final comicRepos = ref.watch(extensionsRepoStateProvider(ItemType.manga));
    final animeRepos = ref.watch(extensionsRepoStateProvider(ItemType.anime));
    final novelRepos = ref.watch(extensionsRepoStateProvider(ItemType.novel));

    final comicReposActive = comicRepos.isNotEmpty && comicRepos.any((r) => r.hidden != true);
    final animeReposActive = animeRepos.isNotEmpty && animeRepos.any((r) => r.hidden != true);
    final novelReposActive = novelRepos.isNotEmpty && novelRepos.any((r) => r.hidden != true);

    void toggleFeature(String canonicalRoute, bool enable) {
      final list = hideItems.toList();
      final lower = canonicalRoute.toLowerCase();
      list.removeWhere((item) => item.toLowerCase() == lower);
      if (!enable) {
        list.add(canonicalRoute);
      }
      ref.read(hideItemsStateProvider.notifier).set(list);
    }

    Future<void> toggleAllRepos(ItemType type, bool enable) async {
      final current = ref.read(extensionsRepoStateProvider(type));
      if (current.isEmpty) return;
      final updated = current.map((r) {
        r.hidden = !enable;
        return r;
      }).toList();
      await ref.read(extensionsRepoStateProvider(type).notifier).set(updated);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Bật/Tắt tính năng & Nguồn mở rộng')),
      ),
      body: LiquidGlassBackdrop(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // --- COMIC SECTION ---
            _buildSectionHeader(
              context,
              icon: Icons.collections_bookmark_outlined,
              title: YomiTr.term(0),
              color: Colors.blueAccent,
            ),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.menu_book),
                    title: Text(tr('Tính năng Comic')),
                    subtitle: Text(tr('Thư viện truyện tranh, lịch sử đọc và trình đọc truyện')),
                    value: comicFeatureOn,
                    onChanged: (val) => toggleFeature(mangaRoute, val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.extension_outlined),
                    title: Text(tr('Nguồn mở rộng Comic')),
                    subtitle: Text(
                      comicRepos.isEmpty
                          ? tr('Chưa thêm kho tiện ích Comic')
                          : tr('{p0} kho đang bật / {p1} tổng số', {
                              'p0': comicRepos.where((r) => r.hidden != true).length.toString(),
                              'p1': comicRepos.length.toString(),
                            }),
                    ),
                    value: comicReposActive,
                    onChanged: comicRepos.isEmpty ? null : (val) => toggleAllRepos(ItemType.manga, val),
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: Text(tr('Quản lý danh sách kho Comic')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SourceRepositories(itemType: ItemType.manga),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- FILM & MOVIE SECTION ---
            _buildSectionHeader(
              context,
              icon: Icons.movie_outlined,
              title: YomiTr.term(1),
              color: Colors.orangeAccent,
            ),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.play_circle_fill_outlined),
                    title: Text(tr('Tính năng Film & Movie')),
                    subtitle: Text(tr('Thư viện phim ảnh, anime, danh sách xem và trình phát video')),
                    value: animeFeatureOn,
                    onChanged: (val) => toggleFeature(animeRoute, val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.extension_outlined),
                    title: Text(tr('Nguồn mở rộng Film & Movie')),
                    subtitle: Text(
                      animeRepos.isEmpty
                          ? tr('Chưa thêm kho tiện ích Film & Movie')
                          : tr('{p0} kho đang bật / {p1} tổng số', {
                              'p0': animeRepos.where((r) => r.hidden != true).length.toString(),
                              'p1': animeRepos.length.toString(),
                            }),
                    ),
                    value: animeReposActive,
                    onChanged: animeRepos.isEmpty ? null : (val) => toggleAllRepos(ItemType.anime, val),
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: Text(tr('Quản lý danh sách kho Film & Movie')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SourceRepositories(itemType: ItemType.anime),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- NOVEL SECTION ---
            _buildSectionHeader(
              context,
              icon: Icons.auto_stories_outlined,
              title: YomiTr.term(2),
              color: Colors.greenAccent,
            ),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.import_contacts_outlined),
                    title: Text(tr('Tính năng Novel')),
                    subtitle: Text(tr('Thư viện tiểu thuyết, light novel và trình đọc text')),
                    value: novelFeatureOn,
                    onChanged: (val) => toggleFeature(novelRoute, val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.extension_outlined),
                    title: Text(tr('Nguồn mở rộng Novel')),
                    subtitle: Text(
                      novelRepos.isEmpty
                          ? tr('Chưa thêm kho tiện ích Novel')
                          : tr('{p0} kho đang bật / {p1} tổng số', {
                              'p0': novelRepos.where((r) => r.hidden != true).length.toString(),
                              'p1': novelRepos.length.toString(),
                            }),
                    ),
                    value: novelReposActive,
                    onChanged: novelRepos.isEmpty ? null : (val) => toggleAllRepos(ItemType.novel, val),
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: Text(tr('Quản lý danh sách kho Novel')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SourceRepositories(itemType: ItemType.novel),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- QUICK SHORTCUTS ---
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.hub_outlined),
                    title: Text(tr('Tất cả kho nguồn tiện ích (Extensions Repo)')),
                    subtitle: Text(tr('Xem và quản lý tất cả kho nguồn tiện ích tập trung')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ExtensionsRepoScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.sort_rounded),
                    title: Text(tr('Tùy chỉnh thứ tự thanh điều hướng')),
                    subtitle: Text(tr('Sắp xếp và ẩn/hiện các tab trên thanh điều hướng chính')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/customNavigationSettings'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

