# test_and_record_037.ps1: Complete automated testing & recording for YomiHub 0.3.7
param(
    [string]$outDir = "D:\A.I Project\YomiHub Project\output\screenshots",
    [string]$artDir = "C:\Users\nguye\.gemini\antigravity\brain\8baf8f3f-01fa-4e4d-9c9b-44c1e5eca073"
)

New-Item -ItemType Directory -Force -Path $outDir,$artDir | Out-Null

$emu = "C:\Users\nguye\AppData\Local\Android\Sdk\emulator\emulator.exe"
$adb = "C:\Users\nguye\AppData\Local\Android\Sdk\platform-tools\adb.exe"
if (-not (Test-Path $adb)) {
    $adb = "D:\yh\tools\android-sdk\platform-tools\adb.exe"
}

Write-Host "==========================================================" -ForegroundColor Green
Write-Host " KIEM TRA VA KHOI DONG ANDROID EMULATOR (NEU CHUA CO)" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green

$devs = (& $adb devices) -join " "
$emuProc = $null
if ($devs -notmatch 'emulator-\d+\s+device') {
    Write-Host "Khoi dong Android Emulator (Medium_Phone_API_37.0)..." -ForegroundColor Yellow
    $emuProc = Start-Process -FilePath $emu -ArgumentList "-avd Medium_Phone_API_37.0 -memory 2048 -no-snapshot-save -no-boot-anim -no-audio -gpu swiftshader_indirect -dns-server 8.8.8.8,1.1.1.1" -PassThru
    Write-Host "Process Emulator PID: $($emuProc.Id)"
    for ($i = 0; $i -lt 60; $i++) {
        Start-Sleep 3
        $devs = (& $adb devices) -join " "
        if ($devs -match 'emulator-\d+\s+device') {
            Write-Host "Thiet bi ADB da ket noi!" -ForegroundColor Green
            break
        }
    }
    $t0 = Get-Date
    Write-Host "Cho Android boot hoan tat (sys.boot_completed)..." -ForegroundColor Cyan
    while (((& $adb shell getprop sys.boot_completed 2>&1) -join '').Trim() -ne '1') {
        if (((Get-Date) - $t0).TotalSeconds -gt 180) { break }
        Start-Sleep 3
    }
    Write-Host "Emulator da khoi dong thanh cong!" -ForegroundColor Green
    & $adb shell "input keyevent 82" # Mo khoa man hinh
    Start-Sleep 1
    & $adb shell "input keyevent 3"  # Home
} else {
    Write-Host "Emulator da dang ket noi san sang!" -ForegroundColor Green
    & $adb shell "input keyevent 82"
    Start-Sleep 1
    & $adb shell "input keyevent 3"
}

