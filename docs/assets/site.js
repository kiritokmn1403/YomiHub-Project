/**
 * YomiHub Website JavaScript
 * Handles:
 * - Table of Contents, Diacritic-insensitive Search, and Scrollspy for Hướng Dẫn (guide.html)
 * - Device Detection, Quick Jump, SHA-256 Copy, and Release Updater for Tải Về (download.html)
 */

document.addEventListener('DOMContentLoaded', () => {
  initGuideFeatures();
  initDownloadFeatures();
  initReleaseUpdater();
});

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
 * Initialize Guide (Hướng Dẫn) TOC, Live Search, and Scrollspy
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

  // 1. Build Table of Contents
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

  // 2. Active Chapter Highlight via IntersectionObserver
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

  // 3. Live Search with diacritic-insensitive matching
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
 * Initialize Download Page (download.html) Features:
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
      badge.textContent = '✨ Gợi ý cho bạn';
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
    button.textContent = 'Đã chép!';
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
 * Automatic Release Link Updater from GitHub Releases API
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
          a.title = 'Tải ' + filename;
          updatedCount++;
        }
      });

      if (updatedCount > 0 && verEl) {
        verEl.textContent = 'Phiên bản ' + v;
      }
    })
    .catch(() => {
      // Silent catch; keep current fallback links
    });
}
