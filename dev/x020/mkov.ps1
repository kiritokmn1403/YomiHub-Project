# overlay_117 = overlay_116 + latest x020 p_NNN (cumulative vs Mangayomi v0.9.7)
$X = 'D:\Claude A.I\dev\x020'
$p = Get-ChildItem $X -Filter 'p_*.tgz' | Sort-Object Name | Select-Object -Last 1
$ov = 'D:\yh\ov117'; Remove-Item $ov -Recurse -Force -ErrorAction SilentlyContinue; New-Item -ItemType Directory $ov | Out-Null
& tar.exe -xzf 'D:\Claude A.I\overlay_116.tgz' -C $ov
& tar.exe -xzf $p.FullName -C $ov
Remove-Item "$ov\.yh_changed.txt","$ov\.yh_del18.txt","$ov\yh_changed20.txt","$ov\yh_del20.txt" -ErrorAction SilentlyContinue
& tar.exe -czf 'D:\Claude A.I\overlay_117.tgz' -C $ov .
Copy-Item 'D:\Claude A.I\overlay_117.tgz' 'D:\Claude A.I\overlay.tgz' -Force
Copy-Item 'D:\Claude A.I\overlay_win_109.tgz' 'D:\Claude A.I\overlay_win.tgz' -Force
"overlay_117 from $($p.Name): " + (Get-Item 'D:\Claude A.I\overlay_117.tgz').Length
