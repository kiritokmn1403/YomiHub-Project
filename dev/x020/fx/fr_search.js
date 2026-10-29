/* FapReel search: icon toggelt een dropdown onder de balk, live suggesties
   (niches/modellen/studio's) via /search.php; klik/Enter gaat naar /reels/<slug>
   (dat toont direct de nieuwste reel). */
(function () {
    var st    = document.getElementById('search-toggle'),
        panel = document.getElementById('search-panel'),
        input = document.getElementById('search-input'),
        list  = document.getElementById('search-suggest');
    if (!st || !panel || !input || !list) { return; }

    function esc(s) { return String(s).replace(/[&<>"]/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]; }); }

    var timer, items = [], active = -1, logged = '';

    // Logt de UITGETYPTE (settled) query, niet elke toetsaanslag: pas na een pauze of bij commit.
    function logSearch(q) {
        q = (q || '').trim();
        if (q.length < 2 || q === logged) { return; }
        logged = q;
        // keepalive: request overleeft de navigatie bij een suggestie-klik/Enter.
        try { fetch('/search.php?q=' + encodeURIComponent(q) + '&log=1', { cache: 'no-store', keepalive: true }); } catch (e) {}
    }

    function open() { panel.hidden = false; st.setAttribute('aria-expanded', 'true'); setTimeout(function () { input.focus(); }, 30); }
    function close() { panel.hidden = true; st.setAttribute('aria-expanded', 'false'); }
    st.addEventListener('click', function () { panel.hidden ? open() : close(); });

    function render(res) {
        items = res || []; active = -1;
        if (!items.length) { list.innerHTML = ''; list.hidden = true; return; }
        list.innerHTML = items.map(function (e) {
            var href, typeLabel;
            if (e.t === 'modelniche') {                                   // model + niche -> /reels/<model>?sub=<niche>
                href = '/reels/' + encodeURIComponent(e.s) + '/' + encodeURIComponent(e.sub || '');   // padvorm = canonical
                typeLabel = 'model + niche';
            } else {
                href = (e.t === 'creator' ? '/reels/creator/' : '/reels/') + encodeURIComponent(e.s);
                typeLabel = e.t;
            }
            var cnt = e.c ? '<span class="s-count">' + Number(e.c).toLocaleString() + ' reels</span>' : '';
            return '<li role="option"><a href="' + href +
                   '"><span class="s-name">' + esc(e.n) + '</span>' + cnt + '<span class="s-type">' + esc(typeLabel) + '</span></a></li>';
        }).join('');
        list.hidden = false;
    }
    function highlight() { for (var i = 0; i < list.children.length; i++) { list.children[i].classList.toggle('is-active', i === active); } }

    input.addEventListener('input', function () {
        var q = input.value.trim();
        clearTimeout(timer);
        if (q.length < 2) { render([]); return; }
        timer = setTimeout(function () {
            fetch('/search.php?q=' + encodeURIComponent(q))
                .then(function (r) { return r.json(); })
                .then(render)
                .catch(function () {});
        }, 140);
        // Bewust GEEN logging tijdens typen: alleen op Enter of suggestie-klik (zie onder).
    });
    input.addEventListener('keydown', function (e) {
        if (e.key === 'ArrowDown') { e.preventDefault(); if (items.length) { active = (active + 1) % items.length; highlight(); } }
        else if (e.key === 'ArrowUp') { e.preventDefault(); if (items.length) { active = (active - 1 + items.length) % items.length; highlight(); } }
        else if (e.key === 'Enter') { e.preventDefault(); var idx = active >= 0 ? active : 0; var a = list.children[idx] && list.children[idx].querySelector('a'); if (a && items[idx]) { logSearch(items[idx].n); location.href = a.getAttribute('href'); } }
        else if (e.key === 'Escape') { close(); }
    });

    // Klik op een suggestie: log de GEKOZEN naam (canonieke term), niet de half-getypte query.
    list.addEventListener('click', function (e) {
        var li = e.target.closest ? e.target.closest('li') : null;
        if (!li) { return; }
        var idx = Array.prototype.indexOf.call(list.children, li);
        if (idx >= 0 && items[idx]) { logSearch(items[idx].n); }
    });

    document.addEventListener('click', function (e) {
        if (panel.hidden) { return; }
        if (e.target === st || st.contains(e.target) || panel.contains(e.target)) { return; }
        close();
    });
})();
