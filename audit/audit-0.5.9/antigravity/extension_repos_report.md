# Báo Cáo Kiểm Chứng Kho Tiện Ích (Extension Repositories Report)

**Phiên bản YomiHub:** v0.5.9  
**Thời gian kiểm tra:** 18/11/2026 09:40  
**Tài liệu đầu vào:** Sheet `Extension Repo` trong `input_0.5.9.json`  
**Phương pháp kiểm thử:** Truy vấn mạng độc lập qua HTTP/HTTPS GET, kiểm tra mã trạng thái, Content-Type, phân tích cú pháp Payload (JSON / Protocol Buffers / HTML).

---

## 1. Bảng Tổng Hợp Kiểm Tra 14 URL Kho Tiện Ích

| STT | Tên Kho Tiện Ích | URL Kiểm Tra | HTTP Status | Định Dạng Dữ Liệu | Số Tiện Ích | Tình Trạng |
|:---:|:---|:---|:---:|:---|:---:|:---:|
| 1 | **Aidoku Community Sources** | `https://aidoku-community.github.io/sources/index.min.json` | ✅ 200 OK | Aidoku Community index.min.json (JSON Object / sources array) | **176** | Hoạt động |
| 2 | **Kavita Extension Repo (Tachiyomi)** | `https://raw.githubusercontent.com/Kareadita/tach-extension/repo/index.min.json` | ✅ 200 OK | Mihon / Tachiyomi index.min.json (JSON Array) | **1** | Hoạt động |
| 3 | **IReader Extensions Repo (repov2 branch)** | `https://raw.githubusercontent.com/IReaderorg/IReader-extensions/repov2/index.min.json` | ✅ 200 OK | IReader index.min.json (JSON Array) | **147** | Hoạt động |
| 4 | **Mangayomi Extensions (Manga / Comic)** | `https://raw.githubusercontent.com/m2k3a/mangayomi-extensions/refs/heads/main/index.json` | ✅ 200 OK | Mangayomi index.json (JSON Array) | **335** | Hoạt động |
| 5 | **Mangayomi Extensions (Anime / Film)** | `https://raw.githubusercontent.com/m2k3a/mangayomi-extensions/refs/heads/main/anime_index.json` | ✅ 200 OK | Mangayomi index.json (JSON Array) | **64** | Hoạt động |
| 6 | **Mangayomi Extensions (Novel)** | `https://raw.githubusercontent.com/m2k3a/mangayomi-extensions/refs/heads/main/novel_index.json` | ✅ 200 OK | Mangayomi index.json (JSON Array) | **9** | Hoạt động |
| 7 | **LNReader Plugins** | `https://raw.githubusercontent.com/LNReader/lnreader-plugins/plugins/v3.0.0/.dist/plugins.min.json` | ✅ 200 OK | LNReader plugins.min.json (JSON Array) | **372** | Hoạt động |
| 8 | **Yūzōnō Anime Repo (Aniyomi / Mihon)** | `https://raw.githubusercontent.com/yuzono/anime-repo/repo/index.min.json` | ✅ 200 OK | Mihon / Aniyomi index.min.json (JSON Array) | **248** | Hoạt động |
| 9 | **Kegareta Sauces (Mangayomi NSFW / Manga)** | `https://raw.githubusercontent.com/gato404/kegareta-sauces/main/index.json` | ✅ 200 OK | Mangayomi index.json (JSON Array) | **272** | Hoạt động |
| 10 | **FelipeGFA Extensões (Mihon PT-BR)** | `https://raw.githubusercontent.com/FelipeGFA/extensoes/repo/index.min.json` | ✅ 200 OK | Mihon / Tachiyomi index.min.json (JSON Array) | **2** | Hoạt động |
| 11 | **Keiyoushi Extensions (Mihon Protocol Buffers)** | `https://raw.githubusercontent.com/keiyoushi/extensions/repo/index.pb` | ✅ 200 OK | Mihon index.pb (Google Protocol Buffers binary) | **> 1,000 (127 KB binary protobuf)** | Hoạt động |
| 12 | **Kotatsu Multi Parsers (Shebyyy)** | `https://github.com/Shebyyy/kotatsu-multi-parsers` | ✅ 200 OK | Kotatsu GitHub Repository (Parser source tree) | **13 parsers (Kotlin/Java compiled)** | Hoạt động |
| 13 | **IReader Extensions Source Repo** | `https://github.com/IReaderorg/IReader-extensions` | ✅ 200 OK | IReader GitHub Repository (Source code) | **Web repository (> 140 novel sources)** | Hoạt động |
| 14 | **codeKK IReader Detail Mirror** | `https://p.codekk.com/detail/Android/IReaderorg/IReader-extensions` | ❌ Không kết nối được | Web Page / Mirror Archive | **0** | Không dùng được |

