# Báo cáo Đối chiếu & Đề xuất Kho Tiện ích YomiHub 0.5.9 (Feature Check 21)

**Thời gian thực hiện:** 18/11/2026  
**Đầu vào:**
- `audit\audit-0.5.9\antigravity\website_scan_repos.json` (29 kho trích xuất từ 13 trang web quét tự động).
- `overlay\lib\yomihub\repos\repo_discovery.dart` (Cơ chế khám phá kho đề xuất hiện tại của YomiHub).
**Tệp dữ liệu chi tiết:** `audit\audit-0.5.9\antigravity\repo_suggestions_059.json`.

---

## 1. Bảng đối chiếu chi tiết 29 kho tiện ích

| STT | Tên kho đề xuất | URL nguồn / Index | Loại | Engine | Số tiện ích | Trạng thái (Alive) | Đã có trong App (inApp) | Đánh giá & Khuyến nghị |
| :---: | :--- | :--- | :---: | :---: | :---: | :---: | :---: | :--- |
| 1 | **Keiyoushi Extensions (Protobuf)** | `https://github.com/keiyoushi/extensions/raw/repo/index.pb` | Comic | mihon | > 1.000 | **ALIVE** (HTTP 200) | **Đã có** | Kho truyện tranh lớn nhất thế giới cho Mihon. Hoạt động cực tốt, phản hồi nhanh. Giữ nguyên. |
| 2 | **Keiyoushi Extensions (JSON)** | `https://raw.githubusercontent.com/keiyoushi/extensions/repo/index.min.json` | Comic | mihon | 2 | **ALIVE** (HTTP 200) | **Đã có** | Bản index JSON dự phòng (chứa metadata thông báo chuyển sang .pb). Giữ nguyên. |
| 3 | **Keiyoushi Extensions (Repo)** | `https://github.com/keiyoushi/extensions` | Comic | mihon | > 1.000 | **ALIVE** (HTTP 200) | **Đã có** | Dự án chính Keiyoushi được YomiHub tự động probe sang `index.pb`. |
| 4 | Keiyoushi Extensions Source | `https://github.com/keiyoushi/extensions-source` | Comic | mihon | 0 | **DEAD** (Không có index) | **Đã có** | Đây là repo chứa mã nguồn Kotlin chưa đóng gói, không có file index. Loại bỏ khỏi danh sách gợi ý. |
| 5 | **ObserverOfTime Extensions** | `https://observeroftime.frama.io/tachiyomi-extensions/index.min.json` | Comic | mihon | 14 | **ALIVE** (HTTP 200) | **Đã có** | Kho độc lập lưu trữ các nguồn truyện tranh không qua kiểm duyệt. Hoạt động ổn định. Giữ nguyên. |
| 6 | ObserverOfTime Badge Link | `https://observeroftime.frama.io/tachiyomi-extensions/index.min.json` | Comic | mihon | 14 | **ALIVE** (HTTP 200) | **Đã có** | Trùng lặp với mục số 5 (bóc tách từ nút bấm cài đặt 1-click). Bỏ qua trùng lặp. |
| 7 | **Yuzono Anime Repo** | `https://raw.githubusercontent.com/yuzono/anime-repo/repo/index.min.json` | Film | aniyomi | 248 | **ALIVE** (HTTP 200) | **Đã có** | Kho Anime/Film phổ biến cho Aniyomi. Hoạt động tốt với 248 nguồn video. Giữ nguyên. |
| 8 | **Salmanbappi Extensions Repo** | `https://raw.githubusercontent.com/salmanbappi/extensions-repo/main/index.min.json` | Comic | mihon | 99 | **ALIVE** (HTTP 200) | **MỚI** | Kho tiện ích truyện tranh chất lượng cao (99 nguồn). **ĐỀ XUẤT THÊM** vào danh sách gợi ý mặc định. |
| 9 | Yuzono Anime Extensions (Source) | `https://github.com/yuzono/anime-extensions` | Film | aniyomi | 0 | **DEAD** (Không có index) | **Đã có** | Repo chứa source code, index thực tế nằm ở `yuzono/anime-repo` (mục 7). Không cần thêm. |
| 10 | Salmanbappi Extensions (GitHub) | `https://github.com/salmanbappi/extensions-repo` | Comic | mihon | 99 | **ALIVE** (HTTP 200) | **MỚI** | Trỏ về cùng kho số 8 (`main/index.min.json`). Sẽ được tự động nạp khi thêm kho số 8. |
| 11 | **Secozzi Aniyomi Extensions** | `https://github.com/Secozzi/aniyomi-extensions` | Film | aniyomi | 1 | **ALIVE** (HTTP 200) | **MỚI** | Kho tiện ích Anime đa nguồn của Secozzi. **ĐỀ XUẤT THÊM** làm nguồn phim dự phòng. |
| 12 | **Cursedyomi Extensions** | `https://github.com/Claudemirovsky/cursedyomi-extensions` | Comic | mihon | 31 | **ALIVE** (HTTP 200) | **MỚI** | Kho 31 nguồn truyện tranh 18+/Cursed. **ĐỀ XUẤT THÊM** vào nhóm nguồn mở rộng người lớn. |
| 13 | **Keiyoushi Mirror (x.noz.one)** | `https://x.noz.one/keiyoushi/index.pb` | Comic | mihon | > 1.000 | **ALIVE** (HTTP 200) | **Đã có** | Gương phân phối tốc độ cao của Noz cho Keiyoushi. Hoạt động tuyệt vời. Giữ nguyên. |
| 14 | **Yuzono Cursed Mirror (Noz)** | `https://x.noz.one/yuzono/cursed/index.pb` | Comic | mihon | > 1.000 | **ALIVE** (HTTP 200) | **Đã có** | Gương truyện người lớn của Noz. Giữ nguyên. |
| 15 | **Secozzi Aniyomi Mirror (Noz)** | `https://x.noz.one/secozzi/index.pb` | Film | aniyomi | > 1.000 | **ALIVE** (HTTP 200) | **Đã có** | Gương phim/anime tốc độ cao. Giữ nguyên. |
| 16 | **Yuzono Anime Mirror (Noz)** | `https://x.noz.one/yuzono/anime/index.pb` | Film | aniyomi | > 1.000 | **ALIVE** (HTTP 200) | **Đã có** | Gương phim/anime của Noz. Giữ nguyên. |
| 17 | Keiyoushi corrupted syntax | `https://github.com/keiyoushi/extensions@repo` | Comic | mihon | 0 | **DEAD** (Lỗi chuỗi) | **Đã có** | Chuỗi bóc tách regex không hoàn chỉnh từ JSON x.noz.one. Loại bỏ. |
| 18 | Secozzi corrupted syntax | `https://github.com/Secozzi/aniyomi-extensions@repo` | Film | aniyomi | 0 | **DEAD** (Lỗi chuỗi) | Không | Chuỗi bóc tách regex không hoàn chỉnh từ JSON x.noz.one. Loại bỏ. |
| 19 | Kotatsu Multi Parsers | `https://github.com/Shebyyy/kotatsu-multi-parsers` | Comic | kotatsu | 0 | **DEAD** (Chỉ chứa APK/code) | **Đã có** | Repo Kotatsu của Shebyyy không cung cấp tệp index JSON trực tiếp. Giữ trong scan để theo dõi. |
| 20 | Kotatsu Multi Parsers (.git) | `https://github.com/Shebyyy/kotatsu-multi-parsers` | Comic | kotatsu | 0 | **DEAD** | **Đã có** | Trùng lặp với mục 19. Bỏ qua. |
| 21 | Kotatsu Parsers Redo | `https://github.com/Kotatsu-Redo/kotatsu-parsers-redo` | Comic | kotatsu | 0 | **DEAD** (Không có index) | Không | Chỉ chứa mã nguồn Kotlin của parser Kotatsu, không có index tự động. Loại bỏ. |
| 22 | Kaisoku Parsers | `https://github.com/glitch-228/kaisoku-parsers` | Comic | kotatsu | 0 | **DEAD** (Không có index) | Không | Không có cấu trúc index tương thích YomiHub. Loại bỏ. |
| 23 | Kotatsu Parsers (hany18h) | `https://github.com/hany18h/kotatsu-parsers` | Comic | kotatsu | 0 | **DEAD** (Không có index) | Không | Không có cấu trúc index tương thích YomiHub. Loại bỏ. |
| 24 | Kototoro Parsers (skepsun) | `https://github.com/skepsun/kototoro-parsers` | Comic | kotatsu | 1 | **ALIVE** (HTTP 200) | **MỚI** | Parser thử nghiệm Kototoro. Có thể theo dõi thêm trong tương lai. |
| 25 | **LNReader Official Plugins** | `https://raw.githubusercontent.com/LNReader/lnreader-plugins/plugins/v3.0.0/.dist/plugins.min.json` | Novel | lnreader | 372 | **ALIVE** (HTTP 200) | **Đã có** | Kho tiểu thuyết chữ lớn nhất (372 nguồn). Hoạt động rất tốt. Giữ nguyên. |
| 26 | **IReader Official Extensions** | `https://github.com/IReaderorg/IReader-extensions` | Novel | ireader | 97 | **ALIVE** (HTTP 200) | **Đã có** | Kho tiểu thuyết chữ IReader (nhánh `repov2/index.min.json`). Hoạt động rất tốt. Giữ nguyên. |
| 27 | IReader Extensions (.git) | `https://github.com/IReaderorg/IReader-extensions` | Novel | ireader | 97 | **ALIVE** (HTTP 200) | **Đã có** | Trùng lặp với mục 26. Bỏ qua. |
| 28 | IReader Fork (kazemcodes) | `https://github.com/kazemcodes/IReader-extensions` | Novel | ireader | 0 | **DEAD** (Dừng hoạt động) | Không | Fork cũ đã dừng cập nhật, không có nhánh repov2. Loại bỏ. |
| 29 | Tachiyomi 1.x Legacy | `https://github.com/tachiyomiorg/tachiyomi-extensions-1.x` | Comic | mihon | 0 | **DEAD** (Archived / DMCA) | Không | Kho gốc Tachiyomi đã bị đóng vĩnh viễn bởi DMCA. Tuyệt đối không thêm. |

