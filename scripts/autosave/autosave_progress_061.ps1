# autosave_progress_061.ps1 - YomiHub 0.6.1: moi 5 phut commit + push tien do (yeu cau chu du an 19/11/2026 17:18; dung khi xong viec)
# Dung: tao tep jobs\STOP_AUTOSAVE_061. Tu dung sau 24 gio. Khong dua secrets/, logs, evidence, input len.
$root = 'D:\A.I Project\A.I Project - YomiHub Project\YomiHub-Project'
Set-Location $root
$env:Path = 'C:\Program Files\Git\cmd;' + $env:Path
$log = Join-Path $root 'logs\autosave_061.txt'
function L($m){ Add-Content $log ("{0:dd/MM HH:mm:ss} {1}" -f (Get-Date), $m) -Encoding UTF8 }
$paths = @('TECHNICAL_UPDATE_NOTES.md','README.md','AGENTS.md','BUILDING.md','.gitignore','A.I Brain - Second Brain','overlay','docs',
  'scripts','jobs/q061_lib.ps1','jobs/q061_dev.ps1')
$end = (Get-Date).AddHours(24)
L "=== autosave bat dau (PID $PID) ==="
while((Get-Date) -lt $end){
  if(Test-Path (Join-Path $root 'jobs\STOP_AUTOSAVE_061')){ L 'gap STOP_AUTOSAVE - dung'; break }
  try {
    if(Test-Path (Join-Path $root '.git\index.lock')){ L 'index.lock dang ton tai - bo qua luot nay' }
    else {
      $ex = $paths | Where-Object { Test-Path (Join-Path $root $_) }
      & git add -A -- $ex 2>&1 | Out-Null
      & git reset -q -- 'audit/audit-0.5.6/coordination/BUILD_LOCK.txt' 'secrets' 2>&1 | Out-Null
      $staged = & git diff --cached --name-only
      if($staged){
        $n = @($staged).Count
        & git commit -q -m ("wip(0.6.1): tu luu tien do {0:dd/MM HH:mm} ({1} tep)" -f (Get-Date), $n) 2>&1 | Out-Null
        $p = & git push -q origin HEAD 2>&1
        if($LASTEXITCODE -ne 0){ & git pull -q --rebase origin main 2>&1 | Out-Null; $p = & git push -q origin HEAD 2>&1 }
        L ("commit {0} tep, push exit {1} {2}" -f $n, $LASTEXITCODE, "$p")
      } else { L 'khong co thay doi' }
    }
  } catch { L "LOI: $_" }
  Start-Sleep 300
}
L '=== autosave ket thuc ==='
