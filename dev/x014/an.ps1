# timeout: 40
. 'D:\Claude A.I\common.ps1'
$ErrorActionPreference = 'Continue'
$bld = 'D:\yh\build\mangayomi'
$tgz = (Get-ChildItem 'D:\Claude A.I\dev\x014\p_*.tgz' | Sort-Object LastWriteTime | Select-Object -Last 1).FullName; Write-Host "patch: $tgz"; & tar.exe -xzf $tgz -C $bld
Push-Location $bld
$paths = @(Get-Content 'D:\Claude A.I\dev\x014\an_paths.txt' | Where-Object { $_.Trim() -ne '' })
if (Test-Path 'D:\Claude A.I\dev\x014\an_pubget.txt') { & flutter.bat pub get 2>&1 | Select-Object -Last 15; Remove-Item 'D:\Claude A.I\dev\x014\an_pubget.txt' }
& flutter.bat analyze --no-pub --no-fatal-infos --no-fatal-warnings @paths 2>&1 | Where-Object { $_ -notmatch '^\s*info -' } | Select-Object -First 200
Pop-Location
