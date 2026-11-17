# Replace the 3 phone APKs (wrong label "YumiHub Android TV") + SHA256SUMS on release v0.5.1
$ErrorActionPreference = 'Stop'
$repo = 'kiritokmn1403/YomiHub-Project'; $tag = 'v0.5.1'
$env:GCM_INTERACTIVE = 'never'; $env:GIT_TERMINAL_PROMPT = '0'
$cred = "protocol=https`nhost=github.com`n`n" | & git credential fill 2>$null
$tok = ($cred | Where-Object { $_ -like 'password=*' }) -replace '^password=', ''
if (-not $tok) { throw 'No GitHub credential' }
$h = @{ Authorization = "token $tok"; 'User-Agent' = 'YomiHub-release'; Accept = 'application/vnd.github+json' }
$api = "https://api.github.com/repos/$repo"
$rel = Invoke-RestMethod -Headers $h "$api/releases/tags/$tag"
$assets = @(Invoke-RestMethod -Headers $h "$api/releases/$($rel.id)/assets?per_page=100" | ForEach-Object { $_ })
foreach ($n in 'YomiHub-0.5.1-arm64-v8a.apk','YomiHub-0.5.1-armeabi-v7a.apk','YomiHub-0.5.1-x86_64.apk','SHA256SUMS-0.5.1.txt','YomiHub-0.5.1-windows-x64-Setup.exe','YomiHub-0.5.1-windows-x64.appxbundle','YomiHub-RootCA.cer','Install-YomiHub.bat','Install-YomiHub.ps1') {
  $a = $assets | Where-Object { $_.name -eq $n }
  if ($a) { Invoke-RestMethod -Method Delete -Headers $h "$api/releases/assets/$($a.id)" | Out-Null; "[{0}] deleted old asset {1}" -f (Get-Date -Format HH:mm:ss), $n }
}
& "D:\A.I Project\A.I Project - YomiHub Project\YomiHub-Project\release_051.ps1"
