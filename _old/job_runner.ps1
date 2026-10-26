# YomiHub job runner: runs *.ps1 job files dropped into D:\Claude A.I\jobs\pending
# (each in its own PowerShell window-less process), logs to jobs\done.
# Stops by itself after 3 hours without new jobs, or when jobs\STOP exists.
$ErrorActionPreference = 'Continue'
$J = 'D:\Claude A.I\jobs'
foreach ($d in 'pending','running','done') { New-Item -ItemType Directory -Force "$J\$d" | Out-Null }
Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -match 'job_runner\.ps1' -and $_.ProcessId -ne $PID } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
Remove-Item "$J\STOP" -ErrorAction SilentlyContinue
$last = Get-Date
Set-Content "$J\runner_alive.txt" (Get-Date -Format s)
while ($true) {
  if (Test-Path "$J\STOP") { break }
  if (((Get-Date) - $last).TotalHours -gt 3) { break }
  Get-ChildItem "$J\pending" -Filter *.ps1 -ErrorAction SilentlyContinue | Sort-Object Name | ForEach-Object {
    $last = Get-Date
    $run = Join-Path "$J\running" $_.Name
    Move-Item $_.FullName $run -Force
    $log = Join-Path "$J\done" ($_.BaseName + '.log')
    $cmd = "& '$run' *> '$log'; Move-Item '$run' '$J\done\' -Force; Add-Content '$log' ('### EXIT ' + `$LASTEXITCODE + ' ' + (Get-Date -Format s))"
    Start-Process powershell -WindowStyle Hidden -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-Command',$cmd)
  }
  Set-Content "$J\runner_alive.txt" (Get-Date -Format s)
  Start-Sleep 3
}
