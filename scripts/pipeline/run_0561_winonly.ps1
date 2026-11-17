# run_0561_winonly.ps1 - YomiHub 0.5.6.1: chỉ dựng lại Windows (sync -> win -> pack) sau khi sửa ProductVersion (Runner.rc);
# APK điện thoại/TV giữ bản 08:09–08:39. Ghi chung main_build_status.txt,
# chờ BUILD_LOCK trống trước mỗi bước (agent Android 6.0 có thể giữ khóa xen kẽ). Không dựng APK android6.
$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$lock = Join-Path $root 'audit-0.5.6\coordination\BUILD_LOCK.txt'
$st   = Join-Path $root 'audit-0.5.7\release\main_build_status.txt'
Start-Transcript -Path (Join-Path $root 'audit-0.5.7\release\main_build.log') -Append | Out-Null
function S($m){ $l = "{0:dd/MM HH:mm:ss} {1}" -f (Get-Date), $m; Write-Host $l; Add-Content $st $l -Encoding UTF8 }
function WaitLock {
  for($i=0; $i -lt 360; $i++){
    $c = "$(Get-Content $lock -Raw -ErrorAction SilentlyContinue)".Trim([char]0xFEFF,' ',"`r","`n")
    if(-not $c){ return }
    if($i % 10 -eq 0){ S "cho khoa: $c" }
    Start-Sleep 60
  }
  S "QUA 6 GIO CHO KHOA - DUNG"; Stop-Transcript | Out-Null; exit 3
}
$steps = @(
  @('sync',     { & "$root\sync_0561.ps1" -Regen }),
  @('win',      { & "$root\build_0561.ps1" -step win }),
  @('pack',     { & "$root\build_0561.ps1" -step pack })
)
S "=== BAT DAU dung bo goi chinh 0.5.6.1 (chi Windows) ==="
foreach($s in $steps){
  WaitLock
  S "--> buoc $($s[0])"
  $t0 = Get-Date
  $global:LASTEXITCODE = 0
  try { & $s[1] } catch { S "NGOAI LE buoc $($s[0]): $_"; $global:LASTEXITCODE = 99 }
  $code = $LASTEXITCODE
  S ("<-- buoc {0} exit={1} ({2:N0} phut)" -f $s[0], $code, ((Get-Date)-$t0).TotalMinutes)
  if($code -ne 0){ S "DUNG vi buoc $($s[0]) loi"; Stop-Transcript | Out-Null; exit $code }
}
S "=== XONG bo goi chinh 0.5.6.1 (chua co APK android6, chua verify toan bo) ==="
Stop-Transcript | Out-Null
