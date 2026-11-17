param(
    [string]$outDir = "D:\A.I Project\A.I Project - YomiHub Project\output\0.4.2",
    [string]$artDir = "C:\Users\nguye\.gemini\antigravity\brain\6b45d51d-55bc-4ab4-944a-d04a406c8d06"
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

New-Item -ItemType Directory -Force -Path $outDir,$artDir | Out-Null
$scDir = "D:\A.I Project\A.I Project - YomiHub Project\output\screenshots"
$vidDir = "D:\A.I Project\A.I Project - YomiHub Project\output\videos"
New-Item -ItemType Directory -Force -Path $scDir,$vidDir | Out-Null

$adb = "C:\Users\nguye\AppData\Local\Android\Sdk\platform-tools\adb.exe"
if (-not (Test-Path $adb)) { $adb = "D:\yh\tools\android-sdk\platform-tools\adb.exe" }
$emu = "C:\Users\nguye\AppData\Local\Android\Sdk\emulator\emulator.exe"
if (-not (Test-Path $emu)) { $emu = "D:\yh\tools\android-sdk\emulator\emulator.exe" }

Write-Host "==========================================================" -ForegroundColor Green
Write-Host " PHAN 1: KIEM THU WINDOWS RELEASE 0.4.2" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green

$winExe = "D:\yh\buildwin\mangayomi\build\windows\x64\runner\Release\YomiHub.exe"
if (Test-Path $winExe) {
    Write-Host "Khoi chay YomiHub Windows Release 0.4.2..." -ForegroundColor Cyan
    $winProc = Start-Process -FilePath $winExe -PassThru
    Start-Sleep -Seconds 7

    function Capture-Screen($fileName) {
        $bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
        $bmp = New-Object System.Drawing.Bitmap($bounds.Width, $bounds.Height)
        $graphics = [System.Drawing.Graphics]::FromImage($bmp)
        $graphics.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size)
        $dest1 = "$outDir\$fileName"
        $dest2 = "$scDir\$fileName"
        $dest3 = "$artDir\$fileName"
        $bmp.Save($dest1, [System.Drawing.Imaging.ImageFormat]::Png)
        Copy-Item $dest1 $dest2 -Force -ErrorAction SilentlyContinue
        Copy-Item $dest1 $dest3 -Force -ErrorAction SilentlyContinue
        $graphics.Dispose()
        $bmp.Dispose()
        Write-Host "Da chup man hinh Windows: $fileName ($((Get-Item $dest1).Length) bytes)" -ForegroundColor Green
    }

    Capture-Screen "win_042_main.png"
    Start-Sleep -Seconds 2
    Capture-Screen "win_042_more_settings.png"

    Stop-Process -Id $winProc.Id -Force -ErrorAction SilentlyContinue
    Write-Host "Da kiem thu xong Windows Release 0.4.2!" -ForegroundColor Green
} else {
    Write-Warning "Khong tim thay Windows Release tai $winExe"
}

Write-Host "==========================================================" -ForegroundColor Green
Write-Host " PHAN 2: KHOI DONG ANDROID EMULATOR & KIEM THU MOBILE 0.4.2" -ForegroundColor Green
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
    Write-Host "Cho Android boot hoan tat..." -ForegroundColor Cyan
    while (((& $adb shell getprop sys.boot_completed 2>&1) -join '').Trim() -ne '1') {
        if (((Get-Date) - $t0).TotalSeconds -gt 180) { break }
        Start-Sleep 3
    }
    Write-Host "Emulator da khoi dong thanh cong!" -ForegroundColor Green
    & $adb shell "input keyevent 82"
    Start-Sleep 1
    & $adb shell "input keyevent 3"
} else {
    Write-Host "Emulator da ket noi san sang!" -ForegroundColor Green
    & $adb shell "input keyevent 82"
    Start-Sleep 1
    & $adb shell "input keyevent 3"
}

function Snap-Android($name) {
    Write-Host ">> [Chup man hinh Android] $name" -ForegroundColor Cyan
    & $adb shell screencap -p /sdcard/$name
    $dest1 = "$outDir\$name"
    $dest2 = "$scDir\$name"
    $dest3 = "$artDir\$name"
    & $adb pull /sdcard/$name $dest1 | Out-Null
    if (Test-Path $dest1) {
        Copy-Item $dest1 $dest2 -Force -ErrorAction SilentlyContinue
        Copy-Item $dest1 $dest3 -Force -ErrorAction SilentlyContinue
        Write-Host "Luu thanh cong: $name ($((Get-Item $dest1).Length) bytes)" -ForegroundColor Green
    }
}

$apkMob = "$outDir\YomiHub-0.4.2-x86_64.apk"
if (-not (Test-Path $apkMob)) {
    $apkMob = "D:\A.I Project\A.I Project - YomiHub Project\YomiHub-Project\output\YomiHub-0.4.2-x86_64.apk"
}

Write-Host "Cai dat YomiHub Mobile 0.4.2 ($apkMob)..." -ForegroundColor Cyan
& $adb install -r $apkMob
Start-Sleep 3

# Bat dau quay video Mobile Walkthrough
& $adb shell rm -f /sdcard/yomihub_v042_mobile_walkthrough.mp4
$recMobProc = Start-Process -FilePath $adb -ArgumentList "shell screenrecord --size 720x1600 --bit-rate 4000000 --time-limit 180 /sdcard/yomihub_v042_mobile_walkthrough.mp4" -PassThru

