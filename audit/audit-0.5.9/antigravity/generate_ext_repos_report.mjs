import fs from 'fs';

const repoAnalysis = [
  {
    stt: 1,
    name: "Aidoku Community Sources",
    url: "https://aidoku-community.github.io/sources/index.min.json",
    httpStatus: 200,
    format: "Aidoku Community index.min.json (JSON Object / sources array)",
    extensionCount: 176,
    active: true,
    error: null,
    note: "Chỉ mục chứa 176 nguồn Aidoku đa ngôn ngữ (Comic/Manga). Tệp trả về đối tượng JSON gồm trường name và mảng sources.",
    alternativeUrls: [
      "https://aidoku-community.github.io/sources/index.json"
    ]
  },
  {
    stt: 2,
    name: "Kavita Extension Repo (Tachiyomi)",
    url: "https://raw.githubusercontent.com/Kareadita/tach-extension/repo/index.min.json",
    httpStatus: 200,
    format: "Mihon / Tachiyomi index.min.json (JSON Array)",
    extensionCount: 1,
    active: true,
    error: null,
    note: "Chứa 1 tiện ích kết nối OPDS server Kavita (Tachiyomi: Kavita, package: eu.kanade.tachiyomi.extension.all.kavita).",
    alternativeUrls: [
      "https://github.com/Kareadita/tach-extension"
    ]
  },
  {
    stt: 3,
    name: "IReader Extensions Repo (repov2 branch)",
    url: "https://raw.githubusercontent.com/IReaderorg/IReader-extensions/repov2/index.min.json",
    httpStatus: 200,
    format: "IReader index.min.json (JSON Array)",
    extensionCount: 147,
    active: true,
    error: "Thiếu tệp repo.json (HTTP 404 khi ứng dụng gọi fetchStore: repo.json)",
    note: "Tệp index.min.json vẫn hoạt động tốt với 147 nguồn tiểu thuyết (Novel). Tuy nhiên, nhánh repov2 không có file repo.json (metadata kho), khiến YomiHub phát sinh cảnh báo trong nhật ký hoạt động.",
    alternativeUrls: [
      "https://raw.githubusercontent.com/IReaderorg/IReader-extensions/repo/index.min.json (nhánh repo cũ, 97 nguồn)"
    ]
  },
  {
    stt: 4,
    name: "Mangayomi Extensions (Manga / Comic)",
    url: "https://raw.githubusercontent.com/m2k3a/mangayomi-extensions/refs/heads/main/index.json",
    httpStatus: 200,
    format: "Mangayomi index.json (JSON Array)",
    extensionCount: 335,
    active: true,
    error: null,
    note: "Kho truyện tranh chính thức của Mangayomi với 335 tiện ích đa ngôn ngữ (Comic/Manga).",
    alternativeUrls: [
      "https://github.com/m2k3a/mangayomi-extensions"
    ]
  },
  {
    stt: 5,
    name: "Mangayomi Extensions (Anime / Film)",
    url: "https://raw.githubusercontent.com/m2k3a/mangayomi-extensions/refs/heads/main/anime_index.json",
    httpStatus: 200,
    format: "Mangayomi index.json (JSON Array)",
    extensionCount: 64,
    active: true,
    error: null,
    note: "Kho Anime/Video của Mangayomi với 64 tiện ích phát video trực tuyến.",
    alternativeUrls: [
      "https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/anime_index.json"
    ]
  },
  {
    stt: 6,
    name: "Mangayomi Extensions (Novel)",
    url: "https://raw.githubusercontent.com/m2k3a/mangayomi-extensions/refs/heads/main/novel_index.json",
    httpStatus: 200,
    format: "Mangayomi index.json (JSON Array)",
    extensionCount: 9,
    active: true,
    error: null,
    note: "Kho Tiểu thuyết (Novel) của Mangayomi với 9 tiện ích đọc truyện chữ.",
    alternativeUrls: [
      "https://github.com/m2k3a/mangayomi-extensions"
    ]
  },
  {
    stt: 7,
    name: "LNReader Plugins",
    url: "https://raw.githubusercontent.com/LNReader/lnreader-plugins/plugins/v3.0.0/.dist/plugins.min.json",
    httpStatus: 200,
    format: "LNReader plugins.min.json (JSON Array)",
    extensionCount: 372,
    active: true,
    error: null,
    note: "Kho plugin tiểu thuyết lớn nhất của LNReader (v3.0.0) với 372 plugin được biên dịch sẵn. Lưu ý: tương tự IReader, đường dẫn repo.json bị 404, app nên nạp thẳng plugins.min.json.",
    alternativeUrls: [
      "https://www.lnreader.app/plugins",
      "https://github.com/LNReader/lnreader-plugins"
    ]
  },
  {
    stt: 8,
    name: "Yūzōnō Anime Repo (Aniyomi / Mihon)",
    url: "https://raw.githubusercontent.com/yuzono/anime-repo/repo/index.min.json",
    httpStatus: 200,
    format: "Mihon / Aniyomi index.min.json (JSON Array)",
    extensionCount: 248,
    active: true,
    error: null,
    note: "Kho tiện ích Anime/Video chuẩn Aniyomi với 248 tiện ích phát video trực tuyến (trong đó có Google Drive, Xvideos, SupJav, v.v.).",
    alternativeUrls: [
      "https://github.com/yuzono/anime-repo"
    ]
  },
  {
    stt: 9,
    name: "Kegareta Sauces (Mangayomi NSFW / Manga)",
    url: "https://raw.githubusercontent.com/gato404/kegareta-sauces/main/index.json",
    httpStatus: 200,
    format: "Mangayomi index.json (JSON Array)",
    extensionCount: 272,
    active: true,
    error: null,
    note: "Kho mở rộng truyện tranh / NSFW dành cho Mangayomi với 272 tiện ích hoạt động.",
    alternativeUrls: [
      "https://github.com/gato404/kegareta-sauces"
    ]
  },
  {
    stt: 10,
    name: "FelipeGFA Extensões (Mihon PT-BR)",
    url: "https://raw.githubusercontent.com/FelipeGFA/extensoes/repo/index.min.json",
    httpStatus: 200,
    format: "Mihon / Tachiyomi index.min.json (JSON Array)",
    extensionCount: 2,
    active: true,
    error: null,
    note: "Kho tiện ích Mihon tiếng Bồ Đào Nha (chứa 2 tiện ích).",
    alternativeUrls: [
      "https://github.com/FelipeGFA/extensoes"
    ]
  },
  {
    stt: 11,
    name: "Keiyoushi Extensions (Mihon Protocol Buffers)",
    url: "https://raw.githubusercontent.com/keiyoushi/extensions/repo/index.pb",
    httpStatus: 200,
    format: "Mihon index.pb (Google Protocol Buffers binary)",
    extensionCount: "> 1,000 (127 KB binary protobuf)",
    active: true,
    error: null,
    note: "Kho chính thức lớn nhất thế giới của Mihon/Tachiyomi. Keiyoushi đóng gói toàn bộ danh mục thành nhị phân Protobuf index.pb để tối ưu dung lượng và tốc độ tải. (Bản index.min.json chỉ là stub chứa 2 extensions, app bắt buộc giải mã index.pb).",
    alternativeUrls: [
      "https://github.com/keiyoushi/extensions/raw/repo/index.pb",
      "https://keiyoushi.github.io/extensions/"
    ]
  },
  {
    stt: 12,
    name: "Kotatsu Multi Parsers (Shebyyy)",
    url: "https://github.com/Shebyyy/kotatsu-multi-parsers",
    httpStatus: 200,
    format: "Kotatsu GitHub Repository (Parser source tree)",
    extensionCount: "13 parsers (Kotlin/Java compiled)",
    active: true,
    error: "Đây là đường link Web GitHub Repository, không phải link JSON direct endpoint.",
    note: "Dự án chứa các parser mở rộng cho ứng dụng Kotatsu. Để ứng dụng YomiHub đồng bộ parser từ repo này, cần tải các tệp .jar/dex trong mục Releases hoặc clone mã nguồn parser để biên dịch.",
    alternativeUrls: [
      "https://api.github.com/repos/Shebyyy/kotatsu-multi-parsers/releases/latest",
      "https://raw.githubusercontent.com/Shebyyy/kotatsu-multi-parsers/main/"
    ]
  },
  {
    stt: 13,
    name: "IReader Extensions Source Repo",
    url: "https://github.com/IReaderorg/IReader-extensions",
    httpStatus: 200,
    format: "IReader GitHub Repository (Source code)",
    extensionCount: "Web repository (> 140 novel sources)",
    active: true,
    error: "Đây là đường link Web GitHub Repository, không phải tệp chỉ mục JSON.",
    note: "Kho mã nguồn của IReaderorg. Endpoint JSON chính thức của repo này chính là mục STT 3: https://raw.githubusercontent.com/IReaderorg/IReader-extensions/repov2/index.min.json.",
    alternativeUrls: [
      "https://raw.githubusercontent.com/IReaderorg/IReader-extensions/repov2/index.min.json"
    ]
  },
  {
    stt: 14,
    name: "codeKK IReader Detail Mirror",
    url: "https://p.codekk.com/detail/Android/IReaderorg/IReader-extensions",
    httpStatus: 0,
    format: "Web Page / Mirror Archive",
    extensionCount: 0,
    active: false,
    error: "ETIMEDOUT (Máy chủ 39.107.66.116 không phản hồi hoặc bị tường lửa chặn)",
    note: "Trang web giới thiệu dự án mã nguồn mở của bên thứ ba (CodeKK Trung Quốc). Không phải kho repo trực tiếp và hiện tại không thể kết nối.",
    alternativeUrls: [
      "https://github.com/IReaderorg/IReader-extensions",
      "https://raw.githubusercontent.com/IReaderorg/IReader-extensions/repov2/index.min.json"
    ]
  }
];

