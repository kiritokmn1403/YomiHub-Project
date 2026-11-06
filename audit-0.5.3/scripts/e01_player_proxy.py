import sys,os; sys.path.insert(0,os.path.expanduser('~/mnt/A.I Project - YomiHub Project/YomiHub-Project/audit-0.5.3')); from edit import edit
F='lib/yomihub/player/yomi_shorts.dart'
edit(F,"import 'package:mangayomi/yomihub/player/sponsorblock.dart';\n","import 'package:mangayomi/yomihub/player/sponsorblock.dart';\nimport 'package:mangayomi/yomihub/player/player_net.dart';\n")
edit(F,"""    final p = _players[slot];
    await p.open(Media(v.url, httpHeaders: YomiSponsorBlock.clean(v.headers)), play: false);""","""    final p = _players[slot];
    // 0.5.3: same network route (Tor / Mihon Proxy / custom proxy) as the
    // extension that produced the URL – tokenised CDN links failed otherwise
    await YomiPlayerNet.apply(p, widget.source.id, url: v.url);
    if (_loaded[slot] != index || !mounted) return;
    await p.open(Media(v.url, httpHeaders: YomiSponsorBlock.clean(v.headers)), play: false);""")
# errors emitted after the screen closed (players disposed while opening) are not real failures
edit(F,"""        if (e.trim().isEmpty) return;
        AppLogger.logOnce('shorts-err:${widget.source.id}:$e'""","""        if (e.trim().isEmpty || !mounted) return;
        AppLogger.logOnce('shorts-err:${widget.source.id}:$e'""")
G='lib/modules/anime/anime_player_view.dart'
s=open(os.path.expanduser('~/mnt/A.I Project - YomiHub Project/YomiHub-Project/overlay/'+G),encoding='utf-8').read()
imp=s.split('\n')[0]
edit(G,imp+'\n',imp+"\nimport 'package:mangayomi/yomihub/player/player_net.dart';\n")
edit(G,"""    await _player.open(
      playbackMedia(
        prefs.videoTrack!.id,""","""    // 0.5.3: play through the same route (Tor / Mihon Proxy / custom proxy)
    // as the source's requests – CDN tokens are often tied to that IP.
    if (!widget.isLocal) {
      await YomiPlayerNet.apply(
        _player,
        widget.episode.manga.value?.sourceId,
        url: prefs.videoTrack!.id,
      );
    }
    await _player.open(
      playbackMedia(
        prefs.videoTrack!.id,""")
