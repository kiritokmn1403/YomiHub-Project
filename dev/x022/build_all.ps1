# YomiHub 0.2.2 final: overlay_119 = overlay_118 + latest x022 p_2NN (cumulative vs overlay_118) -> APK (3 ABI) + Windows x64 (+ JVM bridge)
Add-Type -Namespace YH -Name Power -MemberDefinition '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint esFlags);' -ErrorAction SilentlyContinue
[YH.Power]::SetThreadExecutionState([uint32]"0x80000001") | Out-Null
Get-CimInstance Win32_Process | Where-Object {
  ($_.Name -in @('dart.exe','dartaotruntime.exe','cargo.exe','rustc.exe','qemu-system-x86_64.exe','emulator.exe','YomiHub.exe','xray.exe','tor.exe')) -or
  ($_.Name -in @('java.exe','javaw.exe') -and $_.CommandLine -match 'D:\\yh|MExtensionServer|yomihub.bridge')
} | Where-Object { $_.ProcessId -ne $PID } | ForEach-Object { "kill $($_.ProcessId) $($_.Name)"; Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
Start-Sleep 5
$K = 'D:\Claude A.I'; $X = "$K\dev\x022"
if (-not (Test-Path 'D:\yh\symbols_021')) { Copy-Item 'D:\yh\symbols' 'D:\yh\symbols_021' -Recurse -ErrorAction SilentlyContinue }
$p = Get-ChildItem $X -Filter 'p_2*.tgz' | Sort-Object Name | Select-Object -Last 1
$ov = 'D:\yh\ov119'; Remove-Item $ov -Recurse -Force -ErrorAction SilentlyContinue; New-Item -ItemType Directory $ov | Out-Null
& tar.exe -xzf "$K\overlay_118.tgz" -C $ov
& tar.exe -xzf $p.FullName -C $ov
Remove-Item "$ov\yh_changed22.txt" -ErrorAction SilentlyContinue
& tar.exe -czf "$K\overlay_119.tgz" -C $ov .
Copy-Item "$K\overlay_119.tgz" "$K\overlay.tgz" -Force
Copy-Item "$K\overlay_win_109.tgz" "$K\overlay_win.tgz" -Force
# build_win.ps1 of 0.2.1 is reused unchanged
"overlay_119 from $($p.Name): " + (Get-Item "$K\overlay_119.tgz").Length
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
Get-ChildItem "$K\output" | Where-Object Name -match '0\.2\.2' | ForEach-Object { "$($_.Name) $($_.Length) $($_.LastWriteTime)" }
[YH.Power]::SetThreadExecutionState([uint32]"0x80000000") | Out-Null
