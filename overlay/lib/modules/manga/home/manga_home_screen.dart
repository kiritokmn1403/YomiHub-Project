import 'package:mangayomi/yomihub/library/source_attribution.dart';
import 'package:mangayomi/yomihub/filters/filter_loader.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mangayomi/eval/model/m_manga.dart';
import 'package:mangayomi/eval/model/m_pages.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/models/settings.dart';
import 'package:mangayomi/models/source.dart';
import 'package:mangayomi/repositories/manga_repository.dart';
import 'package:mangayomi/modules/library/providers/library_state_provider.dart';
import 'package:mangayomi/modules/manga/home/providers/state_provider.dart';
import 'package:mangayomi/yomihub/filters/filter_sheet.dart';
import 'package:mangayomi/yomihub/filters/latest_emulation.dart';
import 'package:mangayomi/yomihub/player/yomi_shorts.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:mangayomi/yomihub/filters/filter_refresh.dart';
import 'package:mangayomi/yomihub/ui/liquid_glass.dart';
import 'package:mangayomi/eval/model/m_bridge.dart' show botToast;
import 'package:mangayomi/modules/widgets/listview_widget.dart';
import 'package:mangayomi/modules/widgets/progress_center.dart';
import 'package:mangayomi/providers/l10n_providers.dart';
import 'package:mangayomi/services/get_filter_list.dart';
import 'package:mangayomi/services/get_latest_updates.dart';
import 'package:mangayomi/services/get_popular.dart';
import 'package:mangayomi/services/get_source_baseurl.dart';
import 'package:mangayomi/modules/manga/home/providers/saved_searches_provider.dart';
import 'package:mangayomi/services/search.dart';
import 'package:mangayomi/services/supports_latest.dart';
import 'package:mangayomi/utils/extensions/build_context_extensions.dart';
import 'package:mangayomi/modules/library/widgets/search_text_form_field.dart';
import 'package:mangayomi/modules/manga/home/widget/mangas_card_selector.dart';
import 'package:mangayomi/modules/widgets/cover_grid_skeleton.dart';
import 'package:mangayomi/modules/widgets/gridview_widget.dart';
import 'package:mangayomi/modules/widgets/manga_image_card_widget.dart';
import 'package:mangayomi/utils/global_style.dart';
import 'package:mangayomi/utils/item_type_localization.dart';
import 'package:marquee/marquee.dart';
import 'package:super_sliver_list/super_sliver_list.dart';
import 'package:mangayomi/modules/widgets/tv_menu.dart';
import 'package:mangayomi/utils/platform_utils.dart';

class MangaHomeScreen extends ConsumerStatefulWidget {
  final Source source;
  final bool isSearch;
  final bool isLatest;
  final String query;
  const MangaHomeScreen({
    required this.source,
    this.query = "",
    this.isSearch = false,
    this.isLatest = false,
    super.key,
  });

  @override
  ConsumerState<MangaHomeScreen> createState() => _MangaHomeScreenState();
}

class TypeMangaSelector {
  final IconData icon;
  final String title;
  TypeMangaSelector(this.icon, this.title);
}

class _MangaHomeScreenState extends ConsumerState<MangaHomeScreen> {
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  int _fullDataLength = 50;
  int _page = 1;
  bool _hasNextPage = true;
  late int _selectedIndex = widget.isLatest
      ? 1
      : widget.isSearch
      ? 2
      : 0;
  late Source source = widget.source;
  late bool isLocal = source.name == "local" && source.lang == "";
  late List<dynamic> filters = isLocal ? [] : getFilterList(source: source);
  final List<MManga> _mangaList = [];
  late StreamSubscription<List<Manga>> _mangaStreamSub;
  Map<String, Manga> _libraryIndex = {};
  List<TypeMangaSelector> _types(BuildContext context) {
    final l10n = l10nLocalizations(context)!;
    return [
      TypeMangaSelector(Icons.favorite, l10n.popular),
      TypeMangaSelector(Icons.new_releases_outlined, l10n.latest),
      TypeMangaSelector(Icons.filter_list_outlined, l10n.filter),
      // YomiHub 0.1.8: vertical Short Video feed (YouTube, FikFap)
      TypeMangaSelector(Icons.smart_display_outlined, 'Short'),
    ];
  }

