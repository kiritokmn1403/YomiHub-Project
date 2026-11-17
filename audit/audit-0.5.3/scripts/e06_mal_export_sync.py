import sys,os; sys.path.insert(0,os.path.expanduser('~/mnt/A.I Project - YomiHub Project/YomiHub-Project/audit-0.5.3')); from edit import edit
K='lib/modules/more/settings/track/track.dart'
edit(K,"""                ListTileWidget(
                  title: l10n.manage_trackers,
                  icon: Icons.settings,
                  onTap: () => context.push('/manageTrackers'),
                ),""","""                ListTileWidget(
                  title: l10n.manage_trackers,
                  icon: Icons.settings,
                  onTap: () => context.push('/manageTrackers'),
                ),
                // 0.5.3 (Tankobun / AnymeX): export the tracked lists in the
                // MyAnimeList XML format (MyAnimeList + AniList via idMal)
                ListTileWidget(
                  title: tr('Xuất danh sách MyAnimeList (XML)'),
                  subtitle: tr('Truyện/phim đang theo dõi trên MyAnimeList và AniList → tệp XML nhập được vào MyAnimeList, AnymeX, Taiga'),
                  icon: Icons.ios_share,
                  onTap: () async {
                    BotToast.showText(text: tr('Đang xuất danh sách…'));
                    try {
                      final r = await YomiMalExport.run();
                      BotToast.showText(text: '${tr('Đã xuất')}: $r', duration: const Duration(seconds: 8));
                    } catch (e) {
                      BotToast.showText(text: '${tr('Xuất thất bại')}: $e');
                    }
                  },
                ),""")
edit(K,"import 'package:mangayomi/yomihub/trackers/yomi_tracker_login.dart';\n","import 'package:mangayomi/yomihub/trackers/yomi_tracker_login.dart';\nimport 'package:mangayomi/yomihub/trackers/mal_export.dart';\nimport 'package:bot_toast/bot_toast.dart';\n")
S='lib/modules/more/settings/sync/sync.dart'
edit(S,'  static const serverUrl = "https://github.com/Schnitzel5/mangayomi-server";','  // 0.5.3 (Mangayomi Server, sheet "YomiHub Update" mục 6): the old\n  // Schnitzel5/mangayomi-server is deprecated by its author in favour of the\n  // new sync server.\n  static const serverUrl = "https://github.com/not-akari/mangayomi-sync-server";')
