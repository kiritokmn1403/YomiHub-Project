. 'D:\Claude A.I\dev\x023\t\h.ps1'
& $ADB logcat -c
Tap 961 2160 6
& $ADB logcat -d -v time 2>&1 | Select-String -Pattern 'flutter|AndroidRuntime' | Select-Object -Last 25 | ForEach-Object { "$_".Substring(0, [Math]::Min(250, "$_".Length)) }
Shot2 't13'
