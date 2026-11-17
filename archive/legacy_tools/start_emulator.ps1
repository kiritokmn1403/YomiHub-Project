$emu = "C:\Users\nguye\AppData\Local\Android\Sdk\emulator\emulator.exe"
$adb = "D:\yh\tools\android-sdk\platform-tools\adb.exe"

Write-Host "Kiem tra thiet bi ADB hien tai..." -ForegroundColor Cyan
$devs = (& $adb devices) -join " "
if ($devs -notmatch 'emulator-\d+\s+device') {
    Write-Host "Khoi dong Android Emulator (Medium_Phone_API_37.0)..." -ForegroundColor Yellow
    $proc = Start-Process -FilePath $emu -ArgumentList "-avd Medium_Phone_API_37.0 -memory 2048 -no-snapshot-save -no-boot-anim -no-audio -gpu swiftshader_indirect -dns-server 8.8.8.8,1.1.1.1" -PassThru
    Write-Host "Process Emulator PID: $($proc.Id)"
    for ($i = 0; $i -lt 60; $i++) {
        Start-Sleep 3
        $devs = (& $adb devices) -join " "
        if ($devs -match 'emulator-\d+\s+device') {
            Write-Host "Thiet bi ADB da ket noi!" -ForegroundColor Green
            break
        }
    }
} else {
    Write-Host "Emulator da dang chay san!" -ForegroundColor Green
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
