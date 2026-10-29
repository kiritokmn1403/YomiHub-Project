# T1: install 0.1.5 x86_64, first launch, splash, identity
if (-not (EnsureEmulator)) { return }
$apk = 'D:\Claude A.I\output\YomiHub-0.1.5-x86_64.apk'
"apk: $((Get-Item $apk).Length)"
& $ADB install -r $apk 2>&1 | Select-Object -Last 3
& $ADB shell am force-stop $PKG
& $ADB logcat -c
& $ADB shell am start -n com.yomihub.app/com.kodjodevf.mangayomi.MainActivity | Out-Null
Start-Sleep -Milliseconds 700; Shot 't1_splash_a'
Start-Sleep -Milliseconds 900; Shot 't1_splash_b'
Start-Sleep 6; Shot 't1_home'
L 60
"--- recents label ---"
& $ADB shell dumpsys activity recents | Select-String -Pattern 'yomihub|mangayomi|TaskDescription|label' | Select-Object -First 12 | ForEach-Object { "$_" }
"--- shortcuts ---"
& $ADB shell cmd shortcut get-shortcuts --user 0 com.yomihub.app 2>&1 | Select-Object -First 20
Crash
