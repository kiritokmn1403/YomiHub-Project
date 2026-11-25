import 'package:mangayomi/eval/model/filter.dart';

/// YomiHub 0.6.2: 9 ô thẻ cố định của bảng bộ lọc mới ("New Filter") theo đúng
/// thứ tự hiển thị, kèm [other] ("Khác") ở cuối cho các bộ lọc không khớp.
enum FilterV2Section {
  sort,
  status,
  category,
  contentRating,
  country, // 0.6.5: "Quốc Gia Phát Hành" (sheet New Filter)
  releaseYear,
  searchBy,
  rating,
  translation,
  genre,
  other,
}

/// 10 nhóm chính của sheet "New Filter" theo đúng thứ tự thiết kế
/// (0.6.5: thêm "Quốc Gia Phát Hành").
const List<FilterV2Section> kFilterV2PrimarySections = [
  FilterV2Section.sort,
  FilterV2Section.status,
  FilterV2Section.category,
  FilterV2Section.contentRating,
  FilterV2Section.country,
  FilterV2Section.releaseYear,
  FilterV2Section.searchBy,
  FilterV2Section.rating,
  FilterV2Section.translation,
  FilterV2Section.genre,
];

extension FilterV2SectionMeta on FilterV2Section {
  /// Khóa tiếng Việt chuẩn truyền vào `tr(...)`.
  String get titleKey => switch (this) {
    FilterV2Section.sort => 'Sắp Xếp',
    FilterV2Section.status => 'Tình Trạng',
    FilterV2Section.category => 'Danh Mục',
    FilterV2Section.contentRating => 'Phân Loại Nội Dung',
    FilterV2Section.country => 'Quốc Gia Phát Hành',
    FilterV2Section.releaseYear => 'Năm Phát Hành',
    FilterV2Section.searchBy => 'Tìm Theo',
    FilterV2Section.rating => 'Đánh Giá',
    FilterV2Section.translation => 'Bản Dịch',
    FilterV2Section.genre => 'Thể Loại',
    FilterV2Section.other => 'Khác',
  };
}

/// Ánh xạ giá trị trường `filter.type` (từ Kotatsu, vBook, Aidoku, IReader,
/// Mangayomi/Mihon) sang nhóm bộ lọc tương ứng.
const Map<String, FilterV2Section> kFilterV2TypeHints = {
  'sort': FilterV2Section.sort,
  'order': FilterV2Section.sort,
  'orderby': FilterV2Section.sort,
  'sortby': FilterV2Section.sort,
  'ir_sort': FilterV2Section.sort,
  'status': FilterV2Section.status,
  'state': FilterV2Section.status,
  'states': FilterV2Section.status,
  'category': FilterV2Section.category,
  'categories': FilterV2Section.category,
  'type': FilterV2Section.category,
  'types': FilterV2Section.category,
  'format': FilterV2Section.category,
  'formats': FilterV2Section.category,
  'demographic': FilterV2Section.category,
  'demographics': FilterV2Section.category,
  'country': FilterV2Section.country,
  'countries': FilterV2Section.country,
  'origin': FilterV2Section.country,
  'nation': FilterV2Section.country,
  'region': FilterV2Section.country,
  'vb_tab': FilterV2Section.category,
  'ratings': FilterV2Section.contentRating,
  'contentrating': FilterV2Section.contentRating,
  'content_rating': FilterV2Section.contentRating,
  'agerating': FilterV2Section.contentRating,
  'age_rating': FilterV2Section.contentRating,
  'nsfw': FilterV2Section.contentRating,
  'adult': FilterV2Section.contentRating,
  'mature': FilterV2Section.contentRating,
  'year': FilterV2Section.releaseYear,
  'years': FilterV2Section.releaseYear,
  'yearfrom': FilterV2Section.releaseYear,
  'yearto': FilterV2Section.releaseYear,
  'year_from': FilterV2Section.releaseYear,
  'year_to': FilterV2Section.releaseYear,
  'releaseyear': FilterV2Section.releaseYear,
  'release_year': FilterV2Section.releaseYear,
  'searchby': FilterV2Section.searchBy,
  'search_by': FilterV2Section.searchBy,
  'searchtype': FilterV2Section.searchBy,
  'search_type': FilterV2Section.searchBy,
  'author': FilterV2Section.searchBy,
  'artist': FilterV2Section.searchBy,
  'creator': FilterV2Section.searchBy,
  'rating': FilterV2Section.rating,
  'score': FilterV2Section.rating,
  'minscore': FilterV2Section.rating,
  'min_score': FilterV2Section.rating,
  'minrating': FilterV2Section.rating,
  'min_rating': FilterV2Section.rating,
  'locale': FilterV2Section.translation,
  'originallocale': FilterV2Section.translation,
  'original_locale': FilterV2Section.translation,
  'lang': FilterV2Section.translation,
  'language': FilterV2Section.translation,
  'languages': FilterV2Section.translation,
  'translation': FilterV2Section.translation,
  'translator': FilterV2Section.translation,
  'scanlator': FilterV2Section.translation,
  'genre': FilterV2Section.genre,
  'genres': FilterV2Section.genre,
  'tag': FilterV2Section.genre,
  'tags': FilterV2Section.genre,
  'theme': FilterV2Section.genre,
  'themes': FilterV2Section.genre,
  'vb_genre': FilterV2Section.genre,
};