---

## 2. Tổng kết & Đề xuất hành động cho YomiHub 0.5.9

### A. Các kho hoạt động tốt đang có trong ứng dụng (Khuyến nghị giữ nguyên)
1. **Keiyoushi Protobuf (`index.pb`)**: Cung cấp hơn 1.000 tiện ích truyện tranh toàn cầu.
2. **LNReader Plugins (`plugins.min.json`)**: Cung cấp 372 tiện ích tiểu thuyết chữ.
3. **Yuzono Anime Repo (`index.min.json`)**: Cung cấp 248 tiện ích Anime/Phim điện ảnh.
4. **IReader Extensions (`repov2/index.min.json`)**: Cung cấp 97 tiện ích tiểu thuyết chữ.
5. **Noz Mirrors (`x.noz.one`)**: Các gương phản chiếu Protobuf tốc độ cao cho Keiyoushi, Yuzono và Secozzi.
6. **ObserverOfTime (`index.min.json`)**: 14 tiện ích truyện tranh độc lập.

### B. Các kho MỚI còn sống, chất lượng cao (Đề xuất thêm vào cơ chế khám phá)
1. **Salmanbappi Extensions Repo**:
   - URL: `https://raw.githubusercontent.com/salmanbappi/extensions-repo/main/index.min.json`
   - Loại: Comic (Truyện tranh) — Engine: Mihon — Số lượng: 99 tiện ích.
   - Ưu điểm: Phản hồi nhanh, độc lập với Keiyoushi, bổ sung nhiều nguồn truyện tranh tiếng Anh và quốc tế.
2. **Cursedyomi Extensions (Claudemirovsky)**:
   - URL: `https://raw.githubusercontent.com/Claudemirovsky/cursedyomi-extensions/repo/index.min.json`
   - Loại: Comic (Truyện tranh 18+) — Engine: Mihon — Số lượng: 31 tiện ích.
   - Ưu điểm: Bổ sung các nguồn truyện tranh người lớn cho người dùng có nhu cầu mở rộng.

### C. Các kho CHẾT hoặc không hợp lệ (Cần loại bỏ / Không đưa vào ứng dụng)
1. `tachiyomiorg/tachiyomi-extensions-1.x`: Đã bị khóa vĩnh viễn (Archived).
2. `kazemcodes/IReader-extensions`: Fork cũ không còn duy trì.
3. `keiyoushi/extensions-source`, `yuzono/anime-extensions`: Chỉ chứa mã nguồn, không chứa file index đóng gói.
4. Các repo Kotatsu chưa chuẩn hóa tệp index JSON công khai (`kotatsu-parsers-redo`, `kaisoku-parsers`, `kotatsu-parsers`).
