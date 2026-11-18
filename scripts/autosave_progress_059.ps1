# autosave_progress_059.ps1 - YomiHub 0.5.9: moi 3 phut commit + push tien do (yeu cau chu du an 18/11/2026 12:01)
# Dung: tao tep jobs\STOP_AUTOSAVE. Tu dung sau 8 gio. Khong dua secrets/, logs, evidence, input len.
$root = 'D:\A.I Project\A.I Project - YomiHub Project\YomiHub-Project'
Set-Location $root
$log = Join-Path $root 'logs\autosave_059.txt'
function L($m){ Add-Content $log ("{0:dd/MM HH:mm:ss} {1}" -f (Get-Date), $m) -Encoding UTF8 }
$paths = @('TECHNICAL_UPDATE_NOTES.md','README.md','AGENTS.md','A.I Brain - Second Brain','overlay','docs',
  'audit/audit-0.5.9/antigravity','audit/audit-0.5.9/notes','audit/audit-0.5.9/release','audit/audit-0.5.9/coordination',
  'build','run_059_main.ps1','sync_059.ps1','release_059.ps1',
  'make_installer_exe_059.ps1','make_appxbundle_059.ps1','scripts/autosave_progress_059.ps1')
$end = (Get-Date).AddHours(8)
L "=== autosave bat dau (PID $PID) ==="
while((Get-Date) -lt $end){
  if(Test-Path (Join-Path $root 'jobs\STOP_AUTOSAVE')){ L 'gap STOP_AUTOSAVE - dung'; break }
  try {
    if(Test-Path (Join-Path $root '.git\index.lock')){ L 'index.lock dang ton tai - bo qua luot nay' }
    else {
      $ex = $paths | Where-Object { Test-Path (Join-Path $root $_) }
      & git add -A -- $ex 2>&1 | Out-Null
      & git reset -q -- 'audit/audit-0.5.6/coordination/BUILD_LOCK.txt' 'secrets' 2>&1 | Out-Null
      $staged = & git diff --cached --name-only
      if($staged){
        $n = @($staged).Count
        & git commit -q -m ("wip(0.5.9): tu luu tien do {0:dd/MM HH:mm} ({1} tep)" -f (Get-Date), $n) 2>&1 | Out-Null
        $p = & git push -q origin HEAD 2>&1
        if($LASTEXITCODE -ne 0){ & git pull -q --rebase origin main 2>&1 | Out-Null; $p = & git push -q origin HEAD 2>&1 }
        L ("commit {0} tep, push exit {1} {2}" -f $n, $LASTEXITCODE, "$p")
      } else { L 'khong co thay doi' }
    }
  } catch { L "LOI: $_" }
  Start-Sleep 180
}
L '=== autosave ket thuc ==='