/// Bảng từ khóa hằng đa ngôn ngữ dùng để phân loại bộ lọc theo tên từ mọi
/// nguồn (Mangayomi, Mihon/Aniyomi, Kotatsu, vBook, LNReader, IReader, Aidoku).
///
/// Thứ tự kiểm tra ưu tiên ([_classifyOrder]) bảo đảm không nhầm các cụm ghép
/// như "Sort by Rating" (→ [FilterV2Section.sort]), "Content Rating" (→
/// [FilterV2Section.contentRating]) hay "Search by Genre" (→ [FilterV2Section.searchBy]).
const Map<FilterV2Section, List<String>> kFilterV2Keywords = {
  // 0.6.5: "Quốc Gia Phát Hành" (sheet New Filter)
  FilterV2Section.country: [
    'quốc gia phát hành', 'quoc gia phat hanh', 'quốc gia', 'quoc gia', 'xuất xứ', 'xuat xu',
    'nước', 'nuoc', 'khu vực', 'khu vuc',
    'country', 'country of origin', 'countries', 'origin', 'nation', 'region',
    '国家', '國家', '地区', '地區', '国・地域',
    '국가', 'страна', 'страны', 'país', 'pais', 'países', 'origem', 'origen', 'pays', 'paese', 'negara', 'ülke', 'ประเทศ',
  ],
  FilterV2Section.sort: [
    // Tiếng Việt
    'sắp xếp', 'sap xep', 'xếp theo', 'xep theo', 'thứ tự', 'thu tu',
    // Tiếng Anh
    'sort', 'sort by', 'sort order', 'sorted', 'sorting', 'order', 'order by', 'arrange',
    // Nhật / Trung
    '並べ替え', '並び替え', '並び順', '並替', 'ソート', '表示順', '順',
    '排序', '排序方式', '排列',
    // Bồ Đào Nha / Tây Ban Nha / Pháp
    'ordenar', 'ordenar por', 'ordem', 'ordenação', 'ordenacao', 'classificar',
    'orden', 'ordenación', 'ordenacion',
    'trier', 'trier par', 'tri par', 'ordre de tri',
    // Hàn / Nga / Khác
    '정렬', '정렬 기준', '정렬순',
    'сортировка', 'сортировать', 'порядок',
    'sortieren', 'sortierung', 'ordina', 'ordinamento',
    'urutkan', 'urutan', 'เรียงตาม', 'เรียงลำดับ', 'sırala', 'sıralama',
  ],
  FilterV2Section.contentRating: [
    // Tiếng Việt
    'phân loại nội dung', 'phan loai noi dung', 'giới hạn độ tuổi', 'gioi han do tuoi',
    'độ tuổi', 'do tuoi', 'nội dung người lớn', 'noi dung nguoi lon',
    'người lớn', 'nguoi lon', 'nhạy cảm', 'nhay cam', 'nội dung 18+',
    // Tiếng Anh
    'content rating', 'age rating', 'age restriction', 'maturity', 'mature',
    'adult', 'adult content', 'nsfw', 'erotica', 'hentai', 'smut',
    '18+', 'r18', 'r-18', 'explicit', 'suggestive', 'parental', 'content warning',
    // Nhật / Trung
    '年齢制限', '対象年齢', 'レーティング', '成人向け', 'アダルト', 'R18', 'R-18', 'エロ',
    '内容分级', '內容分級', '年龄限制', '年齡限制', '分级', '分級', '成人', '限制级', '限制級', '少儿不宜', '未成年',
    // Bồ Đào Nha / Tây Ban Nha / Pháp
    'classificação', 'classificacao', 'classificação indicativa', 'classificação etária',
    'conteúdo adulto', 'conteudo adulto', 'faixa etária', 'faixa etaria',
    'clasificación', 'clasificacion', 'clasificación de contenido', 'clasificación por edad',
    'contenido adulto', 'mayores de 18',
    'classification', 'classification du contenu', 'contenu adulte', 'public averti',
    // Hàn / Nga / Khác
    '연령 제한', '연령 등급', '이용등급', '성인', '수위', '19금',
    'возрастной рейтинг', 'возрастное ограничение', 'контент для взрослых', 'цензура',
    'altersfreigabe', 'classificazione', 'konten dewasa', 'เรทอายุ', 'ผู้ใหญ่', 'yetişkin',
  ],
  FilterV2Section.searchBy: [
    // Tiếng Việt
    'tìm theo', 'tim theo', 'tìm kiếm theo', 'tim kiem theo', 'kiểu tìm', 'kieu tim',
    'cách tìm', 'cach tim', 'tìm bằng', 'tim bang',
    'tác giả', 'tac gia', 'họa sĩ', 'hoa si', 'nhân vật', 'nhan vat', 'nhà xuất bản', 'nha xuat ban',
    // Tiếng Anh
    'search by', 'search type', 'search mode', 'search in', 'search field',
    'query type', 'filter by',
    'author', 'artist', 'creator', 'studio', 'publisher', 'author/artist', 'character',
    // Nhật / Trung
    '検索対象', '検索方法', '検索タイプ', '検索条件', '著者', '作者', '作家', '出版社', 'キャラクター',
    '搜索方式', '搜索类型', '搜尋方式', '搜尋類型', '查找方式', '作者', '画师', '畫師', '出版社', '角色',
    // Bồ Đào Nha / Tây Ban Nha / Pháp
    'buscar por', 'pesquisar por', 'procurar por', 'tipo de busca', 'tipo de pesquisa',
    'autor', 'artista', 'estúdio', 'estudio', 'editora',
    'buscar por', 'tipo de búsqueda', 'tipo de busqueda', 'editorial',
    'rechercher par', 'recherche par', 'type de recherche', 'auteur', 'artiste', 'éditeur', 'editeur',
    // Hàn / Nga / Khác
    '검색 기준', '검색 방식', '검색 유형', '저자', '작가', '출판사',
    'поиск по', 'искать по', 'тип поиска', 'автор', 'художник', 'издатель',
    'suche nach', 'cerca per', 'autore', 'cari berdasarkan', 'penulis', 'ค้นหาตาม', 'ผู้แต่ง', 'yazar',
  ],
  FilterV2Section.releaseYear: [
    // Tiếng Việt
    'năm phát hành', 'nam phat hanh', 'năm ra mắt', 'nam ra mat',
    'năm xuất bản', 'nam xuat ban', 'năm sản xuất', 'nam san xuat',
    'từ năm', 'tu nam', 'đến năm', 'den nam', 'năm',
    // Tiếng Anh
    'release year', 'year', 'years', 'year from', 'year to', 'from year', 'to year',
    'published year', 'release date', 'aired', 'publication year', 'decade',
    // Nhật / Trung
    '公開年', '発売年', '放送年', '制作年', '出版年', '発行年', '年代', '年',
    '年份', '发行年份', '發行年份', '上映年份', '出版年份', '连载年份', '連載年份', '年代',
    // Bồ Đào Nha / Tây Ban Nha / Pháp
    'ano', 'anos', 'ano de lançamento', 'ano de lancamento', 'ano de publicação',
    'año', 'años', 'año de lanzamiento', 'año de publicación', 'fecha de lanzamiento',
    'année', 'annees', 'années', 'année de sortie', 'annee de sortie', 'date de sortie',
    // Hàn / Nga / Khác
    '연도', '년도', '발매연도', '출시연도', '방영연도', '연재 연도',
    'год', 'годы', 'год выпуска', 'год выхода', 'дата выхода',
    'jahr', 'jahre', 'erscheinungsjahr', 'anno', 'tahun', 'ปี', 'ปีที่ออก', 'yıl',
  ],
  FilterV2Section.status: [
    // Tiếng Việt
    'tình trạng', 'tinh trang', 'trạng thái', 'trang thai', 'tiến độ', 'tien do',
    'đang tiến hành', 'đang ra', 'hoàn thành', 'tạm ngưng',
    // Tiếng Anh
    'status', 'statuses', 'state', 'states', 'publication status', 'release status',
    'series status', 'work status', 'ongoing', 'completed', 'hiatus', 'cancelled', 'completion',
    // Nhật / Trung
    '状態', 'ステータス', '連載状況', '連載状態', '完結',
    '状态', '狀態', '连载状态', '連載狀態', '进度', '進度', '完结', '完結', '连载', '連載',
    // Bồ Đào Nha / Tây Ban Nha / Pháp
    'estado', 'estados', 'situação', 'situacao', 'andamento', 'status da obra',
    'situación', 'situacion', 'estado de publicación',
    'statut', 'état', 'etat', 'états', 'avancement',
    // Hàn / Nga / Khác
    '상태', '연재 상태', '완결 여부',
    'статус', 'состояние', 'статус выпуска',
    'stato', 'สถานะ', 'durum',
  ],
  FilterV2Section.translation: [
    // Tiếng Việt
    'bản dịch', 'ban dich', 'ngôn ngữ', 'ngon ngu', 'ngôn ngữ gốc', 'ngon ngu goc',
    'nhóm dịch', 'nhom dich', 'dịch giả', 'dich gia', 'dịch thuật', 'dich thuat',
    'vietsub', 'thuyết minh', 'lồng tiếng', 'bản thô', 'dịch máy',
    // Tiếng Anh
    'translation', 'translations', 'translated', 'translator', 'language', 'languages',
    'lang', 'original language', 'translated language', 'scanlator', 'scanlation',
    'fansub', 'subtitle', 'subtitles', 'sub', 'dub', 'sub/dub', 'raw', 'mtl',
    // Nhật / Trung
    '翻訳', '言語', '原語', '字幕', '吹き替え', '訳',
    '翻译', '翻譯', '语言', '語言', '原语言', '原語言', '汉化', '漢化', '汉化组', '漢化組', '字幕', '配音',
    // Bồ Đào Nha / Tây Ban Nha / Pháp
    'tradução', 'traducao', 'traduzido', 'idioma', 'idiomas', 'língua', 'lingua',
    'idioma original', 'scan', 'scans', 'scanlator',
    'traducción', 'traduccion', 'traducido', 'lenguaje',
    'traduction', 'traduit', 'langue', 'langues', 'langue originale', 'scantrad',
    // Hàn / Nga / Khác
    '번역', '언어', '원어', '자막', '더빙', '역자',
    'перевод', 'переводчик', 'язык', 'языки', 'оригинальный язык', 'озвучка', 'субтитры',
    'übersetzung', 'sprache', 'traduzione', 'lingua', 'terjemahan', 'bahasa',
    'แปล', 'ภาษา', 'çeviri', 'dil',
  ],
  FilterV2Section.rating: [
    // Tiếng Việt
    'đánh giá', 'danh gia', 'điểm', 'diem', 'điểm số', 'diem so',
    'xếp hạng', 'xep hang', 'số sao', 'so sao', 'bình chọn', 'binh chon',
    // Tiếng Anh
    'rating', 'ratings', 'score', 'scores', 'min score', 'minimum score',
    'min rating', 'minimum rating', 'user rating', 'stars', 'star', 'votes',
    // Nhật / Trung
    '評価', 'スコア', 'レート', '星', 'ランキング',
    '评分', '評分', '评价', '評價', '分数', '分數', '星级', '星級',
    // Bồ Đào Nha / Tây Ban Nha / Pháp
    'avaliação', 'avaliacao', 'avaliações', 'pontuação', 'pontuacao',
    'nota mínima', 'nota minima', 'nota média', 'nota media',
    'puntuación', 'puntuacion', 'calificación', 'calificacion', 'valoración', 'valoracion',
    'évaluation', 'evaluation', 'score',
    // Hàn / Nga / Khác
    '평점', '별점', '점수', '평가',
    'рейтинг', 'оценка', 'баллы',
    'bewertung', 'valutazione', 'punteggio', 'penilaian', 'skor', 'คะแนน', 'เรตติ้ง', 'puan',
  ],
  FilterV2Section.category: [
    // Tiếng Việt
    'danh mục', 'danh muc', 'chuyên mục', 'chuyen muc', 'loại', 'loai',
    'loại truyện', 'loại phim', 'kiểu truyện', 'dạng', 'đối tượng', 'doi tuong',
    'tạp chí', 'bộ sưu tập',
    // Tiếng Anh
    'category', 'categories', 'type', 'types', 'format', 'formats',
    'demographic', 'demographics', 'media type', 'content type', 'publication type',
    'magazine', 'collection', 'section',
    // Nhật / Trung
    'カテゴリー', 'カテゴリ', 'タイプ', '種別', '種類', '形式', '媒体', '雑誌', '対象', '少年', '青年', '少女',
    '分类', '分類', '类别', '類別', '类型', '類型', '形式', '地区', '地區', '国家', '國家', '连载杂志', '受众', '受眾',
    // Bồ Đào Nha / Tây Ban Nha / Pháp
    'categoria', 'categorias', 'tipo', 'tipos', 'formato', 'formatos',
    'demografia', 'país', 'pais', 'origem',
    'categoría', 'categorías', 'demografía', 'origen',
    'catégorie', 'categorie', 'catégories', 'démographie', 'demographie', 'pays', 'origine',
    // Hàn / Nga / Khác
    '카테고리', '유형', '타입', '종류', '형식', '국가', '대상',
    'категория', 'категории', 'тип', 'типы', 'формат', 'страна', 'происхождение',
    'kategorie', 'typ', 'kategori', 'tipe', 'jenis', 'หมวดหมู่', 'ประเภท', 'tür',
  ],
  FilterV2Section.genre: [
    // Tiếng Việt
    'thể loại', 'the loai', 'nhãn', 'nhan', 'chủ đề', 'chu de',
    'bao gồm thể loại', 'loại trừ thể loại', 'thẻ',
    // Tiếng Anh
    'genre', 'genres', 'subgenre', 'subgenres', 'tag', 'tags', 'theme', 'themes',
    'include tags', 'exclude tags', 'included tags', 'excluded tags',
    'include genres', 'exclude genres', 'topic', 'topics', 'subject', 'subjects',
    // Nhật / Trung
    'ジャンル', 'タグ', 'テーマ', '属性',
    '题材', '題材', '标签', '標籤', '风格', '風格', '流派', '属性', '屬性',
    // Bồ Đào Nha / Tây Ban Nha / Pháp
    'gênero', 'gêneros', 'genero', 'generos', 'tema', 'temas', 'etiqueta', 'etiquetas',
    'género', 'géneros',
    'genre', 'genres', 'étiquette', 'etiquette', 'étiquettes', 'thème', 'themes', 'thèmes',
    // Hàn / Nga / Khác
    '장르', '태그', '주제', '테마',
    'жанр', 'жанры', 'тег', 'теги', 'тэг', 'тэги', 'тематика',
    'genere', 'generi', 'etiket', 'türler', 'แนว', 'หมวด',
  ],
};

