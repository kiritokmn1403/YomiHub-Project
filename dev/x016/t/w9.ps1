Get-Process YomiHub -ErrorAction SilentlyContinue | Stop-Process -Force
$d = 'D:\yh\win015test'
if (-not (Test-Path "$d\YomiHub.exe")) { Expand-Archive 'D:\Claude A.I\output\YomiHub-0.1.5-windows-x64.zip' -DestinationPath $d -Force }
Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = "`"$d\YomiHub.exe`"" } | Out-Null
Start-Sleep 18
Add-Type @'
using System; using System.Runtime.InteropServices;
public class W { [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
 [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
 [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr hdc, uint f);
 [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out R r);
 public struct R { public int L,T,Ri,B; } }
'@
Add-Type -AssemblyName System.Drawing
$p = Get-Process YomiHub | Select-Object -First 1
$h = $p.MainWindowHandle
[W]::ShowWindow($h, 9) | Out-Null; [W]::SetForegroundWindow($h) | Out-Null; Start-Sleep 2
$r = New-Object W+R; [W]::GetWindowRect($h, [ref]$r) | Out-Null
$w = $r.Ri - $r.L; $hh = $r.B - $r.T; "rect $w x $hh"
$bmp = New-Object System.Drawing.Bitmap $w, $hh
$g = [System.Drawing.Graphics]::FromImage($bmp); $g.CopyFromScreen($r.L, $r.T, 0, 0, $bmp.Size)
$bmp.Save('D:\Claude A.I\test\shots\win015_check.png'); "saved"
