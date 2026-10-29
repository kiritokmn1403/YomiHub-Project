Get-Process YomiHub -ErrorAction SilentlyContinue | Stop-Process -Force
& 'D:\Claude A.I\dev\x021\an.ps1'
"=== FINAL BUILD ==="
& 'D:\Claude A.I\dev\x021\build_all.ps1'
