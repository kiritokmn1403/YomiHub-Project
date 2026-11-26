# YumiHub Samsung TV — Tizen 4.0+ Web App (`.wgt`)

Khung ứng dụng **YumiHub Samsung TV** xây dựng theo chuẩn **Tizen Web Application (`.wgt`)** tương thích TV Samsung thông minh chạy **Tizen OS 4.0 trở lên (đời 2018, WebEngine Chromium 56)**.

## 1. Phạm vi & Ràng buộc kỹ thuật
- **Chỉ Phim & Điện ảnh:** Hiển thị duy nhất thư viện Phim & Điện ảnh (`ItemType.anime` / `itemType === 1`), thanh bên 4 mục giống *YumiHub Android TV*: **Thư viện · Cập nhật · Duyệt · Thêm**.
- **Thuần ES5 + Flexbox chuẩn (Chromium 56):**
  - Toàn bộ mã JavaScript trong `js/` chỉ dùng `var`, `function()`, constructor prototype; **không** dùng `let`/`const`, arrow `=>`, `async/await`, template literal, optional chaining `?.`, nullish `??`, spread `...` hay `class`.
  - CSS chỉ dùng Flexbox chuẩn (`display: flex`), không dùng CSS Grid hay `flex-gap`.
- **Cấu hình `config.xml`:**
  - `required_version="4.0"`, `<tizen:profile name="tv"/>` (khi đóng gói bằng Samsung TV Extension trên Tizen Studio, có thể đổi sang `<tizen:profile name="tv-samsung"/>` nếu IDE yêu cầu)
  - Privilege tối thiểu: `http://tizen.org/privilege/tv.inputdevice`, `http://tizen.org/privilege/internet`, kèm `<access origin="*" subdomains="true"/>` và `<tizen:allow-navigation>*</tizen:allow-navigation>`.
  - Trên TV thật có `window.tizen`, trình phát tự nạp `$WEBAPIS/webapis/webapis.js` để dùng `webapis.avplay` và tự fallback sang HTML5 `<video>` khi mở trên PC.
- **Tính năng đã dựng sẵn:**
  - Màn chờ **5 giây** với logo morph từ hình vuông sang hình tròn (`assets/icon-red.png`) + nút bỏ qua khi bấm `Enter`.
  - Lưới Phim & Điện ảnh + bộ lọc danh mục / sắp xếp + trang chi tiết + danh sách tập.
  - Trình phát video HTML5 kèm adapter an toàn cho `webapis.avplay` (tự nhận biết TV thật vs trình duyệt PC), **nhớ và tiếp tục vị trí xem** trong `localStorage` (`yumihub_tv_progress_v1`).
  - Nhập thư viện từ tệp sao lưu YomiHub `.backup` (tự giải nén ZIP Store/Deflate hoặc Gzip thuần ES5 bằng `js/inflate.js`, hoặc đọc JSON `.backup.db`), tự lọc `itemType === 1` và `forItemType === 1`; kèm nút **Nạp dữ liệu mẫu để kiểm thử**.
  - Điều khiển Remote Samsung TV đầy đủ (`tizen.tvinputdevice.registerKeyBatch` + fallback `registerKey` bọc trong `try/catch`):
    - Phím đã đăng ký: `MediaPlayPause` (`10252`), `MediaPlay` (`415`), `MediaPause` (`19`), `MediaStop` (`413`), `MediaRewind` (`412`), `MediaFastForward` (`417`), và 4 phím màu `ColorF0Red` (`403` → Thư viện), `ColorF1Green` (`404` → Cập nhật), `ColorF2Yellow` (`405` → Duyệt), `ColorF3Blue` (`406` → Thêm).
    - Phím hệ thống TV tự động nhận (không cần `registerKey`): `Return` (`10009`), D-pad (`37–40`), `Enter` (`13`).

## 2. Cấu trúc thư mục
```text
tizen/
├── config.xml               # Cấu hình Tizen 4.0 TV Web App
├── index.html               # Khung giao diện 1920x1080
├── README_tizen.md          # Tài liệu đóng gói & cài đặt
├── assets/
│   ├── icon-red.png         # Biểu tượng ứng dụng & màn chờ
│   ├── icon-glyph.png       # Biểu tượng thanh bên
│   └── sample_trailer.webm  # Video mẫu nội bộ để kiểm thử trình phát
├── ci/
│   └── tizen-wgt.yml        # GitHub Actions đóng gói .wgt chưa ký (tắt sẵn bước ký)
├── css/
│   └── style.css            # Giao diện tối 10-foot (Flexbox chuẩn)
├── js/
│   ├── inflate.js           # Giải nén ZIP / Gzip thuần ES5
│   ├── storage.js           # Lưu thư viện & vị trí xem vào localStorage
│   ├── sample_data.js       # Bộ dữ liệu mẫu Phim & Điện ảnh
│   ├── backup.js            # Đọc & lọc .backup YomiHub (itemType === 1)
│   ├── player.js            # Trình phát HTML5 + adapter webapis.avplay
│   ├── remote.js            # Điều hướng D-pad, phím Media & ColorF0-3
│   ├── splash.js            # Màn chờ 5s morph logo vuông -> tròn
│   └── app.js               # Bộ điều phối giao diện chính
├── tools/
│   └── check_es5.mjs        # Script Node.js kiểm tra thuần ES5 (0 phụ thuộc)
└── shots/                   # Ảnh chụp kiểm thử thật trên trình duyệt
```

