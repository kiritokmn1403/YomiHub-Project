import 'package:flutter/material.dart';
import 'package:mangayomi/eval/model/filter.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';

/// YomiHub 0.6.0 (yêu cầu chủ dự án 19/11/2026): mọi mục lựa chọn trong bộ lọc
/// của tiện ích hiển thị dạng ô chọn (checkbox) thay cho danh sách thả xuống
/// (SelectFilter), mũi tên (SortFilter) hay chip (Kotatsu).
///
///  * SelectFilter: chọn đúng một – ô đang chọn được đánh dấu, bấm ô khác để đổi.
///  * SortFilter: ô đánh dấu tiêu chí sắp xếp; bấm lại ô đang chọn để đổi chiều
///    tăng/giảm (mũi tên bên phải).
///  * TriStateFilter: ô ba trạng thái bao gồm → loại trừ → tắt.

/// Số lựa chọn tối đa để mở sẵn nhóm (danh sách ngắn thấy ô chọn ngay).
const int kYomiFilterOpenMax = 8;

/// Số lựa chọn bắt đầu hiện ô tìm kiếm.
const int kYomiFilterSearchMin = 15;

String _optName(dynamic o) {
  try {
    return '${o.name}';
  } catch (_) {
    return '$o';
  }
}

/// Chỉ số hợp lệ của SelectFilter (state hỏng → 0).
int yomiSelectIndex(SelectFilter f) {
  final s = f.state;
  return (s >= 0 && s < f.values.length) ? s : 0;
}

/// Chuyển chọn của SelectFilter sang ô [i]; trả về true nếu có thay đổi.
bool yomiSelectPick(SelectFilter f, int i) {
  if (i < 0 || i >= f.values.length || f.state == i) return false;
  f.state = i;
  return true;
}

/// Bấm ô [i] của SortFilter: ô khác → chọn (giữ chiều), ô đang chọn → đổi chiều.
void yomiSortPick(SortFilter f, int i) {
  if (i < 0 || i >= f.values.length) return;
  if (f.state.index == i) {
    f.state.ascending = !f.state.ascending;
  } else {
    f.state.index = i;
  }
}

/// TriState: bao gồm (1) → loại trừ (2) → tắt (0).
int yomiTriNext(int state) => switch (state) {
  0 => 1,
  1 => 2,
  _ => 0,
};

/// Ô chọn ba trạng thái dùng chung cho mọi kiểu bộ lọc.
class YomiTriCheckbox extends StatelessWidget {
  final TriStateFilter filter;
  final VoidCallback onChanged;
  const YomiTriCheckbox({super.key, required this.filter, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final st = filter.state;
    return CheckboxListTile(
      dense: true,
      tristate: true,
      controlAffinity: ListTileControlAffinity.leading,
      // null = loại trừ (ô đỏ có dấu gạch)
      value: switch (st) {
        1 => true,
        2 => null,
        _ => false,
      },
      fillColor: st == 2 ? WidgetStatePropertyAll(cs.error) : null,
      title: Text(filter.name),
      onChanged: (_) {
        filter.state = yomiTriNext(filter.state);
        onChanged();
      },
    );
  }
}

/// Danh sách ô chọn có tiêu đề gập/mở, ô tìm khi dài.
class _YomiCheckboxGroup extends StatefulWidget {
  final String title;
  final String? subtitle;
  final int count;
  final String Function(int) label;
  final bool Function(int) checked;
  final Widget? Function(int)? trailing;
  final void Function(int) onTap;
  const _YomiCheckboxGroup({
    super.key,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.label,
    required this.checked,
    required this.onTap,
    this.trailing,
  });

  @override
  State<_YomiCheckboxGroup> createState() => _YomiCheckboxGroupState();
}

class _YomiCheckboxGroupState extends State<_YomiCheckboxGroup> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    final rows = <Widget>[];
    for (var i = 0; i < widget.count; i++) {
      final name = widget.label(i);
      if (q.isNotEmpty && !name.toLowerCase().contains(q)) continue;
      rows.add(
        CheckboxListTile(
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
          value: widget.checked(i),
          title: Text(name, style: const TextStyle(fontSize: 13)),
          secondary: widget.trailing?.call(i),
          onChanged: (_) {
            widget.onTap(i);
            setState(() {});
          },
        ),
      );
    }
    return ExpansionTile(
      initiallyExpanded: widget.count <= kYomiFilterOpenMax,
      title: Text(widget.title, style: const TextStyle(fontSize: 14)),
      subtitle: widget.subtitle == null
          ? null
          : Text(
              widget.subtitle!,
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      children: [
        if (widget.count >= kYomiFilterSearchMin)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: TextField(
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search, size: 20),
                hintText: tr('Tìm trong {p0}…', {'p0': widget.title}),
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _q = v),
            ),
          ),
        ...rows,
      ],
    );
  }
}

/// SelectFilter dạng ô chọn (chọn một).
class YomiSelectCheckboxes extends StatelessWidget {
  final SelectFilter filter;
  final VoidCallback onChanged;
  const YomiSelectCheckboxes({super.key, required this.filter, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final f = filter;
    if (f.values.isEmpty) {
      return ListTile(dense: true, title: Text(f.name));
    }
    final cur = yomiSelectIndex(f);
    return _YomiCheckboxGroup(
      key: PageStorageKey<String>('yh_sel_${f.name}_${f.values.length}'),
      title: f.name,
      subtitle: _optName(f.values[cur]),
      count: f.values.length,
      label: (i) => _optName(f.values[i]),
      checked: (i) => i == yomiSelectIndex(f),
      onTap: (i) {
        if (yomiSelectPick(f, i)) onChanged();
      },
    );
  }
}

/// SortFilter dạng ô chọn + mũi tên chiều sắp xếp.
class YomiSortCheckboxes extends StatelessWidget {
  final SortFilter filter;
  final VoidCallback onChanged;
  const YomiSortCheckboxes({super.key, required this.filter, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final f = filter;
    if (f.values.isEmpty) {
      return ListTile(dense: true, title: Text(f.name));
    }
    final idx = (f.state.index >= 0 && f.state.index < f.values.length) ? f.state.index : 0;
    return _YomiCheckboxGroup(
      key: PageStorageKey<String>('yh_sort_${f.name}_${f.values.length}'),
      title: f.name,
      subtitle: '${_optName(f.values[idx])} ${f.state.ascending ? '↑' : '↓'}',
      count: f.values.length,
      label: (i) => _optName(f.values[i]),
      checked: (i) => i == f.state.index,
      trailing: (i) => i == f.state.index
          ? Icon(f.state.ascending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 20)
          : null,
      onTap: (i) {
        yomiSortPick(f, i);
        onChanged();
      },
    );
  }
}
