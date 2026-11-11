# YomiHub 0.5.6 — Kế hoạch phối hợp 3 phiên (lập 10/11/2026 10:15, Asia/Saigon)

Chủ dự án yêu cầu (10/11/2026 10:08): chia việc cập nhật 0.5.6 thành 3 phần; Claude điều phối và giám sát,
ChatGPT Desktop làm Phần B, Google Antigravity IDE làm Phần C. Thấy lỗi phải yêu cầu sửa ngay.

Mục tiêu: 0.5.5+47 -> **0.5.6+48**. Nguồn yêu cầu: `Project YomiHub.xlsx` (43 mục Feature Check, 12 mục YomiHub Update),
`Project GitHub.xlsx`, file log `logs (6).txt` (2.007 mục, 30/10–10/11/2026), `AGENTS.md`, `TECHNICAL_UPDATE_NOTES.md`.

## 1. Ba phần việc
| Phần | Phiên | Phạm vi chính | Phiếu việc |
| --- | --- | --- | --- |
| A | Claude (điều phối) | Phân tích log, đối chiếu danh sách Dự Án GitHub, rà bản dịch, rà soát diff, nghiệm thu gói, gộp ghi chú | `PART_A_CLAUDE.md` |
| B | ChatGPT Desktop | Lõi Dart dùng chung + Android + Android TV (dựng ở `D:\A.I Project\yh\build`) | `PART_B_CHATGPT.md` |
| C | Antigravity IDE | Windows + tích hợp dự án mới + đóng gói + phát hành GitHub (dựng ở `D:\A.I Project\yh\buildwin`) | `PART_C_ANTIGRAVITY.md` |

## 2. Quy tắc bắt buộc cho cả ba phiên
1. Đọc `AGENTS.md` và **toàn bộ** `TECHNICAL_UPDATE_NOTES.md` trước khi sửa mã. `overlay/` là nguồn duy nhất; không chỉ sửa bản sao dựng.
2. **Giữ chỗ tệp (CLAIMS.md):** trước khi sửa một tệp *đã có* trong `overlay/`, ghi thêm 1 dòng `[giờ] B|C <đường dẫn>` vào `CLAIMS.md`.
   Tệp đã có phiên khác giữ thì KHÔNG sửa: ghi yêu cầu vào STATUS của mình và làm mục khác. Xong thì ghi `[giờ] B|C TRẢ <đường dẫn>`.
3. **Khóa tác vụ nặng (BUILD_LOCK.txt):** máy chỉ ~16 GB RAM. Mỗi lúc chỉ một tác vụ nặng (`flutter build`, `flutter test`, giả lập Android).
   Trước khi chạy: nếu `BUILD_LOCK.txt` trống thì ghi `B|C <tác vụ> <giờ bắt đầu>`; chạy xong xóa nội dung. Khóa quá 90 phút không có nhịp trong STATUS thì ghi chú rồi mới được lấy.
4. **Git:** chỉ Phần C chạy lệnh ghi của git (add/commit/push/tag/release). Không force-push, không sửa tag cũ, không đụng `output/` của bản cũ.
5. **Ghi chú:** không ai sửa trực tiếp `TECHNICAL_UPDATE_NOTES.md` trong lúc làm. Mỗi phiên ghi vào `audit-0.5.6/notes/NOTES_B.md` hoặc `NOTES_C.md`
   theo mẫu: hạng mục · lỗi phát hiện · tệp và dòng lệnh đã sửa · công cụ dùng · kết quả kiểm thử · ngày giờ. Claude gộp vào tệp chính ở cuối.
6. **Trạng thái:** ghi nối vào `STATUS_B_CHATGPT.md` / `STATUS_C_ANTIGRAVITY.md` mỗi khi bắt đầu/xong một mục và ít nhất 30 phút một lần:
   `## [YYYY-MM-DD HH:mm] <mã mục> — ĐANG LÀM | XONG | KHÔNG ĐẠT | CHỜ` + tệp sửa + lệnh + kết quả + đường dẫn bằng chứng.
