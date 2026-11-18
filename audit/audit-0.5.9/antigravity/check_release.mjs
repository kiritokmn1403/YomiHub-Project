import fs from 'fs';
import https from 'https';

const pendingLog = 'D:/A.I Project/A.I Project - YomiHub Project/YomiHub-Project/jobs/pending/x059_release.log';
const doneLog = 'D:/A.I Project/A.I Project - YomiHub Project/YomiHub-Project/jobs/done/x059_release.log';
const progressFile = 'D:/A.I Project/A.I Project - YomiHub Project/YomiHub-Project/audit/audit-0.5.9/antigravity/RELEASE_PROGRESS_059.md';
const shaFile = 'D:/A.I Project/A.I Project - YomiHub Project/YomiHub-Project/output/0.5.9/SHA256SUMS-0.5.9.txt';

function readLogFile() {
  let logPath = null;
  let isDone = false;
  if (fs.existsSync(pendingLog)) {
    logPath = pendingLog;
  } else if (fs.existsSync(doneLog)) {
    logPath = doneLog;
    isDone = true;
  }
  if (!logPath) return { exists: false };

  const buf = fs.readFileSync(logPath);
  // Check UTF-16LE BOM or null bytes
  let content = '';
  if (buf.length >= 2 && buf[0] === 0xff && buf[1] === 0xfe) {
    content = buf.toString('utf16le');
  } else if (buf.includes(0x00)) {
    content = buf.toString('utf16le');
  } else {
    content = buf.toString('utf8');
  }

  const lines = content.split(/\r?\n/).filter(l => l.trim().length > 0);
  return { exists: true, logPath, isDone, lines, raw: content };
}

function fetchGithubRelease() {
  return new Promise((resolve) => {
    const options = {
      hostname: 'api.github.com',
      path: '/repos/kiritokmn1403/YomiHub-Project/releases/tags/v0.5.9',
      headers: {
        'User-Agent': 'YomiHub-Release-Monitor/1.0',
        'Accept': 'application/vnd.github.v3+json'
      },
      timeout: 10000
    };

    const req = https.get(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          const json = JSON.parse(data);
          resolve({ status: res.statusCode, data: json });
        } catch (e) {
          resolve({ status: res.statusCode, error: e.message, raw: data });
        }
      });
    });

    req.on('error', (e) => resolve({ status: 0, error: e.message }));
    req.on('timeout', () => {
      req.destroy();
      resolve({ status: 408, error: 'Timeout' });
    });
  });
}

async function run() {
  const logInfo = readLogFile();
  const gh = await fetchGithubRelease();

  console.log('--- LOG INFO ---');
  console.log('Log exists:', logInfo.exists, logInfo.isDone ? '(DONE folder)' : '(PENDING folder)');
  if (logInfo.exists) {
    console.log('Total log lines:', logInfo.lines.length);
    console.log('Last 5 lines:');
    logInfo.lines.slice(-5).forEach(l => console.log('  ', l));
  }

  console.log('\n--- GITHUB API INFO ---');
  console.log('HTTP Status:', gh.status);
  if (gh.data) {
    if (gh.data.assets) {
      console.log('Assets count:', gh.data.assets.length);
      const uploaded = gh.data.assets.filter(a => a.state === 'uploaded');
      console.log('Uploaded count:', uploaded.length);
      gh.data.assets.forEach((a, i) => {
        console.log(`  ${i+1}. ${a.name} (${(a.size/1024/1024).toFixed(2)} MB, state: ${a.state})`);
      });
    } else {
      console.log('Message:', gh.data.message);
    }
  }

  if (fs.existsSync(shaFile)) {
    console.log('\n--- LOCAL SHA256SUMS-0.5.9.txt ---');
    const shaContent = fs.readFileSync(shaFile, 'utf8');
    const shaLines = shaContent.split(/\r?\n/).filter(l => l.trim().length > 0);
    console.log('Local sha lines count:', shaLines.length);
  }
}

run();
