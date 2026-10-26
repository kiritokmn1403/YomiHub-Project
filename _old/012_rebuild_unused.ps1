Get-CimInstance Win32_Process | Where-Object {
  ($_.CommandLine -match 'build_apk\.ps1') -or
  ($_.Name -in @('dart.exe','dartaotruntime.exe','cargo.exe','rustc.exe','flutter.bat')) -or
  ($_.Name -eq 'java.exe' -and $_.CommandLine -match 'D:\\yh')
} | ForEach-Object { "kill $($_.ProcessId) $($_.Name)"; Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
Start-Sleep 5
Start-Process cmd.exe -ArgumentList '/c', 'D:\Claude A.I\2_build_apk.bat' -WorkingDirectory 'D:\Claude A.I'
"rebuild started"
