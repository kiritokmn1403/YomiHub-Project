# gen_checksums_036.ps1: Compute MD5 & SHA256 and generate YomiHub-0.3.6-changelog.txt
param(
    [string]$outDir = "D:\A.I Project\A.I Project - YomiHub Project\output"
)

$expected = @(
    "YomiHub-0.3.6-arm64-v8a.apk",
    "YomiHub-0.3.6-armeabi-v7a.apk",
    "YomiHub-0.3.6-x86_64.apk",
    "YumiHub-Android-TV-0.3.6-arm64-v8a.apk",
    "YumiHub-Android-TV-0.3.6-armeabi-v7a.apk",
    "YumiHub-Android-TV-0.3.6-x86_64.apk",
    "YomiHub-0.3.6-windows-x64-Setup.exe",
    "YomiHub-0.3.6-windows-x64.appxbundle",
    "YomiHub-0.3.6-windows-x64.zip",
    "YomiHub-0.3.6-windows-x64-full.zip"
)

$info = @{}
foreach ($name in $expected) {
    $p = Join-Path $outDir $name
    if (Test-Path $p) {
        $item = Get-Item $p
        $sha = (Get-FileHash -Path $p -Algorithm SHA256).Hash
        $md = (Get-FileHash -Path $p -Algorithm MD5).Hash
        $mb = [math]::Round($item.Length / 1MB, 2)
        $info[$name] = @{
            Length = $item.Length
            SizeMB = $mb
            SHA256 = $sha
            MD5 = $md
        }
        Write-Host "$name : $mb MB | MD5: $md | SHA256: $sha" -ForegroundColor Green
    } else {
        Write-Host "WARNING: Missing $name" -ForegroundColor Yellow
    }
}

$dateStr = Get-Date -Format "yyyy-MM-dd"

$changelog = @"
================================================================================
                    YOMIHUB / YUMIHUB RELEASE CHANGELOG v0.3.6
                                (Build 28 - $dateStr)
================================================================================

1. TỔNG QUAN PHIÊN BẢN (VERSION OVERVIEW)
- Phiên bản ứng dụng: 0.3.6 (Build Number: 28)
- Định danh User-Agent: YomiHub/0.3.6
- Nâng cấp đồng bộ toàn diện trên cả 3 hệ sinh thái: Android Mobile, Android TV và Windows Desktop.
- Tương thích nền tảng:
  + Android Mobile: Android 6.0 (API 23) trở lên, xuất xưởng 3 gói APK tối ưu theo kiến trúc CPU (arm64-v8a, armeabi-v7a, x86_64).
  + Android TV: Tất cả dòng thiết bị Android TV / Google TV, xuất xưởng 3 gói APK riêng biệt "YumiHub Android TV" (loại bỏ hoàn toàn Comic & Novel, tối ưu D-pad remote).
  + Windows: Windows 7 SP1, Windows 8, Windows 8.1, Windows 10, Windows 11 (x64) với đầy đủ 4 gói phát hành:
    * Bản cài đặt tự động dạng .exe (Setup Wizard có giao diện, tạo shortcut desktop & start menu)
    * Bản cài đặt đóng gói .appxbundle (Sideload / Store package đi kèm chứng chỉ số YomiHub-RootCA.cer)
    * Bản Portable ZIP tiêu chuẩn không cần cài đặt
    * Bản Portable ZIP Full tích hợp sẵn M-Extension-Server JRE + Tor + Xray.

--------------------------------------------------------------------------------
2. DANH SÁCH TỆP TIN XUẤT XƯỞNG & MÃ BĂM TOÀN VẸN (DELIVERABLES & CHECKSUMS)
--------------------------------------------------------------------------------
[Android Mobile APKs - YomiHub 0.3.6]
* YomiHub-0.3.6-arm64-v8a.apk
  - Dung lượng: $($info['YomiHub-0.3.6-arm64-v8a.apk'].SizeMB) MB ($($info['YomiHub-0.3.6-arm64-v8a.apk'].Length) bytes)
  - MD5:    $($info['YomiHub-0.3.6-arm64-v8a.apk'].MD5)
  - SHA256: $($info['YomiHub-0.3.6-arm64-v8a.apk'].SHA256)