## 3. Mở kiểm thử trên trình duyệt PC
Do trình duyệt chặn một số thao tác `file://`, hãy phục vụ thư mục `tizen/` qua HTTP cục bộ (ví dụ Node hoặc Python):

```powershell
# Cách 1: Dùng npx http-server (hoặc script Node tạm)
npx --yes http-server "audit/audit-0.6.7/antigravity/tizen" -p 8089 -c-1
```

Mở `http://127.0.0.1:8089/` ở độ phân giải `1920x1080`. Phím mô phỏng Remote:
- `↑ ↓ ← →`: Di chuyển vùng chọn
- `Enter`: Chọn mục / Mở phim / Bỏ qua màn chờ
- `Esc` hoặc `Backspace`: Quay lại (`Back`)
- `Space` hoặc `P` (hoặc `MediaPlayPause` `10252` / `MediaPlay` `415` / `MediaPause` `19`): Phát / Tạm dừng trong trình phát
- `J` / `L` (hoặc `←` / `→`, `MediaRewind` `412` / `MediaFastForward` `417`): Tua lùi / Tua tới 10 giây
- `S` (hoặc `MediaStop` `413`): Dừng và thoát trình phát
- `403` / `404` / `405` / `406` (`ColorF0Red` / `ColorF1Green` / `ColorF2Yellow` / `ColorF3Blue`): Chuyển nhanh 4 mục **Thư viện · Cập nhật · Duyệt · Thêm**

## 3.1. Kiểm tra cú pháp thuần ES5 (`check_es5.mjs`)
Script `tools/check_es5.mjs` chạy bằng Node.js thuần (không cần `npm install` hay kết nối mạng), bóc comment, chuỗi và regex literal rồi kiểm tra cả `vm.Script` lẫn các cú pháp ES6+ (`let`, `const`, `class`, `=>`, `async`, `await`, `import`, `export`, template literal, `?.`, `??`, `...`, `for..of`, default parameter, destructuring, `**`):

```powershell
# Kiểm tra toàn bộ tizen/js/*.js
node audit/audit-0.6.7/antigravity/tizen/tools/check_es5.mjs

# Tự kiểm thử âm tính (ES6+ bắt buộc FAIL) và biên ES5 hợp lệ
node audit/audit-0.6.7/antigravity/tizen/tools/check_es5.mjs --self-test
```

## 3.2. Đóng gói tự động trên GitHub Actions (`ci/tizen-wgt.yml`)
Tệp mẫu `ci/tizen-wgt.yml` (sẵn sàng để sao chép vào `.github/workflows/tizen-wgt.yml`) chạy trên `ubuntu-latest`:
1. Chạy `check_es5.mjs` trên `js/`.
2. Đọc `version` từ `config.xml` (hoặc `inputs.version` khi `workflow_dispatch`), kiểm tra `config.xml`, `index.html` và tệp icon tồn tại.
3. Nén `index.html`, `config.xml`, `js/`, `css/`, `assets/` (và `img/` nếu có) với `config.xml` ở thư mục gốc của archive thành `YumiHub-SamsungTV-<version>-unsigned.wgt` kèm `YumiHub-SamsungTV-<version>-unsigned.wgt.sha256` và upload artifact.
4. Bước ký bằng Tizen CLI **được tắt sẵn** (`if: ${{ false && vars.ENABLE_TIZEN_SIGNING == 'true' }}`). Chỉ bật khi chủ dự án cấu hình đủ secrets (`TIZEN_AUTHOR_P12`, `TIZEN_AUTHOR_PASSWORD`, `TIZEN_DIST_P12`, `TIZEN_DIST_PASSWORD`), biến `ENABLE_TIZEN_SIGNING=true` và cài Tizen Studio CLI trong runner — không tạo chứng chỉ hay lưu mật khẩu trong kho mã nguồn.

## 4. Đóng gói `.wgt` bằng Tizen Studio CLI
Yêu cầu đã cài **Tizen Studio CLI** + **TV Extension** và đã tạo **Samsung/Tizen Author & Distributor Certificate** (chứng chỉ cần tài khoản của chủ dự án).

```powershell
# 1. Kiểm tra đường dẫn thư mục tizen (lưu ý không đóng gói thư mục shots/ khi phát hành nếu muốn gói nhẹ)
tizen build-web -- "audit\audit-0.6.7\antigravity\tizen"

# 2. Đóng gói & ký thành tệp .wgt
tizen package -t wgt -s <TEN_CERTIFICATE_PROFILE> -- "audit\audit-0.6.7\antigravity\tizen\.buildResult"
```

Tệp kết quả sẽ có dạng `YumiHubSamsungTV.wgt`.

## 5. Cài lên Samsung Smart TV qua Developer Mode (`sdb`)
1. Trên Samsung TV: mở **Apps** → bấm trên remote dãy số `1 2 3 4 5` → bật **Developer mode = ON**, nhập **IP máy tính Windows** rồi khởi động lại TV.
2. Trên Windows (Terminal chứa `sdb` trong `tizen-studio\tools\`):
   ```powershell
   sdb connect <IP_CUA_TV>:26101
   sdb devices
   tizen install -n "YumiHubSamsungTV.wgt" -t <DEVICE_ID_TU_SDB_DEVICES>
   ```
3. Sau khi cài xong, mở **YumiHub Samsung TV** trong mục **Apps** trên TV.