---

## 2. Chi Tiết Kỹ Thuật Từng Kho Tiện Ích & Kiến Nghị Xử Lý

### 1. Aidoku Community Sources
- **URL gốc:** `https://aidoku-community.github.io/sources/index.min.json`
- **Mã HTTP:** `200` | **Định dạng:** `Aidoku Community index.min.json (JSON Object / sources array)`
- **Số lượng tiện ích thực tế:** `176`
- **Lỗi / Cảnh báo:** _Không có lỗi_
- **Đánh giá kỹ thuật:** Chỉ mục chứa 176 nguồn Aidoku đa ngôn ngữ (Comic/Manga). Tệp trả về đối tượng JSON gồm trường name và mảng sources.
- **URL thay thế / đề xuất:**
  + `https://aidoku-community.github.io/sources/index.json`

### 2. Kavita Extension Repo (Tachiyomi)
- **URL gốc:** `https://raw.githubusercontent.com/Kareadita/tach-extension/repo/index.min.json`
- **Mã HTTP:** `200` | **Định dạng:** `Mihon / Tachiyomi index.min.json (JSON Array)`
- **Số lượng tiện ích thực tế:** `1`
- **Lỗi / Cảnh báo:** _Không có lỗi_
- **Đánh giá kỹ thuật:** Chứa 1 tiện ích kết nối OPDS server Kavita (Tachiyomi: Kavita, package: eu.kanade.tachiyomi.extension.all.kavita).
- **URL thay thế / đề xuất:**
  + `https://github.com/Kareadita/tach-extension`

### 3. IReader Extensions Repo (repov2 branch)
- **URL gốc:** `https://raw.githubusercontent.com/IReaderorg/IReader-extensions/repov2/index.min.json`
- **Mã HTTP:** `200` | **Định dạng:** `IReader index.min.json (JSON Array)`
- **Số lượng tiện ích thực tế:** `147`
- **Lỗi / Cảnh báo:** `Thiếu tệp repo.json (HTTP 404 khi ứng dụng gọi fetchStore: repo.json)`
- **Đánh giá kỹ thuật:** Tệp index.min.json vẫn hoạt động tốt với 147 nguồn tiểu thuyết (Novel). Tuy nhiên, nhánh repov2 không có file repo.json (metadata kho), khiến YomiHub phát sinh cảnh báo trong nhật ký hoạt động.
- **URL thay thế / đề xuất:**
  + `https://raw.githubusercontent.com/IReaderorg/IReader-extensions/repo/index.min.json (nhánh repo cũ, 97 nguồn)`

### 4. Mangayomi Extensions (Manga / Comic)
- **URL gốc:** `https://raw.githubusercontent.com/m2k3a/mangayomi-extensions/refs/heads/main/index.json`
- **Mã HTTP:** `200` | **Định dạng:** `Mangayomi index.json (JSON Array)`
- **Số lượng tiện ích thực tế:** `335`
- **Lỗi / Cảnh báo:** _Không có lỗi_
- **Đánh giá kỹ thuật:** Kho truyện tranh chính thức của Mangayomi với 335 tiện ích đa ngôn ngữ (Comic/Manga).
- **URL thay thế / đề xuất:**
  + `https://github.com/m2k3a/mangayomi-extensions`

### 5. Mangayomi Extensions (Anime / Film)
- **URL gốc:** `https://raw.githubusercontent.com/m2k3a/mangayomi-extensions/refs/heads/main/anime_index.json`
- **Mã HTTP:** `200` | **Định dạng:** `Mangayomi index.json (JSON Array)`
- **Số lượng tiện ích thực tế:** `64`
- **Lỗi / Cảnh báo:** _Không có lỗi_
- **Đánh giá kỹ thuật:** Kho Anime/Video của Mangayomi với 64 tiện ích phát video trực tuyến.
- **URL thay thế / đề xuất:**
  + `https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/anime_index.json`

