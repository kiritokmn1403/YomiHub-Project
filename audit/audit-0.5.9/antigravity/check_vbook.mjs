import https from 'https';

https.get('https://www.vbookext.me/sources', { headers: { 'User-Agent': 'Mozilla/5.0' } }, res => {
  let b = '';
  res.on('data', c => b += c);
  res.on('end', () => {
    const urls = b.match(/https?:\/\/[^\s"'<>]+/g) || [];
    const matched = urls.filter(u => u.includes('github') || u.includes('.json') || u.includes('plugin.json') || u.includes('repo'));
    console.log(Array.from(new Set(matched)));
  });
});
