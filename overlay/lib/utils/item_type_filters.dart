import 'package:mangayomi/models/manga.dart';

bool _isTypeHidden(String route, List<String> hideItems) {
  final lower = route.toLowerCase();
  return hideItems.any((h) => h.toLowerCase() == lower);
}

List<ItemType> hiddenItemTypes(List<String> hideItems) {
  return [
    if (!_isTypeHidden("/MangaLibrary", hideItems)) ItemType.manga,
    if (!_isTypeHidden("/AnimeLibrary", hideItems)) ItemType.anime,
    if (!_isTypeHidden("/NovelLibrary", hideItems)) ItemType.novel,
  ];
}
