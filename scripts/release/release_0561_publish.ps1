# release_0561_publish.ps1 - YomiHub 0.5.6.1 (0.5.6+49) publish pipeline. MAC DINH = -DryRun (in ke hoach, khong doi gi).
# Chi chay that voi -Execute, va chi SAU "MOC DUYET 0.5.6.1" trong audit-0.5.6\coordination\REVIEW_CLAUDE.md.
# Khong force-push, khong sua/xoa tag cu (v0.5.6), khong tao lai tag da co.
# Usage: .\release_0561_publish.ps1                                   (dry run)
#        .\release_0561_publish.ps1 -Execute -ReleaseDate dd/MM/yyyy [-VpnResult "<text>"] [-Android6Result "<text>"]
param([switch]$DryRun, [switch]$Execute, [string]$ReleaseDate = '', [string]$VpnResult = '', [string]$Android6Result = '', [switch]$AllowExtra, [string]$Tag = 'v0.5.6.1', [string]$Repo = 'kiritokmn1403/YomiHub-Project')
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$ver = '0.5.6.1'
$out = Join-Path $root 'output\0.5.6.1'
$rel = Join-Path $root 'audit-0.5.7\release'
$dry = -not $Execute  # -DryRun la mac dinh; -Execute chi chay that khi duoc truyen mot minh
if ($Execute -and $DryRun) { Write-Output "ERROR: use either -DryRun or -Execute"; exit 2 }
if (-not $ReleaseDate) { $ReleaseDate = (Get-Date).ToString('dd/MM/yyyy') }
$utf8 = New-Object System.Text.UTF8Encoding($false)
function Log($m) { Write-Output ("[{0}] {1}{2}" -f (Get-Date -Format HH:mm:ss), $(if ($dry) { '[DRY] ' } else { '' }), $m) }
function Die($m) { Write-Output "ERROR: $m"; exit 2 }
function Run-Git { param([string[]]$a) $ErrorActionPreference = 'Continue'; & git -C $root @a 2>&1 | ForEach-Object { "$_" } | Write-Output; if ($LASTEXITCODE -ne 0) { Die "git $($a -join ' ') exit $LASTEXITCODE" } }
$P_DATE = '<<NGÀY PHÁT HÀNH>>'; $P_VPN = '<<KẾT QUẢ VPN>>'; $P_A6 = '<<KẾT QUẢ ANDROID6>>'
function Fill($t) {
  $t = $t.Replace($P_DATE, $ReleaseDate)
  if ($VpnResult) { $t = $t.Replace($P_VPN, $VpnResult) }
  if ($Android6Result) { $t = $t.Replace($P_A6, $Android6Result) }
  return $t
}

# ---- danh sach git add tuong minh (khong git add -A); thu muc nang cua audit-0.5.7 bi .gitignore loai ----
$paths = @('overlay', 'README.md', 'TECHNICAL_UPDATE_NOTES.md', '.gitignore',
  'build_0561.ps1', 'build_0561_android.ps1', 'build_0561_android6.ps1', 'sync_0561.ps1',
  'make_appxbundle_0561.ps1', 'make_installer_exe_0561.ps1', 'release_0561_publish.ps1', 'release_0561_fixed.ps1',
  'audit-0.5.7', 'audit-0.5.6/coordination')
# audit-0.5.7: giu *.md, *.py, *.ps1, build23_patch/, ma nguon nho; loai apk/evidence/work/out/orig_libisar/patched_*/jnilibs23 (xem .gitignore)
$heavy = '^audit-0\.5\.7/(vpn/(apk|evidence)|android6/(evidence|work|out|orig_libisar|patched_[^/]+|jnilibs23|tmp))/'

