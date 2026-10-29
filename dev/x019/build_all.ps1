# YomiHub 0.1.9 final: overlay_116 (= overlay_114 + latest p) -> APK + Windows
Add-Type -Namespace YH -Name Power -MemberDefinition '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint esFlags);'
[YH.Power]::SetThreadExecutionState([uint32]"0x80000001") | Out-Null
Get-CimInstance Win32_Process | Where-Object {
  ($_.Name -in @('dart.exe','dartaotruntime.exe','cargo.exe','rustc.exe','qemu-system-x86_64.exe','emulator.exe','YomiHub.exe','xray.exe','tor.exe')) -or
  ($_.Name -in @('java.exe','javaw.exe') -and $_.CommandLine -match 'D:\\yh|MExtensionServer')
} | Where-Object { $_.ProcessId -ne $PID } | ForEach-Object { "kill $($_.ProcessId) $($_.Name)"; Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
Start-Sleep 5
& 'D:\Claude A.I\dev\x019\mkov.ps1'
& subst.exe Y: /D 2>&1 | Out-Null
$t0 = Get-Date
& powershell -NoProfile -ExecutionPolicy Bypass -File 'D:\Claude A.I\build_apk.ps1'
"apk build exit $LASTEXITCODE minutes=" + [int]((Get-Date) - $t0).TotalMinutes
Get-CimInstance Win32_Process | Where-Object { $_.Name -eq 'java.exe' -and $_.CommandLine -match 'D:\\yh' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
& subst.exe Y: /D 2>&1 | Out-Null
$t1 = Get-Date
& powershell -NoProfile -ExecutionPolicy Bypass -File 'D:\Claude A.I\build_win.ps1'
"win build exit $LASTEXITCODE minutes=" + [int]((Get-Date) - $t1).TotalMinutes
Get-Content 'D:\Claude A.I\logs\status.txt' -Tail 16
Get-ChildItem 'D:\Claude A.I\output' | Where-Object Name -match '0\.1\.9' | ForEach-Object { "$($_.Name) $($_.Length) $($_.LastWriteTime)" }
[YH.Power]::SetThreadExecutionState([uint32]"0x80000000") | Out-Null
