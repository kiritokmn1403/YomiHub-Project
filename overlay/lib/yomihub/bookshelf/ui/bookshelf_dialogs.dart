import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:mangayomi/utils/cached_network.dart';
import 'package:mangayomi/yomihub/bookshelf/bookshelf_logic.dart';
import 'package:mangayomi/yomihub/bookshelf/bookshelf_models.dart';
import 'package:mangayomi/yomihub/bookshelf/bookshelf_store.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const List<String> kBsCommonPublishers = [
  'NXB Kim Đồng',
  'NXB Trẻ',
  'IPM',
  'Amak',
  'Hikari',
];

const List<String> kBsCommonPlaces = [
  'Fahasa',
  'Tiki',
  'Shopee',
  'Nhà sách',
];

List<String> bsFolderPresetLabels() => [
      tr('Bản Limited'),
      tr('Artbook & ColorWalk'),
      tr('Boxset'),
      tr('Goods & Postcard'),
      tr('Sách ngoại truyện / Novel'),
    ];

String bsEditionLabel(BsEdition edition) => switch (edition) {
      BsEdition.regular => tr('Bản thường'),
      BsEdition.limited => tr('Bản Limited'),
      BsEdition.special => tr('Bản đặc biệt'),
    };

String bsStatusLabel(BsStatus status) => switch (status) {
      BsStatus.ongoing => tr('Đang ra'),
      BsStatus.completed => tr('Đã trọn bộ'),
      BsStatus.paused => tr('Tạm ngưng'),
    };

String bsReadStatusLabel(BsReadStatus status) => switch (status) {
      BsReadStatus.unread => tr('Chưa đọc'),
      BsReadStatus.reading => tr('Đang đọc'),
      BsReadStatus.read => tr('Đã đọc'),
    };

String bsFormatMoney(double? value) {
  if (value == null) return '—';
  final formatted =
      NumberFormat('#,##0', 'en_US').format(value.round()).replaceAll(',', '.');
  return '$formatted đ';
}

String bsFormatDate(int? millis) {
  if (millis == null || millis <= 0) return '—';
  return DateFormat('dd/MM/yyyy')
      .format(DateTime.fromMillisecondsSinceEpoch(millis));
}

/// Picks one or more image files via file_picker 12, resizes oversized images
/// and saves compressed JPEG copies under the app documents directory (FN-14).
Future<List<String>> bsPickAndSavePhotos({bool allowMultiple = true}) async {
  final picked = await FilePicker.pickFiles(
    type: FileType.image,
    allowMultiple: allowMultiple,
  );
  if (picked.isEmpty) return const [];
  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory(p.join(docs.path, 'yomihub_bookshelf', 'photos'));
  if (!await dir.exists()) await dir.create(recursive: true);

  final out = <String>[];
  final stamp = DateTime.now().microsecondsSinceEpoch;
  for (var i = 0; i < picked.length; i++) {
    final file = picked[i];
    final rawBytes = await file.readAsBytes();
    if (rawBytes.isEmpty) continue;
    var savedBytes = rawBytes;
    try {
      final decoded = img.decodeImage(rawBytes);
      if (decoded != null) {
        final resized = decoded.width > 1280
            ? img.copyResize(decoded, width: 1280)
            : decoded;
        savedBytes = img.encodeJpg(resized, quality: 82);
      }
    } catch (_) {
      savedBytes = rawBytes;
    }
    final destPath = p.join(dir.path, 'bs_${stamp}_$i.jpg');
    await File(destPath).writeAsBytes(savedBytes);
    out.add(destPath);
  }
  return out;
}

/// Renders either an online URL (via YomiHub's extended_image helper) or a
/// local image file path (via ExtendedImage.file), with graceful fallback.
class BsCoverImage extends StatelessWidget {
  const BsCoverImage({
    super.key,
    required this.source,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.fallbackTitle = '',
    this.fit = BoxFit.cover,
  });

  final String source;
  final double? width;
  final double? height;
  final double borderRadius;
  final String fallbackTitle;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final trimmed = source.trim();
    final isUrl =
        trimmed.startsWith('http://') || trimmed.startsWith('https://');

