Add-Type -AssemblyName System.Windows.Forms,System.Drawing
function S($n) { $b=[System.Windows.Forms.Screen]::PrimaryScreen.Bounds; $bmp=New-Object System.Drawing.Bitmap $b.Width,$b.Height; $g=[System.Drawing.Graphics]::FromImage($bmp); $g.CopyFromScreen($b.Location,[System.Drawing.Point]::Empty,$b.Size); $bmp.Save("D:\Claude A.I\test\shots\$n.png"); "shot $n" }
Get-Process YomiHub -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Process 'D:\yh\wintest018\YomiHub.exe'
Start-Sleep 30
S 'w018_a'
Add-Type -Namespace YH -Name Win2 -MemberDefinition '[DllImport("user32.dll")] public static extern bool SetForegroundWindow(System.IntPtr h); [DllImport("user32.dll")] public static extern bool ShowWindow(System.IntPtr h, int c);' -ErrorAction SilentlyContinue
$p = Get-Process YomiHub | Where-Object MainWindowTitle | Select-Object -First 1
[YH.Win2]::ShowWindow($p.MainWindowHandle, 3) | Out-Null; [YH.Win2]::SetForegroundWindow($p.MainWindowHandle) | Out-Null
Start-Sleep 8
S 'w018_b'
"cpu $($p.CPU) mem $([int]($p.WorkingSet64/1MB))MB"
Get-ChildItem "$env:APPDATA" -Recurse -Filter logs.txt -ErrorAction SilentlyContinue | Where-Object FullName -match 'yomi|mangayomi' | ForEach-Object { $_.FullName; Get-Content $_.FullName -Tail 15 }
Get-Process YomiHub,xray,tor,javaw -ErrorAction SilentlyContinue | Stop-Process -Force
