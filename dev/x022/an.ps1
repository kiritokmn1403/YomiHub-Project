# x022: apply all p_2NN.tgz newer than last applied, pub get if flagged, analyze changed dart files
$ErrorActionPreference = 'Continue'
. 'D:\Claude A.I\common.ps1'
$ErrorActionPreference = 'Continue'
$B = 'D:\yh\build\mangayomi'; $X = 'D:\Claude A.I\dev\x022'
$p = Get-ChildItem $X -Filter 'p_2*.tgz' | Sort-Object Name | Select-Object -Last 1
"applying $($p.Name)"
& tar.exe -xzf $p.FullName -C $B
Push-Location $B
if (Test-Path "$X\pubget.flag") {
  & flutter.bat pub get 2>&1 | Select-Object -Last 8
  Remove-Item "$X\pubget.flag" -ErrorAction SilentlyContinue
}
$paths = @(Get-Content "$B\yh_changed22.txt" | Where-Object { $_ -like 'lib/*.dart' } | Sort-Object -Unique | Where-Object { Test-Path "$B\$_" })
"analyzing $($paths.Count) files"
if ($paths.Count -gt 0) { & flutter.bat analyze --no-pub --no-fatal-infos --no-fatal-warnings @paths 2>&1 | Where-Object { $_ -notmatch '^\s*info ' } | Select-Object -First 150 }
Pop-Location