    Widget placeholder() => Container(
          width: width,
          height: height,
          color: cs.surfaceContainerHighest,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu_book_outlined,
                  color: cs.onSurfaceVariant, size: (width ?? 64) < 56 ? 20 : 28),
              if (fallbackTitle.isNotEmpty && (width == null || width! >= 64))
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    fallbackTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
            ],
          ),
        );

    Widget content;
    if (trimmed.isEmpty) {
      content = placeholder();
    } else if (isUrl) {
      content = cachedNetworkImage(
        imageUrl: trimmed,
        width: width,
        height: height,
        fit: fit,
        errorWidget: placeholder(),
      );
    } else {
      final file = File(trimmed);
      content = ExtendedImage.file(
        file,
        width: width,
        height: height,
        fit: fit,
        loadStateChanged: (state) {
          if (state.extendedImageLoadState == LoadState.failed) {
            return placeholder();
          }
          return null;
        },
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(width: width, height: height, child: content),
    );
  }
}

/// Ownership pill badge for search hits (FN-02).
class BsOwnershipBadge extends StatelessWidget {
  const BsOwnershipBadge({
    super.key,
    required this.ownership,
    this.compact = false,
  });

  final BsOwnership ownership;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, IconData icon, String text) = switch (ownership) {
      BsOwnership.owned => (
          Colors.green.shade700,
          Colors.white,
          Icons.check_circle_outline,
          tr('Đã có'),
        ),
      BsOwnership.regularOnly => (
          Colors.orange.shade800,
          Colors.white,
          Icons.star_half_rounded,
          compact ? tr('Có bản thường') : tr('Có bản thường – chưa Limited'),
        ),
      BsOwnership.missing => (
          Colors.red.shade700,
          Colors.white,
          Icons.shopping_bag_outlined,
          tr('Chưa mua'),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen interactive viewer for item photos (FN-14 / FN-21).
Future<void> showBsPhotoViewer(BuildContext context, String source,
    {String? title}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black87,
          foregroundColor: Colors.white,
          title: Text(title ?? tr('Ảnh thực tế')),
        ),
        body: Center(
          child: InteractiveViewer(
            maxScale: 6,
            child: BsCoverImage(
              source: source,
              borderRadius: 0,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    ),
  );
}

/// Creates or edits a [BsSeries] including aliases (FN-23).
Future<BsSeries?> showBsSeriesFormDialog(
  BuildContext context, {
  BsSeries? existing,
  String? initialTitle,
  String? initialOriginal,
  String? initialAuthor,
  String? initialPublisher,
  String? initialCover,
  String? initialSynopsis,
}) async {
  final titleCtrl = TextEditingController(text: existing?.title ?? initialTitle ?? '');
  final originalCtrl =
      TextEditingController(text: existing?.original ?? initialOriginal ?? '');
  final authorCtrl =
      TextEditingController(text: existing?.author ?? initialAuthor ?? '');
  final pubCtrl =
      TextEditingController(text: existing?.publisher ?? initialPublisher ?? '');
  final totalCtrl = TextEditingController(
      text: existing?.totalVolumes == null ? '' : '${existing!.totalVolumes}');
  final aliasesCtrl =
      TextEditingController(text: existing?.aliases.join(', ') ?? '');
  final coverCtrl =
      TextEditingController(text: existing?.cover ?? initialCover ?? '');
  final synopsisCtrl =
      TextEditingController(text: existing?.synopsis ?? initialSynopsis ?? '');
  var status = existing?.status ?? BsStatus.ongoing;
  String? error;

  final result = await showDialog<BsSeries>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(existing == null ? tr('Thêm bộ truyện mới') : tr('Sửa thông tin bộ truyện')),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: titleCtrl,
                  autofocus: existing == null,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: tr('Tên bộ truyện'),
                    errorText: error,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: originalCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: tr('Tên gốc (tùy chọn)'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: aliasesCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: tr('Tên gọi khác (cách nhau bởi dấu phẩy)'),
                    hintText: 'JJK, Jujutsu Kaisen',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: authorCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: tr('Tác giả'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 120,
                      child: TextField(
                        controller: totalCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: tr('Tổng số tập'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: pubCtrl,
                  decoration: InputDecoration(
                    labelText: tr('Nhà xuất bản'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final pub in kBsCommonPublishers)
                      ActionChip(
                        label: Text(pub, style: const TextStyle(fontSize: 12)),
                        onPressed: () => setState(() => pubCtrl.text = pub),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<BsStatus>(
                  initialValue: status,
                  decoration: InputDecoration(
                    labelText: tr('Trạng thái phát hành'),
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    for (final s in BsStatus.values)
                      DropdownMenuItem(value: s, child: Text(bsStatusLabel(s))),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => status = v);
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: coverCtrl,
                        decoration: InputDecoration(
                          labelText: tr('Ảnh bìa (URL hoặc đường dẫn tệp)'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton.filledTonal(
                      tooltip: tr('Chọn ảnh bìa từ máy'),
                      icon: const Icon(Icons.photo_library_outlined),
                      onPressed: () async {
                        final paths =
                            await bsPickAndSavePhotos(allowMultiple: false);
                        if (paths.isNotEmpty && ctx.mounted) {
                          setState(() => coverCtrl.text = paths.first);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: synopsisCtrl,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: tr('Tóm tắt nội dung'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('Huỷ')),
          ),
          FilledButton(
            onPressed: () async {
              final title = titleCtrl.text.trim();
              if (title.isEmpty) {
                setState(() => error = tr('Tên không được để trống'));
                return;
              }
              final aliases = aliasesCtrl.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
              final total = int.tryParse(totalCtrl.text.trim());
              final store = BookshelfStore.instance;
              late BsSeries saved;
              if (existing != null) {
                existing
                  ..title = title
                  ..original = originalCtrl.text.trim()
                  ..author = authorCtrl.text.trim()
                  ..publisher = pubCtrl.text.trim()
                  ..cover = coverCtrl.text.trim()
                  ..synopsis = synopsisCtrl.text.trim()
                  ..totalVolumes = total
                  ..status = status
                  ..aliases = aliases;
                saved = await store.saveSeries(existing);
              } else {
                saved = await store.saveSeries(
                  BsSeries(
                    id: BookshelfStore.newId('s'),
                    title: title,
                    original: originalCtrl.text.trim(),
                    author: authorCtrl.text.trim(),
                    publisher: pubCtrl.text.trim(),
                    cover: coverCtrl.text.trim(),
                    synopsis: synopsisCtrl.text.trim(),
                    totalVolumes: total,
                    status: status,
                    aliases: aliases,
                  ),
                );
              }
              if (ctx.mounted) Navigator.pop(ctx, saved);
            },
            child: Text(tr('Lưu')),
          ),
        ],
      ),
    ),
  );

  titleCtrl.dispose();
  originalCtrl.dispose();
  authorCtrl.dispose();
  pubCtrl.dispose();
  totalCtrl.dispose();
  aliasesCtrl.dispose();
  coverCtrl.dispose();
  synopsisCtrl.dispose();
  return result;
}

/// FN-26 duplicate warning dialog showing existing volume purchase date and
/// reference cover/photos, offering "Vẫn thêm (bản thứ 2)".
Future<bool> showBsDuplicateVolumeDialog(
  BuildContext context, {
  required BsSeries series,
  required BsVolume existing,
  List<String> referencePhotos = const [],
}) async {
  final thumbs = <String>[
    ...referencePhotos,
    if (series.cover.trim().isNotEmpty) series.cover.trim(),
  ];
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 36),
      title: Text(tr('Tập này đã có trong tủ!')),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${series.title} • ${tr('Tập số {p0}', {'p0': existing.numberText})} (${bsEditionLabel(existing.edition)})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(tr('Số bản đang có: {p0}', {'p0': existing.copies})),
            Text(tr('Ngày mua trước đó: {p0}',
                {'p0': bsFormatDate(existing.purchaseDate)})),
            if (existing.price != null)
              Text(tr('Giá mua: {p0}', {'p0': bsFormatMoney(existing.price)})),
            if (existing.place.isNotEmpty)
              Text(tr('Nơi mua: {p0}', {'p0': existing.place})),
            if (thumbs.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 86,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: thumbs.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => showBsPhotoViewer(ctx, thumbs[i]),
                    child: BsCoverImage(
                      source: thumbs[i],
                      width: 62,
                      height: 86,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(tr('Huỷ')),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade800),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(tr('Vẫn thêm (bản thứ 2)')),
        ),
      ],
    ),
  );
  return ok == true;
}

/// Adds or edits a volume with purchase price/place (FN-27), read status &
/// loan tracking (FN-28), and duplicate warning (FN-26).
Future<bool> showBsVolumeEditDialog(
  BuildContext context, {
  required BsSeries series,
  BsVolume? existing,
  double? initialNumber,
  BsEdition initialEdition = BsEdition.regular,
  String initialIsbn = '',
}) async {
  final numCtrl = TextEditingController(
      text: existing != null
          ? existing.numberText
          : (initialNumber != null ? BookshelfStore.fmt(initialNumber) : '1'));
  final isbnCtrl = TextEditingController(text: existing?.isbn ?? initialIsbn);
  final priceCtrl = TextEditingController(
      text: existing?.price == null ? '' : existing!.price!.toStringAsFixed(0));
  final placeCtrl = TextEditingController(text: existing?.place ?? '');
  final noteCtrl = TextEditingController(text: existing?.note ?? '');
  final borrowerCtrl = TextEditingController(text: existing?.borrower ?? '');

  var edition = existing?.edition ?? initialEdition;
  var copies = existing?.copies ?? 1;
  var readStatus = existing?.readStatus ?? BsReadStatus.unread;
  int? purchaseDate = existing?.purchaseDate;
  int? loanDue = existing?.loanDue;
  String? numErr;

  final changed = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(existing == null
            ? tr('Thêm tập vào {p0}', {'p0': series.title})
            : tr('Chi tiết Tập {p0}', {'p0': existing.numberText})),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: numCtrl,
                        enabled: existing == null,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          labelText: tr('Số tập'),
                          errorText: numErr,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: copies > 1
                              ? () => setState(() => copies--)
                              : null,
                        ),
                        Text('×$copies',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => setState(() => copies++),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SegmentedButton<BsEdition>(
                  showSelectedIcon: false,
                  segments: [
                    for (final e in BsEdition.values)
                      ButtonSegment(
                        value: e,
                        label: Text(bsEditionLabel(e),
                            style: const TextStyle(fontSize: 12)),
                      ),
                  ],
                  selected: {edition},
                  onSelectionChanged: (s) => setState(() => edition = s.first),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: isbnCtrl,
                  decoration: InputDecoration(
                    labelText: tr('Mã vạch ISBN'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: tr('Giá mua (VNĐ)'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          purchaseDate == null
                              ? tr('Ngày mua')
                              : bsFormatDate(purchaseDate),
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: purchaseDate == null
                                ? DateTime.now()
                                : DateTime.fromMillisecondsSinceEpoch(
                                    purchaseDate!),
                            firstDate: DateTime(1990),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(
                                () => purchaseDate = picked.millisecondsSinceEpoch);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: placeCtrl,
                  decoration: InputDecoration(
                    labelText: tr('Nơi mua'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final place in kBsCommonPlaces)
                      ActionChip(
                        label: Text(place, style: const TextStyle(fontSize: 12)),
                        onPressed: () => setState(() => placeCtrl.text = place),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<BsReadStatus>(
                  initialValue: readStatus,
                  decoration: InputDecoration(
                    labelText: tr('Trạng thái đọc'),
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    for (final rs in BsReadStatus.values)
                      DropdownMenuItem(
                          value: rs, child: Text(bsReadStatusLabel(rs))),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => readStatus = v);
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: borrowerCtrl,
                        decoration: InputDecoration(
                          labelText: tr('Người đang mượn (nếu có)'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.event_available, size: 16),
                      label: Text(
                        loanDue == null
                            ? tr('Hẹn trả')
                            : bsFormatDate(loanDue),
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: loanDue == null
                              ? DateTime.now().add(const Duration(days: 7))
                              : DateTime.fromMillisecondsSinceEpoch(loanDue!),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => loanDue = picked.millisecondsSinceEpoch);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: noteCtrl,
                  minLines: 2,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: tr('Ghi chú tình trạng sách'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (existing != null)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () async {
                await BookshelfStore.instance.removeVolume(existing.id);
                if (ctx.mounted) Navigator.pop(ctx, true);
              },
              child: Text(tr('Xoá')),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('Huỷ')),
          ),
          FilledButton(
            onPressed: () async {
              final numVal =
                  double.tryParse(numCtrl.text.trim().replaceAll(',', '.'));
              if (numVal == null) {
                setState(() => numErr = tr('Số tập không hợp lệ'));
                return;
              }
              final price = double.tryParse(
                  priceCtrl.text.trim().replaceAll(RegExp(r'[^0-9.]'), ''));
              final borrower = borrowerCtrl.text.trim();
              final store = BookshelfStore.instance;

              if (existing != null) {
                existing
                  ..edition = edition
                  ..isbn = bsToIsbn13(isbnCtrl.text) ?? bsCleanIsbn(isbnCtrl.text)
                  ..copies = copies
                  ..readStatus = readStatus
                  ..purchaseDate = purchaseDate
                  ..price = price
                  ..place = placeCtrl.text.trim()
                  ..note = noteCtrl.text.trim()
                  ..borrower = borrower.isEmpty ? null : borrower
                  ..loanDue = borrower.isEmpty ? null : loanDue;
                await store.saveVolume(existing);
              } else {
                final res = await store.addVolume(
                  series.id,
                  numVal,
                  edition: edition,
                  isbn: isbnCtrl.text,
                  price: price,
                  place: placeCtrl.text.trim(),
                );
                var target = res.volume;
                if (res.duplicate) {
                  if (!ctx.mounted) return;
                  final force = await showBsDuplicateVolumeDialog(
                    ctx,
                    series: series,
                    existing: res.volume,
                  );
                  if (!force) return;
                  final added = await store.addVolume(
                    series.id,
                    numVal,
                    edition: edition,
                    isbn: isbnCtrl.text,
                    price: price,
                    place: placeCtrl.text.trim(),
                    allowExtraCopy: true,
                  );
                  target = added.volume;
                } else {
                  target.copies = copies;
                }
                target
                  ..readStatus = readStatus
                  ..purchaseDate =
                      purchaseDate ?? DateTime.now().millisecondsSinceEpoch
                  ..note = noteCtrl.text.trim()
                  ..borrower = borrower.isEmpty ? null : borrower
                  ..loanDue = borrower.isEmpty ? null : loanDue;
                await store.saveVolume(target);
              }
              if (ctx.mounted) Navigator.pop(ctx, true);
            },
            child: Text(tr('Lưu')),
          ),
        ],
      ),
    ),
  );

  numCtrl.dispose();
  isbnCtrl.dispose();
  priceCtrl.dispose();
  placeCtrl.dispose();
  noteCtrl.dispose();
  borrowerCtrl.dispose();
  return changed == true;
}

/// FN-12 bulk select dialog ("1-50", "1-10, 12, 15").
Future<int> showBsBulkSelectDialog(
  BuildContext context,
  BsSeries series, {
  BsEdition initialEdition = BsEdition.regular,
}) async {
  final rangeCtrl = TextEditingController(
    text: series.totalVolumes != null ? '1-${series.totalVolumes}' : '1-10',
  );
  var edition = initialEdition;
  var added = 0;

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final nums = bsParseRange(rangeCtrl.text);
        return AlertDialog(
          title: Text(tr('Chọn hàng loạt')),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: rangeCtrl,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: tr('Khoảng tập (vd: 1-50 hoặc 1-10, 15)'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final preset in const ['1-10', '1-25', '1-50', '1-100'])
                      ActionChip(
                        label: Text(preset),
                        onPressed: () =>
                            setState(() => rangeCtrl.text = preset),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                SegmentedButton<BsEdition>(
                  showSelectedIcon: false,
                  segments: [
                    for (final e in BsEdition.values)
                      ButtonSegment(
                        value: e,
                        label: Text(bsEditionLabel(e),
                            style: const TextStyle(fontSize: 12)),
                      ),
                  ],
                  selected: {edition},
                  onSelectionChanged: (s) =>
                      setState(() => edition = s.first),
                ),
                const SizedBox(height: 8),
                Text(
                  tr('Sẽ kiểm tra và thêm tối đa {p0} tập', {'p0': nums.length}),
                  style: Theme.of(ctx).textTheme.bodySmall,
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
              onPressed: nums.isEmpty
                  ? null
                  : () async {
                      added = await BookshelfStore.instance.addVolumes(
                        series.id,
                        nums,
                        edition: edition,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
              child: Text(tr('Thêm vào tủ')),
            ),
          ],
        );
      },
    ),
  );

  rangeCtrl.dispose();
  return added;
}

/// FN-13 create or rename custom folder (Limited, Artbook & ColorWalk, Boxset…).
Future<BsFolder?> showBsCreateFolderDialog(
  BuildContext context,
  String seriesId, {
  BsFolder? existing,
}) async {
  final ctrl = TextEditingController(
      text: existing?.name ?? tr('Bản Limited'));
  String? err;

  final out = await showDialog<BsFolder>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(existing == null
            ? tr('Tạo thư mục phiên bản khác')
            : tr('Đổi tên thư mục')),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: ctrl,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: tr('Tên thư mục'),
                  errorText: err,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final preset in bsFolderPresetLabels())
                    ActionChip(
                      label: Text(preset,
                          style: const TextStyle(fontSize: 12)),
                      onPressed: () => setState(() => ctrl.text = preset),
                    ),
                ],
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
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isEmpty) {
                setState(() => err = tr('Tên không được để trống'));
                return;
              }
              final store = BookshelfStore.instance;
              if (existing != null) {
                existing.name = name;
                await store.saveFolder(existing);
                if (ctx.mounted) Navigator.pop(ctx, existing);
              } else {
                final f = await store.addFolder(seriesId, name);
                if (ctx.mounted) Navigator.pop(ctx, f);
              }
            },
            child: Text(tr('Lưu')),
          ),
        ],
      ),
    ),
  );

  ctrl.dispose();
  return out;
}