const List<FilterV2Section> _classifyOrder = [
  FilterV2Section.sort,
  FilterV2Section.contentRating,
  FilterV2Section.country,
  FilterV2Section.searchBy,
  FilterV2Section.releaseYear,
  FilterV2Section.status,
  FilterV2Section.translation,
  FilterV2Section.rating,
  FilterV2Section.category,
  FilterV2Section.genre,
];

final RegExp _cjkOrNonLatin = RegExp(
  r'[\u3040-\u30ff\u3400-\u9fff\uac00-\ud7af\u0e00-\u0e7f\u0600-\u06ff]',
);
final RegExp _camelSplit = RegExp(r'([a-z\d])([A-Z])');
final RegExp _multiSpace = RegExp(r'\s+');
final RegExp _wordChar = RegExp(r'[a-zA-Z0-9À-ỹА-Яа-яЁё]');

String _normalize(String raw) {
  if (raw.isEmpty) return '';
  final s = raw
      .replaceAll(_camelSplit, r'$1 $2')
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .toLowerCase()
      .replaceAll(_multiSpace, ' ')
      .trim();
  return s;
}

bool _isWordCharAt(String s, int index) {
  if (index < 0 || index >= s.length) return false;
  return _wordChar.hasMatch(s[index]);
}

bool _matchesKeyword(String normalizedText, String rawKeyword) {
  if (normalizedText.isEmpty || rawKeyword.isEmpty) return false;
  final kw = _normalize(rawKeyword);
  if (kw.isEmpty) return false;

  // Tránh nhận nhầm "少年" (Shounen), "青年" (Seinen), "年齢" (Tuổi) thành Năm ("年").
  if (kw == '年') {
    if (normalizedText.contains('少年') ||
        normalizedText.contains('青年') ||
        normalizedText.contains('中年') ||
        normalizedText.contains('老年') ||
        normalizedText.contains('年齢') ||
        normalizedText.contains('成年')) {
      final stripped = normalizedText
          .replaceAll('少年', '')
          .replaceAll('青年', '')
          .replaceAll('中年', '')
          .replaceAll('老年', '')
          .replaceAll('年齢', '')
          .replaceAll('未成年', '')
          .replaceAll('成年', '');
      return stripped.contains('年');
    }
    return normalizedText.contains('年');
  }

  // Các chữ tượng hình / Thái / Ả Rập không tách bằng dấu cách.
  if (_cjkOrNonLatin.hasMatch(kw)) {
    return normalizedText.contains(kw);
  }

  // Từ Latin / Cyrillic: bắt buộc ranh giới từ hai đầu để tránh "tag" khớp "stage",
  // "sub" khớp "subject", "ano" khớp "italiano", "sort" khớp "resort".
  var start = 0;
  while (true) {
    final idx = normalizedText.indexOf(kw, start);
    if (idx < 0) return false;
    final leftOk = !_isWordCharAt(normalizedText, idx - 1);
    final rightOk = !_isWordCharAt(normalizedText, idx + kw.length);
    if (leftOk && rightOk) return true;
    start = idx + 1;
  }
}

