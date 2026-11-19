# YomiHub job runner (watch mode).
# Runs every jobs\pending\*.ps1 in name order, logs to jobs\done\<name>.log,
# then keeps watching for new jobs. A job may set its own limit with a first
# line "# timeout: <minutes>" (default 120). Create jobs\STOP to quit.
# 0.5.0: turn off console QuickEdit - a stray click in this window put it in
# "Select" mode and froze every job (03/11/2026 12:10).
try {
  Add-Type -Name QE -Namespace YH -MemberDefinition '[DllImport("kernel32.dll")] public static extern IntPtr GetStdHandle(int h); [DllImport("kernel32.dll")] public static extern bool GetConsoleMode(IntPtr h, out uint m); [DllImport("kernel32.dll")] public static extern bool SetConsoleMode(IntPtr h, uint m);' -ErrorAction Stop
  $qeH = [YH.QE]::GetStdHandle(-10); $qeM = 0
  if ([YH.QE]::GetConsoleMode($qeH, [ref]$qeM)) { [void][YH.QE]::SetConsoleMode($qeH, (($qeM -band (-bnot 0x40)) -bor 0x80)) }
} catch { }
try { . (Join-Path $PSScriptRoot 'link_paths.ps1') } catch { Write-Host $_ }
$J = Join-Path $PSScriptRoot 'jobs'
foreach ($d in 'pending','done') { New-Item -ItemType Directory -Force "$J\$d" | Out-Null }
Remove-Item "$J\STOP" -ErrorAction SilentlyContinue
Write-Host "YomiHub job runner - dang cho tac vu (tao file jobs\STOP de dung)" -ForegroundColor Green
while (-not (Test-Path "$J\STOP")) {
  Set-Content "$J\runner_alive.txt" (Get-Date -Format s)
  $job = Get-ChildItem "$J\pending" -Filter *.ps1 | Sort-Object Name | Select-Object -First 1
  if (-not $job) { Start-Sleep 5; continue }
  $log = Join-Path "$J\done" ($job.BaseName + '.log')
  $limit = 120
  $first = Get-Content $job.FullName -TotalCount 2 -Encoding UTF8 | Out-String
  if ($first -match '#\s*timeout:\s*(\d+)') { $limit = [int]$Matches[1] }
  Write-Host ("== {0}  {1}  (gioi han {2} phut)" -f (Get-Date -Format HH:mm:ss), $job.Name, $limit) -ForegroundColor Cyan
  $cmd = "& '" + $job.FullName + "' *> '" + $log + "'"
  $p = Start-Process powershell -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-Command',$cmd) -WindowStyle Hidden -PassThru
  $done = $p.WaitForExit($limit * 60 * 1000)
  if (-not $done) { & taskkill.exe /T /F /PID $p.Id | Out-Null; Add-Content $log "### TIMEOUT after $limit min" }
  Add-Content $log ("### EXIT " + $(if ($done) { $p.ExitCode } else { 'killed' }) + " " + (Get-Date -Format s))
  Move-Item $job.FullName "$J\done\" -Force
}
Write-Host "Da dung." -ForegroundColor Yellow
