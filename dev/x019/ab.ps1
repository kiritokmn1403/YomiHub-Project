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

"=== BUILD ==="
# dev build: latest patch -> x86_64 APK (emulator)
Add-Type -Namespace YH -Name Power -MemberDefinition '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint esFlags);' -ErrorAction SilentlyContinue
[YH.Power]::SetThreadExecutionState([uint32]"0x80000001") | Out-Null
$env:PATH = "$TOOLS\android-sdk\cmake\3.22.1\bin;" + $env:PATH
$B = 'D:\yh\build\mangayomi'; $X = 'D:\Claude A.I\dev\x019'
$p = Get-ChildItem $X -Filter 'p_*.tgz' | Sort-Object Name | Select-Object -Last 1
"applying $($p.Name)"
& tar.exe -xzf $p.FullName -C $B
Push-Location $B
$abi = if (Test-Path "$X\abi.txt") { (Get-Content "$X\abi.txt").Trim() } else { 'android-x64' }
$t0 = Get-Date
& flutter.bat build apk --release --split-per-abi --target-platform $abi 2>&1 | Select-Object -Last 40
"build exit $LASTEXITCODE minutes=" + [int]((Get-Date) - $t0).TotalMinutes
Pop-Location
Get-ChildItem "$B\build\app\outputs\flutter-apk\*.apk" | Where-Object LastWriteTime -gt $t0 | ForEach-Object { Copy-Item $_.FullName "$X\$($_.Name -replace 'app-','YomiHub-0.1.9-dev-')" -Force; "$($_.Name) $([math]::Round($_.Length/1MB,1)) MB" }
[YH.Power]::SetThreadExecutionState([uint32]"0x80000000") | Out-Null
