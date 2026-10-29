param([string]$pat = 'flutter')
. 'D:\Claude A.I\dev\x020\t\c.ps1'
& $ADB logcat -d -v time 2>&1 | Select-String -Pattern $pat | Select-Object -Last 40 | ForEach-Object { $s = "$_"; if ($s.Length -gt 450) { $s.Substring(0,450) } else { $s } }
