import fs from 'fs';
import https from 'https';
import http from 'http';
import { URL } from 'url';

// Read website_scan_repos.json
const scanData = JSON.parse(fs.readFileSync('D:/A.I Project/A.I Project - YomiHub Project/YomiHub-Project/audit/audit-0.5.9/antigravity/website_scan_repos.json', 'utf8'));
const uniqueRepos = scanData.uniqueRepositories;

// Read repo_discovery.dart to extract in-app patterns
const dartCode = fs.readFileSync('D:/A.I Project/A.I Project - YomiHub Project/YomiHub-Project/overlay/lib/yomihub/repos/repo_discovery.dart', 'utf8');

function fetchUrl(urlStr, maxRedirects = 5) {
  return new Promise((resolve) => {
    try {
      const u = new URL(urlStr);
      const mod = u.protocol === 'https:' ? https : http;
      const req = mod.get(urlStr, {
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36'
        },
        timeout: 10000
      }, (res) => {
        if ([301, 302, 307, 308].includes(res.statusCode) && res.headers.location && maxRedirects > 0) {
          const nextUrl = new URL(res.headers.location, urlStr).toString();
          return resolve(fetchUrl(nextUrl, maxRedirects - 1));
        }
        let data = [];
        res.on('data', chunk => data.push(chunk));
        res.on('end', () => {
          const buffer = Buffer.concat(data);
          resolve({
            statusCode: res.statusCode,
            headers: res.headers,
            buffer,
            text: buffer.toString('utf8')
          });
        });
      });
      req.on('error', (err) => resolve({ statusCode: 0, error: err.message }));
      req.on('timeout', () => {
        req.destroy();
        resolve({ statusCode: 408, error: 'Timeout' });
      });
    } catch (e) {
      resolve({ statusCode: 0, error: e.message });
    }
  });
}

// Function to probe candidate raw index URLs for a github repo
async function probeGitHubIndex(owner, repo) {
  const candidates = [
    `https://raw.githubusercontent.com/${owner}/${repo}/repo/index.min.json`,
    `https://raw.githubusercontent.com/${owner}/${repo}/main/index.json`,
    `https://raw.githubusercontent.com/${owner}/${repo}/main/index.min.json`,
    `https://raw.githubusercontent.com/${owner}/${repo}/repov2/index.min.json`,
    `https://raw.githubusercontent.com/${owner}/${repo}/plugins/v3.0.0/.dist/plugins.min.json`,
    `https://raw.githubusercontent.com/${owner}/${repo}/master/plugins.json`,
    `https://raw.githubusercontent.com/${owner}/${repo}/master/index.json`,
    `https://raw.githubusercontent.com/${owner}/${repo}/master/repository.json`,
    `https://raw.githubusercontent.com/${owner}/${repo}/master/parsers.json`,
    `https://raw.githubusercontent.com/${owner}/${repo}/main/parsers.json`,
    `https://raw.githubusercontent.com/${owner}/${repo}/master/index.min.json`,
    `https://raw.githubusercontent.com/${owner}/${repo}/repo/index.pb`
  ];

  for (const c of candidates) {
    const res = await fetchUrl(c);
    if (res.statusCode === 200) {
      if (c.endsWith('.pb') && res.buffer.length > 50) {
        return { indexUrl: c, res, isPb: true };
      }
      const trimmed = res.text.trim();
      if (trimmed.startsWith('[') || trimmed.startsWith('{')) {
        return { indexUrl: c, res, isPb: false };
      }
    }
  }
  return null;
}

