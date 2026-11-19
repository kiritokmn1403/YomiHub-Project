import 'package:flutter/material.dart';
import 'package:mangayomi/eval/model/filter.dart';
import 'package:mangayomi/yomihub/filters/filter_checkbox.dart';
import 'package:mangayomi/yomihub/filters/filter_v2_classifier.dart';
import 'package:mangayomi/yomihub/filters/multi_select_search.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';

/// YomiHub 0.6.2: Bảng bộ lọc mới ("New Filter") gom toàn bộ bộ lọc của bất
/// kỳ tiện ích nào thành 9 ô thẻ gập/mở theo thứ tự cố định (+ "Khác" nếu có).
///
///  * Hàng nút trên cùng: "Đặt Lại", "Nạp Bộ Lọc", "Đánh Dấu", "Bộ Lọc".
///  * Mọi lựa chọn hiển thị dạng ô chọn (checkbox), tái sử dụng
///    [YomiSelectCheckboxes], [YomiSortCheckboxes], [YomiTriCheckbox] và logic
///    chọn nhiều từ `multi_select_search.dart` (`yomiSelectMultiAllowed`).
///  * Không dùng `PageStorageKey` chung với `ExpansionTile` chứa `TextField`:
///    trạng thái đóng/mở được giữ trực tiếp trong `State` ([_expanded],
///    [_groupExpanded]) cùng `ScrollController(keepScrollOffset: false)` và
///    [YomiFilterStorageScope] để tránh lỗi ép kiểu `bool` → `double?` và bảo
///    toàn trạng thái khi cuộn hoặc gập ô.
class FilterV2Sheet extends StatefulWidget {
  final List<dynamic> filters;
  final void Function(List<dynamic> filters) onChanged;
  final VoidCallback onReset;
  final VoidCallback? onLoad;
  final VoidCallback? onBookmark;
  final VoidCallback onApply;

  /// Đang tải đầy đủ bộ lọc từ tiện ích (hiển thị thanh tiến trình).
  final bool loading;

  /// Lỗi khi nạp bộ lọc (nếu có).
  final String? loadError;

  /// Có hiển thị cả các ô trống trong 9 nhóm chính hay không (mặc định ẩn ô trống).
  final bool showEmptySections;

  /// Khối bổ sung tùy chọn đặt phía trên các ô bộ lọc (vd. "Lọc kết quả").
  final Widget? headerExtra;

  const FilterV2Sheet({
    super.key,
    required this.filters,
    required this.onChanged,
    required this.onReset,
    this.onLoad,
    this.onBookmark,
    required this.onApply,
    this.loading = false,
    this.loadError,
    this.showEmptySections = false,
    this.headerExtra,
  });

  @override
  State<FilterV2Sheet> createState() => _FilterV2SheetState();
}

class _FilterV2SheetState extends State<FilterV2Sheet> {
  final ScrollController _scrollController = ScrollController(
    keepScrollOffset: false,
  );
  final Map<FilterV2Section, bool> _expanded = {};
  final Set<FilterV2Section> _userToggled = {};
  final Map<String, bool> _groupExpanded = {};
  final Map<String, String> _searchQueries = {};
  final Map<String, TextEditingController> _searchControllers = {};
  final Map<TextFilter, TextEditingController> _textControllers = {};

  late Map<FilterV2Section, List<dynamic>> _grouped;

  @override
  void initState() {
    super.initState();
    _rebuildGrouping(initDefaults: true);
  }

