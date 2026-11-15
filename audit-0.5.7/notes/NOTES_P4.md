# NOTES_P4 – Trình duyệt chống fingerprint (U6, một phần) – Opus 5.5, 14/11/2026

## Yêu cầu
U6: quét Frank Yomik, Browser Fingerprint, Anti-bot Signature Project, tích hợp đầy đủ. MATRIX: công tắc `browser_fingerprint_protection` trong hộp thoại "Browser Fingerprint" của trình duyệt không nơi nào đọc (công tắc chết).

## Đã làm
- `lib/yomihub/browser/anti_fingerprint.dart` (mới): `YomiAntiFingerprint.script(seed)` – nhiễu Canvas (`getImageData`, `toDataURL`, `toBlob`) và Audio (`getChannelData`, `getFloatFrequencyData`) ổn định theo (phiên ứng dụng × tên miền); WebGL `UNMASKED_VENDOR/RENDERER` → tên GPU chung; `hardwareConcurrency`/`deviceMemory` = 8; `navigator.webdriver` = false. KHÔNG đổi User-Agent/ngôn ngữ/kích thước màn hình (phải khớp yêu cầu HTTP và cookie Cloudflare).
- `lib/yomihub/browser/browser_screen.dart`: `initialUserScripts` (AT_DOCUMENT_START, cả iframe) khi công tắc bật (mặc định bật như hiển thị cũ); đổi công tắc → tải lại tab hiện tại.
- Không áp vào WebView giải Cloudflare (`cf_challenge.dart` – test kiểm).
- Test `test/yh_057_p4_test.dart` 3/3; analyze 2 tệp: 1 info có sẵn (`onDownloadStartRequest` deprecated). Log `jobs/done/x2_p4.log` 16:00.

## Chưa làm / hạn chế
- Trình duyệt Firefox (Gecko) chưa tiêm script.
- Chưa kiểm thật trên trang thử fingerprint (eisman.github.io/fingerprintjs2, browserleaks) – cần máy thật.
- Frank Yomik (đường ống dịch ảnh), chữ ký anti-bot cho WebView giải CF (thuộc F1, cần phối hợp), Web Scanner phát hiện fingerprint: chưa đổi. Web Scanner nay ghi lỗi quét vào Nhật Ký (FC32, xem NOTES_X1).
