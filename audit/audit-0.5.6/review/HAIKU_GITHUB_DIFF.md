# HAIKU_GITHUB_DIFF - Đối chiếu Dự Án GitHub (Excel vs app)

- Nguồn Excel: `audit-0.5.6/inputs/Project_GitHub_dump.txt` (sheet Project GitHub, cột B = tên, cột C = link)
- Nguồn app: `overlay/lib/yomihub/about/github_projects.dart`
- Chuẩn hóa: bỏ khoảng trắng và dấu `'",;)`, bỏ `/` cuối, http→https, chữ thường.

| Mục | Số link (duy nhất) |
|---|---|
| Excel | 637 |
| App | 643 |
| Có trong Excel, thiếu trong app | 34 |
| Có trong app, không có trong Excel | 40 |

## Link thiếu trong app (có trong Excel)

| Tên dự án | Link | Nhóm |
|---|---|---|
| Aniyomi | https://aniyomi.org/ | Ứng Dụng |
| Kotatsu Project | https://github.com/KotatsuApp/plugin-sdk | Ứng Dụng |
| Kotatsu Project | https://github.com/KotatsuApp/kotatsu-syncserver | Ứng Dụng |
| Kotatsu Project | https://github.com/KotatsuApp/kotatsu-parsers | Ứng Dụng |
| Kotatsu Project | https://github.com/KotatsuApp/subsampling-scale-image-view | Ứng Dụng |
| Mangayomi Project | https://mangayomi.org/ | Ứng Dụng |
| LeechText | https://github.com/haipham22/LeechText/releases?fbclid=IwY2xjawVSRf1leHRuA2FlbQIxMQBwZG9mA3NydGMGYXBwX2lkATAAAR8JrC_5cgbIIzjBOQRemYXYXuh3LzAM2yvZ6Dl1OyXRApxw5mUeGav1pvjrLg_aem_14NBLJ_UQePgctVXdULJtA | Ứng Dụng |
| Anti-bot Signature Project | https://github.com/anonympins/fingerprint | Trình Duyệt - Browser |
| Anti-bot Signature Project | https://gist.github.com/0xdevalias/b34feb567bd50b37161293694066dd53 | Trình Duyệt - Browser |
| Anti-bot Signature Project | https://github.com/fail2ban/fail2ban | Trình Duyệt - Browser |
| Anti-bot Signature Project | https://github.com/crowdsecurity/crowdsec | Trình Duyệt - Browser |
| Anti-bot Signature Project | https://github.com/omkarcloud/botasaurus | Trình Duyệt - Browser |
| Anti-bot Signature Project | https://github.com/topics/anti-bot | Trình Duyệt - Browser |
| Anti-bot Signature Project | https://github.com/altcha-org/altcha | Trình Duyệt - Browser |
| Anti-bot Signature Project | https://github.com/sauravbhattacharya001/gif-captcha | Trình Duyệt - Browser |
| GIF Viewer | https://github.com/ata4/gifiddle | Tính Năng Khác - Other Features |
| GIF Viewer | https://github.com/Cutta/GifView | Tính Năng Khác - Other Features |
| GIF Viewer | https://github.com/valentinpi/gif-viewer | Tính Năng Khác - Other Features |
| GIF Viewer | https://github.com/voidtools/voidImageViewer/ | Tính Năng Khác - Other Features |
| GIF Viewer | https://github.com/CaptainCodeman/gif-player | Tính Năng Khác - Other Features |
| GIF Viewer | https://github.com/morrow/gif-viewer | Tính Năng Khác - Other Features |
| GIF Viewer | https://github.com/egeDevelops/GifViewer-Modern | Tính Năng Khác - Other Features |
| Isar libmdbx | https://github.com/isar/isar | Tính Năng Khác - Other Features |
| Isar libmdbx | https://blog.gitcode.com/9798bc7f1c3f32af4677f172c066be38.html | Tính Năng Khác - Other Features |
| Isar libmdbx | https://deepwiki.com/isar-community/isar-community/4.3-android-configuration | Tính Năng Khác - Other Features |
| Isar libmdbx | https://github.com/isar/isar/issues/1420 | Tính Năng Khác - Other Features |
| Isar libmdbx | https://sourceforge.net/projects/libmdbx.mirror/ | Tính Năng Khác - Other Features |
| Isar libmdbx | https://www.altusintel.com/public-yychh0/ | Tính Năng Khác - Other Features |
| Isar libmdbx | https://github.com/isar-community/isar-community/issues/64 | Tính Năng Khác - Other Features |
| Isar libmdbx | https://blog.stackademic.com/isar-flutter-database-a-lifesaver-for-my-project-7ab6d4f1b5ce?gi=5a97c3cba361 | Tính Năng Khác - Other Features |
| Isar libmdbx | https://github.com/isar/isar/issues/1068 | Tính Năng Khác - Other Features |
| Isar libmdbx | https://deepwiki.com/isar/isar/5.1-native-implementation | Tính Năng Khác - Other Features |
| Frank Yomik | https://github.com/akitaonrails/FrankYomik | Image & Text Translation |
| Excel Functions | https://exceljet.net/functions#:~:text=Complete%20reference%20for%20400%2B%20built-in%20Excel%20functions%2C%20each,1000%2B%20Formulas%2C%20101%20Functions%2C%20and%20New%20Excel%20Functions. | Office Suite |

