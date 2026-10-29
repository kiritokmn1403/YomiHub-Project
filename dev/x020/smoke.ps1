$d='D:\yh\wintest020'; Remove-Item $d -Recurse -Force -ErrorAction SilentlyContinue
Expand-Archive 'D:\Claude A.I\output\YomiHub-0.2.0-windows-x64.zip' $d -Force
$p = Start-Process "$d\YomiHub.exe" -PassThru
Start-Sleep 25
$alive = -not $p.HasExited
"windows exe alive after 25s: $alive"
if ($alive) { "main window title: " + (Get-Process -Id $p.Id).MainWindowTitle; Stop-Process -Id $p.Id -Force }
Get-Process | Where-Object { $_.Name -match 'xray|tor' -and $_.Path -like "$d*" } | Stop-Process -Force -ErrorAction SilentlyContinue
. 'D:\Claude A.I\dev\x020\t\c.ps1'
if (EnsureEmulator) {
  "install: " + ((Adb install -r 'D:\Claude A.I\output\YomiHub-0.2.0-x86_64.apk') -join ' ')
  (Adb shell dumpsys package com.yomihub.app) | Select-String 'versionName' | Select-Object -First 1 | ForEach-Object { "$_".Trim() }
  Adb logcat -c | Out-Null
  Adb shell am force-stop $PKG | Out-Null
  Adb shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 | Out-Null
  Start-Sleep 25; Shot 'final'
  "pid: " + ((Adb shell pidof $PKG) -join '')
  (& $ADB logcat -d -b crash 2>&1 | Select-String 'yomihub' | Select-Object -First 5)
}
