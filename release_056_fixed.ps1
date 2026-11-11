# release_056.ps1 - publish output\0.5.6 to GitHub Releases (v0.5.6) with a
# progress line per file and a final size check against the local files.
# The GitHub token comes from Git Credential Manager at run time and is never
# printed or written to disk.
param([string]$tag = 'v0.5.6', [string]$repo = 'kiritokmn1403/YomiHub-Project')
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$out = "$root\output\0.5.6"
$env:GCM_INTERACTIVE = 'never'; $env:GIT_TERMINAL_PROMPT = '0'

$tmp = [System.IO.Path]::GetTempFileName()
try {
    [System.IO.File]::WriteAllText($tmp, "protocol=https`nhost=github.com`n`n")
    $cred = cmd.exe /c "git credential fill < `"$tmp`" 2>NUL"
} finally {
    Remove-Item $tmp -Force -ErrorAction SilentlyContinue
}
$tok = ($cred | Where-Object { $_ -like 'password=*' }) -replace '^password=', ''
if (-not $tok) { throw 'No GitHub credential in Git Credential Manager' }

$h = @{ Authorization = "token $tok"; 'User-Agent' = 'YomiHub-release'; Accept = 'application/vnd.github+json' }
$api = "https://api.github.com/repos/$repo"
function Log($m) { $line = "[{0}] {1}" -f (Get-Date -Format HH:mm:ss), $m; Write-Output $line }

$files = @(Get-ChildItem $out -File | Sort-Object Name)
$extra = @("$root\TECHNICAL_UPDATE_NOTES.md")
foreach ($e in $extra) {
    if ((Test-Path $e) -and -not ($files | Where-Object { $_.Name -eq (Split-Path $e -Leaf) })) {
        $files += Get-Item $e
    }
}
$files = @($files | Sort-Object Name)
$changelogPath = "$out\YomiHub-0.5.6-changelog.md"
if (-not (Test-Path $changelogPath)) { throw "Missing $changelogPath (release body must come from the changelog)" }
[string]$body = [IO.File]::ReadAllText($changelogPath, [Text.Encoding]::UTF8)
if ($body -match '<<') { throw 'Changelog still contains <<placeholder>>' }
if ($files.Count -lt 1) { throw "No files in $out" }

try { $rel = Invoke-RestMethod -Headers $h "$api/releases/tags/$tag"; Log "Release $tag exists (id $($rel.id))" }
catch {
  if ($_.Exception.Response -and [int]$_.Exception.Response.StatusCode -ne 404) { throw }
  $req = @{ tag_name = $tag; target_commitish = 'main'; name = 'YomiHub 0.5.6 (0.5.6+48)'; body = $body; draft = $false; prerelease = $false; make_latest = 'true' } | ConvertTo-Json
  $rel = Invoke-RestMethod -Method Post -Headers $h -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($req)) "$api/releases"
  Log "Created release $tag (id $($rel.id))"
}
$req = @{ body = $body; make_latest = 'true'; name = 'YomiHub 0.5.6 (0.5.6+48)' } | ConvertTo-Json
Invoke-RestMethod -Method Patch -Headers $h -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($req)) "$api/releases/$($rel.id)" | Out-Null

$existing = @(Invoke-RestMethod -Headers $h "$api/releases/$($rel.id)/assets?per_page=100" | ForEach-Object { $_ })
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
  if ($code -ne '201') { throw "Upload of $($f.Name) failed: HTTP $code" }
  Log ("[{0}/{1}] {2} {3:N1} MB -> HTTP {4} in {5:N0}s - total {6:P0}" -f $i, $files.Count, $f.Name, ($f.Length/1MB), $code, $sw.Elapsed.TotalSeconds, ($done/$total))
}

$assets = @(Invoke-RestMethod -Headers $h "$api/releases/$($rel.id)/assets?per_page=100" | ForEach-Object { $_ })
$bad = 0
foreach ($f in $files) {
  $a = $assets | Where-Object { $_.name -eq $f.Name }
  $ok = $a -and $a.size -eq $f.Length -and $a.state -eq 'uploaded'
  if (-not $ok) { $bad++ }
  Log ("VERIFY {0,-45} local {1,12} remote {2,12} {3}" -f $f.Name, $f.Length, $(if ($a) { $a.size } else { '-' }), $(if ($ok) { 'OK' } else { 'MISSING/MISMATCH' }))
}
Log "assets on release: $($assets.Count); problems: $bad"
Log "URL: $($rel.html_url)"
if ($bad -gt 0) { throw "$bad asset(s) missing or size mismatch" }
Log "Release $tag upload complete."

