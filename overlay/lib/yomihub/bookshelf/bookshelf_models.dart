/// YomiHub 0.6.3 – "Tủ Sách Cá Nhân": data model (tables of sheet
/// "Cau_Truc_Du_Lieu" of `Ke_Hoach_App_Quan_Ly_Tu_Sach_Ca_Nhan.xlsx`).
/// Stored as JSON maps in the Hive box `yomihub_bookshelf` (in app backups).
library;

String _s(Object? v) => v?.toString() ?? '';
double? _d(Object? v) => v is num ? v.toDouble() : double.tryParse(_s(v));
int _i(Object? v, [int def = 0]) => v is num ? v.toInt() : int.tryParse(_s(v)) ?? def;

/// Series status (FN-06 filter: "Đang ra" / "Đã trọn bộ").
enum BsStatus { ongoing, completed, paused }

/// Edition of a volume (FN-21: the regular and the limited edition often
/// share one ISBN, so the duplicate key is (series, number, edition)).
enum BsEdition { regular, limited, special }

enum BsReadStatus { unread, reading, read }

T _enum<T extends Enum>(List<T> values, Object? v, T def) {
  for (final e in values) {
    if (e.name == v) return e;
  }
  return def;
}

/// Table 1 – Series (+ table 7 Series_Aliases as [aliases]).
class BsSeries {
  final String id;
  String title;
  String original;
  String author;
  String publisher;
  String cover; // URL or local file path
  String synopsis;
  int? totalVolumes;
  BsStatus status;
  List<String> aliases;
  int createdAt;
  int updatedAt;

  BsSeries({
    required this.id,
    required this.title,
    this.original = '',
    this.author = '',
    this.publisher = '',
    this.cover = '',
    this.synopsis = '',
    this.totalVolumes,
    this.status = BsStatus.ongoing,
    List<String>? aliases,
    int? createdAt,
    int? updatedAt,
  })  : aliases = aliases ?? [],
        createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch,
        updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;

