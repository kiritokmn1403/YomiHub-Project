# test_all_features_deep.ps1: Deep comprehensive testing of all features and settings in YomiHub 0.3.3
param(
    [string]$outDir = "D:\A.I Project\A.I Project - YomiHub Project\output\screenshots",
    [string]$artDir = "C:\Users\nguye\.gemini\antigravity\brain\1a3c0eed-bdc1-409b-992d-85c81d759828"
)

New-Item -ItemType Directory -Force -Path $outDir,$artDir | Out-Null

$adb = "D:\yh\tools\android-sdk\platform-tools\adb.exe"
if (-not (Test-Path $adb)) {
    $adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
}
$emu = "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe"

function Ensure-Emulator {
    Write-Host "[1/20] Kiem tra trang thai Android Emulator..." -ForegroundColor Cyan
    $state = ((& $adb get-state 2>&1) -join '').Trim()
    if ($state -ne 'device') {
        Write-Host "Khoi dong Android Emulator (Medium_Phone_API_37.0)..." -ForegroundColor Yellow
        $cmd = '"' + $emu + '" -avd Medium_Phone_API_37.0 -memory 2048 -no-snapshot-save -no-boot-anim -no-audio -dns-server 8.8.8.8,1.1.1.1'
        Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = $cmd } | Out-Null
        for ($i = 0; $i -lt 60; $i++) {
            if (((& $adb devices) -join ' ') -match 'emulator-\d+\s+device') { break }
            Start-Sleep 5
        }
    }
    $t0 = Get-Date
    while (((& $adb shell getprop sys.boot_completed 2>&1) -join '').Trim() -ne '1') {
        if (((Get-Date) - $t0).TotalSeconds -gt 180) { break }
        Start-Sleep 3
    }
    Write-Host "Emulator da khoi dong xong!" -ForegroundColor Green
    & $adb shell "input keyevent 82" # Unlock keyguard
    Start-Sleep 1
}

function Snap($filename) {
    Write-Host ">> [Chup anh] $filename" -ForegroundColor DarkCyan
    & $adb shell screencap -p /sdcard/$filename
    & $adb pull /sdcard/$filename "$outDir\$filename" | Out-Null
    if (Test-Path "$outDir\$filename") {
        Copy-Item "$outDir\$filename" "$artDir\$filename" -Force -ErrorAction SilentlyContinue
    }
}

Ensure-Emulator

$wm = (& $adb shell wm size) -join ''
Write-Host "Do phan giai man hinh thiet bi: $wm" -ForegroundColor Yellow

Write-Host "==========================================================" -ForegroundColor Green
Write-Host " PHAN 1: KIEM THU TOAN DIEN CAC TINH NANG YOMIHUB 0.3.4 MOBILE" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green

$apkMobile = "D:\A.I Project\A.I Project - YomiHub Project\output\YomiHub-0.3.4-x86_64.apk"
Write-Host "[2/20] Cai dat APK YomiHub 0.3.4: $apkMobile..."
& $adb install -r $apkMobile
Start-Sleep 3

# Reset du lieu de vao trang thai sach
& $adb shell "pm clear com.yomihub.app"
Start-Sleep 2

# Khoi chay YomiHub Mobile
Write-Host "[3/20] Khoi chay YomiHub Mobile..."
& $adb shell "am start -n com.yomihub.app/com.kodjodevf.mangayomi.MainActivity"
Start-Sleep 6

# Bat dau quay video YomiHub Mobile
Write-Host "[4/20] Bat dau quay video kiem thu toan dien YomiHub Mobile..."
& $adb shell rm -f /sdcard/yomihub_v034_deep_mobile_test.mp4
$recProc = Start-Process -FilePath $adb -ArgumentList "shell screenrecord --size 720x1600 --bit-rate 4000000 --time-limit 180 /sdcard/yomihub_v034_deep_mobile_test.mp4" -PassThru

# 1. Man hinh chao mung / Onboarding
Snap "deep_01_onboarding.png"

# Nhan Tiep tuc / Hoan tat onboarding
& $adb shell "input tap 540 1518"
Start-Sleep 2
& $adb shell "input tap 540 1854"
Start-Sleep 2
& $adb shell "input tap 540 2100"
Start-Sleep 2

# 2. Tab Thu vien (Library) - Manga / Anime / Novel
Snap "deep_02_library_manga.png"