FilterV2Section? _matchText(String text) {
  final norm = _normalize(text);
  if (norm.isEmpty) return null;
  // 0.6.2 (Claude): chọn từ khóa khớp DÀI NHẤT trên mọi ô (cùng độ dài thì theo
  // thứ tự _classifyOrder). Trước đây ô xét trước thắng ngay: "Thể loại" khớp
  // "loại" của Danh Mục trước khi tới "thể loại" của Thể Loại.
  // "Sắp xếp theo …" / "Sort by Rating/Year" luôn là Sắp Xếp (ưu tiên tuyệt đối).
  for (final kw in kFilterV2Keywords[FilterV2Section.sort]!) {
    if (_matchesKeyword(norm, kw)) return FilterV2Section.sort;
  }
  FilterV2Section? best;
  var bestLen = 0;
  for (final sec in _classifyOrder) {
    for (final kw in kFilterV2Keywords[sec]!) {
      final len = _normalize(kw).length;
      if (len > bestLen && _matchesKeyword(norm, kw)) {
        best = sec;
        bestLen = len;
      }
    }
  }
  return best;
}

String _nameOf(dynamic filter) {
  try {
    return (filter.name ?? '').toString();
  } catch (_) {
    return '';
  }
}

String _typeOf(dynamic filter) {
  try {
    return (filter.type ?? '').toString();
  } catch (_) {
    return '';
  }
}

