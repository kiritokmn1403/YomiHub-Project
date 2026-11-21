/// YomiHub 0.6.4 – UI for FN-16 (banner "Ấn phẩm liên quan tủ sách của bạn"),
/// FN-29 (news source settings) and FN-22 (cover photo recognition).
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mangayomi/yomihub/bookshelf/bookshelf_cover_match.dart';
import 'package:mangayomi/yomihub/bookshelf/bookshelf_feed.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:url_launcher/url_launcher.dart';

String bsFeedKindLabel(BsFeedKind k) => switch (k) {
      BsFeedKind.limited => tr('Bản Limited / đặc biệt'),
      BsFeedKind.artbook => tr('Artbook'),
      BsFeedKind.poster => tr('Poster'),
      BsFeedKind.colorwalk => tr('ColorWalk'),
      BsFeedKind.databook => tr('DataBook / Fanbook'),
      BsFeedKind.boxset => tr('Boxset'),
      BsFeedKind.regular => tr('Bản thường'),
    };

/// FN-16: horizontal banner of publisher news matching the shelf.
class BsFeedBanner extends StatelessWidget {
  const BsFeedBanner({super.key, required this.onOpenSeries});
  final void Function(String seriesId) onOpenSeries;

  @override
  Widget build(BuildContext context) {
    final feed = BookshelfFeed.instance;
    return ListenableBuilder(
      listenable: feed,
      builder: (context, _) {
        if (!feed.enabled) return const SizedBox.shrink();
        final items = feed.banners;
        final cs = Theme.of(context).colorScheme;
        final sourceName = {for (final s in feed.sources) s.id: s.name};
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.campaign_outlined, size: 20, color: cs.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(tr('Ấn phẩm liên quan tủ sách của bạn'),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                ),
                if (feed.busy)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else
                  IconButton(
                    tooltip: tr('Tải lại tin phát hành'),
                    icon: const Icon(Icons.refresh),
                    onPressed: () => feed.refresh(force: true),
                  ),
                IconButton(
                  tooltip: tr('Cài đặt thanh gợi ý & nguồn tin'),
                  icon: const Icon(Icons.tune),
                  onPressed: () => showBsFeedSettings(context),
                ),
              ],
            ),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  feed.lastError != null
                      ? tr('Chưa đọc được tin của một số NXB: {p0}', {'p0': feed.lastError!})
                      : tr('Chưa có ấn phẩm mới khớp với các bộ trong tủ sách.'),
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                ),
              )
            else
              SizedBox(
                height: 132,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final m = items[i];
                    return SizedBox(
                      width: 270,
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            final u = Uri.tryParse(m.item.link);
                            if (u != null) launchUrl(u, mode: LaunchMode.externalApplication);
                          },
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${sourceName[m.item.sourceId] ?? m.item.sourceId} · ${m.kinds.map(bsFeedKindLabel).join(', ')}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 11, color: cs.primary),
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      tooltip: tr('Tuỳ chọn'),
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(Icons.more_vert, size: 18),
                                      onSelected: (v) {
                                        if (v == 'hide') feed.dismiss(m.item);
                                        if (v == 'mute') feed.muteSeries(m.series.id);
                                        if (v == 'open') onOpenSeries(m.series.id);
                                      },
                                      itemBuilder: (_) => [
                                        PopupMenuItem(value: 'open', child: Text(tr('Mở bộ trong tủ sách'))),
                                        PopupMenuItem(value: 'hide', child: Text(tr('Ẩn tin này'))),
                                        PopupMenuItem(value: 'mute', child: Text(tr('Không quan tâm bộ này'))),
                                      ],
                                    ),
                                  ],
                                ),
                                Text(m.item.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                                const Spacer(),
                                Text(tr('Bộ trong tủ: {p0}', {'p0': m.series.title}),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

/// FN-29: settings of the banner and the news sources.
Future<void> showBsFeedSettings(BuildContext context) async {
  final feed = BookshelfFeed.instance;
  final sources = feed.sources;
  final kinds = feed.kinds;
  var enabled = feed.enabled;
  var max = feed.maxBanners.toDouble();
  final ctrls = {for (final s in sources) s.id: TextEditingController(text: s.url)};
  final saved = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(tr('Cài đặt thanh gợi ý & nguồn tin')),
        content: SizedBox(
          width: 520,
          child: ListView(
            shrinkWrap: true,
            children: [
              SwitchListTile(
                value: enabled,
                title: Text(tr('Hiện thanh "Ấn phẩm liên quan tủ sách của bạn"')),
                onChanged: (v) => setState(() => enabled = v),
              ),
              const Divider(),
              Text(tr('Nhà xuất bản'), style: const TextStyle(fontWeight: FontWeight.bold)),
              for (final s in sources) ...[
                CheckboxListTile(
                  value: s.enabled,
                  title: Text(s.name),
                  onChanged: (v) => setState(() => s.enabled = v ?? false),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    controller: ctrls[s.id],
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: tr('Địa chỉ trang sách mới / RSS'),
                      hintText: 'https://…',
                    ),
                  ),
                ),
              ],
              const Divider(),
              Text(tr('Loại tin quan tâm (không chọn = tất cả)'), style: const TextStyle(fontWeight: FontWeight.bold)),
              for (final k in BsFeedKind.values)
                CheckboxListTile(
                  dense: true,
                  value: kinds.contains(k),
                  title: Text(bsFeedKindLabel(k)),
                  onChanged: (v) => setState(() => v == true ? kinds.add(k) : kinds.remove(k)),
                ),
              const Divider(),
              Text(tr('Số tin tối đa trên thanh: {p0}', {'p0': max.round()})),
              Slider(value: max, min: 1, max: 20, divisions: 19, onChanged: (v) => setState(() => max = v)),
              TextButton.icon(
                icon: const Icon(Icons.restore),
                label: Text(tr('Hiện lại tin đã ẩn và các bộ đã bỏ quan tâm')),
                onPressed: () => feed.unmuteAll(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Huỷ'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Lưu'))),
        ],
      ),
    ),
  );
  if (saved == true) {
    for (final s in sources) {
      s.url = ctrls[s.id]!.text.trim();
    }
    await feed.setEnabled(enabled);
    await feed.setSources(sources);
    await feed.setKinds(kinds);
    await feed.setMaxBanners(max.round());
    await feed.refresh(force: true);
  }
  for (final c in ctrls.values) {
    c.dispose();
  }
}

