$ErrorActionPreference = 'Continue'
. 'D:\Claude A.I\common.ps1'
$ErrorActionPreference = 'Continue'
Push-Location 'D:\yh\build\mangayomi'
if (Test-Path 'D:\Claude A.I\dev\x016\pubget.flag') { & flutter.bat pub get 2>&1 | Select-Object -Last 8; Remove-Item 'D:\Claude A.I\dev\x016\pubget.flag' }
$paths = @(Get-Content 'D:\Claude A.I\dev\x016\changed.txt' | Where-Object { $_.Trim() -ne '' } | Sort-Object -Unique)
& flutter.bat analyze --no-pub --no-fatal-infos --no-fatal-warnings @paths 2>&1 | Where-Object { $_ -notmatch '^\s*info -' } | Select-Object -First 120
Pop-Location
