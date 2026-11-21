# autosave_progress_064b.ps1 - YomiHub 0.6.4 (21/11/2026 19:45, yeu cau chu du an: luu phien lam viec 5 phut/lan cho ca Claude, Google Antigravity, ChatGPT Codex)
# Moi 5 phut:
#  1) Claude: commit + push co chon loc (TECHNICAL_UPDATE_NOTES, Second Brain, overlay, docs, scripts...) nhu autosave_progress_064.ps1
#  2) Antigravity + Codex + PROGRESS: chup cac tep NOTES/REVIEW/BRIEF/bao cao (*.md, *.csv, *.json nho) trong audit/audit-0.6.4/{antigravity,codex,coordination}
#     vao audit/audit-0.6.4/backup/autosave/<yyyyMMdd_HHmm>/ (chi khi co thay doi; audit/ khong len GitHub theo quy dinh 19/11)
#  3) Kiritokmn Extension Repo (noi Antigravity sua tien ich): luu git diff chua commit thanh .patch + danh sach commit cuc bo (KHONG push)
# Dung: tao tep jobs\STOP_AUTOSAVE_064b. Tu dung sau 24 gio.
$root = 'D:\A.I Project\A.I Project - YomiHub Project\YomiHub-Project'
$ext  = 'D:\A.I Project\A.I Project - Extension Repo\Kiritokmn - Extension Repo'
Set-Location $root
$env:Path = 'C:\Program Files\Git\cmd;' + $env:Path
$log = Join-Path $root 'logs\autosave_064.txt'
function L($m){ Add-Content $log ("{0:dd/MM HH:mm:ss} [b] {1}" -f (Get-Date), $m) -Encoding UTF8 }
$paths = @('TECHNICAL_UPDATE_NOTES.md','README.md','AGENTS.md','BUILDING.md','.gitignore','A.I Brain - Second Brain','overlay','docs','scripts')
$agentDirs = @('audit\audit-0.6.4\antigravity','audit\audit-0.6.4\codex','audit\audit-0.6.4\coordination')
$snapRoot = Join-Path $root 'audit\audit-0.6.4\backup\autosave'
New-Item -ItemType Directory -Force $snapRoot | Out-Null
$lastSig = ''
$lastPatch = ''
$end = (Get-Date).AddHours(24)
L "=== autosave 064b bat dau (PID $PID) ==="
while((Get-Date) -lt $end){
  if(Test-Path (Join-Path $root 'jobs\STOP_AUTOSAVE_064b')){ L 'gap STOP_AUTOSAVE_064b - dung'; break }
  $stamp = Get-Date -Format 'yyyyMMdd_HHmm'
  # 1) Claude - commit + push
  try {
    if(Test-Path (Join-Path $root '.git\index.lock')){ L 'index.lock dang ton tai - bo qua luot commit' }
    else {
      $ex = $paths | Where-Object { Test-Path (Join-Path $root $_) }
      & git add -A -- $ex 2>&1 | Out-Null
      & git reset -q -- 'audit/audit-0.5.6/coordination/BUILD_LOCK.txt' 'secrets' 2>&1 | Out-Null
      $staged = & git diff --cached --name-only
      if($staged){
        $n = @($staged).Count
        & git commit -q -m ("wip(0.6.4): tu luu tien do {0:dd/MM HH:mm} ({1} tep)" -f (Get-Date), $n) 2>&1 | Out-Null
        $p = & git push -q origin HEAD 2>&1
        if($LASTEXITCODE -ne 0){ & git pull -q --rebase origin main 2>&1 | Out-Null; $p = & git push -q origin HEAD 2>&1 }
        L ("claude: commit {0} tep, push exit {1} {2}" -f $n, $LASTEXITCODE, "$p")
      } else { L 'claude: khong co thay doi' }
    }
  } catch { L "LOI commit: $_" }
  # 2) Antigravity / Codex / PROGRESS - chup tep ghi chu
  try {
    $files = @()
    foreach($d in $agentDirs){
      $full = Join-Path $root $d
      if(Test-Path $full){
        $files += Get-ChildItem $full -File -Recurse -Include *.md,*.csv,*.json,*.txt -ErrorAction SilentlyContinue | Where-Object { $_.Length -lt 5MB }
      }
    }
    $sig = ($files | Sort-Object FullName | ForEach-Object { "$($_.FullName)|$($_.Length)|$($_.LastWriteTimeUtc.Ticks)" }) -join ';'
    if($sig -ne $lastSig -and $files.Count -gt 0){
      $dst = Join-Path $snapRoot $stamp
      foreach($f in $files){
        $rel = $f.FullName.Substring($root.Length + 1)
        $to = Join-Path $dst $rel
        New-Item -ItemType Directory -Force (Split-Path $to) | Out-Null
        Copy-Item $f.FullName $to -Force
      }
      $lastSig = $sig
      L ("tac nhan: chup {0} tep -> backup\autosave\{1}" -f $files.Count, $stamp)
    } else { L 'tac nhan: ghi chu khong doi' }
  } catch { L "LOI chup ghi chu: $_" }
  # 3) Extension Repo - patch chua commit + commit cuc bo
  try {
    if(Test-Path (Join-Path $ext '.git')){
      Push-Location $ext
      $patch = (& git diff HEAD 2>$null) -join "`n"
      $head = (& git log --oneline -1 2>$null)
      $sigp = "$head|$($patch.Length)|$($patch.GetHashCode())"
      if($sigp -ne $lastPatch){
        $dst = Join-Path $snapRoot $stamp
        New-Item -ItemType Directory -Force $dst | Out-Null
        if($patch.Length -gt 0){ [IO.File]::WriteAllText((Join-Path $dst 'extension_repo_uncommitted.patch'), $patch, (New-Object Text.UTF8Encoding $false)) }
        (& git log --oneline -15 2>$null) | Set-Content (Join-Path $dst 'extension_repo_log.txt') -Encoding UTF8
        $lastPatch = $sigp
        L ("extrepo: HEAD {0}, patch {1} ky tu" -f $head, $patch.Length)
      } else { L 'extrepo: khong doi' }
      Pop-Location
    }
  } catch { L "LOI extrepo: $_"; try { Pop-Location } catch {} }
  Start-Sleep 300
}
L '=== autosave 064b ket thuc ==='