# Chuyen sang phan loai Anime trong Thu vien
& $adb shell "input tap 360 160"
Start-Sleep 2
Snap "deep_03_library_anime.png"

# Chuyen sang phan loai Novel trong Thu vien
& $adb shell "input tap 540 160"
Start-Sleep 2
Snap "deep_04_library_novel.png"

# 3. Tab Cap nhat (Updates - Tab 2)
Write-Host "[5/20] Kiem tra Tab Cap nhat..."
& $adb shell "input tap 280 2320"
Start-Sleep 2
Snap "deep_05_tab_updates.png"

# 4. Tab Lich su (History - Tab 3)
Write-Host "[6/20] Kiem tra Tab Lich su..."
& $adb shell "input tap 460 2320"
Start-Sleep 2
Snap "deep_06_tab_history.png"

# 5. Tab Kham pha & Nguon mo rong (Browse - Tab 4)
Write-Host "[7/20] Kiem tra Tab Kham pha & Nguon mo rong..."
& $adb shell "input tap 680 2320"
Start-Sleep 3
Snap "deep_07_browse_sources_list.png"

# Chuyen sang Tab Extension (Tien ich mo rong)
Write-Host "[8/20] Kiem tra danh sach Tien ich mo rong & Phimmoi Extension..."
& $adb shell "input tap 540 160"
Start-Sleep 3
Snap "deep_08_browse_extensions_tab.png"

# Tim kiem extension Phimmoi
& $adb shell "input tap 980 160" # Nut search hoac filter
Start-Sleep 1
& $adb shell "input text phimmoi"
Start-Sleep 2
Snap "deep_09_browse_phimmoi_search.png"
& $adb shell "input keyevent 4" # Dong ban phim
Start-Sleep 1

# Chuyen sang Tab Chuyen doi nguon (Migrate)
& $adb shell "input tap 820 160"
Start-Sleep 2
Snap "deep_10_browse_migrate_tab.png"

# 6. Tab GOOGLE PLAY BOOKS (Material 3 Redesign)
Write-Host "[9/20] Kiem tra Tab Google Play Books (Material 3 UI)..."
# Chuyen sang Tab Google Play Books (Tab tren thanh dieu huong chinh)
& $adb shell "input tap 840 2320"
Start-Sleep 3
Snap "deep_11_play_books_home.png"

# Bam cac Filter Chips: Ebook, Sach noi, Truyen tranh, Ban chay nhat, Mien phi
Write-Host "[10/20] Thu nghiem cac Filter Chips tren Play Books..."
& $adb shell "input tap 100 240" # Ebook chip
Start-Sleep 1
Snap "deep_12_play_books_chip_ebook.png"

& $adb shell "input tap 230 240" # Sach noi chip
Start-Sleep 1
Snap "deep_13_play_books_chip_audiobook.png"

& $adb shell "input tap 400 240" # Truyen tranh chip
Start-Sleep 1
Snap "deep_14_play_books_chip_comic.png"

& $adb shell "input tap 600 240" # Ban chay nhat chip
Start-Sleep 1
Snap "deep_15_play_books_chip_bestseller.png"

# Bam thanh tim kiem SearchBar Play Books
& $adb shell "input tap 500 130"
Start-Sleep 1
& $adb shell "input text dac+nhan+tam"
Start-Sleep 2
Snap "deep_16_play_books_search_input.png"
& $adb shell "input keyevent 4" # Dong ban phim
Start-Sleep 1

# Bam thanh dieu huong day trang Play Books: Thu vien, Cua hang, Sach noi
& $adb shell "input tap 400 2260" # Play Books Tab Thu vien
Start-Sleep 2
Snap "deep_17_play_books_library_subtab.png"

& $adb shell "input tap 670 2260" # Play Books Tab Cua hang
Start-Sleep 2
Snap "deep_18_play_books_shop_subtab.png"

& $adb shell "input tap 940 2260" # Play Books Tab Sach noi
Start-Sleep 2
Snap "deep_19_play_books_audio_subtab.png"

# 7. Tab THEM (More) & CAC MUC CAI DAT
Write-Host "[11/20] Kiem tra Tab Them & Danh muc Cai dat..."
& $adb shell "input tap 980 2320" # More Tab
Start-Sleep 3
Snap "deep_20_more_screen_main.png"