7. **Yêu cầu sửa:** trước và sau mỗi mục, đọc `REVIEW_CLAUDE.md`. Mục `YÊU CẦU SỬA` gửi cho phiên mình phải xử lý trước việc khác, rồi ghi `ĐÃ SỬA` kèm bằng chứng vào STATUS.
8. **Trung thực về kết quả:** chỉ ghi ĐẠT khi có bằng chứng (log test, ảnh, video trong `audit-0.5.6/evidence/`). Không sửa/tắt test để qua.
   Không làm được (Android 6.0, Windows 7/8, x86, ARM, cần thiết bị/tài khoản thứ hai…) thì ghi KHÔNG ĐẠT + nguyên nhân kỹ thuật, không đổi tên gói cho giống đạt.
9. **Bảo mật:** không ghi tài khoản, mật khẩu, token, khóa ký vào ghi chú, log, commit, Release. Tài khoản Anime47 trong Excel chỉ dùng để thử trong ứng dụng.
10. **Dữ liệu người dùng:** không chạy script dọn/mirror khi chưa kiểm tra phạm vi xóa. Thử hợp nhất/sao lưu trên dữ liệu thử.
11. **Kiểm thử:** mọi tính năng thử *trong ứng dụng YomiHub*; riêng VPN kiểm thêm bên ngoài. Ảnh + video đặt tên theo mã mục, lưu `audit-0.5.6/evidence/<B|C>/`.
12. Sheet `Website Extension` không có trong file Excel đính kèm: dùng 29 tiện ích của Kiritokmn Extension Repo và danh sách trong `audit-0.3.9/Project YomiHub.json`.

## 3. Các mốc
- **Giai đoạn 1 (song song):** B và C sửa mã theo phiếu; A phát hành `LOG_FINDINGS.md`, `GITHUB_PROJECTS_DIFF.md`, `L10N_REPORT.md`.
- **Mốc 1 – Đóng băng mã:** B và C ghi `MỐC 1 SẴN SÀNG` vào STATUS kèm kết quả `dart analyze lib` (0 lỗi) và `flutter test`. Claude rà diff, ghi `MỐC 1 DUYỆT` vào `REVIEW_CLAUDE.md`.
- **Giai đoạn 2:** B dựng 3 APK mobile + 3 APK `YumiHub Android TV` (bỏ Comic, Novel, Google Play Books, Booru); C dựng Windows `.appxbundle`, `Setup.exe`, portable.
  Cả hai dựng từ cùng một manifest overlay (ghi SHA256 manifest vào STATUS). Kiểm thử có ảnh + video.
- **Mốc 2 – Nghiệm thu gói:** Claude kiểm tra `output/0.5.6`, băm, bằng chứng; ghi `MỐC 2 DUYỆT`.
- **Giai đoạn 3:** chỉ sau `MỐC 2 DUYỆT`, C commit + push + tạo Release `v0.5.6` + sửa README (link tải). Claude đối chiếu số tệp, kích thước, băm trên Release.

---
## 4. ĐIỀU CHỈNH 10/11/2026 22:10 — chia lại 3 phần (có hiệu lực ngay, thay bảng mục 1)
Chủ dự án gửi Excel mới lúc 22:00 (bản sao + bản trích văn bản trong `audit-0.5.6/inputs/`) và yêu cầu giao phần phức tạp cho **Claude Fable 5.2**.
Phiên bản vẫn là **0.5.6+48** (B đã đổi trong `pubspec.yaml` và `app_identity.dart` lúc 10:18).

Yêu cầu mới trong sheet YomiHub Update:
- **U12 (mới):** quét bộ giao diện mới của Mangayomi trong Mangayomi Project, tối ưu, đưa vào app; **cho phép chuyển đổi giao diện cũ ↔ mới**.
- **U13 (mới):** gộp Truyện Tranh, Phim & Điện Ảnh, Tiểu Thuyết, Google Play Books ở màn hình chính thành một mục **Thư Viện (Library)**, theo Mangayomi Project.
  Bản Android TV: Thư Viện chỉ còn Phim & Điện Ảnh.
