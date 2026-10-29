function WaitTap($p, $secs = 20, $after = 2) {
  $t0 = Get-Date
  while (((Get-Date) - $t0).TotalSeconds -lt $secs) {
    $n = Find-Node $p
    if ($n) { Write-Output "tap '$($n.label)' @ $($n.x),$($n.y)"; & $ADB shell input tap $n.x $n.y; Start-Sleep $after; return }
    Start-Sleep 1
  }
  Write-Output "TIMEOUT: $p"
}
function L($n = 40) { Labels 'fj' | Select-Object -First $n }
function Reset {
  & $ADB shell input keyevent 3
  & $ADB shell am force-stop com.yomihub.app
  & $ADB shell am start -W -n com.yomihub.app/com.kodjodevf.mangayomi.MainActivity | Out-Null
  Start-Sleep 8
}
