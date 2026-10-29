# run_042_perfect_screenshots.ps1
$adb = "D:\yh\tools\android-sdk\platform-tools\adb.exe"
$emu = "C:\Users\nguye\AppData\Local\Android\Sdk\emulator\emulator.exe"
$outDir = "D:\A.I Project\A.I Project - YomiHub Project\output\0.4.2"
$artDir = "C:\Users\nguye\.gemini\antigravity\brain\6b45d51d-55bc-4ab4-944a-d04a406c8d06"
$scDir = "D:\A.I Project\A.I Project - YomiHub Project\output\screenshots"

New-Item -ItemType Directory -Force -Path $outDir,$artDir,$scDir | Out-Null

function Snap($name) {
    Write-Host ">> [CAPTURE] $name" -ForegroundColor Cyan
    & $adb shell screencap -p /sdcard/$name
    & $adb pull /sdcard/$name "$outDir\$name" | Out-Null
    Copy-Item "$outDir\$name" "$artDir\$name" -Force -ErrorAction SilentlyContinue
    Copy-Item "$outDir\$name" "$scDir\$name" -Force -ErrorAction SilentlyContinue
    Write-Host "Saved: $name ($((Get-Item "$outDir\$name").Length) bytes)" -ForegroundColor Green
}

Write-Host "--- Checking / Starting Emulator ---"
$devs = (& $adb devices) -join " "
$emuProc = $null
if ($devs -notmatch 'emulator-\d+\s+device') {
    $emuProc = Start-Process -FilePath $emu -ArgumentList "-avd Medium_Phone_API_37.0 -memory 3072 -partition-size 4096 -no-snapshot-save -no-boot-anim -no-audio -gpu swiftshader_indirect -dns-server 8.8.8.8,1.1.1.1" -PassThru
    Write-Host "Emulator started PID: $($emuProc.Id)"
    for ($i = 0; $i -lt 40; $i++) {
        Start-Sleep 3
        $devs = (& $adb devices) -join " "
        if ($devs -match 'emulator-\d+\s+device') { break }
    }
    $t0 = Get-Date
    while (((& $adb shell getprop sys.boot_completed 2>&1) -join '').Trim() -ne '1') {
        if (((Get-Date) - $t0).TotalSeconds -gt 150) { break }
        Start-Sleep 3
    }
}
Write-Host "Emulator ready!"
& $adb shell "input keyevent 82"
Start-Sleep 1
& $adb shell "input keyevent 3"
Start-Sleep 1

Write-Host "--- 1. Testing YomiHub Mobile 0.4.2 ---"
$apkMob = "$outDir\YomiHub-0.4.2-x86_64.apk"
& $adb install -r $apkMob
Start-Sleep 3

& $adb shell "am force-stop com.yomihub.app"
Start-Sleep 1
& $adb shell "am start -n com.yomihub.app/com.kodjodevf.mangayomi.MainActivity"
Start-Sleep 8

# Toggle permission switch if shown
& $adb shell "input tap 920 320"
Start-Sleep 1
& $adb shell "input keyevent 4" # Back to YomiHub
Start-Sleep 4

# Tab 1: Manga Library
Write-Host "Snapping Tab 1 (Manga)..."
& $adb shell "input tap 67 2232"
Start-Sleep 2
Snap "01_android_042_manga_library.png"

# Tab 2: Anime Library
Write-Host "Snapping Tab 2 (Anime)..."
& $adb shell "input tap 202 2232"
Start-Sleep 2
Snap "02_android_042_anime_library.png"

# Tab 3: Novel Library
Write-Host "Snapping Tab 3 (Novel)..."
& $adb shell "input tap 337 2232"
Start-Sleep 2
Snap "03_android_042_novel_library.png"

# Tab 8: More (Thêm) showing History
Write-Host "Snapping Tab More (Thêm)..."
& $adb shell "input tap 1012 2232"
Start-Sleep 2
Snap "04_android_042_more_history_section.png"

# Scroll More to About
Write-Host "Snapping More Scrolled..."
& $adb shell "input swipe 540 1800 540 500 300"
Start-Sleep 2
Snap "05_android_042_about_v042.png"

Write-Host "--- 2. Testing YumiHub Android TV 0.4.2 ---"
$apkTv = "$outDir\YumiHub-Android-TV-0.4.2-x86_64.apk"
& $adb install -r $apkTv
Start-Sleep 3

& $adb shell "am force-stop com.yomihub.app"
Start-Sleep 1
& $adb shell "am start -n com.yomihub.app/com.kodjodevf.mangayomi.MainActivity"
Start-Sleep 8

# Toggle permission if shown
& $adb shell "input tap 920 320"
Start-Sleep 1
& $adb shell "input keyevent 4"
Start-Sleep 4

Write-Host "Snapping TV Dashboard..."
Snap "06_tv_042_home_dashboard.png"

Write-Host "Snapping TV D-pad Down..."
& $adb shell "input keyevent 20" # Down
Start-Sleep 2
Snap "07_tv_042_dpad_nav.png"

Write-Host "Snapping TV D-pad Right..."
& $adb shell "input keyevent 22" # Right
Start-Sleep 2
Snap "08_tv_042_anime_focus.png"

Write-Host "Snapping TV D-pad Up..."
& $adb shell "input keyevent 19" # Up
Start-Sleep 2
Snap "09_tv_042_nav_bar_focus.png"

# Kill emulator cleanly
& $adb emu kill
Start-Sleep 2
Write-Host "DONE! All real screenshots captured!"
