# release_056_publish.ps1 - YomiHub 0.5.6 publish pipeline (runs only with -Execute; default = -DryRun).
# Usage: .\release_056_publish.ps1                       (dry run, prints the plan, changes nothing)
#        .\release_056_publish.ps1 -Execute -Qa2 "<text>" -ReleaseDate dd/MM/yyyy
param([switch]$DryRun, [switch]$Execute, [string]$Qa2 = '', [string]$ReleaseDate = '', [string]$Tag = 'v0.5.6', [string]$Repo = 'kiritokmn1403/YomiHub-Project')
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$out = Join-Path $root 'output\0.5.6'
$rel = Join-Path $root 'audit-0.5.6\release'
$dry = -not $Execute  # -DryRun is the default; -Execute wins only when given alone
if ($Execute -and $DryRun) { Write-Output "ERROR: use either -DryRun or -Execute"; exit 2 }
if (-not $ReleaseDate) { $ReleaseDate = (Get-Date).ToString('dd/MM/yyyy') }
$utf8 = New-Object System.Text.UTF8Encoding($false)
function Log($m) { Write-Output ("[{0}] {1}{2}" -f (Get-Date -Format HH:mm:ss), $(if ($dry) { '[DRY] ' } else { '' }), $m) }
function Die($m) { Write-Output "ERROR: $m"; exit 2 }
function Run-Git { param([string[]]$a) $ErrorActionPreference = 'Continue'; & git -C $root @a 2>&1 | ForEach-Object { "$_" } | Write-Output; if ($LASTEXITCODE -ne 0) { Die "git $($a -join ' ') exit $LASTEXITCODE" } }
function Fill($t) { $t.Replace('<<NG' + [char]0xC0 + 'Y PH' + [char]0xC1 + 'T H' + [char]0xC0 + 'NH>>', $ReleaseDate).Replace('<<QA2>>', $Qa2) }

# ---- explicit commit list (no git add -A) ----
$paths = @('overlay', 'README.md', 'TECHNICAL_UPDATE_NOTES.md', '.gitignore', 'make_appxbundle.ps1',
  'build_056.ps1', 'build_056_android.ps1', 'sync_056.ps1', 'release_056.ps1', 'release_056_fixed.ps1', 'release_056_publish.ps1',
  'audit-0.5.6/YomiHub-0.5.6-changelog.md', 'audit-0.5.6/changed_files.txt', 'audit-0.5.6/overlay_manifest_056.txt',
  'audit-0.5.6/release/README_release_section.md', 'audit-0.5.6/release/TECHNICAL_NOTES_0.5.6_section.md',
  'audit-0.5.6/release/YomiHub-0.5.6-changelog.md', 'audit-0.5.6/release/RELEASE_SCRIPT_REVIEW.md',
  'audit-0.5.6/notes', 'audit-0.5.6/coordination')

# ---- preflight ----
foreach ($p in @($out, "$rel\YomiHub-0.5.6-changelog.md", "$rel\TECHNICAL_NOTES_0.5.6_section.md", "$rel\README_release_section.md", "$root\README.md", "$root\TECHNICAL_UPDATE_NOTES.md", "$root\release_056_fixed.ps1")) {
  if (-not (Test-Path $p)) { Die "missing $p" }
}
$branch = (& git -C $root rev-parse --abbrev-ref HEAD).Trim(); if ($branch -ne 'main') { Die "branch is $branch, expected main" }
$remote = (& git -C $root remote get-url origin).Trim(); if ($remote -notmatch [regex]::Escape($Repo)) { Die "origin $remote != $Repo" }
if ((& git -C $root tag -l $Tag)) { Die "tag $Tag already exists locally" }
$mustHave = @('YomiHub-0.5.6-arm64-v8a.apk','YomiHub-0.5.6-armeabi-v7a.apk','YomiHub-0.5.6-x86_64.apk','YumiHub-Android-TV-0.5.6-arm64-v8a.apk','YumiHub-Android-TV-0.5.6-armeabi-v7a.apk','YumiHub-Android-TV-0.5.6-x86_64.apk','YomiHub-0.5.6-windows-x64.zip','YomiHub-0.5.6-windows-x64-full.zip','YomiHub-0.5.6-windows-x64-Setup.exe','YomiHub-0.5.6-windows-x64.appxbundle','YomiHub-RootCA.cer','Install-YomiHub.bat','Install-YomiHub.ps1')
foreach ($n in $mustHave) { if (-not (Test-Path (Join-Path $out $n))) { Die "output\0.5.6 lacks $n" } }
# secrets / oversize guard on files that will be committed
$bad = @()
foreach ($p in $paths) { $fp = Join-Path $root $p; if (Test-Path $fp) { $bad += Get-ChildItem $fp -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne 'mangayomi_mpv.zip' -and ($_.Length -gt 50MB -or $_.Name -match '\.(jks|keystore|p12|pfx|apk|zip|exe|appxbundle|mp4)$|keystore-password') } } }
if ($bad) { Die ("forbidden/oversize files in commit set: " + (($bad | ForEach-Object FullName) -join '; ')) }
$hits = @(Select-String -Path ((Get-ChildItem (Join-Path $root 'audit-0.5.6\notes'), (Join-Path $root 'audit-0.5.6\coordination'), $rel -Recurse -File | ForEach-Object FullName) + "$root\README.md", "$root\TECHNICAL_UPDATE_NOTES.md") -Pattern 'ghp_|github_pat_|bot[0-9]{8,}:|Piacom|dkkk081426' -List -ErrorAction SilentlyContinue)
if ($hits) { Die ("sensitive string in: " + (($hits | ForEach-Object Path) -join '; ')) }
Log 'Preflight OK (branch main, origin ok, 13 required assets present, no secrets/oversize in commit set)'

