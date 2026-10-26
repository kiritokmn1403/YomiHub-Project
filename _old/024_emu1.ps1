$o = 'D:\Claude A.I\test\emu1.txt'
& {
  Copy-Item 'D:\Claude A.I\test\adb_common_v3.ps1' 'D:\Claude A.I\test\adb_common.ps1' -Force
  . 'D:\Claude A.I\test\adb_common.ps1'
  Get-CimInstance Win32_Process | Where-Object { $_.Name -eq 'java.exe' -and $_.CommandLine -match 'D:\\yh' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
  Start-Sleep 5
  $ok = EnsureEmulator
  if (-not $ok) { return }
  $apk = Get-ChildItem 'D:\Claude A.I\output' -Filter 'YomiHub-*-x86_64.apk' | Sort-Object LastWriteTime | Select-Object -Last 1
  "installing $($apk.FullName) $($apk.Length)"
  Adb install -r -g $apk.FullName
  Adb shell dumpsys package com.yomihub.app | Select-String 'versionName|versionCode|targetSdk'
  Adb logcat -c
  Adb shell monkey -p $PKG -c android.intent.category.LAUNCHER 1
  Start-Sleep 25
  Shot '01_launch'
  Labels '01_launch'
  Start-Sleep 8
  Shot '02_after'
  Labels '02_after'
  "pid: $(Adb shell pidof $PKG)"
  Crash
} *>&1 | Out-File $o -Encoding utf8
