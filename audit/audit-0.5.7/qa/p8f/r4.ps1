Fg
$appPid = (A shell pidof com.yomihub.app) -join ''
"PID $appPid"
A shell "top -H -b -n 1 -p $appPid | head -40"
A shell "df -h /data | tail -2"
A shell "dumpsys meminfo com.yomihub.app | head -40"
Shot 'r4_a'; Shot 'r4_b'
A shell "cat /proc/$appPid/status | grep -E 'Threads|VmRSS'"
