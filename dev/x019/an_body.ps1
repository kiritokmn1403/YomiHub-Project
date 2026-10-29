$ErrorActionPreference = 'Continue'
. 'D:\Claude A.I\common.ps1'
$ErrorActionPreference = 'Continue'
$B = 'D:\yh\build\mangayomi'
$X = 'D:\Claude A.I\dev\x019'
$p = Get-ChildItem $X -Filter 'p_*.tgz' | Sort-Object Name | Select-Object -Last 1
"applying $($p.Name)"
& tar.exe -xzf $p.FullName -C $B
Push-Location $B
if (Test-Path "$X\pubget.flag") { & flutter.bat pub get 2>&1 | Select-Object -Last 8; Remove-Item "$X\pubget.flag" }
$paths = @(Get-Content "$B\.yh_changed.txt" | Where-Object { ($_ -like '*.dart' -or $_ -like 'test/*') -and $_.Trim() -ne '' } | Sort-Object -Unique | Where-Object { Test-Path "$B\$_" })
"analyzing $($paths.Count) files"
& flutter.bat analyze --no-pub --no-fatal-infos --no-fatal-warnings @paths 2>&1 | Select-Object -First 200
if (Test-Path "$X\test.flag") { $t = Get-Content "$X\test.flag"; & flutter.bat test --no-pub $t 2>&1 | Select-Object -Last 40; Remove-Item "$X\test.flag" }
Pop-Location