function Snap($name) {
    Write-Host ">> [Chup man hinh] $name" -ForegroundColor Cyan
    & $adb shell screencap -p /sdcard/$name
    & $adb pull /sdcard/$name "$outDir\$name" | Out-Null
    if (Test-Path "$outDir\$name") {
        Copy-Item "$outDir\$name" "$artDir\$name" -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "==========================================================" -ForegroundColor Green
Write-Host " PHAN 1: KIEM THU WINDOWS RELEASE 0.3.7" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green

Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue

$winExe = "D:\yh\buildwin\mangayomi\build\windows\x64\runner\Release\YomiHub.exe"
if (Test-Path $winExe) {
    Write-Host "Khoi chay YomiHub Windows 0.3.7..."
    $winProc = Start-Process -FilePath $winExe -PassThru
    Start-Sleep -Seconds 8

    try {
        $bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
        $bmp = New-Object System.Drawing.Bitmap($bounds.Width, $bounds.Height)
        $graphics = [System.Drawing.Graphics]::FromImage($bmp)
        $graphics.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size)
        $bmp.Save("$outDir\35_win_yomihub_v037_main.png", [System.Drawing.Imaging.ImageFormat]::Png)
        $graphics.Dispose()
        $bmp.Dispose()
        Copy-Item "$outDir\35_win_yomihub_v037_main.png" "$artDir\35_win_yomihub_v037_main.png" -Force -ErrorAction SilentlyContinue
        Write-Host "Da chup man hinh Windows 0.3.7: 35_win_yomihub_v037_main.png" -ForegroundColor Green
    } catch {
        Write-Warning "Khong the capture man hinh Windows Desktop truc tiep: $_"
    }

    Stop-Process -Id $winProc.Id -Force -ErrorAction SilentlyContinue
}

Write-Host "==========================================================" -ForegroundColor Green
Write-Host " PHAN 2: KIEM THU CHI TIET VA GHI HINH YOMIHUB MOBILE 0.3.7" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green

$apkMobile = "D:\A.I Project\YomiHub Project\output\YomiHub-0.3.7-x86_64.apk"
Write-Host "Cai dat YomiHub Mobile 0.3.7: $apkMobile..."
& $adb install -r $apkMobile
Start-Sleep 3

# Bat dau quay video Mobile Walkthrough
& $adb shell rm -f /sdcard/yomihub_v037_mobile_walkthrough.mp4
$recProc = Start-Process -FilePath $adb -ArgumentList "shell screenrecord --size 720x1600 --bit-rate 4000000 --time-limit 180 /sdcard/yomihub_v037_mobile_walkthrough.mp4" -PassThru

# Khoi chay YomiHub Mobile
& $adb shell "am force-stop com.yomihub.app"
Start-Sleep 1
& $adb shell "am start -n com.yomihub.app/com.kodjodevf.mangayomi.MainActivity"
Start-Sleep 6

# Tab 1: Truyen tranh (X = 67, Y = 2232)
Write-Host "[1/30] Kiem tra Tab 1: Truyen tranh..."
& $adb shell "input tap 67 2232"
Start-Sleep 2
Snap "01_tab1_truyen_tranh.png"

# Tab 2: Phim & Dien anh (X = 202, Y = 2232)
Write-Host "[2/30] Kiem tra Tab 2: Phim & Dien anh..."
& $adb shell "input tap 202 2232"
Start-Sleep 2
Snap "02_tab2_phim_dien_anh.png"

# Tab 3: Tieu thuyet (X = 337, Y = 2232)
Write-Host "[3/30] Kiem tra Tab 3: Tieu thuyet..."
& $adb shell "input tap 337 2232"
Start-Sleep 2
Snap "03_tab3_tieu_thuyet.png"

# Tab 4: Play Books (X = 472, Y = 2232)
Write-Host "[4/30] Kiem tra Tab 4: Google Play Books (Material 3)..."
& $adb shell "input tap 472 2232"
Start-Sleep 3
Snap "04_tab4_play_books_main.png"

# Play Books Chips
Write-Host "[5/30] Bam Filter Chip: Sach noi..."
& $adb shell "input tap 230 240"
Start-Sleep 2
Snap "05_tab4_play_books_chip_sach_noi.png"

Write-Host "[6/30] Bam Filter Chip: Truyen tranh..."
& $adb shell "input tap 400 240"
Start-Sleep 2
Snap "06_tab4_play_books_chip_truyen_tranh.png"

Write-Host "[7/30] Bam Filter Chip: Ban chay nhat..."
& $adb shell "input tap 600 240"
Start-Sleep 2
Snap "07_tab4_play_books_chip_ban_chay.png"

# Play Books Subtabs
Write-Host "[8/30] Play Books Subtab: Thu vien..."
& $adb shell "input tap 400 2050"
Start-Sleep 2
Snap "08_tab4_play_books_subtab_thu_vien.png"

Write-Host "[9/30] Play Books Subtab: Cua hang..."
& $adb shell "input tap 670 2050"
Start-Sleep 2
Snap "09_tab4_play_books_subtab_cua_hang.png"

Write-Host "[10/30] Play Books Subtab: Sach noi..."
& $adb shell "input tap 940 2050"
Start-Sleep 2
Snap "10_tab4_play_books_subtab_sach_noi.png"

# Tab 5: Cap nhat (X = 607, Y = 2232)
Write-Host "[11/30] Kiem tra Tab 5: Cap nhat..."
& $adb shell "input tap 607 2232"
Start-Sleep 2
Snap "11_tab5_cap_nhat.png"

# Tab 6: Lich su (X = 742, Y = 2232)
Write-Host "[12/30] Kiem tra Tab 6: Lich su doc & xem (Grid View)..."
& $adb shell "input tap 742 2232"
Start-Sleep 2
Snap "12_tab6_lich_su.png"

# Tab 7: Duyet (X = 877, Y = 2232)
Write-Host "[13/30] Kiem tra Tab 7: Duyet..."
& $adb shell "input tap 877 2232"
Start-Sleep 2
Snap "13_tab7_duyet_nguon.png"

# Duyet Subtab: Tien ich mo rong (X = 540, Y = 415)
Write-Host "[14/30] Duyet Subtab: Tien ich mo rong..."
& $adb shell "input tap 540 415"
Start-Sleep 3
Snap "14_tab7_duyet_tien_ich.png"

# Duyet Subtab: De xuat (X = 886, Y = 415)
Write-Host "[15/30] Duyet Subtab: De xuat..."
& $adb shell "input tap 886 415"
Start-Sleep 2
Snap "15_tab7_duyet_de_xuat.png"

# Tab 8: Them (X = 1012, Y = 2232)
Write-Host "[16/30] Kiem tra Tab 8: Them..."
& $adb shell "input tap 1012 2232"
Start-Sleep 2
Snap "16_tab8_them_main.png"

# Hop nhat tien ich
Write-Host "[17/30] Mo Hop nhat tien ich..."
& $adb shell "input tap 540 1740"
Start-Sleep 2
Snap "17_tab8_hop_nhat_tien_ich.png"
& $adb shell "input keyevent 4" # Back
Start-Sleep 1

# Cuon xuong phan Cai dat va Gioi thieu
Write-Host "[18/30] Cuon xuong Cai dat va Gioi thieu..."
& $adb shell "input swipe 540 1800 540 500 300"
Start-Sleep 2
Snap "18_tab8_them_scrolled.png"

# Mo Cai dat (X = 540, Y = 1906)
Write-Host "[19/30] Mo Cai dat..."
& $adb shell "input tap 540 1906"
Start-Sleep 2
Snap "19_cai_dat_main.png"

# Cai dat Giao dien
Write-Host "[20/30] Cai dat Giao dien..."
& $adb shell "input tap 540 380"
Start-Sleep 2
Snap "20_cai_dat_giao_dien.png"
& $adb shell "input keyevent 4"
Start-Sleep 1

# Cai dat Trinh doc
Write-Host "[21/30] Cai dat Trinh doc..."
& $adb shell "input tap 540 700"
Start-Sleep 2
Snap "21_cai_dat_trinh_doc.png"
& $adb shell "input keyevent 4"
Start-Sleep 1

# Cai dat Trinh phat video
Write-Host "[22/30] Cai dat Trinh phat video..."
& $adb shell "input tap 540 880"
Start-Sleep 2
Snap "22_cai_dat_trinh_phat_video.png"
& $adb shell "input keyevent 4"
Start-Sleep 1

# Cai dat Du lieu va bo nho
Write-Host "[23/30] Cai dat Du lieu va bo nho..."
& $adb shell "input swipe 540 1800 540 800 300"
Start-Sleep 1
& $adb shell "input tap 540 1000"
Start-Sleep 2
Snap "23_cai_dat_du_lieu_bo_nho.png"

# Gop truyen thu cong
Write-Host "[24/30] Mo Gop truyen thu cong..."
& $adb shell "input swipe 540 1800 540 900 300"
Start-Sleep 1
& $adb shell "input tap 540 1200"
Start-Sleep 2
Snap "24_gop_truyen_thu_cong.png"
& $adb shell "input keyevent 4"
Start-Sleep 1
& $adb shell "input keyevent 4"
Start-Sleep 1

# Cai dat Nang cao
Write-Host "[25/30] Cai dat Nang cao..."
& $adb shell "input swipe 540 1800 540 600 300"
Start-Sleep 1
& $adb shell "input tap 540 1400"
Start-Sleep 2
Snap "25_cai_dat_nang_cao.png"
& $adb shell "input keyevent 4"
Start-Sleep 1
& $adb shell "input keyevent 4" # Back ve Them
Start-Sleep 1

# Mo Gioi thieu (X = 540, Y = 2053)
Write-Host "[26/30] Mo Gioi thieu (Phien ban 0.3.7)..."
& $adb shell "input tap 540 2053"
Start-Sleep 2
Snap "26_gioi_thieu_v037.png"

# Mo Nhat ky ung dung
Write-Host "[27/30] Mo Nhat ky ung dung..."
& $adb shell "input tap 540 1880"
Start-Sleep 2
Snap "27_nhat_ky_ung_dung.png"
& $adb shell "input keyevent 4"
Start-Sleep 1

# Mo Du an GitHub da su dung
Write-Host "[28/30] Mo Du an GitHub da su dung..."
& $adb shell "input tap 540 1334"
Start-Sleep 3
Snap "28_du_an_github_main.png"

# Cuon va mo rong nhom Van phong & Tai lieu
Write-Host "[29/30] Xem nhom Van phong & Tai lieu..."
& $adb shell "input swipe 540 1800 540 500 300"
Start-Sleep 1
& $adb shell "input tap 540 1600"
Start-Sleep 2
Snap "29_du_an_github_office_suite.png"

# Cuon xem AI Chatbot, Cloud va DeX Mode
Write-Host "[30/30] Xem nhom AI Chatbot, Cloud va DeX Mode..."
& $adb shell "input swipe 540 1800 540 500 300"
Start-Sleep 1
Snap "30_du_an_github_ai_cloud_dex.png"

# Dung quay video Mobile
Write-Host "Dung va luu video Mobile Walkthrough..."
& $adb shell "pkill -2 screenrecord"
Start-Sleep 4
if (-not $recProc.HasExited) { Stop-Process -Id $recProc.Id -Force -ErrorAction SilentlyContinue }
& $adb pull /sdcard/yomihub_v037_mobile_walkthrough.mp4 "$outDir\yomihub_v037_mobile_walkthrough.mp4" | Out-Null
if (Test-Path "$outDir\yomihub_v037_mobile_walkthrough.mp4") {
    Copy-Item "$outDir\yomihub_v037_mobile_walkthrough.mp4" "$artDir\yomihub_v037_mobile_walkthrough.mp4" -Force -ErrorAction SilentlyContinue
    Write-Host ("Video Mobile hoan tat ({0:N1} MB)" -f ((Get-Item "$outDir\yomihub_v037_mobile_walkthrough.mp4").Length/1MB)) -ForegroundColor Green
}

Write-Host "==========================================================" -ForegroundColor Yellow
Write-Host " PHAN 3: KIEM THU CHUYEN DUNG YUMI HUB ANDROID TV (0.3.7)" -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Yellow

$apkTv = "D:\A.I Project\YomiHub Project\output\YumiHub-Android-TV-0.3.7-x86_64.apk"
Write-Host "Cai dat YumiHub Android TV: $apkTv..."
& $adb install -r $apkTv
Start-Sleep 3

# Bat dau quay video TV Walkthrough
& $adb shell rm -f /sdcard/yumihub_v037_tv_walkthrough.mp4
$recTvProc = Start-Process -FilePath $adb -ArgumentList "shell screenrecord --size 720x1600 --bit-rate 4000000 --time-limit 180 /sdcard/yumihub_v037_tv_walkthrough.mp4" -PassThru

# Khoi chay TV App
& $adb shell "am force-stop com.yomihub.app"
Start-Sleep 1
& $adb shell "am start -n com.yomihub.app/com.kodjodevf.mangayomi.MainActivity"
Start-Sleep 6
Snap "31_tv_home_dashboard.png"

# Thuc hien dieu huong D-Pad Remote TV
& $adb shell "input keyevent 20" # Down
Start-Sleep 1
Snap "32_tv_dpad_down_nav.png"

& $adb shell "input keyevent 22" # Right
Start-Sleep 1
Snap "33_tv_dpad_item_focus.png"

& $adb shell "input keyevent 19" # Up
Start-Sleep 1
Snap "34_tv_nav_bar_focus.png"

# Dung quay video TV
Write-Host "Dung va luu video TV Walkthrough..."
& $adb shell "pkill -2 screenrecord"
Start-Sleep 4
if (-not $recTvProc.HasExited) { Stop-Process -Id $recTvProc.Id -Force -ErrorAction SilentlyContinue }
& $adb pull /sdcard/yumihub_v037_tv_walkthrough.mp4 "$outDir\yumihub_v037_tv_walkthrough.mp4" | Out-Null
if (Test-Path "$outDir\yumihub_v037_tv_walkthrough.mp4") {
    Copy-Item "$outDir\yumihub_v037_tv_walkthrough.mp4" "$artDir\yumihub_v037_tv_walkthrough.mp4" -Force -ErrorAction SilentlyContinue
    Write-Host ("Video TV hoan tat ({0:N1} MB)" -f ((Get-Item "$outDir\yumihub_v037_tv_walkthrough.mp4").Length/1MB)) -ForegroundColor Green
}

Write-Host "==========================================================" -ForegroundColor Green
Write-Host " HOAN TAT TOAN BO KIEM THU THUC TE CHI TIET CHO BAN 0.3.7!" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
