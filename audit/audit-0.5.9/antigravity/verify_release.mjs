import fs from 'fs';
import path from 'path';
import crypto from 'crypto';

const outputDir = 'D:/A.I Project/A.I Project - YomiHub Project/YomiHub-Project/output/0.5.9';
const shaPath = path.join(outputDir, 'SHA256SUMS-0.5.9.txt');
const shaContent = fs.readFileSync(shaPath, 'utf-8');
const expectedSha = {};
for (const line of shaContent.split('\n')) {
  const parts = line.trim().split(/\s+/);
  if (parts.length >= 2) {
    expectedSha[parts[1]] = parts[0].toLowerCase();
  }
}

// Fetch GitHub release assets
const res = await fetch('https://api.github.com/repos/kiritokmn1403/YomiHub-Project/releases/tags/v0.5.9', {
  headers: { 'User-Agent': 'Node.js' }
});
const data = await res.json();
const ghAssets = data.assets || [];

console.log('GitHub Release assets count:', ghAssets.length);

const results = [];
let allMatch = true;

for (const asset of ghAssets) {
  const localFile = path.join(outputDir, asset.name);
  const exists = fs.existsSync(localFile);
  let localSize = null;
  let localSha = null;
  if (exists) {
    const stat = fs.statSync(localFile);
    localSize = stat.size;
    const buf = fs.readFileSync(localFile);
    localSha = crypto.createHash('sha256').update(buf).digest('hex');
  }

  const shaMatchExpected = expectedSha[asset.name] ? (expectedSha[asset.name] === localSha) : 'N/A';
  const sizeMatch = localSize === asset.size;
  const ghDigestHex = asset.digest ? asset.digest.replace('sha256:', '') : null;
  const digestMatch = ghDigestHex ? (ghDigestHex === localSha) : 'N/A';

  if (!sizeMatch || (expectedSha[asset.name] && shaMatchExpected !== true)) {
    allMatch = false;
  }

  results.push({
    name: asset.name,
    ghSize: asset.size,
    localSize,
    sizeMatch,
    ghState: asset.state,
    localSha,
    expectedSha: expectedSha[asset.name] || 'N/A',
    shaMatchExpected,
    ghDigest: ghDigestHex,
    digestMatch
  });
}

console.log(JSON.stringify({ allMatch, results }, null, 2));
