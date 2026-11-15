# P7 ww_lib.ps1 - cong cu chup/chan doan cua so YomiHub tren Windows (dung chung cho job p7_ww*)
$ErrorActionPreference='Continue'
$WEV='D:\A.I Project\A.I Project - YomiHub Project\YomiHub-Project\audit-0.5.7\evidence\win'
New-Item -ItemType Directory -Force $WEV | Out-Null
Add-Type -AssemblyName System.Drawing,System.Windows.Forms
Add-Type @"
using System; using System.Text; using System.Runtime.InteropServices;
public class W7 {
 [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
 [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h,int c);
 [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
 [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
 [DllImport("user32.dll")] public static extern IntPtr FindWindowEx(IntPtr p, IntPtr c, string cls, string t);
 [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
 [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassName(IntPtr h, StringBuilder s, int n);
 [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr dc, uint f);
 [DllImport("dwmapi.dll")] public static extern int DwmGetCompositionTimingInfo(IntPtr h, ref DTI t);
 [DllImport("dwmapi.dll")] public static extern int DwmIsCompositionEnabled(out bool e);
 public struct RECT { public int L,T,R,B; }
 [StructLayout(LayoutKind.Sequential, Pack=1)] public struct DTI { public uint cbSize; public uint rateRefreshN; public uint rateRefreshD; public ulong qpcRefreshPeriod; public uint rateComposeN; public uint rateComposeD; public ulong qpcVBlank; public ulong cRefresh; public uint cDXRefresh; public ulong qpcCompose; public ulong cFrame; public uint cDXPresent; public ulong cRefreshFrame; public ulong cFrameSubmitted; public uint cDXPresentSubmitted; public ulong cFrameConfirmed; public uint cDXPresentConfirmed; public ulong cRefreshConfirmed; public uint cDXRefreshConfirmed; public ulong cFramesLate; public uint cFramesOutstanding; public ulong cFrameDisplayed; public ulong qpcFrameDisplayed; public ulong cRefreshFrameDisplayed; public ulong cFrameComplete; public ulong qpcFrameComplete; public ulong cFramePending; public ulong qpcFramePending; public ulong cFramesDisplayed; public ulong cFramesComplete; public ulong cFramesPending; public ulong cFramesAvailable; public ulong cFramesDropped; public ulong cFramesMissed; public ulong cRefreshNextDisplayed; public ulong cRefreshNextPresented; public ulong cRefreshesDisplayed; public ulong cRefreshesPresented; public ulong cRefreshStarted; public ulong cPixelsReceived; public ulong cPixelsDrawn; public ulong cBuffersEmpty; }
}
"@
[W7]::SetProcessDPIAware() | Out-Null
function WStat($bmp){ $w=0;$n=0;$set=@{}; for($y=40;$y -lt $bmp.Height;$y+=8){ for($x=4;$x -lt $bmp.Width;$x+=8){ $c=$bmp.GetPixel($x,$y).ToArgb(); $n++; if($c -eq -1){$w++}; $set[$c]=1 } }; "white=$([int](100*$w/[Math]::Max($n,1)))% colors=$($set.Count) size=$($bmp.Width)x$($bmp.Height)" }
function WProc { Get-Process YomiHub -EA SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1 }
function WSnap($tag){
  $p=WProc; if(!$p){ "no process"; return 'none' }
  $h=$p.MainWindowHandle; [W7]::ShowWindow($h,9)|Out-Null; [W7]::SetForegroundWindow($h)|Out-Null; Start-Sleep -Milliseconds 700
  $r=New-Object W7+RECT; [W7]::GetWindowRect($h,[ref]$r)|Out-Null; $w=$r.R-$r.L; $hh=$r.B-$r.T
  if($w -le 0 -or $hh -le 0){ "bad rect"; return 'none' }
  $b=New-Object Drawing.Bitmap $w,$hh; $g=[Drawing.Graphics]::FromImage($b); $g.CopyFromScreen($r.L,$r.T,0,0,$b.Size); $g.Dispose()
  $b.Save("$WEV\$tag.png"); $s = WStat $b; $b.Dispose()
  Write-Host "$tag rect $($r.L),$($r.T) responding=$($p.Responding): $s"
  if($s -match 'white=(\d+)%' -and [int]$Matches[1] -ge 90){ return 'white' } else { return 'ok' }
}
function WDiag {
  $p=WProc; if(!$p){ return }
  "threads: " + (($p.Threads | Group-Object { "$($_.ThreadState)/$($_.WaitReason)" } | ForEach-Object { "$($_.Name)=$($_.Count)" }) -join ', ')
  $t0=@{}; foreach($t in $p.Threads){ try { $t0[$t.Id]=$t.TotalProcessorTime.TotalMilliseconds } catch {} }
  Start-Sleep 3; $p.Refresh()
  $busy = foreach($t in $p.Threads){ try { $d=$t.TotalProcessorTime.TotalMilliseconds-$t0[$t.Id]; if($d -gt 30){ "tid $($t.Id) +$([int]$d)ms $($t.ThreadState)/$($t.WaitReason)" } } catch {} }
  "cpu 3s: " + ($busy -join '; ')
  "modules: " + (($p.Modules | Where-Object { $_.ModuleName -match '^(d3d|dxgi|dcomp|dwm|nv|igd|ig\d|amd|ati|opengl|vulkan|libEGL|libGLES|flutter_windows|RTSS|overlay|.*hook.*|gameoverlay|dxcore|d2d1|twinapi|CoreMessaging|uiautomationcore)' } | ForEach-Object { $_.ModuleName } | Sort-Object -Unique) -join ' ')
  $c=[IntPtr]::Zero; $kids=@(); while(($c=[W7]::FindWindowEx($p.MainWindowHandle,$c,$null,$null)) -ne [IntPtr]::Zero){ $sb=New-Object Text.StringBuilder 200; [W7]::GetClassName($c,$sb,200)|Out-Null; $r=New-Object W7+RECT; [W7]::GetWindowRect($c,[ref]$r)|Out-Null; $kids += "$($sb.ToString()) vis=$([W7]::IsWindowVisible($c)) $($r.L),$($r.T),$($r.R),$($r.B)" }
  "children: " + ($kids -join ' | ')
}
function WDwm {
  $t=New-Object W7+DTI; $t.cbSize=[Runtime.InteropServices.Marshal]::SizeOf($t); $hr=[W7]::DwmGetCompositionTimingInfo([IntPtr]::Zero,[ref]$t)
  $e=$false; [W7]::DwmIsCompositionEnabled([ref]$e)|Out-Null
  "dwm: hr=0x{0:x} cb={5} enabled={1} rateRefresh={2}/{3} qpcRefreshPeriod={4} qpcVBlank={6} cRefresh={7}" -f $hr,$e,$t.rateRefreshN,$t.rateRefreshD,$t.qpcRefreshPeriod,$t.cbSize,$t.qpcVBlank,$t.cRefresh
}
function WKill { Get-Process YomiHub -EA SilentlyContinue | Stop-Process -Force -EA SilentlyContinue; Start-Sleep 2 }
