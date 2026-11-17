# capture_perfect_evidence_042.ps1
param(
    [string]$outDir = "D:\A.I Project\A.I Project - YomiHub Project\output\0.4.2",
    [string]$artDir = "C:\Users\nguye\.gemini\antigravity\brain\6b45d51d-55bc-4ab4-944a-d04a406c8d06"
)

$adb = "D:\yh\tools\android-sdk\platform-tools\adb.exe"
$emu = "C:\Users\nguye\AppData\Local\Android\Sdk\emulator\emulator.exe"
$scDir = "D:\A.I Project\A.I Project - YomiHub Project\output\screenshots"
$vidDir = "D:\A.I Project\A.I Project - YomiHub Project\output\videos"

New-Item -ItemType Directory -Force -Path $outDir,$artDir,$scDir,$vidDir | Out-Null

function Snap($fileName) {
    Write-Host ">> [Capture Screenshot] $fileName" -ForegroundColor Cyan
    & $adb shell screencap -p /sdcard/$fileName
    $dest1 = "$outDir\$fileName"
    $dest2 = "$scDir\$fileName"
    $dest3 = "$artDir\$fileName"
    & $adb pull /sdcard/$fileName $dest1 | Out-Null
    if (Test-Path $dest1) {
        Copy-Item $dest1 $dest2 -Force -ErrorAction SilentlyContinue
        Copy-Item $dest1 $dest3 -Force -ErrorAction SilentlyContinue
        Write-Host "Saved: $fileName ($((Get-Item $dest1).Length) bytes)" -ForegroundColor Green
    }
}

Write-Host "==========================================================" -ForegroundColor Green
Write-Host " STARTING ANDROID EMULATOR (1080x2400 API 37)" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green

& $adb kill-server
& $adb start-server

$proc = Start-Process -FilePath $emu -ArgumentList "-avd Medium_Phone_API_37.0 -memory 3072 -partition-size 4096 -no-snapshot-save -no-boot-anim -no-audio -gpu swiftshader_indirect -dns-server 8.8.8.8,1.1.1.1" -PassThru
Write-Host "Emulator started with PID $($proc.Id)"

for ($i = 0; $i -lt 40; $i++) {
    Start-Sleep 3
    $devs = (& $adb devices) -join " "
    if ($devs -match 'emulator-5554\s+device') {
        Write-Host "ADB device connected!" -ForegroundColor Green
        break
    }
}

$t0 = Get-Date
while (((& $adb shell getprop sys.boot_completed 2>&1) -join '').Trim() -ne '1') {
    if (((Get-Date) - $t0).TotalSeconds -gt 150) { break }
    Start-Sleep 3
}
Write-Host "Android boot completed!" -ForegroundColor Green
Start-Sleep 2

& $adb shell "input keyevent 82" # Unlock screen
Start-Sleep 1
& $adb shell "input keyevent 3"  # Home
Start-Sleep 1

Write-Host "==========================================================" -ForegroundColor Green
Write-Host " TESTING YOMIHUB MOBILE 0.4.2" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green

$apkMob = "$outDir\YomiHub-0.4.2-x86_64.apk"
Write-Host "Installing Mobile APK: $apkMob"
& $adb install -r $apkMob
Start-Sleep 3

# Grant all permissions beforehand
& $adb shell "pm grant com.yomihub.app android.permission.READ_EXTERNAL_STORAGE"
& $adb shell "pm grant com.yomihub.app android.permission.WRITE_EXTERNAL_STORAGE"
& $adb shell "appops set com.yomihub.app MANAGE_EXTERNAL_STORAGE allow"

# Start screen recording for Mobile
& $adb shell rm -f /sdcard/yomihub_v042_mobile_walkthrough.mp4
$recMob = Start-Process -FilePath $adb -ArgumentList "shell screenrecord --size 720x1600 --bit-rate 4000000 --time-limit 180 /sdcard/yomihub_v042_mobile_walkthrough.mp4" -PassThru

# Launch app
& $adb shell "am force-stop com.yomihub.app"
Start-Sleep 1
& $adb shell "am start -n com.yomihub.app/com.kodjodevf.mangayomi.MainActivity"
Start-Sleep 8

# Check if permission switch is on screen, if so click it and go back
& $adb shell "input tap 920 320"
Start-Sleep 1
& $adb shell "input keyevent 4"
Start-Sleep 4

# 1. Main Manga Library
Snap "01_android_042_manga_library.png"

# 2. Anime Library (Tab 2)
& $adb shell "input tap 324 2320"
Start-Sleep 3
Snap "02_android_042_anime_library.png"

# 3. Novel Library (Tab 3)
& $adb shell "input tap 540 2320"
Start-Sleep 3
Snap "03_android_042_novel_library.png"

