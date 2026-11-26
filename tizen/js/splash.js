/* Pure ES5 5-Second Splash Controller with Square-to-Circle Logo Morph */
(function (root) {
  'use strict';

  var DURATION_MS = 5000;
  var finished = false;
  var rafId = null;
  var timerId = null;

  function easeInOutCubic(x) {
    return x < 0.5 ? 4 * x * x * x : 1 - Math.pow(-2 * x + 2, 3) / 2;
  }

  function statusFor(p) {
    if (p < 0.28) return 'Đang khởi động YumiHub TV…';
    if (p < 0.55) return 'Đang nạp thư viện Phim & Điện ảnh…';
    if (p < 0.82) return 'Đang chuẩn bị trình phát & điều khiển TV…';
    return 'Sẵn sàng';
  }

  function start(onDone) {
    var screen = document.getElementById('splash-screen');
    var logoWrap = document.getElementById('splash-logo-wrap');
    var logoImg = document.getElementById('splash-logo-img');
    var fill = document.getElementById('splash-progress-fill');
    var statusEl = document.getElementById('splash-status');
    var skipBtn = document.getElementById('splash-skip-btn');

    function finish() {
      if (finished) return;
      finished = true;
      if (rafId && typeof root.cancelAnimationFrame === 'function') {
        root.cancelAnimationFrame(rafId);
      }
      if (timerId) clearTimeout(timerId);
      if (screen) screen.className = 'splash-screen is-hidden';
      if (typeof onDone === 'function') onDone();
    }

    if (skipBtn) {
      skipBtn.addEventListener('click', finish);
      if (root.YumiRemote) root.YumiRemote.setFocus(skipBtn);
    }

    var startTime = Date.now();

    function frame() {
      if (finished) return;
      var elapsed = Date.now() - startTime;
      var t = Math.min(1, elapsed / DURATION_MS);

      // Morph tu hinh vuong (0px) sang hinh tron (50%) trong khoang t = 0.08..0.45
      var morphT = Math.min(1, Math.max(0, (t - 0.08) / 0.37));
      var eased = easeInOutCubic(morphT);
      if (logoWrap) {
        logoWrap.style.borderRadius = (50 * eased).toFixed(2) + '%';
      }
      if (logoImg) {
        logoImg.style.transform = 'scale(' + (1 + 0.12 * eased).toFixed(3) + ')';
      }

      if (fill) {
        fill.style.width = Math.round(t * 100) + '%';
      }
      if (statusEl) {
        statusEl.textContent = statusFor(t);
      }

      if (t >= 1) {
        finish();
      } else if (typeof root.requestAnimationFrame === 'function') {
        rafId = root.requestAnimationFrame(frame);
      }
    }

    if (typeof root.requestAnimationFrame === 'function') {
      rafId = root.requestAnimationFrame(frame);
    }
    timerId = setTimeout(finish, DURATION_MS + 60);

    return { finish: finish };
  }

  root.YumiSplash = {
    start: start
  };
})(window);