* YomiHub-0.3.6-armeabi-v7a.apk
  - Dung lượng: $($info['YomiHub-0.3.6-armeabi-v7a.apk'].SizeMB) MB ($($info['YomiHub-0.3.6-armeabi-v7a.apk'].Length) bytes)
  - MD5:    $($info['YomiHub-0.3.6-armeabi-v7a.apk'].MD5)
  - SHA256: $($info['YomiHub-0.3.6-armeabi-v7a.apk'].SHA256)

* YomiHub-0.3.6-x86_64.apk
  - Dung lượng: $($info['YomiHub-0.3.6-x86_64.apk'].SizeMB) MB ($($info['YomiHub-0.3.6-x86_64.apk'].Length) bytes)
  - MD5:    $($info['YomiHub-0.3.6-x86_64.apk'].MD5)
  - SHA256: $($info['YomiHub-0.3.6-x86_64.apk'].SHA256)

[Android TV APKs - YumiHub Android TV 0.3.6]
* YumiHub-Android-TV-0.3.6-arm64-v8a.apk
  - Dung lượng: $($info['YumiHub-Android-TV-0.3.6-arm64-v8a.apk'].SizeMB) MB ($($info['YumiHub-Android-TV-0.3.6-arm64-v8a.apk'].Length) bytes)
  - MD5:    $($info['YumiHub-Android-TV-0.3.6-arm64-v8a.apk'].MD5)
  - SHA256: $($info['YumiHub-Android-TV-0.3.6-arm64-v8a.apk'].SHA256)

* YumiHub-Android-TV-0.3.6-armeabi-v7a.apk
  - Dung lượng: $($info['YumiHub-Android-TV-0.3.6-armeabi-v7a.apk'].SizeMB) MB ($($info['YumiHub-Android-TV-0.3.6-armeabi-v7a.apk'].Length) bytes)
  - MD5:    $($info['YumiHub-Android-TV-0.3.6-armeabi-v7a.apk'].MD5)
  - SHA256: $($info['YumiHub-Android-TV-0.3.6-armeabi-v7a.apk'].SHA256)

* YumiHub-Android-TV-0.3.6-x86_64.apk
  - Dung lượng: $($info['YumiHub-Android-TV-0.3.6-x86_64.apk'].SizeMB) MB ($($info['YumiHub-Android-TV-0.3.6-x86_64.apk'].Length) bytes)
  - MD5:    $($info['YumiHub-Android-TV-0.3.6-x86_64.apk'].MD5)
  - SHA256: $($info['YumiHub-Android-TV-0.3.6-x86_64.apk'].SHA256)

[Windows Packages - YomiHub 0.3.6 x64]
* YomiHub-0.3.6-windows-x64-Setup.exe (Bản cài đặt tự động)
  - Dung lượng: $($info['YomiHub-0.3.6-windows-x64-Setup.exe'].SizeMB) MB ($($info['YomiHub-0.3.6-windows-x64-Setup.exe'].Length) bytes)
  - MD5:    $($info['YomiHub-0.3.6-windows-x64-Setup.exe'].MD5)
  - SHA256: $($info['YomiHub-0.3.6-windows-x64-Setup.exe'].SHA256)

* YomiHub-0.3.6-windows-x64.appxbundle (Bản Windows Store / Sideload có chứng chỉ số)
  - Dung lượng: $($info['YomiHub-0.3.6-windows-x64.appxbundle'].SizeMB) MB ($($info['YomiHub-0.3.6-windows-x64.appxbundle'].Length) bytes)
  - MD5:    $($info['YomiHub-0.3.6-windows-x64.appxbundle'].MD5)
  - SHA256: $($info['YomiHub-0.3.6-windows-x64.appxbundle'].SHA256)

