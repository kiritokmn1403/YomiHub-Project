# YomiHub 0.2.1 final: overlay_118 (full, from latest x021 p_1NN) -> APK (3 ABI) + Windows x64 (+ JVM bridge)
Add-Type -Namespace YH -Name Power -MemberDefinition '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint esFlags);' -ErrorAction SilentlyContinue
[YH.Power]::SetThreadExecutionState([uint32]"0x80000001") | Out-Null
Get-CimInstance Win32_Process | Where-Object {
  ($_.Name -in @('dart.exe','dartaotruntime.exe','cargo.exe','rustc.exe','qemu-system-x86_64.exe','emulator.exe','YomiHub.exe','xray.exe','tor.exe')) -or
  ($_.Name -in @('java.exe','javaw.exe') -and $_.CommandLine -match 'D:\\yh|MExtensionServer|yomihub.bridge')
} | Where-Object { $_.ProcessId -ne $PID } | ForEach-Object { "kill $($_.ProcessId) $($_.Name)"; Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
Start-Sleep 5
$K = 'D:\Claude A.I'; $X = "$K\dev\x021"
if (-not (Test-Path 'D:\yh\symbols_020')) { Copy-Item 'D:\yh\symbols' 'D:\yh\symbols_020' -Recurse }
$p = Get-ChildItem $X -Filter 'p_1*.tgz' | Sort-Object Name | Select-Object -Last 1
$ov = 'D:\yh\ov118'; Remove-Item $ov -Recurse -Force -ErrorAction SilentlyContinue; New-Item -ItemType Directory $ov | Out-Null
& tar.exe -xzf $p.FullName -C $ov
Remove-Item "$ov\yh_changed21.txt" -ErrorAction SilentlyContinue
& tar.exe -czf "$K\overlay_118.tgz" -C $ov .
Copy-Item "$K\overlay_118.tgz" "$K\overlay.tgz" -Force
Copy-Item "$K\overlay_win_109.tgz" "$K\overlay_win.tgz" -Force
if (-not (Test-Path "$K\build_win_020.ps1")) { Copy-Item "$K\build_win.ps1" "$K\build_win_020.ps1" }
Copy-Item "$X\build_win_021.ps1" "$K\build_win.ps1" -Force
"overlay_118 from $($p.Name): " + (Get-Item "$K\overlay_118.tgz").Length
& subst.exe Y: /D 2>&1 | Out-Null
$t0 = Get-Date
& powershell -NoProfile -ExecutionPolicy Bypass -File "$K\build_apk.ps1"
"apk build exit $LASTEXITCODE minutes=" + [int]((Get-Date) - $t0).TotalMinutes
Get-CimInstance Win32_Process | Where-Object { $_.Name -eq 'java.exe' -and $_.CommandLine -match 'D:\\yh' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
& subst.exe Y: /D 2>&1 | Out-Null
$t1 = Get-Date
& powershell -NoProfile -ExecutionPolicy Bypass -File "$K\build_win.ps1"
"win build exit $LASTEXITCODE minutes=" + [int]((Get-Date) - $t1).TotalMinutes
Get-Content "$K\logs\status.txt" -Tail 20
Get-ChildItem "$K\output" | Where-Object Name -match '0\.2\.1' | ForEach-Object { "$($_.Name) $($_.Length) $($_.LastWriteTime)" }
[YH.Power]::SetThreadExecutionState([uint32]"0x80000000") | Out-Null
