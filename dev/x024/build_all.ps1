# YomiHub 0.2.4: overlay_121 = overlay_120 + p_401 -> APK (3 ABI) + Windows x64
Add-Type -Namespace YH -Name Power -MemberDefinition '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint esFlags);' -ErrorAction SilentlyContinue
[YH.Power]::SetThreadExecutionState([uint32]"0x80000001") | Out-Null
Get-CimInstance Win32_Process | Where-Object {
  ($_.Name -in @('dart.exe','dartaotruntime.exe','cargo.exe','rustc.exe','qemu-system-x86_64.exe','emulator.exe','YomiHub.exe','xray.exe','tor.exe')) -or
  ($_.Name -in @('java.exe','javaw.exe') -and $_.CommandLine -match 'D:\\yh|MExtensionServer|yomihub.bridge')
} | Where-Object { $_.ProcessId -ne $PID } | ForEach-Object { "kill $($_.ProcessId) $($_.Name)"; Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
Start-Sleep 2

$K = 'D:\A.I Project\YomiHub Project'
$X = "$K\dev\x024"
$ov = 'D:\yh\ov120'

# Ensure overlay_121.tgz is ready and copied to overlay.tgz
if (-not (Test-Path "$K\overlay_121.tgz")) {
  & tar.exe -czf "$K\overlay_121.tgz" -C $ov .
}
Copy-Item "$K\overlay_121.tgz" "$K\overlay.tgz" -Force
if (Test-Path "$K\overlay_win_109.tgz") {
  Copy-Item "$K\overlay_win_109.tgz" "$K\overlay_win.tgz" -Force
}

"overlay_121 length: " + (Get-Item "$K\overlay_121.tgz").Length
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
Get-ChildItem "$K\output" | Where-Object Name -match '0\.2\.4' | ForEach-Object { "$($_.Name) $($_.Length) $($_.LastWriteTime)" }
[YH.Power]::SetThreadExecutionState([uint32]"0x80000000") | Out-Null
