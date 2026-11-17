# run_0561_main.ps1 - YomiHub 0.5.6.1: dựng bộ gói chính (APK điện thoại, APK TV, Windows) tuần tự,
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
  @('test',     { & "$root\build_0561_android.ps1" -step test }),
  @('apk',      { & "$root\build_0561_android.ps1" -step apk }),
  @('tv',       { & "$root\build_0561_android.ps1" -step tv }),
  @('wintest',  { & "$root\build_0561.ps1" -step test }),
  @('win',      { & "$root\build_0561.ps1" -step win }),
  @('pack',     { & "$root\build_0561.ps1" -step pack })
)
S "=== BAT DAU dung bo goi chinh 0.5.6.1 ==="
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
