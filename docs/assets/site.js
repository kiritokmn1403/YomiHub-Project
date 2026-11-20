/**
 * YomiHub Website JavaScript (Multilingual vi/en)
 * Handles:
 * - Language Dictionary & Strings
 * - Language Switcher with Anchor Preservation & localStorage Preference
 * - First-time English Suggestion Banner
 * - Table of Contents, Diacritic-insensitive Search, and Scrollspy for Hướng Dẫn (guide.html)
 * - Device Detection, Quick Jump, SHA-256 Copy, and Release Updater for Tải Về (download.html)
 */

const I18N = {
  vi: {
    searchPlaceholder: 'Tìm trong hướng dẫn…',
    searchNoResults: 'Không có chương nào khớp. Thử từ khóa khác, ví dụ: <code>tor</code>, <code>sao lưu</code>, <code>bộ lọc</code>.',
    copySha: 'Chép',
    copiedSha: 'Đã chép!',
    deviceRec: '✨ Gợi ý cho bạn',
    versionPrefix: 'Phiên bản ',
    dlTitlePrefix: 'Tải ',
    bannerText: 'This page is also available in English · ',
    bannerAction: 'Switch to English',
    dismissAria: 'Đóng thông báo'
  },
  en: {
    searchPlaceholder: 'Search the guide…',
    searchNoResults: 'No chapters match. Try a different search, such as <code>tor</code>, <code>backup</code>, <code>filter</code>.',
    copySha: 'Copy',
    copiedSha: 'Copied!',
    deviceRec: '✨ Suggested for you',
    versionPrefix: 'Version ',
    dlTitlePrefix: 'Download ',
    bannerText: 'Trang này cũng có bản tiếng Việt · ',
    bannerAction: 'Chuyển sang Tiếng Việt',
    dismissAria: 'Dismiss notification'
  }
};

/**
 * Get active language from <html lang="...">
 */
function getLang() {
  const docLang = (document.documentElement.lang || 'vi').toLowerCase();
  return docLang.startsWith('en') ? 'en' : 'vi';
}

/**
 * Translate string helper
 */
function t(key) {
  const lang = getLang();
  return (I18N[lang] && I18N[lang][key]) || I18N.vi[key] || '';
}

document.addEventListener('DOMContentLoaded', () => {
  initLanguageSwitcher();
  initSuggestionBanner();
  initGuideFeatures();
  initDownloadFeatures();
  initReleaseUpdater();
});

/**
 * 1. Language Switcher:
 * - Preserves #hash anchor when switching languages
 * - Saves user language preference to localStorage['yh-lang']
 */
function initLanguageSwitcher() {
  const switchContainer = document.querySelector('.lang-switch');
  if (!switchContainer) return;

  const links = switchContainer.querySelectorAll('.lang-opt');
  links.forEach((link) => {
    link.addEventListener('click', (e) => {
      const targetLang = link.getAttribute('lang') || (link.getAttribute('hreflang') === 'en' ? 'en' : 'vi');
      try {
        localStorage.setItem('yh-lang', targetLang);
      } catch (_) {}

      // Preserve hash anchor on navigation
      const currentHash = window.location.hash;
      if (currentHash) {
        const currentHref = link.getAttribute('href') || '';
        const baseHref = currentHref.split('#')[0];
        link.setAttribute('href', baseHref + currentHash);
      }
    });
  });
}

/**
 * 2. Suggestion Banner:
 * If user visits Vietnamese page, has no stored language preference, and navigator.language starts with 'en' ->
 * Display a subtle banner: "This page is also available in English · [Switch to English]" (with dismiss button)
 */
