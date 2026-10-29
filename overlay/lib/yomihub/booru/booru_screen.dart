import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:mangayomi/modules/more/settings/browse/providers/browse_state_provider.dart';
import 'package:mangayomi/services/http/m_client.dart';
import 'package:mangayomi/utils/cached_network.dart';
import 'package:mangayomi/utils/log/logger.dart';
import 'package:mangayomi/yomihub/booru/booru_api.dart';
import 'package:mangayomi/yomihub/booru/booru_models.dart';
import 'package:mangayomi/yomihub/booru/booru_store.dart';
import 'package:mangayomi/yomihub/booru/booru_viewer.dart';
import 'package:mangayomi/yomihub/cloudflare/cf_challenge.dart';
import 'package:mangayomi/yomihub/extensions/ext_errors.dart';
import 'package:mangayomi/yomihub/i18n/yomi_tr.dart';

/// YomiHub 0.4.4 – Booru App main screen (tab right of "Play Books").
///
/// Features taken from the Booru projects of the sheet: several boards and
/// API families with a site switcher (BooruHub, Boorusphere), tag search with
/// autocomplete and search history (Boorusama), infinite grid, favourites,
/// tag blacklist, rating filter tied to the app's NSFW setting (Rule-34 App,
/// Booru-Studio), viewer with zoom / video / download / share (Boorusama,
/// Hybooru).
class BooruScreen extends ConsumerStatefulWidget {
  const BooruScreen({super.key});

  @override
  ConsumerState<BooruScreen> createState() => _BooruScreenState();
}

/// Shared HTTP client: follows "VPN & DNS" (Tor/WARP/proxy, DoH).
http.Client booruClient() => MClient.init(reqcopyWith: {'useDartHttpClient': true});

void booruLog(String where, Object e, {BooruSite? site}) {
  final net = YomiExtErrors.isNetworkError(e) || e is TimeoutException;
  var hint = '';
  if (e is BooruException) {
    hint = switch (e.kind) {
      BooruError.needsKey => ' – trang yêu cầu tài khoản/API key: nhập trong Cài đặt › Booru App',
      BooruError.cloudflare => ' – trang chặn bằng Cloudflare: bật WARP/VPN trong "VPN & DNS"',
      BooruError.blocked => ' – máy chủ từ chối truy cập',
      _ => '',
    };
  } else {
    final h = YomiExtErrors.hint(e);
    if (h != null) hint = ' – $h';
  }
  AppLogger.log('[Booru App] $where${site == null ? '' : ' (${site.name}, ${site.host})'}: ${YomiExtErrors.short(e)}$hint',
      logLevel: net ? LogLevel.warning : LogLevel.error);
}

class _BooruScreenState extends ConsumerState<BooruScreen> with SingleTickerProviderStateMixin {
  final store = BooruStore.instance;
  late final TabController _tabs = TabController(length: 3, vsync: this);
  final _search = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  late final BooruApi _api = BooruApi(booruClient());

  final List<BooruPost> _posts = [];
  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;
  String? _error;
  bool _errorCf = false;
  String _query = '';
  int _gen = 0;

