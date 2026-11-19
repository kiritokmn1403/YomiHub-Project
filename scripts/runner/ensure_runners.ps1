# ensure_runners.ps1 - YomiHub 0.5.6.1: bật lại runner nào chưa chạy (không bao giờ bật trùng).
# Gọi bởi tác vụ Windows "YomiHub runners" (khi đăng nhập, khi máy thức dậy, và mỗi 10 phút).
$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))  # 0.6.0: scripts\runner -> goc du an
$log  = Join-Path $root 'jobs\ensure_runners.log'
$procs = Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" | Select-Object -ExpandProperty CommandLine
foreach ($pair in @(@('run_jobs.ps1','3_run_jobs.bat'), @('run_jobs_fast.ps1','3b_run_fast_jobs.bat'))) {
  $script = $pair[0]; $bat = $pair[1]
  $running = $procs | Where-Object { $_ -and $_ -match [regex]::Escape("\$script") }
  if (-not $running) {
    Start-Process -FilePath (Join-Path $root $bat) -WorkingDirectory $root
    Add-Content $log ("{0:yyyy-MM-dd HH:mm:ss} bat lai {1}" -f (Get-Date), $bat)
  }
}