fs.writeFileSync(
  'D:/A.I Project/A.I Project - YomiHub Project/YomiHub-Project/audit/audit-0.5.9/antigravity/extension_repos_report.json',
  JSON.stringify(repoAnalysis, null, 2)
);

let md = `# Báo Cáo Kiểm Chứng Kho Tiện Ích (Extension Repositories Report)

**Phiên bản YomiHub:** v0.5.9  
**Thời gian kiểm tra:** 18/11/2026 09:40  
**Tài liệu đầu vào:** Sheet \`Extension Repo\` trong \`input_0.5.9.json\`  
**Phương pháp kiểm thử:** Truy vấn mạng độc lập qua HTTP/HTTPS GET, kiểm tra mã trạng thái, Content-Type, phân tích cú pháp Payload (JSON / Protocol Buffers / HTML).

---

## 1. Bảng Tổng Hợp Kiểm Tra 14 URL Kho Tiện Ích

| STT | Tên Kho Tiện Ích | URL Kiểm Tra | HTTP Status | Định Dạng Dữ Liệu | Số Tiện Ích | Tình Trạng |
|:---:|:---|:---|:---:|:---|:---:|:---:|
`;

for (const r of repoAnalysis) {
  const statusBadge = r.httpStatus === 200 ? '✅ 200 OK' : (r.httpStatus > 0 ? `⚠️ HTTP ${r.httpStatus}` : '❌ Không kết nối được');
  const activeBadge = r.active ? 'Hoạt động' : 'Không dùng được';
  md += `| ${r.stt} | **${r.name}** | \`${r.url}\` | ${statusBadge} | ${r.format} | **${r.extensionCount}** | ${activeBadge} |\n`;
}