/// FN-22: pick/take a photo of a cover → series that look alike.
Future<void> showBsCoverMatch(BuildContext context, {required void Function(String seriesId) onOpenSeries}) async {
  final files = await FilePicker.pickFiles(type: FileType.image);
  if (files.isEmpty || !context.mounted) return;
  final f = files.first;
  Uint8List? bytes;
  try {
    bytes = await f.readAsBytes();
  } catch (_) {
    if (f.path != null) bytes = await File(f.path!).readAsBytes();
  }
  if (bytes == null || !context.mounted) return;
  final data = bytes;
  final future = BookshelfCoverMatch.match(data);
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(tr('Nhận diện bìa bằng ảnh')),
      content: SizedBox(
        width: 460,
        child: FutureBuilder<List<BsCoverCandidate>>(
          future: future,
          builder: (ctx, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return Column(mainAxisSize: MainAxisSize.min, children: [
                const LinearProgressIndicator(),
                const SizedBox(height: 12),
                Text(tr('Đang so ảnh với bìa các bộ trong tủ sách…')),
              ]);
            }
            final list = snap.data ?? const [];
            if (snap.hasError || list.isEmpty) {
              return Text(tr('Không tìm thấy bộ nào có bìa giống ảnh này. Hãy chụp thẳng, đủ sáng, cả bìa – hoặc thêm ảnh bìa cho các bộ trong tủ sách.'));
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.memory(data, height: 140, fit: BoxFit.contain),
                const SizedBox(height: 8),
                for (final c in list)
                  ListTile(
                    leading: const Icon(Icons.menu_book_outlined),
                    title: Text(c.series.title),
                    subtitle: Text(tr('Giống {p0}%', {'p0': c.percent})),
                    onTap: () {
                      Navigator.pop(ctx);
                      onOpenSeries(c.series.id);
                    },
                  ),
              ],
            );
          },
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('Đóng')))],
    ),
  );
}
