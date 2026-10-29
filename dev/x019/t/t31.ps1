. 'D:\Claude A.I\dev\x019\t\c.ps1'
if (-not (EnsureEmulator)) { return }
"install: " + ((Adb install -r 'D:\Claude A.I\output\YomiHub-Lite-0.1.9-x86_64.apk') -join ' ')
Adb logcat -c | Out-Null
Adb shell monkey -p com.yomihub.lite -c android.intent.category.LAUNCHER 1 | Out-Null
Start-Sleep 15
Shot 't31_lite'
Labels 't31_lite' | Select-Object -First 15
"pid: " + ((Adb shell pidof com.yomihub.lite) -join '')
Adb logcat -d -b crash 2>&1 | Select-Object -Last 10