md += `
---

## 2. Chi Tiết Kỹ Thuật Từng Kho Tiện Ích & Kiến Nghị Xử Lý

`;

for (const r of repoAnalysis) {
  md += `### ${r.stt}. ${r.name}
- **URL gốc:** \`${r.url}\`
- **Mã HTTP:** \`${r.httpStatus}\` | **Định dạng:** \`${r.format}\`
- **Số lượng tiện ích thực tế:** \`${r.extensionCount}\`
- **Lỗi / Cảnh báo:** ${r.error ? `\`${r.error}\`` : '_Không có lỗi_'}
- **Đánh giá kỹ thuật:** ${r.note}
- **URL thay thế / đề xuất:**
${r.alternativeUrls.map(u => `  + \`${u}\``).join('\n')}

`;
}

md += `
---

## 3. Kết Luận & Khuyến Nghị Kiến Trúc Cho YomiHub v0.5.9

1. **Kho IReader repov2 (\`repov2/index.min.json\`):**
   - Không bị chết (HTTP 200, 147 nguồn). Lỗi ghi nhận trong nhật ký 0.5.8 là do YomiHub gửi request tìm tệp metadata \`repo.json\` trước khi nạp index (\`https://raw.githubusercontent.com/IReaderorg/IReader-extensions/repov2/repo.json\` -> 404).
   - *Khuyến nghị:* Trong bộ nạp kho tiện ích IReader của YomiHub, nếu \`repo.json\` trả 404 thì coi đây là kho không có metadata bổ sung và nạp trực tiếp \`index.min.json\`, không coi là lỗi nguồn.

2. **Kho Keiyoushi (\`index.pb\` vs \`index.min.json\`):**
   - Keiyoushi chỉ giữ 2 tiện ích tượng trưng trong \`index.min.json\` và đẩy toàn bộ >1,000 tiện ích vào \`index.pb\` (Protobuf binary).
   - *Khuyến nghị:* Duy trì trình giải mã nhị phân Protobuf \`ExtensionList\` trong YomiHub cho URL \`index.pb\`.

3. **Kho Kotatsu Multi Parsers (Shebyyy):**
   - Link trong bảng là link web GitHub repo, không thể parse JSON trực tiếp.
   - *Khuyến nghị:* Tích hợp trình quét GitHub API \`https://api.github.com/repos/Shebyyy/kotatsu-multi-parsers/releases/latest\` để tự động tải các parser \`.jar\` compiled.

4. **Trang CodeKK:**
   - Máy chủ Trung Quốc bị timeout. Loại bỏ khỏi danh sách nạp tự động, dùng trực tiếp kho gốc GitHub IReader.
`;

fs.writeFileSync(
  'D:/A.I Project/A.I Project - YomiHub Project/YomiHub-Project/audit/audit-0.5.9/antigravity/extension_repos_report.md',
  md
);

console.log("Created extension_repos_report.md and extension_repos_report.json successfully!");