# Khoi chay YomiHub Mobile
& $adb shell "am force-stop com.yomihub.app"
Start-Sleep 1
& $adb shell "am start -n com.yomihub.app/com.kodjodevf.mangayomi.MainActivity"
Start-Sleep 7

Snap-Android "01_android_042_manga_library.png"

# Chuyen sang tab Anime
& $adb shell "input tap 270 1520"
Start-Sleep 2
Snap-Android "02_android_042_anime_library.png"

# Chuyen sang tab Novel
& $adb shell "input tap 450 1520"
Start-Sleep 2
Snap-Android "03_android_042_novel_library.png"

# Chuyen sang tab More ("Thêm")
& $adb shell "input tap 630 1520"
Start-Sleep 2
Snap-Android "04_android_042_more_history_section.png"

# Mo Cài đặt / Thông tin (About)
& $adb shell "input swipe 360 1200 360 400 300"
Start-Sleep 2
Snap-Android "05_android_042_about_v042.png"

# Dung quay video Mobile
Write-Host "Dung va luu video Mobile Walkthrough..." -ForegroundColor Cyan
& $adb shell "pkill -2 screenrecord"
Start-Sleep 4
if ($recMobProc -and -not $recMobProc.HasExited) { Stop-Process -Id $recMobProc.Id -Force -ErrorAction SilentlyContinue }

$mobVid = "$outDir\yomihub_v042_mobile_walkthrough.mp4"
& $adb pull /sdcard/yomihub_v042_mobile_walkthrough.mp4 $mobVid | Out-Null
if (Test-Path $mobVid) {
    Copy-Item $mobVid "$vidDir\yomihub_v042_mobile_walkthrough.mp4" -Force -ErrorAction SilentlyContinue
    Copy-Item $mobVid "$artDir\yomihub_v042_mobile_walkthrough.mp4" -Force -ErrorAction SilentlyContinue
    Write-Host ("Video Mobile hoan tat ({0:N1} MB)" -f ((Get-Item $mobVid).Length/1MB)) -ForegroundColor Green
}

Write-Host "==========================================================" -ForegroundColor Yellow
Write-Host " PHAN 3: KIEM THU YUMI HUB ANDROID TV 0.4.2" -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Yellow

$apkTv = "$outDir\YumiHub-Android-TV-0.4.2-x86_64.apk"
if (-not (Test-Path $apkTv)) {
    $apkTv = "D:\A.I Project\A.I Project - YomiHub Project\YomiHub-Project\output\YumiHub-Android-TV-0.4.2-x86_64.apk"
}

Write-Host "Cai dat YumiHub Android TV ($apkTv)..." -ForegroundColor Cyan
& $adb install -r $apkTv
Start-Sleep 3

# Bat dau quay video TV Walkthrough
& $adb shell rm -f /sdcard/yumihub_v042_tv_walkthrough.mp4
$recTvProc = Start-Process -FilePath $adb -ArgumentList "shell screenrecord --size 720x1600 --bit-rate 4000000 --time-limit 180 /sdcard/yumihub_v042_tv_walkthrough.mp4" -PassThru

# Khoi chay TV App
& $adb shell "am force-stop com.yomihub.app"
Start-Sleep 1
& $adb shell "am start -n com.yomihub.app/com.kodjodevf.mangayomi.MainActivity"
Start-Sleep 7

Snap-Android "06_tv_042_home_dashboard.png"

# Thuc hien dieu huong D-Pad Remote TV
& $adb shell "input keyevent 20" # Down
Start-Sleep 1
Snap-Android "07_tv_042_dpad_nav.png"

& $adb shell "input keyevent 22" # Right
Start-Sleep 1
Snap-Android "08_tv_042_anime_focus.png"

& $adb shell "input keyevent 19" # Up
Start-Sleep 1
Snap-Android "09_tv_042_nav_bar_focus.png"

# Dung quay video TV
Write-Host "Dung va luu video TV Walkthrough..." -ForegroundColor Cyan
& $adb shell "pkill -2 screenrecord"
Start-Sleep 4
if ($recTvProc -and -not $recTvProc.HasExited) { Stop-Process -Id $recTvProc.Id -Force -ErrorAction SilentlyContinue }

$tvVid = "$outDir\yumihub_v042_tv_walkthrough.mp4"
& $adb pull /sdcard/yumihub_v042_tv_walkthrough.mp4 $tvVid | Out-Null
if (Test-Path $tvVid) {
    Copy-Item $tvVid "$vidDir\yumihub_v042_tv_walkthrough.mp4" -Force -ErrorAction SilentlyContinue
    Copy-Item $tvVid "$artDir\yumihub_v042_tv_walkthrough.mp4" -Force -ErrorAction SilentlyContinue
    Write-Host ("Video TV hoan tat ({0:N1} MB)" -f ((Get-Item $tvVid).Length/1MB)) -ForegroundColor Green
}

Write-Host "==========================================================" -ForegroundColor Green
Write-Host " HOAN TAT TOAN BO KIEM THU THUC TE CHI TIET CHO BAN 0.4.2!" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
