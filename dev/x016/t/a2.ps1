# splash timing with fast captures
& $ADB shell am force-stop $PKG
Start-Sleep 2
$t0 = Get-Date
& $ADB shell am start -n com.yomihub.app/com.kodjodevf.mangayomi.MainActivity | Out-Null
for ($i = 0; $i -lt 14; $i++) {
  $ms = [int]((Get-Date) - $t0).TotalMilliseconds
  $f = "$T\shots\a2_{0:D5}.png" -f $ms
  cmd /c "`"$ADB`" exec-out screencap -p > `"$f`""
  "shot $ms"
  Start-Sleep -Milliseconds 250
}
