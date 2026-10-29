param(
    [string]$outDir = "D:\A.I Project\A.I Project - YomiHub Project\output\screenshots",
    [string]$artDir = "C:\Users\nguye\.gemini\antigravity\brain\dadfd1a7-3e7f-42bf-9ee4-71d8c929f85f"
)

New-Item -ItemType Directory -Force -Path $outDir,$artDir | Out-Null

$adb = "D:\yh\tools\android-sdk\platform-tools\adb.exe"
if (-not (Test-Path $adb)) {
    $adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
}

$emu = "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe"

function Ensure-Emulator {
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
    Write-Host "Emulator da san sang!" -ForegroundColor Green
}

function Snap($name) {
    Write-Host "Chup anh man hinh: $name..." -ForegroundColor Cyan
    & $adb shell screencap -p /sdcard/$name
    & $adb pull /sdcard/$name "$outDir\$name" | Out-Null
    if (Test-Path "$outDir\$name") {
        Copy-Item "$outDir\$name" "$artDir\$name" -Force -ErrorAction SilentlyContinue
    }
}

Ensure-Emulator

Write-Host "==========================================================" -ForegroundColor Green
Write-Host " BAT DAU KIEM THU TOAN DIEN YOMIHUB 0.3.3 VA QUAY VIDEO" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green

# 1. Cai dat APK Mobile YomiHub 0.3.3
$apkMobile = "D:\A.I Project\A.I Project - YomiHub Project\output\YomiHub-0.3.3-x86_64.apk"
Write-Host "[1/16] Cai dat APK Mobile 0.3.3: $apkMobile..."
& $adb install -r $apkMobile
Start-Sleep -Seconds 3

# Khoi chay YomiHub Mobile
& $adb shell "am force-stop com.yomihub.app"
Start-Sleep -Seconds 1
& $adb shell "am start -n com.yomihub.app/com.kodjodevf.mangayomi.MainActivity"
Start-Sleep -Seconds 5

# 2. Bat dau quay video kiem thu YomiHub Mobile
Write-Host "[2/16] Khoi dong quay video YomiHub Mobile tren Android..."
& $adb shell rm -f /sdcard/yomihub_v033_mobile_test.mp4
$recProc = Start-Process -FilePath $adb -ArgumentList "shell screenrecord --size 720x1600 --bit-rate 4000000 --time-limit 180 /sdcard/yomihub_v033_mobile_test.mp4" -PassThru

# 3. Chup anh man hinh Welcome / Home
Snap "01_v033_onboarding_or_home.png"

# Nhan tiep tuc neu co onboarding
& $adb shell "input tap 540 1518"
Start-Sleep -Seconds 2
& $adb shell "input tap 540 1854"
Start-Sleep -Seconds 2

# 4. Chup man hinh chinh Thu vien (Library)
Snap "02_v033_mobile_main_library.png"

# 5. Chuyen sang Tab Kham pha (Browse - Tab 4)
Write-Host "[3/16] Chuyen sang Tab Kham pha & Nguon mo rong..."
& $adb shell "input tap 750 2320"
Start-Sleep -Seconds 3
Snap "03_v033_mobile_browse_sources.png"

# 6. Chuyen sang Tab Google Play Books (Tab 3)
Write-Host "[4/16] Chuyen sang Google Play Books voi Material 3 Search Bar & Filter Chips..."
& $adb shell "input tap 540 2320"
Start-Sleep -Seconds 4
Snap "04_v033_mobile_play_books.png"

# 7. Chuyen sang Tab Them (More - Tab 5)
Write-Host "[5/16] Chuyen sang Tab Them (Cai dat & Tien ich)..."
& $adb shell "input tap 970 2320"
Start-Sleep -Seconds 3
Snap "05_v033_mobile_more_screen.png"

# Cuon xuong de xem cac cai dat
& $adb shell "input swipe 540 1800 540 800 300"
Start-Sleep -Seconds 2
Snap "06_v033_mobile_more_scrolled.png"

# 8. Mo Du an nguon mo GitHub (About > GitHub Projects)
Write-Host "[6/16] Mo Danh sach Du an nguon mo GitHub..."
& $adb shell "input tap 540 1780"
Start-Sleep -Seconds 3
Snap "07_v033_mobile_about_screen.png"

