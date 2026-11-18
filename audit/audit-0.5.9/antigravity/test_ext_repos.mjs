import fs from 'fs';
import https from 'https';
import http from 'http';

const urls = [
  "https://aidoku-community.github.io/sources/index.min.json",
  "https://raw.githubusercontent.com/Kareadita/tach-extension/repo/index.min.json",
  "https://raw.githubusercontent.com/IReaderorg/IReader-extensions/repov2/index.min.json",
  "https://raw.githubusercontent.com/m2k3a/mangayomi-extensions/refs/heads/main/index.json",
  "https://raw.githubusercontent.com/m2k3a/mangayomi-extensions/refs/heads/main/anime_index.json",
  "https://raw.githubusercontent.com/m2k3a/mangayomi-extensions/refs/heads/main/novel_index.json",
  "https://raw.githubusercontent.com/LNReader/lnreader-plugins/plugins/v3.0.0/.dist/plugins.min.json",
  "https://raw.githubusercontent.com/yuzono/anime-repo/repo/index.min.json",
  "https://raw.githubusercontent.com/gato404/kegareta-sauces/main/index.json",
  "https://raw.githubusercontent.com/FelipeGFA/extensoes/repo/index.min.json",
  "https://raw.githubusercontent.com/keiyoushi/extensions/repo/index.pb",
  "https://github.com/Shebyyy/kotatsu-multi-parsers",
  "https://github.com/IReaderorg/IReader-extensions",
  "https://p.codekk.com/detail/Android/IReaderorg/IReader-extensions"
];

async function fetchUrl(targetUrl) {
  return new Promise((resolve) => {
    try {
      const u = new URL(targetUrl);
      const mod = u.protocol === 'https:' ? https : http;
      const headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': '*/*'
      };
      const req = mod.get(targetUrl, { headers, timeout: 20000 }, (res) => {
        // Handle redirects
        if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
          let nextUrl = res.headers.location;
          if (!nextUrl.startsWith('http')) {
            nextUrl = new URL(nextUrl, targetUrl).href;
          }
          fetchUrl(nextUrl).then(resolve);
          return;
        }

        const chunks = [];
        res.on('data', chunk => chunks.push(chunk));
        res.on('end', () => {
          const buffer = Buffer.concat(chunks);
          resolve({
            url: targetUrl,
            status: res.statusCode,
            headers: res.headers,
            data: buffer,
            error: null
          });
        });
      });
      req.on('timeout', () => {
        req.destroy();
        resolve({ url: targetUrl, status: 0, error: 'TIMEOUT (20s)' });
      });
      req.on('error', (err) => {
        resolve({ url: targetUrl, status: 0, error: err.message });
      });
    } catch (e) {
      resolve({ url: targetUrl, status: 0, error: e.message });
    }
  });
}

async function run() {
  console.log(`Starting fetch of ${urls.length} extension repository URLs...`);
  const results = [];
  for (const url of urls) {
    console.log(`Fetching: ${url}`);
    const res = await fetchUrl(url);
    results.push(res);
  }

  const report = results.map(r => {
    let format = 'Unknown';
    let count = 0;
    let detail = '';

    if (r.error) {
      detail = r.error;
    } else if (r.status === 200) {
      const ct = r.headers['content-type'] || '';
      const text = r.data.toString('utf8');

      if (r.url.endsWith('.pb') || r.url.includes('/index.pb')) {
        format = 'Mihon index.pb (Protobuf)';
        // Protobuf rough estimate or parser
        count = (r.data.length > 0) ? `~${Math.round(r.data.length / 1000)} KB raw protobuf` : 0;
      } else if (r.url.endsWith('.json')) {
        try {
          const parsed = JSON.parse(text);
          if (Array.isArray(parsed)) {
            count = parsed.length;
            if (r.url.includes('aidoku')) format = 'Aidoku index.min.json';
            else if (r.url.includes('lnreader')) format = 'LNReader plugins.min.json';
            else if (r.url.includes('mangayomi') || r.url.includes('kegareta')) format = 'Mangayomi index.json';
            else format = 'Mihon / Tachiyomi index.min.json';
          } else if (typeof parsed === 'object') {
            count = Object.keys(parsed).length;
            format = 'JSON Object';
          }
        } catch (e) {
          format = 'Malformed JSON / HTML response';
          detail = e.message;
        }
      } else if (r.url.includes('github.com')) {
        format = 'GitHub Repository';
        // count releases or repo structure if needed
        count = 'Web repository';
      } else {
        format = 'Web Page';
        count = 'Web page';
      }
    }

    return {
      url: r.url,
      status: r.status,
      format,
      count,
      error: r.error || (r.status !== 200 ? `HTTP ${r.status}` : null),
      dataSample: r.data ? r.data.slice(0, 200).toString('utf8') : null
    };
  });

  fs.writeFileSync('D:/A.I Project/A.I Project - YomiHub Project/YomiHub-Project/audit/audit-0.5.9/antigravity/raw_ext_repos.json', JSON.stringify(report, null, 2));
  console.log('Finished testing extension repos. Output saved to raw_ext_repos.json');
}

run();
