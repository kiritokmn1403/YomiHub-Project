/* Pure ES5 localStorage Manager for YumiHub Samsung TV */
(function (root) {
  'use strict';

  var KEYS = {
    library: 'yumihub_tv_library_v1',
    progress: 'yumihub_tv_progress_v1',
    settings: 'yumihub_tv_settings_v1'
  };

  function safeGet(key, fallback) {
    try {
      var raw = root.localStorage.getItem(key);
      if (!raw) return fallback;
      return JSON.parse(raw);
    } catch (e) {
      return fallback;
    }
  }

  function safeSet(key, val) {
    try {
      root.localStorage.setItem(key, JSON.stringify(val));
      return true;
    } catch (e) {
      return false;
    }
  }

  function getLibrary() {
    var data = safeGet(KEYS.library, null);
    if (!data || typeof data !== 'object') {
      return {
        sourceLabel: 'Chưa nạp',
        importedAt: 0,
        movies: [],
        categories: [],
        chapters: [],
        history: [],
        stats: { totalRawMovies: 0, filteredMovies: 0, ignoredOtherTypes: 0 }
      };
    }
    return data;
  }

  function saveLibrary(libData) {
    return safeSet(KEYS.library, libData);
  }

  function getProgressMap() {
    var map = safeGet(KEYS.progress, {});
    return map && typeof map === 'object' ? map : {};
  }

  function getEpisodeProgress(epKey) {
    if (!epKey) return null;
    var map = getProgressMap();
    return map.hasOwnProperty(epKey) ? map[epKey] : null;
  }

  function saveEpisodeProgress(epKey, timeSec, durationSec, completed) {
    if (!epKey) return null;
    var map = getProgressMap();
    var cleanTime = Math.max(0, Math.floor(Number(timeSec) || 0));
    var cleanDur = Math.max(0, Math.floor(Number(durationSec) || 0));
    var prev = map[epKey] || {};
    var isDone = Boolean(completed) || (cleanDur > 0 && cleanTime >= cleanDur - 2);
    map[epKey] = {
      timeSec: isDone && cleanDur > 0 ? cleanDur : cleanTime,
      durationSec: cleanDur || prev.durationSec || 0,
      completed: isDone,
      updatedAt: Date.now()
    };
    safeSet(KEYS.progress, map);
    return map[epKey];
  }

  function countSavedProgress() {
    var map = getProgressMap();
    return Object.keys(map).length;
  }

  function getSettings() {
    var s = safeGet(KEYS.settings, {});
    return {
      bridgeUrl: (s && s.bridgeUrl) ? String(s.bridgeUrl) : '',
      sortBy: (s && s.sortBy) ? String(s.sortBy) : 'recent'
    };
  }

  function saveSettings(partial) {
    var cur = getSettings();
    var k;
    for (k in partial) {
      if (partial.hasOwnProperty(k)) {
        cur[k] = partial[k];
      }
    }
    return safeSet(KEYS.settings, cur);
  }

  function clearAll() {
    try {
      root.localStorage.removeItem(KEYS.library);
      root.localStorage.removeItem(KEYS.progress);
    } catch (e) {}
  }

  root.YumiStorage = {
    KEYS: KEYS,
    getLibrary: getLibrary,
    saveLibrary: saveLibrary,
    getProgressMap: getProgressMap,
    getEpisodeProgress: getEpisodeProgress,
    saveEpisodeProgress: saveEpisodeProgress,
    countSavedProgress: countSavedProgress,
    getSettings: getSettings,
    saveSettings: saveSettings,
    clearAll: clearAll
  };
})(window);
