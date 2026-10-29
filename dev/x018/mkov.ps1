# overlay_115 = overlay_114 + latest p_NNN (cumulative vs 0.1.7)
$X = 'D:\Claude A.I\dev\x018'
$p = Get-ChildItem $X -Filter 'p_*.tgz' | Sort-Object Name | Select-Object -Last 1
$ov = 'D:\yh\ov115'; Remove-Item $ov -Recurse -Force -ErrorAction SilentlyContinue; New-Item -ItemType Directory $ov | Out-Null
& tar.exe -xzf 'D:\Claude A.I\overlay_114.tgz' -C $ov
& tar.exe -xzf $p.FullName -C $ov
Remove-Item "$ov\.yh_changed.txt","$ov\.yh_del18.txt" -ErrorAction SilentlyContinue
& tar.exe -czf 'D:\Claude A.I\overlay_115.tgz' -C $ov .
Copy-Item 'D:\Claude A.I\overlay_115.tgz' 'D:\Claude A.I\overlay.tgz' -Force
"overlay_115 from $($p.Name): " + (Get-Item 'D:\Claude A.I\overlay_115.tgz').Length
