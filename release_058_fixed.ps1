# release_058_fixed.ps1 - publish output\0.5.8 to GitHub Releases (v0.5.8, "YomiHub 0.5.8") with a
# progress line per file and a final size check against the local files.
# The GitHub token comes from Git Credential Manager at run time and is never
# printed or written to disk.
param([string]$tag = 'v0.5.8', [string]$repo = 'kiritokmn1403/YomiHub-Project')
$ErrorActionPreference = 'Stop'
if ($tag -ne 'v0.5.8') { throw "release_058_fixed.ps1 chi phat hanh v0.5.8 (khong sua tag/Release cu: $tag)" }
$root = $PSScriptRoot
$out = "$root\output\0.5.8"
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
$changelogPath = "$out\YomiHub-0.5.8-changelog.md"
if (-not (Test-Path $changelogPath)) { throw "Missing $changelogPath (release body must come from the changelog)" }
[string]$body = [IO.File]::ReadAllText($changelogPath, [Text.Encoding]::UTF8)
if ($body -match '<<') { throw 'Changelog still contains <<placeholder>>' }
if ($files.Count -lt 1) { throw "No files in $out" }

try { $rel = Invoke-RestMethod -Headers $h "$api/releases/tags/$tag"; Log "Release $tag exists (id $($rel.id))" }
catch {
    Log "Creating release $tag..."
    $payload = @{ tag_name = $tag; target_commitish = 'main'; name = "YomiHub 0.5.8"; body = $body; draft = $false; prerelease = $false; make_latest = 'true' } | ConvertTo-Json
    $rel = Invoke-RestMethod -Method Post -Headers $h -Uri "$api/releases" -Body ([System.Text.Encoding]::UTF8.GetBytes($payload)) -ContentType 'application/json; charset=utf-8'
    Log "Release created (id $($rel.id))"
}

$req = @{ body = $body; make_latest = 'true'; name = "YomiHub 0.5.8" } | ConvertTo-Json
Invoke-RestMethod -Method Patch -Headers $h -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($req)) "$api/releases/$($rel.id)" | Out-Null

$existing = @(Invoke-RestMethod -Headers $h "$api/releases/$($rel.id)/assets?per_page=100" | ForEach-Object { $_ })
Log ("{0} assets already on release" -f $existing.Count)

$uploadUrlBase = ($rel.upload_url -replace '\{\?name,label\}', '')
$total = $files.Count
$totalBytes = ($files | Measure-Object Length -Sum).Sum
$doneBytes = 0
$idx = 0
foreach ($f in $files) {
    $idx++
    $name = $f.Name
    $len = $f.Length
    $mb = $len / 1MB
    $old = $existing | Where-Object { $_.name -eq $name }
    if ($old -and $old.size -eq $len -and $old.state -eq 'uploaded') {
        $doneBytes += $len
        Log ("[{0}/{1}] SKIP {2} ({3:N1} MB - already uploaded) - {4:P0}" -f $idx, $total, $name, $mb, ($doneBytes / $totalBytes))
        continue
    }
    if ($old) {
        Log ("[{0}/{1}] DELETE old {2} (id {3}, size {4} vs local {5})" -f $idx, $total, $name, $old.id, $old.size, $len)
        Invoke-RestMethod -Method Delete -Headers $h -Uri "$api/releases/assets/$($old.id)" | Out-Null
    }
    $ctype = switch -Regex ($name) {
        '\.apk$' { 'application/vnd.android.package-archive' }
        '\.appxbundle$' { 'application/x-ms-appxbundle' }
        '\.zip$' { 'application/zip' }
        '\.exe$' { 'application/vnd.microsoft.portable-executable' }
        '\.cer$' { 'application/x-x509-ca-cert' }
        '\.(ps1|bat|txt|md)$' { 'text/plain; charset=utf-8' }
        default { 'application/octet-stream' }
    }
    $uri = "$uploadUrlBase`?name=$([Uri]::EscapeDataString($name))"
    Log ("[{0}/{1}] UPLOAD {2} ({3:N1} MB)..." -f $idx, $total, $name, $mb)
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $code = ''
    for ($try = 1; $try -le 3; $try++) {
        $code = & curl.exe -sS --speed-limit 10240 --speed-time 60 -o NUL -w "%{http_code}" -X POST -H "Authorization: token $tok" -H "Content-Type: $ctype" --data-binary "@$($f.FullName)" $uri
        if ($code -eq '201') { break }
        Log ("[{0}/{1}] {2}: attempt {3} failed (HTTP {4}) - retrying..." -f $idx, $total, $name, $try, $code)
        $part = @(Invoke-RestMethod -Headers $h "$api/releases/$($rel.id)/assets?per_page=100" | ForEach-Object { $_ }) | Where-Object { $_.name -eq $name }
        if ($part) { Invoke-RestMethod -Method Delete -Headers $h "$api/releases/assets/$($part.id)" | Out-Null }
        Start-Sleep 5
    }
    $sw.Stop()
    if ($code -ne '201') { throw "Upload of $name failed: HTTP $code" }
    $doneBytes += $len
    $dur = $sw.Elapsed.TotalSeconds
    $speed = if ($dur -gt 0) { ($mb / $dur) } else { 0 }
    Log ("[{0}/{1}] OK {2} ({3:N1} MB in {4:N1}s = {5:N2} MB/s) - total {6:P0}" -f $idx, $total, $name, $mb, $dur, $speed, ($doneBytes / $totalBytes))
}

Log "Verifying all assets on GitHub release..."
$final = @(Invoke-RestMethod -Headers $h "$api/releases/$($rel.id)/assets?per_page=100" | ForEach-Object { $_ })
$missing = @()
foreach ($f in $files) {
    $match = $final | Where-Object { $_.name -eq $f.Name }
    if (-not $match) { $missing += "$($f.Name) (missing)" }
    elseif ($match.size -ne $f.Length) { $missing += "$($f.Name) (size mismatch: local $($f.Length) vs remote $($match.size))" }
}
if ($missing.Count -gt 0) {
    throw ("Release verification failed: " + ($missing -join ', '))
}
Log ("Release verification SUCCESS: All {0} assets verified with identical sizes on GitHub!" -f $files.Count)
