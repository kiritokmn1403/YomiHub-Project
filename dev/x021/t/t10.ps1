. 'D:\Claude A.I\dev\x021\t\h.ps1'
& $ADB logcat -c
TapText '^Uninstall$' 4
L2 'dlg' | Select-Object -First 12
TapText '^(OK|Ok|Uninstall|Yes)$' 4
Back 3
L2 'list' | Select-String 'Manga Million' 
$n = Find-Node '^Manga Million$'
if ($n) { Tap $n.x $n.y 20 }
"pid " + ((& $ADB shell pidof com.yomihub.app) -join '')
& $ADB logcat -d -v time 2>&1 | Select-String -Pattern 'swallowed|FATAL|DalvikHandler|HttpException|System.err' | Select-Object -Last 15 | ForEach-Object { "$_" }
& $ADB logcat -d -b events 2>&1 | Select-String 'am_crash' | Select-Object -Last 5 | ForEach-Object { "$_" }