/// FN-13 / FN-14 / FN-15: adds or edits a special [BsItem] inside [folder]
/// with accessory checkboxes (Postcard, Poster, Standee, Sealed) and photos.
Future<bool> showBsItemDialog(
  BuildContext context, {
  required BsFolder folder,
  BsItem? existing,
}) async {
  final nameCtrl = TextEditingController(text: existing?.name ?? '');
  final isbnCtrl = TextEditingController(text: existing?.isbn ?? '');
  final priceCtrl = TextEditingController(
      text: existing?.price == null ? '' : existing!.price!.toStringAsFixed(0));
  final storageCtrl = TextEditingController(text: existing?.storage ?? '');
  final notesCtrl = TextEditingController(text: existing?.notes ?? '');

  var postcard = existing?.postcard ?? false;
  var poster = existing?.poster ?? false;
  var standee = existing?.standee ?? false;
  var sealed = existing?.sealed ?? false;
  final photos = List<String>.from(existing?.photos ?? const []);
  String? err;

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(existing == null
            ? tr('Thêm ấn phẩm vào {p0}', {'p0': folder.name})
            : existing.name),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: nameCtrl,
                  autofocus: existing == null,
                  decoration: InputDecoration(
                    labelText: tr('Tên ấn phẩm (vd: Tập 105 Limited)'),
                    errorText: err,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: isbnCtrl,
                        decoration: InputDecoration(
                          labelText: tr('Mã vạch ISBN'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: tr('Giá mua (VNĐ)'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: storageCtrl,
                  decoration: InputDecoration(
                    labelText: tr('Vị trí cất giữ (vd: Tủ kính tầng 2)'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Text(tr('Phụ kiện đi kèm'),
                    style: Theme.of(ctx).textTheme.titleSmall),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: postcard,
                  onChanged: (v) => setState(() => postcard = v ?? false),
                  title: Text(tr('Có Postcard')),
                ),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: poster,
                  onChanged: (v) => setState(() => poster = v ?? false),
                  title: Text(tr('Có Poster')),
                ),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: standee,
                  onChanged: (v) => setState(() => standee = v ?? false),
                  title: Text(tr('Có Standee')),
                ),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: sealed,
                  onChanged: (v) => setState(() => sealed = v ?? false),
                  title: Text(tr('Nguyên Seal')),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        tr('Ảnh thực tế ({p0})', {'p0': photos.length}),
                        style: Theme.of(ctx).textTheme.titleSmall,
                      ),
                    ),
                    FilledButton.tonalIcon(
                      icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                      label: Text(tr('Thêm ảnh')),
                      onPressed: () async {
                        final added = await bsPickAndSavePhotos();
                        if (added.isNotEmpty && ctx.mounted) {
                          setState(() => photos.addAll(added));
                        }
                      },
                    ),
                  ],
                ),
                if (photos.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 92,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: photos.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => Stack(
                        children: [
                          GestureDetector(
                            onTap: () => showBsPhotoViewer(ctx, photos[i],
                                title: nameCtrl.text),
                            child: BsCoverImage(
                              source: photos[i],
                              width: 72,
                              height: 92,
                            ),
                          ),
                          Positioned(
                            right: 2,
                            top: 2,
                            child: InkWell(
                              onTap: () => setState(() => photos.removeAt(i)),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(2),
                                child: const Icon(Icons.close,
                                    color: Colors.white, size: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                TextField(
                  controller: notesCtrl,
                  minLines: 2,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: tr('Ghi chú'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (existing != null)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () async {
                folder.items.removeWhere((e) => e.id == existing.id);
                await BookshelfStore.instance.saveFolder(folder);
                if (ctx.mounted) Navigator.pop(ctx, true);
              },
              child: Text(tr('Xoá')),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('Huỷ')),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) {
                setState(() => err = tr('Tên không được để trống'));
                return;
              }
              final price = double.tryParse(
                  priceCtrl.text.trim().replaceAll(RegExp(r'[^0-9.]'), ''));
              final isbn =
                  bsToIsbn13(isbnCtrl.text) ?? bsCleanIsbn(isbnCtrl.text);
              if (existing != null) {
                existing
                  ..name = name
                  ..isbn = isbn
                  ..postcard = postcard
                  ..poster = poster
                  ..standee = standee
                  ..sealed = sealed
                  ..notes = notesCtrl.text.trim()
                  ..storage = storageCtrl.text.trim()
                  ..price = price
                  ..photos = photos;
              } else {
                folder.items.add(
                  BsItem(
                    id: BookshelfStore.newId('i'),
                    name: name,
                    isbn: isbn,
                    postcard: postcard,
                    poster: poster,
                    standee: standee,
                    sealed: sealed,
                    notes: notesCtrl.text.trim(),
                    storage: storageCtrl.text.trim(),
                    price: price,
                    photos: photos,
                  ),
                );
              }
              await BookshelfStore.instance.saveFolder(folder);
              if (ctx.mounted) Navigator.pop(ctx, true);
            },
            child: Text(tr('Lưu')),
          ),
        ],
      ),
    ),
  );

  nameCtrl.dispose();
  isbnCtrl.dispose();
  priceCtrl.dispose();
  storageCtrl.dispose();
  notesCtrl.dispose();
  return ok == true;
}

