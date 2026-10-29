Get-Process YomiHub -ErrorAction SilentlyContinue | Stop-Process -Force
$exe = 'D:\yh\buildwin\mangayomi\build\windows\x64\runner\Release\YomiHub.exe'
Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = "`"$exe`"" } | Out-Null
Start-Sleep 12
$p = Get-Process YomiHub | Select-Object -First 1
"cpu1=$($p.CPU) threads=$($p.Threads.Count) responding=$($p.Responding)"
Start-Sleep 5
$p.Refresh(); "cpu2=$($p.CPU) responding=$($p.Responding) mem=$([int]($p.WorkingSet64/1MB))"
Get-CimInstance Win32_VideoController | ForEach-Object { "gpu: $($_.Name) $($_.DriverVersion) status=$($_.Status)" }
$q = quser 2>&1; "session: $q"
