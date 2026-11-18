import fs from 'fs';
import https from 'https';
import http from 'http';

const sites = [
  { name: "Wotaku", url: "https://wotaku.wiki/" },
  { name: "Miyomi", url: "https://miyomi.app/" },
  { name: "Tachiyomi & Mihon community", url: "https://bio.link/iitachiyomi" },
  { name: "MIYOMI (Mikkiio)", url: "https://mikkiio.github.io/repos/" },
  { name: "Tachiyomi Tips", url: "https://tachiyomitips.com/tachiyomi-extension-repo/" },
  { name: "Tachiyomi Extensions (ObserverOfTime)", url: "https://observeroftime.frama.io/tachiyomi-extensions/" },
  { name: "EverythingMoe", url: "https://everythingmoe.com/post/aniyomirepo.html" },
  { name: "Mihon & Aniyomi Extensions (Noz)", url: "https://x.noz.one/" },
  { name: "Kotatsu Multi Parsers", url: "https://github.com/Shebyyy/kotatsu-multi-parsers" },
  { name: "LNReader", url: "https://www.lnreader.app/plugins" },
  { name: "IReader Extension", url: "https://github.com/IReaderorg/IReader-extensions" },
  { name: "vBook", url: "https://www.vbookext.me/sources" },
  { name: "codeKK", url: "https://p.codekk.com/detail/Android/IReaderorg/IReader-extensions" }
];

async function fetchPage(targetUrl) {
  return new Promise((resolve) => {
    try {
      const u = new URL(targetUrl);
      const mod = u.protocol === 'https:' ? https : http;
      const headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.5'
      };
      const req = mod.get(targetUrl, { headers, timeout: 25000 }, (res) => {
        if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
          let nextUrl = res.headers.location;
          if (!nextUrl.startsWith('http')) {
            nextUrl = new URL(nextUrl, targetUrl).href;
          }
          fetchPage(nextUrl).then(resolve);
          return;
        }

        let body = '';
        res.on('data', chunk => body += chunk);
        res.on('end', () => {
          resolve({ status: res.statusCode, body, error: null });
        });
      });
      req.on('timeout', () => {
        req.destroy();
        resolve({ status: 0, body: '', error: 'TIMEOUT (25s)' });
      });
      req.on('error', (err) => {
        resolve({ status: 0, body: '', error: err.message });
      });
    } catch (e) {
      resolve({ status: 0, body: '', error: e.message });
    }
  });
}

function extractRepoUrls(text, sourceUrl) {
  const found = new Set();
  
  // Custom schemes
  const schemeRegex = /(?:tachiyomi|aniyomi|mangayomi):\/\/add-repo\?url=([^"'\s<>]+)/gi;
  let m;
  while ((m = schemeRegex.exec(text)) !== null) {
    try {
      found.add(decodeURIComponent(m[1]));
    } catch (_) {
      found.add(m[1]);
    }
  }

  // Direct repo index URLs
  const urlRegex = /https?:\/\/[^\s"'<>\)]+(?:index\.min\.json|index\.json|repo\.json|plugins\.min\.json|index\.pb)/gi;
  while ((m = urlRegex.exec(text)) !== null) {
    let clean = m[0].replace(/[\.,;:]$/, '');
    found.add(clean);
  }

  // GitHub repo hints for extension repos
  const ghRegex = /https?:\/\/github\.com\/[a-zA-Z0-9_\-\.]+\/(?:[a-zA-Z0-9_\-\.]*extension[a-zA-Z0-9_\-\.]*|[a-zA-Z0-9_\-\.]*parser[a-zA-Z0-9_\-\.]*|[a-zA-Z0-9_\-\.]*plugins[a-zA-Z0-9_\-\.]*)/gi;
  while ((m = ghRegex.exec(text)) !== null) {
    let clean = m[0].replace(/[\.,;:]$/, '');
    if (!clean.includes('/commit/') && !clean.includes('/issues') && !clean.includes('/pull/')) {
      found.add(clean);
    }
  }

  return Array.from(found);
}

function classifyAppType(repoUrl, sourceText) {
  const lower = (repoUrl + ' ' + (sourceText || '')).toLowerCase();
  const types = [];
  if (lower.includes('anime') || lower.includes('film') || lower.includes('movie') || lower.includes('video') || lower.includes('aniyomi')) {
    types.push('Film');
  }
  if (lower.includes('novel') || lower.includes('lnreader') || lower.includes('ireader') || lower.includes('book') || lower.includes('truyenchu')) {
    types.push('Novel');
  }
  if (lower.includes('comic') || lower.includes('manga') || lower.includes('tachiyomi') || lower.includes('mihon') || lower.includes('aidoku') || lower.includes('kotatsu')) {
    types.push('Comic');
  }
  if (types.length === 0) types.push('Comic'); // Default fallback for manga/comic extensions
  return types.join(' / ');
}

async function run() {
  console.log(`Starting scan of ${sites.length} websites...`);
  const pageResults = [];
  const allExtractedRepos = new Map(); // repoUrl -> { repoUrl, sources: Set, appType }

  for (const site of sites) {
    console.log(`Scanning [${site.name}]: ${site.url}`);
    const res = await fetchPage(site.url);
    const extracted = res.body ? extractRepoUrls(res.body, site.url) : [];
    
    pageResults.push({
      siteName: site.name,
      siteUrl: site.url,
      status: res.status,
      error: res.error || (res.status !== 200 ? `HTTP ${res.status}` : null),
      reposFoundCount: extracted.length,
      reposFound: extracted
    });

    for (const repoUrl of extracted) {
      if (!allExtractedRepos.has(repoUrl)) {
        allExtractedRepos.set(repoUrl, {
          repoUrl,
          sourcePages: [site.name],
          appType: classifyAppType(repoUrl)
        });
      } else {
        const item = allExtractedRepos.get(repoUrl);
        if (!item.sourcePages.includes(site.name)) {
          item.sourcePages.push(site.name);
        }
      }
    }
  }

  const finalOutput = {
    scanTimestamp: new Date().toISOString(),
    summary: {
      totalSitesScanned: sites.length,
      sitesSuccess: pageResults.filter(p => p.status === 200).length,
      sitesFailed: pageResults.filter(p => p.status !== 200).length,
      totalUniqueReposExtracted: allExtractedRepos.size
    },
    sites: pageResults,
    uniqueRepositories: Array.from(allExtractedRepos.values())
  };

  fs.writeFileSync('D:/A.I Project/A.I Project - YomiHub Project/YomiHub-Project/audit/audit-0.5.9/antigravity/website_scan_repos.json', JSON.stringify(finalOutput, null, 2));
  console.log('Finished website scan. Saved to website_scan_repos.json');
}

run();
