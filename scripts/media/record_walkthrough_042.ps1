param(
    [string]$outDir = "D:\A.I Project\A.I Project - YomiHub Project\output\0.4.2",
    [string]$artDir = "C:\Users\nguye\.gemini\antigravity\brain\6b45d51d-55bc-4ab4-944a-d04a406c8d06"
)

$adb = "D:\yh\tools\android-sdk\platform-tools\adb.exe"
$scDir = "D:\A.I Project\A.I Project - YomiHub Project\output\screenshots"
$vidDir = "D:\A.I Project\A.I Project - YomiHub Project\output\videos"
New-Item -ItemType Directory -Force -Path $outDir,$artDir,$scDir,$vidDir | Out-Null

function Snap-Android($name) {
    Write-Host ">> [Chup man hinh] $name" -ForegroundColor Cyan
    & $adb shell screencap -p /sdcard/$name
    $dest1 = "$outDir\$name"
    $dest2 = "$scDir\$name"
    $dest3 = "$artDir\$name"
    & $adb pull /sdcard/$name $dest1 | Out-Null
    if (Test-Path $dest1) {
        Copy-Item $dest1 $dest2 -Force -ErrorAction SilentlyContinue
        Copy-Item $dest1 $dest3 -Force -ErrorAction SilentlyContinue
        Write-Host "Luu screenshot: $name ($((Get-Item $dest1).Length) bytes)" -ForegroundColor Green
    }
}

Write-Host "==========================================================" -ForegroundColor Green
Write-Host " KIEM THU YOMIHUB MOBILE 0.4.2 & QUAY VIDEO WALKTHROUGH" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green

# Bat dau quay video Mobile
& $adb shell rm -f /sdcard/yomihub_v042_mobile_walkthrough.mp4
$recMobProc = Start-Process -FilePath $adb -ArgumentList "shell screenrecord --size 720x1600 --bit-rate 4000000 --time-limit 180 /sdcard/yomihub_v042_mobile_walkthrough.mp4" -PassThru
Write-Host "Recording Mobile video (PID $($recMobProc.Id))..." -ForegroundColor Yellow

# Khoi chay YomiHub Mobile
& $adb shell "am force-stop com.yomihub.app"
Start-Sleep 1
& $adb shell "am start -n com.yomihub.app/com.kodjodevf.mangayomi.MainActivity"
Start-Sleep 8

Snap-Android "01_android_042_manga_library.png"

# Chuyen sang tab Anime
& $adb shell "input tap 270 1520"
Start-Sleep 3
Snap-Android "02_android_042_anime_library.png"

# Chuyen sang tab Novel
& $adb shell "input tap 450 1520"
Start-Sleep 3
Snap-Android "03_android_042_novel_library.png"

# Chuyen sang tab More ("Thêm")
& $adb shell "input tap 630 1520"
Start-Sleep 3
Snap-Android "04_android_042_more_history_section.png"

# Cuon xuong phan Cai dat va About
& $adb shell "input swipe 360 1200 360 400 300"
Start-Sleep 2
Snap-Android "05_android_042_about_v042.png"

# Dung quay video Mobile
Write-Host "Dung quay video Mobile..." -ForegroundColor Cyan
& $adb shell "pkill -2 screenrecord"
Start-Sleep 4
if ($recMobProc -and -not $recMobProc.HasExited) { Stop-Process -Id $recMobProc.Id -Force -ErrorAction SilentlyContinue }

$mobVid = "$outDir\yomihub_v042_mobile_walkthrough.mp4"
& $adb pull /sdcard/yomihub_v042_mobile_walkthrough.mp4 $mobVid | Out-Null
if (Test-Path $mobVid) {
    Copy-Item $mobVid "$vidDir\yomihub_v042_mobile_walkthrough.mp4" -Force -ErrorAction SilentlyContinue
    Copy-Item $mobVid "$artDir\yomihub_v042_mobile_walkthrough.mp4" -Force -ErrorAction SilentlyContinue
    Write-Host ("Video Mobile hoan tat: $mobVid ({0:N1} MB)" -f ((Get-Item $mobVid).Length/1MB)) -ForegroundColor Green
}

Write-Host "==========================================================" -ForegroundColor Yellow
Write-Host " KIEM THU YUMIHUB ANDROID TV 0.4.2 & QUAY VIDEO WALKTHROUGH" -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Yellow

$apkTv = "$outDir\YumiHub-Android-TV-0.4.2-x86_64.apk"
Write-Host "Cai dat YumiHub Android TV: $apkTv..." -ForegroundColor Cyan
& $adb install -r $apkTv
Start-Sleep 3

# Bat dau quay video TV
& $adb shell rm -f /sdcard/yumihub_v042_tv_walkthrough.mp4
$recTvProc = Start-Process -FilePath $adb -ArgumentList "shell screenrecord --size 720x1600 --bit-rate 4000000 --time-limit 180 /sdcard/yumihub_v042_tv_walkthrough.mp4" -PassThru
Write-Host "Recording TV video (PID $($recTvProc.Id))..." -ForegroundColor Yellow

# Khoi chay TV App
& $adb shell "am force-stop com.yomihub.app"
Start-Sleep 1
& $adb shell "am start -n com.yomihub.app/com.kodjodevf.mangayomi.MainActivity"
Start-Sleep 8

Snap-Android "06_tv_042_home_dashboard.png"

# Dieu huong D-Pad Remote TV
& $adb shell "input keyevent 20" # Down
Start-Sleep 2
Snap-Android "07_tv_042_dpad_nav.png"

& $adb shell "input keyevent 22" # Right
Start-Sleep 2
Snap-Android "08_tv_042_anime_focus.png"

& $adb shell "input keyevent 19" # Up
Start-Sleep 2
Snap-Android "09_tv_042_nav_bar_focus.png"

# Dung quay video TV
Write-Host "Dung quay video TV..." -ForegroundColor Cyan
& $adb shell "pkill -2 screenrecord"
Start-Sleep 4
if ($recTvProc -and -not $recTvProc.HasExited) { Stop-Process -Id $recTvProc.Id -Force -ErrorAction SilentlyContinue }

$tvVid = "$outDir\yumihub_v042_tv_walkthrough.mp4"
& $adb pull /sdcard/yumihub_v042_tv_walkthrough.mp4 $tvVid | Out-Null
if (Test-Path $tvVid) {
    Copy-Item $tvVid "$vidDir\yumihub_v042_tv_walkthrough.mp4" -Force -ErrorAction SilentlyContinue
    Copy-Item $tvVid "$artDir\yumihub_v042_tv_walkthrough.mp4" -Force -ErrorAction SilentlyContinue
    Write-Host ("Video TV hoan tat: $tvVid ({0:N1} MB)" -f ((Get-Item $tvVid).Length/1MB)) -ForegroundColor Green
}

Write-Host "==========================================================" -ForegroundColor Green
Write-Host " HOAN TAT TOAN BO KIEM THU THUC TE CHI TIET CHO BAN 0.4.2!" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
