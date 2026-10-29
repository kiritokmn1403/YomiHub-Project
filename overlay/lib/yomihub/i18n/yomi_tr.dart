import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// YomiHub 0.1.8: translations of YomiHub's own texts.
///
/// The YomiHub screens are written in Vietnamese; [tr] looks the Vietnamese
/// text up in `assets/yomihub_i18n/<lang>.json` for the app language chosen
/// in Settings › Appearance › Language (falling back to English, then to the
/// Vietnamese text itself). Mangayomi's own texts keep using the ARB files.
class YomiTr {
  YomiTr._();
  static String lang = 'vi';
  static Map<String, String> _table = const {};
  static Map<String, String> _en = const {};
  static final version = ValueNotifier<int>(0);
  static String? _loading;

  static const languages = [
    'ar', 'as', 'de', 'en', 'es', 'es_419', 'fr', 'hi', 'id', 'it', 'ja',
    'ko', 'pt', 'pt_BR', 'ru', 'th', 'tr', 'zh',
  ];

  static Future<Map<String, String>> _read(String code) async {
    try {
      final s = await rootBundle.loadString('assets/yomihub_i18n/$code.json');
      return Map<String, String>.from(jsonDecode(s) as Map);
    } catch (_) {
      return const {};
    }
  }

  /// Picks the table for a locale ("pt_BR", "es_419", "zh"…).
  static Future<void> use(String languageCode, [String? country]) async {
    var code = languageCode;
    if (country != null && languages.contains('${languageCode}_$country')) {
      code = '${languageCode}_$country';
    }
    if (code == lang && (_table.isNotEmpty || code == 'vi')) return;
    if (_loading == code) return;
    _loading = code;
    if (_en.isEmpty) _en = await _read('en');
    _table = code == 'vi' ? const {} : await _read(code);
    lang = code;
    _loading = null;
    version.value++;
  }

  static String get(String vi) {
    final s = lang == 'vi' ? vi : (_table[vi] ?? _en[vi] ?? vi);
    return sections(s);
  }

  /// YomiHub 0.2.0: the three section names (Comic, Film & Movie, Novel)
  /// in every app language. English keeps the names chosen for YomiHub.
  static const terms = <String, List<String>>{
    'ar': ['قصص مصورة', 'أفلام ومسلسلات', 'روايات'],
    'as': ['কমিক', 'চলচ্চিত্ৰ আৰু ছবি', 'উপন্যাস'],
    'de': ['Comics', 'Filme & Serien', 'Romane'],
    'es': ['Cómics', 'Cine y películas', 'Novelas'],
    'es_419': ['Cómics', 'Cine y películas', 'Novelas'],
    'fr': ['Bandes dessinées', 'Films & cinéma', 'Romans'],
    'hi': ['कॉमिक्स', 'फ़िल्में और सिनेमा', 'उपन्यास'],
    'id': ['Komik', 'Film & Sinema', 'Novel'],
    'it': ['Fumetti', 'Film e cinema', 'Romanzi'],
    'ja': ['コミック', '映画・動画', '小説'],
    'ko': ['만화', '영화·영상', '소설'],
    'pt': ['Banda desenhada', 'Filmes e cinema', 'Romances'],
    'pt_BR': ['Quadrinhos', 'Filmes e cinema', 'Romances'],
    'ru': ['Комиксы', 'Фильмы и кино', 'Романы'],
    'th': ['การ์ตูน', 'ภาพยนตร์และหนัง', 'นิยาย'],
    'tr': ['Çizgi roman', 'Film & Sinema', 'Romanlar'],
    'vi': ['Truyện tranh', 'Phim & Điện ảnh', 'Tiểu thuyết'],
    'zh': ['漫画', '影视', '小说'],
  };
  static final _novel = RegExp(r'(?<!Light )\bNovel\b(?!s)');
  static final _comic = RegExp(r'\bComic\b');

  /// Replaces the English section names inside [s] for the current language.
  static String sections(String s) {
    final t = terms[lang];
    if (t == null || s.isEmpty) return s;
    if (!s.contains('Film & Movie') && !s.contains('Comic') && !s.contains('Novel')) return s;
    return s
        .replaceAll('Film & Movie', t[1])
        .replaceAll(_novel, t[2])
        .replaceAll(_comic, t[0]);
  }

