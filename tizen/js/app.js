/* Pure ES5 Main App Controller for YumiHub Samsung TV */
(function (root) {
  'use strict';

  var NAV_TITLES = {
    library: 'Thư viện Phim & Điện ảnh',
    updates: 'Cập nhật mới nhất',
    browse: 'Duyệt Phim & Điện ảnh',
    more: 'Thêm & Nhập sao lưu'
  };

  var state = {
    tab: 'library',
    selectedCatId: 'all',
    selectedBrowseGenre: 'Tất cả',
    sortBy: 'recent',
    activeMovie: null,
    returnTab: 'library',
    library: null,
    browseCatalog: []
  };

  function el(id) {
    return document.getElementById(id);
  }

  function escapeHtml(str) {
    return String(str === null || typeof str === 'undefined' ? '' : str)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  var toastTimer = null;
  function showToast(msg) {
    var t = el('toast');
    if (!t) return;
    t.textContent = msg;
    t.className = 'toast';
    if (toastTimer) clearTimeout(toastTimer);
    toastTimer = setTimeout(function () {
      t.className = 'toast is-hidden';
    }, 3200);
  }

  function reloadFromStorage() {
    state.library = root.YumiStorage.getLibrary();
    var settings = root.YumiStorage.getSettings();
    state.sortBy = settings.sortBy || 'recent';
    var bridgeInput = el('bridge-url-input');
    if (bridgeInput) bridgeInput.value = settings.bridgeUrl || '';
    var badge = el('browse-bridge-badge');
    if (badge) {
      badge.textContent = settings.bridgeUrl
        ? ('Cầu nối LAN: ' + settings.bridgeUrl)
        : 'Nguồn mẫu cục bộ';
    }
  }

  function getEpisodesForMovie(movieId) {
    var list = [];
    var chapters = (state.library && state.library.chapters) ? state.library.chapters : [];
    var i;
    for (i = 0; i < chapters.length; i++) {
      if (String(chapters[i].mangaId) === String(movieId)) {
        list.push(chapters[i]);
      }
    }
    if (!list.length && state.activeMovie && Array.isArray(state.activeMovie.episodes)) {
      return state.activeMovie.episodes;
    }
    return list;
  }

  function getMovieResumeSummary(movieId) {
    var eps = getEpisodesForMovie(movieId);
    var i;
    var bestSec = 0;
    var bestDur = 0;
    var watchedCount = 0;
    var resumeEpIdx = 0;

    for (i = 0; i < eps.length; i++) {
      var k = root.YumiBackup.episodeKey(movieId, eps[i].id, i);
      var p = root.YumiStorage.getEpisodeProgress(k);
      if (p && p.completed) {
        watchedCount++;
      } else if (p && p.timeSec > 0 && bestSec === 0) {
        bestSec = p.timeSec;
        bestDur = p.durationSec || 10;
        resumeEpIdx = i;
      }
    }
    return {
      totalEps: eps.length,
      watchedCount: watchedCount,
      resumeSec: bestSec,
      resumeDur: bestDur,
      resumeEpIdx: resumeEpIdx
    };
  }

  function setVisibleView(viewName) {
    var views = ['library', 'updates', 'browse', 'more', 'detail'];
    var i;
    for (i = 0; i < views.length; i++) {
      var panel = el('view-' + views[i]);
      if (!panel) continue;
      panel.className = (views[i] === viewName) ? 'view-panel' : 'view-panel is-hidden';
    }
  }

  function updateSidebarActive() {
    var navBtns = document.querySelectorAll('.nav-item');
    var i;
    for (i = 0; i < navBtns.length; i++) {
      var nav = navBtns[i].getAttribute('data-nav');
      var cls = 'nav-item focusable';
      if (nav === state.tab) cls += ' is-active';
      navBtns[i].className = cls;
    }
  }

  function renderLibrary() {
    var lib = state.library;
    var movies = lib && Array.isArray(lib.movies) ? lib.movies.slice(0) : [];
    var cats = lib && Array.isArray(lib.categories) ? lib.categories : [];

    var catRow = el('library-categories');
    var grid = el('library-grid');
    var emptyBox = el('library-empty');
    var sortBtn = el('btn-sort-toggle');
    var countEl = el('page-count');

    if (sortBtn) {
      sortBtn.textContent = state.sortBy === 'alpha' ? 'Sắp xếp: Tên A-Z' : 'Sắp xếp: Mới cập nhật';
    }

    // Filter chips
    var chipsHtml = '';
    chipsHtml += '<button type="button" class="chip-btn focusable' + (state.selectedCatId === 'all' ? ' is-active' : '') + '" data-focusable="true" data-zone="toolbar" data-cat="all">Tất cả (' + movies.length + ')</button>';
    chipsHtml += '<button type="button" class="chip-btn focusable' + (state.selectedCatId === 'resuming' ? ' is-active' : '') + '" data-focusable="true" data-zone="toolbar" data-cat="resuming">Đang xem dở</button>';
    var i;
    for (i = 0; i < cats.length; i++) {
      var cId = String(cats[i].id);
      chipsHtml += '<button type="button" class="chip-btn focusable' + (state.selectedCatId === cId ? ' is-active' : '') + '" data-focusable="true" data-zone="toolbar" data-cat="' + escapeHtml(cId) + '">' + escapeHtml(cats[i].name) + '</button>';
    }
    if (catRow) {
      catRow.innerHTML = chipsHtml;
      var chipBtns = catRow.querySelectorAll('.chip-btn');
      for (i = 0; i < chipBtns.length; i++) {
        (function (btn) {
          btn.addEventListener('click', function () {
            state.selectedCatId = btn.getAttribute('data-cat');
            renderLibrary();
          });
        })(chipBtns[i]);
      }
    }

    // Apply category filter
    var filtered = [];
    for (i = 0; i < movies.length; i++) {
      var m = movies[i];
      if (state.selectedCatId === 'all') {
        filtered.push(m);
      } else if (state.selectedCatId === 'resuming') {
        var sum = getMovieResumeSummary(m.id);
        if (sum.resumeSec > 0) filtered.push(m);
      } else {
        var mCats = Array.isArray(m.categories) ? m.categories : [];
        var j;
        var matched = false;
        for (j = 0; j < mCats.length; j++) {
          if (String(mCats[j]) === state.selectedCatId) {
            matched = true;
            break;
          }
        }
        if (matched) filtered.push(m);
      }
    }

    // Apply sort
    filtered.sort(function (a, b) {
      if (state.sortBy === 'alpha') {
        return String(a.name || '').localeCompare(String(b.name || ''));
      }
      return (b.lastUpdate || 0) - (a.lastUpdate || 0);
    });

    if (countEl) countEl.textContent = filtered.length + ' bộ phim';

    if (!movies.length) {
      if (grid) grid.innerHTML = '';
      if (emptyBox) emptyBox.className = 'empty-state';
      return;
    }

    if (emptyBox) emptyBox.className = 'empty-state is-hidden';

    var html = '';
    for (i = 0; i < filtered.length; i++) {
      var item = filtered[i];
      var s = getMovieResumeSummary(item.id);
      var pct = s.resumeSec > 0 && s.resumeDur > 0
        ? Math.min(100, Math.round((s.resumeSec / s.resumeDur) * 100))
        : (s.watchedCount > 0 && s.watchedCount === s.totalEps ? 100 : 0);

      html += '<div class="movie-card-wrap">';
      html += '<button type="button" class="movie-card focusable" data-focusable="true" data-zone="content" data-movie-id="' + escapeHtml(item.id) + '">';
      html += '<div class="movie-poster-box">';
      html += '<img class="movie-poster-img" src="' + escapeHtml(item.imageUrl) + '" alt="' + escapeHtml(item.name) + '">';
      html += '<span class="movie-badge-ep">' + s.totalEps + ' tập</span>';
      if (s.resumeSec > 0) {
        html += '<span class="movie-badge-resume">Tiếp ' + root.YumiPlayer.formatTime(s.resumeSec) + '</span>';
      }
      if (pct > 0) {
        html += '<div class="movie-progress-bar"><div class="movie-progress-fill" style="width:' + pct + '%"></div></div>';
      }
      html += '</div>';
      html += '<div class="movie-card-body">';
      html += '<div class="movie-card-title">' + escapeHtml(item.name) + '</div>';
      html += '<div class="movie-card-meta">' + escapeHtml(item.author || item.source || 'Phim & Điện ảnh') + '</div>';
      html += '</div>';
      html += '</button>';
      html += '</div>';
    }

    if (grid) {
      grid.innerHTML = html;
      var cards = grid.querySelectorAll('.movie-card');
      for (i = 0; i < cards.length; i++) {
        (function (card) {
          card.addEventListener('click', function () {
            openMovieById(card.getAttribute('data-movie-id'), 'library');
          });
        })(cards[i]);
      }
    }
  }

  function renderUpdates() {
    var lib = state.library;
    var movies = lib && Array.isArray(lib.movies) ? lib.movies : [];
    var chapters = lib && Array.isArray(lib.chapters) ? lib.chapters.slice(0) : [];
    var movieMap = {};
    var i;
    for (i = 0; i < movies.length; i++) {
      movieMap[String(movies[i].id)] = movies[i];
    }

    chapters.sort(function (a, b) {
      return Number(b.dateUpload || 0) - Number(a.dateUpload || 0);
    });

    var listEl = el('updates-list');
    var countEl = el('page-count');
    if (countEl) countEl.textContent = chapters.length + ' tập mới';

    if (!chapters.length) {
      if (listEl) {
        listEl.innerHTML = '<div class="empty-state"><h3>Chưa có tập phim cập nhật</h3><p>Hãy nạp dữ liệu mẫu hoặc nhập tệp <code>.backup</code> ở mục Thêm.</p></div>';
      }
      return;
    }

    var html = '';
    for (i = 0; i < chapters.length; i++) {
      var ch = chapters[i];
      var mv = movieMap[String(ch.mangaId)];
      if (!mv) continue;
      var epKey = root.YumiBackup.episodeKey(mv.id, ch.id, i);
      var prog = root.YumiStorage.getEpisodeProgress(epKey);
      var pill = 'Mới · ' + escapeHtml(ch.duration || '00:10');
      if (prog && prog.completed) pill = 'Đã xem';
      else if (prog && prog.timeSec > 0) pill = 'Xem tiếp ' + root.YumiPlayer.formatTime(prog.timeSec);

      var dt = new Date(Number(ch.dateUpload) || Date.now());
      var dtText = dt.getDate() + '/' + (dt.getMonth() + 1) + '/' + dt.getFullYear();

      html += '<button type="button" class="update-row focusable" data-focusable="true" data-zone="content" data-movie-id="' + escapeHtml(mv.id) + '" data-chap-id="' + escapeHtml(ch.id) + '">';
      html += '<img class="update-thumb" src="' + escapeHtml(mv.imageUrl) + '" alt="">';
      html += '<div class="update-info">';
      html += '<div class="update-movie">' + escapeHtml(mv.name) + '</div>';
      html += '<div class="update-ep">' + escapeHtml(ch.name) + '</div>';
      html += '<div class="update-date">Cập nhật: ' + escapeHtml(dtText) + ' · ' + escapeHtml(mv.source || 'YumiHub') + '</div>';
      html += '</div>';
      html += '<span class="update-pill">' + pill + '</span>';
      html += '</button>';
    }

    if (listEl) {
      listEl.innerHTML = html;
      var rows = listEl.querySelectorAll('.update-row');
      for (i = 0; i < rows.length; i++) {
        (function (row) {
          row.addEventListener('click', function () {
            openMovieById(row.getAttribute('data-movie-id'), 'updates');
          });
        })(rows[i]);
      }
    }
  }

  function renderBrowse() {
    var catalog = state.browseCatalog;
    var genresMap = { 'Tất cả': true };
    var i;
    var j;
    for (i = 0; i < catalog.length; i++) {
      var gs = catalog[i].genre || [];
      for (j = 0; j < gs.length; j++) genresMap[gs[j]] = true;
    }

    var genreNames = Object.keys(genresMap);
    var gHtml = '';
    for (i = 0; i < genreNames.length; i++) {
      var g = genreNames[i];
      gHtml += '<button type="button" class="chip-btn focusable' + (state.selectedBrowseGenre === g ? ' is-active' : '') + '" data-focusable="true" data-zone="toolbar" data-genre="' + escapeHtml(g) + '">' + escapeHtml(g) + '</button>';
    }
    var gRow = el('browse-genres');
    if (gRow) {
      gRow.innerHTML = gHtml;
      var btns = gRow.querySelectorAll('.chip-btn');
      for (i = 0; i < btns.length; i++) {
        (function (btn) {
          btn.addEventListener('click', function () {
            state.selectedBrowseGenre = btn.getAttribute('data-genre');
            renderBrowse();
          });
        })(btns[i]);
      }
    }

    var filtered = [];
    for (i = 0; i < catalog.length; i++) {
      var item = catalog[i];
      if (state.selectedBrowseGenre === 'Tất cả' || (item.genre && item.genre.indexOf(state.selectedBrowseGenre) !== -1)) {
        filtered.push(item);
      }
    }

    var countEl = el('page-count');
    if (countEl) countEl.textContent = filtered.length + ' đề xuất';

    var grid = el('browse-grid');
    var html = '';
    for (i = 0; i < filtered.length; i++) {
      var m = filtered[i];
      html += '<div class="movie-card-wrap">';
      html += '<button type="button" class="movie-card focusable" data-focusable="true" data-zone="content" data-browse-id="' + escapeHtml(m.id) + '">';
      html += '<div class="movie-poster-box">';
      html += '<img class="movie-poster-img" src="' + escapeHtml(m.imageUrl) + '" alt="' + escapeHtml(m.name) + '">';
      html += '<span class="movie-badge-ep">' + (m.episodes ? m.episodes.length : 1) + ' tập</span>';
      html += '</div>';
      html += '<div class="movie-card-body">';
      html += '<div class="movie-card-title">' + escapeHtml(m.name) + '</div>';
      html += '<div class="movie-card-meta">' + escapeHtml((m.genre || []).join(' · ')) + '</div>';
      html += '</div>';
      html += '</button>';
      html += '</div>';
    }
    if (grid) {
      grid.innerHTML = html;
      var cards = grid.querySelectorAll('.movie-card');
      for (i = 0; i < cards.length; i++) {
        (function (card) {
          card.addEventListener('click', function () {
            var bid = card.getAttribute('data-browse-id');
            var k;
            for (k = 0; k < catalog.length; k++) {
              if (String(catalog[k].id) === String(bid)) {
                openDetail(catalog[k], 'browse');
                break;
              }
            }
          });
        })(cards[i]);
      }
    }
  }

  function renderMoreStats() {
    var lib = state.library;
    var stats = (lib && lib.stats) ? lib.stats : { totalRawMovies: 0, filteredMovies: 0, ignoredOtherTypes: 0 };
    var savedCount = root.YumiStorage.countSavedProgress();
    var box = el('library-stats-grid');
    if (!box) return;

    var cards = [
      { val: lib && lib.movies ? lib.movies.length : 0, lbl: 'Phim & Điện ảnh trong thư viện' },
      { val: lib && lib.chapters ? lib.chapters.length : 0, lbl: 'Tập phim đã nạp' },
      { val: savedCount, lbl: 'Vị trí xem đã nhớ (localStorage)' },
      { val: stats.ignoredOtherTypes || 0, lbl: 'Mục khác loại đã tự động lọc bỏ' }
    ];
    var html = '';
    var i;
    for (i = 0; i < cards.length; i++) {
      html += '<div class="stat-box"><div class="stat-inner">';
      html += '<div class="stat-val">' + cards[i].val + '</div>';
      html += '<div class="stat-lbl">' + escapeHtml(cards[i].lbl) + '</div>';
      html += '</div></div>';
    }
    box.innerHTML = html;
  }

  function renderMore() {
    var countEl = el('page-count');
    if (countEl) countEl.textContent = 'Nhập .backup & Cài đặt';
    renderMoreStats();
  }

  function openMovieById(movieId, returnTab) {
    var movies = (state.library && state.library.movies) ? state.library.movies : [];
    var i;
    for (i = 0; i < movies.length; i++) {
      if (String(movies[i].id) === String(movieId)) {
        openDetail(movies[i], returnTab);
        return;
      }
    }
  }

  function isMovieInLibrary(movieId) {
    var movies = (state.library && state.library.movies) ? state.library.movies : [];
    var i;
    for (i = 0; i < movies.length; i++) {
      if (String(movies[i].id) === String(movieId)) return true;
    }
    return false;
  }

  function toggleMovieInLibrary(movie) {
    if (!state.library) reloadFromStorage();
    var movies = state.library.movies || [];
    var chapters = state.library.chapters || [];
    var idx = -1;
    var i;
    for (i = 0; i < movies.length; i++) {
      if (String(movies[i].id) === String(movie.id)) {
        idx = i;
        break;
      }
    }
    if (idx !== -1) {
      movies.splice(idx, 1);
      showToast('Đã xóa "' + movie.name + '" khỏi Thư viện');
    } else {
      var copy = {
        id: movie.id,
        name: movie.name,
        author: movie.author,
        status: movie.status || 0,
        itemType: 1,
        favorite: true,
        source: movie.source || 'Duyệt TV',
        genre: movie.genre || [],
        categories: movie.categories || [],
        imageUrl: movie.imageUrl,
        description: movie.description,
        lastUpdate: Date.now(),
        updatedAt: Date.now()
      };
      movies.unshift(copy);
      var eps = movie.episodes || [];
      for (i = 0; i < eps.length; i++) {
        chapters.push(eps[i]);
      }
      showToast('Đã thêm "' + movie.name + '" vào Thư viện');
    }
    state.library.movies = movies;
    state.library.chapters = chapters;
    root.YumiStorage.saveLibrary(state.library);
    openDetail(movie, state.returnTab);
  }

  function openDetail(movie, returnTab) {
    state.activeMovie = movie;
    state.returnTab = returnTab || state.tab;
    setVisibleView('detail');

    var eps = getEpisodesForMovie(movie.id);
    var sum = getMovieResumeSummary(movie.id);
    var inLib = isMovieInLibrary(movie.id);

    var titleEl = el('page-title');
    var countEl = el('page-count');
    if (titleEl) titleEl.textContent = movie.name || 'Chi tiết phim';
    if (countEl) countEl.textContent = eps.length + ' tập phim';

    var genres = Array.isArray(movie.genre) ? movie.genre : [];
    var gHtml = '';
    var i;
    for (i = 0; i < genres.length; i++) {
      gHtml += '<span class="genre-tag">' + escapeHtml(genres[i]) + '</span>';
    }

    var ctaLabel = sum.resumeSec > 0
      ? ('&#9654; Xem tiếp Tập ' + (sum.resumeEpIdx + 1) + ' (' + root.YumiPlayer.formatTime(sum.resumeSec) + ')')
      : '&#9654; Xem từ đầu';

    var statusLabel = movie.status === 1 ? 'Hoàn thành' : 'Đang phát hành';

    var hero = el('detail-hero');
    if (hero) {
      hero.innerHTML =
        '<img class="detail-poster" src="' + escapeHtml(movie.imageUrl) + '" alt="' + escapeHtml(movie.name) + '">' +
        '<div class="detail-meta">' +
        '<div>' +
        '<div class="detail-title">' + escapeHtml(movie.name) + '</div>' +
        '<div class="detail-sub">' + escapeHtml(movie.author || 'YumiHub') + ' · ' + escapeHtml(statusLabel) + ' · ' + escapeHtml(movie.source || 'Phim & Điện ảnh') + '</div>' +
        '<div class="detail-genres">' + gHtml + '</div>' +
        '<div class="detail-desc">' + escapeHtml(movie.description || '') + '</div>' +
        '</div>' +
        '<div class="detail-cta-row">' +
        '<button type="button" id="btn-detail-play" class="btn-primary focusable" data-focusable="true" data-zone="detail">' + ctaLabel + '</button>' +
        '<button type="button" id="btn-detail-lib" class="btn-secondary focusable" data-focusable="true" data-zone="detail">' + (inLib ? '&#10003; Đã có trong Thư viện' : '+ Thêm vào Thư viện') + '</button>' +
        '</div>' +
        '</div>';

      var playBtn = el('btn-detail-play');
      var libBtn = el('btn-detail-lib');
      if (playBtn) {
        playBtn.addEventListener('click', function () {
          launchPlayer(movie, eps, sum.resumeEpIdx);
        });
      }
      if (libBtn) {
        libBtn.addEventListener('click', function () {
          toggleMovieInLibrary(movie);
        });
      }
    }

    var epSummary = el('detail-ep-summary');
    if (epSummary) {
      epSummary.textContent = sum.watchedCount + '/' + eps.length + ' tập đã xem · Tiến độ lưu tự động vào localStorage';
    }

    var epListEl = el('detail-episodes');
    if (epListEl) {
      var epHtml = '';
      for (i = 0; i < eps.length; i++) {
        var ep = eps[i];
        var k = root.YumiBackup.episodeKey(movie.id, ep.id, i);
        var prog = root.YumiStorage.getEpisodeProgress(k);
        var stClass = 'ep-status';
        var stText = 'Chưa xem';
        if (prog && prog.completed) {
          stClass += ' is-watched';
          stText = 'Đã xem xong';
        } else if (prog && prog.timeSec > 0) {
          stClass += ' is-resuming';
          stText = 'Xem tiếp từ ' + root.YumiPlayer.formatTime(prog.timeSec);
        }

        epHtml += '<button type="button" class="episode-row focusable" data-focusable="true" data-zone="detail" data-ep-idx="' + i + '">';
        epHtml += '<div class="ep-left">';
        epHtml += '<div class="ep-name">' + escapeHtml(ep.name) + '</div>';
        epHtml += '<div class="ep-sub">Thời lượng: ' + escapeHtml(ep.duration || '00:10') + '</div>';
        epHtml += '</div>';
        epHtml += '<div class="ep-right"><span class="' + stClass + '">' + stText + '</span></div>';
        epHtml += '</button>';
      }
      epListEl.innerHTML = epHtml;
      var rows = epListEl.querySelectorAll('.episode-row');
      for (i = 0; i < rows.length; i++) {
        (function (row) {
          row.addEventListener('click', function () {
            var idx = Number(row.getAttribute('data-ep-idx')) || 0;
            launchPlayer(movie, eps, idx);
          });
        })(rows[i]);
      }
    }

    var mainBtn = el('btn-detail-play');
    if (mainBtn && root.YumiRemote) {
      root.YumiRemote.setFocus(mainBtn);
    }
  }

  function launchPlayer(movie, episodes, epIndex) {
    root.YumiPlayer.open(
      movie,
      episodes,
      epIndex,
      function () {
        if (state.activeMovie) {
          openDetail(state.activeMovie, state.returnTab);
        } else {
          switchTab(state.tab, true);
        }
      },
      showToast
    );
    var playBtn = el('btn-player-play');
    if (playBtn && root.YumiRemote) {
      root.YumiRemote.setFocus(playBtn);
    }
  }

  function switchTab(tabName, keepFocusInSidebar) {
    state.tab = tabName;
    state.activeMovie = null;
    updateSidebarActive();
    setVisibleView(tabName);

    var titleEl = el('page-title');
    if (titleEl) titleEl.textContent = NAV_TITLES[tabName] || 'YumiHub Samsung TV';

    if (tabName === 'library') renderLibrary();
    else if (tabName === 'updates') renderUpdates();
    else if (tabName === 'browse') renderBrowse();
    else if (tabName === 'more') renderMore();

    if (!keepFocusInSidebar && root.YumiRemote) {
      root.YumiRemote.focusFirst('content');
    }
  }

  function loadSampleDataset() {
    var payload = root.YumiSampleData.createSampleBackupPayload();
    var res = root.YumiBackup.importObject(payload, 'Dữ liệu mẫu Phim & Điện ảnh');
    reloadFromStorage();

    var statusBox = el('backup-status-box');
    if (statusBox) {
      statusBox.className = 'status-box is-success';
      statusBox.textContent = 'Đã nạp thành công ' + res.movies.length + ' bộ Phim & Điện ảnh (' + res.chapters.length + ' tập, lọc bỏ ' + res.stats.ignoredOtherTypes + ' mục khác loại).';
    }
    showToast('Đã nạp ' + res.movies.length + ' phim mẫu (lọc bỏ ' + res.stats.ignoredOtherTypes + ' mục khác)');

    if (state.tab === 'library') renderLibrary();
    else if (state.tab === 'updates') renderUpdates();
    else if (state.tab === 'more') renderMore();
  }

  function handleBackupFileSelected(file) {
    var statusBox = el('backup-status-box');
    root.YumiBackup.importFile(
      file,
      function (res) {
        reloadFromStorage();
        if (statusBox) {
          statusBox.className = 'status-box is-success';
          statusBox.textContent = 'Đã nhập "' + res.sourceLabel + '": giữ lại ' + res.movies.length + ' Phim & Điện ảnh, ' + res.categories.length + ' danh mục, ' + res.chapters.length + ' tập (lọc bỏ ' + res.stats.ignoredOtherTypes + ' mục không phải phim).';
        }
        renderMoreStats();
        showToast('Nhập sao lưu thành công: ' + res.movies.length + ' phim');
      },
      function (errMsg) {
        if (statusBox) {
          statusBox.className = 'status-box is-error';
          statusBox.textContent = 'Lỗi đọc sao lưu: ' + errMsg;
        }
        showToast('Lỗi nhập sao lưu: ' + errMsg);
      }
    );
  }

  function bindUiEvents() {
    var navBtns = document.querySelectorAll('.nav-item');
    var i;
    for (i = 0; i < navBtns.length; i++) {
      (function (btn) {
        btn.addEventListener('click', function () {
          switchTab(btn.getAttribute('data-nav'), true);
        });
      })(navBtns[i]);
    }

    var sortBtn = el('btn-sort-toggle');
    if (sortBtn) {
      sortBtn.addEventListener('click', function () {
        state.sortBy = state.sortBy === 'recent' ? 'alpha' : 'recent';
        root.YumiStorage.saveSettings({ sortBy: state.sortBy });
        renderLibrary();
      });
    }

    var emptySampleBtn = el('btn-empty-sample');
    if (emptySampleBtn) emptySampleBtn.addEventListener('click', function () {
      loadSampleDataset();
      if (root.YumiRemote) root.YumiRemote.focusFirst('content');
    });

    var emptyGotoMoreBtn = el('btn-empty-goto-more');
    if (emptyGotoMoreBtn) emptyGotoMoreBtn.addEventListener('click', function () {
      switchTab('more', false);
    });

    var chooseBtn = el('btn-choose-backup');
    var fileInput = el('backup-file-input');
    if (chooseBtn && fileInput) {
      chooseBtn.addEventListener('click', function () {
        fileInput.click();
      });
      fileInput.addEventListener('change', function () {
        if (fileInput.files && fileInput.files[0]) {
          handleBackupFileSelected(fileInput.files[0]);
        }
      });
    }

    var loadSampleBtn = el('btn-load-sample');
    if (loadSampleBtn) loadSampleBtn.addEventListener('click', loadSampleDataset);

    var clearBtn = el('btn-clear-data');
    if (clearBtn) {
      clearBtn.addEventListener('click', function () {
        root.YumiStorage.clearAll();
        reloadFromStorage();
        var statusBox = el('backup-status-box');
        if (statusBox) {
          statusBox.className = 'status-box';
          statusBox.textContent = 'Đã xóa toàn bộ thư viện và tiến độ xem trong localStorage.';
        }
        renderMoreStats();
        showToast('Đã xóa dữ liệu localStorage');
      });
    }

    var saveBridgeBtn = el('btn-save-bridge');
    if (saveBridgeBtn) {
      saveBridgeBtn.addEventListener('click', function () {
        var inp = el('bridge-url-input');
        var val = inp ? inp.value.trim() : '';
        root.YumiStorage.saveSettings({ bridgeUrl: val });
        reloadFromStorage();
        showToast(val ? ('Đã lưu cầu nối LAN: ' + val) : 'Đã xóa URL cầu nối LAN');
      });
    }

    var detailBackBtn = el('btn-detail-back');
    if (detailBackBtn) {
      detailBackBtn.addEventListener('click', function () {
        switchTab(state.returnTab || 'library', false);
      });
    }

    var pBack = el('btn-player-back');
    var pPrev = el('btn-player-prev');
    var pRew = el('btn-player-rew');
    var pPlay = el('btn-player-play');
    var pFf = el('btn-player-ff');
    var pNext = el('btn-player-next');

    if (pBack) pBack.addEventListener('click', function () { root.YumiPlayer.close(); });
    if (pPrev) pPrev.addEventListener('click', function () { root.YumiPlayer.stepEpisode(-1); });
    if (pRew) pRew.addEventListener('click', function () { root.YumiPlayer.seekBy(-10); });
    if (pPlay) pPlay.addEventListener('click', function () { root.YumiPlayer.togglePlay(); });
    if (pFf) pFf.addEventListener('click', function () { root.YumiPlayer.seekBy(10); });
    if (pNext) pNext.addEventListener('click', function () { root.YumiPlayer.stepEpisode(1); });
  }

  function handleBackKey() {
    if (root.YumiPlayer.isOpen()) {
      root.YumiPlayer.close();
      return;
    }
    if (state.activeMovie) {
      switchTab(state.returnTab || 'library', false);
      return;
    }
    if (state.tab !== 'library') {
      switchTab('library', true);
      var firstNav = document.querySelector('.nav-item[data-nav="library"]');
      if (firstNav && root.YumiRemote) root.YumiRemote.setFocus(firstNav);
      return;
    }
    try {
      if (typeof root.tizen !== 'undefined' && root.tizen.application) {
        root.tizen.application.getCurrentApplication().exit();
      }
    } catch (e) {}
  }

  function handleColorKey(colorName, keyCode) {
    var map = {
      red: { tab: 'library', label: 'Phím Đỏ (F0): Thư viện' },
      green: { tab: 'updates', label: 'Phím Xanh lá (F1): Cập nhật' },
      yellow: { tab: 'browse', label: 'Phím Vàng (F2): Duyệt' },
      blue: { tab: 'more', label: 'Phím Xanh dương (F3): Thêm' }
    };
    var entry = map[colorName];
    if (!entry) return;

    if (root.YumiPlayer && root.YumiPlayer.isOpen()) {
      root.YumiPlayer.close();
    }

    switchTab(entry.tab, false);
    if (root.YumiRemote) {
      var navItem = document.querySelector('.nav-item[data-nav="' + entry.tab + '"]');
      if (entry.tab === 'updates' && (!state.library || !state.library.chapters || !state.library.chapters.length)) {
        if (navItem) root.YumiRemote.setFocus(navItem);
      }
    }
    showToast(entry.label + ' (mã ' + keyCode + ')');
  }

  function bootstrap() {
    state.browseCatalog = root.YumiSampleData.getBrowseCatalog();
    reloadFromStorage();
    bindUiEvents();

    var splashCtrl = null;
    root.YumiRemote.init({
      onBack: handleBackKey,
      onPlayPause: function () { root.YumiPlayer.togglePlay(); },
      onRewind: function () { root.YumiPlayer.seekBy(-10); },
      onFastForward: function () { root.YumiPlayer.seekBy(10); },
      onStop: function () { root.YumiPlayer.close(); },
      onColorKey: handleColorKey,
      onSplashSkip: function () {
        if (splashCtrl) splashCtrl.finish();
      }
    });

    splashCtrl = root.YumiSplash.start(function () {
      var shell = el('app-shell');
      if (shell) shell.className = 'app-shell';
      switchTab('library', true);
      if (state.library && state.library.movies && state.library.movies.length) {
        root.YumiRemote.focusFirst('content');
      } else {
        root.YumiRemote.focusFirst('content');
      }
    });
  }

  root.YumiApp = {
    switchTab: switchTab,
    loadSampleDataset: loadSampleDataset,
    openDetail: openDetail,
    openMovieById: openMovieById,
    handleBackupFileSelected: handleBackupFileSelected,
    handleColorKey: handleColorKey
  };

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', bootstrap);
  } else {
    bootstrap();
  }
})(window);