### 6. Mangayomi Extensions (Novel)
- **URL gốc:** `https://raw.githubusercontent.com/m2k3a/mangayomi-extensions/refs/heads/main/novel_index.json`
- **Mã HTTP:** `200` | **Định dạng:** `Mangayomi index.json (JSON Array)`
- **Số lượng tiện ích thực tế:** `9`
- **Lỗi / Cảnh báo:** _Không có lỗi_
- **Đánh giá kỹ thuật:** Kho Tiểu thuyết (Novel) của Mangayomi với 9 tiện ích đọc truyện chữ.
- **URL thay thế / đề xuất:**
  + `https://github.com/m2k3a/mangayomi-extensions`

### 7. LNReader Plugins
- **URL gốc:** `https://raw.githubusercontent.com/LNReader/lnreader-plugins/plugins/v3.0.0/.dist/plugins.min.json`
- **Mã HTTP:** `200` | **Định dạng:** `LNReader plugins.min.json (JSON Array)`
- **Số lượng tiện ích thực tế:** `372`
- **Lỗi / Cảnh báo:** _Không có lỗi_
- **Đánh giá kỹ thuật:** Kho plugin tiểu thuyết lớn nhất của LNReader (v3.0.0) với 372 plugin được biên dịch sẵn. Lưu ý: tương tự IReader, đường dẫn repo.json bị 404, app nên nạp thẳng plugins.min.json.
- **URL thay thế / đề xuất:**
  + `https://www.lnreader.app/plugins`
  + `https://github.com/LNReader/lnreader-plugins`

### 8. Yūzōnō Anime Repo (Aniyomi / Mihon)
- **URL gốc:** `https://raw.githubusercontent.com/yuzono/anime-repo/repo/index.min.json`
- **Mã HTTP:** `200` | **Định dạng:** `Mihon / Aniyomi index.min.json (JSON Array)`
- **Số lượng tiện ích thực tế:** `248`
- **Lỗi / Cảnh báo:** _Không có lỗi_
- **Đánh giá kỹ thuật:** Kho tiện ích Anime/Video chuẩn Aniyomi với 248 tiện ích phát video trực tuyến (trong đó có Google Drive, Xvideos, SupJav, v.v.).
- **URL thay thế / đề xuất:**
  + `https://github.com/yuzono/anime-repo`

### 9. Kegareta Sauces (Mangayomi NSFW / Manga)
- **URL gốc:** `https://raw.githubusercontent.com/gato404/kegareta-sauces/main/index.json`
- **Mã HTTP:** `200` | **Định dạng:** `Mangayomi index.json (JSON Array)`
- **Số lượng tiện ích thực tế:** `272`
- **Lỗi / Cảnh báo:** _Không có lỗi_
- **Đánh giá kỹ thuật:** Kho mở rộng truyện tranh / NSFW dành cho Mangayomi với 272 tiện ích hoạt động.
- **URL thay thế / đề xuất:**
  + `https://github.com/gato404/kegareta-sauces`

### 10. FelipeGFA Extensões (Mihon PT-BR)
- **URL gốc:** `https://raw.githubusercontent.com/FelipeGFA/extensoes/repo/index.min.json`
- **Mã HTTP:** `200` | **Định dạng:** `Mihon / Tachiyomi index.min.json (JSON Array)`
- **Số lượng tiện ích thực tế:** `2`
- **Lỗi / Cảnh báo:** _Không có lỗi_
- **Đánh giá kỹ thuật:** Kho tiện ích Mihon tiếng Bồ Đào Nha (chứa 2 tiện ích).
- **URL thay thế / đề xuất:**
  + `https://github.com/FelipeGFA/extensoes`

### 11. Keiyoushi Extensions (Mihon Protocol Buffers)
- **URL gốc:** `https://raw.githubusercontent.com/keiyoushi/extensions/repo/index.pb`
- **Mã HTTP:** `200` | **Định dạng:** `Mihon index.pb (Google Protocol Buffers binary)`
- **Số lượng tiện ích thực tế:** `> 1,000 (127 KB binary protobuf)`
- **Lỗi / Cảnh báo:** _Không có lỗi_
- **Đánh giá kỹ thuật:** Kho chính thức lớn nhất thế giới của Mihon/Tachiyomi. Keiyoushi đóng gói toàn bộ danh mục thành nhị phân Protobuf index.pb để tối ưu dung lượng và tốc độ tải. (Bản index.min.json chỉ là stub chứa 2 extensions, app bắt buộc giải mã index.pb).
- **URL thay thế / đề xuất:**
  + `https://github.com/keiyoushi/extensions/raw/repo/index.pb`
  + `https://keiyoushi.github.io/extensions/`

