# Public QA package: screenshots/videos without the owner's library (PRIVATE_* and n9v053_01_* stay local)
Set-Location "D:\A.I Project\A.I Project - YomiHub Project\YomiHub-Project"
$q = "audit-0.5.3\qa"; $tmp = "D:\yh\qa053\qa_public"
if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }; New-Item -ItemType Directory -Force $tmp | Out-Null
Get-ChildItem $q -File | Where-Object { $_.Extension -in '.png','.mp4' -and $_.Name -notlike 'PRIVATE_*' -and $_.Name -notlike 'n9v053_01*' } | Copy-Item -Destination $tmp
$zip = "output\YomiHub-0.5.3-QA-screenshots.zip"; Remove-Item $zip -ErrorAction SilentlyContinue
Compress-Archive "$tmp\*" $zip -CompressionLevel Optimal
"files: " + (Get-ChildItem $tmp).Count + "  zip: " + [math]::Round((Get-Item $zip).Length/1MB,1) + " MB"
(Get-ChildItem $tmp).Name -join ', '
