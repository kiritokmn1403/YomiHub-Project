# qa046.ps1 - helpers for YomiHub 0.4.6 interactive QA
$adb = "D:\yh\tools\android-sdk\platform-tools\adb.exe"
$sdk = "C:\Users\nguye\AppData\Local\Android\Sdk"
$QA  = "D:\A.I Project\A.I Project - YomiHub Project\YomiHub-Project\output\0.4.6\qa"
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
  $cmd = "`"$sdk\emulator\emulator.exe`" -avd $avd -memory 2048 -no-snapshot-save -no-boot-anim -no-audio -gpu host $extra"
  Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = $cmd } | Out-Null
  for ($i=0; $i -lt 150; $i++) { Start-Sleep 4; $b = (A shell getprop sys.boot_completed) -join ''; if ($b.Trim() -eq '1') { break } }
  "booted $avd after $($i*4)s"
}

