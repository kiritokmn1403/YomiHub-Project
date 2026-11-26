/* Pure ES5 Samsung TV Remote & PC Keyboard Navigation */
(function (root) {
  'use strict';

  var currentFocused = null;
  var handlers = {
    onBack: null,
    onPlayPause: null,
    onRewind: null,
    onFastForward: null,
    onStop: null,
    onColorKey: null,
    onSplashSkip: null
  };

  function registerTvKeys() {
    try {
      if (typeof root.tizen !== 'undefined' && root.tizen.tvinputdevice) {
        // Phim he thong: Return (10009), D-pad (37-40), Enter (13) duoc TV tu dong gui, khong can registerKey.
        var keys = [
          'MediaPlayPause',
          'MediaPlay',
          'MediaPause',
          'MediaStop',
          'MediaRewind',
          'MediaFastForward',
          'ColorF0Red',
          'ColorF1Green',
          'ColorF2Yellow',
          'ColorF3Blue'
        ];
        if (typeof root.tizen.tvinputdevice.registerKeyBatch === 'function') {
          try {
            root.tizen.tvinputdevice.registerKeyBatch(keys);
            return;
          } catch (eBatch) {}
        }
        if (typeof root.tizen.tvinputdevice.registerKey === 'function') {
          var i;
          for (i = 0; i < keys.length; i++) {
            try {
              root.tizen.tvinputdevice.registerKey(keys[i]);
            } catch (eKey) {}
          }
        }
      }
    } catch (e) {}
  }

  function isVisible(el) {
    if (!el) return false;
    if (el.offsetParent === null && el.style.position !== 'fixed') return false;
    var rect = el.getBoundingClientRect();
    return rect.width > 0 && rect.height > 0;
  }

  function getFocusableElements() {
    var all = document.querySelectorAll('[data-focusable="true"]');
    var splash = document.getElementById('splash-screen');
    var player = document.getElementById('view-player');
    var splashOpen = splash && splash.className.indexOf('is-hidden') === -1;
    var playerOpen = player && player.className.indexOf('is-hidden') === -1;

    var list = [];
    var i;
    for (i = 0; i < all.length; i++) {
      var el = all[i];
      var zone = el.getAttribute('data-zone') || '';
      if (splashOpen && zone !== 'splash') continue;
      if (!splashOpen && playerOpen && zone !== 'player') continue;
      if (!splashOpen && !playerOpen && (zone === 'splash' || zone === 'player')) continue;
      if (isVisible(el)) {
        list.push(el);
      }
    }
    return list;
  }

  function setFocus(el) {
    if (!el) return;
    if (currentFocused && currentFocused !== el) {
      currentFocused.className = currentFocused.className.replace(/\bis-focused\b/g, '').replace(/\s+/g, ' ').trim();
    }
    currentFocused = el;
    if (el.className.indexOf('is-focused') === -1) {
      el.className = (el.className + ' is-focused').trim();
    }
    try {
      el.focus();
      if (typeof el.scrollIntoView === 'function') {
        el.scrollIntoView({ block: 'nearest', inline: 'nearest' });
      }
    } catch (e) {}
  }

  function focusFirst(preferredZone) {
    var list = getFocusableElements();
    if (!list.length) return;
    if (preferredZone) {
      var i;
      for (i = 0; i < list.length; i++) {
        if (list[i].getAttribute('data-zone') === preferredZone) {
          setFocus(list[i]);
          return;
        }
      }
    }
    setFocus(list[0]);
  }

  function moveSpatial(dir) {
    var list = getFocusableElements();
    if (!list.length) return;
    if (!currentFocused || list.indexOf(currentFocused) === -1) {
      setFocus(list[0]);
      return;
    }

    var curRect = currentFocused.getBoundingClientRect();
    var cx = curRect.left + curRect.width / 2;
    var cy = curRect.top + curRect.height / 2;

    var best = null;
    var bestScore = 1e12;
    var i;

    for (i = 0; i < list.length; i++) {
      var cand = list[i];
      if (cand === currentFocused) continue;
      var r = cand.getBoundingClientRect();
      var tx = r.left + r.width / 2;
      var ty = r.top + r.height / 2;
      var dx = tx - cx;
      var dy = ty - cy;

      var valid = false;
      var primary = 0;
      var secondary = 0;

      if (dir === 'left' && dx < -8) {
        valid = true;
        primary = -dx;
        secondary = Math.abs(dy);
      } else if (dir === 'right' && dx > 8) {
        valid = true;
        primary = dx;
        secondary = Math.abs(dy);
      } else if (dir === 'up' && dy < -8) {
        valid = true;
        primary = -dy;
        secondary = Math.abs(dx);
      } else if (dir === 'down' && dy > 8) {
        valid = true;
        primary = dy;
        secondary = Math.abs(dx);
      }

      if (!valid) continue;
      var score = primary + secondary * 2.4;
      if (score < bestScore) {
        bestScore = score;
        best = cand;
      }
    }

    if (best) {
      setFocus(best);
    }
  }

  function isTypingInInput(target) {
    if (!target) return false;
    var tag = (target.tagName || '').toUpperCase();
    return tag === 'INPUT' || tag === 'TEXTAREA';
  }

  function onKeyDown(ev) {
    var code = ev.keyCode || ev.which || 0;
    var target = ev.target || document.activeElement;
    var typing = isTypingInInput(target);

    // Man cho 5 giay: Enter/OK bo qua nhanh
    var splash = document.getElementById('splash-screen');
    if (splash && splash.className.indexOf('is-hidden') === -1) {
      if (code === 13 || code === 32) {
        ev.preventDefault();
        if (typeof handlers.onSplashSkip === 'function') handlers.onSplashSkip();
      }
      return;
    }

    if (root.YumiPlayer && root.YumiPlayer.isOpen()) {
      root.YumiPlayer.showOsd();
    }

    // Back: Tizen Return (10009, phim he thong), Escape 27, Backspace 8 (khi khong go input)
    if (code === 10009 || code === 27 || (code === 8 && !typing)) {
      ev.preventDefault();
      if (typeof handlers.onBack === 'function') handlers.onBack();
      return;
    }

    // 4 phim mau Samsung TV: ColorF0Red (403), ColorF1Green (404), ColorF2Yellow (405), ColorF3Blue (406)
    if (code === 403 || code === 404 || code === 405 || code === 406) {
      ev.preventDefault();
      var colorName = 'red';
      if (code === 404) colorName = 'green';
      else if (code === 405) colorName = 'yellow';
      else if (code === 406) colorName = 'blue';
      if (typeof handlers.onColorKey === 'function') {
        handlers.onColorKey(colorName, code);
      }
      return;
    }

    // Phim Media TV + PC: Play/Pause (415, 19, 10252, Space 32, P 80)
    if (code === 415 || code === 19 || code === 10252 || ((code === 32 || code === 80) && !typing)) {
      if (root.YumiPlayer && root.YumiPlayer.isOpen()) {
        ev.preventDefault();
        if (typeof handlers.onPlayPause === 'function') handlers.onPlayPause();
        return;
      }
    }

    // Rewind (412, J 74)
    if (code === 412 || (code === 74 && !typing)) {
      if (root.YumiPlayer && root.YumiPlayer.isOpen()) {
        ev.preventDefault();
        if (typeof handlers.onRewind === 'function') handlers.onRewind();
        return;
      }
    }

    // FastForward (417, L 76)
    if (code === 417 || (code === 76 && !typing)) {
      if (root.YumiPlayer && root.YumiPlayer.isOpen()) {
        ev.preventDefault();
        if (typeof handlers.onFastForward === 'function') handlers.onFastForward();
        return;
      }
    }

    // Stop (413, S 83)
    if (code === 413 || (code === 83 && !typing)) {
      if (root.YumiPlayer && root.YumiPlayer.isOpen()) {
        ev.preventDefault();
        if (typeof handlers.onStop === 'function') handlers.onStop();
        return;
      }
    }

    // Phim mui ten D-pad
    if (code === 37) {
      if (typing) return;
      ev.preventDefault();
      moveSpatial('left');
      return;
    }
    if (code === 38) {
      ev.preventDefault();
      moveSpatial('up');
      return;
    }
    if (code === 39) {
      if (typing) return;
      ev.preventDefault();
      moveSpatial('right');
      return;
    }
    if (code === 40) {
      ev.preventDefault();
      moveSpatial('down');
      return;
    }

    // Enter / OK
    if (code === 13) {
      if (currentFocused && isVisible(currentFocused)) {
        ev.preventDefault();
        currentFocused.click();
      }
    }
  }

  function init(opts) {
    opts = opts || {};
    handlers.onBack = opts.onBack || null;
    handlers.onPlayPause = opts.onPlayPause || null;
    handlers.onRewind = opts.onRewind || null;
    handlers.onFastForward = opts.onFastForward || null;
    handlers.onStop = opts.onStop || null;
    handlers.onColorKey = opts.onColorKey || null;
    handlers.onSplashSkip = opts.onSplashSkip || null;

    registerTvKeys();
    document.addEventListener('keydown', onKeyDown);
  }

  root.YumiRemote = {
    init: init,
    setFocus: setFocus,
    focusFirst: focusFirst,
    moveSpatial: moveSpatial
  };
})(window);
