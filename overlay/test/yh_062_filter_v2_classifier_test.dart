import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/eval/model/filter.dart';
import 'package:mangayomi/yomihub/filters/filter_v2_classifier.dart';
import 'package:mangayomi/yomihub/filters/filter_v2_sheet.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';

SelectFilterOption _o(String name, [String? value]) =>
    SelectFilterOption(name, value ?? name, 'SelectOption');

SelectFilter _sel(String name, {String? type, List<String> opts = const ['A', 'B', 'C']}) =>
    SelectFilter(type ?? 'SelectFilter', name, 0, opts.map(_o).toList(), 'SelectFilter');

void main() {
  setUp(() {
    YomiTr.lang = 'vi';
  });

  group('YomiHub 0.6.2 – FilterV2Classifier (classify)', () {
    test('01. thứ tự enum FilterV2Section khớp 9 ô thiết kế + Khác ở cuối', () {
      expect(FilterV2Section.values, [
        FilterV2Section.sort,
        FilterV2Section.status,
        FilterV2Section.category,
        FilterV2Section.contentRating,
        FilterV2Section.releaseYear,
        FilterV2Section.searchBy,
        FilterV2Section.rating,
        FilterV2Section.translation,
        FilterV2Section.genre,
        FilterV2Section.other,
      ]);
      expect(kFilterV2PrimarySections.length, 9);
      expect(kFilterV2PrimarySections.last, FilterV2Section.genre);
    });

    test('02. SortFilter luôn xếp vào Sắp Xếp bất kể tên', () {
      final f = SortFilter('SortFilter', 'Tùy chọn', SortState(0, false, null), [_o('A')], null);
      expect(classify(f), FilterV2Section.sort);
    });

    test('03. Sắp Xếp (Việt & Kotatsu type=sort)', () {
      expect(classify(_sel('Sắp xếp', type: 'sort')), FilterV2Section.sort);
      expect(classify(_sel('Xếp theo')), FilterV2Section.sort);
      expect(classify(_sel('sap xep')), FilterV2Section.sort);
    });

    test('04. Sắp Xếp ưu tiên hơn Đánh Giá / Năm ("Sort by Rating")', () {
      expect(classify(_sel('Sort by Rating')), FilterV2Section.sort);
      expect(classify(_sel('Order by Release Year')), FilterV2Section.sort);
      expect(classify(_sel('Sắp xếp theo đánh giá')), FilterV2Section.sort);
    });

    test('05. Sắp Xếp đa ngôn ngữ (Nhật, Trung)', () {
      expect(classify(_sel('並べ替え')), FilterV2Section.sort);
      expect(classify(_sel('ソート')), FilterV2Section.sort);
      expect(classify(_sel('排序方式')), FilterV2Section.sort);
    });

    test('06. Sắp Xếp đa ngôn ngữ (Bồ Đào Nha, Tây Ban Nha, Pháp)', () {
      expect(classify(_sel('Ordenar por')), FilterV2Section.sort);
      expect(classify(_sel('Ordenación')), FilterV2Section.sort);
      expect(classify(_sel('Trier par')), FilterV2Section.sort);
    });

    test('07. Sắp Xếp đa ngôn ngữ (Hàn, Nga)', () {
      expect(classify(_sel('정렬 기준')), FilterV2Section.sort);
      expect(classify(_sel('Сортировка')), FilterV2Section.sort);
    });

    test('08. Tình Trạng (Việt & Kotatsu type=states)', () {
      final f = GroupFilter('states', 'Tình trạng', [
        CheckBoxFilter('states', 'Đang tiến hành', 'ONGOING', 'CheckBox'),
      ], 'GroupFilter');
      expect(classify(f), FilterV2Section.status);
      expect(classify(_sel('Trạng thái')), FilterV2Section.status);
    });

    test('09. Tình Trạng (Anh)', () {
      expect(classify(_sel('Status')), FilterV2Section.status);
      expect(classify(_sel('Publication Status')), FilterV2Section.status);
      expect(classify(CheckBoxFilter(null, 'Only Completed', 'done', null)), FilterV2Section.status);
    });

    test('10. Tình Trạng đa ngôn ngữ (Nhật, Trung, Bồ Đào Nha, Tây Ban Nha, Pháp)', () {
      expect(classify(_sel('連載状況')), FilterV2Section.status);
      expect(classify(_sel('连载状态')), FilterV2Section.status);
      expect(classify(_sel('Situação')), FilterV2Section.status);
      expect(classify(_sel('Estado')), FilterV2Section.status);
      expect(classify(_sel('Statut')), FilterV2Section.status);
    });

    test('11. Danh Mục (vBook vb_tab, Kotatsu types & demographics)', () {
      expect(classify(_sel('Danh mục', type: 'vb_tab')), FilterV2Section.category);
      expect(classify(GroupFilter('types', 'Loại', [], 'GroupFilter')), FilterV2Section.category);
      expect(classify(GroupFilter('demographics', 'Đối tượng', [], 'GroupFilter')), FilterV2Section.category);
    });

    test('12. Danh Mục đa ngôn ngữ (Anh, Nhật, Trung, Bồ Đào Nha, Hàn)', () {
      expect(classify(_sel('Category')), FilterV2Section.category);
      expect(classify(_sel('Format')), FilterV2Section.category);
      expect(classify(_sel('カテゴリー')), FilterV2Section.category);
      expect(classify(_sel('少年')), FilterV2Section.category);
      expect(classify(_sel('分类')), FilterV2Section.category);
      expect(classify(_sel('Categoria')), FilterV2Section.category);
      expect(classify(_sel('카테고리')), FilterV2Section.category);
    });

    test('13. Phân Loại Nội Dung (Kotatsu ratings & tiếng Việt)', () {
      expect(classify(GroupFilter('ratings', 'Phân loại nội dung', [], 'GroupFilter')), FilterV2Section.contentRating);
      expect(classify(GroupFilter('ratings', 'Ratings', [], 'GroupFilter')), FilterV2Section.contentRating);
      expect(classify(_sel('Giới hạn độ tuổi')), FilterV2Section.contentRating);
    });

    test('14. Phân Loại Nội Dung ưu tiên hơn Đánh Giá ("Content Rating", "Age Rating")', () {
      expect(classify(_sel('Content Rating')), FilterV2Section.contentRating);
      expect(classify(_sel('Age Rating')), FilterV2Section.contentRating);
      expect(classify(CheckBoxFilter(null, 'NSFW / 18+', 'nsfw', null)), FilterV2Section.contentRating);
    });

    test('15. Phân Loại Nội Dung đa ngôn ngữ (Nhật, Trung, Bồ Đào Nha, Tây Ban Nha, Nga)', () {
      expect(classify(_sel('年齢制限')), FilterV2Section.contentRating);
      expect(classify(_sel('内容分级')), FilterV2Section.contentRating);
      expect(classify(_sel('Classificação indicativa')), FilterV2Section.contentRating);
      expect(classify(_sel('Clasificación de contenido')), FilterV2Section.contentRating);
      expect(classify(_sel('Возрастной рейтинг')), FilterV2Section.contentRating);
    });

    test('16. Năm Phát Hành (Việt & Kotatsu year/yearFrom/yearTo)', () {
      expect(classify(TextFilter('year', 'Năm phát hành', 'TextFilter')), FilterV2Section.releaseYear);
      expect(classify(TextFilter('yearFrom', 'Từ năm', 'TextFilter')), FilterV2Section.releaseYear);
      expect(classify(TextFilter('yearTo', 'Đến năm', 'TextFilter')), FilterV2Section.releaseYear);
    });

    test('17. Năm Phát Hành đa ngôn ngữ (Anh, Nhật, Trung, Bồ Đào Nha, Tây Ban Nha, Pháp)', () {
      expect(classify(_sel('Release Year')), FilterV2Section.releaseYear);
      expect(classify(TextFilter(null, '公開年', 'TextFilter')), FilterV2Section.releaseYear);
      expect(classify(_sel('年份')), FilterV2Section.releaseYear);
      expect(classify(_sel('Ano de lançamento')), FilterV2Section.releaseYear);
      expect(classify(_sel('Año')), FilterV2Section.releaseYear);
      expect(classify(_sel('Année de sortie')), FilterV2Section.releaseYear);
    });

    test('18. Tìm Theo (Việt, Anh, ưu tiên hơn Thể Loại với "Search by Genre")', () {
      expect(classify(_sel('Tìm theo')), FilterV2Section.searchBy);
      expect(classify(_sel('Search by')), FilterV2Section.searchBy);
      expect(classify(_sel('Search by Genre')), FilterV2Section.searchBy);
      expect(classify(_sel('Tìm theo thể loại')), FilterV2Section.searchBy);
    });

    test('19. Tìm Theo cho Tác giả / Họa sĩ đa ngôn ngữ (Kotatsu, Nhật, Trung, Bồ Đào Nha)', () {
      expect(classify(TextFilter('author', 'Tác giả', 'TextFilter')), FilterV2Section.searchBy);
      expect(classify(TextFilter(null, 'Author/Artist', 'TextFilter')), FilterV2Section.searchBy);
      expect(classify(TextFilter(null, '著者', 'TextFilter')), FilterV2Section.searchBy);
      expect(classify(_sel('搜索方式')), FilterV2Section.searchBy);
      expect(classify(_sel('Buscar por')), FilterV2Section.searchBy);
    });

    test('20. Đánh Giá (Việt, Anh)', () {
      expect(classify(_sel('Đánh giá')), FilterV2Section.rating);
      expect(classify(TextFilter('min_score', 'Minimum Score', 'TextFilter')), FilterV2Section.rating);
      expect(classify(_sel('User Rating')), FilterV2Section.rating);
    });

    test('21. Đánh Giá đa ngôn ngữ (Nhật, Trung, Bồ Đào Nha, Tây Ban Nha, Hàn, Nga)', () {
      expect(classify(_sel('評価')), FilterV2Section.rating);
      expect(classify(_sel('评分')), FilterV2Section.rating);
      expect(classify(_sel('Avaliação')), FilterV2Section.rating);
      expect(classify(_sel('Puntuación')), FilterV2Section.rating);
      expect(classify(_sel('평점')), FilterV2Section.rating);
      expect(classify(_sel('Рейтинг')), FilterV2Section.rating);
    });

    test('22. Bản Dịch (Việt, Anh, Kotatsu locale/originalLocale)', () {
      expect(classify(_sel('Bản dịch')), FilterV2Section.translation);
      expect(classify(_sel('Ngôn ngữ', type: 'locale')), FilterV2Section.translation);
      expect(classify(_sel('Ngôn ngữ gốc', type: 'originalLocale')), FilterV2Section.translation);
      expect(classify(_sel('Translation Language')), FilterV2Section.translation);
      expect(classify(TextFilter(null, 'Scanlator', 'TextFilter')), FilterV2Section.translation);
    });

    test('23. Bản Dịch đa ngôn ngữ (Nhật, Trung, Bồ Đào Nha, Tây Ban Nha, Pháp, Nga)', () {
      expect(classify(_sel('翻訳')), FilterV2Section.translation);
      expect(classify(_sel('翻译')), FilterV2Section.translation);
      expect(classify(_sel('Tradução')), FilterV2Section.translation);
      expect(classify(_sel('Idioma')), FilterV2Section.translation);
      expect(classify(_sel('Traduction')), FilterV2Section.translation);
      expect(classify(_sel('Перевод')), FilterV2Section.translation);
    });

    test('24. Thể Loại (Mangayomi, Mihon, Kotatsu tags, vBook vb_genre)', () {
      expect(classify(GroupFilter('tags', 'Thể loại', [], 'GroupFilter')), FilterV2Section.genre);
      expect(classify(_sel('Thể loại', type: 'vb_genre')), FilterV2Section.genre);
      expect(classify(GroupFilter('GroupFilter', 'Include Tags', [], 'GroupFilter')), FilterV2Section.genre);
      expect(classify(TriStateFilter(null, 'Action', 'action', null)), FilterV2Section.genre);
    });

    test('25. Thể Loại đa ngôn ngữ (Anh, Nhật, Trung, Bồ Đào Nha, Hàn, Nga)', () {
      expect(classify(_sel('Genres')), FilterV2Section.genre);
      expect(classify(_sel('ジャンル')), FilterV2Section.genre);
      expect(classify(_sel('题材')), FilterV2Section.genre);
      expect(classify(_sel('Gêneros')), FilterV2Section.genre);
      expect(classify(_sel('장르')), FilterV2Section.genre);
      expect(classify(_sel('Жанры')), FilterV2Section.genre);
    });

    test('26. Không khớp & chống khớp nhầm chuỗi con → Khác (other)', () {
      expect(classify(null), FilterV2Section.other);
      expect(classify(SeparatorFilter('SeparatorFilter')), FilterV2Section.other);
      // 0.6.2: 'subject' là từ khóa Thể Loại hợp lệ → ca chống khớp chuỗi con dùng 'Subsection'
      expect(classify(CheckBoxFilter(null, 'Subsection Filter', 'subj', null)), FilterV2Section.other);
      expect(classify(TextFilter(null, 'Stage', 'TextFilter')), FilterV2Section.other);
      expect(classify(CheckBoxFilter(null, 'Italiano Custom', 'it', null)), FilterV2Section.other);
      expect(classify(HeaderFilter('Nota: tap reset', 'HeaderFilter')), FilterV2Section.other);
      expect(classify(_sel('Server', opts: ['S1', 'S2'])), FilterV2Section.other);
    });

    test('27. Suy luận GroupFilter tên chung ("Bộ lọc") từ danh sách con', () {
      final group = GroupFilter('GroupFilter', 'Bộ lọc', [
        TriStateFilter(null, 'Hành động', 'action', null),
        TriStateFilter(null, 'Hài hước', 'comedy', null),
      ], 'GroupFilter');
      expect(classify(group), FilterV2Section.genre);
    });

    test('28. groupFiltersV2 gom HeaderFilter + CheckBox phẳng và bỏ SeparatorFilter', () {
      final list = <dynamic>[
        HeaderFilter('Bộ lọc chỉ dùng khi ô tìm kiếm để trống', 'HeaderFilter'),
        SeparatorFilter('SeparatorFilter'),
        HeaderFilter('Thể loại', 'HeaderFilter'),
        CheckBoxFilter(null, 'Action', 'action', 'CheckBox'),
        CheckBoxFilter(null, 'Comedy', 'comedy', 'CheckBox'),
        SortFilter('SortFilter', 'Sắp xếp', SortState(0, false, null), [_o('Mới')], null),
      ];
      final grouped = groupFiltersV2(list);
      expect(grouped[FilterV2Section.sort]!.length, 1);
      expect(grouped[FilterV2Section.genre]!.length, 2);
      expect(grouped[FilterV2Section.other]!.length, 1);
      expect(grouped[FilterV2Section.other]!.first, isA<HeaderFilter>());
    });
  });

  group('YomiHub 0.6.2 – FilterV2Sheet widget', () {
    testWidgets('hiện đủ 4 nút hàng trên cùng và đúng thứ tự các ô thẻ', (t) async {
      var resetCount = 0;
      var loadCount = 0;
      var bookmarkCount = 0;
      var applyCount = 0;

      final filters = <dynamic>[
        SortFilter('SortFilter', 'Sắp xếp', SortState(0, false, null), [_o('Mới nhất'), _o('Phổ biến')], null),
        SelectFilter('SelectFilter', 'Tình trạng', 0, [_o('Tất cả'), _o('Đang ra')], null),
        GroupFilter('tags', 'Thể loại', [
          TriStateFilter('tags', 'Hành động', 'action', 'TriState'),
          TriStateFilter('tags', 'Kinh dị', 'horror', 'TriState'),
        ], 'GroupFilter'),
        CheckBoxFilter(null, 'Mục tùy chỉnh riêng', 'custom', null),
      ];

      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterV2Sheet(
              filters: filters,
              onChanged: (_) {},
              onReset: () => resetCount++,
              onLoad: () => loadCount++,
              onBookmark: () => bookmarkCount++,
              onApply: () => applyCount++,
            ),
          ),
        ),
      );
      await t.pumpAndSettle();

      expect(find.text('Đặt Lại'), findsOneWidget);
      expect(find.text('Nạp Bộ Lọc'), findsOneWidget);
      expect(find.text('Đánh Dấu'), findsOneWidget);
      expect(find.text('Bộ Lọc'), findsOneWidget);

      await t.tap(find.text('Đặt Lại'));
      await t.tap(find.text('Nạp Bộ Lọc'));
      await t.tap(find.text('Đánh Dấu'));
      await t.tap(find.text('Bộ Lọc'));
      expect(resetCount, 1);
      expect(loadCount, 1);
      expect(bookmarkCount, 1);
      expect(applyCount, 1);

      // Kiểm tra thứ tự Y của các ô: Sắp Xếp < Tình Trạng < Thể Loại < Khác
      final sortY = t.getTopLeft(find.text('Sắp Xếp')).dy;
      final statusY = t.getTopLeft(find.text('Tình Trạng')).dy;
      final genreY = t.getTopLeft(find.text('Thể Loại')).dy;
      final otherY = t.getTopLeft(find.text('Khác')).dy;
      expect(sortY, lessThan(statusY));
      expect(statusY, lessThan(genreY));
      expect(genreY, lessThan(otherY));
    });

    testWidgets('Tìm Theo chọn-một, Thể loại TriState 3 trạng thái, giữ TextFilter khi gập/mở', (t) async {
      final searchBy = _sel('Tìm theo', opts: ['Tên truyện', 'Tác giả', 'Thể loại']);
      final year = TextFilter('year', 'Năm phát hành', 'TextFilter');
      final genre = GroupFilter('tags', 'Thể loại', [
        TriStateFilter('tags', 'Hành động', 'action', 'TriState'),
      ], 'GroupFilter');

      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterV2Sheet(
              filters: [year, searchBy, genre],
              onChanged: (_) {},
              onReset: () {},
              onApply: () {},
            ),
          ),
        ),
      );
      await t.pumpAndSettle();

      // Nhập năm rồi gập & mở lại ô Năm Phát Hành -> KHÔNG mất chữ, KHÔNG lỗi PageStorageKey bool/double
      await t.enterText(find.byType(TextField).first, '2024');
      await t.pumpAndSettle();
      expect(year.state, '2024');

      await t.tap(find.text('Năm Phát Hành'));
      await t.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);

      await t.tap(find.text('Năm Phát Hành'));
      await t.pumpAndSettle();
      expect(t.widget<TextField>(find.byType(TextField).first).controller?.text, '2024');
      expect(t.takeException(), isNull);

      // Tìm Theo chỉ chọn-một
      await t.ensureVisible(find.text('Tác giả'));
      await t.tap(find.text('Tác giả'));
      await t.pumpAndSettle();
      await t.ensureVisible(find.text('Thể loại').last);
      await t.tap(find.text('Thể loại').last);
      await t.pumpAndSettle();
      expect(searchBy.state, 2);
      expect(searchBy.multi, isEmpty);

      // TriState 0 -> 1 -> 2
      await t.ensureVisible(find.text('Hành động'));
      await t.tap(find.text('Hành động'));
      await t.pumpAndSettle();
      expect((genre.state.first as TriStateFilter).state, 1);
      await t.tap(find.text('Hành động'));
      await t.pumpAndSettle();
      expect((genre.state.first as TriStateFilter).state, 2);
    });
  });
}
