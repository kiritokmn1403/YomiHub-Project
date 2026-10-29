$cands = @("$env:USERPROFILE\Documents\YomiHub", "$env:APPDATA\YomiHub", "$env:APPDATA\com.yomihub.app", "$env:LOCALAPPDATA\YomiHub")
foreach ($c in $cands) { if (Test-Path $c) { "== $c"; Get-ChildItem $c -Force | Select-Object Name,Length,LastWriteTime | Format-Table -AutoSize | Out-String -Width 200 } }
$docs = [Environment]::GetFolderPath('MyDocuments'); "docs=$docs"
Get-ChildItem $docs -Directory -ErrorAction SilentlyContinue | Where-Object Name -match 'yomi|manga' | ForEach-Object { "== $($_.FullName)"; Get-ChildItem $_.FullName -Force | Select-Object Name,Length,LastWriteTime | Format-Table -AutoSize | Out-String -Width 200 }
Get-ChildItem $docs -Recurse -Depth 2 -Include logs.txt,crash*.txt,*.log -ErrorAction SilentlyContinue | Where-Object FullName -match 'Yomi' | ForEach-Object { "### $($_.FullName) $($_.LastWriteTime)"; Get-Content $_.FullName -Tail 25 }
Get-WinEvent -LogName Application -MaxEvents 30 -ErrorAction SilentlyContinue | Where-Object { $_.Message -match 'YomiHub' } | Select-Object -First 5 | ForEach-Object { "$($_.TimeCreated) $($_.Id) $($_.Message.Substring(0,[Math]::Min(400,$_.Message.Length)))" }
