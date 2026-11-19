# run_062_main.ps1 - YomiHub 0.6.2: dựng bộ gói chính (APK điện thoại, APK TV, Windows, APK android6, verify) tuần tự
param(
  [string[]]$RunSteps
)
$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))  # 0.6.2: scripts\pipeline -> goc du an
$lock = Join-Path $root 'audit\audit-0.5.6\coordination\BUILD_LOCK.txt'
$st   = Join-Path $root 'audit\audit-0.6.2\release\main_build_status_062.txt'
Start-Transcript -Path (Join-Path $root 'audit\audit-0.6.2\release\main_build_062.log') -Append | Out-Null
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
  @('sync',     { & "$root\scripts\sync\sync_062.ps1" -Regen }),
  @('test',     { & "$root\scripts\build\build_062_android.ps1" -step test }),
  @('apk',      { & "$root\scripts\build\build_062_android.ps1" -step apk }),
  @('tv',       { & "$root\scripts\build\build_062_android.ps1" -step tv }),
  @('wintest',  { & "$root\scripts\build\build_062.ps1" -step test }),
  @('win',      { & "$root\scripts\build\build_062.ps1" -step win }),
  @('pack',     { & "$root\scripts\build\build_062.ps1" -step pack }),
  @('a6build',  { & "$root\scripts\build\build_062_android6.ps1" -step all }),
  @('a6copy',   { & "$root\scripts\build\build_062_android.ps1" -step a6 }),
  @('verify',   { & "$root\scripts\build\build_062.ps1" -step verify })
)
if ($RunSteps -and $RunSteps.Count -gt 0) {
  $parsedSteps = @()
  foreach ($rs in $RunSteps) {
    $parsedSteps += ($rs -split ',') | ForEach-Object { $_.Trim() } | Where-Object { $_ }
  }
  $steps = @($steps | Where-Object { $parsedSteps -contains $_[0] })
  S ("Loc buoc theo RunSteps: " + (($steps | ForEach-Object { $_[0] }) -join ', '))
}
S "=== BAT DAU dung bo goi chinh 0.6.2 ==="
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
S "=== XONG bo goi chinh 0.6.2 (gom APK android6 + verify) ==="
Stop-Transcript | Out-Null