  @override
  void didUpdateWidget(covariant FilterV2Sheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    _rebuildGrouping(initDefaults: false);
    _syncTextControllers();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (final c in _searchControllers.values) {
      c.dispose();
    }
    for (final c in _textControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _rebuildGrouping({required bool initDefaults}) {
    _grouped = groupFiltersV2(widget.filters);
    for (final section in FilterV2Section.values) {
      final items = _grouped[section] ?? const [];
      if (initDefaults || !_userToggled.contains(section)) {
        _expanded[section] = _defaultSectionExpanded(section, items);
      }
    }
  }

  void _syncTextControllers() {
    final activeTextFilters = <TextFilter>{};
    void collect(List<dynamic> items) {
      for (final f in items) {
        if (f is TextFilter) {
          activeTextFilters.add(f);
          final ctrl = _textControllers[f];
          if (ctrl != null && ctrl.text != f.state) {
            ctrl.value = TextEditingValue(
              text: f.state,
              selection: TextSelection.collapsed(offset: f.state.length),
            );
          }
        } else if (f is GroupFilter) {
          collect(f.state);
        }
      }
    }

    collect(widget.filters);
    final stale = _textControllers.keys
        .where((k) => !activeTextFilters.contains(k))
        .toList();
    for (final k in stale) {
      _textControllers.remove(k)?.dispose();
    }
  }

  TextEditingController _controllerForTextFilter(TextFilter f) {
    final existing = _textControllers[f];
    if (existing != null) return existing;
    final created = TextEditingController(text: f.state);
    _textControllers[f] = created;
    return created;
  }

  TextEditingController _controllerForSearch(String key) {
    final existing = _searchControllers[key];
    if (existing != null) return existing;
    final created = TextEditingController(text: _searchQueries[key] ?? '');
    _searchControllers[key] = created;
    return created;
  }

  bool _defaultSectionExpanded(FilterV2Section section, List<dynamic> items) {
    if (items.isEmpty) return false;
    if (_activeCountForList(items) > 0) return true;
    if (section == FilterV2Section.sort) return true;
    return _leafOptionCount(items) <= kYomiFilterOpenMax;
  }

  void _notifyChanged() {
    widget.onChanged(widget.filters);
    if (mounted) setState(() {});
  }

  String _sectionTitle(FilterV2Section section) => switch (section) {
    FilterV2Section.sort => tr('Sắp Xếp'),
    FilterV2Section.status => tr('Tình Trạng'),
    FilterV2Section.category => tr('Danh Mục'),
    FilterV2Section.contentRating => tr('Phân Loại Nội Dung'),
    FilterV2Section.releaseYear => tr('Năm Phát Hành'),
    FilterV2Section.searchBy => tr('Tìm Theo'),
    FilterV2Section.rating => tr('Đánh Giá'),
    FilterV2Section.translation => tr('Bản Dịch'),
    FilterV2Section.genre => tr('Thể Loại'),
    FilterV2Section.other => tr('Khác'),
  };

  IconData _sectionIcon(FilterV2Section section) => switch (section) {
    FilterV2Section.sort => Icons.sort_rounded,
    FilterV2Section.status => Icons.flag_outlined,
    FilterV2Section.category => Icons.category_outlined,
    FilterV2Section.contentRating => Icons.shield_outlined,
    FilterV2Section.releaseYear => Icons.calendar_today_outlined,
    FilterV2Section.searchBy => Icons.manage_search_rounded,
    FilterV2Section.rating => Icons.star_outline_rounded,
    FilterV2Section.translation => Icons.translate_rounded,
    FilterV2Section.genre => Icons.local_offer_outlined,
    FilterV2Section.other => Icons.tune_rounded,
  };

  static String _optName(dynamic o) {
    try {
      return '${o.name}';
    } catch (_) {
      return '$o';
    }
  }

  static String _filterName(dynamic f) {
    try {
      return (f.name ?? '').toString();
    } catch (_) {
      return '';
    }
  }

  static int _leafOptionCount(List<dynamic> list) {
    var count = 0;
    for (final f in list) {
      if (f is GroupFilter) {
        count += _leafOptionCount(f.state);
      } else if (f is SelectFilter) {
        count += f.values.length;
      } else if (f is SortFilter) {
        count += f.values.length;
      } else if (f is HeaderFilter || f is SeparatorFilter) {
        continue;
      } else {
        count++;
      }
    }
    return count;
  }

  static int _activeCountForItem(dynamic f) {
    if (f is SortFilter) {
      return (f.state.index > 0 || f.state.ascending) ? 1 : 0;
    }
    if (f is SelectFilter) {
      if (f.values.isEmpty) return 0;
      final chosen = yomiSelectChosen(f);
      if (chosen.length > 1) return chosen.length;
      return chosen.first > 0 ? 1 : 0;
    }
    if (f is TriStateFilter) return f.state == 0 ? 0 : 1;
    if (f is CheckBoxFilter) return f.state ? 1 : 0;
    if (f is TextFilter) return f.state.trim().isEmpty ? 0 : 1;
    if (f is GroupFilter) return _activeCountForList(f.state);
    return 0;
  }

  static int _activeCountForList(List<dynamic> list) {
    var sum = 0;
    for (final f in list) {
      sum += _activeCountForItem(f);
    }
    return sum;
  }

  String? _sectionSummary(List<dynamic> items) {
    final labels = <String>[];
    void collect(List<dynamic> list) {
      for (final f in list) {
        if (f is SortFilter && f.values.isNotEmpty) {
          final idx = (f.state.index >= 0 && f.state.index < f.values.length)
              ? f.state.index
              : 0;
          labels.add('${_optName(f.values[idx])} ${f.state.ascending ? '↑' : '↓'}');
        } else if (f is SelectFilter && f.values.isNotEmpty) {
          final chosen = yomiSelectChosen(f);
          if (chosen.length > 1 || chosen.first > 0) {
            labels.addAll(chosen.map((i) => _optName(f.values[i])));
          }
        } else if (f is TriStateFilter && f.state != 0) {
          labels.add(f.state == 2 ? '✕ ${f.name}' : '✓ ${f.name}');
        } else if (f is CheckBoxFilter && f.state) {
          labels.add(f.name);
        } else if (f is TextFilter && f.state.trim().isNotEmpty) {
          labels.add('${f.name}: ${f.state.trim()}');
        } else if (f is GroupFilter) {
          collect(f.state);
        }
      }
    }

    collect(items);
    if (labels.isEmpty) return null;
    if (labels.length <= 3) return labels.join(', ');
    return '${labels.take(3).join(', ')} (+${labels.length - 3})';
  }

  @override
  Widget build(BuildContext context) {
    final visibleSections = <FilterV2Section>[
      for (final s in kFilterV2PrimarySections)
        if (widget.showEmptySections || (_grouped[s]?.isNotEmpty ?? false)) s,
      if ((_grouped[FilterV2Section.other]?.isNotEmpty ?? false))
        FilterV2Section.other,
    ];

    return SafeArea(
      top: false,
      child: Column(
        children: [
          _buildTopBar(context),
          if (widget.loading) ...[
            const LinearProgressIndicator(minHeight: 2),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
              child: Text(
                tr('Đang tải toàn bộ bộ lọc của tiện ích…'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ] else if (widget.loadError != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.loadError!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 1),
          Expanded(
            child: visibleSections.isEmpty && widget.headerExtra == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        tr('Tiện ích này không có bộ lọc'),
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.headerExtra != null) ...[
                          widget.headerExtra!,
                          const SizedBox(height: 8),
                        ],
                        for (final section in visibleSections)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildSectionCard(context, section),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: widget.onReset,
                        icon: const Icon(Icons.restart_alt, size: 18),
                        label: Text(tr('Đặt Lại')),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: widget.loading ? null : widget.onLoad,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: Text(tr('Nạp Bộ Lọc')),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: widget.onBookmark,
                        icon: const Icon(Icons.bookmark_border, size: 18),
                        label: Text(tr('Đánh Dấu')),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: widget.onApply,
                    icon: const Icon(Icons.filter_alt_outlined, size: 18),
                    label: Text(tr('Bộ Lọc')),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, FilterV2Section section) {
    final items = _grouped[section] ?? const [];
    final isExpanded = _expanded[section] ?? false;
    final activeCount = _activeCountForList(items);
    final summary = _sectionSummary(items);
    final cs = Theme.of(context).colorScheme;
    final title = _sectionTitle(section);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: activeCount > 0
              ? cs.primary.withValues(alpha: 0.55)
              : cs.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: items.isEmpty
                ? null
                : () => setState(() {
                    _userToggled.add(section);
                    _expanded[section] = !isExpanded;
                  }),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    _sectionIcon(section),
                    size: 20,
                    color: activeCount > 0 ? cs.primary : cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: activeCount > 0 ? cs.primary : null,
                          ),
                        ),
                        if (summary != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            summary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: activeCount > 0 ? cs.primary : cs.onSurfaceVariant,
                            ),
                          ),
                        ] else if (items.isEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            tr('Tiện ích này không có bộ lọc'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (activeCount > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        tr('{p0} đang chọn', {'p0': activeCount}),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (items.isNotEmpty)
                    Tooltip(
                      message: isExpanded ? tr('Thu gọn nhóm') : tr('Mở rộng nhóm'),
                      child: Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (items.isNotEmpty)
            Visibility(
              visible: isExpanded,
              maintainState: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(height: 1),
                  YomiFilterStorageScope(
                    children: _buildSectionItems(
                      context,
                      section,
                      title,
                      items,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildSectionItems(
    BuildContext context,
    FilterV2Section section,
    String sectionTitle,
    List<dynamic> items,
  ) {
    // Nếu cả ô là danh sách phẳng dài các CheckBoxFilter / TriStateFilter (≥ 15),
    // gắn ô tìm kiếm chung ngay đầu ô thẻ.
    final flatSelectableCount = items
        .where((f) => f is TriStateFilter || f is CheckBoxFilter)
        .length;
    final hasSectionSearch = flatSelectableCount >= kYomiFilterSearchMin;
    final sectionSearchKey = 'sec_${section.name}';
    final query = (_searchQueries[sectionSearchKey] ?? '').trim().toLowerCase();

    final out = <Widget>[];
    if (hasSectionSearch) {
      out.add(_buildInlineSearchField(sectionSearchKey, sectionTitle));
    }

    for (var i = 0; i < items.length; i++) {
      final f = items[i];
      if (hasSectionSearch &&
          (f is TriStateFilter || f is CheckBoxFilter) &&
          query.isNotEmpty &&
          !_filterName(f).toLowerCase().contains(query)) {
        continue;
      }
      out.add(
        _buildFilterItem(
          context,
          section,
          f,
          keyPrefix: '${section.name}_$i',
          isSoleGroupInSection: items.length == 1 && f is GroupFilter,
        ),
      );
    }
    return out;
  }

  Widget _buildInlineSearchField(String storageKey, String groupTitle) {
    final ctrl = _controllerForSearch(storageKey);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          isDense: true,
          prefixIcon: const Icon(Icons.search, size: 20),
          hintText: tr('Tìm trong {p0}…', {'p0': groupTitle}),
          border: const OutlineInputBorder(),
        ),
        onChanged: (v) => setState(() => _searchQueries[storageKey] = v),
      ),
    );
  }

  Widget _buildFilterItem(
    BuildContext context,
    FilterV2Section section,
    dynamic f, {
    required String keyPrefix,
    bool isSoleGroupInSection = false,
  }) {
    if (f is SortFilter) {
      return YomiSortCheckboxes(filter: f, onChanged: _notifyChanged);
    }
    if (f is SelectFilter) {
      return _buildSelectFilter(section, f);
    }
    if (f is TriStateFilter) {
      return YomiTriCheckbox(filter: f, onChanged: _notifyChanged);
    }
    if (f is CheckBoxFilter) {
      return CheckboxListTile(
        dense: true,
        controlAffinity: ListTileControlAffinity.leading,
        value: f.state,
        title: Text(f.name, style: const TextStyle(fontSize: 13)),
        onChanged: (v) {
          f.state = v ?? false;
          _notifyChanged();
        },
      );
    }
    if (f is TextFilter) {
      final isNumeric =
          section == FilterV2Section.releaseYear ||
          section == FilterV2Section.rating ||
          (f.type?.toLowerCase().startsWith('year') ?? false);
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
        child: TextField(
          controller: _controllerForTextFilter(f),
          keyboardType: isNumeric ? TextInputType.number : null,
          decoration: InputDecoration(
            isDense: true,
            labelText: f.name,
            border: const OutlineInputBorder(),
          ),
          onChanged: (val) {
            f.state = val;
            _notifyChanged();
          },
        ),
      );
    }
    if (f is HeaderFilter) {
      return ListTile(
        dense: true,
        leading: const Icon(Icons.info_outline, size: 18),
        title: Text(f.name, style: Theme.of(context).textTheme.bodySmall),
      );
    }
    if (f is GroupFilter) {
      return _buildGroupFilter(
        context,
        section,
        f,
        groupKey: '${keyPrefix}_${f.name}',
        inlineDirect: isSoleGroupInSection,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildSelectFilter(FilterV2Section section, SelectFilter f) {
    if (f.values.isEmpty) {
      return ListTile(dense: true, title: Text(f.name));
    }
    // Sắp Xếp / Tìm Theo luôn chọn-một theo quy tắc chọn nhiều (yomiSelectMultiAllowed).
    final forceSingle =
        section == FilterV2Section.sort || section == FilterV2Section.searchBy;
    if (!forceSingle || !yomiSelectMultiAllowed(f)) {
      return YomiSelectCheckboxes(filter: f, onChanged: _notifyChanged);
    }
    // Dự phòng chọn-một nếu tên thuộc ngôn ngữ chưa có trong _sortLike của multi_select_search.
    final activeIdx = yomiSelectIndex(f);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 2),
          child: Text(
            f.name,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        for (var i = 0; i < f.values.length; i++)
          CheckboxListTile(
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            value: i == activeIdx,
            title: Text(
              _optName(f.values[i]),
              style: const TextStyle(fontSize: 13),
            ),
            onChanged: (_) {
              if (f.state != i || f.multi.isNotEmpty) {
                f.multi = <int>[];
                f.state = i;
                _notifyChanged();
              }
            },
          ),
      ],
    );
  }

  Widget _buildGroupFilter(
    BuildContext context,
    FilterV2Section section,
    GroupFilter group, {
    required String groupKey,
    required bool inlineDirect,
  }) {
    final searchKey = 'grp_$groupKey';
    final hasSearch = group.state.length >= kYomiFilterSearchMin;
    final query = (_searchQueries[searchKey] ?? '').trim().toLowerCase();

    final children = <Widget>[
      if (hasSearch) _buildInlineSearchField(searchKey, group.name),
      for (var i = 0; i < group.state.length; i++)
        if (!hasSearch ||
            query.isEmpty ||
            _filterName(group.state[i]).toLowerCase().contains(query))
          _buildFilterItem(
            context,
            section,
            group.state[i],
            keyPrefix: '${groupKey}_$i',
          ),
    ];

    if (inlineDirect) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    }

    final expanded = _groupExpanded.putIfAbsent(
      groupKey,
      () =>
          group.state.length <= kYomiFilterOpenMax ||
          _activeCountForList(group.state) > 0,
    );
    final active = _activeCountForList(group.state);
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _groupExpanded[groupKey] = !expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    active > 0 ? '${group.name} ($active)' : group.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: active > 0 ? cs.primary : null,
                    ),
                  ),
                ),
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: cs.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        Visibility(
          visible: expanded,
          maintainState: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ],
    );
  }
}
