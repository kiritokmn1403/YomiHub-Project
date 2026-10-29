# 0.1.6 T1: install x86_64, splash timeline, crash check
if (-not (EnsureEmulator)) { return }
& $ADB shell settings put global animator_duration_scale 1
$apk = 'D:\Claude A.I\output\YomiHub-0.1.6-x86_64.apk'
"apk: $((Get-Item $apk).Length)"
& $ADB install -r $apk 2>&1 | Select-Object -Last 3
& $ADB shell am force-stop $PKG
& $ADB logcat -c
$t0 = Get-Date
& $ADB shell am start -n com.yomihub.app/com.kodjodevf.mangayomi.MainActivity | Out-Null
foreach ($ms in 900, 1700, 2600, 3600, 4700, 6500) {
  while (((Get-Date) - $t0).TotalMilliseconds -lt $ms) { Start-Sleep -Milliseconds 50 }
  Shot ("a1_splash_{0:D4}" -f $ms)
}
Start-Sleep 3; Shot 'a1_home'
L 40
Crash
& $ADB logcat -d -s flutter:* | Select-Object -Last 30