# ---- prepare texts in memory (placeholders) ----
$chg = Fill ([IO.File]::ReadAllText("$rel\YomiHub-0.5.6-changelog.md", [Text.Encoding]::UTF8))
$tn  = Fill ([IO.File]::ReadAllText("$rel\TECHNICAL_NOTES_0.5.6_section.md", [Text.Encoding]::UTF8))
$rd  = Fill ([IO.File]::ReadAllText("$rel\README_release_section.md", [Text.Encoding]::UTF8))
$warn = @()
foreach ($t in @(@('changelog', $chg), @('technical-notes', $tn), @('readme', $rd))) {
  if ($t[1].Contains('<<')) { $warn += "$($t[0]) still has <<placeholder>>" }
  if ($t[1].Contains('CH' + [char]0x1AF + 'A ph' + [char]0xE1 + 't h' + [char]0xE0 + 'nh')) { $warn += "$($t[0]) still says 'CHUA phat hanh' (edit the draft)" }
}
if ($Execute -and -not $Qa2) { $warn += '-Qa2 is empty' }
if ($warn) { if ($Execute) { Die ($warn -join ' | ') } else { $warn | ForEach-Object { Log "WARN $_" } } }

# split the technical section: body (drop draft comments) and the one-line summary
$mark = $tn.IndexOf('<!-- ===== ')
if ($mark -lt 0) { Die 'summary marker not found in TECHNICAL_NOTES section' }
$tnBody = ($tn.Substring(0, $mark) -replace '(?m)^<!-- B[^\r\n]*-->\r?\n', '').TrimEnd()
$summary = ($tn.Substring($mark) -split "\r?\n" | Where-Object { $_ -match '^- \*\*' } | Select-Object -First 1)
if (-not $summary) { Die 'summary line not found' }
$rdBody = ($rd -replace '(?m)^<!-- B[^\r\n]*-->\r?\n', '').Trim()

# ---- a. changelog ----
Log "a. write changelog -> output\0.5.6\YomiHub-0.5.6-changelog.md ($($chg.Length) chars)"
if ($Execute) { [IO.File]::WriteAllText("$out\YomiHub-0.5.6-changelog.md", $chg, $utf8) }

# ---- b. notes + README ----
Log 'b1. append technical section to end of TECHNICAL_UPDATE_NOTES.md'
Log 'b2. insert summary line at top of "## 1. Trang thai hien tai" list'
Log 'b3. README: replace block from "**Phien ban hien tai" up to "## Cau truc" with the 0.5.6 section'
if ($Execute) {
  $tf = "$root\TECHNICAL_UPDATE_NOTES.md"; $x = [IO.File]::ReadAllText($tf, [Text.Encoding]::UTF8)
  if ($x.Contains('0.5.6 (0.5.6+48)')) { Die 'TECHNICAL_UPDATE_NOTES.md already mentions 0.5.6 (rerun guard)' }
  $h1 = '## 1. Tr' + [char]0x1EA1 + 'ng th' + [char]0xE1 + 'i hi' + [char]0x1EC7 + 'n t' + [char]0x1EA1 + 'i'
  $m = [regex]::Match($x, '(?m)^' + [regex]::Escape($h1) + '[^\r\n]*\r?\n\r?\n')
  if (-not $m.Success) { Die 'heading "## 1." not found' }
  $x = $x.Insert($m.Index + $m.Length, $summary + "`n")
  $x = $x.TrimEnd() + "`n`n" + $tnBody + "`n"
  [IO.File]::WriteAllText($tf, $x, $utf8)
  $rf = "$root\README.md"; $r = [IO.File]::ReadAllText($rf, [Text.Encoding]::UTF8)
  $a = $r.IndexOf('**Phi' + [char]0xEA + 'n b' + [char]0x1EA3 + 'n hi' + [char]0x1EC7 + 'n t' + [char]0x1EA1 + 'i:')
  $b = $r.IndexOf('## C' + [char]0x1EA5 + 'u tr' + [char]0xFA + 'c')
  if ($a -lt 0 -or $b -le $a) { Die 'README anchors not found' }
  $r = $r.Substring(0, $a) + $rdBody + "`n`n" + $r.Substring($b)
  [IO.File]::WriteAllText($rf, $r, $utf8)
  Log 'b done'
}