### 12. Kotatsu Multi Parsers (Shebyyy)
- **URL gốc:** `https://github.com/Shebyyy/kotatsu-multi-parsers`
- **Mã HTTP:** `200` | **Định dạng:** `Kotatsu GitHub Repository (Parser source tree)`
- **Số lượng tiện ích thực tế:** `13 parsers (Kotlin/Java compiled)`
- **Lỗi / Cảnh báo:** `Đây là đường link Web GitHub Repository, không phải link JSON direct endpoint.`
- **Đánh giá kỹ thuật:** Dự án chứa các parser mở rộng cho ứng dụng Kotatsu. Để ứng dụng YomiHub đồng bộ parser từ repo này, cần tải các tệp .jar/dex trong mục Releases hoặc clone mã nguồn parser để biên dịch.
- **URL thay thế / đề xuất:**
  + `https://api.github.com/repos/Shebyyy/kotatsu-multi-parsers/releases/latest`
  + `https://raw.githubusercontent.com/Shebyyy/kotatsu-multi-parsers/main/`

### 13. IReader Extensions Source Repo
- **URL gốc:** `https://github.com/IReaderorg/IReader-extensions`
- **Mã HTTP:** `200` | **Định dạng:** `IReader GitHub Repository (Source code)`
- **Số lượng tiện ích thực tế:** `Web repository (> 140 novel sources)`
- **Lỗi / Cảnh báo:** `Đây là đường link Web GitHub Repository, không phải tệp chỉ mục JSON.`
- **Đánh giá kỹ thuật:** Kho mã nguồn của IReaderorg. Endpoint JSON chính thức của repo này chính là mục STT 3: https://raw.githubusercontent.com/IReaderorg/IReader-extensions/repov2/index.min.json.
- **URL thay thế / đề xuất:**
  + `https://raw.githubusercontent.com/IReaderorg/IReader-extensions/repov2/index.min.json`

### 14. codeKK IReader Detail Mirror
- **URL gốc:** `https://p.codekk.com/detail/Android/IReaderorg/IReader-extensions`
- **Mã HTTP:** `0` | **Định dạng:** `Web Page / Mirror Archive`
- **Số lượng tiện ích thực tế:** `0`
- **Lỗi / Cảnh báo:** `ETIMEDOUT (Máy chủ 39.107.66.116 không phản hồi hoặc bị tường lửa chặn)`
- **Đánh giá kỹ thuật:** Trang web giới thiệu dự án mã nguồn mở của bên thứ ba (CodeKK Trung Quốc). Không phải kho repo trực tiếp và hiện tại không thể kết nối.
- **URL thay thế / đề xuất:**
  + `https://github.com/IReaderorg/IReader-extensions`
  + `https://raw.githubusercontent.com/IReaderorg/IReader-extensions/repov2/index.min.json`


---

## 3. Kết Luận & Khuyến Nghị Kiến Trúc Cho YomiHub v0.5.9

1. **Kho IReader repov2 (`repov2/index.min.json`):**
   - Không bị chết (HTTP 200, 147 nguồn). Lỗi ghi nhận trong nhật ký 0.5.8 là do YomiHub gửi request tìm tệp metadata `repo.json` trước khi nạp index (`https://raw.githubusercontent.com/IReaderorg/IReader-extensions/repov2/repo.json` -> 404).
   - *Khuyến nghị:* Trong bộ nạp kho tiện ích IReader của YomiHub, nếu `repo.json` trả 404 thì coi đây là kho không có metadata bổ sung và nạp trực tiếp `index.min.json`, không coi là lỗi nguồn.

2. **Kho Keiyoushi (`index.pb` vs `index.min.json`):**
   - Keiyoushi chỉ giữ 2 tiện ích tượng trưng trong `index.min.json` và đẩy toàn bộ >1,000 tiện ích vào `index.pb` (Protobuf binary).
   - *Khuyến nghị:* Duy trì trình giải mã nhị phân Protobuf `ExtensionList` trong YomiHub cho URL `index.pb`.

3. **Kho Kotatsu Multi Parsers (Shebyyy):**
   - Link trong bảng là link web GitHub repo, không thể parse JSON trực tiếp.
   - *Khuyến nghị:* Tích hợp trình quét GitHub API `https://api.github.com/repos/Shebyyy/kotatsu-multi-parsers/releases/latest` để tự động tải các parser `.jar` compiled.

4. **Trang CodeKK:**
   - Máy chủ Trung Quốc bị timeout. Loại bỏ khỏi danh sách nạp tự động, dùng trực tiếp kho gốc GitHub IReader.