FilterV2Section? _matchTypeField(String type) {
  final t = type.trim();
  if (t.isEmpty) return null;
  final lower = t.toLowerCase();
  if (kFilterV2TypeHints.containsKey(lower)) {
    return kFilterV2TypeHints[lower];
  }
  // Loại bỏ hậu tố tên lớp sinh bởi fetch_sources_list ("StatusFilter", "GenreFilter"…)
  final cleaned = lower
      .replaceAll(RegExp(r'(select|text|group|checkbox|tristate|header|sort)?filter$'), '')
      .replaceFirst(RegExp(r'^ir_'), '')
      .trim();
  if (cleaned.isNotEmpty && kFilterV2TypeHints.containsKey(cleaned)) {
    return kFilterV2TypeHints[cleaned];
  }
  if (cleaned.isNotEmpty) {
    return _matchText(cleaned);
  }
  return null;
}

FilterV2Section? _inferFromSelectValues(SelectFilter f) {
  if (f.values.isEmpty) return null;
  final counts = <FilterV2Section, int>{};
  for (final v in f.values) {
    final label = v is SelectFilterOption ? v.name : '$v';
    final hit = _matchText(label);
    if (hit != null && hit != FilterV2Section.other) {
      counts[hit] = (counts[hit] ?? 0) + 1;
    }
  }
  if (counts.isEmpty) return null;
  FilterV2Section? best;
  var bestN = 0;
  counts.forEach((sec, n) {
    if (n > bestN) {
      bestN = n;
      best = sec;
    }
  });
  return bestN >= 2 ? best : null;
}

