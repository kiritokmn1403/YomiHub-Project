. 'D:\Claude A.I\dev\x019\t\c.ps1'
Adb logcat -c | Out-Null
TapText '^AllNovel$' 25 | Out-Null
Shot 't05_installed'
Labels 't05_installed' | Select-Object -First 22
Adb logcat -d -v brief 2>&1 | Select-String -Pattern 'IReader|ireader|DexClassLoader|ClassNotFound|NoSuchMethod|NoClassDef|E/flutter|AndroidRuntime' | Select-Object -Last 30 | ForEach-Object { "$_" }
