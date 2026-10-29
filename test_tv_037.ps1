# test_tv_037.ps1: Test & record YumiHub Android TV 0.3.7
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

Write-Host "Kiem tra thiet bi ADB hien tai..." -ForegroundColor Cyan
$devs = (& $adb devices) -join " "
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
    & $adb shell "input keyevent 82"
    Start-Sleep 1
    & $adb shell "input keyevent 3"
} else {
    Write-Host "Emulator da san sang!" -ForegroundColor Green
}

function Snap($name) {
    Write-Host ">> [Chup man hinh TV] $name" -ForegroundColor Cyan
    & $adb shell screencap -p /sdcard/$name
    & $adb pull /sdcard/$name "$outDir\$name" | Out-Null
    if (Test-Path "$outDir\$name") {
        Copy-Item "$outDir\$name" "$artDir\$name" -Force -ErrorAction SilentlyContinue
    }
}

$apkTv = "D:\A.I Project\YomiHub Project\output\YumiHub-Android-TV-0.3.7-x86_64.apk"
Write-Host "Cai dat YumiHub Android TV 0.3.7..."
& $adb install -r $apkTv
Start-Sleep 3

Write-Host "Khoi chay TV App de chup anh..."
& $adb shell "am force-stop com.yomihub.app"
Start-Sleep 1
& $adb shell "am start -n com.yomihub.app/com.kodjodevf.mangayomi.MainActivity"
Start-Sleep 6
Snap "31_tv_home_dashboard.png"

Write-Host "Dieu huong D-Pad Remote va chup anh..."
& $adb shell "input keyevent 20" # Down
Start-Sleep 2
Snap "32_tv_dpad_down_nav.png"

& $adb shell "input keyevent 22" # Right
Start-Sleep 2
Snap "33_tv_dpad_item_focus.png"

& $adb shell "input keyevent 19" # Up
Start-Sleep 2
Snap "34_tv_nav_bar_focus.png"

# Bay gio ghi video rieng biet de tranh xung dot swiftshader
Write-Host "Bat dau quay video TV Walkthrough (18s)..."
& $adb shell rm -f /sdcard/yumihub_v037_tv_walkthrough.mp4
$recProc = Start-Process -FilePath $adb -ArgumentList "shell screenrecord --size 720x1600 --bit-rate 4000000 --time-limit 18 /sdcard/yumihub_v037_tv_walkthrough.mp4" -PassThru

# Thao tac dieu huong D-pad trong video
Start-Sleep 2
& $adb shell "input keyevent 20" # Down
Start-Sleep 2
& $adb shell "input keyevent 22" # Right
Start-Sleep 2
& $adb shell "input keyevent 22" # Right
Start-Sleep 2
& $adb shell "input keyevent 21" # Left
Start-Sleep 2
& $adb shell "input keyevent 19" # Up
Start-Sleep 2
& $adb shell "input keyevent 23" # Select/Enter
Start-Sleep 4

if (-not $recProc.HasExited) {
    Stop-Process -Id $recProc.Id -Force -ErrorAction SilentlyContinue
}

& $adb pull /sdcard/yumihub_v037_tv_walkthrough.mp4 "$outDir\yumihub_v037_tv_walkthrough.mp4" | Out-Null
if (Test-Path "$outDir\yumihub_v037_tv_walkthrough.mp4") {
    Copy-Item "$outDir\yumihub_v037_tv_walkthrough.mp4" "$artDir\yumihub_v037_tv_walkthrough.mp4" -Force -ErrorAction SilentlyContinue
    Write-Host ("TV Video hoan tat ({0:N1} MB)" -f ((Get-Item "$outDir\yumihub_v037_tv_walkthrough.mp4").Length/1MB)) -ForegroundColor Green
}
Write-Host "Hoan tat kiem thu TV 0.3.7!" -ForegroundColor Green