FilterV2Section? _inferFromGroupChildren(GroupFilter f) {
  if (f.state.isEmpty) return null;
  var triCount = 0;
  final counts = <FilterV2Section, int>{};
  for (final child in f.state) {
    if (child is TriStateFilter) triCount++;
    final sec = classify(child);
    if (sec != FilterV2Section.other) {
      counts[sec] = (counts[sec] ?? 0) + 1;
    }
  }
  if (counts.isEmpty) {
    return triCount > 0 ? FilterV2Section.genre : null;
  }
  FilterV2Section? best;
  var bestN = 0;
  counts.forEach((sec, n) {
    if (n > bestN) {
      bestN = n;
      best = sec;
    }
  });
  return best;
}

// 0.6.5 (sheet New Filter – ô "Quốc Gia Phát Hành": đưa thông tin các quốc gia
// phát hành vào): nhiều nguồn đặt tên bộ lọc là "Type"/"Loại" nhưng lựa chọn lại
// là quốc gia (Manga/Manhwa/Manhua, Japan/Korea/China…). Xét giá trị trước tên.
const Set<String> _kOriginValues = {
  'manga', 'manhwa', 'manhua', 'manhuа', 'manhwa/webtoon', 'comic', 'comics',
  'japan', 'japanese', 'korea', 'korean', 'south korea', 'china', 'chinese',
  'taiwan', 'hong kong', 'vietnam', 'viet nam', 'vietnamese', 'thailand', 'indonesia',
  'jp', 'kr', 'cn', 'tw', 'hk', 'vn', 'ja', 'ko', 'zh',
  'nhật', 'nhat', 'nhật bản', 'nhat ban', 'hàn', 'han', 'hàn quốc', 'han quoc',
  'trung', 'trung quốc', 'trung quoc', 'việt nam', 'âu mỹ', 'au my', 'mỹ', 'my',
  '日本', '韩国', '韓国', '中国', '中國', '日漫', '韩漫', '韓漫', '国漫', '國漫',
};