# ---- c. SHA256SUMS ----
$sumFile = "$out\SHA256SUMS-0.5.6.txt"
$list = @(Get-ChildItem $out -File | Where-Object { $_.Name -ne 'SHA256SUMS-0.5.6.txt' } | Sort-Object Name -CaseSensitive)
Log ("c. regenerate SHA256SUMS-0.5.6.txt for {0} files (UTF-8 no BOM, LF)" -f $list.Count)
if ($Execute) {
  $sb = New-Object System.Text.StringBuilder
  foreach ($f in $list) { $hsh = (Get-FileHash $f.FullName -Algorithm SHA256).Hash.ToLower(); [void]$sb.Append("$hsh  $($f.Name)`n") }
  [IO.File]::WriteAllText($sumFile, $sb.ToString(), $utf8)
}

# ---- d. commit / tag / push ----
Log ('d. git add (explicit): ' + ($paths -join ', '))
Log 'd. git commit -m "release: YomiHub 0.5.6 (0.5.6+48)"; git tag -a v0.5.6; git push origin main; git push origin v0.5.6'
if ($Execute) {
  $env:GIT_TERMINAL_PROMPT = '0'; $env:GCM_INTERACTIVE = 'never'
  foreach ($p in $paths) { if (Test-Path (Join-Path $root $p)) { Run-Git @('add', '--', $p) } else { Log "skip missing $p" } }
  $staged = @(& git -C $root diff --cached --name-only)
  if (-not $staged) { Die 'nothing staged' }
  $badStaged = @($staged | Where-Object { $_ -match '^(output|src|jobs|fetch|logs)/|\.(apk|zip|exe|appxbundle|jks|mp4|png)$|keystore-password' })
  if ($badStaged) { Die ('forbidden staged: ' + ($badStaged -join '; ')) }
  Log ("staged {0} files" -f $staged.Count)
  Run-Git @('commit', '-m', 'release: YomiHub 0.5.6 (0.5.6+48)')
  Run-Git @('tag', '-a', $Tag, '-m', 'YomiHub 0.5.6 (0.5.6+48)')
  Run-Git @('push', 'origin', 'main')
  Run-Git @('push', 'origin', $Tag)
}

# ---- e. upload assets ----
Log 'e. run release_056_fixed.ps1 (create/update Release, upload, verify sizes)'
if ($Execute) {
  & powershell -NoProfile -ExecutionPolicy Bypass -File "$root\release_056_fixed.ps1" -tag $Tag -repo $Repo
  if ($LASTEXITCODE -ne 0) { Die "release_056_fixed.ps1 exit $LASTEXITCODE" }
}

# ---- f. final check against GitHub ----
Log 'f. list Release assets via API and compare name+size with output\0.5.6 (+TECHNICAL_UPDATE_NOTES.md)'
if ($Execute) {
  $env:GCM_INTERACTIVE = 'never'; $env:GIT_TERMINAL_PROMPT = '0'
  $tmp = [IO.Path]::GetTempFileName()
  try { [IO.File]::WriteAllText($tmp, "protocol=https`nhost=github.com`n`n"); $cred = cmd.exe /c "git credential fill < `"$tmp`" 2>NUL" } finally { Remove-Item $tmp -Force -ErrorAction SilentlyContinue }
  $tok = ($cred | Where-Object { $_ -like 'password=*' }) -replace '^password=', ''
  if (-not $tok) { Die 'No GitHub credential in Git Credential Manager' }
  $hd = @{ Authorization = "token $tok"; 'User-Agent' = 'YomiHub-release'; Accept = 'application/vnd.github+json' }
  $r = Invoke-RestMethod -Headers $hd "https://api.github.com/repos/$Repo/releases/tags/$Tag"
  $assets = @(Invoke-RestMethod -Headers $hd "https://api.github.com/repos/$Repo/releases/$($r.id)/assets?per_page=100" | ForEach-Object { $_ })
  $local = @(Get-ChildItem $out -File) + @(Get-Item "$root\TECHNICAL_UPDATE_NOTES.md")
  $problems = 0; $rows = @()
  foreach ($f in ($local | Sort-Object Name)) {
    $a = $assets | Where-Object { $_.name -eq $f.Name }
    $ok = $a -and $a.size -eq $f.Length -and $a.state -eq 'uploaded'
    if (-not $ok) { $problems++ }
    $rows += [pscustomobject]@{ Name = $f.Name; Local = $f.Length; Remote = $(if ($a) { $a.size } else { '-' }); Status = $(if ($ok) { 'OK' } else { 'MISMATCH' }) }
  }
  $rows | Format-Table -AutoSize | Out-String -Width 200 | Write-Output
  Log "release $($r.tag_name) draft=$($r.draft) assets=$($assets.Count) problems=$problems url=$($r.html_url)"
  if ($problems -gt 0) { Die "$problems asset problem(s)" }
}
Log $(if ($dry) { 'Dry run finished. Nothing was changed.' } else { 'Publish finished OK.' })
exit 0
