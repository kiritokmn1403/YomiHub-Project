Add-Type -AssemblyName System.Drawing
# returns 'choice' when the "Nhập theo cách nào?" dialog is up, 'busy' for the reading dialog, else 'none'
function DlgState(){
  adb shell screencap -d 2 -p /sdcard/yh_p.png | Out-Null; adb pull /sdcard/yh_p.png "$env:TEMP\yh_p.png" 2>&1 | Out-Null
  $b = [System.Drawing.Bitmap]::FromFile("$env:TEMP\yh_p.png")
  function L($x,$y){ $c=$b.GetPixel($x,$y); ($c.R+$c.G+$c.B)/3 }
  $s = 'none'
  if ((L 720 690) -gt 200 -and (L 1210 370) -gt 200 -and (L 300 800) -lt 140) { $s='choice' } elseif ((L 840 515) -gt 200 -and (L 1090 550) -gt 200 -and (L 720 690) -lt 150) { $s='busy' }
  $b.Dispose(); return $s
}
