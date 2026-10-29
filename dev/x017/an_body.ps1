$ErrorActionPreference = 'Continue'
. 'D:\Claude A.I\common.ps1'
$ErrorActionPreference = 'Continue'
$B = 'D:\yh\build\mangayomi'
$p = Get-ChildItem 'D:\Claude A.I\dev\x017' -Filter 'p_*.tgz' | Sort-Object Name | Select-Object -Last 1
"applying $($p.Name)"
& tar.exe -xzf $p.FullName -C $B
Push-Location $B
if (Test-Path 'D:\Claude A.I\dev\x017\pubget.flag') { & flutter.bat pub get 2>&1 | Select-Object -Last 8; Remove-Item 'D:\Claude A.I\dev\x017\pubget.flag' }
$paths = @(Get-Content "$B\.yh_changed.txt" | Where-Object { $_ -like '*.dart' -or $_ -like 'test/*' } | Where-Object { $_.Trim() -ne '' } | Sort-Object -Unique)
$paths += @(Get-Content 'D:\Claude A.I\dev\x016\changed.txt' | Where-Object { $_.Trim() -ne '' -and $_ -like '*.dart' })
$paths = $paths | Sort-Object -Unique | Where-Object { Test-Path "$B\$_" }
"analyzing $($paths.Count) files"
& flutter.bat analyze --no-pub --no-fatal-infos --no-fatal-warnings @paths 2>&1 | Select-Object -First 150
Pop-Location
