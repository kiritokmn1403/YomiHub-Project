/* Pure ES5 Video Player with HTML5 + Safe Samsung TV webapis.avplay Adapter */
(function (root) {
  'use strict';

  function formatTime(seconds) {
    var s = Math.max(0, Math.floor(Number(seconds) || 0));
    var mins = Math.floor(s / 60);
    var secs = s % 60;
    var mStr = mins < 10 ? ('0' + mins) : String(mins);
    var sStr = secs < 10 ? ('0' + secs) : String(secs);
    return mStr + ':' + sStr;
  }

  function ensureWebapisLoaded() {
    try {
      if (typeof root.tizen !== 'undefined' && typeof root.webapis === 'undefined') {
        if (!document.getElementById('tizen-webapis-script')) {
          var sc = document.createElement('script');
          sc.id = 'tizen-webapis-script';
          sc.src = '$WEBAPIS/webapis/webapis.js';
          document.head.appendChild(sc);
        }
      }
    } catch (e) {}
  }

  function hasAvplay() {
    try {
      return typeof root.webapis !== 'undefined' &&
        root.webapis &&
        typeof root.webapis.avplay !== 'undefined';
    } catch (e) {
      return false;
    }
  }

  var state = {
    isOpen: false,
    movie: null,
    episodes: [],
    epIndex: 0,
    epKey: '',
    engine: 'HTML5',
    lastSaveTick: 0,
    osdTimer: null,
    videoEl: null,
    onCloseCallback: null,
    onToast: null
  };

  function getEl(id) {
    return document.getElementById(id);
  }

  function notify(msg) {
    if (typeof state.onToast === 'function') {
      state.onToast(msg);
    }
  }

  function showOsd() {
    var osd = getEl('player-osd');
    if (!osd) return;
    osd.className = 'player-osd';
    if (state.osdTimer) {
      clearTimeout(state.osdTimer);
    }
    state.osdTimer = setTimeout(function () {
      if (state.isOpen && state.videoEl && !state.videoEl.paused) {
        osd.className = 'player-osd is-idle';
      }
    }, 4500);
  }

  function updateHud() {
    var v = state.videoEl;
    if (!v) return;
    var cur = Number(v.currentTime) || 0;
    var dur = (isFinite(v.duration) && v.duration > 0) ? v.duration : 10;
    var pct = Math.min(100, Math.max(0, (cur / dur) * 100));

    var curEl = getEl('player-time-current');
    var totEl = getEl('player-time-total');
    var fillEl = getEl('player-seek-fill');
    var playBtn = getEl('btn-player-play');

    if (curEl) curEl.textContent = formatTime(cur);
    if (totEl) totEl.textContent = formatTime(dur);
    if (fillEl) fillEl.style.width = pct.toFixed(1) + '%';
    if (playBtn) {
      playBtn.innerHTML = v.paused ? '&#9654; Phát' : '&#10074;&#10074; Tạm dừng';
    }
  }

  function persistPosition(force, completed) {
    if (!state.epKey || !state.videoEl) return;
    var now = Date.now();
    if (!force && (now - state.lastSaveTick) < 1000) return;
    state.lastSaveTick = now;

    var cur = Number(state.videoEl.currentTime) || 0;
    var dur = (isFinite(state.videoEl.duration) && state.videoEl.duration > 0) ? state.videoEl.duration : 10;
    var saved = root.YumiStorage.saveEpisodeProgress(state.epKey, cur, dur, Boolean(completed));
    var badge = getEl('player-saved-badge');
    if (badge && saved) {
      badge.textContent = 'Đã lưu: ' + formatTime(saved.timeSec);
    }
  }

  function tryAvplayOpen(url, resumeSec) {
    if (!hasAvplay()) return false;
    try {
      var av = root.webapis.avplay;
      try { av.close(); } catch (e0) {}
      av.open(url);
      av.setDisplayRect(0, 0, 1920, 1080);
      av.prepareAsync(function () {
        try {
          if (resumeSec > 0) {
            av.seekTo(resumeSec * 1000);
          }
          av.play();
        } catch (e2) {}
      }, function () {});
      return true;
    } catch (e) {
      return false;
    }
  }

  function tryAvplayClose() {
    if (!hasAvplay()) return;
    try {
      root.webapis.avplay.stop();
      root.webapis.avplay.close();
    } catch (e) {}
  }

  function bindVideoEvents() {
    var v = getEl('tv-video');
    if (!v || state.videoEl === v) return;
    state.videoEl = v;

    v.addEventListener('loadedmetadata', function () {
      var saved = root.YumiStorage.getEpisodeProgress(state.epKey);
      if (saved && saved.timeSec > 0 && !saved.completed) {
        var maxSeek = (isFinite(v.duration) && v.duration > 1) ? (v.duration - 0.5) : saved.timeSec;
        var target = Math.min(saved.timeSec, maxSeek);
        try { v.currentTime = target; } catch (e) {}
        notify('Tiếp tục phát từ ' + formatTime(target));
      }
      updateHud();
    });

    v.addEventListener('timeupdate', function () {
      updateHud();
      persistPosition(false, false);
    });

    v.addEventListener('pause', function () {
      updateHud();
      persistPosition(true, false);
      showOsd();
    });

    v.addEventListener('play', function () {
      updateHud();
      showOsd();
    });

    v.addEventListener('ended', function () {
      persistPosition(true, true);
      updateHud();
      showOsd();
      notify('Đã xem xong tập này');
    });
  }

  function open(movie, episodes, epIndex, onClose, onToast) {
    ensureWebapisLoaded();
    bindVideoEvents();
    state.movie = movie;
    state.episodes = episodes || [];
    state.epIndex = Math.max(0, Math.min(epIndex || 0, state.episodes.length - 1));
    state.onCloseCallback = onClose || null;
    state.onToast = onToast || null;

    var ep = state.episodes[state.epIndex];
    if (!ep) return;

    state.epKey = root.YumiBackup.episodeKey(movie.id, ep.id, state.epIndex);
    var saved = root.YumiStorage.getEpisodeProgress(state.epKey);
    var resumeSec = (saved && saved.timeSec > 0 && !saved.completed) ? saved.timeSec : 0;

    var overlay = getEl('view-player');
    if (overlay) overlay.className = 'player-overlay';
    state.isOpen = true;

    var mTitle = getEl('player-movie-title');
    var eTitle = getEl('player-ep-title');
    var engBadge = getEl('player-engine-badge');
    var savedBadge = getEl('player-saved-badge');

    if (mTitle) mTitle.textContent = movie.name || 'Phim';
    if (eTitle) eTitle.textContent = ep.name || ('Tập ' + (state.epIndex + 1));
    if (savedBadge) {
      savedBadge.textContent = resumeSec > 0 ? ('Khôi phục: ' + formatTime(resumeSec)) : 'Chưa lưu vị trí';
    }

    var streamUrl = ep.url || 'assets/sample_trailer.webm';
    // Thu dung Samsung webapis.avplay khi chay tren TV that; fallback sang HTML5 <video>
    var usedAvplay = tryAvplayOpen(streamUrl, resumeSec);
    state.engine = usedAvplay ? 'Samsung AVPlay' : 'HTML5 Video';
    if (engBadge) engBadge.textContent = state.engine;

    if (!usedAvplay && state.videoEl) {
      state.videoEl.src = streamUrl;
      state.videoEl.load();
      var playPromise = null;
      try {
        playPromise = state.videoEl.play();
      } catch (e) {}
      if (playPromise && typeof playPromise.catch === 'function') {
        playPromise.catch(function () {});
      }
    }

    updateHud();
    showOsd();
  }

  function togglePlay() {
    if (!state.isOpen) return;
    showOsd();
    if (state.engine === 'Samsung AVPlay' && hasAvplay()) {
      try {
        var st = root.webapis.avplay.getState();
        if (st === 'PLAYING') root.webapis.avplay.pause();
        else root.webapis.avplay.play();
      } catch (e) {}
      return;
    }
    if (!state.videoEl) return;
    if (state.videoEl.paused) {
      var p = null;
      try { p = state.videoEl.play(); } catch (e1) {}
      if (p && typeof p.catch === 'function') p.catch(function () {});
    } else {
      state.videoEl.pause();
    }
    updateHud();
  }

  function seekBy(deltaSec) {
    if (!state.isOpen) return;
    showOsd();
    if (!state.videoEl) return;
    var dur = (isFinite(state.videoEl.duration) && state.videoEl.duration > 0) ? state.videoEl.duration : 10;
    var next = Math.max(0, Math.min(dur - 0.2, (Number(state.videoEl.currentTime) || 0) + deltaSec));
    try {
      state.videoEl.currentTime = next;
    } catch (e) {}
    persistPosition(true, false);
    updateHud();
  }

  function setTimeAndSave(sec) {
    if (!state.isOpen || !state.videoEl) return;
    var dur = (isFinite(state.videoEl.duration) && state.videoEl.duration > 0) ? state.videoEl.duration : 10;
    var next = Math.max(0, Math.min(dur, Number(sec) || 0));
    try { state.videoEl.currentTime = next; } catch (e) {}
    persistPosition(true, false);
    updateHud();
  }

  function stepEpisode(delta) {
    if (!state.isOpen || !state.episodes.length) return;
    var nextIdx = state.epIndex + delta;
    if (nextIdx < 0 || nextIdx >= state.episodes.length) {
      notify(delta < 0 ? 'Đây là tập đầu tiên.' : 'Đây là tập cuối cùng.');
      return;
    }
    persistPosition(true, false);
    open(state.movie, state.episodes, nextIdx, state.onCloseCallback, state.onToast);
  }

  function close() {
    if (!state.isOpen) return;
    persistPosition(true, false);
    if (state.osdTimer) clearTimeout(state.osdTimer);
    tryAvplayClose();
    if (state.videoEl) {
      try {
        state.videoEl.pause();
        state.videoEl.removeAttribute('src');
        state.videoEl.load();
      } catch (e) {}
    }
    var overlay = getEl('view-player');
    if (overlay) overlay.className = 'player-overlay is-hidden';
    state.isOpen = false;
    if (typeof state.onCloseCallback === 'function') {
      state.onCloseCallback();
    }
  }

  function isOpen() {
    return state.isOpen;
  }

  root.YumiPlayer = {
    open: open,
    close: close,
    isOpen: isOpen,
    togglePlay: togglePlay,
    seekBy: seekBy,
    setTimeAndSave: setTimeAndSave,
    stepEpisode: stepEpisode,
    showOsd: showOsd,
    formatTime: formatTime
  };
})(window);