# ---- preflight ----
foreach ($p in @($out, "$rel\YomiHub-0.5.6.1-changelog.md", "$rel\TECHNICAL_NOTES_0.5.6.1_section.md", "$rel\README_release_section_0561.md", "$root\README.md", "$root\TECHNICAL_UPDATE_NOTES.md", "$root\release_0561_fixed.ps1")) {
  if (-not (Test-Path $p)) { Die "missing $p" }
}
$branch = (& git -C $root rev-parse --abbrev-ref HEAD).Trim(); if ($branch -ne 'main') { Die "branch is $branch, expected main" }
$remote = (& git -C $root remote get-url origin).Trim(); if ($remote -notmatch [regex]::Escape($Repo)) { Die "origin $remote != $Repo" }
if ((& git -C $root tag -l $Tag)) { Die "tag $Tag already exists locally (khong tao lai / khong sua tag)" }
$oldTagSha = (& git -C $root rev-parse 'v0.5.6^{commit}' 2>$null); if (-not $oldTagSha) { Die 'tag v0.5.6 khong ton tai trong repo cuc bo (khong duoc phep tiep tuc)' }
& git -C $root merge-base --is-ancestor 'v0.5.6' HEAD; if ($LASTEXITCODE -ne 0) { Die 'HEAD khong chua v0.5.6 (nhanh main bi lech?)' }
$lsr = $null
try { $env:GIT_TERMINAL_PROMPT = '0'; $env:GCM_INTERACTIVE = 'never'; $lsr = & git -C $root ls-remote --tags origin "refs/tags/$Tag" 2>$null } catch { }
if ($lsr) { Die "tag $Tag already exists on origin" } elseif ($dry) { Log "ls-remote: tag $Tag chua co tren origin (neu mang cho phep kiem tra)" }
$ps = Get-Content "$root\overlay\pubspec.yaml" -Raw
if ($ps -notmatch '(?m)^version:\s*0\.5\.6\+49\s*$') { Die 'overlay/pubspec.yaml khong phai version: 0.5.6+49' }
if ((Get-Content "$root\overlay\lib\yomihub\app_identity.dart" -Raw) -notmatch "userAgent = 'YomiHub/0\.5\.6\.1'") { Die "app_identity.dart userAgent khong phai YomiHub/0.5.6.1" }
$mustHave = @(
  "YomiHub-$ver-arm64-v8a.apk", "YomiHub-$ver-armeabi-v7a.apk", "YomiHub-$ver-x86_64.apk",
  "YumiHub-Android-TV-$ver-arm64-v8a.apk", "YumiHub-Android-TV-$ver-armeabi-v7a.apk", "YumiHub-Android-TV-$ver-x86_64.apk",
  "YomiHub-$ver-android6-arm64-v8a.apk", "YomiHub-$ver-android6-armeabi-v7a.apk", "YomiHub-$ver-android6-x86_64.apk",
  "YomiHub-$ver-windows-x64.zip", "YomiHub-$ver-windows-x64-full.zip", "YomiHub-$ver-windows-x64-Setup.exe", "YomiHub-$ver-windows-x64.appxbundle",
  'YomiHub-RootCA.cer', 'Install-YomiHub.bat', 'Install-YomiHub.ps1')
foreach ($n in $mustHave) {
  $fp = Join-Path $out $n
  if (-not (Test-Path $fp)) { Die "output\0.5.6.1 lacks $n" }
  if ((Get-Item $fp).Length -le 0) { Die "output\0.5.6.1\$n co kich thuoc 0" }
}
$allowed = $mustHave + @("YomiHub-$ver-changelog.md", "SHA256SUMS-$ver.txt")
$extra = @(Get-ChildItem $out -File | Where-Object { $allowed -notcontains $_.Name } | ForEach-Object Name)
if ($extra) { if ($Execute -and -not $AllowExtra) { Die ("tep la trong output\0.5.6.1 (them -AllowExtra neu muon tai len): " + ($extra -join ', ')) } else { Log ('WARN tep la se duoc tai len: ' + ($extra -join ', ')) } }
# tep se commit = tep da theo doi + tep moi khong bi .gitignore (khong quet thu muc bi loai)
$cand = @(& git -C $root ls-files -c -o --exclude-standard -- @($paths | Where-Object { Test-Path (Join-Path $root $_) }))
$bad = @($cand | Where-Object { $f = Join-Path $root $_; (Test-Path $f -PathType Leaf) -and ((Split-Path $f -Leaf) -ne 'mangayomi_mpv.zip') -and (((Get-Item $f).Length -gt 50MB) -or ($_ -match '\.(jks|keystore|p12|pfx|apk|zip|exe|appxbundle|mp4)$|keystore-password') -or (($_ -match $heavy) -and ($_ -notmatch '/jnilibs23/MANIFEST\.txt$'))) })
if ($bad) { Die ("forbidden/oversize files in commit set: " + ($bad -join '; ')) }
$scan = @($cand | Where-Object { $_ -match '^(audit-0\.5\.7|audit-0\.5\.6/coordination)/.*\.(md|txt|ps1|py|kt|gradle)$|^(README\.md|TECHNICAL_UPDATE_NOTES\.md|release_0561_.*\.ps1|build_0561.*\.ps1|sync_0561\.ps1)$' } | ForEach-Object { Join-Path $root $_ })
$hits = @(Select-String -Path $scan -Pattern 'ghp_|github_pat_|bot[0-9]{8,}:|Piacom|dkkk081426' -List -ErrorAction SilentlyContinue | Where-Object { $_.Path -notmatch 'release_0561_publish\.ps1$' })
if ($hits) { Die ("sensitive string in: " + (($hits | ForEach-Object Path) -join '; ')) }
Log ("Preflight OK (branch main, origin ok, v0.5.6 = {0}, {1} required assets present, {2} files in commit set, no secrets/oversize)" -f $oldTagSha.Substring(0, 8), $mustHave.Count, $cand.Count)

