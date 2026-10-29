. 'D:\Claude A.I\dev\x021\t\h.ps1'
if (-not (EnsureEmulator)) { return }
& $ADB install -r 'D:\Claude A.I\dev\x021\YomiHub-0.2.1-dev-x86_64-release.apk' 2>&1 | Select-Object -Last 1
& $ADB logcat -c
Launch 15
TapText "^Browse\n" 4
TapText '^Source$' 4
$n = Find-Node '^Manga Million'
"node $($n.x),$($n.y)"
if ($n) { Tap 300 $n.y 25 }
Shot2 't19_mm'
L2 'mm' | Select-Object -First 16
& $ADB logcat -d -v time 2>&1 | Select-String -Pattern 'InjektionException|NoClassDef|swallowed|Caused by' | Select-Object -Last 8 | ForEach-Object { "$_" }
"pid " + ((& $ADB shell pidof com.yomihub.app) -join '')
