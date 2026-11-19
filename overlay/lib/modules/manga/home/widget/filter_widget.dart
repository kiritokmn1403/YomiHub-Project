import 'package:flutter/material.dart';
import 'package:mangayomi/eval/model/filter.dart';
import 'package:mangayomi/utils/extensions/build_context_extensions.dart';
import 'package:mangayomi/yomihub/filters/filter_checkbox.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

/// YomiHub 0.6.0: StatefulWidget – mỗi lần đổi bộ lọc tự vẽ lại ô chọn.
/// Trước đây là StatelessWidget nên trong bảng bộ lọc (bottom sheet không được
/// vẽ lại khi màn mở nó setState) ô đã bấm không đổi dấu → "không chọn được".
class FilterWidget extends StatefulWidget {
  final List<dynamic> filterList;
  final Function(List<dynamic>) onChanged;
  const FilterWidget({
    super.key,
    required this.onChanged,
    required this.filterList,
  });

  @override
  State<FilterWidget> createState() => _FilterWidgetState();
}

class _FilterWidgetState extends State<FilterWidget> {
  List<dynamic> get filterList => widget.filterList;

  /// YomiHub 0.6.2: KHÔNG lưu/đọc vị trí cuộn qua PageStorage. Nhóm bộ lọc
  /// (ExpansionTile) ghi trạng thái mở/gập (bool) vào PageStorage cùng định danh
  /// với danh sách lồng bên trong → ScrollPosition.restoreScrollOffset đọc bool
  /// thành double → "type 'bool' is not a subtype of type 'double?'" (log 19/11
  /// 21:53, giải mã bằng symbols_061) rồi Null check ở ô nhập chữ.
  final ScrollController _scroll = ScrollController(keepScrollOffset: false);

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void onChanged(List<dynamic> list) {
    widget.onChanged(list);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SuperListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.all(0),
      itemCount: filterList.length,
      primary: false,
      shrinkWrap: true,
      itemBuilder: (context, idx) {
        final filterState = filterList[idx];
        Widget? widget;
        if (filterState is TextFilter) {
          widget = SeachFormTextFieldWidget(
            text: filterState.state,
            onChanged: (val) {
              filterList[idx] = filterState..state = val;
              onChanged(filterList);
            },
            labelText: filterState.name,
          );
        } else if (filterState is HeaderFilter) {
          widget = ListTile(dense: true, title: Text(filterState.name));
        } else if (filterState is SeparatorFilter) {
          widget = const Divider();
        } else if (filterState is TriStateFilter) {
          // YomiHub 0.6.0: ô chọn 3 trạng thái dùng chung
          widget = YomiTriCheckbox(
            filter: filterState,
            onChanged: () {
              filterList[idx] = filterState;
              onChanged(filterList);
            },
          );
        } else if (filterState is CheckBoxFilter) {
          widget = CheckboxListTile(
            dense: true,
            value: filterState.state,
            onChanged: (value) {
              filterList[idx] = filterState..state = value ?? false;
              onChanged(filterList);
            },
            title: Text(filterState.name),
            controlAffinity: ListTileControlAffinity.leading,
          );
        } else if (filterState is GroupFilter) {
          widget = ExpansionTile(
            // 0.6.2: khóa riêng → trạng thái mở/gập không đè lên khóa của danh sách khác
            key: PageStorageKey<String>('yh_grp_${idx}_${filterState.name}'),
            title: Text(filterState.name, style: const TextStyle(fontSize: 13)),
            children: [
              YomiFilterStorageScope(children: [
                FilterWidget(
                  filterList: filterState.state,
                  onChanged: (values) {
                    filterState.state = values;
                    onChanged(filterList);
                  },
                ),
              ]),
            ],
          );
        } else if (filterState is SortFilter) {
          // YomiHub 0.6.0: tiêu chí sắp xếp dạng ô chọn (bấm lại để đổi chiều)
          widget = YomiSortCheckboxes(
            filter: filterState,
            onChanged: () {
              filterList[idx] = filterState;
              onChanged(filterList);
            },
          );
        } else if (filterState is SelectFilter) {
          // YomiHub 0.6.0: danh sách thả xuống → ô chọn (chọn một)
          widget = YomiSelectCheckboxes(
            filter: filterState,
            onChanged: () {
              filterList[idx] = filterState;
              onChanged(filterList);
            },
          );
        }
        return widget ?? const SizedBox.shrink();
      },
    );
  }
}

class SeachFormTextFieldWidget extends StatefulWidget {
  final String labelText;
  final String text;
  final Function(String) onChanged;
  const SeachFormTextFieldWidget({
    super.key,
    required this.text,
    required this.onChanged,
    required this.labelText,
  });

  @override
  State<SeachFormTextFieldWidget> createState() =>
      _SeachFormTextFieldWidgetState();
}

class _SeachFormTextFieldWidgetState extends State<SeachFormTextFieldWidget> {
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  late final _controller = TextEditingController(text: widget.text);
  @override
  Widget build(BuildContext context) {
    if (widget.text.isEmpty) {
      _controller.clear();
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          isDense: true,
          filled: false,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: context.secondaryColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: context.primaryColor),
          ),
          border: const OutlineInputBorder(borderSide: BorderSide()),
          labelText: widget.labelText,
        ),
      ),
    );
  }
}