function initSuggestionBanner() {
  if (getLang() !== 'vi') return;

  let storedLang = null;
  try {
    storedLang = localStorage.getItem('yh-lang');
  } catch (_) {}

  // Only show if user has not explicitly made a language choice yet
  if (storedLang) return;

  const navLang = (navigator.language || navigator.userLanguage || '').toLowerCase();
  if (!navLang.startsWith('en')) return;

  const enOpt = document.querySelector('.lang-opt[hreflang="en"]');
  if (!enOpt) return;

  const baseEnHref = enOpt.getAttribute('href') || 'en/index.html';
  const targetHref = baseEnHref.split('#')[0] + (window.location.hash || '');

  const banner = document.createElement('aside');
  banner.className = 'lang-suggestion-banner';
  banner.setAttribute('role', 'status');
  banner.innerHTML = `
    <span>${t('bannerText')}</span>
    <a href="${targetHref}" class="lang-suggestion-action">${t('bannerAction')}</a>
    <button type="button" class="lang-suggestion-close" aria-label="${t('dismissAria')}">&times;</button>
  `;

  // Attach action and close handlers
  const actionLink = banner.querySelector('.lang-suggestion-action');
  if (actionLink) {
    actionLink.addEventListener('click', () => {
      try {
        localStorage.setItem('yh-lang', 'en');
      } catch (_) {}
    });
  }

  const closeBtn = banner.querySelector('.lang-suggestion-close');
  if (closeBtn) {
    closeBtn.addEventListener('click', () => {
      banner.remove();
      try {
        localStorage.setItem('yh-lang', 'vi');
      } catch (_) {}
    });
  }

  // Insert banner right below banner band
  const bannerBand = document.querySelector('.banner-band');
  if (bannerBand && bannerBand.nextSibling) {
    bannerBand.parentNode.insertBefore(banner, bannerBand.nextSibling);
  } else {
    document.body.insertBefore(banner, document.body.firstChild);
  }
}

/**
 * Remove Vietnamese accents/diacritics for smart fuzzy search
 */
function stripDiacritics(str) {
  if (!str) return '';
  return str
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/đ/g, 'd')
    .replace(/Đ/g, 'D')
    .toLowerCase()
    .trim();
}

/**
 * 3. Guide (Hướng Dẫn) TOC, Live Search, and Scrollspy
 */
function initGuideFeatures() {
  const guideMain = document.getElementById('guide');
  if (!guideMain) return;

  const chapters = Array.from(guideMain.querySelectorAll('section.chapter'));
  if (chapters.length === 0) return;

  const desktopTocList = document.getElementById('toc-list');
  const mobileTocList = document.getElementById('toc-list-mobile');
  const searchInput = document.getElementById('guide-search');
  const noResultsEl = document.getElementById('guide-no-results');

  // Set localized placeholder and no-results message
  document.querySelectorAll('.guide-search-input').forEach((inp) => {
    inp.placeholder = t('searchPlaceholder');
  });
  if (noResultsEl) {
    noResultsEl.innerHTML = t('searchNoResults');
  }

  // Build Table of Contents
  chapters.forEach((chapter) => {
    const id = chapter.id;
    const h2 = chapter.querySelector('h2');
    if (!id || !h2) return;

    const titleText = h2.textContent.trim();

    if (desktopTocList) {
      const li = document.createElement('li');
      const a = document.createElement('a');
      a.href = '#' + id;
      a.className = 'toc-link';
      a.textContent = titleText;
      a.dataset.targetId = id;
      li.appendChild(a);
      desktopTocList.appendChild(li);
    }

    if (mobileTocList) {
      const li = document.createElement('li');
      const a = document.createElement('a');
      a.href = '#' + id;
      a.className = 'toc-link';
      a.textContent = titleText;
      a.dataset.targetId = id;
      li.appendChild(a);
      mobileTocList.appendChild(li);
    }
  });

  // Active Chapter Highlight via IntersectionObserver
  if ('IntersectionObserver' in window && desktopTocList) {
    const tocLinks = desktopTocList.querySelectorAll('.toc-link');
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            const id = entry.target.id;
            tocLinks.forEach((link) => {
              if (link.dataset.targetId === id) {
                link.classList.add('active');
              } else {
                link.classList.remove('active');
              }
            });
          }
        });
      },
      {
        rootMargin: '-10% 0px -75% 0px',
        threshold: 0
      }
    );

    chapters.forEach((chapter) => observer.observe(chapter));
  }

  // Live Search with diacritic-insensitive matching
  if (searchInput) {
    searchInput.addEventListener('input', (e) => {
      const query = stripDiacritics(e.target.value);
      let matchCount = 0;

      chapters.forEach((chapter) => {
        const text = stripDiacritics(chapter.textContent);
        const keywords = stripDiacritics(chapter.getAttribute('data-keywords') || '');

        const isMatch = !query || text.includes(query) || keywords.includes(query);

        if (isMatch) {
          chapter.style.display = '';
          matchCount++;
        } else {
          chapter.style.display = 'none';
        }
      });

      if (noResultsEl) {
        noResultsEl.style.display = matchCount === 0 ? 'block' : 'none';
      }
    });
  }
}