# ---- chuan bi van ban trong bo nho (cho trong) ----
$chg = Fill ([IO.File]::ReadAllText("$rel\YomiHub-0.5.6.1-changelog.md", [Text.Encoding]::UTF8))
$tn  = Fill ([IO.File]::ReadAllText("$rel\TECHNICAL_NOTES_0.5.6.1_section.md", [Text.Encoding]::UTF8))
$rd  = Fill ([IO.File]::ReadAllText("$rel\README_release_section_0561.md", [Text.Encoding]::UTF8))
$warn = @()
foreach ($t in @(@('changelog', $chg), @('technical-notes', $tn), @('readme', $rd))) {
  if ($t[1].Contains('<<')) { $warn += "$($t[0]) still has <<placeholder>> (dien <<KET QUA VPN>> / <<KET QUA ANDROID6>> / <<NGAY PHAT HANH>>)" }
}
if ($warn) { if ($Execute) { Die ($warn -join ' | ') } else { $warn | ForEach-Object { Log "WARN $_" } } }

# tach phan ky thuat: than (bo dong nhap) va dong tom tat
$mark = $tn.IndexOf('<!-- ===== ')
if ($mark -lt 0) { Die 'summary marker not found in TECHNICAL_NOTES section' }
$tnBody = ($tn.Substring(0, $mark) -replace '(?m)^<!-- B[^\r\n]*-->\r?\n', '').TrimEnd()
$summary = ($tn.Substring($mark) -split "\r?\n" | Where-Object { $_ -match '^- \*\*' } | Select-Object -First 1)
if (-not $summary) { Die 'summary line not found' }
$rdBody = ($rd -replace '(?m)^<!-- B[^\r\n]*-->\r?\n', '').Trim()

# ---- a. changelog ----
Log "a. write changelog -> output\0.5.6.1\YomiHub-0.5.6.1-changelog.md ($($chg.Length) chars)"
if ($Execute) { [IO.File]::WriteAllText("$out\YomiHub-0.5.6.1-changelog.md", $chg, $utf8) }

# ---- b. notes + README ----
Log 'b1. append 0.5.6.1 technical section to end of TECHNICAL_UPDATE_NOTES.md'
Log 'b2. insert summary line at top of "## 1." list'
Log 'b3. README: insert the 0.5.6.1 section (download links v0.5.6.1 + Android 6.0 note) above the 0.5.6 block; old block kept as "Phien ban truoc"'
if ($Execute) {
  $tf = "$root\TECHNICAL_UPDATE_NOTES.md"; $x = [IO.File]::ReadAllText($tf, [Text.Encoding]::UTF8)
  if ($x.Contains('0.5.6.1 (0.5.6+49)')) { Die 'TECHNICAL_UPDATE_NOTES.md already has the 0.5.6.1 (0.5.6+49) section (rerun guard)' }
  $m = [regex]::Match($x, '(?m)^## 1\.[^\r\n]*\r?\n\r?\n')
  if (-not $m.Success) { Die 'heading "## 1." not found' }
  $x = $x.Insert($m.Index + $m.Length, $summary + "`n")
  $x = $x.TrimEnd() + "`n`n" + $tnBody + "`n"
  [IO.File]::WriteAllText($tf, $x, $utf8)
  $rf = "$root\README.md"; $r = [IO.File]::ReadAllText($rf, [Text.Encoding]::UTF8)
  if ($r.Contains('Releases v0.5.6.1')) { Die 'README.md already has the 0.5.6.1 section (rerun guard)' }
  $anchor = '**Phiên bản hiện tại: 0.5.6**'
  $a = $r.IndexOf($anchor)
  if ($a -lt 0) { Die 'README anchor "**Phiên bản hiện tại: 0.5.6**" not found' }
  $r = $r.Substring(0, $a) + $rdBody + "`n`n---`n`n" + '**Phiên bản trước: 0.5.6**' + $r.Substring($a + $anchor.Length)
  [IO.File]::WriteAllText($rf, $r, $utf8)
  Log 'b done'
}

