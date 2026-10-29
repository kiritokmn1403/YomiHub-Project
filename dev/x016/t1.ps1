$ErrorActionPreference = 'Continue'
. 'D:\Claude A.I\common.ps1'
$ErrorActionPreference = 'Continue'
Push-Location 'D:\yh\build\mangayomi'
& flutter.bat test test/yh_016_test.dart -r expanded 2>&1 | Select-Object -Last 120
& flutter.bat test test/yh_repos_test.dart -r expanded 2>&1 | Select-Object -Last 40
Pop-Location
