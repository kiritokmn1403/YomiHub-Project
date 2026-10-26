$o = 'D:\Claude A.I\test\emu2.txt'
& {
  Get-CimInstance Win32_Process | Where-Object {
    ($_.Name -eq 'java.exe' -and $_.CommandLine -match 'D:\\yh') -or ($_.Name -eq 'adb.exe') -or ($_.Name -match 'qemu-system|^emulator') -or
    ($_.Name -eq 'powershell.exe' -and $_.CommandLine -match '024_emu1')
  } | ForEach-Object { "kill $($_.ProcessId) $($_.Name)"; Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
  Start-Sleep 5
  $os = Get-CimInstance Win32_OperatingSystem
  "free RAM MB: $([int]($os.FreePhysicalMemory/1024))  free virtual MB: $([int]($os.FreeVirtualMemory/1024))"
  Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 12 | ForEach-Object { "{0,-28} {1,8} MB" -f $_.Name, [int]($_.WorkingSet64/1MB) }
  Copy-Item 'D:\Claude A.I\test\adb_common_v4.ps1' 'D:\Claude A.I\test\adb_common.ps1' -Force
  . 'D:\Claude A.I\test\adb_common.ps1'
  $r = EnsureEmulator
  $r
  if (-not ($r -contains $true)) { return }
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
