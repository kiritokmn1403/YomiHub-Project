if (-not (EnsureEmulator)) { return }
$apk = 'D:\Claude A.I\output\YomiHub-0.1.6-x86_64.apk'
"apk: $((Get-Item $apk).Length) $((Get-Item $apk).LastWriteTime)"
& $ADB install -r $apk 2>&1 | Select-Object -Last 1
& $ADB shell am force-stop $PKG
Start-Sleep 2
$t0 = Get-Date
& $ADB shell am start -n com.yomihub.app/com.kodjodevf.mangayomi.MainActivity | Out-Null
for ($i = 0; $i -lt 16; $i++) {
  $ms = [int]((Get-Date) - $t0).TotalMilliseconds
  $f = "$T\shots\d1_{0:D5}.png" -f $ms
  cmd /c "`"$ADB`" exec-out screencap -p > `"$f`""
  "shot $ms $((Get-Item $f).Length)"
  Start-Sleep -Milliseconds 200
}
"pid=$(& $ADB shell pidof $PKG)"