# Cuon xuong xem toan bo muc Them
& $adb shell "input swipe 540 1800 540 800 300"
Start-Sleep 1
Snap "deep_21_more_screen_scrolled.png"

# Mo Cài đặt (Settings)
Write-Host "[12/20] Mo chi tiet Cai dat..."
& $adb shell "input tap 540 1350"
Start-Sleep 2
Snap "deep_22_settings_menu.png"

# 7.1 Cai dat Giao dien (Appearance)
Write-Host "[13/20] Kiem tra Cai dat Giao dien (Appearance)..."
& $adb shell "input tap 540 380"
Start-Sleep 2
Snap "deep_23_settings_appearance.png"
& $adb shell "input keyevent 4" # Back
Start-Sleep 1

# 7.2 Cai dat Trinh doc truyen (Reader)
Write-Host "[14/20] Kiem tra Cai dat Trinh doc (Reader)..."
& $adb shell "input tap 540 700"
Start-Sleep 2
Snap "deep_24_settings_reader.png"
& $adb shell "input keyevent 4" # Back
Start-Sleep 1

# 7.3 Cai dat Trinh phat video (Player)
Write-Host "[15/20] Kiem tra Cai dat Trinh phat video (Player)..."
& $adb shell "input tap 540 880"
Start-Sleep 2
Snap "deep_25_settings_player.png"
& $adb shell "input keyevent 4" # Back
Start-Sleep 1

# 7.4 Cai dat Du lieu & Luu tru (Data & Storage)
Write-Host "[16/20] Kiem tra Du lieu & Luu tru (Gop truyen, Gop nguon, Cloud)..."
& $adb shell "input swipe 540 1800 540 900 300"
Start-Sleep 1
& $adb shell "input tap 540 900" # Data & Storage
Start-Sleep 2
Snap "deep_26_settings_data_and_storage.png"

# Cuon xuong muc Gop truyen thu cong & Gop nguon tuy chon
& $adb shell "input swipe 540 1800 540 900 300"
Start-Sleep 1
Snap "deep_27_data_storage_merge_options.png"

# Mo man hinh Gop truyen thu cong
Write-Host "Kiem tra tinh nang Gop truyen thu cong..."
& $adb shell "input tap 540 1200"
Start-Sleep 2
Snap "deep_28_manual_content_merge_screen.png"
& $adb shell "input keyevent 4" # Back
Start-Sleep 1

# Mo man hinh Gop nguon tuy chon
Write-Host "Kiem tra tinh nang Gop nguon tuy chon..."
& $adb shell "input tap 540 1380"
Start-Sleep 2
Snap "deep_29_custom_extension_merge_screen.png"
& $adb shell "input keyevent 4" # Back
Start-Sleep 1

# Quay lai menu Cai dat
& $adb shell "input keyevent 4"
Start-Sleep 1

# 7.5 Cai dat Nang cao & Nhat ky ung dung (Advanced & App Log)
Write-Host "[17/20] Kiem tra Cai dat Nang cao & Nhat ky ung dung (App Log)..."
& $adb shell "input swipe 540 1800 540 600 300"
Start-Sleep 1
& $adb shell "input tap 540 1400" # Advanced
Start-Sleep 2
Snap "deep_30_settings_advanced.png"

# Mo Nhat ky ung dung (App Log Viewer)
& $adb shell "input tap 540 500" # App Log
Start-Sleep 2
Snap "deep_31_app_log_viewer.png"
& $adb shell "input keyevent 4" # Back
Start-Sleep 1
& $adb shell "input keyevent 4" # Back ra menu More
Start-Sleep 1

# 8. Muc Gioi thieu (About) & Danh muc Du an nguon mo GitHub
Write-Host "[18/20] Kiem tra Muc Gioi thieu & Danh muc Du an GitHub..."
& $adb shell "input tap 540 1780" # About
Start-Sleep 2
Snap "deep_32_about_screen.png"

# Mo Danh muc Du an nguon mo GitHub (Open Source Projects)
& $adb shell "input tap 540 1100" # GitHub Projects
Start-Sleep 3
Snap "deep_33_github_projects_office_suite.png"

# Cuon trang xem toan bo danh muc Office Suite, AI, Cloud, DeX
& $adb shell "input swipe 540 1800 540 600 300"
Start-Sleep 2
Snap "deep_34_github_projects_ai_and_cloud.png"