/**
 * 4. Download Page (download.html) Features:
 * - Device Detection and highlighting
 * - Copy SHA-256 to clipboard
 */
function initDownloadFeatures() {
  const downloadMain = document.getElementById('download');
  if (!downloadMain) return;

  // 1. Device detection & recommendation
  const ua = navigator.userAgent || '';
  let targetGroupId = null;

  if (/Windows NT/i.test(ua)) {
    targetGroupId = 'windows';
  } else if (/Android/i.test(ua)) {
    if (/Android 6(\.0)?/i.test(ua)) {
      targetGroupId = 'android6';
    } else if (/(Android TV|GoogleTV|LargeScreen)/i.test(ua)) {
      targetGroupId = 'tv';
    } else {
      targetGroupId = 'android';
    }
  }

  if (targetGroupId) {
    const quickBtn = document.querySelector(`.quick-btn[href="#${targetGroupId}"]`);
    if (quickBtn && !quickBtn.querySelector('.device-badge')) {
      quickBtn.classList.add('recommended');
      const badge = document.createElement('span');
      badge.className = 'device-badge';
      badge.textContent = t('deviceRec');
      quickBtn.appendChild(badge);
    }

    const groupEl = document.getElementById(targetGroupId);
    if (groupEl) {
      groupEl.classList.add('highlighted');
    }
  }

  // 2. Copy SHA-256 button
  downloadMain.addEventListener('click', (e) => {
    const btn = e.target.closest('.btn-copy');
    if (!btn) return;

    const sha = btn.dataset.copy || '';
    if (!sha) return;

    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(sha).then(() => {
        showCopiedState(btn);
      }).catch(() => {
        fallbackCopy(sha, btn);
      });
    } else {
      fallbackCopy(sha, btn);
    }
  });

  function showCopiedState(button) {
    const originalText = button.textContent;
    button.textContent = t('copiedSha');
    button.classList.add('copied');
    setTimeout(() => {
      button.textContent = originalText;
      button.classList.remove('copied');
    }, 1500);
  }

  function fallbackCopy(text, button) {
    const ta = document.createElement('textarea');
    ta.value = text;
    ta.style.position = 'fixed';
    ta.style.opacity = '0';
    document.body.appendChild(ta);
    ta.select();
    try {
      document.execCommand('copy');
      showCopiedState(button);
    } catch (_) {}
    document.body.removeChild(ta);
  }
}

/**
 * 5. Automatic Release Link Updater from GitHub Releases API
 * Keeps existing links if GitHub API fails or is rate-limited
 */
function initReleaseUpdater() {
  const verEl = document.getElementById('ver');
  const dlLinks = document.querySelectorAll('a.dl[data-pat]');
  if (!verEl && dlLinks.length === 0) return;

  fetch('https://api.github.com/repos/kiritokmn1403/YomiHub-Project/releases/latest')
    .then((res) => (res.ok ? res.json() : null))
    .then((release) => {
      if (!release || !release.tag_name) return;
      const v = release.tag_name.replace(/^v/, '');
      const assetNames = new Set((release.assets || []).map((a) => a.name));
      let updatedCount = 0;

      dlLinks.forEach((a) => {
        const pattern = a.dataset.pat;
        if (!pattern) return;
        const filename = pattern.replace('{v}', v);
        if (assetNames.has(filename)) {
          a.href = `https://github.com/kiritokmn1403/YomiHub-Project/releases/download/${release.tag_name}/${filename}`;
          a.title = t('dlTitlePrefix') + filename;
          updatedCount++;
        }
      });

      if (updatedCount > 0 && verEl) {
        verEl.textContent = t('versionPrefix') + v;
      }
    })
    .catch(() => {
      // Silent catch; keep current fallback links
    });
}