- **U5 (mở rộng):** danh sách quét nay là Yomikiru, Yomihon, Zenshin, Nyora, Nuvio, **Mangayomi Project**, **Kotatsu Project**, GIF Viewer.
- Project GitHub.xlsx: Mangayomi Project (thêm mangayomi.org), Kotatsu Project (thêm plugin-sdk, kotatsu-syncserver, kotatsu-parsers,
  subsampling-scale-image-view), Aniyomi (thêm aniyomi.org).

| Phần | Phiên | Phạm vi | Phiếu việc |
| --- | --- | --- | --- |
| A | **Claude Fable 5.2** (phần phức tạp) | U12, U13, U5 phần Mangayomi Project + Kotatsu Project, U10 Android 6.0 + Isar | `PART_A_FABLE.md` |
| B | ChatGPT Desktop | như `PART_B_CHATGPT.md`, **bỏ** B2 dòng 10 (Isar/Android 6.0) — đã chuyển sang A | `PART_B_CHATGPT.md` |
| C | Antigravity IDE | như `PART_C_ANTIGRAVITY.md`, U5 chỉ còn Yomikiru, Yomihon, Zenshin, Nyora, Nuvio, GIF Viewer | `PART_C_ANTIGRAVITY.md` |
| Giám sát | Claude Opus 5.5 (điều phối) | phân tích log, rà diff, `REVIEW_CLAUDE.md`, duyệt Mốc 1/2, gộp ghi chú, nghiệm thu | `PART_A_CLAUDE.md` |

Phần A giữ các tệp điều hướng/màn hình chính/cài đặt giao diện. B và C cần sửa các tệp đó thì ghi yêu cầu vào STATUS, không sửa trực tiếp.
Trạng thái Phần A ghi vào `STATUS_A_FABLE.md`, ghi chú vào `audit-0.5.6/notes/NOTES_A.md`.

## 5. ĐIỀU CHỈNH 10/11/2026 22:55 — Phần B chuyển sang Claude Fable 5.2 (phiên thứ hai)
ChatGPT Desktop hết lượt dùng ~22:40. Chủ dự án để điều phối quyết định: Phần B giao cho **một phiên Claude Fable 5.2 thứ hai ("Fable-B")**.
Fable-B dùng nguyên phiếu `PART_B_CHATGPT.md` và tiếp tục từ `STATUS_B_CHATGPT.md` (mục 22:34 L1 liệt kê việc còn lại), `evidence/B/`, `notes/NOTES_B.md`.
Fable-B ghi STATUS/NOTES vào cùng tệp B (ghi nối, ký hiệu `B(Fable)`), ghi CLAIMS với ký hiệu `B`. Nếu ChatGPT dùng lại được thì chỉ được làm việc do điều phối giao mới.
Upstream Mangayomi mới nhất: `src/mangayomi-0.9.95` (v0.9.95+128); nền dựng hiện tại vẫn là `src/mangayomi` (v0.9.7).

## 6. ĐIỀU CHỈNH 11/11/2026 05:05 — phân công lại theo độ khó
Chủ dự án (04:55): (a) chọn **phương án 1** — 0.5.6 giữ nền Mangayomi v0.9.7, giao diện "Mới" là phần điều hướng kiểu v0.9.95 do A làm;
chuyển nền đầy đủ sang v0.9.95 (Shiori, lưu trữ mới) để bản sau. (b) ChatGPT đã có lượt lại thì giao việc cho ChatGPT; dùng thêm Haiku, Sonnet cho việc nhẹ.

