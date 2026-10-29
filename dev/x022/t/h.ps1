. 'D:\Claude A.I\dev\x021\t\h.ps1'
$T = 'D:\Claude A.I\dev\x022\t'
New-Item -ItemType Directory -Force "$T\shots" | Out-Null
function Shot2($name) { & $ADB shell screencap -p /sdcard/yh_shot.png | Out-Null; & $ADB pull /sdcard/yh_shot.png "$T\shots\$name.png" 2>&1 | Out-Null; "shot $name" }
function AppLog($n = 40) {
  foreach ($d in '/sdcard/YomiHub','/sdcard/Download/YomiHub','/storage/emulated/0/Android/data/com.yomihub.app/files') {
    $r = (& $ADB shell "ls $d/logs.txt" 2>&1) -join ''
    if ($r -notmatch 'No such') { & $ADB pull "$d/logs.txt" "$T\logs_app.txt" 2>&1 | Out-Null; "--- app log ($d) ---"; Get-Content "$T\logs_app.txt" -Encoding UTF8 -Tail $n; return }
  }
  "app log not found"
}
function CrashCheck { "pid " + ((& $ADB shell pidof com.yomihub.app) -join ''); & $ADB logcat -d -b events 2>&1 | Select-String 'am_crash|am_anr' | Select-Object -Last 5 | ForEach-Object { "$_" } }
