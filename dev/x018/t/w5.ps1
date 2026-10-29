Get-Process YomiHub,xray,tor,javaw -ErrorAction SilentlyContinue | Stop-Process -Force
$o='D:\Claude A.I\test\win_out.txt'; $e='D:\Claude A.I\test\win_err.txt'
$p = Start-Process 'D:\yh\wintest018\YomiHub.exe' -RedirectStandardOutput $o -RedirectStandardError $e -PassThru
Start-Sleep 25
Add-Type -AssemblyName System.Windows.Forms,System.Drawing
$b=[System.Windows.Forms.Screen]::PrimaryScreen.Bounds; $bmp=New-Object System.Drawing.Bitmap $b.Width,$b.Height; $g=[System.Drawing.Graphics]::FromImage($bmp); $g.CopyFromScreen($b.Location,[System.Drawing.Point]::Empty,$b.Size); $bmp.Save('D:\Claude A.I\test\shots\w018_c.png')
Get-Process YomiHub,xray,tor,javaw -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep 1
"--- out"; Get-Content $o -Tail 60; "--- err"; Get-Content $e -Tail 40
# GPU info
Get-CimInstance Win32_VideoController | ForEach-Object { "$($_.Name) $($_.DriverVersion)" }
