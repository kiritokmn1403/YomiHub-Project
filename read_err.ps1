$bytes = [System.IO.File]::ReadAllBytes('D:\A.I Project\YomiHub Project\logs\flutter_build.txt')
# flutter_build.txt may have null bytes from UTF-16
$clean = [System.Text.Encoding]::ASCII.GetString($bytes) -replace "`0", ""
$lines = $clean -split "\r?\n"
Write-Host "Total lines: $($lines.Count)"
$lines | Select-Object -Last 60 | ForEach-Object { Write-Host $_ }
