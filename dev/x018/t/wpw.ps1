param([string]$exePath = 'D:\yh\wintest018\YomiHub.exe', [string]$name = 'w018_pw')
Add-Type -AssemblyName System.Drawing
Add-Type -Namespace YH -Name PW -MemberDefinition @'
[DllImport("user32.dll")] public static extern bool PrintWindow(System.IntPtr h, System.IntPtr hdc, uint f);
[DllImport("user32.dll")] public static extern bool GetWindowRect(System.IntPtr h, out RECT r);
[DllImport("user32.dll")] public static extern bool SetForegroundWindow(System.IntPtr h);
public struct RECT { public int L, T, R, B; }
'@
Get-Process YomiHub,xray,tor,javaw -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Process $exePath
Start-Sleep 25
$p = Get-Process YomiHub | Where-Object MainWindowTitle | Select-Object -First 1
[YH.PW]::SetForegroundWindow($p.MainWindowHandle) | Out-Null; Start-Sleep 2
$r = New-Object YH.PW+RECT; [YH.PW]::GetWindowRect($p.MainWindowHandle, [ref]$r) | Out-Null
$w = $r.R - $r.L; $h = $r.B - $r.T
$bmp = New-Object System.Drawing.Bitmap $w, $h
$g = [System.Drawing.Graphics]::FromImage($bmp); $hdc = $g.GetHdc()
$ok = [YH.PW]::PrintWindow($p.MainWindowHandle, $hdc, 2); $g.ReleaseHdc($hdc)
$bmp.Save("D:\Claude A.I\test\shots\$name.png"); "printwindow $ok ${w}x${h}"
Get-Process YomiHub,xray,tor,javaw -ErrorAction SilentlyContinue | Stop-Process -Force
