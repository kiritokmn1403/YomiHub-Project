import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mangayomi/l10n/generated/app_localizations.dart';
import 'package:mangayomi/repositories/source_repository.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/modules/more/settings/reader/providers/reader_state_provider.dart';
import 'package:mangayomi/providers/l10n_providers.dart';
import 'package:mangayomi/providers/storage_provider.dart';
import 'package:mangayomi/modules/browse/extension/extension_screen.dart';
import 'package:mangayomi/modules/browse/sources/sources_screen.dart';
import 'package:mangayomi/modules/widgets/tv_row_button.dart';
import 'package:mangayomi/modules/main_view/providers/tv_mode_provider.dart';
import 'package:mangayomi/modules/library/widgets/search_text_form_field.dart';
import 'package:mangayomi/modules/widgets/tv_pill.dart';
import 'package:mangayomi/services/fetch_sources_list.dart';
import 'package:mangayomi/utils/platform_utils.dart';
import 'package:mangayomi/modules/browse/providers/browse_initial_tab_provider.dart';
import 'package:mangayomi/modules/more/settings/browse/providers/browse_state_provider.dart';
import 'package:mangayomi/yomihub/browse/yomi_suggestions.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';

class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key});

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

enum BrowseTabKind { sources, extensions }

class BrowseTab {
  final ItemType type;
  final BrowseTabKind kind;

  const BrowseTab(this.type, this.kind);
}

