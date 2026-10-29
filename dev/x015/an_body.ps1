$ErrorActionPreference = 'Continue'
. 'D:\Claude A.I\common.ps1'
$ErrorActionPreference = 'Continue'
$bld = 'D:\yh\build\mangayomi'
$tgz = (Get-ChildItem 'D:\Claude A.I\dev\x015\p_*.tgz' | Sort-Object Name | Select-Object -Last 1).FullName; Write-Output "patch $tgz"; & tar.exe -xzf $tgz -C $bld
Push-Location $bld
if (Test-Path 'D:\Claude A.I\dev\x015\pubget.flag') { & flutter.bat pub get 2>&1 | Select-Object -Last 8; Remove-Item 'D:\Claude A.I\dev\x015\pubget.flag' }
$paths = @(Get-Content 'D:\Claude A.I\dev\x015\an_paths.txt' | Where-Object { $_.Trim() -ne '' })
& flutter.bat analyze --no-pub --no-fatal-infos --no-fatal-warnings @paths 2>&1 | Where-Object { $_ -notmatch '^\s*info -' } | Select-Object -First 150
Pop-Location
