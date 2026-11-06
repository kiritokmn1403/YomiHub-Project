# release_053.ps1 - publish output\0.5.3 to GitHub Releases (v0.5.3) with a
# progress line per file and a final size check against the local files.
# The GitHub token comes from Git Credential Manager at run time and is never
# printed or written to disk.
param([string]$tag = 'v0.5.3', [string]$repo = 'kiritokmn1403/YomiHub-Project')
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$out = "$root\output\0.5.3"
$env:GCM_INTERACTIVE = 'never'; $env:GIT_TERMINAL_PROMPT = '0'
$cred = "protocol=https`nhost=github.com`n`n" | & git credential fill 2>$null
$tok = ($cred | Where-Object { $_ -like 'password=*' }) -replace '^password=', ''
if (-not $tok) { throw 'No GitHub credential in Git Credential Manager' }
$h = @{ Authorization = "token $tok"; 'User-Agent' = 'YomiHub-release'; Accept = 'application/vnd.github+json' }
$api = "https://api.github.com/repos/$repo"
function Log($m) { $line = "[{0}] {1}" -f (Get-Date -Format HH:mm:ss), $m; Write-Output $line }

$files = @(Get-ChildItem $out -File | Sort-Object Name)
$extra = @("$root\TECHNICAL_UPDATE_NOTES.md", "$out\..\YomiHub-0.5.3-QA-screenshots.zip")
foreach ($e in $extra) { if (Test-Path $e) { $files += Get-Item $e } }
# ReadAllText: Get-Content -Raw adds PSPath note properties that ConvertTo-Json would serialize
[string]$body = [IO.File]::ReadAllText("$out\YomiHub-0.5.3-changelog.md", [Text.Encoding]::UTF8)

try { $rel = Invoke-RestMethod -Headers $h "$api/releases/tags/$tag"; Log "Release $tag exists (id $($rel.id))" }
catch {
  $req = @{ tag_name = $tag; target_commitish = 'main'; name = 'YomiHub 0.5.3 (0.5.3+45)'; body = $body; draft = $false; prerelease = $false; make_latest = 'true' } | ConvertTo-Json
  $rel = Invoke-RestMethod -Method Post -Headers $h -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($req)) "$api/releases"
  Log "Created release $tag (id $($rel.id))"
}
$req = @{ body = $body; make_latest = 'true'; name = 'YomiHub 0.5.3 (0.5.3+45)' } | ConvertTo-Json
Invoke-RestMethod -Method Patch -Headers $h -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($req)) "$api/releases/$($rel.id)" | Out-Null

$existing = @(Invoke-RestMethod -Headers $h "$api/releases/$($rel.id)/assets?per_page=100" | ForEach-Object { $_ })  # unroll the JSON array (PowerShell 5)
$total = ($files | Measure-Object Length -Sum).Sum; $done = 0; $i = 0
Log ("Uploading {0} files, {1:N1} MB" -f $files.Count, ($total / 1MB))
foreach ($f in $files) {
  $i++
  $old = $existing | Where-Object { $_.name -eq $f.Name }
  if ($old -and $old.size -eq $f.Length -and $old.state -eq 'uploaded' -and $f.Extension -notin '.md','.txt') {
    $done += $f.Length; Log ("[{0}/{1}] {2} already uploaded ({3:N1} MB) - {4:P0}" -f $i, $files.Count, $f.Name, ($f.Length/1MB), ($done/$total)); continue
  }
  if ($old) { Invoke-RestMethod -Method Delete -Headers $h "$api/releases/assets/$($old.id)" | Out-Null }
  $name = [Uri]::EscapeDataString($f.Name)
  $url = "https://uploads.github.com/repos/$repo/releases/$($rel.id)/assets?name=$name"
  $sw = [Diagnostics.Stopwatch]::StartNew()
  $code = & curl.exe -sS -o NUL -w "%{http_code}" -X POST -H "Authorization: token $tok" -H "Content-Type: application/octet-stream" --data-binary "@$($f.FullName)" $url
  $sw.Stop(); $done += $f.Length
  Log ("[{0}/{1}] {2} {3:N1} MB -> HTTP {4} in {5:N0}s - total {6:P0}" -f $i, $files.Count, $f.Name, ($f.Length/1MB), $code, $sw.Elapsed.TotalSeconds, ($done/$total))
}
$assets = @(Invoke-RestMethod -Headers $h "$api/releases/$($rel.id)/assets?per_page=100" | ForEach-Object { $_ })
$bad = 0
foreach ($f in $files) {
  $a = $assets | Where-Object { $_.name -eq $f.Name }
  $ok = $a -and $a.size -eq $f.Length -and $a.state -eq 'uploaded'
  if (-not $ok) { $bad++ }
  $dl = '-'
  if ($a) { try { $r = Invoke-WebRequest -UseBasicParsing -Method Head -MaximumRedirection 5 $a.browser_download_url; $dl = $r.StatusCode } catch { $dl = 'ERR' } }
  Log ("VERIFY {0,-45} local {1,12} remote {2,12} {3} download={4}" -f $f.Name, $f.Length, $(if ($a) { $a.size } else { '-' }), $(if ($ok) { 'OK' } else { 'MISSING/MISMATCH' }), $dl)
}
$latest = Invoke-RestMethod -Headers $h "$api/releases/latest"
Log "releases/latest = $($latest.tag_name); assets on release: $($assets.Count); problems: $bad"
Log "URL: $($rel.html_url)"
