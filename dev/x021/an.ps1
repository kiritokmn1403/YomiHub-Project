# x021: apply latest p_1NN.tgz to the build tree, pub get if needed, analyze changed dart files
$ErrorActionPreference = 'Continue'
. 'D:\Claude A.I\common.ps1'
$ErrorActionPreference = 'Continue'
$B = 'D:\yh\build\mangayomi'; $X = 'D:\Claude A.I\dev\x021'
$p = Get-ChildItem $X -Filter 'p_1*.tgz' | Sort-Object Name | Select-Object -Last 1
"applying $($p.Name)"
& tar.exe -xzf $p.FullName -C $B
Push-Location $B
if ((Test-Path "$X\pubget.flag") -or -not (Test-Path "$B\.dart_tool\yh021.ok")) {
  & flutter.bat pub get 2>&1 | Select-Object -Last 8
  Remove-Item "$X\pubget.flag" -ErrorAction SilentlyContinue
  New-Item -ItemType File -Force "$B\.dart_tool\yh021.ok" | Out-Null
}
$paths = @(Get-Content "$B\yh_changed21.txt" | Where-Object { $_ -like 'lib/*.dart' -or $_ -like 'lib/*/*' } | Where-Object { $_ -like '*.dart' } | Sort-Object -Unique | Where-Object { Test-Path "$B\$_" })
"analyzing $($paths.Count) files"
& flutter.bat analyze --no-pub --no-fatal-infos --no-fatal-warnings @paths 2>&1 | Where-Object { $_ -notmatch '^\s*info ' } | Select-Object -First 150
Pop-Location
