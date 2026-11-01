# qa048.ps1 - Automated QA and verification script for YomiHub 0.4.8 on Galaxy Note 9
$PSScriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { "D:\A.I Project\A.I Project - YomiHub Project\YomiHub-Project" }
$adb = "D:\yh\tools\android-sdk\platform-tools\adb.exe"
$QA  = "$PSScriptRoot\output\0.4.8\qa"
New-Item -ItemType Directory -Force $QA | Out-Null
$global:SER = '281038ac31217ece'
$env:QA_SERIAL = $global:SER

function A { & $adb -s $global:SER @args 2>&1 }
function Snap($name) {
    Remove-Item "$QA\$name.png" -ErrorAction SilentlyContinue
    A shell screencap -p /data/local/tmp/qa.png | Out-Null
    A pull /data/local/tmp/qa.png "$QA\$name.png" | Out-Null
    Write-Host "Screenshot: $name.png ($((Test-Path "$QA\$name.png")))" -ForegroundColor Green
}
function Dump($name) {
    A shell uiautomator dump /data/local/tmp/ui.xml | Out-Null
    A pull /data/local/tmp/ui.xml "$QA\$name.xml" | Out-Null
}
function Tap($x,$y) { A shell input tap $x $y | Out-Null; Start-Sleep -Milliseconds 1200 }
function Key($k) { A shell input keyevent $k | Out-Null; Start-Sleep -Milliseconds 800 }
function Swipe($x1,$y1,$x2,$y2,$ms=400) { A shell input swipe $x1 $y1 $x2 $y2 $ms | Out-Null; Start-Sleep -Milliseconds 1200 }
function RecStart($name,$limit=180) {
    Start-Process -FilePath $adb -ArgumentList @('-s', $global:SER, 'shell', 'screenrecord', '--bit-rate', '4000000', '--time-limit', "$limit", "/data/local/tmp/$name.mp4") -WindowStyle Hidden | Out-Null
    Write-Host "Started screen recording: $name.mp4" -ForegroundColor Cyan
}
function RecPull($name) {
    A shell "pkill -2 screenrecord" 2>&1 | Out-Null
    Start-Sleep 3
    A pull "/data/local/tmp/$name.mp4" "$QA\$name.mp4" | Out-Null
    Write-Host "Pulled video recording: $name.mp4 ($((Test-Path "$QA\$name.mp4")))" -ForegroundColor Green
}
function TapText($xmlName, $text) {
    $xmlPath = "$QA\$xmlName.xml"
    if (-not (Test-Path $xmlPath)) {
        Write-Host "File not found: $xmlPath" -ForegroundColor Yellow
        return
    }
    [xml]$x = Get-Content $xmlPath -Encoding UTF8
    $n = $x.SelectNodes("//node") | Where-Object { $_.text -eq $text -or $_.'content-desc' -eq $text -or $_.text -like "*$text*" -or $_.'content-desc' -like "*$text*" } | Select-Object -First 1
    if (-not $n) { Write-Host "NOT FOUND: $text" -ForegroundColor Yellow; return }
    $m = [regex]::Matches($n.bounds, '\d+')
    $cx = ([int]$m[0].Value + [int]$m[2].Value)/2
    $cy = ([int]$m[1].Value + [int]$m[3].Value)/2
    Tap $cx $cy
    Write-Host "Tapped '$text' at ($cx, $cy)" -ForegroundColor Green
}

Write-Host "=== YOMIHUB 0.4.8 QA RUNNER: Samsung Galaxy Note 9 (SM-N960N) ===" -ForegroundColor Cyan
Write-Host "Target Device: $global:SER" -ForegroundColor Green

# 1. Wake device & unlock
A shell "input keyevent 224" # WAKEUP
Start-Sleep 1
A shell "input keyevent 82"  # UNLOCK
Start-Sleep 1
A shell "input keyevent 3"   # HOME
Start-Sleep 1

# 2. Stop running instance if any
A shell "am force-stop com.yomihub.app" | Out-Null
Start-Sleep 1

# 3. Start recording and launch app
RecStart "yomihub_048_walkthrough" 180
Start-Sleep 1

Write-Host "Launching YomiHub 0.4.8..." -ForegroundColor Cyan
A shell "am start -n com.yomihub.app/com.kodjodevf.mangayomi.MainActivity" | Out-Null

# 4. Capture Splash Screen (Morph 5s)
Start-Sleep 2
Snap "01_splash_morph"
Start-Sleep 4

# 5. Capture Home Screen
Snap "02_home_screen"
Dump "ui_home"

# 6. Navigate to Browse (Khám phá)
Dump "ui_main"
TapText "ui_main" "Khám phá"
Start-Sleep 2
Snap "03_browse_screen"
Dump "ui_browse"

# 7. Tap "Đề Xuất" Tab
TapText "ui_browse" "Đề Xuất"
Start-Sleep 3
Snap "04_suggestions_screen"
Dump "ui_suggestions"

# 8. Scroll down in Suggestions to verify smooth grid layout and Vietnamese Unicode text
Swipe 720 2200 720 800 500
Start-Sleep 2
Snap "05_suggestions_scrolled"

# 9. Tap a suggestion item if exists to test detail navigation
Tap 360 800
Start-Sleep 3
Snap "06_suggestion_detail"
Key 4 # Back
Start-Sleep 2

# 10. Navigate to More (Thêm)
Dump "ui_browse_nav"
TapText "ui_browse_nav" "Thêm"
if (-not (Test-Path "$QA\07_more_screen.png")) {
    Tap 1296 2800
}
Start-Sleep 2
Snap "07_more_screen"
Dump "ui_more"

# 11. Navigate to Settings (Cài đặt)
TapText "ui_more" "Cài đặt"
Start-Sleep 2
Snap "08_settings_screen"
Dump "ui_settings"

# 12. Tap "Bật / Tắt tính năng" (Feature Toggle screen)
TapText "ui_settings" "Bật / Tắt tính năng"
Start-Sleep 2
Snap "09_feature_toggle_screen"
Dump "ui_feature_toggle"

# 13. Test toggle interaction on Feature Toggle screen
Tap 1200 650
Start-Sleep 1
Snap "10_feature_toggle_interaction"
Tap 1200 650
Start-Sleep 1
Key 4 # Back to Settings
Start-Sleep 1

# 14. Tap "Trình phát" (Player settings)
Dump "ui_settings_2"
TapText "ui_settings_2" "Trình phát"
Start-Sleep 2
Snap "11_player_settings_resume"
Key 4 # Back to Settings
Start-Sleep 1

# 15. Tap "Sao lưu đám mây" (Cloud Backup)
Dump "ui_settings_3"
TapText "ui_settings_3" "Sao lưu đám mây"
Start-Sleep 2
Snap "12_cloud_backup_screen"
Key 4 # Back to Settings
Start-Sleep 1

# 16. Tap "Thông tin" (About Screen) -> Verify YomiHub 0.4.8 and GitHub repo link
Dump "ui_settings_4"
TapText "ui_settings_4" "Thông tin"
if (-not (Test-Path "$QA\13_about_screen_048.png")) {
    Swipe 720 2200 720 800 400
    Start-Sleep 1
    Dump "ui_settings_scrolled"
    TapText "ui_settings_scrolled" "Thông tin"
}
Start-Sleep 2
Snap "13_about_screen_048"

# 17. Stop and pull video recording
RecPull "yomihub_048_walkthrough"
Write-Host "=== QA WALKTHROUGH COMPLETED ON GALAXY NOTE 9! ===" -ForegroundColor Green