async function analyzeAll() {
  console.log(`Analyzing ${uniqueRepos.length} unique repos from website scan...`);
  const results = [];

  for (let i = 0; i < uniqueRepos.length; i++) {
    const item = uniqueRepos[i];
    let rawUrl = item.repoUrl.trim();
    
    // Normalize corrupted or shield badges
    if (rawUrl.includes('link=tachiyomi%3A%2F%2Fadd-repo%3Furl%3D')) {
      const match = rawUrl.match(/url%3D([^&]+)/);
      if (match) rawUrl = decodeURIComponent(match[1]);
    }
    if (rawUrl.includes('&quot;')) {
      const m = rawUrl.match(/https:\/\/[^"&]+/);
      if (m) rawUrl = m[0];
    }
    if (rawUrl.endsWith('.git')) {
      rawUrl = rawUrl.replace(/\.git$/, '');
    }

    console.log(`[${i + 1}/${uniqueRepos.length}] Checking: ${rawUrl}`);

    let name = '';
    let indexUrl = rawUrl;
    let type = item.appType || 'Comic';
    let engine = 'mihon';
    let alive = false;
    let count = 0;
    let inApp = false;

    // Check inApp in repo_discovery.dart
    const urlLower = rawUrl.toLowerCase();
    const isDirectSite = dartCode.includes(rawUrl) || dartCode.toLowerCase().includes(urlLower);
    
    // Determine engine based on URL & context
    if (urlLower.includes('kotatsu') || urlLower.includes('kaisoku') || urlLower.includes('kototoro')) {
      engine = 'kotatsu';
      type = 'Comic';
    } else if (urlLower.includes('lnreader')) {
      engine = 'lnreader';
      type = 'Novel';
    } else if (urlLower.includes('ireader')) {
      engine = 'ireader';
      type = 'Novel';
    } else if (urlLower.includes('vbook')) {
      engine = 'vbook';
    } else if (urlLower.includes('anime') || urlLower.includes('aniyomi') || urlLower.includes('secozzi')) {
      engine = 'aniyomi';
      type = 'Film';
    } else if (urlLower.includes('mangayomi')) {
      engine = 'mangayomi';
      type = 'Comic';
    } else if (urlLower.includes('aidoku')) {
      engine = 'aidoku';
      type = 'Comic';
    } else {
      engine = 'mihon';
      type = item.appType || 'Comic';
    }

    // Probe the URL directly
    let res = await fetchUrl(rawUrl);

    if (res.statusCode === 200) {
      if (rawUrl.endsWith('.pb')) {
        alive = true;
        count = 1000; // Protobuf index, Keiyoushi has > 1000
      } else {
        try {
          const json = JSON.parse(res.text);
          if (Array.isArray(json)) {
            alive = true;
            count = json.length;
          } else if (json && typeof json === 'object') {
            alive = true;
            count = Object.keys(json).length;
          }
        } catch (_) {
          // If HTML (e.g. GitHub repo page)
          if (rawUrl.includes('github.com')) {
            const m = rawUrl.match(/github\.com\/([^\/]+)\/([^\/]+)/);
            if (m) {
              const probeRes = await probeGitHubIndex(m[1], m[2]);
              if (probeRes) {
                alive = true;
                indexUrl = probeRes.indexUrl;
                if (probeRes.isPb) {
                  count = 1000;
                } else {
                  try {
                    const pj = JSON.parse(probeRes.res.text);
                    count = Array.isArray(pj) ? pj.length : Object.keys(pj).length;
                  } catch (e) {
                    count = 1;
                  }
                }
              } else {
                alive = false; // GitHub page alive but has no standard direct index
              }
            }
          }
        }
      }
    } else if (res.statusCode === 0 || res.statusCode >= 400) {
      // Check if it's GitHub URL that might need raw
      if (rawUrl.includes('github.com')) {
        const m = rawUrl.match(/github\.com\/([^\/]+)\/([^\/]+)/);
        if (m) {
          const probeRes = await probeGitHubIndex(m[1], m[2]);
          if (probeRes) {
            alive = true;
            indexUrl = probeRes.indexUrl;
            if (probeRes.isPb) {
              count = 1000;
            } else {
              try {
                const pj = JSON.parse(probeRes.res.text);
                count = Array.isArray(pj) ? pj.length : Object.keys(pj).length;
              } catch (e) {
                count = 1;
              }
            }
          }
        }
      }
    }

    // Name formatting
    if (rawUrl.includes('keiyoushi')) {
      name = 'Keiyoushi Extensions';
    } else if (rawUrl.includes('observeroftime')) {
      name = 'ObserverOfTime Tachiyomi Extensions';
    } else if (rawUrl.includes('yuzono/anime')) {
      name = 'Yuzono Anime Repo';
    } else if (rawUrl.includes('yuzono/cursed')) {
      name = 'Yuzono Cursed Repo';
    } else if (rawUrl.includes('salmanbappi')) {
      name = 'Salmanbappi Extensions Repo';
    } else if (rawUrl.includes('secozzi')) {
      name = 'Secozzi Aniyomi Extensions';
    } else if (rawUrl.includes('Claudemirovsky/cursedyomi')) {
      name = 'Cursedyomi Extensions (Claudemirovsky)';
    } else if (rawUrl.includes('Shebyyy/kotatsu-multi-parsers')) {
      name = 'Kotatsu Multi Parsers (Shebyyy)';
    } else if (rawUrl.includes('Kotatsu-Redo')) {
      name = 'Kotatsu Parsers Redo';
    } else if (rawUrl.includes('kaisoku-parsers')) {
      name = 'Kaisoku Parsers (glitch-228)';
    } else if (rawUrl.includes('hany18h/kotatsu-parsers')) {
      name = 'Kotatsu Parsers (hany18h)';
    } else if (rawUrl.includes('skepsun/kototoro-parsers')) {
      name = 'Kototoro Parsers (skepsun)';
    } else if (rawUrl.includes('lnreader')) {
      name = 'LNReader Official Plugins';
    } else if (rawUrl.includes('IReaderorg/IReader-extensions')) {
      name = 'IReader Official Extensions';
    } else if (rawUrl.includes('kazemcodes/IReader-extensions')) {
      name = 'IReader Extensions Fork (kazemcodes)';
    } else if (rawUrl.includes('tachiyomiorg/tachiyomi-extensions-1.x')) {
      name = 'Tachiyomi 1.x Legacy Extensions (Archived)';
    } else {
      name = rawUrl.split('/').slice(-2).join('/');
    }

    // Check inApp:
    // In repo_discovery.dart:
    // 1) sites map includes: bio.link/iitachiyomi, mikkiio.github.io/repos/, tachiyomitips.com, observeroftime.frama.io, everythingmoe.com, x.noz.one, kotatsu-multi-parsers, lnreader.app/plugins, IReaderorg/IReader-extensions, codeKK, vbookext.me, vbook-extensions.
    // 2) _probe method probes any github repo listed on those pages.
    // If the index URL or repo URL is directly queried by repo_discovery.dart or dynamically discovered:
    if (isDirectSite || rawUrl.includes('keiyoushi') || rawUrl.includes('observeroftime') || rawUrl.includes('yuzono') || rawUrl.includes('secozzi') || rawUrl.includes('Shebyyy/kotatsu') || rawUrl.includes('lnreader') || rawUrl.includes('IReaderorg')) {
      inApp = true;
    } else {
      inApp = false;
    }

    results.push({
      name,
      url: rawUrl,
      resolvedIndexUrl: indexUrl !== rawUrl ? indexUrl : undefined,
      type,
      engine,
      count,
      alive,
      inApp
    });
  }

  // Save json
  fs.writeFileSync('D:/A.I Project/A.I Project - YomiHub Project/YomiHub-Project/audit/audit-0.5.9/antigravity/repo_suggestions_059.json', JSON.stringify(results, null, 2));
  console.log('Saved repo_suggestions_059.json');

  return results;
}

analyzeAll();
