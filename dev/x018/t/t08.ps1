. 'D:\Claude A.I\dev\x018\t\c.ps1'
if (-not (EnsureEmulator)) { return }
$apk = 'D:\Claude A.I\output\YomiHub-0.1.8-x86_64.apk'
Adb install -r $apk | Select-Object -Last 2
Adb shell dumpsys package $PKG | Select-String 'versionName|minSdk' | Select-Object -First 3
Adb logcat -c
Adb shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 | Out-Null
Start-Sleep 3; Shot 't08_splash'
Start-Sleep 12; Shot 't08_home'
Tap 878 2136 4; Shot 't08_browse'
Labels 't08_browse' | Select-Object -First 15
Crash | Select-String -NotMatch 'LocalLibraryScanner' | Select-Object -Last 15
# Windows smoke test
$z = 'D:\yh\wintest018'; Remove-Item $z -Recurse -Force -ErrorAction SilentlyContinue
Expand-Archive 'D:\Claude A.I\output\YomiHub-0.1.8-windows-x64.zip' $z -Force
$exe = Get-ChildItem $z -Recurse -Filter YomiHub.exe | Select-Object -First 1
"exe: $($exe.FullName)"
Get-Process YomiHub -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Process $exe.FullName
Start-Sleep 20
$p = Get-Process YomiHub -ErrorAction SilentlyContinue; "running: $([bool]$p) title: $($p.MainWindowTitle)"
New-Item -ItemType Directory -Force 'D:\Claude A.I\test\shots' | Out-Null
& 'D:\Claude A.I\dev\x017\wshot.ps1' 'w018_home'
Get-Process YomiHub,xray,tor,javaw -ErrorAction SilentlyContinue | Stop-Process -Force