class _BrowseScreenState extends ConsumerState<BrowseScreen>
    with TickerProviderStateMixin {
  late final hideItems = ref.read(hideItemsStateProvider);
  final _textEditingController = TextEditingController();

  /// Which TV list row currently holds focus, so the rest of the list can
  /// fade back while one is active. Lives here so both the sources and the
  /// extensions tab share it.
  final _tvActiveRow = ValueNotifier<Object?>(null);
  late TabController _tabBarController;
  late List<BrowseTab> _tabList;

  /// YomiHub 0.1.8: Browse has one tab per category ("Comic Setting
  /// Extension", "Film & Movie Setting Extension", "Novel Setting
  /// Extension"); each holds Sources, Extensions and Suggestions.
  /// [_tabList] keeps the old (type, kind) list so the rest of the app can
  /// still ask for "the anime extensions tab".
  late List<ItemType> _types;
  final Map<ItemType, int> _segment = {};
  static const _segSources = 0, _segExtensions = 1, _segSuggest = 2;

  List<ItemType> _typesOf(List<BrowseTab> tabs) {
    final out = <ItemType>[];
    for (final t in tabs) {
      if (!out.contains(t.type)) out.add(t.type);
    }
    return out;
  }

  BrowseTab get _currentTab {
    final type = _types[_tabBarController.index.clamp(0, _types.length - 1)];
    final seg = _segment[type] ?? _segSources;
    return BrowseTab(
      type,
      seg == _segExtensions ? BrowseTabKind.extensions : BrowseTabKind.sources,
    );
  }

  /// Opens the category of [tab] and its Sources / Extensions part.
  void _openTab(BrowseTab tab) {
    final i = _types.indexOf(tab.type);
    if (i < 0) return;
    setState(() {
      _segment[tab.type] = tab.kind == BrowseTabKind.extensions
          ? _segExtensions
          : _segSources;
      _isSearch = false;
      _textEditingController.clear();
    });
    _tabBarController.animateTo(i);
  }

  // Hide manga & novel from Browse (sources + extensions) on the anime-only TV
  // layout so only anime shows. Recomputed live so toggling "Anime only" updates
  // the tabs without a restart. Defaults to isTv, user-overridable. See #729.
  List<BrowseTab> _computeTabList(bool animeOnly) => [
    if (!animeOnly && !hideItems.contains("/MangaLibrary"))
      BrowseTab(ItemType.manga, BrowseTabKind.sources),
    if (!hideItems.contains("/AnimeLibrary"))
      BrowseTab(ItemType.anime, BrowseTabKind.sources),
    if (!animeOnly && !hideItems.contains("/NovelLibrary"))
      BrowseTab(ItemType.novel, BrowseTabKind.sources),
    if (!animeOnly && !hideItems.contains("/MangaLibrary"))
      BrowseTab(ItemType.manga, BrowseTabKind.extensions),
    if (!hideItems.contains("/AnimeLibrary"))
      BrowseTab(ItemType.anime, BrowseTabKind.extensions),
    if (!animeOnly && !hideItems.contains("/NovelLibrary"))
      BrowseTab(ItemType.novel, BrowseTabKind.extensions),
  ];

  @override
  void initState() {
    super.initState();
    _tabList = _computeTabList(ref.read(animeOnlyTvModeProvider));
    _types = _typesOf(_tabList);
    _tabBarController = TabController(
      length: _types.length,
      initialIndex: _takeRequestedTabIndex(),
      vsync: this,
    );
    _tabBarController.addListener(_onTabChanged);
  }

  /// The index of the tab somebody asked us to open on, or zero.
  ///
  /// The request is cleared after this frame rather than as it is read.
  /// Riverpod counts initState as part of the build and throws on a write
  /// there, which took the whole Browse screen down.
  int _takeRequestedTabIndex() {
    final requested = ref.read(browseInitialTabProvider);
    if (requested == null) return 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(browseInitialTabProvider.notifier).clear();
    });
    final index = _types.indexOf(requested.type);
    if (index >= 0) {
      _segment[requested.type] = requested.kind == BrowseTabKind.extensions
          ? _segExtensions
          : _segSources;
    }
    return index < 0 ? 0 : index;
  }

  void _onTabChanged() {
    _chekPermission();
    setState(() {
      _textEditingController.clear();
      _isSearch = false;
    });
  }

  Future<void> _chekPermission() async {
    await StorageProvider().requestPermission();
  }

  @override
  void dispose() {
    _tvActiveRow.dispose();
    _tabBarController.dispose();
    _textEditingController.dispose();
    super.dispose();
  }

  bool _isSearch = false;

  /// The top-bar action icons, which differ per tab (see #729): Sources =
  /// global-search + filter; Extensions = add + search + language filter.
  List<Widget> _actions(
    BuildContext context,
    bool isExtensionTab,
    ItemType tabType,
  ) {
    return [
      _isSearch
          ? SeachFormTextField(
              onChanged: (value) {
                setState(() {});
              },
              onSuffixPressed: () {
                _textEditingController.clear();
                setState(() {});
              },
              onPressed: () {
                setState(() {
                  _isSearch = false;
                });
                _textEditingController.clear();
              },
              controller: _textEditingController,
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isExtensionTab && ref.watch(developerModeStateProvider))
                  IconButton(
                    focusColor: Theme.of(context).colorScheme.primary
                        .withValues(alpha: 0.4),
                    onPressed: () {
                      context.push('/createExtension');
                    },
                    icon: Icon(
                      Icons.add_outlined,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                IconButton(
                  splashRadius: 20,
                  focusColor: Theme.of(context).colorScheme.primary
                      .withValues(alpha: 0.4),
                  onPressed: () {
                    if (isExtensionTab) {
                      setState(() {
                        _isSearch = true;
                      });
                    } else {
                      context.push('/globalSearch', extra: (null, tabType));
                    }
                  },
                  icon: Icon(
                    !isExtensionTab
                        ? Icons.travel_explore_rounded
                        : Icons.search_rounded,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
            ),
      IconButton(
        splashRadius: 20,
        focusColor: Theme.of(context).colorScheme.primary
            .withValues(alpha: 0.4),
        onPressed: () {
          context.push(
            isExtensionTab ? '/ExtensionLang' : '/sourceFilter',
            extra: tabType,
          );
        },
        icon: Icon(
          !isExtensionTab ? Icons.filter_list_sharp : Icons.translate_rounded,
          color: Theme.of(context).hintColor,
        ),
      ),
    ];
  }

  Widget _view(ItemType type, int seg) {
    switch (seg) {
      case _segExtensions:
        return ExtensionScreen(
          query: _textEditingController.text,
          itemType: type,
        );
      case _segSuggest:
        return YomiSuggestionsView(
          itemType: type,
          onOpenExtensions: () => setState(() => _segment[type] = _segExtensions),
        );
      default:
        return SourcesScreen(
          itemType: type,
          tabs: _tabList,
          tabIndex: (index) {
            if (index >= 0 && index < _tabList.length) _openTab(_tabList[index]);
          },
        );
    }
  }

  List<Widget> _tabViews() => _types.map((type) {
    final seg = _segment[type] ?? _segSources;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: _segSources,
                  icon: const Icon(Icons.explore_outlined, size: 18),
                  label: Text(tr('Nguồn')),
                ),
                ButtonSegment(
                  value: _segExtensions,
                  icon: const Icon(Icons.extension_outlined, size: 18),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(tr('Tiện ích')),
                      const SizedBox(width: 4),
                      ExtensionUpdateNumbersBadge(itemType: type),
                    ],
                  ),
                ),
                ButtonSegment(
                  value: _segSuggest,
                  icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                  label: Text(tr('Đề xuất')),
                ),
              ],
              selected: {seg},
              onSelectionChanged: (v) => setState(() {
                _segment[type] = v.first;
                _isSearch = false;
                _textEditingController.clear();
              }),
            ),
          ),
        ),
        Expanded(
          child: KeyedSubtree(key: ValueKey('$type$seg'), child: _view(type, seg)),
        ),
      ],
    );
  }).toList();

  // YomiHub 0.2.1: translated as a whole phrase (was "<type> Setting
  // Extension" in English for every language).
  String _categoryTitle(ItemType type, AppLocalizations l10n) =>
      YomiTr.sectionSetting(switch (type) {
        ItemType.manga => 0,
        ItemType.anime => 1,
        ItemType.novel => 2,
      });

  // Android TV Browse: pill tabs (matching the home) + a top-bar focus ladder
  // (icons -> pills -> list) so nothing steals focus on Up. See #729.
  Widget _buildTvLayout(
    BuildContext context,
    BrowseTab currentTab,
    bool isExtensionTab,
    AppLocalizations l10n,
  ) {
    return DefaultTabController(
      animationDuration: Duration.zero,
      length: _types.length,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
                child: Row(
                  children: [
                    Text(
                      l10n.browse,
                      style: TextStyle(
                        color: Theme.of(context).hintColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    ..._actions(context, isExtensionTab, currentTab.type),
                  ],
                ),
              ),
              // Pills centred on screen, matching the home category filter.
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < _types.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        TvPill(
                          label: _categoryTitle(_types[i], l10n),
                          selected: i == _tabBarController.index,
                          onTap: () {
                            _tabBarController.animateTo(i);
                            setState(() {});
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Expanded(
                child: TvRowFocusScope(
                  notifier: _tvActiveRow,
                  child: TabBarView(
                    controller: _tabBarController,
                    children: _tabViews(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Recompute the tab list live when "Anime only" flips; recreate the
    // controller when the tab count changes.
    final newTabs = _computeTabList(ref.watch(animeOnlyTvModeProvider));
    final newTypes = _typesOf(newTabs);
    _tabList = newTabs;
    if (newTypes.length != _types.length) {
      _types = newTypes;
      _tabBarController.removeListener(_onTabChanged);
      _tabBarController.dispose();
      _tabBarController = TabController(length: _types.length, vsync: this);
      _tabBarController.addListener(_onTabChanged);
    } else {
      _types = newTypes;
    }
    if (_types.isEmpty) {
      return SizedBox.shrink();
    }
    final currentTab = _currentTab;
    final isExtensionTab = currentTab.kind == BrowseTabKind.extensions;

    final l10n = l10nLocalizations(context)!;
    if (isTv) {
      return _buildTvLayout(context, currentTab, isExtensionTab, l10n);
    }
    return DefaultTabController(
      animationDuration: Duration.zero,
      length: _types.length,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          title: Text(
            l10n.browse,
            style: TextStyle(color: Theme.of(context).hintColor),
          ),
          actions: _actions(context, isExtensionTab, currentTab.type),
          bottom: TabBar(
            indicatorSize: TabBarIndicatorSize.label,
            isScrollable: true,
            controller: _tabBarController,
            tabs: _types.map((type) {
              return Tab(
                child: Row(
                  children: [
                    Text(_categoryTitle(type, l10n)),
                    const SizedBox(width: 8),
                    ExtensionUpdateNumbersBadge(itemType: type),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        body: TabBarView(controller: _tabBarController, children: _tabViews()),
      ),
    );
  }
}

final extensionUpdateCountProvider = StreamProvider.family<int, ItemType>((
  ref,
  itemType,
) {
  return sourceRepository
      .watchActiveByItemType(itemType)
      .map(
        (list) => list
            .where(
              (element) =>
                  (element.isAdded ?? false) &&
                  !(element.isObsolete ?? false) &&
                  compareVersions(
                    element.version ?? '',
                    element.versionLast ?? '',
                  ) <
                  0,
            )
            .length,
      );
});

class ExtensionUpdateNumbersBadge extends ConsumerWidget {
  final ItemType itemType;
  const ExtensionUpdateNumbersBadge({required this.itemType, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(extensionUpdateCountProvider(itemType));
    return countAsync.when(
      data: (count) {
        if (count == 0) return const SizedBox.shrink();
        return Badge(
          backgroundColor: Theme.of(context).focusColor,
          label: Text(
            count.toString(),
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall!.color,
            ),
          ),
        );
      },
      error: (error, stackTrace) => const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
    );
  }
}
