Get-Process YomiHub,xray,tor,javaw -ErrorAction SilentlyContinue | Stop-Process -Force
$z='D:\yh\wintest017'
if (-not (Test-Path "$z\YomiHub.exe")) { Expand-Archive 'D:\Claude A.I\output\YomiHub-0.1.7-windows-x64.zip' $z -Force }
$exe = Get-ChildItem $z -Recurse -Filter YomiHub.exe | Select-Object -First 1
Start-Process $exe.FullName
Start-Sleep 25
Add-Type -AssemblyName System.Windows.Forms,System.Drawing
$b=[System.Windows.Forms.Screen]::PrimaryScreen.Bounds; $bmp=New-Object System.Drawing.Bitmap $b.Width,$b.Height; $g=[System.Drawing.Graphics]::FromImage($bmp); $g.CopyFromScreen($b.Location,[System.Drawing.Point]::Empty,$b.Size); $bmp.Save('D:\Claude A.I\test\shots\w017_c.png')
Get-Process YomiHub,xray,tor,javaw -ErrorAction SilentlyContinue | Stop-Process -Force
"done $($exe.FullName)"