| Ai | Việc | Ghi vào |
| --- | --- | --- |
| **ChatGPT Desktop** | **Phần B trở lại** (B1–B3 mã + test, rồi B4 dựng 6 APK + kiểm thử sau Mốc 1). Fable-B dừng lúc 22:58 (giới hạn lượt), chỉ trả claim `service.dart`, chưa sửa mã. | STATUS_B_CHATGPT.md, NOTES_B.md |
| **Claude Fable 5.2 (Fable-A)** | Việc khó còn lại: sửa điểm yếu hàng đợi ghi Isar (tác vụ không chờ trong tác vụ ghi) có test chống khóa chết; sau Mốc 2 thử lại Android 6.0 (isar 3.4.1, AVD API 23). | STATUS_A_FABLE.md, NOTES_A.md |
| **Antigravity IDE** | Phần C còn lại: kiểm thử **trong ứng dụng** trên Windows các mục C3 + mục A/B (ảnh + video), thử dựng x86; **dựng lại** gói Windows sau Mốc 1 chung. | STATUS_C_ANTIGRAVITY.md, NOTES_C.md |
| **Claude Sonnet** | Rà mã độc lập Mốc 1 cho thay đổi của A và C (đọc diff, tìm lỗi logic/hồi quy). Không sửa mã. | `review/SONNET_REVIEW.md` |
| **Claude Haiku** | Việc nhẹ: kiểm gói `output/0.5.6` (băm khớp, cấu trúc, phiên bản); đối chiếu danh sách Dự Án GitHub với Excel. Không sửa mã. | `review/HAIKU_*.md` |
| **Claude Opus (điều phối)** | Duyệt Mốc 1/Mốc 2 dựa trên báo cáo trên, gộp ghi chú, nghiệm thu, giám sát. | REVIEW_CLAUDE.md |

Gói Windows C dựng lúc 02:49 là **bản thử** (dựng trước Mốc 1, chưa có mã B hoàn chỉnh) — không phát hành; phải dựng lại từ manifest chung sau Mốc 1.

## 7. ĐIỀU CHỈNH 11/11/2026 07:45 — phân công tiết kiệm token Claude
Chủ dự án yêu cầu: tốn ít token Claude nhất mà vẫn hiệu quả. Nguyên tắc: việc nặng về khối lượng → ChatGPT, Antigravity (không tốn token Claude);
Claude chỉ dùng ở nơi cần phán đoán, mỗi việc chọn model rẻ nhất đủ sức.

| Ai | Loại việc | Việc cụ thể còn lại |
| --- | --- | --- |
| **ChatGPT Desktop** (lực lượng chính) | Viết/sửa mã, test, dựng Android, kiểm thử trên AVD/máy thật | R7–R12 (sửa lỗi Phần C, R7 trước); sau Mốc 1: dựng 3 APK mobile + 3 APK TV, kiểm thử trong app có ảnh + video (B4); cập nhật NOTES_B |
| **Antigravity IDE** | Windows: dựng, đóng gói, kiểm thử giao diện; git/Release | Sau Mốc 1: dựng lại 3 gói Windows (sửa R13), kiểm thử trong app (R6), ghi R5 (ARM/x86); sau Mốc 2: commit, push, Release v0.5.6, README |
| **Claude Haiku** | Việc máy móc, đọc tệp lớn | Tóm tắt STATUS/log job cho điều phối; kiểm băm + cấu trúc gói; đếm khóa i18n; đối chiếu Release với output/0.5.6 |
| **Claude Sonnet** | Rà mã theo mốc | Rà diff R7–R12 trước Mốc 1; rà gói cuối trước Mốc 2; gộp NOTES_A/B/C vào TECHNICAL_UPDATE_NOTES.md |
| **Claude Fable 5.2** | Chỉ lỗi khó mà phiên khác không gỡ được | Nếu job a056_t08 (R14/R15) trượt; Android 6.0 sau Mốc 2 (nếu chủ dự án vẫn muốn) |
| **Claude Opus (điều phối)** | Quyết định, duyệt mốc | Đọc báo cáo tóm tắt của Haiku/Sonnet thay vì tự đọc tệp; chỉ chụp màn hình khi một phiên bị kẹt |

Cách làm để giảm token: mọi phiên ghi STATUS ngắn (≤ 5 dòng/mục); bằng chứng dài để trong tệp, STATUS chỉ ghi đường dẫn.
Điều phối kiểm tra mỗi 60–90 phút qua tóm tắt của Haiku. Phiên Claude con chỉ đọc đúng tệp cần, không đọc lại toàn bộ TECHNICAL_UPDATE_NOTES.md.

