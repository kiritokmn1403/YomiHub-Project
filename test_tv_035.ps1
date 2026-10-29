# test_tv_035.ps1: Test & record YumiHub Android TV 0.3.5
param(
    [string]$outDir = "D:\A.I Project\A.I Project - YomiHub Project\output\screenshots",
    [string]$artDir = "C:\Users\nguye\.gemini\antigravity\brain\b7be3b10-426e-474e-bcba-a68458c5c86b"
)

New-Item -ItemType Directory -Force -Path $outDir,$artDir | Out-Null
$adb = "D:\yh\tools\android-sdk\platform-tools\adb.exe"

function Snap($name) {
    Write-Host ">> [Chup man hinh TV] $name" -ForegroundColor Cyan
    & $adb shell screencap -p /sdcard/$name
    & $adb pull /sdcard/$name "$outDir\$name" | Out-Null
    if (Test-Path "$outDir\$name") {
        Copy-Item "$outDir\$name" "$artDir\$name" -Force -ErrorAction SilentlyContinue
    }
}

$apkTv = "D:\A.I Project\A.I Project - YomiHub Project\output\YumiHub-Android-TV-0.3.5-x86_64.apk"
Write-Host "Cai dat YumiHub Android TV 0.3.5..."
& $adb install -r $apkTv
Start-Sleep 3

Write-Host "Bat dau quay video TV Walkthrough (25s time-limit)..."
& $adb shell rm -f /sdcard/yumihub_v035_tv_walkthrough.mp4
$recProc = Start-Process -FilePath $adb -ArgumentList "shell screenrecord --size 720x1600 --bit-rate 4000000 --time-limit 25 /sdcard/yumihub_v035_tv_walkthrough.mp4" -PassThru

Write-Host "Khoi chay TV App..."
& $adb shell "am force-stop com.yomihub.app"
Start-Sleep 1
& $adb shell "am start -n com.yomihub.app/com.kodjodevf.mangayomi.MainActivity"
Start-Sleep 6
Snap "31_tv_home_dashboard.png"

Write-Host "Dieu huong D-Pad Remote..."
& $adb shell "input keyevent 20" # Down
Start-Sleep 2
Snap "32_tv_dpad_down_nav.png"

& $adb shell "input keyevent 22" # Right
Start-Sleep 2
Snap "33_tv_dpad_item_focus.png"

& $adb shell "input keyevent 19" # Up
Start-Sleep 2
Snap "34_tv_nav_bar_focus.png"

Write-Host "Cho video hoan tat..."
Start-Sleep 10

if (-not $recProc.HasExited) {
    Stop-Process -Id $recProc.Id -Force -ErrorAction SilentlyContinue
}

& $adb pull /sdcard/yumihub_v035_tv_walkthrough.mp4 "$outDir\yumihub_v035_tv_walkthrough.mp4" | Out-Null
if (Test-Path "$outDir\yumihub_v035_tv_walkthrough.mp4") {
    Copy-Item "$outDir\yumihub_v035_tv_walkthrough.mp4" "$artDir\yumihub_v035_tv_walkthrough.mp4" -Force -ErrorAction SilentlyContinue
    Write-Host ("TV Video hoan tat ({0:N1} MB)" -f ((Get-Item "$outDir\yumihub_v035_tv_walkthrough.mp4").Length/1MB)) -ForegroundColor Green
}
Write-Host "Hoan tat kiem thu TV 0.3.5!" -ForegroundColor Green