List<String> _optionLabels(dynamic filter) {
  if (filter is SelectFilter) {
    return [
      for (final v in filter.values) v is SelectFilterOption ? v.name : '$v',
    ];
  }
  if (filter is GroupFilter) {
    return [for (final c in filter.state) _nameOf(c)];
  }
  return const [];
}

bool _looksLikeOrigin(dynamic filter) {
  final labels = _optionLabels(filter)
      .map((e) => _normalize(e))
      .where((e) => e.isNotEmpty && e != 'all' && e != 'tất cả' && e != 'tat ca' && e != 'any')
      .toList();
  if (labels.length < 2) return false;
  final hits = labels.where(_kOriginValues.contains).length;
  return hits >= 2 && hits * 2 >= labels.length;
}

/// Phân loại thuần một đối tượng bộ lọc (từ bất kỳ nguồn nào) vào đúng 1 trong
/// 9 ô thiết kế của sheet "New Filter" hoặc [FilterV2Section.other] nếu không khớp.
FilterV2Section classify(dynamic filter) {
  if (filter == null) return FilterV2Section.other;
  if (filter is SortFilter) return FilterV2Section.sort;
  if (filter is SeparatorFilter) return FilterV2Section.other;

  final typeStr = _typeOf(filter);
  // Kotatsu dùng type = 'ratings' cho "Phân loại nội dung" (Content rating).
  if (typeStr.trim().toLowerCase() == 'ratings') {
    return FilterV2Section.contentRating;
  }

  final name = _nameOf(filter);
  final byName = _matchText(name);
  // 0.6.5: "Type: Manga/Manhwa/Manhua" (Comick…) là quốc gia phát hành.
  if ((byName == null ||
          byName == FilterV2Section.category ||
          byName == FilterV2Section.other) &&
      _looksLikeOrigin(filter)) {
    return FilterV2Section.country;
  }
  if (byName != null) return byName;

  final byType = _matchTypeField(typeStr);
  if (byType != null) return byType;

  if (filter is GroupFilter) {
    final byChildren = _inferFromGroupChildren(filter);
    if (byChildren != null) return byChildren;
  } else if (filter is SelectFilter) {
    final byOptions = _inferFromSelectValues(filter);
    if (byOptions != null) return byOptions;
  }

  // TriStateFilter ở cấp ngoài cùng (bao gồm / loại trừ / tắt) mặc định thuộc
  // Thể Loại nếu tên là tên thẻ/thể loại cụ thể (Action, Fantasy…) chưa có trong
  // bảng từ khóa, trừ khi bản thân tên ghi rõ là "Khác" / "Other".
  if (filter is TriStateFilter) {
    final norm = _normalize(name);
    if (norm != 'khác' && norm != 'khac' && norm != 'other' && norm != 'misc') {
      return FilterV2Section.genre;
    }
  }

  return FilterV2Section.other;
}