## 7. ĐIỀU CHỈNH 11/11/2026 09:55 — chia việc tiết kiệm token
Chủ dự án (09:49): chia việc sao cho tốn ít token nhất mà vẫn hiệu quả; ChatGPT có lượt thì giao ChatGPT; dùng Haiku/Sonnet cho việc nhẹ; ChatGPT cũng tự chia như vậy.

Nguyên tắc: việc giao theo mức độ khó, model rẻ nhất làm được thì giao model đó; giao tiếp qua tệp (không chụp màn hình trừ khi bắt buộc);
mỗi báo cáo ngắn, chỉ nêu thay đổi/lỗi/quyết định cần; không đọc lại cả tệp lớn khi chỉ cần phần cuối.

| Model / phiên | Mức | Việc |
| --- | --- | --- |
| **ChatGPT Desktop** (chính) | trung bình–khó | Hoàn tất R7–R12 (đang làm), sau Mốc 1: dựng 3+3 APK, kiểm thử Android/TV. **Tự chia nhỏ**: việc dịch, danh sách link, đọc log, ghi ma trận kiểm thử → model/sub-agent rẻ của ChatGPT; giữ model chính cho sửa mã và quyết định. |
| **Antigravity IDE** (Gemini Flash, rẻ) | lao động GUI | Sau Mốc 1: dựng lại gói Windows từ manifest chung, kiểm thử trong ứng dụng, chụp ảnh + quay video. Không sửa mã overlay (trừ khi điều phối giao). |
| **Claude Haiku** | nhẹ | Canh tiến độ định kỳ (đọc STATUS/CLAIMS/LOCK/log, phát hiện vi phạm quy tắc, phiên đứng yên > 45 phút), cập nhật băm/manifest, kiểm gói, gộp ghi chú thô. Chỉ báo điều phối khi cần quyết định. |
| **Claude Sonnet** | rà mã | Chỉ chạy ở mốc: rà diff B (R7–R12) trước Mốc 1; rà gói + bằng chứng trước Mốc 2. |
| **Claude Fable 5.2** | khó | Chỉ gọi khi có lỗi khó (khóa chết, mất dữ liệu, lỗi biên dịch khó) mà các phiên trên không xử lý được. |
| **Claude Opus (điều phối)** | quyết định | Duyệt Mốc 1/2, phân xử, gộp TECHNICAL_UPDATE_NOTES cuối cùng. Không tự làm việc tay. |

## 8. ĐIỀU CHỈNH 11/11/2026 10:35 — ChatGPT hết lượt lần 3; chia phần B còn lại
Chủ dự án (10:23): Claude tiếp quản việc của ChatGPT, chia bớt cho Antigravity.
- **R16/R17/Tor** (ChatGPT đã sửa sau snapshot 10:16, chưa chạy test) → **Claude Sonnet**: rà diff, chạy test qua job, sửa nếu trượt.
- **Dựng 6 APK** → **Claude Haiku** qua trình chạy job (`build_056.ps1 -step apk` / `-step tv` hoặc tương đương), **chỉ một lần sau MỐC 1b** (C2 xong + R16/R17 đạt) để không dựng hai lần.
  Bản trung gian B4 (snapshot 10:16) **bỏ**, không dựng.
- **Kiểm thử trong ứng dụng Android/TV** (ma trận `evidence/B/B4-QA/RESULTS.md`, công cụ `capture.ps1`, AVD `YomiHub056_Phone_API34` + AVD TV API34 do ChatGPT chuẩn bị)
  → **Antigravity**, sau C2 và sau khi có APK. Kiểm thử Windows như cũ. Ảnh + video vào `evidence/B/B4-QA/` và `evidence/C/`.
- Nếu ChatGPT có lượt lại: chỉ nhận việc điều phối giao mới; không tự làm tiếp B4.