& $adb shell "input swipe 540 1800 540 600 300"
Start-Sleep 2
Snap "deep_35_github_projects_dex_and_scanners.png"

# Dung quay video YomiHub Mobile
Write-Host "[19/20] Dung va trich xuat video YomiHub Mobile..."
& $adb shell "pkill -2 screenrecord"
Start-Sleep 4
if (-not $recProc.HasExited) { Stop-Process -Id $recProc.Id -Force -ErrorAction SilentlyContinue }
& $adb pull /sdcard/yomihub_v034_deep_mobile_test.mp4 "$outDir\yomihub_v034_deep_mobile_test.mp4" | Out-Null
if (Test-Path "$outDir\yomihub_v034_deep_mobile_test.mp4") {
    Copy-Item "$outDir\yomihub_v034_deep_mobile_test.mp4" "$artDir\yomihub_v034_deep_mobile_test.mp4" -Force -ErrorAction SilentlyContinue
    $len = (Get-Item "$outDir\yomihub_v034_deep_mobile_test.mp4").Length / 1MB
    Write-Host ("Video YomiHub Mobile luu thanh cong ({0:N1} MB)" -f $len) -ForegroundColor Green
}

Write-Host "==========================================================" -ForegroundColor Yellow
Write-Host " PHAN 2: KIEM THU TOAN DIEN YUMI HUB ANDROID TV (0.3.4)" -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Yellow

$apkTv = "D:\A.I Project\A.I Project - YomiHub Project\output\YumiHub-Android-TV-0.3.4-x86_64.apk"
Write-Host "[20/20] Cai dat APK YumiHub Android TV: $apkTv..."
& $adb install -r $apkTv
Start-Sleep 3

# Bat dau quay video TV
& $adb shell rm -f /sdcard/yumihub_tv_v034_deep_test.mp4
$recTvProc = Start-Process -FilePath $adb -ArgumentList "shell screenrecord --size 720x1600 --bit-rate 4000000 --time-limit 180 /sdcard/yumihub_tv_v034_deep_test.mp4" -PassThru

# Khoi chay TV App
& $adb shell "am force-stop com.yomihub.app"
Start-Sleep 1
& $adb shell "am start -n com.yomihub.app/com.kodjodevf.mangayomi.MainActivity"
Start-Sleep 6
Snap "deep_36_tv_main_dashboard.png"

# Thuc hien dieu huong D-Pad Remote TV
& $adb shell "input keyevent 20" # Down
Start-Sleep 1
Snap "deep_37_tv_dpad_down.png"

& $adb shell "input keyevent 20" # Down tiep
Start-Sleep 1
Snap "deep_38_tv_dpad_rows.png"

& $adb shell "input keyevent 22" # Right
Start-Sleep 1
Snap "deep_39_tv_dpad_item_focus.png"

& $adb shell "input keyevent 19" # Up
Start-Sleep 1
& $adb shell "input keyevent 19" # Up ve thanh dieu huong
Start-Sleep 1
Snap "deep_40_tv_nav_bar_focus.png"

# Dung quay video TV
Write-Host "Dung va trich xuat video YumiHub Android TV..."
& $adb shell "pkill -2 screenrecord"
Start-Sleep 4
if (-not $recTvProc.HasExited) { Stop-Process -Id $recTvProc.Id -Force -ErrorAction SilentlyContinue }
& $adb pull /sdcard/yumihub_tv_v034_deep_test.mp4 "$outDir\yumihub_tv_v034_deep_test.mp4" | Out-Null
if (Test-Path "$outDir\yumihub_tv_v034_deep_test.mp4") {
    Copy-Item "$outDir\yumihub_tv_v034_deep_test.mp4" "$artDir\yumihub_tv_v034_deep_test.mp4" -Force -ErrorAction SilentlyContinue
    $lenTv = (Get-Item "$outDir\yumihub_tv_v034_deep_test.mp4").Length / 1MB
    Write-Host ("Video YumiHub Android TV luu thanh cong ({0:N1} MB)" -f $lenTv) -ForegroundColor Green
}

Write-Host "==========================================================" -ForegroundColor Green
Write-Host " HOAN TAT KIEM THU TOAN DIEN TOAN BO CAC TINH NANG VA CAI DAT!" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
