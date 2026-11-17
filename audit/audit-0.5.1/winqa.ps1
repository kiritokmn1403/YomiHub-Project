# 0.5.1 Windows QA helpers: capture ONLY the YomiHub window (0.5.0 grabbed the
# whole desktop, which can show the owner's other apps in a public release).
$QA = "D:\A.I Project\A.I Project - YomiHub Project\YomiHub-Project\audit-0.5.1\qa"
New-Item -ItemType Directory -Force $QA | Out-Null
$FF = (Get-ChildItem "D:\yh\tools" -Directory -Filter "ffmpeg-*" | Select-Object -First 1).FullName + "\bin\ffmpeg.exe"
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
Add-Type -Name W -Namespace YH51 -MemberDefinition @'
[DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
[DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
[DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr dc, uint f);
public struct RECT { public int L, T, R, B; }
'@
function YhWin { (Get-Process YomiHub -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1) }
function WinFront { $p = YhWin; if ($p) { [YH51.W]::ShowWindow($p.MainWindowHandle, 3) | Out-Null; [YH51.W]::SetForegroundWindow($p.MainWindowHandle) | Out-Null; Start-Sleep -Milliseconds 600 } }
function WinShot($name) {
  $p = YhWin; if (-not $p) { "winshot ${name} - no window"; return }
  $r = New-Object YH51.W+RECT; [YH51.W]::GetWindowRect($p.MainWindowHandle, [ref]$r) | Out-Null
  $w = $r.R - $r.L; $h = $r.B - $r.T
  $bmp = New-Object System.Drawing.Bitmap($w, $h); $g = [System.Drawing.Graphics]::FromImage($bmp)
  $dc = $g.GetHdc(); [YH51.W]::PrintWindow($p.MainWindowHandle, $dc, 2) | Out-Null; $g.ReleaseHdc($dc)
  $bmp.Save("$QA\$name.png", [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose(); "winshot $name ${w}x$h"
}
function WinRec($name, $sec=120) {
  $p = YhWin; if (-not $p) { "winrec: no window"; return }
  $t = $p.MainWindowTitle
  $cmd = "`"$FF`" -y -f gdigrab -framerate 12 -t $sec -i title=`"$t`" -vf scale=1600:-2 -c:v libx264 -preset veryfast -crf 30 -pix_fmt yuv420p -movflags +frag_keyframe+empty_moov `"$QA\$name.mp4`""
  $si = New-CimInstance -ClassName Win32_ProcessStartup -ClientOnly -Property @{ ShowWindow = [uint16]0 }
  Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = $cmd; ProcessStartupInformation = $si } | Out-Null; "winrec $name (window '$t')"
}
function WinRecStop { Get-Process ffmpeg -ErrorAction SilentlyContinue | Stop-Process -Force; Start-Sleep 1; "winrec stopped" }
