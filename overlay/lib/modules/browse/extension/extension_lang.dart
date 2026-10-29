import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mangayomi/models/manga.dart';
import 'package:mangayomi/models/source.dart';
import 'package:mangayomi/providers/l10n_providers.dart';
import 'package:mangayomi/repositories/source_repository.dart';
import 'package:mangayomi/modules/browse/extension/widgets/extension_lang_list_tile_widget.dart';
import 'package:mangayomi/utils/global_style.dart';
import 'package:mangayomi/utils/language.dart';
import 'package:super_sliver_list/super_sliver_list.dart';
import 'package:mangayomi/utils/platform_utils.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';

class ExtensionsLang extends ConsumerStatefulWidget {
  final ItemType itemType;
  const ExtensionsLang({required this.itemType, super.key});

  @override
  ConsumerState<ExtensionsLang> createState() => _ExtensionsLangState();
}

class _ExtensionsLangState extends ConsumerState<ExtensionsLang> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nLocalizations(context)!;
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: tr('Tìm kiếm ngôn ngữ...'),
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontSize: 16),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim().toLowerCase();
                  });
                },
              )
            : Text(l10n.extensions),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            tooltip: _isSearching ? l10n.cancel : l10n.search,
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _searchQuery = '';
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          PopupMenuButton<int>(
            popUpAnimationStyle: popupAnimationStyle,
            itemBuilder: (context) {
              return [
                PopupMenuItem<int>(value: 0, child: Text(l10n.enable_all)),
                PopupMenuItem<int>(value: 1, child: Text(l10n.disable_all)),
              ];
            },
            onSelected: (value) {
              bool enable = value == 0;
              final sources = sourceRepository.getByItemType(widget.itemType);
              final now = DateTime.now().millisecondsSinceEpoch;
              for (var source in sources) {
                source
                  ..isActive = enable
                  ..updatedAt = now;
              }
              sourceRepository.putAll(sources);
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Source>>(
        stream: sourceRepository.watchByItemType(widget.itemType),
        builder: (context, snapshot) {
          final entries = snapshot.hasData ? snapshot.data! : <Source>[];
          final allLanguages = entries.map((e) => e.lang!).toSet().toList();
          allLanguages.sort((a, b) => a.compareTo(b));

          final filteredLanguages = _searchQuery.isEmpty
              ? allLanguages
              : allLanguages.where((lang) {
                  final code = lang.toLowerCase();
                  final fullName = completeLanguageName(code).toLowerCase();
                  final englishName = completeLanguageNameEnglish(code).toLowerCase();
                  return code.contains(_searchQuery) ||
                      fullName.contains(_searchQuery) ||
                      englishName.contains(_searchQuery);
                }).toList();

          if (filteredLanguages.isEmpty && _searchQuery.isNotEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_off, size: 64, color: Theme.of(context).hintColor),
                    const SizedBox(height: 12),
                    Text(
                      tr('Không tìm thấy ngôn ngữ phù hợp: "{p0}"', {'p0': _searchQuery}),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).hintColor),
                    ),
                  ],
                ),
              ),
            );
          }

          return SuperListView.builder(
            padding: tvPageInsets,
            itemCount: filteredLanguages.length,
            itemBuilder: (context, index) {
              final lang = filteredLanguages[index];
              return ExtensionLangListTileWidget(
                lang: lang,
                onChanged: (val) {
                  final now = DateTime.now().millisecondsSinceEpoch;
                  final toUpdate = entries
                      .where(
                        (source) =>
                            source.lang!.toLowerCase() == lang.toLowerCase(),
                      )
                      .map((source) => source..isActive = val..updatedAt = now)
                      .toList();
                  sourceRepository.putAll(toUpdate);
                },
                value: entries
                    .where(
                      (element) =>
                          element.lang!.toLowerCase() == lang.toLowerCase() &&
                          element.isActive!,
                    )
                    .isNotEmpty,
              );
            },
          );
        },
      ),
    );
  }
}
