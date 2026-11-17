import io,sys
def edit(p,pairs):
    s=io.open(p,encoding='utf-8',newline='').read(); c='\r\n' in s; s=s.replace('\r\n','\n')
    for a,b in pairs:
        if s.count(a)!=1: sys.exit('MISMATCH %s %d %r'%(p,s.count(a),a[:60]))
        s=s.replace(a,b)
    if c: s=s.replace('\n','\r\n')
    io.open(p,'w',encoding='utf-8',newline='').write(s)
edit('overlay/lib/yomihub/player/resume_policy.dart',[
('''    Duration stable = Duration.zero,
    double rate = 1.0,
  }) {
    final diff = position - target;
    final ahead = tolerance +
        Duration(milliseconds: (stable.inMilliseconds * (rate <= 0 ? 1.0 : rate)).round());''',
'''    Duration stable = Duration.zero,
    double rate = 1.0,
    Duration sinceSeek = Duration.zero,
  }) {
    final diff = position - target;
    // 0.5.7 (P8F): playback keeps running after a seek. On the Note 9 a seek
    // finished at once, the next check came 2.5 s later, the position was
    // target + 2.5 s (> tolerance) and the resume seeked again - 8 times in
    // 20 s, each one flushing the decoder (black screen + spinner). The time
    // since the last seek is therefore allowed on top of the tolerance.
    final run = stable > sinceSeek ? stable : sinceSeek;
    final ahead = tolerance +
        Duration(milliseconds: (run.inMilliseconds * (rate <= 0 ? 1.0 : rate)).round());'''),
('''    int maxTries = 8,
    bool expired = false,
  }) {
    if (target <= Duration.zero) return ResumeStep.confirmed;
    if (isNear(target: target, position: position, stable: stable, rate: rate)) {''',
'''    int maxTries = 8,
    bool expired = false,
    Duration sinceSeek = Duration.zero,
  }) {
    if (target <= Duration.zero) return ResumeStep.confirmed;
    if (isNear(
      target: target,
      position: position,
      stable: stable,
      rate: rate,
      sinceSeek: sinceSeek,
    )) {'''),
])
edit('overlay/lib/yomihub/player/yomi_pip.dart',[
('''  static Future<void> open() async {''',
'''  /// 0.5.7 (P8F): Back turns into Picture-in-Picture only while a picture
  /// is really playing. A video that is still loading / re-buffering (or has
  /// no frame yet) made a black PiP window and dropped the user on the
  /// launcher; Back now simply returns to the previous screen then.
  static bool pipOnBack({
    required bool playing,
    required bool buffering,
    required int? width,
    required int? height,
  }) =>
      playing && !buffering && (width ?? 0) > 0 && (height ?? 0) > 0;

  static Future<void> open() async {'''),
])
edit('overlay/lib/modules/anime/anime_player_view.dart',[
('''            if (backPip) {
              if (_player.state.playing) {
                _enterPip();''',
'''            if (backPip) {
              final st = _player.state;
              if (YomiPip.pipOnBack(
                playing: st.playing,
                buffering: st.buffering,
                width: st.width,
                height: st.height,
              )) {
                _enterPip();'''),
('''        tries: tries,
        expired: now.isAfter(hardLimit) || (tries > 0 && now.isAfter(until)),
      );''',
'''        tries: tries,
        expired: now.isAfter(hardLimit) || (tries > 0 && now.isAfter(until)),
        sinceSeek: tries > 0 ? now.difference(baselineAt) : Duration.zero,
      );'''),
('''          position: st.position,
          stable: stable,
          rate: st.rate,
        )) {
          reached = true;''',
'''          position: st.position,
          stable: stable,
          rate: st.rate,
          sinceSeek: tries > 0 ? now.difference(baselineAt) : Duration.zero,
        )) {
          reached = true;'''),
])
print('ok')
