$ErrorActionPreference='Continue'
$root = 'D:\A.I Project\A.I Project - YomiHub Project\YomiHub-Project'
if (-not (Test-Path $root)) { $root = Split-Path (Split-Path $PSScriptRoot) }
$ev = "$root\audit-0.5.7\evidence\windows\r21"
New-Item -ItemType Directory -Force $ev | Out-Null
Add-Type -AssemblyName System.Drawing,System.Windows.Forms
Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text;
public class P7 { [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h); [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h,int c);
[DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
[DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out RECT r);
[DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr dc, uint f);
[DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
[DllImport("user32.dll")] public static extern IntPtr FindWindowEx(IntPtr p, IntPtr a, string c, string t);
[DllImport("user32.dll")] public static extern int GetWindowLong(IntPtr h, int i);
[DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
[DllImport("user32.dll")] public static extern uint GetDpiForWindow(IntPtr h);
[DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr h,int x,int y,int w,int hh,bool r);
public struct RECT { public int L,T,R,B; } }
"@
[P7]::SetProcessDPIAware() | Out-Null
function Stat($bmp){ $w=0;$n=0;$set=@{}; for($y=40;$y -lt $bmp.Height;$y+=8){ for($x=4;$x -lt $bmp.Width;$x+=8){ $c=$bmp.GetPixel($x,$y).ToArgb(); $n++; if($c -eq -1){$w++}; $set[$c]=1 } }; "white=$([int](100*$w/[Math]::Max($n,1)))% colors=$($set.Count) size=$($bmp.Width)x$($bmp.Height)" }
function Snap($pname,$tag,[switch]$NoFg){
  $p=Get-Process $pname -EA SilentlyContinue | ? { $_.MainWindowHandle -ne 0 } | select -First 1; if(!$p){ "$tag : no process/window $pname"; return }
  $h=$p.MainWindowHandle
  if(-not $NoFg){ [P7]::ShowWindow($h,9)|Out-Null; [P7]::SetForegroundWindow($h)|Out-Null; Start-Sleep -Milliseconds 800 }
  $r=New-Object P7+RECT; [P7]::GetWindowRect($h,[ref]$r)|Out-Null; $w=$r.R-$r.L; $hh=$r.B-$r.T
  if($w -le 0 -or $hh -le 0){ "$tag : bad rect"; return }
  $b=New-Object Drawing.Bitmap $w,$hh; $g=[Drawing.Graphics]::FromImage($b); $g.CopyFromScreen($r.L,$r.T,0,0,$b.Size); $g.Dispose()
  $b.Save("$ev\$tag.png"); "$tag SCREEN rect $($r.L),$($r.T) ${w}x$hh responding=$($p.Responding): $(Stat $b)"; $b.Dispose()
  $b2=New-Object Drawing.Bitmap $w,$hh; $g2=[Drawing.Graphics]::FromImage($b2); $dc=$g2.GetHdc(); [P7]::PrintWindow($h,$dc,2)|Out-Null; $g2.ReleaseHdc($dc); $g2.Dispose()
  $b2.Save("$ev\${tag}_pw.png"); "$tag PRINTWINDOW: $(Stat $b2)"; $b2.Dispose()
  $v=[P7]::FindWindowEx($h,[IntPtr]::Zero,'FLUTTERVIEW',$null)
  if($v -ne [IntPtr]::Zero){ $cr=New-Object P7+RECT; [P7]::GetClientRect($v,[ref]$cr)|Out-Null; $pr=New-Object P7+RECT; [P7]::GetClientRect($h,[ref]$pr)|Out-Null
    "$tag view=$v visible=$([P7]::IsWindowVisible($v)) viewClient=$($cr.R)x$($cr.B) topClient=$($pr.R)x$($pr.B) style=0x$('{0:X}' -f [P7]::GetWindowLong($h,-16)) ex=0x$('{0:X}' -f [P7]::GetWindowLong($h,-20)) vstyle=0x$('{0:X}' -f [P7]::GetWindowLong($v,-16)) vex=0x$('{0:X}' -f [P7]::GetWindowLong($v,-20)) dpi=$([P7]::GetDpiForWindow($h))" } else { "$tag : no FLUTTERVIEW child" }
}
Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text; using System.Collections.Generic;
public class P7E { public struct RECT { public int L,T,R,B; } public delegate bool EnumProc(IntPtr h, IntPtr l);
[DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc p, IntPtr l);
[DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr h, EnumProc p, IntPtr l);
[DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassName(IntPtr h, StringBuilder s, int n);
[DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
[DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
[DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
[DllImport("user32.dll")] public static extern int GetWindowLong(IntPtr h, int i);
[DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
[DllImport("dwmapi.dll")] public static extern int DwmGetWindowAttribute(IntPtr h, int a, out int v, int sz);
public static List<string> List(bool children, IntPtr parent){ var o=new List<string>(); EnumProc cb=(h,l)=>{ if(!children && !IsWindowVisible(h)) return true; var c=new StringBuilder(256); GetClassName(h,c,256); var t=new StringBuilder(256); GetWindowText(h,t,256); uint pid; GetWindowThreadProcessId(h,out pid); RECT r; GetWindowRect(h,out r); int cl=0; DwmGetWindowAttribute(h,14,out cl,4);
 o.Add(String.Format("hwnd={0:X} pid={1} class={2} title=[{3}] rect={4},{5},{6},{7} style={8:X} ex={9:X} cloaked={10} vis={11}", h.ToInt64(), pid, c, t, r.L,r.T,r.R,r.B, GetWindowLong(h,-16), GetWindowLong(h,-20), cl, IsWindowVisible(h))); return true; };
 if(children) EnumChildWindows(parent,cb,IntPtr.Zero); else EnumWindows(cb,IntPtr.Zero); return o; } }
"@
function Mods($pname){ $p=Get-Process $pname -EA SilentlyContinue | select -First 1; if(!$p){ return }
  "modules($pname pid $($p.Id) threads=$($p.Threads.Count) cpu=$($p.TotalProcessorTime.TotalSeconds)): " + (($p.Modules | ? { $_.ModuleName -match 'd3d|dxgi|igd|igc|nv|warp|dcomp|EGL|GLES|vulkan|dwm|opengl|ig9|overlay|hook|rtss|gameoverlay|d2d' } | % { $_.ModuleName }) -join ', ')
  $p.Modules | ? { $_.FileName -notmatch '\\Windows\\|YomiHub\\|hello_win' } | % { "  foreign module: $($_.FileName)" } }
