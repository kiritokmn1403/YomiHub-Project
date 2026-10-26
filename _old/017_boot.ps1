$o = 'D:\Claude A.I\test\boot.txt'
& {
  . 'D:\Claude A.I\test\adb_common.ps1'
  "emu: $EMU"
  try {
    $p = Start-Process -FilePath $EMU -ArgumentList @('-avd','Medium_Phone_API_37.0','-no-snapshot-save','-no-boot-anim') -PassThru -RedirectStandardOutput "$T\emu_out.txt" -RedirectStandardError "$T\emu_err.txt"
    "emulator pid $($p.Id)"
  } catch { "START FAILED: $_" }
  Start-Sleep 20
  Get-Process | Where-Object { $_.Name -match 'qemu|emulator' } | ForEach-Object { "$($_.Id) $($_.Name)" }
  for ($i = 0; $i -lt 60; $i++) { if (((& $ADB devices) -join ' ') -match 'emulator-\d+\s+device') { break }; Start-Sleep 5 }
  & $ADB devices
  Get-Content "$T\emu_err.txt" -ErrorAction SilentlyContinue | Select-Object -Last 20
  EnsureEmulator
  Shot '00_home'
} *>&1 | Out-File $o -Encoding utf8