/// Gom danh sách bộ lọc của tiện ích vào các ô theo đúng thứ tự [FilterV2Section].
///
/// Xử lý thông minh danh sách phẳng có [HeaderFilter] đi trước các ô chọn
/// [CheckBoxFilter]/[TriStateFilter] và bỏ qua [SeparatorFilter].
Map<FilterV2Section, List<dynamic>> groupFiltersV2(List<dynamic> filters) {
  final map = <FilterV2Section, List<dynamic>>{
    for (final s in FilterV2Section.values) s: <dynamic>[],
  };

  FilterV2Section? headerSection;
  for (final f in filters) {
    if (f == null || f is SeparatorFilter) {
      headerSection = null;
      continue;
    }
    if (f is HeaderFilter) {
      final hs = classify(f);
      if (hs != FilterV2Section.other) {
        // Header trùng tên nhóm → dùng làm ngữ cảnh cho các ô phẳng phía sau,
        // không nhân đôi tiêu đề bên trong thẻ đã có tên nhóm.
        headerSection = hs;
      } else {
        headerSection = null;
        if (f.name.trim().isNotEmpty) {
          map[FilterV2Section.other]!.add(f);
        }
      }
      continue;
    }

    var sec = classify(f);
    if (sec == FilterV2Section.other &&
        headerSection != null &&
        (f is CheckBoxFilter || f is TriStateFilter || f is TextFilter || f is SelectFilter)) {
      sec = headerSection;
    } else if (f is GroupFilter || f is SortFilter) {
      headerSection = null;
    }
    map[sec]!.add(f);
  }

  return map;
}
