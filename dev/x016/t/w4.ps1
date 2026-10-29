$d = [Environment]::GetFolderPath('MyDocuments') + '\YomiHub'
Get-Item "$d\logs.txt","$d\crash_reports.json" | ForEach-Object { "$($_.Name) $($_.Length) $($_.LastWriteTime)" }
Get-Content "$d\logs.txt" -Tail 30 -Encoding UTF8
"---- crash"
Get-Content "$d\crash_reports.json" -Encoding UTF8 -Raw | Select-Object -First 1 | ForEach-Object { $_.Substring([Math]::Max(0,$_.Length-3000)) }
