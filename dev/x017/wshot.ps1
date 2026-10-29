param([string]$name = 'w')
Add-Type -AssemblyName System.Windows.Forms,System.Drawing
Add-Type -Namespace YH -Name Win -MemberDefinition '[DllImport("user32.dll")] public static extern bool SetForegroundWindow(System.IntPtr h); [DllImport("user32.dll")] public static extern bool ShowWindow(System.IntPtr h, int c);' -ErrorAction SilentlyContinue
$p = Get-Process YomiHub -ErrorAction SilentlyContinue | Where-Object MainWindowTitle | Select-Object -First 1
if ($p) { [YH.Win]::ShowWindow($p.MainWindowHandle, 3) | Out-Null; [YH.Win]::SetForegroundWindow($p.MainWindowHandle) | Out-Null; Start-Sleep 2 }
$b = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$bmp = New-Object System.Drawing.Bitmap $b.Width, $b.Height
$g = [System.Drawing.Graphics]::FromImage($bmp); $g.CopyFromScreen($b.Location, [System.Drawing.Point]::Empty, $b.Size)
$bmp.Save("D:\Claude A.I\test\shots\$name.png"); "screen saved $name $($b.Width)x$($b.Height)"
