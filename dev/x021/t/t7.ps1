. 'D:\Claude A.I\dev\x021\t\h.ps1'
if (-not (EnsureEmulator)) { return }
& $ADB install -r 'D:\Claude A.I\dev\x021\YomiHub-0.2.1-dev-x86_64-release.apk' 2>&1 | Select-Object -Last 1
& $ADB logcat -c; & $ADB logcat -b crash -c
Launch 15
Tap 848 2169 5
TapText '^Extensions$' 5
L2 'ext' | Select-Object -First 50 | Select-String -NotMatch 'Tab '
