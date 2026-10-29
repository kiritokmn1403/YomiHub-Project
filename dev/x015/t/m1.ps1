if (-not (EnsureEmulator)) { return }
Start-Sleep 30; & $ADB shell am start -n com.yomihub.app/com.kodjodevf.mangayomi.MainActivity | Out-Null; Start-Sleep 15
& $ADB logcat -c
& $ADB shell monkey -p com.yomihub.app --throttle 200 --pct-syskeys 0 --pct-appswitch 0 -s 1505 2500 2>&1 | Select-Object -Last 4
& $ADB shell cmd connectivity airplane-mode disable
"--- crash buffer ---"
& $ADB logcat -d -b crash 2>&1 | Select-String -Pattern 'yomihub' | Select-Object -First 10
"--- anr ---"
& $ADB logcat -d 2>&1 | Select-String -Pattern 'ANR in com.yomihub' -Context 0,6 | Select-Object -First 2
"--- flutter errors ---"
& $ADB logcat -d -s flutter 2>&1 | Select-String -Pattern 'Exception|Error|═' | Select-Object -First 10