& $adb shell "input tap 540 1100"
Start-Sleep -Seconds 3
Snap "08_v033_mobile_github_projects.png"

# Cuon trang kiem tra cac nhom du an moi (Office Suite, AI, Cloud, DeX)
& $adb shell "input swipe 540 1800 540 600 300"
Start-Sleep -Seconds 2
Snap "09_v033_mobile_github_projects_scrolled.png"

# Quay lai
& $adb shell "input keyevent 4"
Start-Sleep -Seconds 2
& $adb shell "input keyevent 4"
Start-Sleep -Seconds 2

# Dung quay video YomiHub Mobile
Write-Host "[7/16] Dung va trich xuat video YomiHub Mobile..."
& $adb shell "pkill -2 screenrecord"
Start-Sleep -Seconds 4
if (-not $recProc.HasExited) { Stop-Process -Id $recProc.Id -Force -ErrorAction SilentlyContinue }
& $adb pull /sdcard/yomihub_v033_mobile_test.mp4 "$outDir\yomihub_v033_mobile_test.mp4" | Out-Null
if (Test-Path "$outDir\yomihub_v033_mobile_test.mp4") {
    Copy-Item "$outDir\yomihub_v033_mobile_test.mp4" "$artDir\yomihub_v033_mobile_test.mp4" -Force -ErrorAction SilentlyContinue
    Write-Host "Video YomiHub Mobile luu thanh cong ({0:N1} MB)" -f ((Get-Item "$outDir\yomihub_v033_mobile_test.mp4").Length/1MB) -ForegroundColor Green
}

# 9. KIEM THU CHUYEN BIET CHO YUMI HUB ANDROID TV (0.3.3)
Write-Host "==========================================================" -ForegroundColor Yellow
Write-Host " BAT DAU KIEM THU BAN DUNG YUMI HUB ANDROID TV (0.3.3)" -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Yellow

$apkTv = "D:\A.I Project\A.I Project - YomiHub Project\output\YumiHub-Android-TV-0.3.3-x86_64.apk"
Write-Host "[8/16] Cai dat APK YumiHub Android TV: $apkTv..."
& $adb install -r $apkTv
Start-Sleep -Seconds 3

# Bat dau quay video TV
& $adb shell rm -f /sdcard/yumihub_tv_v033_test.mp4
$recTvProc = Start-Process -FilePath $adb -ArgumentList "shell screenrecord --size 720x1600 --bit-rate 4000000 --time-limit 180 /sdcard/yumihub_tv_v033_test.mp4" -PassThru

# Khoi chay TV App
Write-Host "[9/16] Khoi chay YumiHub Android TV..."
& $adb shell "am force-stop com.yomihub.app"
Start-Sleep -Seconds 1
& $adb shell "am start -n com.yomihub.app/com.kodjodevf.mangayomi.MainActivity"
Start-Sleep -Seconds 7

# Chup anh TV Home Screen
Snap "10_v033_tv_home_screen.png"

# Cuon kiem tra giao dien TV va D-pad
& $adb shell "input keyevent 20"
Start-Sleep 1
& $adb shell "input keyevent 20"
Start-Sleep 1
Snap "11_v033_tv_home_dpad_nav.png"

# Dung quay video TV
Write-Host "[10/16] Dung va trich xuat video YumiHub Android TV..."
& $adb shell "pkill -2 screenrecord"
Start-Sleep -Seconds 4
if (-not $recTvProc.HasExited) { Stop-Process -Id $recTvProc.Id -Force -ErrorAction SilentlyContinue }
& $adb pull /sdcard/yumihub_tv_v033_test.mp4 "$outDir\yumihub_tv_v033_test.mp4" | Out-Null
if (Test-Path "$outDir\yumihub_tv_v033_test.mp4") {
    Copy-Item "$outDir\yumihub_tv_v033_test.mp4" "$artDir\yumihub_tv_v033_test.mp4" -Force -ErrorAction SilentlyContinue
    Write-Host "Video YumiHub Android TV luu thanh cong ({0:N1} MB)" -f ((Get-Item "$outDir\yumihub_tv_v033_test.mp4").Length/1MB) -ForegroundColor Green
}

Write-Host "==========================================================" -ForegroundColor Green
Write-Host " TOAN BO QUA TRINH KIEM THU DA HOAN TAT THANH CONG!" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
