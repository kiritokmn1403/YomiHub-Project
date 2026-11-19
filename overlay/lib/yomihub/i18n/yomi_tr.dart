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
    // 0.6.2: ngôn ngữ của Aniyomi / Nekoyomi / Kotatsu (Antigravity /swarm 2);
    // bỏ ceb, eo, jv, nn vì Flutter (Material/Cupertino) không hỗ trợ.
    'am', 'be', 'bg', 'bn', 'ca', 'cs', 'da', 'el', 'et', 'eu', 'fa', 'fi',
    'fil', 'gl', 'gu', 'he', 'hr', 'hu', 'ka', 'kk', 'km', 'kn', 'lo', 'lt',
    'lv', 'ml', 'mr', 'ms', 'my', 'nb', 'ne', 'nl', 'or', 'pa', 'pl', 'ro',
    'si', 'sk', 'sl', 'sq', 'sr', 'sv', 'ta', 'te', 'uk', 'ur', 'uz', 'zh_Hant',
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
    // 0.6.2: tiếng Trung phồn thể (Locale zh_Hant / zh_TW / zh_HK)
    if (languageCode == 'zh' && (country == 'Hant' || country == 'TW' || country == 'HK')) {
      code = 'zh_Hant';
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
    // 0.6.2: 48 ngôn ngữ mới (Antigravity /swarm 3 @term_translator, Claude duyệt).
    'am': ['ኮሚክስ', 'ፊልሞች እና ሲኒማ', 'ልብ ወለዶች'],
    'be': ['Коміксы', 'Фільмы і кіно', 'Раманы'],
    'bg': ['Комикси', 'Филми и кино', 'Романи'],
    'bn': ['কমিক্স', 'চলচ্চিত্র ও সিনেমা', 'উপন্যাস'],
    'ca': ['Còmics', 'Cinema i pel·lícules', 'Novel·les'],
    'cs': ['Komiksy', 'Filmy a kino', 'Romány'],
    'da': ['Tegneserier', 'Film og serier', 'Romaner'],
    'el': ['Κόμικς', 'Ταινίες και κινηματογράφος', 'Μυθιστορήματα'],
    'et': ['Koomiksid', 'Filmid ja kino', 'Romaanid'],
    'eu': ['Komikiak', 'Filmak eta zinema', 'Eleberriak'],
    'fa': ['کمیک‌ها', 'فیلم و سینما', 'رمان‌ها'],
    'fi': ['Sarjakuvat', 'Elokuvat ja sarjat', 'Romaanit'],
    'fil': ['Komiks', 'Pelikula at Sine', 'Nobela'],
    'gl': ['Cómics', 'Cine e películas', 'Novelas'],
    'gu': ['કોમિક્સ', 'ફિલ્મ અને સિનેમા', 'નવલકથા'],
    'he': ['קומיקס', 'סרטים וקולנוע', 'רומנים'],
    'hr': ['Stripovi', 'Filmovi i kino', 'Romani'],
    'hu': ['Képregények', 'Filmek és mozi', 'Regények'],
    'ka': ['კომიქსები', 'ფილმები და კინო', 'რომანები'],
    'kk': ['Комикстер', 'Фильмдер мен кино', 'Романдар'],
    'km': ['រឿងតុក្កតា', 'ភាពយន្ត និងកុន', 'ប្រលោមលោក'],
    'kn': ['ಕಾಮಿಕ್ಸ್', 'ಚಲನಚಿತ್ರ ಮತ್ತು ಸಿನಿಮಾ', 'ಕಾದಂಬರಿಗಳು'],
    'lo': ['ກາຕູນ', 'ຮູບເງົາ ແລະ ໜັງ', 'ນະວະນິຍາຍ'],
    'lt': ['Komiksai', 'Filmai ir kinas', 'Romanai'],
    'lv': ['Komiksi', 'Filmas un kino', 'Romāni'],
    'ml': ['കോമിക്സ്', 'സിനിമയും ചലച്ചിത്രവും', 'നോവലുകൾ'],
    'mr': ['कॉमिक्स', 'चित्रपट आणि सिनेमा', 'कादंबरी'],
    'ms': ['Komik', 'Filem & Sinema', 'Novel'],
    'my': ['ရုပ်ပြ', 'ရုပ်ရှင်နှင့် ဗီဒီယို', 'ဝတ္ထု'],
    'nb': ['Tegneserier', 'Filmer og serier', 'Romaner'],
    'ne': ['कमिक्स', 'चलचित्र र सिनेमा', 'उपन्यास'],
    'nl': ['Strips', 'Films & series', 'Romans'],
    'or': ['କମିକ୍ସ', 'ଚଳଚ୍ଚିତ୍ର ଓ ସିନେମା', 'ଉପନ୍ୟାସ'],
    'pa': ['ਕਾਮਿਕਸ', 'ਫ਼ਿਲਮਾਂ ਅਤੇ ਸਿਨੇਮਾ', 'ਨਾਵਲ'],
    'pl': ['Komiksy', 'Filmy i kino', 'Powieści'],
    'ro': ['Benzi desenate', 'Filme și cinema', 'Romane'],
    'si': ['කොමික්ස්', 'චිත්‍රපට සහ සිනමාව', 'නවකතා'],
    'sk': ['Komiksy', 'Filmy a kino', 'Romány'],
    'sl': ['Stripi', 'Filmi in kino', 'Romani'],
    'sq': ['Komike', 'Filma dhe kinema', 'Romane'],
    'sr': ['Стрипови', 'Филмови и биоскоп', 'Романи'],
    'sv': ['Serier', 'Film & bio', 'Romaner'],
    'ta': ['காமிக்ஸ்', 'திரைப்படங்கள் & சினிமா', 'நாவல்கள்'],
    'te': ['కామిక్స్', 'సినిమాలు & చలనచిత్రాలు', 'నవలలు'],
    'uk': ['Комікси', 'Фільми та кіно', 'Романи'],
    'ur': ['کامکس', 'فلمیں اور سنیما', 'ناول'],
    'uz': ['Komikslar', 'Filmlar va kino', 'Romanlar'],
    'zh_Hant': ['漫畫', '影視', '小說'],
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
    // 0.6.2: 48 ngôn ngữ mới (Antigravity /swarm 3 @term_translator, Claude duyệt).
    'am': ['የኮሚክስ ቅጥያ ቅንብሮች', 'የፊልሞች እና ሲኒማ ቅጥያ ቅንብሮች', 'የልብ ወለድ ቅጥያ ቅንብሮች'],
    'be': ['Налады пашырэнняў коміксаў', 'Налады пашырэнняў фільмаў і кіно', 'Налады пашырэнняў раманаў'],
    'bg': ['Настройки на разширенията за комикси', 'Настройки на разширенията за филми и кино', 'Настройки на разширенията за романи'],
    'bn': ['কমিক্স এক্সটেনশন সেটিংস', 'চলচ্চিত্র ও সিনেমা এক্সটেনশন সেটিংস', 'উপন্যাস এক্সটেনশন সেটিংস'],
    'ca': ['Configuració de les extensions de còmics', 'Configuració de les extensions de cinema i pel·lícules', 'Configuració de les extensions de novel·les'],
    'cs': ['Nastavení rozšíření komiksů', 'Nastavení rozšíření filmů a kina', 'Nastavení rozšíření románů'],
    'da': ['Indstillinger for tegneserieudvidelser', 'Indstillinger for film- og serieudvidelser', 'Indstillinger for romanudvidelser'],
    'el': ['Ρυθμίσεις επεκτάσεων κόμικς', 'Ρυθμίσεις επεκτάσεων ταινιών και κινηματογράφου', 'Ρυθμίσεις επεκτάσεων μυθιστορημάτων'],
    'et': ['Koomiksilaienduste seaded', 'Filmi- ja kinolaienduste seaded', 'Romaanilaienduste seaded'],
    'eu': ['Komikien luzapenen ezarpenak', 'Filmen eta zinemaren luzapenen ezarpenak', 'Eleberrien luzapenen ezarpenak'],
    'fa': ['تنظیمات افزونه‌های کمیک', 'تنظیمات افزونه‌های فیلم و سینما', 'تنظیمات افزونه‌های رمان'],
    'fi': ['Sarjakuvalaajennusten asetukset', 'Elokuva- ja sarjalaajennusten asetukset', 'Romaanilaajennusten asetukset'],
    'fil': ['Mga Setting ng Extension ng Komiks', 'Mga Setting ng Extension ng Pelikula at Sine', 'Mga Setting ng Extension ng Nobela'],
    'gl': ['Configuración das extensións de cómics', 'Configuración das extensións de cine e películas', 'Configuración das extensións de novelas'],
    'gu': ['કોમિક્સ એક્સ્ટેન્શન સેટિંગ્સ', 'ફિલ્મ અને સિનેમા એક્સ્ટેન્શન સેટિંગ્સ', 'નવલકથા એક્સ્ટેન્શન સેટિંગ્સ'],
    'he': ['הגדרות הרחבות קומיקס', 'הגדרות הרחבות סרטים וקולנוע', 'הגדרות הרחבות רומנים'],
    'hr': ['Postavke proširenja za stripove', 'Postavke proširenja za filmove i kino', 'Postavke proširenja za romane'],
    'hu': ['Képregény-kiterjesztések beállításai', 'Film- és mozikiterjesztések beállításai', 'Regénykiterjesztések beállításai'],
    'ka': ['კომიქსების გაფართოებების პარამეტრები', 'ფილმებისა და კინოს გაფართოებების პარამეტრები', 'რომანების გაფართოებების პარამეტრები'],
    'kk': ['Комикстер кеңейтімдерінің параметрлері', 'Фильмдер мен кино кеңейтімдерінің параметрлері', 'Романдар кеңейтімдерінің параметрлері'],
    'km': ['ការកំណត់ផ្នែកបន្ថែមរឿងតុក្កតា', 'ការកំណត់ផ្នែកបន្ថែមភាពយន្ត និងកុន', 'ការកំណត់ផ្នែកបន្ថែមប្រលោមលោក'],
    'kn': ['ಕಾಮಿಕ್ಸ್ ವಿಸ್ತರಣೆ ಸೆಟ್ಟಿಂಗ್‌ಗಳು', 'ಚಲನಚಿತ್ರ ಮತ್ತು ಸಿನಿಮಾ ವಿಸ್ತರಣೆ ಸೆಟ್ಟಿಂಗ್‌ಗಳು', 'ಕಾದಂಬರಿ ವಿಸ್ತರಣೆ ಸೆಟ್ಟಿಂಗ್‌ಗಳು'],
    'lo': ['ການຕັ້ງຄ່າສ່ວນຂະຫຍາຍກາຕູນ', 'ການຕັ້ງຄ່າສ່ວນຂະຫຍາຍຮູບເງົາ ແລະ ໜັງ', 'ການຕັ້ງຄ່າສ່ວນຂະຫຍາຍນະວະນິຍາຍ'],
    'lt': ['Komiksų plėtinių nustatymai', 'Filmų ir kino plėtinių nustatymai', 'Romanų plėtinių nustatymai'],
    'lv': ['Komiksu paplašinājumu iestatījumi', 'Filmu un kino paplašinājumu iestatījumi', 'Romānu paplašinājumu iestatījumi'],
    'ml': ['കോമിക്സ് വിപുലീകരണ ക്രമീകരണങ്ങൾ', 'സിനിമയും ചലച്ചിത്രവും വിപുലീകരണ ക്രമീകരണങ്ങൾ', 'നോവൽ വിപുലീകരണ ക്രമീകരണങ്ങൾ'],
    'mr': ['कॉमिक्स विस्तार सेटिंग्ज', 'चित्रपट आणि सिनेमा विस्तार सेटिंग्ज', 'कादंबरी विस्तार सेटिंग्ज'],
    'ms': ['Tetapan Sambungan Komik', 'Tetapan Sambungan Filem & Sinema', 'Tetapan Sambungan Novel'],
    'my': ['ရုပ်ပြ တိုးချဲ့မှု ဆက်တင်များ', 'ရုပ်ရှင်နှင့် ဗီဒီယို တိုးချဲ့မှု ဆက်တင်များ', 'ဝတ္ထု တိုးချဲ့မှု ဆက်တင်များ'],
    'nb': ['Innstillinger for tegneserieutvidelser', 'Innstillinger for film- og serieutvidelser', 'Innstillinger for romanutvidelser'],
    'ne': ['कमिक्स विस्तार सेटिङहरू', 'चलचित्र र सिनेमा विस्तार सेटिङहरू', 'उपन्यास विस्तार सेटिङहरू'],
    'nl': ['Instellingen voor stripextensies', 'Instellingen voor film- en serie-extensies', 'Instellingen voor romanextensies'],
    'or': ['କମିକ୍ସ ଏକ୍ସଟେନସନ୍ ସେଟିଂସମୂହ', 'ଚଳଚ୍ଚିତ୍ର ଓ ସିନେମା ଏକ୍ସଟେନସନ୍ ସେଟିଂସମୂହ', 'ଉପନ୍ୟାସ ଏକ୍ସଟେନସନ୍ ସେଟିଂସମୂହ'],
    'pa': ['ਕਾਮਿਕਸ ਐਕਸਟੈਂਸ਼ਨ ਸੈਟਿੰਗਾਂ', 'ਫ਼ਿਲਮਾਂ ਅਤੇ ਸਿਨੇਮਾ ਐਕਸਟੈਂਸ਼ਨ ਸੈਟਿੰਗਾਂ', 'ਨਾਵਲ ਐਕਸਟੈਂਸ਼ਨ ਸੈਟਿੰਗਾਂ'],
    'pl': ['Ustawienia rozszerzeń komiksów', 'Ustawienia rozszerzeń filmów i kina', 'Ustawienia rozszerzeń powieści'],
    'ro': ['Setări extensii benzi desenate', 'Setări extensii filme și cinema', 'Setări extensii romane'],
    'si': ['කොමික්ස් දිගු සැකසුම්', 'චිත්‍රපට සහ සිනමාව දිගු සැකසුම්', 'නවකතා දිගු සැකසුම්'],
    'sk': ['Nastavenia rozšírení komiksov', 'Nastavenia rozšírení filmov a kina', 'Nastavenia rozšírení románov'],
    'sl': ['Nastavitve razširitev za stripe', 'Nastavitve razširitev za filme in kino', 'Nastavitve razširitev za romane'],
    'sq': ['Cilësimet e shtesave të komikeve', 'Cilësimet e shtesave të filmave dhe kinemasë', 'Cilësimet e shtesave të romaneve'],
    'sr': ['Подешавања екстензија за стрипове', 'Подешавања екстензија за филмове и биоскоп', 'Подешавања екстензија за романе'],
    'sv': ['Inställningar för serietillägg', 'Inställningar för film- och biotillägg', 'Inställningar för romantillägg'],
    'ta': ['காமிக்ஸ் நீட்டிப்பு அமைப்புகள்', 'திரைப்படங்கள் & சினிமா நீட்டிப்பு அமைப்புகள்', 'நாவல்கள் நீட்டிப்பு அமைப்புகள்'],
    'te': ['కామిక్స్ పొడిగింపు సెట్టింగ్‌లు', 'సినిమాలు & చలనచిత్రాల పొడిగింపు సెట్టింగ్‌లు', 'నవలల పొడిగింపు సెట్టింగ్‌లు'],
    'uk': ['Налаштування розширень коміксів', 'Налаштування розширень фільмів та кіно', 'Налаштування розширень романів'],
    'ur': ['کامکس ایکسٹینشن کی ترتیبات', 'فلمیں اور سنیما ایکسٹینشن کی ترتیبات', 'ناول ایکسٹینشن کی ترتیبات'],
    'uz': ['Komikslar kengaytmalari sozlamalari', 'Filmlar va kino kengaytmalari sozlamalari', 'Romanlar kengaytmalari sozlamalari'],
    'zh_Hant': ['漫畫擴充設定', '影視擴充設定', '小說擴充設定'],
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
