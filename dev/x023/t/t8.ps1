. 'D:\Claude A.I\dev\x023\t\h.ps1'
& $ADB pull /sdcard/YomiHub/logs.txt "$T\logs_app.txt" 2>&1 | Out-Null
Get-Content "$T\logs_app.txt" -Encoding UTF8 -Tail 40 | ForEach-Object { if ($_.Length -gt 220) { $_.Substring(0,220) } else { $_ } }
& $ADB logcat -d -v time 2>&1 | Select-String -Pattern 'flutter' | Select-Object -Last 15 | ForEach-Object { "$_".Substring(0, [Math]::Min(220, "$_".Length)) }