  Future<MPages?> _loadMore() async {
    MPages? mangaRes;
    if (_isLoading) {
      if (source.isFullData!) {
        await Future.delayed(const Duration(milliseconds: 500));
        _fullDataLength = _fullDataLength + 50;
      } else {
        if (_selectedIndex == 0 && !_isSearch && _query.isEmpty) {
          mangaRes = await ref.read(
            getPopularProvider(source: source, page: _page + 1).future,
          );
        } else if (_selectedIndex == 1 && !_isSearch && _query.isEmpty && !supportsLatest && !_isFiltering) {
          mangaRes = await ref.read(
            getPopularProvider(source: source, page: _page + 1).future,
          );
        } else if (_selectedIndex == 1 && !_isSearch && _query.isEmpty && !_isFiltering) {
          mangaRes = await ref.read(
            getLatestUpdatesProvider(source: source, page: _page + 1).future,
          );
        } else if (_selectedIndex == 2 && (_isSearch && _query.isNotEmpty) ||
            _isFiltering) {
          mangaRes = await ref.read(
            searchProvider(
              source: source,
              query: _query,
              page: _page + 1,
              filterList: filters,
            ).future,
          );
        }
      }
      if (mangaRes!.list.isNotEmpty) {
        if (mounted) {
          setState(() {
            _page = _page + 1;
            _hasNextPage = mangaRes!.hasNextPage;
          });
        }
      }
    }

    return mangaRes;
  }

  @override
  void initState() {
    super.initState();
    // YomiHub: apply this source's default saved filter (Komikku/Nekoyomi).
    if (!isLocal && !widget.isLatest && !widget.isSearch && widget.query.isEmpty) {
      final dp = YomiFilterStore.defaultPreset(source.id ?? 0);
      final loaded = dp == null ? null : YomiFilterStore.loadPreset(source.id ?? 0, dp);
      if (loaded != null) {
        filters = loaded;
        _selectedIndex = 2;
        _isFiltering = true;
      }
    }
    // YomiHub 0.2.1: placeholder filters ("Tap 'Reset' to load filters")
    // are loaded in the background a few seconds after the source opens
    if (!isLocal && YomiFilterRefresh.supports(source) && YomiFilterRefresh.needsLoad(filters)) {
      Future.delayed(const Duration(seconds: 6), () async {
        if (!mounted || !YomiFilterRefresh.needsLoad(filters)) return;
        final fresh = await YomiFilterRefresh.load(source);
        if (fresh != null && mounted && !_isFiltering) {
          setState(() => filters = fresh);
        }
      });
    }
    _scrollController.addListener(_onScroll);
    _mangaStreamSub = mangaRepository
        .watchBySourceAndLang(source.name, source.lang)
        .listen((mangas) {
          if (mounted) {
            setState(() {
              _libraryIndex = {};
              for (final m in mangas.where(
                (e) => e.sourceId == null || e.sourceId == source.id,
              )) {
                if (m.name == null) continue;
                final existing = _libraryIndex[m.name!];
                // Prefer the record with the lower id (first inserted = real entry).
                // Guards against pre-existing duplicate records in the DB.
                if (existing == null || m.id! < existing.id!) {
                  _libraryIndex[m.name!] = m;
                }
              }
            });
          }
        });
  }

