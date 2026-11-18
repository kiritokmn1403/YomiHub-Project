import fs from 'fs';
import https from 'https';

async function fetchJson(url) {
  return new Promise((resolve) => {
    https.get(url, { headers: { 'User-Agent': 'Mozilla/5.0' }, timeout: 15000 }, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        return fetchJson(res.headers.location).then(resolve);
      }
      if (res.statusCode !== 200) {
        return resolve({ status: res.statusCode, data: null });
      }
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        try {
          resolve({ status: 200, data: JSON.parse(body) });
        } catch (e) {
          resolve({ status: 200, raw: body });
        }
      });
    }).on('error', (err) => resolve({ status: 0, error: err.message }));
  });
}

async function analyze() {
  const aidoku = await fetchJson('https://aidoku-community.github.io/sources/index.min.json');
  console.log('Aidoku source count:', aidoku.data?.sources?.length);

  const keiyoushiJson = await fetchJson('https://raw.githubusercontent.com/keiyoushi/extensions/repo/index.min.json');
  console.log('Keiyoushi index.min.json count:', keiyoushiJson.data?.length);

  const ireaderV2 = await fetchJson('https://raw.githubusercontent.com/IReaderorg/IReader-extensions/repov2/index.min.json');
  console.log('IReader repov2 count:', ireaderV2.data?.length);

  const ireaderRepo = await fetchJson('https://raw.githubusercontent.com/IReaderorg/IReader-extensions/repo/index.min.json');
  console.log('IReader repo (branch repo) status & count:', ireaderRepo.status, ireaderRepo.data?.length);

  const kotatsuApi = await fetchJson('https://api.github.com/repos/Shebyyy/kotatsu-multi-parsers/contents');
  console.log('Kotatsu files count via github API:', kotatsuApi.data?.length);
}

analyze();
