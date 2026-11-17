# YomiHub 0.5.2 QA: records the Note 9 DeX display (screenrecord v1.2 has no
# --display-id) as a timed screencap sequence, then encodes a real-time MP4.
param([string]$name, [int]$max = 900)
Set-Location "D:\A.I Project\A.I Project - YomiHub Project\YomiHub-Project"
$adb = "D:\yh\tools\android-sdk\platform-tools\adb.exe"
$ff = "D:\yh\tools\ffmpeg-9.0.2-essentials_build\bin\ffmpeg.exe"
$dir = "audit-0.5.3\qa\frames_$name"
New-Item -ItemType Directory -Force $dir | Out-Null
Remove-Item "audit-0.5.3\qa\STOPREC" -ErrorAction SilentlyContinue
$i = 0; $t0 = Get-Date
while (-not (Test-Path "audit-0.5.3\qa\STOPREC") -and ((Get-Date) - $t0).TotalSeconds -lt $max) {
  & $adb -s 281038ac31217ece shell "screencap -d 2 -p /sdcard/yh_rec.png" 2>$null | Out-Null
  & $adb -s 281038ac31217ece pull /sdcard/yh_rec.png ("{0}\f{1:d5}.png" -f $dir, $i) 2>$null | Out-Null
  $i++
}
$sec = ((Get-Date) - $t0).TotalSeconds
$fps = [Math]::Max(0.5, [Math]::Round($i / [Math]::Max(1, $sec), 3))
& $ff -y -framerate $fps -i "$dir\f%05d.png" -vf "scale=1280:-2,format=yuv420p" -c:v libx264 -preset veryfast -crf 28 -r 10 "audit-0.5.3\qa\$name.mp4" 2>&1 | Select-Object -Last 2 | Set-Content "audit-0.5.3\qa\$name.ffmpeg.txt"
"frames=$i sec=$([int]$sec) fps=$fps" | Add-Content "audit-0.5.3\qa\$name.ffmpeg.txt"