  List<BooruTag> _suggest = const [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    store.addListener(_onStore);
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 800) _load();
    });
    _focus.addListener(() => setState(() {}));
    store.init().then((_) => _reload());
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    store.removeListener(_onStore);
    _tabs.dispose();
    _search.dispose();
    _focus.dispose();
    _scroll.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  bool get _nsfw => ref.read(showNSFWStateProvider);
  BooruSite get _site => store.site(_nsfw);

  Future<void> _reload() async {
    _gen++;
    setState(() {
      _posts.clear();
      _page = 1;
      _hasMore = true;
      _error = null;
      _loading = false;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
    await _load();
  }

  Future<void> _load() async {
    if (_loading || !_hasMore || !store.ready) return;
    final gen = _gen;
    final site = _site;
    setState(() => _loading = true);
    try {
      var got = await _api.posts(site, _query, _page,
          safe: !_nsfw, login: store.login(site.id), apiKey: store.apiKey(site.id));
      if (gen != _gen) return;
      final raw = got.length;
      got = BooruFilter.apply(got, showNsfw: _nsfw, blacklist: store.blacklist);
      setState(() {
        _posts.addAll(got);
        _page++;
        _hasMore = raw >= BooruApi.pageSize ~/ 2;
        _error = null;
      });
    } catch (e) {
      if (gen != _gen) return;
      booruLog(_query.isEmpty ? 'Không tải được danh sách' : 'Không tìm được "$_query"', e, site: site);
      setState(() {
        _error = _friendly(e);
        // a Cloudflare challenge waiting in the background shows up as a
        // timeout: offer the WebView button for both
        _errorCf = (e is BooruException && e.kind == BooruError.cloudflare) || e is TimeoutException;
      });
    } finally {
      if (gen == _gen && mounted) setState(() => _loading = false);
    }
  }

  String _friendly(Object e) {
    if (e is BooruException) {
      switch (e.kind) {
        case BooruError.needsKey:
          return tr('{p0} yêu cầu tài khoản / API key. Nhập trong Cài đặt › Booru App › Tài khoản.', {'p0': e.site.name});
        case BooruError.cloudflare:
          return tr('{p0} đang chặn bằng Cloudflare. Bật WARP/VPN trong "VPN & DNS" rồi thử lại.', {'p0': e.site.name});
        case BooruError.blocked:
          return tr('{p0} từ chối truy cập (có thể bị nhà mạng chặn). Thử bật VPN & DNS.', {'p0': e.site.name});
        default:
          return tr('Lỗi máy chủ: {p0}', {'p0': e.message});
      }
    }
    if (e is TimeoutException) {
      return tr('{p0} không phản hồi kịp (có thể đang chờ xác minh Cloudflare). Thử lại hoặc bấm "Vượt Cloudflare bằng WebView".', {'p0': _site.name});
    }
    return tr('Không tải được: {p0}', {'p0': YomiExtErrors.short(e)});
  }

  void _submit(String q) {
    _query = q.trim();
    _search.text = _query;
    _focus.unfocus();
    setState(() => _suggest = const []);
    store.addHistory(_query);
    _tabs.animateTo(0);
    _reload();
  }

  void _onTyping(String v) {
    _debounce?.cancel();
    final words = v.split(' ');
    final last = words.isEmpty ? '' : words.last;
    if (last.length < 2) {
      setState(() => _suggest = const []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final s = await _api.autocomplete(_site, last.startsWith('-') ? last.substring(1) : last);
        if (mounted && _search.text == v) setState(() => _suggest = s);
      } catch (e) {
        booruLog('Gợi ý thẻ lỗi', e, site: _site);
      }
    });
  }

  void _pickSuggestion(BooruTag t) {
    final words = _search.text.split(' ');
    final neg = words.isNotEmpty && words.last.startsWith('-');
    words[words.length - 1] = '${neg ? '-' : ''}${t.name}';
    _search.text = '${words.join(' ')} ';
    _search.selection = TextSelection.collapsed(offset: _search.text.length);
    setState(() => _suggest = const []);
  }

  void _open(List<BooruPost> list, int i) {
    // root navigator: full screen, above the bottom navigation bar
    Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
      builder: (_) => BooruViewer(
        posts: list,
        initialIndex: i,
        api: _api,
        onTag: (t) {
          Navigator.of(context, rootNavigator: true).pop();
          _submit(t);
        },
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final showNsfw = ref.watch(showNSFWStateProvider);
    final sites = store.visibleSites(showNsfw);
    final site = store.site(showNsfw);
    return Scaffold(
      appBar: AppBar(
        title: PopupMenuButton<String>(
          tooltip: tr('Chọn trang Booru'),
          onSelected: (id) async {
            await store.setActiveSite(id);
            _reload();
          },
          itemBuilder: (_) => [
            for (final s in sites)
              CheckedPopupMenuItem(value: s.id, checked: s.id == site.id, child: Text(s.name)),
          ],
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('Booru'),
            const SizedBox(width: 8),
            Flexible(
              child: Text('· ${site.name}',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
            ),
            const Icon(Icons.arrow_drop_down),
          ]),
        ),
        actions: [
          IconButton(
            tooltip: tr('Tải lại'),
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
          IconButton(
            tooltip: tr('Cài đặt Booru App'),
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/booruSettings'),
          ),
        ],
        bottom: TabBar(controller: _tabs, tabs: [
          Tab(text: tr('Duyệt')),
          Tab(text: tr('Yêu thích')),
          Tab(text: tr('Lịch sử tìm')),
        ]),
      ),
      body: TabBarView(controller: _tabs, children: [
        _browse(site),
        _favourites(showNsfw),
        _historyTab(),
      ]),
    );
  }

  Widget _browse(BooruSite site) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: TextField(
          controller: _search,
          focusNode: _focus,
          textInputAction: TextInputAction.search,
          onChanged: _onTyping,
          onSubmitted: _submit,
          decoration: InputDecoration(
            isDense: true,
            prefixIcon: const Icon(Icons.search),
            hintText: tr('Tìm theo thẻ (vd: scenery 1girl -sketch)'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
            suffixIcon: _search.text.isEmpty && _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _search.clear();
                      _submit('');
                    },
                  ),
          ),
        ),
      ),
      if (_focus.hasFocus && _suggest.isNotEmpty)
        Expanded(
          child: ListView(children: [
            for (final t in _suggest)
              ListTile(
                dense: true,
                leading: const Icon(Icons.sell_outlined, size: 18),
                title: Text(t.name.replaceAll('_', ' ')),
                trailing: t.count > 0 ? Text('${t.count}') : null,
                onTap: () => _pickSuggestion(t),
              ),
          ]),
        )
      else
        Expanded(child: _grid()),
    ]);
  }

  Widget _grid() {
    if (_posts.isEmpty && _loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_posts.isEmpty && _error != null) {
      return _message(Icons.cloud_off_outlined, _error!, retry: true, cloudflare: _errorCf);
    }
    if (_posts.isEmpty && !_hasMore) {
      return _message(Icons.image_search_outlined, tr('Không có kết quả'));
    }
    return RefreshIndicator(
      onRefresh: _reload,
      child: GridView.builder(
        controller: _scroll,
        padding: const EdgeInsets.all(6),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: store.columns,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 0.72,
        ),
        itemCount: _posts.length + (_hasMore || _error != null ? 1 : 0),
        itemBuilder: (_, i) {
          if (i >= _posts.length) {
            if (_error != null) {
              return Center(child: IconButton(icon: const Icon(Icons.refresh), onPressed: _load));
            }
            WidgetsBinding.instance.addPostFrameCallback((_) => _load());
            return const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()));
          }
          return BooruTile(post: _posts[i], onTap: () => _open(_posts, i));
        },
      ),
    );
  }

  Widget _favourites(bool showNsfw) {
    final favs = store.favourites.where((p) => showNsfw || !p.isNsfw).toList();
    if (favs.isEmpty) {
      return _message(Icons.favorite_border, tr('Chưa có ảnh yêu thích. Mở ảnh và chạm ♥ để lưu.'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(6),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: store.columns,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 0.72,
      ),
      itemCount: favs.length,
      itemBuilder: (_, i) => BooruTile(post: favs[i], onTap: () => _open(favs, i)),
    );
  }

  Widget _historyTab() {
    final h = store.history;
    if (h.isEmpty) return _message(Icons.history, tr('Chưa có lịch sử tìm kiếm'));
    return ListView(children: [
      for (final q in h)
        ListTile(
          leading: const Icon(Icons.history),
          title: Text(q),
          onTap: () => _submit(q),
        ),
      const Divider(),
      ListTile(
        leading: const Icon(Icons.delete_sweep_outlined),
        title: Text(tr('Xoá lịch sử tìm kiếm')),
        onTap: store.clearHistory,
      ),
    ]);
  }

  Future<void> _solveCf() async {
    final s = _site;
    // same challenge page the extensions use; cf_clearance + UA are then
    // applied to every request to this host by MClient
    final ok = await YomiCf.solve('${s.baseUrl}/', () async => false);
    if (!ok) booruLog('Không vượt được Cloudflare', 'Cloudflare challenge not solved', site: s);
    await _reload();
  }

  Widget _message(IconData icon, String text, {bool retry = false, bool cloudflare = false}) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
            if (retry) ...[
              const SizedBox(height: 12),
              FilledButton.tonalIcon(onPressed: _reload, icon: const Icon(Icons.refresh), label: Text(tr('Thử lại'))),
            ],
            if (cloudflare) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _solveCf,
                icon: const Icon(Icons.shield_outlined),
                label: Text(tr('Vượt Cloudflare bằng WebView')),
              ),
            ],
          ]),
        ),
      );
}

class BooruTile extends StatelessWidget {
  const BooruTile({super.key, required this.post, required this.onTap});
  final BooruPost post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final site = BooruStore.instance.siteById(post.siteId);
    return Material(
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(10),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: onTap,
        child: Stack(fit: StackFit.expand, children: [
          cachedNetworkImage(
            imageUrl: post.previewUrl,
            headers: {
              'User-Agent': 'YomiHub/0.4.4 (Booru App)',
              if (site != null) 'Referer': '${site.baseUrl}/',
            },
            width: null,
            height: null,
            fit: BoxFit.cover,
            errorWidget: const Icon(Icons.broken_image_outlined),
          ),
          if (post.isVideo || post.isGif)
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                child: Text(post.isVideo ? '▶ ${post.ext.toUpperCase()}' : 'GIF',
                    style: const TextStyle(color: Colors.white, fontSize: 10)),
              ),
            ),
          if (BooruStore.instance.isFavourite(post))
            const Positioned(left: 4, top: 4, child: Icon(Icons.favorite, color: Colors.pinkAccent, size: 16)),
        ]),
      ),
    );
  }
}
