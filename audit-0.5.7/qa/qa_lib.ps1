# QA1 device walkthrough library (YomiHub 0.5.7). Dot-source from job: . "D:\Claude A.I\audit-0.5.7\qa\qa_lib.ps1"
$root='D:\Claude A.I'; . "$root\common.ps1"; $ErrorActionPreference='Continue'
$global:S = if ($env:QA_SERIAL) { $env:QA_SERIAL } else { '281038ac31217ece' }
$global:PKG='com.yomihub.app'
$global:QA="$root\audit-0.5.7"
$global:EV="$QA\evidence\phone\qa1"
$global:RUNLOG="$QA\qa\run_qa1.log"
$global:XML="$env:TEMP\qa1_ui.xml"
New-Item -ItemType Directory -Force $EV | Out-Null
function A { & adb -s $S @args 2>&1 }
function Log($m){ $l=("{0} {1}" -f (Get-Date -Format HH:mm:ss),$m); Write-Host $l; Add-Content -Path $RUNLOG -Value $l -Encoding UTF8 }
function Shot($n){ A shell screencap -p /sdcard/qa.png | Out-Null; A pull /sdcard/qa.png "$EV\$n.png" | Out-Null; Log "SHOT $n" }
function Tap($x,$y){ A shell input tap $x $y | Out-Null }
function Key($k){ A shell input keyevent $k | Out-Null }
function Back { Key 4 }
function Swipe($a,$b,$c,$d,$ms=300){ A shell input swipe $a $b $c $d $ms | Out-Null }
function Wake { A shell input keyevent 224 | Out-Null; A shell wm dismiss-keyguard | Out-Null }
function Launch { A shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 | Out-Null; Log "launch $PKG" }
function Stop { A shell am force-stop $PKG | Out-Null; Log "force-stop" }
function Size { (A shell wm size) -join ' ' }
function Nodes {
  for($i=0;$i -lt 3;$i++){
    A shell uiautomator dump /sdcard/qa.xml | Out-Null
    A pull /sdcard/qa.xml $XML | Out-Null
    try { $d=New-Object System.Xml.XmlDocument; $d.Load($XML)
      $out=@(); foreach($n in $d.SelectNodes('//node')){
        if($n.GetAttribute('bounds') -match '\[(\d+),(\d+)\]\[(\d+),(\d+)\]'){
          $out += [pscustomobject]@{ T=$n.GetAttribute('text'); D=$n.GetAttribute('content-desc'); C=($n.GetAttribute('clickable') -eq 'true'); X1=[int]$Matches[1];Y1=[int]$Matches[2];X2=[int]$Matches[3];Y2=[int]$Matches[4]; P=$n.GetAttribute('package') } } }
      if($out.Count -gt 0){ return $out } } catch {}
    Start-Sleep 1 }
  return @()
}
function Lbl($n){ (($n.T + ' ' + $n.D) -replace '\s+',' ').Trim() }
function Ui($name){ # dump compact listing to evidence\ui_<name>.txt
  $ns=Nodes; $lines=foreach($n in $ns){ $l=Lbl $n; if($l -or $n.C){ "{0} [{1},{2}][{3},{4}] {5}" -f $(if($n.C){'C'}else{'-'}),$n.X1,$n.Y1,$n.X2,$n.Y2,$l } }
  $lines | Set-Content -Path "$EV\ui_$name.txt" -Encoding UTF8; Log "UI $name ($($ns.Count) nodes)"; return $ns }
function Find($pat,$idx=0,$ns=$null){ if(-not $ns){$ns=Nodes}
  $m=@($ns | Where-Object { $_.X2 -gt $_.X1 -and $_.Y2 -gt $_.Y1 -and (Lbl $_) -match $pat }); if($m.Count -gt $idx){ return $m[$idx] } return $null }
function TapText($pat,$idx=0,$tries=4){ for($i=0;$i -lt $tries;$i++){ $n=Find $pat $idx; if($n){ $x=[int](($n.X1+$n.X2)/2); $y=[int](($n.Y1+$n.Y2)/2); Tap $x $y; Log "TAP '$pat' -> ($x,$y) [$(Lbl $n)]"; return $true }; Start-Sleep 2 }
  Log "TAP-FAIL '$pat' (not found)"; return $false }
function HasText($pat,$tries=3){ for($i=0;$i -lt $tries;$i++){ if(Find $pat){ return $true }; Start-Sleep 2 }; return $false }
function Result($flow,$res,$note){ Add-Content -Path "$QA\qa\results_qa1.txt" -Value ("{0}`t{1}`t{2}" -f $flow,$res,$note) -Encoding UTF8; Log "RESULT $flow $res $note" }
function Fg { (A shell dumpsys window | Select-String 'mCurrentFocus') -join ' ' }
function LogcatSave($name){ A logcat -d > "$EV\$name.txt" ; Log "logcat saved $name" }
function GoMore { Wake; Stop; Start-Sleep 1; Launch; Start-Sleep 9; A logcat -c | Out-Null; ToMore }
function ToMore { for($i=0;$i -lt 6;$i++){ if(Find 'Th.m Tab 5'){break}; if(-not (Fg) -or -not ((Fg) -match 'yomihub')){ Launch; Start-Sleep 8 } else { Back; Start-Sleep 2 } }; TapText 'Th.m Tab 5' | Out-Null; Start-Sleep 2; Swipe 720 2200 720 700 300; Start-Sleep 1 }
function MoreItem($pat,$shot){ if(TapText $pat){ Start-Sleep 4; Shot $shot; $null=Ui $shot; return $true } else { Log "MISSING $pat"; return $false } }
function GoHome { Wake; Stop; Start-Sleep 1; Launch; Start-Sleep 9; A logcat -c | Out-Null; for($i=0;$i -lt 6;$i++){ if(Find 'Th.m Tab 5'){break}; if(-not ((Fg) -match 'yomihub')){ Launch; Start-Sleep 8 } else { Back; Start-Sleep 2 } } }
