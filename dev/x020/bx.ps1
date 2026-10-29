# dev build: latest patch -> x86_64 APK (emulator)
$ErrorActionPreference = 'Continue'
. 'D:\Claude A.I\common.ps1'
$ErrorActionPreference = 'Continue'
Add-Type -Namespace YH -Name Power -MemberDefinition '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint esFlags);' -ErrorAction SilentlyContinue
[YH.Power]::SetThreadExecutionState([uint32]"0x80000001") | Out-Null
$env:PATH = "$TOOLS\android-sdk\cmake\3.22.1\bin;" + $env:PATH
$B = 'D:\yh\build\mangayomi'; $X = 'D:\Claude A.I\dev\x020'
$p = Get-ChildItem $X -Filter 'p_*.tgz' | Sort-Object Name | Select-Object -Last 1
"applying $($p.Name)"
& tar.exe -xzf $p.FullName -C $B
Push-Location $B
$abi = if (Test-Path "$X\abi.txt") { (Get-Content "$X\abi.txt").Trim() } else { 'android-x64' }
$t0 = Get-Date
& flutter.bat build apk --release --split-per-abi --target-platform $abi 2>&1 | Select-Object -Last 40
"build exit $LASTEXITCODE minutes=" + [int]((Get-Date) - $t0).TotalMinutes
Pop-Location
Get-ChildItem "$B\build\app\outputs\flutter-apk\*.apk" | Where-Object LastWriteTime -gt $t0 | ForEach-Object { Copy-Item $_.FullName "$X\$($_.Name -replace 'app-','YomiHub-0.2.0-dev-')" -Force; "$($_.Name) $([math]::Round($_.Length/1MB,1)) MB" }
[YH.Power]::SetThreadExecutionState([uint32]"0x80000000") | Out-Null