  @override
  void dispose() {
    _mangaStreamSub.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _textEditingController.dispose();
    _searchFieldFocus.dispose();
    _postSearchFocus.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (_mangaList.isNotEmpty &&
          _hasNextPage &&
          !_isLoading &&
          !(_getManga?.isLoading ?? false)) {
        setState(() => _isLoading = true);
        _loadMore().then((value) {
          if (mounted && value != null) {
            setState(() {
              _mangaList.addAll(YomiFilterStore.apply(value.list, source, _libraryIndex));
              _isLoading = false;
            });
          }
        });
      }
    }
  }

  void _promptSaveSearch() {
    final query = _query.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.enter_search_to_save_first)),
      );
      return;
    }
    final controller = TextEditingController(text: query);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.save_search),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: context.l10n.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(savedSearchesProvider.notifier)
                  .add(source.id!, controller.text, query);
              Navigator.pop(ctx);
            },
            child: Text(context.l10n.save),
          ),
        ],
      ),
    );
  }

  void _showSavedSearches() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final saved =
              ref.watch(savedSearchesProvider)[source.id] ??
              const <SavedSearch>[];
          if (saved.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                context.l10n.no_saved_searches,
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView(
            shrinkWrap: true,
            children: [
              for (final s in saved)
                ListTile(
                  leading: const Icon(Icons.bookmark_outline),
                  title: Text(s.name),
                  subtitle: Text(
                    s.query,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => ref
                        .read(savedSearchesProvider.notifier)
                        .remove(source.id!, s.name),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _runSavedSearch(s.query);
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  void _runSavedSearch(String query) {
    _mangaList.clear();
    _textEditingController.text = query;
    setState(() {
      _isSearch = true;
      _selectedIndex = 2;
      _query = query;
      _page = 1;
    });
  }

  late final _textEditingController = TextEditingController(text: widget.query);
  // TV search focus flow: opening search puts focus on the field; submitting
  // hands focus to the next button in the row, so it never reverts to Popular /
  // Latest (which, on revert, would re-select and close the search field).
  final _searchFieldFocus = FocusNode();
  final _postSearchFocus = FocusNode();
  late String _query = widget.query;
  late bool _isSearch = widget.isSearch;
  AsyncValue<MPages?>? _getManga;
  int _length = 0;
  bool _isFiltering = false;
  late final supportsLatest = isLocal
      ? true
      : ref.watch(supportsLatestProvider(source: source));
  late final filterList = isLocal ? [] : getFilterList(source: source);
  Future<void> _onSourceOverflow(int value) async {
    if (value == 0) {
      final baseUrl = ref.read(sourceBaseUrlProvider(source: source));
      final data = {
        'url': baseUrl,
        'sourceId': source.id.toString(),
        'title': '',
      };
      if (mounted) context.push("/mangawebview", extra: data);
    } else {
      final res = await context.push('/extension_detail', extra: source);
      if (res != null && mounted) setState(() => source = res as Source);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedIndex == 2 && (_isSearch && _query.isNotEmpty) ||
        _isFiltering) {
      _getManga = ref.watch(
        searchProvider(
          source: source,
          query: _query,
          page: 1,
          filterList: filters,
        ),
      );
    } else if (_selectedIndex == 1 && _query.isEmpty && !supportsLatest) {
      _getManga = ref.watch(getPopularProvider(source: source, page: 1));
    } else if (_selectedIndex == 1 && _query.isEmpty) {
      _getManga = ref.watch(getLatestUpdatesProvider(source: source, page: 1));
    } else if (_selectedIndex == 0 && _query.isEmpty) {
      _getManga = ref.watch(getPopularProvider(source: source, page: 1));
    }
    final l10n = context.l10n;
    final displayType = ref.watch(mangaHomeDisplayTypeStateProvider);
    final displayTypeIcon = switch (displayType) {
      DisplayType.comfortableGrid ||
      DisplayType.compactGrid => Icons.view_module,
      _ => Icons.view_list,
    };
    return Scaffold(
      appBar: AppBar(
        title: _isSearch
            ? null
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    !isLocal
                        ? "${source.name}"
                        : "${context.l10n.local_source} ${source.itemType.localized(context.l10n)}",
                  ),
                  source.notes != null && source.notes!.isNotEmpty
                      ? SizedBox(
                          height: 20,
                          child: Marquee(
                            text: l10n.extension_notes(trNotes(source.notes!)),
                            style: const TextStyle(fontSize: 12),
                            blankSpace: 40.0,
                            velocity: 30.0,
                            pauseAfterRound: const Duration(seconds: 1),
                            startPadding: 10.0,
                          ),
                        )
                      : Container(),
                ],
              ),
        leading: !_isSearch ? null : Container(),
        actions: [
          // YomiHub 0.2.2: this extension's downloaded + local titles
          if (!isLocal && !_isSearch)
            IconButton(
              splashRadius: 20,
              tooltip: tr('Đã tải & cục bộ'),
              icon: Icon(Icons.download_done_outlined, color: Theme.of(context).hintColor),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => YomiSourceOfflineScreen(source: source)),
              ),
            ),
          _isSearch
              ? SeachFormTextField(
                  onFieldSubmitted: (submit) {
                    _mangaList.clear();
                    setState(() {
                      if (submit.isNotEmpty) {
                        _selectedIndex = 2;

                        _query = submit;
                      } else {
                        _selectedIndex = 0;
                      }
                      _page = 1;
                    });
                    // Hand focus to the next button in the row so it never
                    // reverts to Popular / Latest.
                    if (isTv) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) _postSearchFocus.requestFocus();
                      });
                    }
                  },
                  onChanged: (value) {},
                  onSuffixPressed: () {
                    _textEditingController.clear();
                    _mangaList.clear();
                    _query = "";
                    setState(() {});
                  },
                  onPressed: () {
                    setState(() {
                      if (_textEditingController.text.isEmpty) {
                        _isSearch = false;
                        _query = "";
                        _isFiltering = false;
                        _selectedIndex = 0;
                        _page = 1;
                        _textEditingController.clear();
                        _mangaList.clear();
                      } else {
                        Navigator.pop(context);
                      }
                    });
                  },
                  controller: _textEditingController,
                  focusNode: _searchFieldFocus,
                )
              : IconButton(
                  splashRadius: 20,
                  onPressed: () {
                    setState(() {
                      _isSearch = true;
                    });
                    // Force focus onto the field so it doesn't revert to the
                    // previously focused pill while the search button unmounts.
                    if (isTv) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) _searchFieldFocus.requestFocus();
                      });
                    }
                  },
                  focusColor: isTv
                      ? context.primaryColor.withValues(alpha: 0.4)
                      : null,
                  icon: Icon(Icons.search, color: Theme.of(context).hintColor),
                ),
          if (isTv)
            IconButton(
              focusNode: _postSearchFocus,
              focusColor: context.primaryColor.withValues(alpha: 0.4),
              icon: Icon(displayTypeIcon),
              onPressed: () async {
                const order = [
                  DisplayType.comfortableGrid,
                  DisplayType.compactGrid,
                  DisplayType.list,
                ];
                final current = ref.read(mangaHomeDisplayTypeStateProvider);
                final picked = await showTvMenu(
                  context,
                  title: context.l10n.display_mode,
                  options: [
                    TvMenuOption(
                      context.l10n.comfortable_grid,
                      selected: current == DisplayType.comfortableGrid,
                    ),
                    TvMenuOption(
                      context.l10n.compact_grid,
                      selected: current == DisplayType.compactGrid,
                    ),
                    TvMenuOption(
                      context.l10n.list,
                      selected: current == DisplayType.list,
                    ),
                  ],
                );
                if (picked != null) {
                  ref
                      .read(mangaHomeDisplayTypeStateProvider.notifier)
                      .setMangaHomeDisplayType(order[picked]);
                }
              },
            )
          else
            PopupMenuButton(
              popUpAnimationStyle: popupAnimationStyle,
              icon: Icon(displayTypeIcon),
              itemBuilder: (context) {
                final displayType = ref.watch(
                  mangaHomeDisplayTypeStateProvider,
                );
                final displayTypeNotifier = ref.read(
                  mangaHomeDisplayTypeStateProvider.notifier,
                );
                return [
                  PopupMenuItem<int>(
                    value: 0,
                    child: RadioGroup(
                      groupValue: displayType,
                      onChanged: (a) {
                        context.pop();
                        displayTypeNotifier.setMangaHomeDisplayType(a!);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RadioListTile(
                            title: Text(context.l10n.comfortable_grid),
                            value: DisplayType.comfortableGrid,
                          ),
                          RadioListTile(
                            title: Text(context.l10n.compact_grid),
                            value: DisplayType.compactGrid,
                          ),
                          RadioListTile(
                            title: Text(context.l10n.list),
                            value: DisplayType.list,
                          ),
                        ],
                      ),
                    ),
                  ),
                  PopupMenuItem<int>(
                    value: 2,
                    child: Text(context.l10n.save_search),
                  ),
                  PopupMenuItem<int>(
                    value: 3,
                    child: Text(context.l10n.saved_searches),
                  ),
                ];
              },
              onSelected: (value) async {
                if (value == 0) {
                  final baseUrl = ref.watch(
                    sourceBaseUrlProvider(source: source),
                  );
                  Map<String, dynamic> data = {
                    'url': baseUrl,
                    'sourceId': source.id.toString(),
                    'title': '',
                  };
                  context.push("/mangawebview", extra: data);
                } else if (value == 1) {
                  final res = await context.push(
                    '/extension_detail',
                    extra: source,
                  );
                  if (res != null && mounted) {
                    setState(() {
                      source = res as Source;
                    });
                  }
                } else if (value == 2) {
                  _promptSaveSearch();
                } else if (value == 3) {
                  _showSavedSearches();
                }
              },
            ),
          if (!isLocal)
            if (isTv)
              IconButton(
                focusColor: context.primaryColor.withValues(alpha: 0.4),
                icon: const Icon(Icons.more_vert),
                onPressed: () async {
                  final picked = await showTvMenu(
                    context,
                    title: source.name ?? '',
                    options: [
                      TvMenuOption(context.l10n.open_in_browser),
                      TvMenuOption(context.l10n.settings),
                    ],
                  );
                  if (picked != null && mounted) _onSourceOverflow(picked);
                },
              )
            else
              PopupMenuButton(
                popUpAnimationStyle: popupAnimationStyle,
                itemBuilder: (context) {
                  return [
                    PopupMenuItem<int>(
                      value: 0,
                      child: Text(context.l10n.open_in_browser),
                    ),
                    PopupMenuItem<int>(
                      value: 1,
                      child: Text(context.l10n.settings),
                    ),
                  ];
                },
                onSelected: _onSourceOverflow,
              ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(AppBar().preferredSize.height * 0.8),
          child: Column(
            children: [
              SizedBox(
                width: context.width(1),
                height: 45,
                child: SuperListView.builder(
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  itemCount: YomiShorts.supports(source) ? 4 : 3,
                  itemBuilder: (context, index) {
                    if (index == 3) {
                      return MangasCardSelector(
                        icon: _types(context)[3].icon,
                        selected: false,
                        text: _types(context)[3].title,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => YomiShortsScreen(source: source, query: _query),
                          ),
                        ),
                      );
                    }
                    return MangasCardSelector(
                      icon: _types(context)[index].icon,
                      selected: _selectedIndex == index,
                      text: _types(context)[index].title,
                      onPressed: () async {
                        if (index == 1 && !supportsLatest) {
                          // YomiHub 0.1.8: "Latest" from the source's own
                          // sort filter, else its popular list
                          final latest = YomiLatestEmulation.apply(filterList);
                          _mangaList.clear();
                          if (latest == null) {
                            botToast(tr('Nguồn này không có danh sách Mới nhất, đang hiện danh sách Phổ biến'), second: 3);
                          }
                          setState(() {
                            _selectedIndex = 1;
                            _isFiltering = latest != null;
                            if (latest != null) filters = latest;
                            _isSearch = false;
                            _query = "";
                            _textEditingController.clear();
                            _page = 1;
                            _isLoading = false;
                          });
                          if (latest == null) {
                            _getManga = ref.refresh(getPopularProvider(source: source, page: 1));
                          } else {
                            _getManga = ref.refresh(
                              searchProvider(source: source, query: '', page: 1, filterList: latest),
                            );
                          }
                          return;
                        }
                        if (filters.isEmpty) {
                          filters = filterList;
                        }
                        if (index == 2) {
                          // YomiHub 0.2.2: the filter menu opens first; the
                          // extension's complete filter list is then loaded
                          // inside it (failures go to the app log)
                          var sheetLoading = !isLocal && YomiFilterLoader.needsLoad(source, filters);
                          String? sheetError;
                          var sheetStarted = false;
                          final result = await showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: ref.read(liquidGlassProvider).enabled
                                ? Colors.transparent
                                : null,
                            builder: (context) => StatefulBuilder(
                              builder: (context, setState) {
                                if (sheetLoading && !sheetStarted) {
                                  sheetStarted = true;
                                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                                    final r = await YomiFilterLoader.loadAll(source, filters);
                                    if (r.filters != null) filters = r.filters!;
                                    sheetLoading = false;
                                    sheetError = r.error;
                                    if (context.mounted) setState(() {});
                                  });
                                }
                                return SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.85,
                                  child: YomiFilterSheet(
                                    source: source,
                                    filters: filters,
                                    loading: sheetLoading,
                                    loadError: sheetError,
                                    resetLabel: l10n.reset,
                                    filterLabel: l10n.filter,
                                    onLoadFilter: () async {
                                      setState(() {
                                        sheetLoading = true;
                                        sheetError = null;
                                      });
                                      final r = await YomiFilterLoader.loadAll(source, filters);
                                      if (r.filters != null) filters = r.filters!;
                                      sheetLoading = false;
                                      sheetError = r.error;
                                      if (context.mounted) setState(() {});
                                    },
                                    onReset: () async {
                                      setState(() {
                                        filters = getFilterList(source: source);
                                      });
                                      // 0.2.1: Reset also reloads filters
                                      // that are still a placeholder
                                      if (YomiFilterRefresh.supports(source) &&
                                          YomiFilterRefresh.needsLoad(filters)) {
                                        final fresh = await YomiFilterRefresh.load(source, force: true);
                                        if (fresh != null && context.mounted) {
                                          setState(() => filters = fresh);
                                        }
                                      }
                                    },
                                    onChanged: (values) =>
                                        setState(() => filters = values),
                                    onFilter: () =>
                                        Navigator.pop(context, 'filter'),
                                  ),
                                );
                              },
                            ),
                          );
                          if (result == 'filter') {
                            _mangaList.clear();
                            if (mounted) {
                              setState(() {
                                _selectedIndex = 2;
                                _isFiltering = true;
                                _page = 1;
                                _isLoading = false;
                              });
                            }

                            _getManga = ref.refresh(
                              searchProvider(
                                source: source,
                                query: _query,
                                page: 1,
                                filterList: filters,
                              ),
                            );
                          }
                        } else {
                          _mangaList.clear();
                          setState(() {
                            _selectedIndex = index;
                            _isFiltering = false;
                            _isSearch = false;
                            _query = "";
                            _textEditingController.clear();
                            _page = 1;
                            _isLoading = false;
                          });
                        }
                      },
                    );
                  },
                ),
              ),
              Container(
                color: context.primaryColor,
                height: 0.3,
                width: context.width(1),
              ),
            ],
          ),
        ),
      ),
      body: _getManga!.isLoading
          // Fetching a source page is the app's longest routine wait. Lay out
          // the grid the covers will land in rather than a centred spinner;
          // the list mode has no fixed cell shape to stand in for, so it keeps
          // the spinner.
          ? (displayType == DisplayType.list
                ? const ProgressCenter()
                : Consumer(
                    builder: (context, ref, child) => CoverGridSkeleton(
                      gridSize: ref.watch(
                        libraryGridSizeStateProvider(itemType: source.itemType),
                      ),
                      childAspectRatio:
                          displayType == DisplayType.comfortableGrid
                          ? 0.642
                          : 0.69,
                    ),
                  ))
          : _getManga!.when(
              data: (data) {
                if (_hasNextPage) {
                  if (!data!.hasNextPage) {
                    if (mounted) {
                      setState(() {
                        _hasNextPage = false;
                      });
                    }
                  }
                }
                if (_mangaList.isEmpty && data!.list.isNotEmpty) {
                  _mangaList.addAll(YomiFilterStore.apply(data.list, source, _libraryIndex));
                }
                Widget buildProgressIndicator() {
                  return !(data!.list.isNotEmpty &&
                          (data.hasNextPage || _hasNextPage))
                      ? Container()
                      : _isLoading
                      ? const Center(
                          child: SizedBox(
                            height: 100,
                            width: 200,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(4),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            onPressed: () {
                              if (!_getManga!.isLoading) {
                                if (mounted) {
                                  setState(() {
                                    _isLoading = true;
                                  });
                                }
                                _loadMore().then((value) {
                                  if (mounted && value != null) {
                                    setState(() {
                                      _mangaList.addAll(YomiFilterStore.apply(value.list, source, _libraryIndex));
                                      _isLoading = false;
                                    });
                                  }
                                });
                              }
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  l10n.load_more,
                                  style: const TextStyle(
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  maxLines: 2,
                                ),
                                const Icon(Icons.arrow_forward_outlined),
                              ],
                            ),
                          ),
                        );
                }

                if (data!.list.isEmpty) {
                  return Center(child: Text(l10n.no_result));
                }
                _length = source.isFullData!
                    ? _fullDataLength
                    : _mangaList.length;
                _length = (_mangaList.length < _length
                    ? _mangaList.length
                    : _length);
                final isComfortableGrid =
                    displayType == DisplayType.comfortableGrid;
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    children: [
                      Flexible(
                        child: displayType == DisplayType.list
                            ? SuperListViewWidget(
                                controller: _scrollController,
                                itemCount: _length + 1,
                                itemBuilder: (context, index) {
                                  if (index == _length) {
                                    return buildProgressIndicator();
                                  }
                                  return MangaHomeImageCardListTile(
                                    itemType: source.itemType,
                                    manga: _mangaList[index],
                                    source: source,
                                    libraryManga:
                                        _libraryIndex[_mangaList[index].name],
                                  );
                                },
                              )
                            : Consumer(
                                builder: (context, ref, child) {
                                  final gridSize = ref.watch(
                                    libraryGridSizeStateProvider(
                                      itemType: source.itemType,
                                    ),
                                  );

                                  return GridViewWidget(
                                    gridSize: gridSize,
                                    controller: _scrollController,
                                    itemCount: _length + 1,
                                    childAspectRatio: isComfortableGrid
                                        ? 0.642
                                        : 0.69,
                                    itemBuilder: (context, index) {
                                      if (index == _length) {
                                        return buildProgressIndicator();
                                      }
                                      return MangaHomeImageCard(
                                        autofocus:
                                            isTv && index == 0 && !_isSearch,
                                        itemType: source.itemType,
                                        manga: _mangaList[index],
                                        source: source,
                                        isComfortableGrid: isComfortableGrid,
                                        libraryManga:
                                            _libraryIndex[_mangaList[index]
                                                .name],
                                      );
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
              error: (error, stackTrace) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            IconButton(
                              onPressed: () {
                                if (_selectedIndex == 2 &&
                                        (_isSearch && _query.isNotEmpty) ||
                                    _isFiltering) {
                                  ref.invalidate(
                                    searchProvider(
                                      source: source,
                                      query: _query,
                                      page: 1,
                                      filterList: filters,
                                    ),
                                  );
                                } else if (_selectedIndex == 1 &&
                                    !_isSearch &&
                                    _query.isEmpty) {
                                  ref.invalidate(
                                    getLatestUpdatesProvider(
                                      source: source,
                                      page: 1,
                                    ),
                                  );
                                } else if (_selectedIndex == 0 &&
                                    !_isSearch &&
                                    _query.isEmpty) {
                                  ref.invalidate(
                                    getPopularProvider(source: source, page: 1),
                                  );
                                }
                              },
                              icon: const Icon(Icons.refresh),
                            ),
                            Text(l10n.refresh),
                          ],
                        ),
                        const SizedBox(width: 20),
                        Column(
                          children: [
                            IconButton(
                              onPressed: () async {
                                final baseUrl = ref.watch(
                                  sourceBaseUrlProvider(source: source),
                                );
                                Map<String, dynamic> data = {
                                  'url': baseUrl,
                                  'sourceId': source.id.toString(),
                                  'title': '',
                                  "hasCloudFlare":
                                      source.hasCloudflare ?? false,
                                };
                                context.push("/mangawebview", extra: data);
                              },
                              icon: Icon(
                                Icons.public,
                                size: 22,
                                color: context.secondaryColor,
                              ),
                            ),
                            Text(context.l10n.webview),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // This screen keeps its own recovery actions above (refresh
                  // with the right provider, and a webview for Cloudflare), so
                  // only the cause is demoted here to match ErrorState.
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      error.toString(),
                      textAlign: TextAlign.center,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.textColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
    );
  }
}

class MangaHomeImageCard extends ConsumerStatefulWidget {
  final MManga manga;
  final ItemType itemType;
  final Source source;
  final bool isComfortableGrid;
  final Manga? libraryManga;
  final bool autofocus;
  const MangaHomeImageCard({
    super.key,
    required this.manga,
    required this.source,
    required this.itemType,
    required this.isComfortableGrid,
    this.libraryManga,
    this.autofocus = false,
  });

  @override
  ConsumerState<MangaHomeImageCard> createState() => _MangaHomeImageCardState();
}

class _MangaHomeImageCardState extends ConsumerState<MangaHomeImageCard> {
  @override
  Widget build(BuildContext context) {
    return MangaImageCardWidget(
      getMangaDetail: widget.manga,
      source: widget.source,
      itemType: widget.itemType,
      isComfortableGrid: widget.isComfortableGrid,
      libraryManga: widget.libraryManga,
      autofocus: widget.autofocus,
    );
  }
}

class MangaHomeImageCardListTile extends ConsumerStatefulWidget {
  final MManga manga;
  final ItemType itemType;
  final Source source;
  final Manga? libraryManga;
  const MangaHomeImageCardListTile({
    super.key,
    required this.manga,
    required this.source,
    required this.itemType,
    this.libraryManga,
  });

  @override
  ConsumerState<MangaHomeImageCardListTile> createState() =>
      _MangaHomeImageCardListTileState();
}

class _MangaHomeImageCardListTileState
    extends ConsumerState<MangaHomeImageCardListTile> {
  @override
  Widget build(BuildContext context) {
    return MangaImageCardListTileWidget(
      getMangaDetail: widget.manga,
      source: widget.source,
      itemType: widget.itemType,
      libraryManga: widget.libraryManga,
    );
  }
}
