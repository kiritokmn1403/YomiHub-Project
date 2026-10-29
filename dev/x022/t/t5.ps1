. 'D:\Claude A.I\dev\x022\t\h.ps1'
& $ADB logcat -b events -c
& $ADB shell am force-stop com.yomihub.app
Launch 15
$t0 = Get-Date
& $ADB shell monkey -p com.yomihub.app --pct-syskeys 0 --pct-appswitch 2 --throttle 120 -s 7311 3000 2>&1 | Select-Object -Last 6
"monkey secs " + [int]((Get-Date)-$t0).TotalSeconds
& $ADB shell cmd connectivity airplane-mode disable
Start-Sleep 3
CrashCheck
& $ADB logcat -d -b crash 2>&1 | Select-Object -Last 30
& $ADB logcat -d -v time 2>&1 | Select-String -Pattern 'E/flutter|ANR in|FATAL' | Select-Object -Last 15 | ForEach-Object { "$_" }
