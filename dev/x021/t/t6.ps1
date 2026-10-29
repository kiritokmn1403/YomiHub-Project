. 'D:\Claude A.I\dev\x021\t\h.ps1'
& $ADB logcat -c
TapText '^Source$' 4
if (TapText '^Manga Million' 25) { Shot2 't6_mm'; L2 'mm' | Select-Object -First 16 } else { L2 's' | Select-Object -First 30 }
& $ADB logcat -d -v time 2>&1 | Select-String -Pattern 'DalvikHandler|ProtoNumber|NoClassDef|swallowed|FATAL|AndroidRuntime' | Select-Object -Last 10 | ForEach-Object { "$_" }
"pid " + ((& $ADB shell pidof com.yomihub.app) -join '')
