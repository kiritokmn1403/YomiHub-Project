Get-CimInstance Win32_Process | Where-Object { $_.Name -match 'qemu-system|^emulator' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
Copy-Item 'D:\Claude A.I\overlay_072.tgz' 'D:\Claude A.I\overlay.tgz' -Force
"overlay md5 " + (Get-FileHash 'D:\Claude A.I\overlay.tgz' -Algorithm MD5).Hash
& powershell -NoProfile -ExecutionPolicy Bypass -File 'D:\Claude A.I\build_apk.ps1'
"build exit $LASTEXITCODE"
Get-ChildItem 'D:\Claude A.I\output' | ForEach-Object { "$($_.Name) $($_.Length) $($_.LastWriteTime)" }
Get-CimInstance Win32_Process | Where-Object { $_.Name -eq 'java.exe' -and $_.CommandLine -match 'D:\\yh' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
