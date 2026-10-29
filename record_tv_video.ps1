$emu = "C:\Users\nguye\AppData\Local\Android\Sdk\emulator\emulator.exe"
$adb = "C:\Users\nguye\AppData\Local\Android\Sdk\platform-tools\adb.exe"
$outDir = "D:\A.I Project\YomiHub Project\output\screenshots"
$artDir = "C:\Users\nguye\.gemini\antigravity\brain\8baf8f3f-01fa-4e4d-9c9b-44c1e5eca073"

$devs = (& $adb devices) -join " "
if ($devs -notmatch 'emulator-\d+\s+device') {
    Write-Host "Khoi dong emulator..."
    Start-Process -FilePath $emu -ArgumentList "-avd Medium_Phone_API_37.0 -memory 2048 -no-snapshot-save -no-boot-anim -no-audio -gpu swiftshader_indirect -dns-server 8.8.8.8,1.1.1.1"
    for ($i = 0; $i -lt 60; $i++) {
        Start-Sleep 3
        $devs = (& $adb devices) -join " "
        if ($devs -match 'emulator-\d+\s+device') { break }
    }
    $t0 = Get-Date
    while (((& $adb shell getprop sys.boot_completed 2>&1) -join '').Trim() -ne '1') {
        if (((Get-Date) - $t0).TotalSeconds -gt 180) { break }
        Start-Sleep 3
    }
}

& $adb shell "input keyevent 82"
Start-Sleep 1
& $adb shell "am start -n com.yomihub.app/com.kodjodevf.mangayomi.MainActivity"
Start-Sleep 5

& $adb shell rm -f /sdcard/yumihub_v037_tv_walkthrough.mp4
Write-Host "Recording TV Walkthrough..."
$rec = Start-Process -FilePath $adb -ArgumentList "shell screenrecord --size 720x1600 --bit-rate 4000000 --time-limit 15 /sdcard/yumihub_v037_tv_walkthrough.mp4" -PassThru

Start-Sleep 2
& $adb shell "input keyevent 20"
Start-Sleep 2
& $adb shell "input keyevent 22"
Start-Sleep 2
& $adb shell "input keyevent 21"
Start-Sleep 2
& $adb shell "input keyevent 19"
Start-Sleep 8

if (-not $rec.HasExited) { Stop-Process -Id $rec.Id -Force -ErrorAction SilentlyContinue }
Start-Sleep 2
& $adb pull /sdcard/yumihub_v037_tv_walkthrough.mp4 "$outDir\yumihub_v037_tv_walkthrough.mp4"
Copy-Item "$outDir\yumihub_v037_tv_walkthrough.mp4" "$artDir\yumihub_v037_tv_walkthrough.mp4" -Force
$fi = Get-Item "$outDir\yumihub_v037_tv_walkthrough.mp4"
Write-Host ("TV Video Size: {0:N0} bytes ({1:N2} MB)" -f $fi.Length, ($fi.Length/1MB))
