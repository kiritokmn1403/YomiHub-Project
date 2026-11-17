# usage: tv.sh <name> <timeout_s> ; stdin = PowerShell lines (TV emulator emulator-5554)
cd "$HOME/mnt/A.I Project - YomiHub Project/YomiHub-Project"
n=$1; t=${2:-150}
{ echo '. .\common.ps1; $ErrorActionPreference="Continue"; $env:ANDROID_SERIAL="emulator-5554"; $Q="audit-0.5.2\qa"'; echo 'function Shot($name){ adb shell screencap -p /sdcard/yh_shot.png | Out-Null; adb pull /sdcard/yh_shot.png "$Q\$name.png" 2>&1 | Out-Null; "shot $name" }; function Key($k){ adb shell input keyevent $k }; function Tap($x,$y){ adb shell input tap $x $y }'; cat; } | bash audit-0.5.2/job.sh pending_fast $n 10 >/dev/null
bash audit-0.5.2/wait.sh $n $t
