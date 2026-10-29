$exe = 'D:\yh\buildwin\mangayomi\build\windows\x64\runner\Release\YomiHub.exe'
"exe: $((Get-Item $exe).Length) $((Get-Item $exe).VersionInfo.ProductName) $((Get-Item $exe).VersionInfo.FileDescription)"
Get-Process YomiHub -ErrorAction SilentlyContinue | Stop-Process -Force
"docs before: " + (Test-Path "$env:USERPROFILE\Documents\YomiHub") + " / Mangayomi: " + (Test-Path "$env:USERPROFILE\Documents\Mangayomi\databases\yomihub_prefs.hive")
$docs = [Environment]::GetFolderPath('MyDocuments'); "mydocs=$docs"
Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = "`"$exe`"" } | Out-Null
Start-Sleep 4; $bmpA=1; Start-Sleep 14
$p = Get-Process YomiHub -ErrorAction SilentlyContinue
"proc: $($p.Id) title='$($p.MainWindowTitle)' mem=$([int]($p.WorkingSet64/1MB))MB"
Get-ChildItem "$docs\YomiHub" -ErrorAction SilentlyContinue | ForEach-Object { "  YomiHub\$($_.Name)" }
Get-ChildItem "$docs\YomiHub\databases" -ErrorAction SilentlyContinue | Select-Object -First 8 | ForEach-Object { "  db\$($_.Name) $($_.Length)" }
Get-ItemProperty 'HKCU:\Software\Classes\yomihub\shell\open\command' -ErrorAction SilentlyContinue | ForEach-Object { "proto yomihub: $($_.'(default)')" }
Get-ItemProperty 'HKCU:\Software\Classes\mangayomi\shell\open\command' -ErrorAction SilentlyContinue | ForEach-Object { "proto mangayomi: $($_.'(default)')" }
Add-Type -AssemblyName System.Windows.Forms,System.Drawing
$b = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$bmp = New-Object System.Drawing.Bitmap $b.Width, $b.Height
$g = [System.Drawing.Graphics]::FromImage($bmp); $g.CopyFromScreen($b.Location, [System.Drawing.Point]::Empty, $b.Size)
$bmp.Save('D:\Claude A.I\test\shots\win016_e.png'); "screen saved $($b.Width)x$($b.Height)"
"alive after 18s: $([bool](Get-Process YomiHub -ErrorAction SilentlyContinue))"
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
$bmp.Save('D:\Claude A.I\test\shots\win016_f.png'); "saved"
