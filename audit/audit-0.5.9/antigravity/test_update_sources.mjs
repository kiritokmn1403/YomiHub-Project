import fs from 'fs';
import https from 'https';

async function fetchHttp(url) {
  return new Promise((resolve) => {
    https.get(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': '*/*'
      },
      timeout: 20000
    }, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        return fetchHttp(res.headers.location).then(resolve);
      }
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        resolve({ status: res.statusCode, body, error: null });
      });
    }).on('error', (err) => resolve({ status: 0, body: '', error: err.message }));
  });
}

async function run() {
  console.log("Checking 8 update sources...");
  const report = {};

  // 1. GitHub releases/latest API
  console.log("1. Checking GitHub releases/latest API...");
  const ghApi = await fetchHttp("https://api.github.com/repos/kiritokmn1403/YomiHub-Project/releases/latest");
  try {
    const data = JSON.parse(ghApi.body);
    report.githubApi = {
      status: ghApi.status,
      tag: data.tag_name,
      name: data.name,
      published_at: data.published_at,
      assetCount: data.assets ? data.assets.length : 0,
      assets: data.assets ? data.assets.map(a => ({ name: a.name, size: a.size, download_url: a.browser_download_url })) : []
    };
  } catch (e) {
    report.githubApi = { status: ghApi.status, error: ghApi.error || e.message, bodySnippet: ghApi.body.slice(0, 300) };
  }

  // 2. GitHub Releases Webpage
  console.log("2. Checking GitHub Releases webpage...");
  const ghWeb = await fetchHttp("https://github.com/kiritokmn1403/YomiHub-Project/releases");
  report.githubWeb = {
    status: ghWeb.status,
    error: ghWeb.error,
    hasReleases: ghWeb.body.includes('/releases/tag/'),
    bodySnippet: ghWeb.body.slice(0, 300)
  };

  // 3-5. Google Drive folders
  const gdriveFolders = [
    { id: "16PCPorl1Ae9nmKMMWAC3Oz1rp_w9tH__", label: "GDrive Primary (16PCPorl...)" },
    { id: "1EF_4MJQVxLpeKhRoMSctHBFPklPsmAdn", label: "GDrive Secondary 1 (1EF_4MJ...)" },
    { id: "1vLWPTfFznhWko0O6YGJqecnFEU5CLr10", label: "GDrive Secondary 2 (1vLWPT...)" }
  ];

  report.googleDrive = [];
  for (const g of gdriveFolders) {
    console.log(`Checking Google Drive ${g.label}...`);
    const url = `https://drive.google.com/embeddedfolderview?id=${g.id}#list`;
    const res = await fetchHttp(url);
    // Parse files from HTML embeddedfolderview
    const files = [];
    const nameRegex = /class="flip-entry-title">([^<]+)<\/div>/g;
    let m;
    while ((m = nameRegex.exec(res.body)) !== null) {
      files.push(m[1].trim());
    }
    report.googleDrive.push({
      folderId: g.id,
      label: g.label,
      url,
      status: res.status,
      error: res.error,
      fileCount: files.length,
      files
    });
  }

  // 6-8. MediaFire folders
  const mediafireFolders = [
    { key: "kg0wfu3lpbc98", label: "MediaFire YomiHub (kg0wfu3lpbc98)" },
    { key: "8s2tlcukdmw6x", label: "MediaFire Alpha (8s2tlcukdmw6x)" },
    { key: "jmgm4xds8kamx", label: "MediaFire Beta (jmgm4xds8kamx)" }
  ];

  report.mediaFire = [];
  for (const mf of mediafireFolders) {
    console.log(`Checking MediaFire ${mf.label}...`);
    const url = `https://www.mediafire.com/api/1.5/folder/get_content.php?folder_key=${mf.key}&content_type=files&response_format=json&chunk_size=200`;
    const res = await fetchHttp(url);
    try {
      const data = JSON.parse(res.body);
      const folderFiles = data.response?.folder_content?.files || [];
      report.mediaFire.push({
        folderKey: mf.key,
        label: mf.label,
        url,
        status: res.status,
        result: data.response?.result,
        fileCount: folderFiles.length,
        files: folderFiles.map(f => ({
          filename: f.filename,
          size: f.size,
          uploadDate: f.created,
          links: f.links?.normal_download
        }))
      });
    } catch (e) {
      report.mediaFire.push({
        folderKey: mf.key,
        label: mf.label,
        url,
        status: res.status,
        error: res.error || e.message,
        snippet: res.body.slice(0, 200)
      });
    }
  }

  fs.writeFileSync('D:/A.I Project/A.I Project - YomiHub Project/YomiHub-Project/audit/audit-0.5.9/antigravity/raw_update_sources.json', JSON.stringify(report, null, 2));
  console.log("Finished checking update sources. Saved to raw_update_sources.json");
}

run();