* YomiHub-0.3.6-windows-x64.zip (Bản Portable tiêu chuẩn không cần cài đặt)
  - Dung lượng: $($info['YomiHub-0.3.6-windows-x64.zip'].SizeMB) MB ($($info['YomiHub-0.3.6-windows-x64.zip'].Length) bytes)
  - MD5:    $($info['YomiHub-0.3.6-windows-x64.zip'].MD5)
  - SHA256: $($info['YomiHub-0.3.6-windows-x64.zip'].SHA256)

* YomiHub-0.3.6-windows-x64-full.zip (Bản Portable tích hợp sẵn M-Extension-Server JRE + Tor + Xray)
  - Dung lượng: $($info['YomiHub-0.3.6-windows-x64-full.zip'].SizeMB) MB ($($info['YomiHub-0.3.6-windows-x64-full.zip'].Length) bytes)
  - MD5:    $($info['YomiHub-0.3.6-windows-x64-full.zip'].MD5)
  - SHA256: $($info['YomiHub-0.3.6-windows-x64-full.zip'].SHA256)

--------------------------------------------------------------------------------
3. CHI TIẾT CÁC TÍNH NĂNG MỚI VÀ VÁ LỖI (NEW FEATURES & BUG FIXES IN v0.3.6)
--------------------------------------------------------------------------------
1. Vá triệt để các lỗi tiện ích mở rộng ghi nhận trong nhật ký hoạt động:
   - YouTube: Sửa lỗi cú pháp phản hồi HTML (SyntaxError '<') khi phân tích dữ liệu luồng video và metadata, tăng độ bền bỉ khi trích xuất streams và subtitles.
   - Hako (Light Novel): Tăng timeout kết nối, bổ sung cơ chế thử lại (retry logic) khi mạng phản hồi chậm, tránh tình trạng gián đoạn danh sách chương truyện.
   - RoPhim: Xử lý lỗi Network Unreachable thông qua cơ chế tự động thử qua mirror và cập nhật User-Agent tiêu chuẩn YomiHub/0.3.6.
   - Anime47: Bổ sung cookie authentication bypass và tự động cập nhật header phiên truy cập, đảm bảo lấy trọn vẹn danh sách tập phim và server phát trực tiếp.

2. Nâng cấp phiên bản toàn diện lên v0.3.6 (Build 28):
   - Chuẩn hóa chuỗi định danh HTTP Client: userAgent = 'YomiHub/0.3.6' trên toàn hệ thống mạng.
   - Đồng bộ hóa phiên bản trong pubspec.yaml (0.3.6+28), app_identity.dart, và toàn bộ các tiện ích mở rộng tích hợp.

3. Hoàn thiện bộ cài đặt và ký số Windows Release 0.3.6:
   - Bản Setup .exe: Cài đặt mượt mà, tự động đăng ký shortcut và gỡ cài đặt sạch sẽ.
   - Bản .appxbundle: Ký số chuẩn với chứng chỉ số hợp lệ `YomiHub-RootCA.cer`, đi kèm script `Install-YomiHub.bat` và `Install-YomiHub.ps1` hỗ trợ cài đặt tự động một chạm.
   - Bản Portable tiêu chuẩn và Portable Full (tích hợp JRE 17, Tor daemon, Xray core).

4. Chuyên biệt hóa phiên bản Android TV (YumiHub Android TV 0.3.6):
   - Đặt tên hiển thị ứng dụng chuẩn xác: "YumiHub Android TV".
   - Loại bỏ hoàn toàn 2 phân hệ Truyện tranh và Tiểu thuyết, tập trung 100% vào Phim, Hoạt hình và Truyền hình.
   - Tối ưu hóa điều hướng D-pad Remote, phản hồi nhanh nhạy trên màn hình TV lớn.

================================================================================
"@

$clPath = Join-Path $outDir "YomiHub-0.3.6-changelog.txt"
Set-Content -Path $clPath -Value $changelog -Encoding UTF8
Write-Host "Changelog written to $clPath" -ForegroundColor Green
