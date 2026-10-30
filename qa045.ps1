# qa045.ps1 - helpers for YomiHub 0.4.5 interactive QA (dot-source from a job)
$adb = "D:\yh\tools\android-sdk\platform-tools\adb.exe"
$sdk = "C:\Users\nguye\AppData\Local\Android\Sdk"
$QA  = "D:\A.I Project\A.I Project - YomiHub Project\YomiHub-Project\output\0.4.5\qa"
New-Item -ItemType Directory -Force $QA | Out-Null
$global:SER = if ($env:QA_SERIAL) { $env:QA_SERIAL } else { '' }
function A { if ($global:SER) { & $adb -s $global:SER @args 2>&1 } else { & $adb @args 2>&1 } }
function Snap($name) { Remove-Item "$QA\$name.png" -ErrorAction SilentlyContinue; A shell screencap -p /data/local/tmp/qa.png | Out-Null; A pull /data/local/tmp/qa.png "$QA\$name.png" | Out-Null; "snap $name $((Test-Path "$QA\$name.png"))" }
function Dump($name) { A shell uiautomator dump /data/local/tmp/ui.xml | Out-Null; A pull /data/local/tmp/ui.xml "$QA\$name.xml" | Out-Null; "dump $name" }
function Tap($x,$y) { A shell input tap $x $y | Out-Null; Start-Sleep -Milliseconds 900 }
function Key($k) { A shell input keyevent $k | Out-Null; Start-Sleep -Milliseconds 700 }
function Txt($t) { A shell input text ($t -replace ' ','%s') | Out-Null; Start-Sleep -Milliseconds 500 }
function Swipe($x1,$y1,$x2,$y2,$ms=300) { A shell input swipe $x1 $y1 $x2 $y2 $ms | Out-Null; Start-Sleep -Milliseconds 900 }
function RecStart($name,$limit=180) { Start-Process -FilePath $adb -ArgumentList (@($(if($global:SER){@('-s',$global:SER)}else{@()})) + @('shell','screenrecord','--bit-rate','4000000','--time-limit',"$limit","/data/local/tmp/$name.mp4")) -WindowStyle Hidden | Out-Null; "rec start $name" }
function RecPull($name) { A pull "/data/local/tmp/$name.mp4" "$QA\$name.mp4" | Out-Null; "rec pulled $name" }
function TapText($xmlName, $text) {
  [xml]$x = Get-Content "$QA\$xmlName.xml" -Encoding UTF8
  $n = $x.SelectNodes("//node") | Where-Object { $_.text -eq $text -or $_.'content-desc' -eq $text } | Select-Object -First 1
  if (-not $n) { "NOT FOUND: $text"; return }
  $m = [regex]::Matches($n.bounds, '\d+'); $cx = ([int]$m[0].Value + [int]$m[2].Value)/2; $cy = ([int]$m[1].Value + [int]$m[3].Value)/2
  Tap $cx $cy; "tap '$text' @ $cx,$cy"
}
function EmuStart($avd, $extra='') {
  $cmd = "`"$sdk\emulator\emulator.exe`" -avd $avd -memory 2048 -no-snapshot-save -no-boot-anim -no-audio -gpu swiftshader_indirect $extra"
  Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = $cmd } | Out-Null
  for ($i=0; $i -lt 150; $i++) { Start-Sleep 4; $b = (A shell getprop sys.boot_completed) -join ''; if ($b.Trim() -eq '1') { break } }
  "booted $avd after $($i*4)s"
}
$FF = (Get-ChildItem "D:\yh\tools" -Directory -Filter "ffmpeg-*" | Select-Object -First 1).FullName + "\bin\ffmpeg.exe"
function WinRecStart($name, $sec=600) {
  $cmd = "`"$FF`" -y -f gdigrab -framerate 12 -t $sec -i desktop -vf scale=1600:-2 -c:v libx264 -preset veryfast -crf 30 -pix_fmt yuv420p -movflags +frag_keyframe+empty_moov `"$QA\$name.mp4`""
  $si = New-CimInstance -ClassName Win32_ProcessStartup -ClientOnly -Property @{ ShowWindow = [uint16]0 }
  Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = $cmd; ProcessStartupInformation = $si } | Out-Null; "winrec $name"
}
function WinSnap($name) {
  Add-Type -AssemblyName System.Windows.Forms, System.Drawing
  $b = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds; $bmp = New-Object System.Drawing.Bitmap($b.Width, $b.Height)
  $g = [System.Drawing.Graphics]::FromImage($bmp); $g.CopyFromScreen($b.Location, [System.Drawing.Point]::Empty, $b.Size)
  $bmp.Save("$QA\$name.png", [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose(); "winsnap $name"
}

function WinRecStop() { Get-Process ffmpeg -ErrorAction SilentlyContinue | Stop-Process -Force; "winrec stopped" }

# 0.4.5: dump + find node whose text/desc contains $text (scroll down up to $n times), tap it
function FindTap($text, $n=6, $dx=0) {
  for ($i=0; $i -le $n; $i++) {
    A shell uiautomator dump /data/local/tmp/ui.xml | Out-Null; A pull /data/local/tmp/ui.xml "$QA\_ft.xml" | Out-Null
    [xml]$x = Get-Content "$QA\_ft.xml" -Encoding UTF8
    $nd = $x.SelectNodes("//node") | Where-Object { ($_.text -and $_.text.Contains($text)) -or ($_.'content-desc' -and $_.'content-desc'.Contains($text)) } | Select-Object -First 1
    if ($nd) { $m = [regex]::Matches($nd.bounds, '\d+'); $cx = ([int]$m[0].Value + [int]$m[2].Value)/2 + $dx; $cy = ([int]$m[1].Value + [int]$m[3].Value)/2; Tap $cx $cy; return "tap '$text' @ $cx,$cy" }
    Swipe 640 2000 640 900 400
  }
  "NOT FOUND: $text"
}
function Labels($name) { Dump $name | Out-Null; [xml]$x = Get-Content "$QA\$name.xml" -Encoding UTF8; ($x.SelectNodes("//node") | ForEach-Object { if ($_.text) { $_.text } elseif ($_.'content-desc') { $_.'content-desc' } }) -join ' ¦ ' }

# 0.4.5: safety guard – never send taps unless YomiHub is the focused app
function Fg { ((A shell dumpsys activity activities) | Select-String "topResumedActivity" | Select-Object -First 1).ToString() }
function EnsureApp {
  if ((Fg) -notmatch 'com\.yomihub\.app') {
    A shell monkey -p com.yomihub.app -c android.intent.category.LAUNCHER 1 | Out-Null; Start-Sleep 8
    if ((Fg) -notmatch 'com\.yomihub\.app') { throw "YomiHub not in foreground: $(Fg)" }
  }
}
function Tap($x,$y) { EnsureApp; A shell input tap $x $y | Out-Null; Start-Sleep -Milliseconds 900 }
function Key($k) { EnsureApp; A shell input keyevent $k | Out-Null; Start-Sleep -Milliseconds 700 }
function Swipe($x1,$y1,$x2,$y2,$ms=300) { EnsureApp; A shell input swipe $x1 $y1 $x2 $y2 $ms | Out-Null; Start-Sleep -Milliseconds 900 }