/// Adds an entry to the wishlist / shopping list (FN-17 / FN-25).
Future<BsWish?> showBsAddWishDialog(
  BuildContext context, {
  BsSeries? preselectedSeries,
}) async {
  final store = BookshelfStore.instance;
  final allSeries = store.series;
  if (allSeries.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr('Hãy tạo ít nhất một bộ truyện trước'))),
    );
    return null;
  }
  var selected = preselectedSeries ?? allSeries.first;
  final volCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  var edition = BsEdition.regular;

  final wish = await showDialog<BsWish>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(tr('Thêm vào Cần mua')),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selected.id,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: tr('Bộ truyện'),
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (final s in allSeries)
                    DropdownMenuItem(
                      value: s.id,
                      child: Text(s.title, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (id) {
                  final s = store.seriesById(id ?? '');
                  if (s != null) setState(() => selected = s);
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: volCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: tr('Số tập (bỏ trống nếu cả bộ / ấn phẩm)'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              SegmentedButton<BsEdition>(
                showSelectedIcon: false,
                segments: [
                  for (final e in BsEdition.values)
                    ButtonSegment(
                      value: e,
                      label: Text(bsEditionLabel(e),
                          style: const TextStyle(fontSize: 12)),
                    ),
                ],
                selected: {edition},
                onSelectionChanged: (s) => setState(() => edition = s.first),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: noteCtrl,
                decoration: InputDecoration(
                  labelText: tr('Ghi chú'),
                  border: const OutlineInputBorder(),
                ),
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
            onPressed: () async {
              final vol = double.tryParse(
                  volCtrl.text.trim().replaceAll(',', '.'));
              final added = await store.addWish(
                selected.id,
                volume: vol,
                edition: edition,
                note: noteCtrl.text.trim(),
              );
              if (ctx.mounted) Navigator.pop(ctx, added);
            },
            child: Text(tr('Thêm')),
          ),
        ],
      ),
    ),
  );

  volCtrl.dispose();
  noteCtrl.dispose();
  return wish;
}
