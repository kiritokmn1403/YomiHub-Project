import fs from 'fs';
import path from 'path';

const base = 'D:/A.I Project/A.I Project - Extension Repo/Kiritokmn - Extension Repo/sources';
const dirs = fs.readdirSync(base).filter(d => fs.statSync(path.join(base, d)).isDirectory());

const allSources = [];

for (const dir of dirs) {
  const pPath = path.join(base, dir, 'plugin.json');
  if (!fs.existsSync(pPath)) continue;
  try {
    const raw = JSON.parse(fs.readFileSync(pPath, 'utf8'));
    const meta = raw.metadata || raw;
    allSources.push({
      dir,
      name: meta.name || dir,
      source: meta.source || '',
      type: meta.type || '',
      locale: meta.locale || meta.lang || '',
      nsfw: meta.nsfw,
      version: meta.version || 1,
      raw
    });
  } catch (e) {
    console.error(`Error reading ${dir}:`, e.message);
  }
}

console.log(`Loaded ${allSources.length} sources.`);

// Check NSFW and Lang
const suspicious = [];

for (const s of allSources) {
  const text = (s.dir + ' ' + s.name + ' ' + s.source + ' ' + (s.raw.metadata?.description || '')).toLowerCase();
  
  // Potential NSFW indicators
  const nsfwKeywords = ['hentai', '18+', 'sex', 'porn', 'jav', 'doujin', 'r18', 'fikfap', 'rule34', 'lust', 'adult', 'eromanga', 'phimsex'];
  const hasNsfwKeyword = nsfwKeywords.some(kw => text.includes(kw));

  let nsfwIssue = null;
  if (hasNsfwKeyword && !s.nsfw) {
    nsfwIssue = { oldNsfw: s.nsfw, newNsfw: true, reason: `Tên/nguồn chứa từ khóa 18+ (${nsfwKeywords.filter(kw => text.includes(kw)).join(', ')}) nhưng nsfw đang là false` };
  }

  // Language check
  let langIssue = null;
  const currentLang = (s.locale || '').toLowerCase();
  
  // Chinese indicators
  const isChineseDomain = s.source.includes('.cn') || s.source.includes('bqg') || s.source.includes('shu') || s.source.includes('biqu') || s.source.includes('69shuba') || s.source.includes('75zw') || s.source.includes('faloo');
  // Vietnamese indicators
  const isVietnameseDomain = s.source.includes('.vn') || text.includes('truyen') || text.includes('tangthuvien') || text.includes('bachngocsach') || text.includes('hamtruyen') || text.includes('phimmoi') || text.includes('animevietsub');
  // Japanese indicators
  const isJapaneseDomain = s.source.includes('.jp') || s.source.includes('syosetu') || s.source.includes('kakuyomu');

  if (isChineseDomain && !currentLang.startsWith('zh')) {
    langIssue = { oldLang: s.locale, newLang: 'zh-CN', reason: `Trang nội dung tiếng Trung (${s.source}) nhưng lang là ${s.locale}` };
  } else if (isVietnameseDomain && !currentLang.startsWith('vi')) {
    langIssue = { oldLang: s.locale, newLang: 'vi', reason: `Trang nội dung tiếng Việt (${s.source}) nhưng lang là ${s.locale}` };
  } else if (isJapaneseDomain && !currentLang.startsWith('ja')) {
    langIssue = { oldLang: s.locale, newLang: 'ja', reason: `Trang nội dung tiếng Nhật (${s.source}) nhưng lang là ${s.locale}` };
  }

  if (nsfwIssue || langIssue) {
    suspicious.push({
      dir: s.dir,
      name: s.name,
      source: s.source,
      version: s.version,
      nsfwIssue,
      langIssue
    });
  }
}

console.log(`Found ${suspicious.length} sources with potential issues:`);
console.log(JSON.stringify(suspicious.map(x => ({ dir: x.dir, nsfw: x.nsfwIssue, lang: x.langIssue })), null, 2));

fs.writeFileSync('D:/A.I Project/A.I Project - YomiHub Project/YomiHub-Project/audit/audit-0.5.9/antigravity/raw_audit_sources.json', JSON.stringify({ total: allSources.length, suspicious, allSources: allSources.map(s => ({ dir: s.dir, name: s.name, source: s.source, locale: s.locale, nsfw: s.nsfw, version: s.version })) }, null, 2));
