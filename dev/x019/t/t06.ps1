. 'D:\Claude A.I\dev\x019\t\c.ps1'
Adb logcat -c | Out-Null
TapText '^Source$' 3 | Out-Null
Labels 't06_src' | Select-Object -First 25
TapText '^AllNovel' 20 | Out-Null
Shot 't06_allnovel'
Labels 't06_allnovel' | Select-Object -First 25
Adb logcat -d -v brief 2>&1 | Select-String -Pattern 'IReader|ireader|ClassNotFound|NoSuchMethod|NoClassDef|E/flutter|FATAL' | Select-Object -Last 20 | ForEach-Object { "$_" }