# ---- c. SHA256SUMS ----
$sumFile = "$out\SHA256SUMS-$ver.txt"
$list = @(Get-ChildItem $out -File | Where-Object { $_.Name -ne "SHA256SUMS-$ver.txt" } | Sort-Object Name -CaseSensitive)
Log ("c. regenerate SHA256SUMS-$ver.txt for {0} files (UTF-8 no BOM, LF)" -f $list.Count)
if ($Execute) {
  $sb = New-Object System.Text.StringBuilder
  foreach ($f in $list) { $hsh = (Get-FileHash $f.FullName -Algorithm SHA256).Hash.ToLower(); [void]$sb.Append("$hsh  $($f.Name)`n") }
  [IO.File]::WriteAllText($sumFile, $sb.ToString(), $utf8)
}

# ---- d. commit / tag / push (khong force) ----
Log ('d. git add (explicit): ' + ($paths -join ', '))
Log 'd. git commit -m "release: YomiHub 0.5.6.1 (0.5.6+49)"; git tag -a v0.5.6.1; git push origin main; git push origin v0.5.6.1  (khong --force)'
if ($Execute) {
  $env:GIT_TERMINAL_PROMPT = '0'; $env:GCM_INTERACTIVE = 'never'
  foreach ($p in $paths) { if (Test-Path (Join-Path $root $p)) { Run-Git @('add', '--', $p) } else { Log "skip missing $p" } }
  $staged = @(& git -C $root diff --cached --name-only)
  if (-not $staged) { Die 'nothing staged' }
  $badStaged = @($staged | Where-Object { $_ -match '^(output|src|jobs|fetch|logs)/|\.(apk|zip|exe|appxbundle|jks|mp4|png)$|keystore-password' -or (($_ -match $heavy) -and ($_ -notmatch '/jnilibs23/MANIFEST\.txt$')) })
  if ($badStaged) { Die ('forbidden staged: ' + ($badStaged -join '; ')) }
  Log ("staged {0} files" -f $staged.Count)
  Run-Git @('commit', '-m', 'release: YomiHub 0.5.6.1 (0.5.6+49)', '-m', "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`nClaude-Session: https://claude.ai/code/session_01PnzRAu9eEMtb2yrCdK6awk")
  Run-Git @('tag', '-a', $Tag, '-m', 'YomiHub 0.5.6.1 (0.5.6+49)')
  Run-Git @('push', 'origin', 'main')
  Run-Git @('push', 'origin', $Tag)
  $oldAfter = (& git -C $root rev-parse 'v0.5.6^{commit}')
  if ($oldAfter -ne $oldTagSha) { Die "tag v0.5.6 da thay doi ($oldTagSha -> $oldAfter)" }
}

# ---- e. upload assets ----
Log 'e. run release_0561_fixed.ps1 (create/update Release "YomiHub 0.5.6.1", upload, verify sizes)'
if ($Execute) {
  & powershell -NoProfile -ExecutionPolicy Bypass -File "$root\release_0561_fixed.ps1" -tag $Tag -repo $Repo
  if ($LASTEXITCODE -ne 0) { Die "release_0561_fixed.ps1 exit $LASTEXITCODE" }
}

# ---- f. kiem lai tren GitHub ----
Log 'f. list Release assets via API and compare name+size with output\0.5.6.1 (+TECHNICAL_UPDATE_NOTES.md)'
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
  Log "release $($r.tag_name) name='$($r.name)' draft=$($r.draft) assets=$($assets.Count) problems=$problems url=$($r.html_url)"
  if ($r.name -ne 'YomiHub 0.5.6.1') { $problems++; Log "Release name sai: $($r.name)" }
  if ($problems -gt 0) { Die "$problems asset problem(s)" }
}
Log $(if ($dry) { 'Dry run finished. Nothing was changed.' } else { 'Publish finished OK.' })
exit 0
