# Báo cáo Kiểm toán Ngôn ngữ & Cờ NSFW Tiện ích (Feature Check 34)

**Thời gian thực hiện:** 18/11/2026  
**Phạm vi:** Toàn bộ 196 tiện ích trong thư mục `sources/` thuộc kho `D:\A.I Project\A.I Project - Extension Repo\Kiritokmn - Extension Repo`.  
**Mục tiêu:** Rà soát và chuẩn hóa:
1. Trường ngôn ngữ (`locale` / `lang`): Phải phản ánh chính xác ngôn ngữ nội dung của nguồn (tiếng Việt, tiếng Anh, tiếng Trung, tiếng Nhật hoặc toàn cầu).
2. Cờ người lớn (`nsfw`): Trang có nội dung người lớn (18+, hentai, phim người lớn, nội dung khiêu dâm) bắt buộc phải bật cờ `nsfw: true`; các trang truyện/phim thông thường phải để `nsfw: false`.

---

## 1. Bảng tổng hợp các nguồn cần điều chỉnh

| STT | Nguồn (dir) | Tên nguồn | URL gốc | Ngôn ngữ (lang) cũ → mới | Cờ NSFW cũ → mới | Version cũ → mới | Lý do điều chỉnh |
| :---: | :--- | :--- | :--- | :---: | :---: | :---: | :--- |
| 1 | `hentaivn` | HentaiVN | `https://hentaihvn.tv` | `vi_VN` (giữ nguyên) | `false` → `true` | 31 → 32 | Trang web chuyên truyện tranh Hentai/18+ tiếng Việt. Đã có trường `"tag": "nsfw"` nhưng cờ `"nsfw"` đang bị cấu hình sai là `false`. Cần chuyển thành `true`. |
| 2 | `mimimoe` | Mimimoe | `https://mimihentai.moe` | `vi` (giữ nguyên) | `false` → `true` | 5 → 6 | Trang mimihentai.moe chuyên đọc truyện Hentai/Doujinshi 18+. Cờ `"nsfw"` đang bị để `false`, cần bật thành `true`. |
| 3 | `nettruyen18` | NetTruyen18 | `https://nettruyen18.com` | `vi` (giữ nguyên) | `false` → `true` | 4 → 5 | Trang NetTruyen18 chuyên thể loại truyện tranh 18+/Manhwa người lớn. Cần bật cờ `"nsfw": true`. |
| 4 | `vinahentai` | VinaHentai | `https://vinahentai.bio` | `vi` (giữ nguyên) | `false` → `true` | 6 → 7 | Trang VinaHentai chuyên truyện tranh Hentai người lớn. Cờ `"nsfw"` đang bị để `false`, cần bật thành `true`. |
| 5 | `ehentai` | E Hentai | `https://e-hentai.org` | `vi` → `global` | `true` (giữ nguyên) | 5 → 6 | E-Hentai là kho lưu trữ truyện tranh Doujinshi/Manga đa ngôn ngữ toàn cầu (Anh, Nhật, Trung...), không phải chỉ có tiếng Việt. Cần chuẩn hóa `locale` thành `global` (tương tự như `fikfap`, `pornhub`, `tikporn`). |

---

## 2. Thống kê kết quả kiểm toán 196 nguồn

- **Tổng số tiện ích được rà soát:** 196 nguồn.
- **Số nguồn điều chỉnh cờ NSFW:** 4 nguồn (`hentaivn`, `mimimoe`, `nettruyen18`, `vinahentai`).
- **Số nguồn điều chỉnh mã ngôn ngữ:** 1 nguồn (`ehentai`: chuyển từ `vi` sang `global`).
- **Số nguồn đã tuân thủ chuẩn xác từ trước:** 191 nguồn.
  - Các nguồn 18+ đã có `nsfw: true` chuẩn: `cbhentai`, `fikfap`, `hentaivietsubcom`, `po18`, `po18sm`, `pornhub`, `sayhentai`, `sexviettop`, `syosetur18`, `tikporn`, `watchhentainet`.
  - Các nguồn truyện/phim thông thường có `nsfw: false` chuẩn: 180 nguồn.
  - Phân bổ ngôn ngữ sau chuẩn hóa:
    - Tiếng Việt (`vi`, `vi_VN`): 134 nguồn.
    - Tiếng Trung (`zh-CN`, `zh_CN`): 46 nguồn.
    - Tiếng Anh (`en`, `en_US`): 8 nguồn.
    - Toàn cầu đa ngôn ngữ (`global`): 4 nguồn (`fikfap`, `pornhub`, `tikporn`, `ehentai`).
    - Tiếng Nhật (`ja`): 4 nguồn (`syosetu`, `kakuyomu`, `syosetur18`...).

---

## 3. Quy trình thực hiện & Kiểm thử

1. Cập nhật tệp cấu hình `plugin.json` cho 5 nguồn trên:
   - Đặt lại `nsfw: true` cho `hentaivn`, `mimimoe`, `nettruyen18`, `vinahentai`.
   - Đặt `locale: "global"` cho `ehentai`.
   - Tăng phiên bản `version` lên +1 cho mỗi nguồn.
2. Kiểm tra cú pháp và thực thi kiểm thử cục bộ:
   - `node .build/test/hentaivn.mjs`
   - `node .build/test/mimimoe.mjs`
   - `node .build/test/nettruyen18.mjs`
   - `node .build/test/vinahentai.mjs`
   - `node .build/test/ehentai.mjs`
3. Chạy `npm run build` để tái tạo lại toàn bộ gói `.zip` và chỉ mục `index.json` của kho tiện ích.
4. Thực hiện local git commit trong kho `Kiritokmn - Extension Repo` (không push lên remote).
