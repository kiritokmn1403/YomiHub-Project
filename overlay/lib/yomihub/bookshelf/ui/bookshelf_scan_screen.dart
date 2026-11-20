import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mangayomi/yomihub/bookshelf/bookshelf_logic.dart';
import 'package:mangayomi/yomihub/bookshelf/bookshelf_models.dart';
import 'package:mangayomi/yomihub/bookshelf/bookshelf_store.dart';
import 'package:mangayomi/yomihub/bookshelf/ui/bookshelf_dialogs.dart';
import 'package:mangayomi/yomihub/bookshelf/ui/bookshelf_series_screen.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

enum _BatchStatus { lookingUp, matched, owned, notFound, saved }

class _BatchEntry {
  _BatchEntry({
    required this.isbn,
    this.status = _BatchStatus.lookingUp,
    this.lookup,
    this.matchedSeries,
    this.ownedVolume,
    this.title = '',
    this.author = '',
    this.publisher = '',
    this.cover = '',
    this.volume = 1,
    this.edition = BsEdition.regular,
    this.allowExtraCopy = false,
    this.selected = false,
  });

  final String isbn;
  _BatchStatus status;
  BsLookup? lookup;
  BsSeries? matchedSeries;
  BsVolume? ownedVolume;
  String title;
  String author;
  String publisher;
  String cover;
  double volume;
  BsEdition edition;
  bool allowExtraCopy;
  bool selected;
}

/// Barcode / ISBN scanner screen (FN-07, FN-08, FN-09, FN-19, FN-20, FN-21).
class BookshelfScanScreen extends StatefulWidget {
  const BookshelfScanScreen({super.key, this.preselectedSeriesId});

  final String? preselectedSeriesId;

  @override
  State<BookshelfScanScreen> createState() => _BookshelfScanScreenState();
}

class _BookshelfScanScreenState extends State<BookshelfScanScreen> {
  final BookshelfStore _store = BookshelfStore.instance;
  final TextEditingController _isbnCtrl = TextEditingController();
  final Map<String, DateTime> _cooldown = {};
  final List<_BatchEntry> _batch = [];

  MobileScannerController? _cam;
  bool _batchMode = false;
  bool _handling = false;
  bool _lookingUp = false;
  bool _torchOn = false;

  bool get _hasCamera => Platform.isAndroid || Platform.isIOS;

  @override
  void initState() {
    super.initState();
    _store.init();
    if (_hasCamera) {
      _cam = MobileScannerController(
        formats: const [
          BarcodeFormat.ean13,
          BarcodeFormat.ean8,
          BarcodeFormat.upcA,
        ],
        detectionSpeed: DetectionSpeed.normal,
      );
    }
  }

  @override
  void dispose() {
    _cam?.dispose();
    _isbnCtrl.dispose();
    super.dispose();
  }

  String _normalizeScan(String raw) => bsToIsbn13(raw) ?? bsCleanIsbn(raw);

  Future<void> _onBarcode(String? raw) async {
    if (raw == null || raw.trim().isEmpty) return;
    final isbn = _normalizeScan(raw);
    if (isbn.length < 8) return;

    final now = DateTime.now();
    final prev = _cooldown[isbn];
    if (prev != null && now.difference(prev) < const Duration(seconds: 3)) {
      return;
    }
    _cooldown[isbn] = now;
    HapticFeedback.mediumImpact();

    if (_batchMode) {
      await _enqueueBatch(isbn);
    } else {
      await _handleSingle(isbn);
    }
  }

  Future<void> _submitManual() async {
    final raw = _isbnCtrl.text.trim();
    if (raw.isEmpty) return;
    final isbn = _normalizeScan(raw);
    if (isbn.length < 8) {
      _snack(tr('Mã ISBN không hợp lệ (cần 8–13 chữ số)'));
      return;
    }
    _isbnCtrl.clear();
    if (_batchMode) {
      await _enqueueBatch(isbn);
    } else {
      await _handleSingle(isbn);
    }
  }

