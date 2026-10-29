import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mangayomi/models/source.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'package:mangayomi/utils/share.dart';
import 'package:mangayomi/utils/utils.dart';
import 'package:mangayomi/yomihub/extensions/url_override.dart';
import 'package:share_plus/share_plus.dart';

/// YomiHub 0.2.0: web link of an item / chapter / episode, for the share
/// buttons (chapter list, Short Video feed).
///
/// Works for every extension type: absolute links are kept, relative ones
/// get the source's base URL (after "Đổi URL"/"Cưỡng chế đổi URL"), and the
/// JSON links some extensions use ({"id":…}, {"url":…}) are unpacked.
class YomiShareLink {
  YomiShareLink._();

  static const _jsonHosts = <String, String>{
    'fikfap.com': 'https://fikfap.com/post/{id}',
    'youtube.com': 'https://www.youtube.com/watch?v={id}',
    'www.youtube.com': 'https://www.youtube.com/watch?v={id}',
  };

  static String webUrl(Source? source, String? link) {
    var l = (link ?? '').trim();
    if (l.isEmpty) return source?.baseUrl ?? '';
    final base = (YomiUrlOverride.baseUrlFor(source?.id, source?.baseUrl) ?? source?.baseUrl ?? '')
        .replaceAll(RegExp(r'/+$'), '');
    if (l.startsWith('{')) {
      try {
        final j = jsonDecode(l);
        if (j is Map) {
          for (final k in ['webUrl', 'shareUrl', 'url', 'link', 'href', 'pageUrl']) {
            final v = j[k];
            if (v is String && v.isNotEmpty) return webUrl(source, v);
          }
          final id = j['id'] ?? j['videoId'] ?? j['slug'];
          if (id != null) {
            final host = Uri.tryParse(base)?.host ?? '';
            final tpl = _jsonHosts[host];
            if (tpl != null) return tpl.replaceAll('{id}', '$id');
            return '$base/${Uri.encodeComponent('$id')}';
          }
        }
      } catch (_) {}
      return base;
    }
    // YouTube extension short links: v:ID, p:ID, c:ID
    final yt = RegExp(r'^([vpc]):([\w\-@.]+)$').firstMatch(l);
    if (yt != null) {
      final id = yt.group(2)!;
      return switch (yt.group(1)) {
        'v' => 'https://www.youtube.com/watch?v=$id',
        'p' => 'https://www.youtube.com/playlist?list=$id',
        _ => id.startsWith('@') ? 'https://www.youtube.com/$id' : 'https://www.youtube.com/channel/$id',
      };
    }
    // "yhweb:" (site web player), "yh_..." internal prefixes
    l = l.replaceFirst(RegExp(r'^yhweb:'), '');
    if (RegExp(r'^https?://', caseSensitive: false).hasMatch(l)) {
      final u = Uri.tryParse(l);
      final to = u == null ? null : YomiUrlOverride.rewrite(u);
      return (to ?? u)?.toString() ?? l;
    }
    if (l.startsWith('//')) return 'https:$l';
    if (base.isEmpty) return l;
    return '$base${l.startsWith('/') ? '' : '/'}$l';
  }

  static Source? sourceOf(String? lang, String? name, int? id) {
    try {
      return getSource(lang ?? '', name ?? '', id, installedOnly: false);
    } catch (_) {
      return null;
    }
  }

  static Future<void> share(BuildContext context, String url, {String? title}) async {
    if (url.isEmpty) return;
    final box = context.findRenderObject() as RenderBox?;
    await shareOrCopy(
      ShareParams(
        text: (title ?? '').isEmpty ? url : '$title\n$url',
        subject: title,
        sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }
}

/// Small share icon for list rows.
class YomiShareButton extends StatelessWidget {
  final String Function() url;
  final String? title;
  final double size;
  const YomiShareButton({super.key, required this.url, this.title, this.size = 20});

  @override
  Widget build(BuildContext context) => Builder(
        builder: (ctx) => IconButton(
          visualDensity: VisualDensity.compact,
          iconSize: size,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
          icon: const Icon(Icons.share_outlined),
          tooltip: tr('Chia sẻ'),
          onPressed: () => YomiShareLink.share(ctx, url(), title: title),
        ),
      );
}
