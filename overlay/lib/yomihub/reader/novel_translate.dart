import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:mangayomi/services/http/m_client.dart';
import 'package:mangayomi/utils/log/logger.dart';
import 'package:mangayomi/yomihub/prefs/yomi_prefs.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// YomiHub 0.1.8: chapter translation for Novel (from IReader's translation
/// engine).
///
/// The chapter HTML is split into paragraphs, sent to Google Translate's
/// public web endpoint in batches (≤ 4 500 characters, as IReader does),
/// and put back paragraph by paragraph, keeping images and markup. In
/// bilingual mode the original paragraph stays and the translation follows
/// it in italics. Translations are cached on disk per chapter, so reading a
/// chapter again (or offline) costs nothing.
class YomiNovelTranslate {
  YomiNovelTranslate._();

  static bool get enabled => YomiPrefs.get<bool>('novelTranslate', false);
  static String get target => YomiPrefs.get<String>('novelTranslateTo', 'vi');
  static bool get bilingual => YomiPrefs.get<bool>('novelBilingual', false);

  static const languages = {
    'vi': 'Tiếng Việt', 'en': 'English', 'zh-CN': '中文 (简体)', 'zh-TW': '中文 (繁體)', 'ja': '日本語',
    'ko': '한국어', 'fr': 'Français', 'de': 'Deutsch', 'es': 'Español', 'pt': 'Português', 'ru': 'Русский',
    'id': 'Bahasa Indonesia', 'th': 'ไทย', 'ar': 'العربية', 'hi': 'हिन्दी', 'it': 'Italiano', 'tr': 'Türkçe',
  };

  static Future<File> _cacheFile(String html) async {
    final key = sha1.convert(utf8.encode('$target|$bilingual|$html')).toString();
    final dir = Directory(p.join((await getApplicationSupportDirectory()).path, 'novel_translate'));
    await dir.create(recursive: true);
    return File(p.join(dir.path, '$key.html'));
  }

  /// Translated chapter, or [html] unchanged when translation is off/fails.
  static Future<String> apply(String html) async {
    if (!enabled || html.trim().isEmpty) return html;
    try {
      final cache = await _cacheFile(html);
      if (await cache.exists()) return await cache.readAsString();
      final out = await _translateHtml(html);
      await cache.writeAsString(out);
      return out;
    } catch (e) {
      AppLogger.log('Novel translate failed: $e', logLevel: LogLevel.error);
      return html;
    }
  }

  static Future<String> _translateHtml(String html) async {
    final doc = html_parser.parseFragment(html);
    // block elements whose text is translated as one unit
    final blocks = <dom.Element>[];
    void walk(dom.Node n) {
      for (final c in n.nodes.toList()) {
        if (c is dom.Element) {
          final tag = c.localName ?? '';
          if (const {'p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'li', 'blockquote', 'figcaption', 'td'}.contains(tag)) {
            if (c.text.trim().isNotEmpty) blocks.add(c);
          } else if (tag == 'div' && c.children.every((e) => const {'br', 'span', 'b', 'i', 'em', 'strong', 'a'}.contains(e.localName))) {
            if (c.text.trim().isNotEmpty) blocks.add(c);
          } else {
            walk(c);
          }
        }
      }
    }

    walk(doc);
    if (blocks.isEmpty) {
      // plain text chapter: wrap lines into paragraphs
      final text = doc.text ?? '';
      final lines = text.split(RegExp(r'\n+')).where((l) => l.trim().isNotEmpty).toList();
      final tr = await translateAll(lines);
      final b = StringBuffer();
      for (var i = 0; i < lines.length; i++) {
        if (bilingual) b.write('<p>${_esc(lines[i])}</p>');
        b.write(bilingual ? '<p><i>${_esc(tr[i])}</i></p>' : '<p>${_esc(tr[i])}</p>');
      }
      return b.toString();
    }
    final texts = blocks.map((e) => e.text.trim()).toList();
    final tr = await translateAll(texts);
    for (var i = 0; i < blocks.length; i++) {
      final e = blocks[i];
      if (bilingual) {
        final t = dom.Element.tag(e.localName == 'li' ? 'div' : 'p')
          ..attributes['class'] = 'yh-translation'
          ..innerHtml = '<i>${_esc(tr[i])}</i>';
        e.append(dom.Element.tag('br'));
        e.append(t);
      } else {
        // keep images inside the block
        final imgs = e.querySelectorAll('img').map((x) => x.outerHtml).join();
        e.innerHtml = imgs + _esc(tr[i]);
      }
    }
    return doc.outerHtml;
  }

  static String _esc(String s) =>
      s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');

  /// Translates every string, batching requests.
  static Future<List<String>> translateAll(List<String> texts) =>
      translateAllTo(texts, target);

  /// YomiHub 0.1.9: same, into [to] (used by "Dịch ảnh").
  static Future<List<String>> translateAllTo(List<String> texts, String to) async {
    final out = List<String>.from(texts);
    const sep = '\n⁣\n'; // invisible separator that survives translation
    var i = 0;
    while (i < texts.length) {
      final batch = <int>[];
      var len = 0;
      while (i < texts.length && (batch.isEmpty || len + texts[i].length < 4500)) {
        batch.add(i);
        len += texts[i].length + sep.length;
        i++;
      }
      final joined = batch.map((k) => texts[k]).join(sep);
      final translated = await _google(joined, to);
      final parts = translated.split(RegExp(r'\s*⁣\s*'));
      if (parts.length == batch.length) {
        for (var k = 0; k < batch.length; k++) {
          out[batch[k]] = parts[k].trim();
        }
      } else {
        // the separator was lost: translate one by one
        for (final k in batch) {
          out[k] = (await _google(texts[k], to)).trim();
        }
      }
    }
    return out;
  }

  static Future<String> translateText(String text, {String? targetLang}) => _google(text, targetLang);

  static Future<String> _google(String text, [String? to]) async {
    final uri = Uri.https('translate.googleapis.com', '/translate_a/single', {
      'client': 'gtx',
      'sl': 'auto',
      'tl': to ?? target,
      'dt': 't',
      'dj': '1',
    });
    final client = MClient.init(reqcopyWith: {'useDartHttpClient': true});
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final r = await client
            .post(uri, headers: {'Content-Type': 'application/x-www-form-urlencoded;charset=utf-8'}, body: {'q': text})
            .timeout(const Duration(seconds: 30));
        if (r.statusCode == 200) {
          final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map;
          return ((j['sentences'] as List?) ?? const [])
              .map((s) => (s as Map)['trans'] ?? '')
              .join();
        }
        if (r.statusCode == 429) await Future.delayed(Duration(seconds: 2 << attempt));
      } catch (_) {
        await Future.delayed(Duration(milliseconds: 600 << attempt));
      }
    }
    throw Exception(tr('Google Translate không phản hồi'));
  }
}
