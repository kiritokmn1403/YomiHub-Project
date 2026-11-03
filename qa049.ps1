# qa049.ps1 - YomiHub 0.4.9 device QA helper (adb). Usage:
#   qa049.ps1 -dev <serial> -cmds "shot:01_name","tap:540,1200","text:Cài đặt","key:BACK","wait:2","type:abc","rec:on:clip1","rec:off","dump:name","swipe:x1,y1,x2,y2"
param([string]$dev = '281038ac31217ece', [string[]]$cmds)
$adb = "D:\yh\tools\android-sdk\platform-tools\adb.exe"
$qa = "D:\A.I Project\A.I Project - YomiHub Project\YomiHub-Project\audit-0.4.9\qa"
New-Item -ItemType Directory -Force $qa | Out-Null
function A { & $adb -s $dev @args 2>&1 }
function Dump($name) {
  A shell uiautomator dump /sdcard/yh_ui.xml | Out-Null
  A pull /sdcard/yh_ui.xml "$qa\$name.xml" | Out-Null
  return (Get-Content "$qa\$name.xml" -Raw -Encoding UTF8)
}
function Center($b) { if ($b -match '\[(\d+),(\d+)\]\[(\d+),(\d+)\]') { return @([int](([int]$Matches[1]+[int]$Matches[3])/2), [int](([int]$Matches[2]+[int]$Matches[4])/2)) } }
foreach ($c in $cmds) {
  $k, $v = $c -split ':', 2
  switch ($k) {
    'shot' { A shell screencap -p /sdcard/yh_s.png | Out-Null; A pull /sdcard/yh_s.png "$qa\$v.png" | Out-Null; "shot $v " + (Get-Item "$qa\$v.png").Length }
    'tap'  { $p = $v -split ','; A shell input tap $p[0] $p[1] | Out-Null; "tap $v" }
    'swipe' { $p = $v -split ','; A shell input swipe $p[0] $p[1] $p[2] $p[3] 400 | Out-Null; "swipe $v" }
    'key'  { A shell input keyevent $v | Out-Null; "key $v" }
    'type' { A shell input text ($v -replace ' ', '%s') | Out-Null; "type $v" }
    'wait' { Start-Sleep -Milliseconds ([double]$v * 1000); "wait $v" }
    'text' {
      $x = Dump 'last_ui'; $found = $false
      foreach ($m in [regex]::Matches($x, '<node [^>]*>')) {
        $n = $m.Value
        if ($n -match ('(text|content-desc)="[^"]*' + [regex]::Escape($v) + '[^"]*"') -and $n -match 'bounds="([^"]+)"') {
          $p = Center $Matches[1]; A shell input tap $p[0] $p[1] | Out-Null; "text '$v' -> tap $($p -join ',')"; $found = $true; break
        }
      }
      if (-not $found) { "text '$v' NOT FOUND" }
    }
    'dump' { $x = Dump $v; ([regex]::Matches($x, '(?:text|content-desc)="([^"]+)"[^>]*bounds="([^"]+)"') | % { "$($_.Groups[1].Value) @ $($_.Groups[2].Value)" }) -join "`n" }
    'rec'  {
      $s, $n = $v -split ':', 2
      if ($s -eq 'on') { Start-Process -FilePath $adb -ArgumentList "-s $dev shell screenrecord --bit-rate 6000000 --time-limit 180 /sdcard/yh_$n.mp4" -WindowStyle Hidden; Set-Content "$qa\_rec.txt" $n; "rec on $n" }
      else { $n = Get-Content "$qa\_rec.txt"; A shell pkill -INT screenrecord | Out-Null; Start-Sleep 3; A pull "/sdcard/yh_$n.mp4" "$qa\$n.mp4" | Out-Null; "rec off $n " + (Get-Item "$qa\$n.mp4" -ErrorAction SilentlyContinue).Length }
    }
    'sh'   { A shell $v }
    default { A @($c -split ' ') }
  }
}