  Future<void> _scanFromImage() async {
    final res = await FilePicker.pickFiles(type: FileType.image);
    final path = res.isEmpty ? null : res.first.path;
    if (path == null) return;
    if (_cam == null) {
      _snack(tr('Nhập mã ISBN thủ công ở ô bên dưới'));
      return;
    }
    final cap = await _cam!.analyzeImage(path);
    final barcodes = cap?.barcodes ?? const [];
    final raw = barcodes.isEmpty ? null : barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) {
      _snack(tr('Không tìm thấy mã vạch ISBN trong ảnh'));
      return;
    }
    await _onBarcode(raw);
  }

  List<String> _photosForSeries(String seriesId) {
    final photos = <String>[];
    for (final f in _store.foldersOf(seriesId)) {
      for (final item in f.items) {
        photos.addAll(item.photos);
      }
    }
    return photos;
  }

  Future<void> _handleSingle(String isbn) async {
    if (_handling) return;
    _handling = true;
    try {
      await _cam?.stop();
    } catch (_) {}

    try {
      final owned = _store.volumesByIsbn(isbn);
      if (owned.isNotEmpty) {
        await _showAlreadyOwnedFlow(isbn, owned.first);
        return;
      }

      if (mounted) setState(() => _lookingUp = true);
      final lookup = await _store.lookupIsbn(isbn);
      if (mounted) setState(() => _lookingUp = false);
      if (!mounted) return;

      if (lookup != null && lookup.title.trim().isNotEmpty) {
        final matched = _store.matchSeries(lookup.title) ??
            (widget.preselectedSeriesId == null
                ? null
                : _store.seriesById(widget.preselectedSeriesId!));
        if (matched != null) {
          await _showAddToMatchedFlow(isbn, matched, lookup);
        } else {
          await _showCreateFromLookupFlow(isbn, lookup);
        }
      } else {
        await _showQuickCreateFlow(isbn);
      }
    } finally {
      if (mounted) setState(() => _lookingUp = false);
      _handling = false;
      if (mounted && _cam != null) {
        try {
          await _cam!.start();
        } catch (_) {}
      }
    }
  }

  /// FN-08 / FN-21: Red alert "BẠN ĐÃ CÓ TẬP NÀY!" + ask Regular vs Limited
  /// because regular and limited editions in Vietnam often share one ISBN.
  Future<void> _showAlreadyOwnedFlow(String isbn, BsVolume existing) async {
    final series = _store.seriesById(existing.seriesId);
    final seriesTitle = series?.title ?? tr('Tủ sách của bạn');
    final refPhotos = <String>[
      ..._photosForSeries(existing.seriesId),
      if ((series?.cover ?? '').trim().isNotEmpty) series!.cover.trim(),
    ];

    await _store.recordScan(
      BsScan(
        isbn: isbn,
        at: DateTime.now().millisecondsSinceEpoch,
        title: '$seriesTitle #${existing.numberText}',
        result: 'owned',
      ),
    );
    if (!mounted) return;

    final chosen = await showDialog<BsEdition>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        icon: const Icon(Icons.error_rounded, color: Colors.red, size: 42),
        title: Text(
          tr('BẠN ĐÃ CÓ TẬP NÀY!'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.red.shade700,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade400),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$seriesTitle • ${tr('Tập số {p0}', {'p0': existing.numberText})}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(tr('Phiên bản đang có: {p0} (×{p1})', {
                        'p0': bsEditionLabel(existing.edition),
                        'p1': existing.copies,
                      })),
                      Text(tr('Ngày mua: {p0}',
                          {'p0': bsFormatDate(existing.purchaseDate)})),
                    ],
                  ),
                ),
                if (refPhotos.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    tr('Ảnh đối chiếu trong tủ:'),
                    style: Theme.of(ctx).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 86,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: refPhotos.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => GestureDetector(
                        onTap: () => showBsPhotoViewer(ctx, refPhotos[i],
                            title: seriesTitle),
                        child: BsCoverImage(
                          source: refPhotos[i],
                          width: 62,
                          height: 86,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  tr('Bạn đang cầm bản Thường hay Limited?'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('Bỏ qua')),
          ),
          Wrap(
            spacing: 6,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx, BsEdition.regular),
                child: Text(tr('Bản thường')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, BsEdition.limited),
                child: Text(tr('Bản Limited')),
              ),
              FilledButton.tonal(
                onPressed: () => Navigator.pop(ctx, BsEdition.special),
                child: Text(tr('Bản đặc biệt')),
              ),
            ],
          ),
        ],
      ),
    );

    if (chosen == null || !mounted || series == null) return;
    final res = await _store.addVolume(
      series.id,
      existing.number,
      edition: chosen,
      isbn: isbn,
    );
    if (!mounted) return;
    if (res.duplicate) {
      final force = await showBsDuplicateVolumeDialog(
        context,
        series: series,
        existing: res.volume,
        referencePhotos: refPhotos,
      );
      if (!force) return;
      await _store.addVolume(
        series.id,
        existing.number,
        edition: chosen,
        isbn: isbn,
        allowExtraCopy: true,
      );
    }
    await _store.recordScan(
      BsScan(
        isbn: isbn,
        at: DateTime.now().millisecondsSinceEpoch,
        title: '${series.title} #${existing.numberText}',
        result: 'added',
      ),
    );
    _snack(tr('Đã thêm {p0} – Tập {p1} ({p2})', {
      'p0': series.title,
      'p1': existing.numberText,
      'p2': bsEditionLabel(chosen),
    }));
  }

  /// FN-19: Scanned ISBN matches an existing series -> "Thêm Tập X vào bộ Y?"
  Future<void> _showAddToMatchedFlow(
    String isbn,
    BsSeries matched,
    BsLookup lookup,
  ) async {
    var selectedSeries = matched;
    final nextGuess = (_store.latestOf(matched.id) ?? 0).floorToDouble() + 1;
    final volCtrl = TextEditingController(
      text: BookshelfStore.fmt(lookup.volume ?? nextGuess),
    );
    var edition = BsEdition.regular;

    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(tr('Thêm Tập {p0} vào bộ {p1}?', {
            'p0': volCtrl.text.trim(),
            'p1': selectedSeries.title,
          })),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      BsCoverImage(
                        source: lookup.cover.isNotEmpty
                            ? lookup.cover
                            : selectedSeries.cover,
                        width: 56,
                        height: 82,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(lookup.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            if (lookup.publisher.isNotEmpty)
                              Text(lookup.publisher,
                                  style: Theme.of(ctx).textTheme.bodySmall),
                            Text('ISBN: $isbn',
                                style: Theme.of(ctx).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedSeries.id,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: tr('Bộ truyện'),
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      for (final s in _store.series)
                        DropdownMenuItem(
                          value: s.id,
                          child: Text(s.title, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (id) {
                      final s = _store.seriesById(id ?? '');
                      if (s != null) setState(() => selectedSeries = s);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: volCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: tr('Số tập'),
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
                    onSelectionChanged: (sel) =>
                        setState(() => edition = sel.first),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'skip'),
              child: Text(tr('Huỷ')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'new'),
              child: Text(tr('Tạo bộ mới')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, 'add'),
              child: Text(tr('Thêm')),
            ),
          ],
        ),
      ),
    );

    final volNum =
        double.tryParse(volCtrl.text.trim().replaceAll(',', '.')) ?? 1;
    volCtrl.dispose();

    if (action == 'new' && mounted) {
      await _showCreateFromLookupFlow(isbn, lookup);
      return;
    }
    if (action != 'add' || !mounted) {
      await _store.recordScan(BsScan(
        isbn: isbn,
        at: DateTime.now().millisecondsSinceEpoch,
        title: lookup.title,
        result: 'skipped',
      ));
      return;
    }

    final res = await _store.addVolume(
      selectedSeries.id,
      volNum,
      edition: edition,
      isbn: isbn,
    );
    if (res.duplicate && mounted) {
      final force = await showBsDuplicateVolumeDialog(
        context,
        series: selectedSeries,
        existing: res.volume,
      );
      if (!force) return;
      await _store.addVolume(
        selectedSeries.id,
        volNum,
        edition: edition,
        isbn: isbn,
        allowExtraCopy: true,
      );
    }
    await _store.recordScan(BsScan(
      isbn: isbn,
      at: DateTime.now().millisecondsSinceEpoch,
      title: '${selectedSeries.title} #${BookshelfStore.fmt(volNum)}',
      result: 'added',
    ));
    _snack(tr('Đã thêm Tập {p0} vào {p1}', {
      'p0': BookshelfStore.fmt(volNum),
      'p1': selectedSeries.title,
    }));
  }

  /// FN-19: New series prefilled from Google Books / Open Library metadata.
  Future<void> _showCreateFromLookupFlow(String isbn, BsLookup lookup) async {
    final guessTitle = bsSeriesKey(lookup.title).isNotEmpty
        ? lookup.title.replaceAll(
            RegExp(r'\s*[-–]?\s*(Tập|Vol\.?|Volume)\s*\d+.*$',
                caseSensitive: false),
            '',
          ).trim()
        : lookup.title;
    final titleCtrl =
        TextEditingController(text: guessTitle.isEmpty ? lookup.title : guessTitle);
    final pubCtrl = TextEditingController(text: lookup.publisher);
    final volCtrl =
        TextEditingController(text: BookshelfStore.fmt(lookup.volume ?? 1));
    var edition = BsEdition.regular;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(tr('Tạo bộ truyện mới?')),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      BsCoverImage(
                        source: lookup.cover,
                        width: 56,
                        height: 82,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(lookup.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            if (lookup.author.isNotEmpty)
                              Text(lookup.author,
                                  style: Theme.of(ctx).textTheme.bodySmall),
                            Text('ISBN: $isbn',
                                style: Theme.of(ctx).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: tr('Tên bộ truyện'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: volCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            labelText: tr('Số tập'),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: pubCtrl,
                          decoration: InputDecoration(
                            labelText: tr('Nhà xuất bản'),
                            border: const OutlineInputBorder(),
                          ),
                        ),
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
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('Huỷ')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr('Tạo & Thêm tập')),
            ),
          ],
        ),
      ),
    );

    final title = titleCtrl.text.trim();
    final pub = pubCtrl.text.trim();
    final volNum =
        double.tryParse(volCtrl.text.trim().replaceAll(',', '.')) ?? 1;
    titleCtrl.dispose();
    pubCtrl.dispose();
    volCtrl.dispose();

    if (confirmed != true || title.isEmpty || !mounted) {
      await _store.recordScan(BsScan(
        isbn: isbn,
        at: DateTime.now().millisecondsSinceEpoch,
        title: lookup.title,
        result: 'skipped',
      ));
      return;
    }

    final series = await _store.createSeries(
      title,
      author: lookup.author,
      publisher: pub,
      cover: lookup.cover,
      synopsis: lookup.synopsis,
    );
    await _store.addVolume(series.id, volNum, edition: edition, isbn: isbn);
    await _store.recordScan(BsScan(
      isbn: isbn,
      at: DateTime.now().millisecondsSinceEpoch,
      title: '$title #${BookshelfStore.fmt(volNum)}',
      result: 'added',
    ));
    _snack(tr('Đã tạo bộ "{p0}" và thêm Tập {p1}', {
      'p0': series.title,
      'p1': BookshelfStore.fmt(volNum),
    }));
  }

  /// FN-09: Quick 3-field create form when online ISBN lookup returns nothing.
  Future<({BsSeries series, double volume, BsEdition edition})?>
      _showQuickCreateFlow(String isbn, {bool recordOnCancel = true}) async {
    final titleCtrl = TextEditingController();
    final volCtrl = TextEditingController(text: '1');
    final pubCtrl = TextEditingController();
    var edition = BsEdition.regular;
    var coverPath = '';
    BsSeries? pickedExisting;
    String? err;

    final preselected = widget.preselectedSeriesId == null
        ? null
        : _store.seriesById(widget.preselectedSeriesId!);
    if (preselected != null) {
      pickedExisting = preselected;
      titleCtrl.text = preselected.title;
      pubCtrl.text = preselected.publisher;
      final next = (_store.latestOf(preselected.id) ?? 0).floorToDouble() + 1;
      volCtrl.text = BookshelfStore.fmt(next);
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final q = titleCtrl.text.trim();
          final suggestions = q.isEmpty
              ? _store.series.take(5).toList()
              : _store.search(q, limit: 5).map((h) => h.series).toList();
          return AlertDialog(
            title: Text(tr('Tạo mới nhanh (chưa có trên mạng)')),
            content: SizedBox(
              width: 430,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      tr('Không thấy thông tin ISBN {p0} trên Google Books / Open Library. Điền nhanh 3 ô để lưu ngay:',
                          {'p0': isbn}),
                      style: Theme.of(ctx).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: titleCtrl,
                      autofocus: preselected == null,
                      onChanged: (_) => setState(() {
                        pickedExisting = null;
                        err = null;
                      }),
                      decoration: InputDecoration(
                        labelText: tr('1. Tên bộ truyện'),
                        errorText: err,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    if (suggestions.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (final s in suggestions)
                            ChoiceChip(
                              label: Text(s.title,
                                  style: const TextStyle(fontSize: 12)),
                              selected: pickedExisting?.id == s.id,
                              onSelected: (_) => setState(() {
                                pickedExisting = s;
                                titleCtrl.text = s.title;
                                if (pubCtrl.text.trim().isEmpty) {
                                  pubCtrl.text = s.publisher;
                                }
                                final next =
                                    (_store.latestOf(s.id) ?? 0).floorToDouble() +
                                        1;
                                volCtrl.text = BookshelfStore.fmt(next);
                              }),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: volCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              labelText: tr('2. Tập số'),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: pubCtrl,
                            decoration: InputDecoration(
                              labelText: tr('3. Nhà xuất bản'),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final pub in kBsCommonPublishers)
                          ActionChip(
                            label: Text(pub,
                                style: const TextStyle(fontSize: 11)),
                            onPressed: () => setState(() => pubCtrl.text = pub),
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
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.photo_camera_outlined),
                            label: Text(coverPath.isEmpty
                                ? tr('Chọn / chụp ảnh bìa')
                                : tr('Đã chọn ảnh bìa')),
                            onPressed: () async {
                              final paths = await bsPickAndSavePhotos(
                                  allowMultiple: false);
                              // 0.6.3 review: the dialog may be closed while the picker is open
                              if (paths.isNotEmpty && ctx.mounted) {
                                setState(() => coverPath = paths.first);
                              }
                            },
                          ),
                        ),
                        if (coverPath.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          BsCoverImage(
                              source: coverPath, width: 38, height: 52),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(tr('Huỷ')),
              ),
              FilledButton(
                onPressed: () {
                  if (titleCtrl.text.trim().isEmpty) {
                    setState(() => err = tr('Tên không được để trống'));
                    return;
                  }
                  Navigator.pop(ctx, true);
                },
                child: Text(tr('Lưu vào tủ')),
              ),
            ],
          );
        },
      ),
    );

    final title = titleCtrl.text.trim();
    final pub = pubCtrl.text.trim();
    final volNum =
        double.tryParse(volCtrl.text.trim().replaceAll(',', '.')) ?? 1;
    titleCtrl.dispose();
    volCtrl.dispose();
    pubCtrl.dispose();

    if (ok != true || title.isEmpty || !mounted) {
      if (recordOnCancel) {
        await _store.recordScan(BsScan(
          isbn: isbn,
          at: DateTime.now().millisecondsSinceEpoch,
          result: 'notFound',
        ));
      }
      return null;
    }

    var targetSeries = pickedExisting;
    if (targetSeries == null) {
      final norm = bsNormalize(title);
      for (final s in _store.series) {
        if (bsNormalize(s.title) == norm) {
          targetSeries = s;
          break;
        }
      }
      targetSeries ??= await _store.createSeries(
        title,
        publisher: pub,
        cover: coverPath,
      );
    }

    final res = await _store.addVolume(
      targetSeries.id,
      volNum,
      edition: edition,
      isbn: isbn,
    );
    if (res.duplicate && mounted) {
      final force = await showBsDuplicateVolumeDialog(
        context,
        series: targetSeries,
        existing: res.volume,
      );
      if (!force) return null;
      await _store.addVolume(
        targetSeries.id,
        volNum,
        edition: edition,
        isbn: isbn,
        allowExtraCopy: true,
      );
    }

    await _store.recordScan(BsScan(
      isbn: isbn,
      at: DateTime.now().millisecondsSinceEpoch,
      title: '${targetSeries.title} #${BookshelfStore.fmt(volNum)}',
      result: 'added',
    ));
    _snack(tr('Đã thêm {p0} – Tập {p1}', {
      'p0': targetSeries.title,
      'p1': BookshelfStore.fmt(volNum),
    }));
    return (series: targetSeries, volume: volNum, edition: edition);
  }

  /// FN-20: Batch queue addition + background ISBN lookup.
  Future<void> _enqueueBatch(String isbn) async {
    final entry = _BatchEntry(isbn: isbn);
    setState(() => _batch.insert(0, entry));

    final owned = _store.volumesByIsbn(isbn);
    if (owned.isNotEmpty) {
      final first = owned.first;
      final s = _store.seriesById(first.seriesId);
      if (!mounted) return;
      setState(() {
        entry.status = _BatchStatus.owned;
        entry.matchedSeries = s;
        entry.ownedVolume = first;
        entry.title = s?.title ?? '';
        entry.volume = first.number;
        entry.edition = first.edition;
        entry.selected = false;
      });
      await _store.recordScan(BsScan(
        isbn: isbn,
        at: DateTime.now().millisecondsSinceEpoch,
        title: '${entry.title} #${first.numberText}',
        result: 'owned',
      ));
      return;
    }

    final lookup = await _store.lookupIsbn(isbn);
    if (!mounted) return;
    if (lookup != null && lookup.title.trim().isNotEmpty) {
      final matched = _store.matchSeries(lookup.title);
      setState(() {
        entry.lookup = lookup;
        entry.matchedSeries = matched;
        entry.status = _BatchStatus.matched;
        entry.title = matched?.title ??
            lookup.title
                .replaceAll(
                  RegExp(r'\s*[-–]?\s*(Tập|Vol\.?|Volume)\s*\d+.*$',
                      caseSensitive: false),
                  '',
                )
                .trim();
        entry.author = lookup.author;
        entry.publisher = lookup.publisher;
        entry.cover = lookup.cover;
        entry.volume = lookup.volume ??
            ((matched != null
                    ? (_store.latestOf(matched.id) ?? 0).floorToDouble() + 1
                    : 1));
        entry.selected = true;
      });
      await _store.recordScan(BsScan(
        isbn: isbn,
        at: DateTime.now().millisecondsSinceEpoch,
        title: lookup.title,
        result: matched != null ? 'added' : 'skipped',
      ));
    } else {
      setState(() {
        entry.status = _BatchStatus.notFound;
        entry.selected = false;
      });
      await _store.recordScan(BsScan(
        isbn: isbn,
        at: DateTime.now().millisecondsSinceEpoch,
        result: 'notFound',
      ));
    }
  }

  /// FN-20: End-of-session review screen to approve matched/owned/notFound items.
  Future<void> _openBatchReview() async {
    try {
      await _cam?.stop();
    } catch (_) {}

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final matchedCount =
              _batch.where((e) => e.status == _BatchStatus.matched).length;
          final ownedCount =
              _batch.where((e) => e.status == _BatchStatus.owned).length;
          final notFoundCount =
              _batch.where((e) => e.status == _BatchStatus.notFound).length;
          final readyCount = _batch.where((e) => e.selected).length;

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (_, scrollCtrl) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          tr('Duyệt quét hàng loạt ({p0})',
                              {'p0': _batch.length}),
                          style: Theme.of(ctx)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(tr('Đóng')),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Chip(
                        backgroundColor: Colors.green.withValues(alpha: 0.15),
                        label: Text(tr('Đã khớp: {p0}', {'p0': matchedCount})),
                      ),
                      Chip(
                        backgroundColor: Colors.orange.withValues(alpha: 0.15),
                        label: Text(tr('Đã có: {p0}', {'p0': ownedCount})),
                      ),
                      Chip(
                        backgroundColor: Colors.red.withValues(alpha: 0.15),
                        label: Text(
                            tr('Chưa tìm thấy: {p0}', {'p0': notFoundCount})),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    controller: scrollCtrl,
                    itemCount: _batch.length,
                    itemBuilder: (_, i) {
                      final e = _batch[i];
                      final statusColor = switch (e.status) {
                        _BatchStatus.lookingUp => Colors.grey,
                        _BatchStatus.matched => Colors.green,
                        _BatchStatus.owned => Colors.orange,
                        _BatchStatus.notFound => Colors.red,
                        _BatchStatus.saved => Colors.teal,
                      };
                      final statusText = switch (e.status) {
                        _BatchStatus.lookingUp => tr('Đang tra…'),
                        _BatchStatus.matched => e.matchedSeries != null
                            ? tr('Khớp bộ: {p0}', {'p0': e.matchedSeries!.title})
                            : tr('Bộ mới từ mạng'),
                        _BatchStatus.owned => tr('Đã có trong tủ!'),
                        _BatchStatus.notFound => tr('Chưa tìm thấy'),
                        _BatchStatus.saved => tr('Đã lưu'),
                      };

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        child: CheckboxListTile(
                          value: e.selected,
                          onChanged: (e.status == _BatchStatus.lookingUp ||
                                  e.status == _BatchStatus.saved)
                              ? null
                              : (v) {
                                  setSheet(() => e.selected = v ?? false);
                                  setState(() {});
                                },
                          title: Text(
                            e.title.isEmpty
                                ? 'ISBN ${e.isbn}'
                                : '${e.title} • ${tr('Tập số {p0}', {'p0': BookshelfStore.fmt(e.volume)})}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$statusText • ${e.isbn}',
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (e.status != _BatchStatus.lookingUp &&
                                  e.status != _BatchStatus.saved)
                                Wrap(
                                  spacing: 6,
                                  children: [
                                    for (final ed in BsEdition.values)
                                      ChoiceChip(
                                        visualDensity: VisualDensity.compact,
                                        label: Text(bsEditionLabel(ed),
                                            style:
                                                const TextStyle(fontSize: 11)),
                                        selected: e.edition == ed,
                                        onSelected: (_) {
                                          setSheet(() {
                                            e.edition = ed;
                                            if (e.status == _BatchStatus.owned) {
                                              e.allowExtraCopy =
                                                  e.ownedVolume?.edition == ed;
                                              e.selected = true;
                                            }
                                          });
                                          setState(() {});
                                        },
                                      ),
                                    if (e.status == _BatchStatus.notFound)
                                      ActionChip(
                                        visualDensity: VisualDensity.compact,
                                        label: Text(tr('Điền nhanh'),
                                            style:
                                                const TextStyle(fontSize: 11)),
                                        onPressed: () async {
                                          final created =
                                              await _showQuickCreateFlow(
                                            e.isbn,
                                            recordOnCancel: false,
                                          );
                                          if (created != null) {
                                            setSheet(() {
                                              e.matchedSeries = created.series;
                                              e.title = created.series.title;
                                              e.volume = created.volume;
                                              e.edition = created.edition;
                                              e.status = _BatchStatus.saved;
                                              e.selected = false;
                                            });
                                            setState(() {});
                                          }
                                        },
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() => _batch.clear());
                          Navigator.pop(ctx);
                        },
                        child: Text(tr('Xoá hàng chờ')),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        icon: const Icon(Icons.save_alt),
                        label: Text(tr('Lưu tất cả ({p0})', {'p0': readyCount})),
                        onPressed: readyCount == 0
                            ? null
                            : () async {
                                final saved = await _commitBatchSelections();
                                if (ctx.mounted) Navigator.pop(ctx);
                                _snack(tr('Đã lưu {p0} cuốn vào tủ',
                                    {'p0': saved}));
                              },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (mounted && _cam != null) {
      try {
        await _cam!.start();
      } catch (_) {}
    }
  }

  Future<int> _commitBatchSelections() async {
    var saved = 0;
    final createdByKey = <String, BsSeries>{};

    for (final e in _batch.where((x) => x.selected)) {
      var target = e.matchedSeries;
      if (target == null) {
        final key = bsNormalize(e.title);
        if (key.isEmpty) continue;
        target = createdByKey[key];
        if (target == null) {
          for (final s in _store.series) {
            if (bsNormalize(s.title) == key) {
              target = s;
              break;
            }
          }
        }
        if (target == null) {
          target = await _store.createSeries(
            e.title,
            author: e.author,
            publisher: e.publisher,
            cover: e.cover,
          );
          createdByKey[key] = target;
        }
      }

      final res = await _store.addVolume(
        target.id,
        e.volume,
        edition: e.edition,
        isbn: e.isbn,
        allowExtraCopy: e.allowExtraCopy,
      );
      if (!res.duplicate) saved++;
    }

    if (mounted) {
      setState(() => _batch.removeWhere((x) => x.selected));
    }
    return saved;
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Quét mã vạch ISBN')),
        actions: [
          if (_hasCamera)
            IconButton(
              tooltip: tr('Quét từ ảnh'),
              icon: const Icon(Icons.image_search_outlined),
              onPressed: _scanFromImage,
            ),
          if (_hasCamera)
            IconButton(
              tooltip: tr('Đèn flash'),
              icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
              onPressed: () {
                _cam?.toggleTorch();
                setState(() => _torchOn = !_torchOn);
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Batch scan mode toggle (FN-20)
          SwitchListTile(
            dense: true,
            secondary: const Icon(Icons.layers_outlined),
            title: Text(tr('Chế độ quét hàng loạt')),
            subtitle: Text(
              _batchMode
                  ? tr('Quét liên tục nhiều cuốn (chống trùng 3 giây), duyệt lại cuối phiên')
                  : tr('Quét từng cuốn để kiểm tra trùng tức thì tại quầy'),
            ),
            value: _batchMode,
            onChanged: (v) => setState(() => _batchMode = v),
          ),

          // Camera scanner or Windows manual info
          Expanded(
            flex: 5,
            child: _cam == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.qr_code_2,
                              size: 64, color: cs.primary.withValues(alpha: 0.7)),
                          const SizedBox(height: 12),
                          Text(
                            tr('Máy tính không có camera quét mã vạch tích hợp.\nHãy nhập mã ISBN-10 / ISBN-13 ở ô bên dưới để kiểm tra tủ sách và tra thông tin.'),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      MobileScanner(
                        controller: _cam!,
                        onDetect: (cap) => _onBarcode(
                          cap.barcodes.isEmpty
                              ? null
                              : cap.barcodes.first.rawValue,
                        ),
                        errorBuilder: (ctx, e) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              tr('Không mở được camera ({p0}). Hãy cấp quyền Camera cho YomiHub hoặc nhập ISBN thủ công.',
                                  {'p0': e.errorCode.name}),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Container(
                          width: 260,
                          height: 140,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _batchMode ? Colors.amber : Colors.white,
                              width: 2.5,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      if (_lookingUp)
                        Container(
                          color: Colors.black54,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 10),
                              Text(
                                tr('Đang tra thông tin sách…'),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),

          // Manual ISBN input
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _isbnCtrl,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _submitManual(),
                    decoration: InputDecoration(
                      isDense: true,
                      prefixIcon: const Icon(Icons.dialpad),
                      labelText: tr('Nhập mã ISBN thủ công'),
                      hintText: '978-604-2-...',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _submitManual,
                  child: Text(tr('Kiểm tra')),
                ),
              ],
            ),
          ),

          if (_batchMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.fact_check_outlined),
                  label: Text(
                    tr('Duyệt & Lưu phiên quét ({p0})', {'p0': _batch.length}),
                  ),
                  onPressed: _batch.isEmpty ? null : _openBatchReview,
                ),
              ),
            )
          else
            Expanded(
              flex: 3,
              child: ListenableBuilder(
                listenable: _store,
                builder: (_, _) {
                  final scans = _store.scans.take(15).toList();
                  if (scans.isEmpty) {
                    return Center(
                      child: Text(
                        tr('Đưa mã vạch sau bìa sách vào khung hoặc nhập ISBN để kiểm tra.'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: scans.length,
                    itemBuilder: (_, i) {
                      final sc = scans[i];
                      final (IconData ic, Color cl) = switch (sc.result) {
                        'owned' => (Icons.warning_amber_rounded, Colors.red),
                        'added' => (Icons.check_circle_outline, Colors.green),
                        'notFound' => (Icons.help_outline, Colors.orange),
                        _ => (Icons.history, cs.onSurfaceVariant),
                      };
                      return ListTile(
                        dense: true,
                        leading: Icon(ic, color: cl),
                        title: Text(
                          sc.title.isEmpty ? sc.isbn : sc.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text('${sc.isbn} • ${bsFormatDate(sc.at)}'),
                        onTap: () {
                          final own = _store.volumesByIsbn(sc.isbn);
                          if (own.isNotEmpty) {
                            Navigator.of(context, rootNavigator: true).push(
                              MaterialPageRoute(
                                builder: (_) => BookshelfSeriesScreen(
                                    seriesId: own.first.seriesId),
                              ),
                            );
                          } else {
                            _isbnCtrl.text = sc.isbn;
                            _submitManual();
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
