Get-Process YomiHub -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep 2
$exe = 'D:\yh\buildwin\mangayomi\build\windows\x64\runner\Release\YomiHub.exe'
$o = 'D:\Claude A.I\test\win_out.txt'; $e = 'D:\Claude A.I\test\win_err.txt'
$p = Start-Process $exe -RedirectStandardOutput $o -RedirectStandardError $e -PassThru
Start-Sleep 25
Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
"--- out"; Get-Content $o -Tail 40
"--- err"; Get-Content $e -Tail 40
