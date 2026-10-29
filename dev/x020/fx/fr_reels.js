/* FapReel vertical reels feed: muted autoplay of the visible reel, tap for sound,
   lazy-load of the next batch via /reels/feed.php. Progressive enhancement on top
   of a server-rendered, CSS scroll-snap feed. */
(function () {
    var cfg  = window.FR_REELS;
    var feed = document.getElementById('reels-feed');
    if (!cfg || !feed) { return; }

    // Reels moeilijker te downloaden: rechtsklik ("Video opslaan als") en slepen op de video/poster
    // blokkeren. Echte bescherming zit server-side; dit weert de makkelijke vectoren.
    feed.addEventListener('contextmenu', function (e) {
        if (e.target.closest('.reel-video, .reel-poster')) { e.preventDefault(); }
    });
    feed.addEventListener('dragstart', function (e) {
        if (e.target.closest('.reel-video, .reel-poster')) { e.preventDefault(); }
    });

    var muted = true, loading = false, active = null, autoAdvance = false;
    try { if (localStorage.getItem('fr_muted') === '0') { muted = false; } } catch (e) {}   // geluidsvoorkeur onthouden
    try { autoAdvance = localStorage.getItem('fr_autoplay') === '1'; } catch (e) {}

    function setSrc(reel) {
        var v = reel.querySelector('video');
        if (v && !v.getAttribute('src') && reel.dataset.src) { v.setAttribute('src', reel.dataset.src); }
        return v;
    }
    // Buffer de VOLGENDE reel alvast (preload=auto + load) zodat de swipe instant is.
    // Pas aanroepen als de huidige reel al speelt, zodat het niet om bandbreedte vecht.
    function preloadNext(reel) {
        if (reel !== active) { return; }   // gebruiker al doorgeswipet -> volgende niet resetten
        var next = reel.nextElementSibling;
        if (!next || !next.classList.contains('reel') || next.classList.contains('reel-end') || next._frPreloaded) { return; }
        var nv = setSrc(next);
        if (!nv) { return; }
        next._frPreloaded = true;
        try { nv.preload = 'auto'; nv.load(); } catch (e) {}
    }
    // Los video's ver van de actieve reel (mobiel heeft een limiet op het aantal
    // gelijktijdig geladen video's/decoders; zonder dit speelt na ~5 reels niets meer).
    var KEEP = 1;
    function unloadFar(activeReel) {
        var reels = feed.querySelectorAll('.reel:not(.reel-end)');
        var ai = Array.prototype.indexOf.call(reels, activeReel);
        Array.prototype.forEach.call(reels, function (r, i) {
            if (Math.abs(i - ai) <= KEEP) { return; }
            var v = r.querySelector('video');
            if (v && v.getAttribute('src')) {
                try { v.pause(); v.removeAttribute('src'); v.load(); } catch (e) {}
                r._frPreloaded = false;
                r.classList.remove('is-loading');
            }
        });
    }
    function activate(reel) {
        if (reel === active) { return; }
        if (feed.classList.contains('is-loading')) { feed.classList.remove('is-loading'); }   // eerste echte reel actief -> loading-overlay weg
        if (active) { var pv = active.querySelector('video'); if (pv) { pv.pause(); } active.classList.remove('is-active'); if (active._ctaTimer) { clearTimeout(active._ctaTimer); active._ctaTimer = null; } }
        active = reel;
        reel.classList.add('is-active');
        reel.classList.remove('is-paused');
        // Clip: controls VERBORGEN bij aankomst (pas tonen op tap/hover, zie onder).
        if (reel.classList.contains('reel-clip')) { var _cv = reel.querySelector('video'); if (_cv) { _cv.controls = false; } }
        // Persoonlijke viewers (fav/pop, noindex): tab-titel meelopen met het actieve model i.p.v. generiek.
        if (cfg.mode === 'fav' || cfg.mode === 'pop') {
            var tnm = reel.querySelector('.reel-name'), tst = reel.querySelector('.reel-studio span');
            var twho = tnm ? tnm.textContent.trim() : (tst ? tst.textContent.trim() : '');
            try { document.title = (twho || (cfg.mode === 'pop' ? 'Most Popular' : 'Your Favorites')) + ' | FapReel'; } catch (e) {}
        }
        var pb0 = reel.querySelector('.reel-prog span'); if (pb0) { pb0.style.width = '0'; }
        // "Watch full video"-knop pas na 1,75s in beeld sliden + pulse (1x per reel; blijft daarna staan).
        if (!reel._ctaTimer && !reel.classList.contains('cta-in')) {
            reel._ctaTimer = setTimeout(function () { reel._ctaTimer = null; if (active === reel) { reel.classList.add('cta-in'); } }, 1750);
        }
        unloadFar(reel);
        var v = setSrc(reel);
        if (v) {
            if (v.readyState < 3) { reel.classList.add('is-loading'); }
            var tryPlay = function () { if (active === reel && v.paused) { v.muted = muted; var p = v.play(); if (p && p.catch) { p.catch(function () { if (!v.muted) { v.muted = true; var p2 = v.play(); if (p2 && p2.catch) { p2.catch(function () {}); } } }); } } };
            if (!v._frLoad) {
                v._frLoad = true;
                var done = function () { reel.classList.remove('is-loading'); preloadNext(reel); };
                v.addEventListener('playing', done);
                // Koude reel (eerste van een lazy batch, niet ge-preload): de directe play()
                // kan op mobiel mislukken zonder data -> opnieuw proberen zodra er data is.
                v.addEventListener('canplay', function () { done(); tryPlay(); });
                v.addEventListener('loadeddata', tryPlay);
                v.addEventListener('error', function () { done(); if (active !== reel) { return; } if (!v._frRetry) { v._frRetry = 1; try { var s = reel.dataset.src; v.removeAttribute('src'); v.setAttribute('src', s); v.load(); tryPlay(); } catch (e) {} } else if (!reel.classList.contains('reel-cta')) { advanceNext(reel); } });
                v.addEventListener('waiting', function () { reel.classList.add('is-loading'); });
                // Auto-advance: eindigt de video en staat de toggle aan -> door naar de volgende reel.
                v.addEventListener('ended', function () { if (autoAdvance && active === reel) { advanceNext(reel); } });
                // Voortgangsbalk: loopt de clip opnieuw -> currentTime 0 -> balk springt zichtbaar terug.
                var pbar = reel.querySelector('.reel-prog span');
                v.addEventListener('timeupdate', function () {
                    if (active === reel && pbar && v.duration) { pbar.style.width = (v.currentTime / v.duration * 100) + '%'; }
                });
            }
            v.muted = muted; v.loop = !autoAdvance; tryPlay();
        }
        // Preload the next reel's source so the swap is instant.
        var next = reel.nextElementSibling;
        if (next && next.classList.contains('reel') && !next.classList.contains('reel-end')) { setSrc(next); }
        maybeLoadMore(reel);
    }
    function maybeLoadMore(reel) {
        var reels = feed.querySelectorAll('.reel:not(.reel-end):not(.reel-cta):not(.reel-sfw-inject)');
        var idx = Array.prototype.indexOf.call(reels, reel);
        if (idx >= 0 && idx >= reels.length - 2) { loadMore(); }
    }
    function loadMore(cb) {
        if (loading || cfg.offset >= cfg.total) { if (cb) { cb(); } return; }
        loading = true;
        var url, favAdvance = 0, idFeed = (cfg.mode === 'fav' || cfg.mode === 'pop');
        if (idFeed) {
            // Id-lijst-viewer: fav = localStorage (favs), pop = server (cfg.ids). Slice als reel-markup.
            var list = cfg.mode === 'pop' ? (cfg.ids || []) : favs;
            var slice = list.slice(cfg.offset, cfg.offset + cfg.batch);
            favAdvance = slice.length;
            if (!favAdvance) { cfg.offset = cfg.total; loading = false; if (cb) { cb(); } return; }
            url = '/reels/cards.php?feed=1&ids=' + encodeURIComponent(slice.join(','));
            if (cfg.cta) { url += '&cta=1&off=' + cfg.offset; }   // /shorts: CTA's tussen de reels (cadans via off)
        } else {
            url = '/reels/feed.php?mode=' + encodeURIComponent(cfg.mode) +
                  '&key=' + encodeURIComponent(cfg.key) +
                  '&offset=' + cfg.offset + '&rb=' + (cfg.reelBase || 0) + '&slug=' + encodeURIComponent(cfg.slug || '') + '&count=' + cfg.batch;
            var ctaM = (location.search || '').match(/[?&]cta=([a-z0-9_-]+)/i);   // CTA-preview (?cta=dna) meegeven
            if (ctaM) { url += '&cta=' + encodeURIComponent(ctaM[1]); }
        }
        fetch(url).then(function (r) { return r.text(); }).then(function (html) {
            html = (html || '').trim();
            var end = feed.querySelector('.reel-end');
            if (html && end) {
                var added = 0, tmp = document.createElement('div');
                tmp.innerHTML = html;
                Array.prototype.forEach.call(tmp.querySelectorAll('.reel'), function (node) {
                    // Dubbele reel: een kop-reel (populair of RedGifs, server-gerenderd bovenaan) die
                    // verderop in de contigue stream terugkomt. Niet nogmaals tonen, maar wel meetellen
                    // voor de offset zodat de paginering blijft kloppen.
                    var isReel = !node.classList.contains('reel-cta') && !node.classList.contains('reel-more') && !node.classList.contains('reel-clip');
                    if (isReel && node.id && document.getElementById(node.id)) { added++; return; }
                    feed.insertBefore(node, end); io.observe(node);
                    if (!node.classList.contains('reel-cta') && !node.classList.contains('reel-more') && (cfg.mode === 'clips' || !node.classList.contains('reel-clip'))) { added++; }   // CTA telt nooit; clip telt alleen mee in de pure clips-feed
                    if (!node.classList.contains('reel-cta') && !node.classList.contains('reel-clip')) { sfwOnReel(node); }   // soft-feed: SFW-reel tussenschuiven
                });
                if (idFeed) { cfg.offset += favAdvance; }   // op id-basis doorschuiven (ook missende ids)
                else { cfg.offset += added; if (added === 0) { cfg.offset = cfg.total; } }
            } else if (idFeed) { cfg.offset += favAdvance; }
            else { cfg.offset = cfg.total; }
            reflectAuto();
            reflectLikes();
            reflectFavs();
            reflectSoft();
            loading = false; if (cb) { cb(); }
        }).catch(function () { loading = false; if (cb) { cb(); } });
    }

    var _rotating = false, _rotClear = null;   // tijdens roteren de observer bevriezen: geen drift-activatie
    var io = new IntersectionObserver(function (entries) {
        if (_rotating) { return; }   // roteren verandert slide-hoogtes -> anders verspringt active (+ unloadFar -> herstart)
        entries.forEach(function (e) {
            if (e.isIntersecting && e.intersectionRatio >= 0.55 &&
                e.target.classList.contains('reel') && !e.target.classList.contains('reel-end')) {
                activate(e.target);
            }
        });
    }, { root: feed, threshold: [0.55] });
    Array.prototype.forEach.call(feed.querySelectorAll('.reel:not(.reel-end)'), function (r) { io.observe(r); });

    // ---- SFW-injectie (alleen soft-modus, alleen de standaard-feeds) ----
    // Opent met SFW_LEAD scherpe SFW-reels en mengt er om de SFW_EVERY reels eentje tussen, zodat een
    // soft-bezoeker niet alleen blur ziet. Geinjecteerde reels dragen .reel-sfw-inject en tellen NIET mee
    // in de offset/loadmore (ze verstoren de clip/CTA-boekhouding dus niet).
    var SFW = { on: document.body.classList.contains('reels-soft'), lead: 2, every: 3,
                pool: [], idx: 0, count: 0, ready: false };
    // Voorkom de korte flits van een geblurde server-reel: houd de feed verborgen tot de SFW-lead er staat.
    // Fallback-timer zorgt dat de feed sowieso verschijnt (trage/mislukte pool-fetch).
    function sfwUnhold() { feed.classList.remove('sfw-hold'); }
    if (SFW.on && cfg.sfwInject) { feed.classList.add('sfw-hold'); setTimeout(sfwUnhold, 1500); }
    function sfwClone() {
        if (!SFW.pool.length) { return null; }
        var n = SFW.pool[SFW.idx % SFW.pool.length].cloneNode(true);
        SFW.idx++; n.classList.add('reel-sfw-inject');
        return n;
    }
    function sfwPut(refNode) {
        var n = sfwClone(); if (!n) { return null; }
        feed.insertBefore(n, refNode || feed.querySelector('.reel-end')); io.observe(n);
        reflectLikes(n); reflectFavs(n);
        return n;
    }
    // Tel een echte content-reel; na elke SFW.every er eentje inschuiven.
    function sfwOnReel(node) {
        if (!SFW.on || !SFW.ready) { return; }
        SFW.count++;
        if (SFW.count % SFW.every === 0) { sfwPut(node.nextSibling); }
    }
    function sfwBoot() {
        if (!SFW.on || !cfg.sfwInject) { return; }   // alleen soft-modus + de standaard-feeds (homepage/reels/shorts)
        fetch('/reels/sfwpool.php?n=24').then(function (r) { return r.text(); }).then(function (html) {
            var tmp = document.createElement('div'); tmp.innerHTML = (html || '').trim();
            SFW.pool = Array.prototype.slice.call(tmp.querySelectorAll('.reel'));
            if (!SFW.pool.length) { sfwUnhold(); return; }
            SFW.ready = true;
            // 1) Openen: SFW_LEAD reels vooraan (voor de eerste server-reel).
            var firstReel = feed.querySelector('.reel:not(.reel-sfw-inject)');
            var lead0 = null;
            for (var i = 0; i < SFW.lead; i++) { var ln = sfwPut(firstReel); if (ln && !lead0) { lead0 = ln; } }
            // 2) Sprenkelen door de al aanwezige server-reels.
            var existing = feed.querySelectorAll('.reel:not(.reel-end):not(.reel-cta):not(.reel-sfw-inject)');
            Array.prototype.forEach.call(existing, function (node) { sfwOnReel(node); });
            // 3) Land op de eerste SFW-lead (alleen bij een gewone load, geen #reel-deeplink).
            if (lead0 && !targetId) { requestAnimationFrame(function () { lead0.scrollIntoView(); activate(lead0); sfwUnhold(); }); }
            else { sfwUnhold(); }
        }).catch(function () { sfwUnhold(); });
    }

    // Soft-modus: watch-full knoppen naar de /video/<slug> soft-variant (data-soft-href) omwisselen.
    // Googlebot rendert geen JS -> die houdt de normale href, dus soft geldt nooit voor crawlers.
    var isSoft = document.body.classList.contains('reels-soft');
    function reflectSoft() {
        if (!isSoft) { return; }
        var reels = feed.querySelectorAll('.reel:not(.reel-cta):not(.reel-end):not(.reel-sfw)');
        for (var i = 0; i < reels.length; i++) {
            var reel = reels[i];
            var btn = reel.querySelector('.reel-fullbtn[data-soft-href]');
            var soft = btn ? btn.getAttribute('data-soft-href') : (reel._softHref || '');
            if (btn && soft) { btn.setAttribute('href', soft); btn.removeAttribute('data-soft-href'); reel._softHref = soft; }
            var inner = reel.querySelector('.reel-inner');
            if (inner && !reel._softCta) {
                reel._softCta = 1;
                var box = document.createElement('div');
                box.className = 'reel-soft-cta';
                box.innerHTML = '<p class="reel-soft-txt">You need to be 18+ to watch this uncensored.</p>' +
                    '<a class="reel-soft-btn" href="https://pb-netw2.com/ct?id=310545a3&cid=50130&bn=129&url=" rel="nofollow sponsored">I\'m 18+ Show me more!</a>' +
                    '<span class="reel-soft-sub">No blur. Full scenes. 9 months free.</span>';
                inner.appendChild(box);
            }
        }
    }
    reflectSoft();

    function toggleMute() {
        muted = !muted;
        try { localStorage.setItem('fr_muted', muted ? '1' : '0'); } catch (e) {}
        feed.classList.toggle('is-muted', muted);
        if (active) { var v = active.querySelector('video'); if (v) { v.muted = muted; if (!muted) { var p = v.play(); if (p && p.catch) { p.catch(function () {}); } } } }
    }
    // iOS: geluid-autoplay is geblokkeerd, maar een play() BINNEN een tik/swipe-gesture mag wel geluid.
    // Bij elke pointerup (einde van een swipe/tik): staat de voorkeur op "geluid aan", unmute dan de reel
    // die het dichtst bij het scherm-midden staat (het snap-doel), binnen deze gesture. Zo komt geluid
    // terug bij elke swipe i.p.v. dat iOS het permanent mute't.
    feed.addEventListener('pointerup', function (e) {
        if (e && e.target && e.target.closest && e.target.closest('.reel-speed')) { return; }   // 2x-knop loslaten = geen unmute-gesture
        if (muted) { return; }
        var vh = window.innerHeight || document.documentElement.clientHeight, best = null, bestD = 1e9;
        Array.prototype.forEach.call(feed.querySelectorAll('.reel:not(.reel-end)'), function (r) {
            var rc = r.getBoundingClientRect(), d = Math.abs((rc.top + rc.bottom) / 2 - vh / 2);
            if (d < bestD) { bestD = d; best = r; }
        });
        if (best) { var v = setSrc(best); if (v && v.muted) { v.muted = false; var p = v.play(); if (p && p.catch) { p.catch(function () {}); } } }
    });
    feed.classList.toggle('is-muted', muted);

    // Korte toast onderin (bv. "Link copied" bij de deel-fallback op desktop).
    var toastEl = null, toastT = 0;
    function toast(msg) {
        if (!toastEl) { toastEl = document.createElement('div'); toastEl.className = 'reel-toast'; document.body.appendChild(toastEl); }
        toastEl.textContent = msg;
        requestAnimationFrame(function () { if (toastEl) { toastEl.classList.add('show'); } });
        clearTimeout(toastT);
        toastT = setTimeout(function () { if (toastEl) { toastEl.classList.remove('show'); } }, 2200);
    }
    // Deel deze reel: native deelmenu (Web Share) op mobiel, anders link naar klembord kopieren.
    // Gedeeld wordt de #reel-<id> deeplink; reels.js resolvet die bij binnenkomst via seekTo().
    function shareReel(reel) {
        var url = location.origin + location.pathname + '#' + reel.id;
        var model = reel.querySelector('.reel-name'), studio = reel.querySelector('.reel-studio span');
        var who = model ? model.textContent.trim() : (studio ? studio.textContent.trim() : '');
        var title = who ? (who + ' on FapReel') : 'FapReel';
        var text = who ? ('Watch ' + who + ' on FapReel') : 'Watch this reel on FapReel';
        if (navigator.share) {
            navigator.share({ title: title, text: text, url: url }).catch(function () {});
        } else if (navigator.clipboard && navigator.clipboard.writeText) {
            navigator.clipboard.writeText(url).then(function () { toast('Link copied'); }).catch(function () { toast(url); });
        } else {
            toast(url);
        }
    }

    // Stabiele anonieme client-id (per browser) voor like-dedup i.p.v. IP: zo tellen verschillende
    // browsers/apparaten apart, maar kan één browser niet dubbel tellen of andermans likes wegklikken.
    var frCid = (function () {
        try {
            var c = localStorage.getItem('fr_cid');
            if (!c) { c = Date.now().toString(36) + Math.random().toString(36).slice(2, 12); localStorage.setItem('fr_cid', c); }
            return c;
        } catch (e) { return ''; }
    })();

    // Likes: liked-state per bezoeker in localStorage; globale teller via /reels/like.php.
    var liked = {};
    try { (JSON.parse(localStorage.getItem('fr_likes') || '[]') || []).forEach(function (x) { liked[x] = 1; }); } catch (e) {}
    function saveLiked() { try { localStorage.setItem('fr_likes', JSON.stringify(Object.keys(liked))); } catch (e) {} }
    function fmtLikes(n) {
        n = +n || 0;
        if (n <= 0) { return ''; }
        if (n < 1000) { return '' + n; }
        if (n < 10000) { return (n / 1000).toFixed(1).replace(/\.0$/, '') + 'k'; }
        return Math.round(n / 1000) + 'k';
    }
    function reflectLikes(scope) {
        Array.prototype.forEach.call((scope || feed).querySelectorAll('.reel-like'), function (b) {
            var on = !!liked[b.getAttribute('data-id')];
            b.classList.toggle('is-liked', on);
            b.setAttribute('aria-pressed', on ? 'true' : 'false');
        });
    }
    function toggleLike(btn) {
        var id = btn.getAttribute('data-id'); if (!id) { return; }
        var on = !liked[id];
        if (on) { liked[id] = 1; } else { delete liked[id]; }
        saveLiked();
        btn.classList.toggle('is-liked', on);
        btn.setAttribute('aria-pressed', on ? 'true' : 'false');
        var nEl = btn.querySelector('.reel-like-n');
        // Cumulatieve teller: alleen omhoog. Bij unlike verandert het globale getal niet meer.
        var raw = (parseInt(nEl.getAttribute('data-n'), 10) || 0) + (on ? 1 : 0);
        if (raw < 0) { raw = 0; }
        nEl.setAttribute('data-n', raw); nEl.textContent = fmtLikes(raw);
        if (on) { btn.classList.remove('pop'); void btn.offsetWidth; btn.classList.add('pop'); }
        fetch('/reels/like.php', { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body: 'id=' + encodeURIComponent(id) + '&a=' + (on ? 'like' : 'unlike') + '&cid=' + encodeURIComponent(frCid) })
            .then(function (r) { return r.json(); })
            .then(function (d) { if (d && typeof d.count === 'number') { nEl.setAttribute('data-n', d.count); nEl.textContent = fmtLikes(d.count); } })
            .catch(function () {});
    }

    // Favorites: reel-ids per bezoeker in localStorage (nieuwste vooraan), zichtbaar op /favorites.
    var favs = [];
    try { favs = JSON.parse(localStorage.getItem('fr_favs') || '[]') || []; } catch (e) {}
    function saveFavs() { try { localStorage.setItem('fr_favs', JSON.stringify(favs)); } catch (e) {} }

    // Eenmalige inhaalslag: bestaande localStorage-favorites die nog niet naar de server zijn
    // gestuurd alsnog syncen (1 batch-request). De marker wordt pas gezet als de sync slaagt,
    // zodat niks verloren gaat bij offline; dedup gebeurt server-side (cumulatief, nooit dubbel).
    (function syncFavsOnce() {
        try {
            if (!frCid || !favs.length) { return; }
            var synced = {};
            try { (JSON.parse(localStorage.getItem('fr_favs_synced') || '[]') || []).forEach(function (x) { synced[x] = 1; }); } catch (e) {}
            var todo = favs.filter(function (id) { return !synced[id]; });
            if (!todo.length) { return; }
            fetch('/reels/fav.php', { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body: 'ids=' + encodeURIComponent(todo.join(',')) + '&cid=' + encodeURIComponent(frCid) })
                .then(function () { try { localStorage.setItem('fr_favs_synced', JSON.stringify(favs.slice())); } catch (e) {} })
                .catch(function () {});
        } catch (e) {}
    })();
    function reflectFavs(scope) {
        Array.prototype.forEach.call((scope || feed).querySelectorAll('.reel-fav'), function (b) {
            var on = favs.indexOf(b.getAttribute('data-id')) !== -1;
            b.classList.toggle('is-fav', on);
            b.setAttribute('aria-pressed', on ? 'true' : 'false');
        });
    }
    function toggleFav(btn) {
        var id = btn.getAttribute('data-id'); if (!id) { return; }
        var i = favs.indexOf(id), on = i === -1;
        if (on) { favs.unshift(id); } else { favs.splice(i, 1); }
        saveFavs();
        btn.classList.toggle('is-fav', on);
        btn.setAttribute('aria-pressed', on ? 'true' : 'false');
        if (on) { btn.classList.remove('pop'); void btn.offsetWidth; btn.classList.add('pop'); }
        // Lichte meting: globale favorite-teller ophogen/verlagen (geen UI-teller, fire-and-forget).
        fetch('/reels/fav.php', { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body: 'id=' + encodeURIComponent(id) + '&a=' + (on ? 'fav' : 'unfav') + '&cid=' + encodeURIComponent(frCid) }).catch(function () {});
    }

    // Tap-to-pause: tikken op de reel pauzeert/hervat de video (geluid blijft op de mute-knop).
    function togglePause(reel) {
        var v = reel.querySelector('video');
        if (!v) { return; }
        if (v.paused) { reel.classList.remove('is-paused'); var p = v.play(); if (p && p.catch) { p.catch(function () {}); } }
        else { v.pause(); reel.classList.add('is-paused'); }
    }

    // Scroll naar de volgende reel (IntersectionObserver activeert 'm dan). Niets meer? Laad bij.
    function advanceNext(reel) {
        var next = reel.nextElementSibling;
        if (next && next.classList.contains('reel') && !next.classList.contains('reel-end')) {
            next.scrollIntoView({ behavior: 'smooth' });
        } else if (cfg.offset < cfg.total) {
            loadMore(function () { advanceNext(reel); });
        }
    }
    // Reflecteer de auto-advance-state op alle toggle-knoppen + de actieve video's loop.
    function reflectAuto() {
        Array.prototype.forEach.call(feed.querySelectorAll('.reel-auto'), function (b) {
            b.classList.toggle('is-on', autoAdvance);
            b.setAttribute('aria-pressed', autoAdvance ? 'true' : 'false');
        });
        if (active) { var v = active.querySelector('video'); if (v) { v.loop = !autoAdvance; } }
    }
    function toggleAuto() {
        autoAdvance = !autoAdvance;
        try { localStorage.setItem('fr_autoplay', autoAdvance ? '1' : '0'); } catch (e) {}
        reflectAuto();
    }
    // iOS Safari slikt binnen de mandatory scroll-snap feed de eerste synthetische CLICK soms in
    // -> same-tab pills vragen dan 2 taps. Een target="_blank" link (gele "full video"-knop) is
    // immuun omdat die al op de touch-gesture (pointerup) wordt geactiveerd. We navigeren same-tab
    // links daarom zelf op pointerup, op diezelfde gesture-laag. Swipes, modifier-clicks (nieuw
    // tabblad op desktop), nieuw-tab/download en in-page anchors laten we met rust.
    var pdX = 0, pdY = 0, pdLink = null;
    feed.addEventListener('pointerdown', function (e) {
        pdLink = e.target.closest ? e.target.closest('a[href]') : null;
        pdX = e.clientX; pdY = e.clientY;
    }, true);
    feed.addEventListener('pointerup', function (e) {
        var a = e.target.closest ? e.target.closest('a[href]') : null;
        if (!a || a !== pdLink) { return; }                                   // geen link / versleept naar andere link
        if (a.target === '_blank' || a.hasAttribute('download')) { return; }  // nieuw tabblad: native regelt dit
        if ((e.button && e.button !== 0) || e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) { return; }
        var href = a.getAttribute('href') || '';
        if (!href || href.charAt(0) === '#') { return; }                      // in-page anchors met rust laten
        if (Math.abs(e.clientX - pdX) > 10 || Math.abs(e.clientY - pdY) > 10) { return; }  // swipe, geen tap
        e.preventDefault();
        location.assign(a.href);
    }, true);

    // "2x"-knop: zolang ingedrukt gehouden (vinger op mobiel, muisknop op desktop) speelt de reel op
    // dubbele snelheid; loslaten -> weer normaal. Pointer-events vangen touch en muis in een.
    var spdBtn = null, spdVid = null;
    // Sommige browsers (o.a. iOS Safari) herstarten een muted-inline video bij een playbackRate-wijziging.
    // We bewaren de positie en zetten 'm terug (direct + volgende frame + kort erna) als 'ie terugsprong.
    function frSetRate(v, rate) {
        if (!v) { return; }
        rate = Math.min(rate, 2);                                        // iOS/WebKit faalt boven 2x
        if (v.playbackRate === rate) { return; }
        var t = v.currentTime, wasPlaying = !v.paused;
        try { v.defaultPlaybackRate = rate; } catch (x) {}               // iOS reset anders terug naar 1x bij state-wissels/loop
        try { v.playbackRate = rate; } catch (x) { return; }
        // WebKit kan bij de snelheidswissel kort stallen/terugspringen (AVFoundation-bug 163433). Alleen
        // herstellen als 'ie echt TERUGsprong (niet bij normaal vooruit spelen), afspelen hervatten, rate herbevestigen.
        // Zo min mogelijk aan de video raken (elke extra wissel = extra hik op iOS). Alleen positie terugzetten
        // als 'ie ECHT terugsprong en afspelen hervatten. GEEN rate-herbevestiging (defaultPlaybackRate dekt de reset).
        var heal = function () {
            if (v.currentTime < t - 0.35) { try { v.currentTime = t; } catch (x) {} }
            if (wasPlaying && v.paused) { var p = v.play(); if (p && p.catch) { p.catch(function () {}); } }
        };
        v.addEventListener('ratechange', heal, { once: true });
        setTimeout(heal, 140);
    }
    function spdStop(e) {
        if (!spdBtn) { return; }
        if (e) { e.stopPropagation(); }                                   // geen unmute/nav op deze release
        frSetRate(spdVid, 1);
        spdBtn.classList.remove('on');
        spdBtn = null; spdVid = null;
    }
    feed.addEventListener('pointerdown', function (e) {
        var b = e.target.closest ? e.target.closest('.reel-speed') : null;
        if (!b) { return; }
        e.stopPropagation();                                             // GEEN preventDefault: dat breekt scroll en triggert op WebKit juist een reset
        var reel = b.closest('.reel'), v = reel ? reel.querySelector('video') : null;
        // Alleen versnellen als de reel ECHT speelt en genoeg gebufferd is (readyState>=3). Op een koude/
        // bufferende video herstart iOS juist bij een playbackRate-wissel; dan doen we bewust niets.
        if (!v || v.readyState < 3 || v.paused) { return; }
        if (spdBtn && spdBtn !== b) { spdStop(); }
        spdBtn = b; spdVid = v;
        try { b.setPointerCapture(e.pointerId); } catch (x) {}           // blijf events krijgen als vinger verschuift
        b.classList.add('on');
        frSetRate(v, 2);
    }, true);
    window.addEventListener('pointerup', spdStop, true);
    window.addEventListener('pointercancel', spdStop, true);

    feed.addEventListener('click', function (e) {
        var reel = e.target.closest ? e.target.closest('.reel') : null;
        if (!reel || reel.classList.contains('reel-end')) { return; }
        if (e.target.closest('a')) { return; }
        if (e.target.closest('.reel-speed')) { return; }                                                     // 2x-knop: nooit pauzeren
        if (e.target.closest('.reel-nichebar')) { return; }                                                  // niche-dropdown: niet pauzeren
        if (e.target.closest('.reel-like')) { toggleLike(e.target.closest('.reel-like')); return; }             // like (hartje + globale teller)
        if (e.target.closest('.reel-fav')) { toggleFav(e.target.closest('.reel-fav')); return; }                // favorite (+ -> localStorage)
        if (e.target.closest('.reel-share')) { shareReel(reel); return; }                                      // delen (Web Share / klembord)
        if (e.target.closest('.reel-mute')) { toggleMute(); return; }                                          // geluid zit op de mute-knop
        if (e.target.closest('.reel-fs')) { fullscreenClip(reel); return; }                                     // clip fullscreen (desktop)
        if (e.target.closest('.reel-auto') || e.target.closest('.reel-auto-lbl')) { toggleAuto(); return; }   // toggle (knop + label)
        if (reel.classList.contains('reel-clip')) {
            var coarse = window.matchMedia && window.matchMedia('(pointer: coarse)').matches;
            // Clips op DESKTOP: geen native controls -> klik op de slanke balk = spoelen,
            // klik op de video = pauze/hervat (zoals een reel).
            if (!coarse) {
                if (e.target.closest('.reel-prog')) { return; }   // balk = scrubber (pointerdown/move hieronder)
                togglePause(reel);
                return;
            }
            // Mobiel + LANDSCAPE: tap op de clip = ECHTE native fullscreen (geldige gebruikersgesture ->
            // adresbalk weg). In portrait doet een tap niks (overlays blijven; draaien = de rotate-hint).
            if (coarse && window.matchMedia('(orientation: landscape)').matches) {
                var cvf = reel.querySelector('video');
                if (cvf) {
                    cvf.controls = true;
                    cvf.addEventListener('webkitendfullscreen', function () { this.controls = false; }, { once: true });
                    try {
                        if (cvf.requestFullscreen) { cvf.requestFullscreen(); }
                        else if (cvf.webkitEnterFullscreen) { cvf.webkitEnterFullscreen(); }   // iOS Safari
                        else if (cvf.webkitRequestFullscreen) { cvf.webkitRequestFullscreen(); }
                    } catch (e) {}
                }
            }
            return;
        }
        togglePause(reel);                                                                                     // tikken op de reel = pauze/hervat
    });

    // Clips op DESKTOP: geen native controls-balk -> de slanke reel-balk is een scrubber. Sleep of klik
    // op de balk om te spoelen (klik-op-video = pauze, zie click-handler). Mobiel: balk is alleen visueel.
    var scrubV = null, scrubBar = null;
    function frSeek(clientX) {
        if (!scrubV || !isFinite(scrubV.duration) || scrubV.duration <= 0) { return; }
        var r = scrubBar.getBoundingClientRect();
        scrubV.currentTime = Math.max(0, Math.min(1, (clientX - r.left) / r.width)) * scrubV.duration;
        var sp = scrubBar.firstChild; if (sp && sp.style) { sp.style.width = Math.max(0, Math.min(100, (clientX - r.left) / r.width * 100)) + '%'; }
    }
    feed.addEventListener('pointerdown', function (e) {
        var bar = e.target.closest ? e.target.closest('.reel-clip .reel-prog') : null;
        if (!bar) { return; }
        var clip = bar.closest('.reel-clip'), v = clip && clip.querySelector('video');
        if (!v) { return; }
        scrubV = v; scrubBar = bar;
        clip.classList.add('is-scrubbing');
        frSeek(e.clientX);
        e.preventDefault();
        try { bar.setPointerCapture(e.pointerId); } catch (x) {}
    });
    window.addEventListener('pointermove', function (e) { if (scrubV) { frSeek(e.clientX); } });
    window.addEventListener('pointerup', function () {
        if (scrubBar) { var c = scrubBar.closest('.reel-clip'); if (c) { c.classList.remove('is-scrubbing'); } }
        scrubV = null; scrubBar = null;
    });

    // Clip fullscreen (desktop-knop in de bar). In fullscreen native controls aan; bij afsluiten weer uit
    // (de fullscreenchange-handler hieronder zet clip-controls terug -> onze overlays weer zichtbaar).
    function fullscreenClip(reel) {
        var v = reel.querySelector('video');
        if (!v) { return; }
        v.controls = true;
        try {
            if (v.requestFullscreen) { v.requestFullscreen(); }
            else if (v.webkitRequestFullscreen) { v.webkitRequestFullscreen(); }
            else if (v.webkitEnterFullscreen) { v.addEventListener('webkitendfullscreen', function () { this.controls = false; }, { once: true }); v.webkitEnterFullscreen(); }
        } catch (e) {}
    }

    // Clip in LANDSCAPE -> video fullscreen (horizontale clip vult het scherm); terug bij portrait
    // gewoon weer in de FapReel-viewer. Best-effort: sommige browsers blokkeren fullscreen zonder
    // gebruikersgesture -> dan niks.
    var _preRotateClip = null, _rotTarget = null, _rotTimer = null;
    function clipLandscapeFullscreen() {
        // Alleen touch-apparaten (telefoon/tablet). Desktop is altijd landscape -> moet niks doen.
        if (window.matchMedia && !window.matchMedia('(pointer: coarse)').matches) { return; }
        var landscape = window.matchMedia ? window.matchMedia('(orientation: landscape)').matches
                                          : (window.innerWidth > window.innerHeight);
        if (landscape) {
            // De bedoelde clip is die van vóór de rotatie (_rotTarget); de scroll-snap-reflow kan `active`
            // intussen naar een buur (CTA/eindkaart) hebben verlegd omdat de slide-hoogte verandert.
            var target = _rotTarget || active;
            _rotTarget = null;
            if (!target || !target.classList.contains('reel-clip')) { document.body.classList.remove('rot-clip'); return; }   // CTA/reel actief -> overlay mag blijven
            if (active !== target) { activate(target); }   // active hersteld naar de bedoelde clip
            try { target.scrollIntoView(); } catch (e) {}   // en terug in beeld (anders is de scroll verdrift)
            _preRotateClip = target;   // onthoud de bekeken clip voor de terugkeer naar portrait
            var v = target.querySelector('video');
            if (!v) { return; }
            v.controls = true;         // fullscreen: native controls (tijdlijn/duur) aan
            try {
                if (v.requestFullscreen) { v.requestFullscreen(); }
                else if (v.webkitEnterFullscreen) { v.webkitEnterFullscreen(); }   // iOS Safari (<video> only)
                else if (v.webkitRequestFullscreen) { v.webkitRequestFullscreen(); }
            } catch (e) {}
        } else {
            document.body.classList.remove('rot-clip');   // terug in portrait -> opruimen
            Array.prototype.forEach.call(feed.querySelectorAll('.rot-fill'), function (n) { n.classList.remove('rot-fill'); });
            var pc = _preRotateClip; _preRotateClip = null;
            var pv = pc ? pc.querySelector('video') : null;
            if (pv) { pv.controls = false; }   // controls uit -> overlays weer zichtbaar
            // Portrait: fullscreen sluiten -> terug in de FapReel-viewer.
            try {
                if (document.exitFullscreen && document.fullscreenElement) { document.exitFullscreen(); }
                else if (document.webkitExitFullscreen && document.webkitFullscreenElement) { document.webkitExitFullscreen(); }
            } catch (e) {}
            // iOS: video ging fullscreen via webkitEnterFullscreen (buiten de Fullscreen API) -> apart sluiten.
            var vids = feed.querySelectorAll('.reel-clip video');
            for (var i = 0; i < vids.length; i++) {
                if (vids[i].webkitDisplayingFullscreen && vids[i].webkitExitFullscreen) {
                    try { vids[i].webkitExitFullscreen(); } catch (e) {}
                }
            }
            // Scroll de bekeken clip weer in beeld: na de oriëntatie-herberekening drift de scroll-snap
            // anders weg (soms naar de eindkaart). Even later zodat de layout gesetteld is.
            if (pc) { setTimeout(function () { pc.scrollIntoView(); activate(pc); }, 60); }
        }
    }
    // Bij een oriëntatiesignaal: leg METEEN (synchroon, vóór de reflow/observer) de bedoelde clip vast,
    // en voer de fullscreen-logica gedebounced uit zodat de layout eerst settelt.
    function onRotate() {
        _rotTarget = active;
        _rotating = true;   // bevries de observer -> active blijft op deze clip (geen unloadFar/herstart tijdens de reflow)
        // Onderdruk de portrait-overlay EN laat de bedoelde clip METEEN fullscreen vullen (synchroon, vóór de
        // reflow waarin `active` even naar een buur/CTA kan verspringen) -> geen flits van overlay of kleine viewer.
        Array.prototype.forEach.call(feed.querySelectorAll('.rot-fill'), function (n) { n.classList.remove('rot-fill'); });
        var onClip = !!(active && active.classList.contains('reel-clip'));
        document.body.classList.toggle('rot-clip', onClip);
        if (onClip) { active.classList.add('rot-fill'); }
        if (_rotTimer) { clearTimeout(_rotTimer); }
        _rotTimer = setTimeout(function () { _rotTimer = null; clipLandscapeFullscreen(); }, 250);
        if (_rotClear) { clearTimeout(_rotClear); }
        _rotClear = setTimeout(function () { _rotating = false; }, 600);   // observer weer vrij als alles gesetteld is
    }
    window.addEventListener('orientationchange', onRotate);
    if (window.matchMedia) {
        var mq = window.matchMedia('(orientation: landscape)');
        try { mq.addEventListener('change', onRotate); }
        catch (e) { try { mq.addListener(onRotate); } catch (e2) {} }
    }
    // Bij verlaten van fullscreen: clip-controls weer uit -> in portrait weer de overlays zichtbaar.
    function onFsChange() {
        if (!(document.fullscreenElement || document.webkitFullscreenElement)) {
            var vids = feed.querySelectorAll('.reel-clip video');
            for (var i = 0; i < vids.length; i++) { vids[i].controls = false; }
        }
    }
    document.addEventListener('fullscreenchange', onFsChange);
    document.addEventListener('webkitfullscreenchange', onFsChange);

    function activateFirst() { var f = feed.querySelector('.reel:not(.reel-end)'); if (f) { activate(f); } }
    function seekTo(id) {
        var el = document.getElementById(id);
        if (el && el.classList.contains('reel') && !el.classList.contains('reel-end')) {
            requestAnimationFrame(function () { el.scrollIntoView(); activate(el); });
        } else if (cfg.offset < cfg.total) { loadMore(function () { seekTo(id); }); }
        else { activateFirst(); }
    }
    // Id-lijst-viewers (mostfav/mostpopular/favorites) starten met alleen de eindkaart; verberg
    // die + toon een spinner tot de eerste reel (of de gezochte #reel-deeplink) geladen en actief
    // is. Voorkomt dat "You are all caught up" kort flitst voordat de reel laadt.
    if (cfg.total > 0 && !feed.querySelector('.reel:not(.reel-end)')) { feed.classList.add('is-loading'); }
    var targetId = /^#reel-\d+$/.test(location.hash) ? location.hash.slice(1) : null;
    if (targetId) {
        seekTo(targetId);
    } else {
        // Geen reel-deeplink: land direct op de EERSTE reel, voorbij het hub-head-blok (H1 +
        // stats) - geen "marketing-swipe" meer bij binnenkomst. De header blijft in de DOM
        // (crawlbaar voor Google) en blijft bereikbaar door omhoog te swipen. (#start kwam van
        // de age-gate-keuze; ditzelfde gedrag geldt nu op elke gewone load.)
        var f0 = feed.querySelector('.reel:not(.reel-end)');
        if (f0) { requestAnimationFrame(function () { f0.scrollIntoView(); activate(f0); }); }
        else if (cfg.mode === 'fav' || cfg.mode === 'pop') { loadMore(function () { activateFirst(); }); }   // id-lijst-viewer: eerst laden
        else { activateFirst(); }
    }
    reflectAuto();   // begintoestand van de auto-advance-toggle (onthouden uit localStorage)
    reflectLikes();  // begintoestand van de like-hartjes (onthouden uit localStorage)
    reflectFavs();   // begintoestand van de favorite-plusjes (onthouden uit localStorage)
    sfwBoot();       // soft-modus: SFW-reels vooraan + tussenmengen (client-side, alleen soft-verkeer)

    // Eenmalige "Tap for sound"-hint naast de mute-knop: geluid zit nu op die knop (tikken op de
    // reel pauzeert). 1x per bezoeker, verdwijnt na ~5,5s of bij de eerste tap.
    (function () {
        var SK = 'fr_sound_hint', seen = false;
        try { seen = !!localStorage.getItem(SK); } catch (e) {}
        if (seen) { return; }
        var host = feed.querySelector('.reel:not(.reel-end) .reel-inner');
        if (!host) { return; }
        var el = document.createElement('div');
        el.className = 'sound-hint';
        el.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="11 5 6 9 2 9 2 15 6 15 11 19 11 5" fill="currentColor" stroke="none"></polygon><path d="M15.5 8.5a5 5 0 0 1 0 7"></path><path d="M18.8 6a9 9 0 0 1 0 12"></path></svg><span>Tap for sound</span>';
        host.appendChild(el);
        requestAnimationFrame(function () { if (el) { el.classList.add('show'); } });
        var kill = function () {
            if (!el) { return; }
            try { localStorage.setItem(SK, '1'); } catch (e) {}
            feed.removeEventListener('click', kill);
            var h = el; el = null;
            h.classList.remove('show');
            setTimeout(function () { if (h.parentNode) { h.parentNode.removeChild(h); } }, 400);
        };
        setTimeout(kill, 5500);
        feed.addEventListener('click', kill);
    })();

    // Swipe-hint op de eerste reel (alleen home): 1x per bezoeker, ~3s of tot de eerste scroll.
    var hint = document.getElementById('swipe-hint');
    if (hint) {
        var HK = 'fr_swipe_hint', seen = false;
        try { seen = !!localStorage.getItem(HK); } catch (e) {}
        if (seen) {
            if (hint.parentNode) { hint.parentNode.removeChild(hint); }
        } else {
            requestAnimationFrame(function () { if (hint) { hint.classList.add('show'); } });
            var killHint = function () {
                if (!hint) { return; }
                try { localStorage.setItem(HK, '1'); } catch (e) {}
                feed.removeEventListener('scroll', killHint);
                var h = hint; hint = null;
                h.classList.remove('show');
                setTimeout(function () { if (h.parentNode) { h.parentNode.removeChild(h); } }, 500);
            };
            setTimeout(killHint, 4500);
            feed.addEventListener('scroll', killHint, { passive: true });
        }
    }
})();

