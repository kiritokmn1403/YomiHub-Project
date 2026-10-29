. 'D:\Claude A.I\dev\x023\t\h.ps1'
& $ADB logcat -b events -c; & $ADB logcat -b crash -c
& $ADB shell am force-stop com.yomihub.app
Launch 15
& $ADB shell monkey -p com.yomihub.app --pct-syskeys 0 --pct-appswitch 2 --throttle 120 -s 5151 3000 2>&1 | Select-Object -Last 2
& $ADB shell cmd connectivity airplane-mode disable
Start-Sleep 3
CrashCheck
& $ADB logcat -d -b crash 2>&1 | Select-Object -Last 20
& $ADB pull /sdcard/YomiHub/logs.txt "$T\logs_app.txt" 2>&1 | Out-Null
Get-Content "$T\logs_app.txt" -Encoding UTF8 | Select-String '^\[08/10/2026 1[89].*\]\[(ERROR|WARNING)\]' | Select-Object -Last 15 | ForEach-Object { "$_".Substring(0, [Math]::Min(230, "$_".Length)) }