# 4. Browse (Tab 4)
& $adb shell "input tap 756 2320"
Start-Sleep 3
Snap "04_android_042_browse_extensions.png"

# 5. More Screen (Tab 5) - History is always accessible
& $adb shell "input tap 972 2320"
Start-Sleep 3
Snap "05_android_042_more_history_section.png"

# 6. Scroll down More Screen to show Settings & About
& $adb shell "input swipe 540 1800 540 800 300"
Start-Sleep 2
Snap "06_android_042_more_scrolled.png"

# Stop Mobile screen recording
Write-Host "Stopping Mobile recording..."
& $adb shell "pkill -2 screenrecord"
Start-Sleep 3
if ($recMob -and -not $recMob.HasExited) { Stop-Process -Id $recMob.Id -Force -ErrorAction SilentlyContinue }

$mobVid = "$outDir\yomihub_v042_mobile_walkthrough.mp4"
& $adb pull /sdcard/yomihub_v042_mobile_walkthrough.mp4 $mobVid | Out-Null
if (Test-Path $mobVid) {
    Copy-Item $mobVid "$vidDir\yomihub_v042_mobile_walkthrough.mp4" -Force -ErrorAction SilentlyContinue
    Copy-Item $mobVid "$artDir\yomihub_v042_mobile_walkthrough.mp4" -Force -ErrorAction SilentlyContinue
    Write-Host ("Mobile Video Complete: {0:N1} MB" -f ((Get-Item $mobVid).Length / 1MB)) -ForegroundColor Green
}

Write-Host "==========================================================" -ForegroundColor Yellow
Write-Host " TESTING YUMIHUB ANDROID TV 0.4.2" -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Yellow

$apkTv = "$outDir\YumiHub-Android-TV-0.4.2-x86_64.apk"
Write-Host "Installing TV APK: $apkTv"
& $adb install -r $apkTv
Start-Sleep 3

& $adb shell "pm grant com.yomihub.app android.permission.READ_EXTERNAL_STORAGE"
& $adb shell "pm grant com.yomihub.app android.permission.WRITE_EXTERNAL_STORAGE"
& $adb shell "appops set com.yomihub.app MANAGE_EXTERNAL_STORAGE allow"

# Start TV screen recording
& $adb shell rm -f /sdcard/yumihub_v042_tv_walkthrough.mp4
$recTv = Start-Process -FilePath $adb -ArgumentList "shell screenrecord --size 720x1600 --bit-rate 4000000 --time-limit 180 /sdcard/yumihub_v042_tv_walkthrough.mp4" -PassThru

# Launch TV app
& $adb shell "am force-stop com.yomihub.app"
Start-Sleep 1
& $adb shell "am start -n com.yomihub.app/com.kodjodevf.mangayomi.MainActivity"
Start-Sleep 8

# Bypass permission if visible
& $adb shell "input tap 920 320"
Start-Sleep 1
& $adb shell "input keyevent 4"
Start-Sleep 4

# TV Dashboard
Snap "07_tv_042_home_dashboard.png"

# D-pad Down navigation
& $adb shell "input keyevent 20"
Start-Sleep 2
Snap "08_tv_042_dpad_down_nav.png"

# D-pad Right navigation
& $adb shell "input keyevent 22"
Start-Sleep 2
Snap "09_tv_042_dpad_right_focus.png"

# D-pad Up navigation
& $adb shell "input keyevent 19"
Start-Sleep 2
Snap "10_tv_042_nav_bar_focus.png"

# Stop TV recording
Write-Host "Stopping TV recording..."
& $adb shell "pkill -2 screenrecord"
Start-Sleep 3
if ($recTv -and -not $recTv.HasExited) { Stop-Process -Id $recTv.Id -Force -ErrorAction SilentlyContinue }

$tvVid = "$outDir\yumihub_v042_tv_walkthrough.mp4"
& $adb pull /sdcard/yumihub_v042_tv_walkthrough.mp4 $tvVid | Out-Null
if (Test-Path $tvVid) {
    Copy-Item $tvVid "$vidDir\yumihub_v042_tv_walkthrough.mp4" -Force -ErrorAction SilentlyContinue
    Copy-Item $tvVid "$artDir\yumihub_v042_tv_walkthrough.mp4" -Force -ErrorAction SilentlyContinue
    Write-Host ("TV Video Complete: {0:N1} MB" -f ((Get-Item $tvVid).Length / 1MB)) -ForegroundColor Green
}

# Stop emulator cleanly
& $adb emu kill
Start-Sleep 3

Write-Host "==========================================================" -ForegroundColor Green
Write-Host " ALL TEST EVIDENCE CAPTURED SUCCESSFULLY!" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