  /// YomiHub 0.2.1: "Comic Setting Extension" / "Film & Movie Setting
  /// Extension" / "Novel Setting Extension" (Browse tabs) written as a
  /// proper phrase in every app language.
  static const sectionSettings = <String, List<String>>{
    'en': ['Comic Extension Settings', 'Film & Movie Extension Settings', 'Novel Extension Settings'],
    'vi': ['Cài đặt tiện ích Truyện tranh', 'Cài đặt tiện ích Phim & Điện ảnh', 'Cài đặt tiện ích Tiểu thuyết'],
    'ar': ['إعدادات إضافات القصص المصورة', 'إعدادات إضافات الأفلام والمسلسلات', 'إعدادات إضافات الروايات'],
    'as': ['কমিক এক্সটেনচনৰ ছেটিংছ', 'চলচ্চিত্ৰ আৰু ছবি এক্সটেনচনৰ ছেটিংছ', 'উপন্যাস এক্সটেনচনৰ ছেটিংছ'],
    'de': ['Einstellungen der Comic-Erweiterungen', 'Einstellungen der Film- & Serien-Erweiterungen', 'Einstellungen der Roman-Erweiterungen'],
    'es': ['Ajustes de extensiones de cómics', 'Ajustes de extensiones de cine y películas', 'Ajustes de extensiones de novelas'],
    'es_419': ['Configuración de extensiones de cómics', 'Configuración de extensiones de cine y películas', 'Configuración de extensiones de novelas'],
    'fr': ['Paramètres des extensions BD', 'Paramètres des extensions films & cinéma', 'Paramètres des extensions romans'],
    'hi': ['कॉमिक्स एक्सटेंशन सेटिंग्स', 'फ़िल्में और सिनेमा एक्सटेंशन सेटिंग्स', 'उपन्यास एक्सटेंशन सेटिंग्स'],
    'id': ['Pengaturan Ekstensi Komik', 'Pengaturan Ekstensi Film & Sinema', 'Pengaturan Ekstensi Novel'],
    'it': ['Impostazioni estensioni fumetti', 'Impostazioni estensioni film e cinema', 'Impostazioni estensioni romanzi'],
    'ja': ['コミック拡張機能の設定', '映画・動画拡張機能の設定', '小説拡張機能の設定'],
    'ko': ['만화 확장 프로그램 설정', '영화·영상 확장 프로그램 설정', '소설 확장 프로그램 설정'],
    'pt': ['Definições das extensões de banda desenhada', 'Definições das extensões de filmes e cinema', 'Definições das extensões de romances'],
    'pt_BR': ['Configurações das extensões de quadrinhos', 'Configurações das extensões de filmes e cinema', 'Configurações das extensões de romances'],
    'ru': ['Настройки расширений комиксов', 'Настройки расширений фильмов и кино', 'Настройки расширений романов'],
    'th': ['การตั้งค่าส่วนขยายการ์ตูน', 'การตั้งค่าส่วนขยายภาพยนตร์และหนัง', 'การตั้งค่าส่วนขยายนิยาย'],
    'tr': ['Çizgi roman uzantı ayarları', 'Film & Sinema uzantı ayarları', 'Roman uzantı ayarları'],
    'zh': ['漫画扩展设置', '影视扩展设置', '小说扩展设置'],
  };

  /// 0 = Comic, 1 = Film & Movie, 2 = Novel.
  static String sectionSetting(int i) =>
      (sectionSettings[lang] ?? sectionSettings['en']!)[i];

  /// One section name: 0 = Comic, 1 = Film & Movie, 2 = Novel.
  static String term(int i) =>
      terms[lang]?[i] ?? const ['Comic', 'Film & Movie', 'Novel'][i];
}

/// Translated YomiHub text. [args] fill `{name}` placeholders.
String tr(String vi, [Map<String, Object?>? args]) {
  var s = YomiTr.get(vi);
  if (args != null) {
    args.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
  }
  return s;
}

/// YomiHub 0.2.1: extension notes written by YomiHub (built-in extensions,
/// Kotatsu "may be broken" marker) shown in the app language.
String trNotes(String notes) {
  final t = tr(notes);
  if (t != notes) return t;
  return notes.replaceAll(' • có thể đang lỗi', ' • ${tr('có thể đang lỗi')}');
}
