/* Pure ES5 YomiHub .backup Parser & Film/Movie Filter */
/* Reads YomiHub backup schema (backup.dart): filters ItemType.anime (itemType === 1) only */
(function (root) {
  'use strict';

  function isFilmItem(item) {
    if (!item || typeof item !== 'object') return false;
    return item.itemType === 1 || item.itemType === '1' || item.itemType === 'anime';
  }

  function isFilmCategory(cat) {
    if (!cat || typeof cat !== 'object') return false;
    if (typeof cat.forItemType !== 'undefined' && cat.forItemType !== null) {
      return cat.forItemType === 1 || cat.forItemType === '1' || cat.forItemType === 'anime';
    }
    if (typeof cat.forManga === 'boolean') {
      return cat.forManga === false;
    }
    return false;
  }

  function parseLastPageToSec(val) {
    if (val === null || typeof val === 'undefined' || val === '') return 0;
    var num = Number(val);
    if (!isFinite(num) || num <= 0) return 0;
    // Neu backup luu dang mili-giay (lon hon 86400), quy doi ve giay
    if (num > 86400) {
      return Math.floor(num / 1000);
    }
    return Math.floor(num);
  }

  function makeFallbackPoster(name) {
    return root.YumiSampleData.makePosterSvg(
      name || 'Phim YumiHub',
      'Đã nhập từ .backup',
      '#172554',
      '#3B1D63',
      'PHIM TV'
    );
  }

  function episodeKey(movieId, chapterId, idx) {
    return 'm_' + String(movieId) + '_ep_' + String(chapterId || idx);
  }

  function importObject(rawObj, sourceLabel) {
    if (!rawObj || typeof rawObj !== 'object') {
      throw new Error('Dữ liệu sao lưu không đúng định dạng JSON hợp lệ.');
    }

    var rawItems = Array.isArray(rawObj.manga) ? rawObj.manga : [];
    var rawCats = Array.isArray(rawObj.categories) ? rawObj.categories : [];
    var rawChapters = Array.isArray(rawObj.chapters) ? rawObj.chapters : [];
    var rawHistory = Array.isArray(rawObj.history) ? rawObj.history : [];

    var movies = [];
    var movieIdMap = {};
    var ignoredCount = 0;
    var i;

    for (i = 0; i < rawItems.length; i++) {
      var item = rawItems[i];
      if (!isFilmItem(item)) {
        ignoredCount++;
        continue;
      }
      var mid = item.id !== null && typeof item.id !== 'undefined' ? item.id : (i + 1);
      var cleanMovie = {
        id: mid,
        name: item.name || 'Không rõ tên phim',
        author: item.author || item.artist || item.source || 'YomiHub',
        status: typeof item.status === 'number' ? item.status : 0,
        itemType: 1,
        favorite: item.favorite !== false,
        source: item.source || 'YomiHub Backup',
        lang: item.lang || 'vi',
        genre: Array.isArray(item.genre) ? item.genre : [],
        categories: Array.isArray(item.categories) ? item.categories : [],
        imageUrl: (item.imageUrl && String(item.imageUrl).indexOf('http') === 0) || (item.imageUrl && String(item.imageUrl).indexOf('data:') === 0)
          ? item.imageUrl
          : makeFallbackPoster(item.name),
        description: item.description || 'Nhập từ bản sao lưu YomiHub (chỉ giữ Phim & Điện ảnh).',
        lastUpdate: item.lastUpdate || item.updatedAt || Date.now(),
        updatedAt: item.updatedAt || item.lastUpdate || Date.now()
      };
      movies.push(cleanMovie);
      movieIdMap[String(mid)] = cleanMovie;
    }

    var categories = [];
    for (i = 0; i < rawCats.length; i++) {
      if (isFilmCategory(rawCats[i])) {
        categories.push({
          id: rawCats[i].id,
          name: rawCats[i].name || 'Danh mục phim',
          pos: rawCats[i].pos || 0,
          forItemType: 1
        });
      }
    }

    var chapters = [];
    for (i = 0; i < rawChapters.length; i++) {
      var ch = rawChapters[i];
      if (!ch || !movieIdMap.hasOwnProperty(String(ch.mangaId))) continue;
      var epUrl = (ch.url && (String(ch.url).indexOf('http') === 0 || String(ch.url).indexOf('assets/') === 0))
        ? ch.url
        : 'assets/sample_trailer.webm';
      var ep = {
        id: ch.id !== null && typeof ch.id !== 'undefined' ? ch.id : (i + 1),
        mangaId: ch.mangaId,
        name: ch.name || ('Tập ' + (i + 1)),
        url: epUrl,
        dateUpload: ch.dateUpload || String(Date.now()),
        duration: ch.duration || '00:10',
        isRead: Boolean(ch.isRead),
        lastPageRead: ch.lastPageRead || '0',
        updatedAt: ch.updatedAt || 0
      };
      chapters.push(ep);

      var epKey = episodeKey(ep.mangaId, ep.id, i);
      var sec = parseLastPageToSec(ep.lastPageRead);
      if ((sec > 0 || ep.isRead) && !root.YumiStorage.getEpisodeProgress(epKey)) {
        root.YumiStorage.saveEpisodeProgress(epKey, sec, ep.isRead ? Math.max(sec, 10) : 10, ep.isRead);
      }
    }

    var history = [];
    for (i = 0; i < rawHistory.length; i++) {
      var h = rawHistory[i];
      if (!h) continue;
      if (isFilmItem(h) || movieIdMap.hasOwnProperty(String(h.mangaId))) {
        history.push({
          id: h.id,
          mangaId: h.mangaId,
          chapterId: h.chapterId,
          date: h.date || String(Date.now()),
          readingTimeSeconds: h.readingTimeSeconds || 0,
          itemType: 1
        });
      }
    }

    var result = {
      sourceLabel: sourceLabel || 'Tệp .backup YomiHub',
      importedAt: Date.now(),
      movies: movies,
      categories: categories,
      chapters: chapters,
      history: history,
      stats: {
        totalRawMovies: rawItems.length,
        filteredMovies: movies.length,
        ignoredOtherTypes: ignoredCount
      }
    };

    root.YumiStorage.saveLibrary(result);
    return result;
  }

  function importFile(file, onSuccess, onError) {
    if (!file) {
      onError('Chưa chọn tệp sao lưu.');
      return;
    }
    var reader = new FileReader();
    reader.onload = function (ev) {
      try {
        var jsonText = root.YumiArchive.extractJsonText(ev.target.result);
        var parsed = JSON.parse(jsonText);
        var res = importObject(parsed, file.name);
        onSuccess(res);
      } catch (err) {
        onError(err && err.message ? err.message : String(err));
      }
    };
    reader.onerror = function () {
      onError('Không thể đọc tệp từ bộ nhớ thiết bị.');
    };
    reader.readAsArrayBuffer(file);
  }

  root.YumiBackup = {
    isFilmItem: isFilmItem,
    isFilmCategory: isFilmCategory,
    episodeKey: episodeKey,
    importObject: importObject,
    importFile: importFile
  };
})(window);
