# YomiHub A6: hàm kiểm thử UI trên AVD API 23 (dùng chung cho job a6_5x)
. 'D:\A.I Project\A.I Project - YomiHub Project\YomiHub-Project\audit-0.5.7\android6\a6_lib.ps1'
[Console]::OutputEncoding = [Text.Encoding]::UTF8; $OutputEncoding = [Text.Encoding]::UTF8
$AL="$root\audit-0.5.6\coordination\AVD_LOCK.txt"
function AvdTake {
  # chi tra ve $true/$false (thong bao qua Write-Host de khong lam hong gia tri tra ve)
 $c="$(Get-Content $AL -Raw -ErrorAction SilentlyContinue)".Trim([char]0xFEFF,' ',"`r","`n"); if($c -and $c -notmatch '^A6'){ Write-Host "AVD_LOCK bi giu: $c"; return $false }; if(-not $c){ Set-Content $AL ("A6 " + (Get-Date -Format HH:mm)) -Encoding utf8 }; return $true }
function AvdFree { EmuKill; $c="$(Get-Content $AL -Raw -ErrorAction SilentlyContinue)".Trim([char]0xFEFF,' ',"`r","`n"); if($c -match '^A6'){ Set-Content $AL '' -NoNewline }; "avd lock tra" }
function Nodes {
  A shell uiautomator dump /sdcard/q.xml 2>&1 | Out-Null
  $x = (A shell cat /sdcard/q.xml) -join ''
  $r=@(); foreach($m in [regex]::Matches($x,'<node [^>]*?(?:text="([^"]*)")[^>]*?content-desc="([^"]*)"[^>]*?bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"')){
    $t=($m.Groups[1].Value + ' ' + $m.Groups[2].Value).Trim()
    $r += [pscustomobject]@{t=$t; x=[int](([int]$m.Groups[3].Value+[int]$m.Groups[5].Value)/2); y=[int](([int]$m.Groups[4].Value+[int]$m.Groups[6].Value)/2)} }
  return $r
}
function Texts { (Nodes | Where-Object { $_.t } | ForEach-Object { "$($_.t -replace '\s+',' ')@$($_.x),$($_.y)" }) -join ' | ' }
function TapT([string]$pat,[int]$wait=3){ $n = Nodes | Where-Object { $_.t -match $pat } | Select-Object -First 1; if($n){ A shell input tap $n.x $n.y; Start-Sleep $wait; "tap '$pat' @$($n.x),$($n.y)"; return $true } else { "KHONG THAY '$pat'"; return $false } }
function Tap($x,$y,[int]$wait=3){ A shell input tap $x $y; Start-Sleep $wait }
function Back([int]$wait=2){ A shell input keyevent 4; Start-Sleep $wait }
function Errs($tag){ A logcat -d -v time | Out-File "$EV\${tag}_logcat.txt" -Encoding utf8; Select-String -Path "$EV\${tag}_logcat.txt" -Pattern 'FATAL|E/AndroidRuntime|UnsatisfiedLink|NoSuchMethodError|NoClassDefFound|VerifyError|dlopen failed|cannot locate symbol|E/flutter|MDBX|signal 11|SIGSEGV|SIGABRT' | Select-Object -First 25 | ForEach-Object { if($_.Line.Length -gt 300){ $_.Line.Substring(0,300) } else { $_.Line } } }