## Link có trong app nhưng không có trong Excel

- https://github.com/kodjodevf/mangayomi-extensions
- https://github.com/kodjodevf/m_extension_server
- https://github.com/Kotatsu-Redo/kotatsu-parsers-redo
- https://github.com/IReaderorg/IReader-extensions
- https://github.com/LNReader/lnreader-plugins
- https://github.com/Aidoku-Community/sources
- https://github.com/guardianproject/tor-android
- https://github.com/WireGuard/wireguard-android
- https://github.com/schwabe/ics-openvpn
- https://github.com/XTLS/Xray-core
- https://github.com/heiher/hev-socks5-tunnel
- https://github.com/media-kit/media-kit
- https://github.com/Anarios/return-youtube-dislike
- https://github.com/ajayyy/SponsorBlock
- https://github.com/NanoHttpd/nanohttpd
- https://github.com/square/okhttp
- https://github.com/jhy/jsoup
- https://github.com/cashapp/zipline
- https://github.com/flutter/flutter
- https://github.com/kiritokmn1403/Decode-Extract
- https://github.com/haipham22/LeechText/releases
- https://github.com/donutbrowser/donutbrowser
- https://github.com/yt-dlp/yt-dlp
- https://github.com/JunkFood02/Seal
- https://github.com/DennisSnijder/Video-Downloader
- https://github.com/SheetJS/sheetjs
- https://github.com/exceljs/exceljs
- https://github.com/apache/poi
- https://github.com/apache/pdfbox
- https://github.com/OfficeDev/Open-XML-SDK
- https://github.com/topics/ooxml
- https://github.com/googleapis/google-api-dart-client
- https://github.com/android/health-connect-samples
- https://github.com/android/health-connect-toolbox
- https://github.com/ShuchirJ/HCGateway
- https://github.com/matinzd/react-native-health-connect
- https://github.com/VREMSoftwareDevelopment/WiFiAnalyzer
- https://copilot.com/
- https://github.com/zhom/donutbrowser
- https://exceljet.net/functions#:~:text=Complete%20reference%20for%20400%2B%20built-in%20Excel%20functions%2C%20each

## Kiểm 6 link mới

Cả 6 link mới đều chưa có trong `github_projects.dart`.

- `aniyomi.org`: có trong Excel; THIẾU trong app
- `mangayomi.org`: có trong Excel; THIẾU trong app
- `github.com/kotatsuapp/plugin-sdk`: có trong Excel; THIẾU trong app
- `kotatsu-syncserver`: có trong Excel; THIẾU trong app
- `kotatsu-parsers`: có trong Excel (`KotatsuApp/kotatsu-parsers`); THIẾU trong app (app chỉ có `Kotatsu-Redo/kotatsu-parsers-redo`, repo khác)
- `subsampling-scale-image-view`: có trong Excel; THIẾU trong app
