import 'package:mangayomi/eval/model/m_pages.dart';
import 'package:mangayomi/models/source.dart';
import 'package:mangayomi/modules/more/settings/browse/providers/browse_state_provider.dart';
import 'package:mangayomi/repositories/manga_repository.dart';
import 'package:mangayomi/services/isolate_service.dart';
import 'package:mangayomi/services/local_source_page.dart';
import 'package:mangayomi/yomihub/filters/multi_select_search.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'search.g.dart';

@riverpod
Future<MPages?> search(
  Ref ref, {
  required Source source,
  required String query,
  required int page,
  required List<dynamic> filterList,
}) async {
  if (source.name == "local" && source.lang == "") {
    return localSourcePage(
      (offset, limit) => mangaRepository.searchLocalByItemType(
        source.itemType,
        query,
        offset,
        limit,
      ),
      page,
    );
  }
  final proxy = ref.read(androidProxyServerStateProvider);
  // YomiHub 0.6.1: SelectFilter chọn nhiều ô → tìm từng ô rồi gộp kết quả
  return yomiSearchMulti(
    filterList,
    (filters) => getIsolateService.get<MPages?>(
      query: query,
      filterList: filters,
      source: source,
      page: page,
      serviceType: 'search',
      proxyServer: proxy,
    ),
    sourceName: source.name ?? '',
  );
}
