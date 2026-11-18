import fs from 'fs';
import https from 'https';

const pendingLog = 'D:/A.I Project/A.I Project - YomiHub Project/YomiHub-Project/jobs/pending/x059_release.log';
const doneLog = 'D:/A.I Project/A.I Project - YomiHub Project/YomiHub-Project/jobs/done/x059_release.log';
const progressFile = 'D:/A.I Project/A.I Project - YomiHub Project/YomiHub-Project/audit/audit-0.5.9/antigravity/RELEASE_PROGRESS_059.md';
const shaFile = 'D:/A.I Project/A.I Project - YomiHub Project/YomiHub-Project/output/0.5.9/SHA256SUMS-0.5.9.txt';

function getNowTime() {
  const d = new Date();
  return d.toTimeString().split(' ')[0];
}

function readLog() {
  let p = fs.existsSync(pendingLog) ? pendingLog : (fs.existsSync(doneLog) ? doneLog : null);
  if (!p) return null;
  const buf = fs.readFileSync(p);
  const text = (buf.length >= 2 && buf[0] === 0xff && buf[1] === 0xfe) || buf.includes(0x00)
    ? buf.toString('utf16le')
    : buf.toString('utf8');
  return { path: p, lines: text.split(/\r?\n/).filter(l => l.trim().length > 0), raw: text };
}

function fetchGithub() {
  return new Promise((resolve) => {
    const req = https.get('https://api.github.com/repos/kiritokmn1403/YomiHub-Project/releases/tags/v0.5.9', {
      headers: { 'User-Agent': 'YomiHub-Monitor', 'Accept': 'application/vnd.github.v3+json' },
      timeout: 10000
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try { resolve(JSON.parse(data)); } catch (e) { resolve(null); }
      });
    });
    req.on('error', () => resolve(null));
    req.on('timeout', () => { req.destroy(); resolve(null); });
  });
}

export async function checkStatus() {
  const log = readLog();
  const gh = await fetchGithub();

  if (!log) {
    return { error: 'Chưa tìm thấy tệp log x059_release.log' };
  }

  // Check exit code
  const exitMatch = log.raw.match(/### RELEASE EXIT (\d+)/);
  const isFinished = !!exitMatch;
  const exitCode = exitMatch ? parseInt(exitMatch[1], 10) : null;

  // Check error lines
  const errorLines = log.lines.filter(l => l.includes('FAIL') || l.includes('ERROR'));

  // Parse completed files
  const okLines = log.lines.filter(l => l.includes('] OK '));
  const doneCount = okLines.length;

  // Parse last upload line
  const uploadLines = log.lines.filter(l => l.includes('] UPLOAD '));
  const lastUploadLine = uploadLines.length > 0 ? uploadLines[uploadLines.length - 1] : '';
  
  let currentFile = 'Không rõ';
  let currentFileSize = '';
  const uMatch = lastUploadLine.match(/UPLOAD\s+([^\s]+)\s+\(([^)]+)\)/);
  if (uMatch) {
    currentFile = uMatch[1];
    currentFileSize = uMatch[2];
  }

  // Total percent and speed from last OK line
  let totalPercent = 0;
  let lastSpeed = 0;
  if (okLines.length > 0) {
    const lastOk = okLines[okLines.length - 1];
    const pMatch = lastOk.match(/total\s+(\d+)%/);
    if (pMatch) totalPercent = parseInt(pMatch[1], 10);
    
    // Find latest non-zero speed
    for (let i = okLines.length - 1; i >= 0; i--) {
      const sMatch = okLines[i].match(/=\s*([\d.]+)\s*MB\/s/);
      if (sMatch && parseFloat(sMatch[1]) > 0.05) {
        lastSpeed = parseFloat(sMatch[1]);
        break;
      }
    }
  }

  // Check GitHub uploaded count
  let ghUploadedCount = 0;
  if (gh && gh.assets) {
    ghUploadedCount = gh.assets.filter(a => a.state === 'uploaded').length;
  }

  // Calculate ETA
  // Total size ~ 2150 MB. Uploaded = 2150 * (totalPercent/100)
  // Remaining MB = 2150 * (1 - totalPercent/100)
  let etaMinutes = 0;
  if (lastSpeed > 0 && totalPercent < 100) {
    const remainingMB = 2150 * (1 - totalPercent / 100);
    etaMinutes = Math.round(remainingMB / lastSpeed / 60);
  }

  const now = getNowTime();
  let line = '';
  if (isFinished) {
    line = `[${now}] Hoàn tất ${doneCount}/19 tệp (GitHub API: ${ghUploadedCount}/19) | Tổng: 100% | Exit code: ${exitCode}`;
  } else {
    line = `[${now}] ${doneCount}/19 tệp đã xong (GitHub API: ${ghUploadedCount}/19) | Đang tải: ${currentFile} (${currentFileSize}) | Tổng: ${totalPercent}% | Tốc độ: ~${lastSpeed.toFixed(2)} MB/s | Còn lại: ~${etaMinutes} phút`;
  }

  // Append to RELEASE_PROGRESS_059.md
  if (!fs.existsSync(progressFile)) {
    fs.writeFileSync(progressFile, '# Tiến độ Tải lên Bản phát hành GitHub Release v0.5.9\n\n| Thời gian | Tiến độ | Tệp đang tải | % Hoàn thành | Tốc độ | Ước tính còn lại |\n| :---: | :---: | :--- | :---: | :---: | :---: |\n');
  }
  
  const mdRow = isFinished
    ? `| ${now} | ${doneCount}/19 (Hoàn tất) | Đã xong toàn bộ 19 tệp | 100% | - | 0 phút |\n`
    : `| ${now} | ${doneCount}/19 | \`${currentFile}\` (${currentFileSize}) | ${totalPercent}% | ${lastSpeed.toFixed(2)} MB/s | ~${etaMinutes} phút |\n`;
  fs.appendFileSync(progressFile, mdRow);

  return {
    now,
    doneCount,
    ghUploadedCount,
    currentFile,
    currentFileSize,
    totalPercent,
    lastSpeed,
    etaMinutes,
    isFinished,
    exitCode,
    errorLines,
    line,
    assets: gh ? gh.assets : []
  };
}

if (process.argv[1].endsWith('check_status.mjs')) {
  checkStatus().then(r => console.log(JSON.stringify(r, null, 2)));
}
