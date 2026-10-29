Get-Process qemu-system-x86_64,emulator -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
& 'D:\Claude A.I\dev\x022\an.ps1'
"=== BUILD ==="
Remove-Item 'D:\yh\build\mangayomi\build\m_extension_server' -Recurse -Force -ErrorAction SilentlyContinue
& 'D:\Claude A.I\dev\x022\bx.ps1'
