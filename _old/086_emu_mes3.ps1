$o = 'D:\Claude A.I\test\emu_v012c.txt'
& {
  . 'D:\Claude A.I\test\adb_common.ps1'
  function WaitTap($p, $secs = 30, $after = 3) {
    $t0 = Get-Date
    while (((Get-Date) - $t0).TotalSeconds -lt $secs) {
      $n = Find-Node $p
      if ($n) { Write-Host "tap '$($n.label)'"; & $ADB shell input tap $n.x $n.y; Start-Sleep $after; return $true }
      Start-Sleep 3
    }
    Write-Host "TIMEOUT: $p"; return $false
  }
  function Reset {
    Adb shell am force-stop com.yomihub.app
    Adb shell am start -W -n com.yomihub.app/com.kodjodevf.mangayomi.MainActivity | Out-Null
    Start-Sleep 9
  }
  $r = EnsureEmulator; $r
  Reset
  $null = WaitTap '^Thêm' 15
  $c = $null
  for ($i = 0; $i -lt 5 -and -not $c; $i++) { Adb shell input swipe 540 1900 540 700 300; Start-Sleep 2; $c = Find-Node '^Cài đặt$' }
  if ($c) { Tap $c.x $c.y 4 } else { "no Cai dat" }
  $null = WaitTap '^Duyệt' 10 4
  Shot 'P0_browse_settings'; Labels 'P0_browse_settings' | Select-Object -First 25
  if (WaitTap 'M-Extension-Server' 10 6) {
    Shot 'P1_mes_screen'; Labels 'P1_mes_screen'
    if (WaitTap '^Khởi động lại$' 5 8) { Shot 'P2_restarted'; Labels 'P2_restarted' | Select-String 'Đang|Không|lần|127' }
  }
  Crash
} *>&1 | Out-File $o -Encoding utf8