/* Hub-intro: op mobiel max 5 regels + Read more/less. Meet eerst de volle hoogte, her-meet na
   fonts/load; knop verschijnt alleen als de tekst echt buiten 5 regels valt (los van de reels-engine). */
(function () {
    var intro = document.querySelector('.hub-intro');
    if (!intro || intro.classList.contains('hub-intro-x') || !window.matchMedia) { return; }
    var mq = window.matchMedia('(max-width: 700px)');
    var btn = document.createElement('button');
    btn.type = 'button'; btn.className = 'hub-intro-more'; btn.textContent = 'Read more';
    intro.insertAdjacentElement('afterend', btn);
    function setup() {
        btn.classList.remove('is-visible');
        intro.classList.remove('is-clamped');
        btn.textContent = 'Read more';
        if (!mq.matches) { return; }
        var full = intro.scrollHeight;
        intro.classList.add('is-clamped');
        if (full - intro.clientHeight > 4) { btn.classList.add('is-visible'); }
        else { intro.classList.remove('is-clamped'); }
    }
    btn.addEventListener('click', function () {
        var clamped = intro.classList.toggle('is-clamped');
        btn.textContent = clamped ? 'Read more' : 'Read less';
    });
    setup();
    if (document.fonts && document.fonts.ready) { document.fonts.ready.then(setup); }
    window.addEventListener('load', setup);
    if (mq.addEventListener) { mq.addEventListener('change', setup); }
    else if (mq.addListener) { mq.addListener(setup); }
})();
