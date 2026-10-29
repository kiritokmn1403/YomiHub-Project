# overlay_116 = overlay_115 + latest x019 p_NNN (cumulative vs Mangayomi v0.9.7)
$X = 'D:\Claude A.I\dev\x019'
$p = Get-ChildItem $X -Filter 'p_*.tgz' | Sort-Object Name | Select-Object -Last 1
$ov = 'D:\yh\ov116'; Remove-Item $ov -Recurse -Force -ErrorAction SilentlyContinue; New-Item -ItemType Directory $ov | Out-Null
& tar.exe -xzf 'D:\Claude A.I\overlay_115.tgz' -C $ov
& tar.exe -xzf $p.FullName -C $ov
Remove-Item "$ov\.yh_changed.txt","$ov\.yh_del18.txt","$ov\.yh_del19.txt" -ErrorAction SilentlyContinue
& tar.exe -czf 'D:\Claude A.I\overlay_116.tgz' -C $ov .
Copy-Item 'D:\Claude A.I\overlay_116.tgz' 'D:\Claude A.I\overlay.tgz' -Force
Copy-Item 'D:\Claude A.I\overlay_win_109.tgz' 'D:\Claude A.I\overlay_win.tgz' -Force
"overlay_116 from $($p.Name): " + (Get-Item 'D:\Claude A.I\overlay_116.tgz').Length
