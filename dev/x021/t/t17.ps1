. 'D:\Claude A.I\dev\x021\t\h.ps1'
& $ADB logcat -c
Tap 300 1215 20
Shot2 't17_mm'
L2 'mm' | Select-Object -First 16
& $ADB logcat -d -v time 2>&1 | Select-String -Pattern 'ProtoNumber|NoClassDef|swallowed|Manga Million|DalvikHandler' | Select-Object -Last 8 | ForEach-Object { "$_" }
"pid " + ((& $ADB shell pidof com.yomihub.app) -join '')