  factory BsSeries.fromJson(Map m) => BsSeries(
        id: _s(m['id']),
        title: _s(m['title']),
        original: _s(m['original']),
        author: _s(m['author']),
        publisher: _s(m['publisher']),
        cover: _s(m['cover']),
        synopsis: _s(m['synopsis']),
        totalVolumes: m['totalVolumes'] == null ? null : _i(m['totalVolumes']),
        status: _enum(BsStatus.values, m['status'], BsStatus.ongoing),
        aliases: [for (final a in (m['aliases'] as List? ?? const [])) _s(a)],
        createdAt: _i(m['createdAt']),
        updatedAt: _i(m['updatedAt']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'original': original,
        'author': author,
        'publisher': publisher,
        'cover': cover,
        'synopsis': synopsis,
        'totalVolumes': totalVolumes,
        'status': status.name,
        'aliases': aliases,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}

/// Table 2 – Volumes (only owned volumes are stored; wishes live in
/// [BsWish]). [copies] > 1 = collector owns several copies (FN-26).
class BsVolume {
  final String id;
  final String seriesId;
  double number;
  BsEdition edition;
  String isbn;
  int copies;
  BsReadStatus readStatus;
  int? purchaseDate;
  double? price;
  String place;
  String note;
  String? borrower; // FN-28 – who has borrowed it
  int? loanDue;

  BsVolume({
    required this.id,
    required this.seriesId,
    required this.number,
    this.edition = BsEdition.regular,
    this.isbn = '',
    this.copies = 1,
    this.readStatus = BsReadStatus.unread,
    this.purchaseDate,
    this.price,
    this.place = '',
    this.note = '',
    this.borrower,
    this.loanDue,
  });

  String get numberText => number == number.roundToDouble() ? number.toInt().toString() : number.toString();

  factory BsVolume.fromJson(Map m) => BsVolume(
        id: _s(m['id']),
        seriesId: _s(m['seriesId']),
        number: _d(m['number']) ?? 0,
        edition: _enum(BsEdition.values, m['edition'], BsEdition.regular),
        isbn: _s(m['isbn']),
        copies: _i(m['copies'], 1),
        readStatus: _enum(BsReadStatus.values, m['readStatus'], BsReadStatus.unread),
        purchaseDate: m['purchaseDate'] == null ? null : _i(m['purchaseDate']),
        price: _d(m['price']),
        place: _s(m['place']),
        note: _s(m['note']),
        borrower: m['borrower'] == null ? null : _s(m['borrower']),
        loanDue: m['loanDue'] == null ? null : _i(m['loanDue']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'seriesId': seriesId,
        'number': number,
        'edition': edition.name,
        'isbn': isbn,
        'copies': copies,
        'readStatus': readStatus.name,
        'purchaseDate': purchaseDate,
        'price': price,
        'place': place,
        'note': note,
        'borrower': borrower,
        'loanDue': loanDue,
      };
}

/// Tables 3–5 – a custom folder of a series (Limited, Artbook & ColorWalk,
/// Boxset, Goods…) holding special items with accessories and photos.
class BsFolder {
  final String id;
  final String seriesId;
  String name;
  List<BsItem> items;

  BsFolder({required this.id, required this.seriesId, required this.name, List<BsItem>? items})
      : items = items ?? [];

  factory BsFolder.fromJson(Map m) => BsFolder(
        id: _s(m['id']),
        seriesId: _s(m['seriesId']),
        name: _s(m['name']),
        items: [for (final e in (m['items'] as List? ?? const [])) if (e is Map) BsItem.fromJson(e)],
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'seriesId': seriesId, 'name': name, 'items': [for (final i in items) i.toJson()]};
}

class BsItem {
  final String id;
  String name;
  String isbn;
  bool postcard, poster, standee, sealed;
  String notes;
  String storage; // "Tủ kính tầng 2"
  double? price;
  List<String> photos; // local file paths (FN-14)

  BsItem({
    required this.id,
    required this.name,
    this.isbn = '',
    this.postcard = false,
    this.poster = false,
    this.standee = false,
    this.sealed = false,
    this.notes = '',
    this.storage = '',
    this.price,
    List<String>? photos,
  }) : photos = photos ?? [];

  factory BsItem.fromJson(Map m) => BsItem(
        id: _s(m['id']),
        name: _s(m['name']),
        isbn: _s(m['isbn']),
        postcard: m['postcard'] == true,
        poster: m['poster'] == true,
        standee: m['standee'] == true,
        sealed: m['sealed'] == true,
        notes: _s(m['notes']),
        storage: _s(m['storage']),
        price: _d(m['price']),
        photos: [for (final p in (m['photos'] as List? ?? const [])) _s(p)],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isbn': isbn,
        'postcard': postcard,
        'poster': poster,
        'standee': standee,
        'sealed': sealed,
        'notes': notes,
        'storage': storage,
        'price': price,
        'photos': photos,
      };
}

/// Table 8 – Wishlist ("Cần mua").
class BsWish {
  final String id;
  final String seriesId;
  double? volume;
  BsEdition edition;
  String note;
  int? remindAt;

  BsWish({required this.id, required this.seriesId, this.volume, this.edition = BsEdition.regular, this.note = '', this.remindAt});

  factory BsWish.fromJson(Map m) => BsWish(
        id: _s(m['id']),
        seriesId: _s(m['seriesId']),
        volume: _d(m['volume']),
        edition: _enum(BsEdition.values, m['edition'], BsEdition.regular),
        note: _s(m['note']),
        remindAt: m['remindAt'] == null ? null : _i(m['remindAt']),
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'seriesId': seriesId, 'volume': volume, 'edition': edition.name, 'note': note, 'remindAt': remindAt};
}

/// Table 10 – Scan_History (FN-20 batch scan, offline cache of look-ups).
class BsScan {
  final String isbn;
  final int at;
  final String title;
  final String result; // owned | added | skipped | notFound

  const BsScan({required this.isbn, required this.at, this.title = '', this.result = ''});

  factory BsScan.fromJson(Map m) =>
      BsScan(isbn: _s(m['isbn']), at: _i(m['at']), title: _s(m['title']), result: _s(m['result']));

  Map<String, dynamic> toJson() => {'isbn': isbn, 'at': at, 'title': title, 'result': result};
}

/// Ownership badge of a search result (FN-02).
enum BsOwnership {
  /// green – owned (the asked volume, or the series has volumes)
  owned,

  /// orange – the regular edition is owned but not the limited one
  regularOnly,

  /// red – not bought yet
  missing,
}

/// One instant-search hit.
class BsHit {
  final BsSeries series;
  final double? volume;
  final BsOwnership ownership;
  final int score;
  final double? latest;
  const BsHit(this.series, this.volume, this.ownership, this.score, this.latest);
}

/// Result of an ISBN look-up (own shelf first, then online catalogues).
class BsLookup {
  final String isbn;
  final String title;
  final String author;
  final String publisher;
  final String cover;
  final String synopsis;
  final double? volume;
  final String source; // shelf | google | openlibrary | cache
  const BsLookup({
    required this.isbn,
    this.title = '',
    this.author = '',
    this.publisher = '',
    this.cover = '',
    this.synopsis = '',
    this.volume,
    this.source = '',
  });
}
