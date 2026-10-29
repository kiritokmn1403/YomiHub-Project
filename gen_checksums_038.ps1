$files = Get-ChildItem -Path "D:\A.I Project\A.I Project - YomiHub Project\output\*0.3.8*" | Sort-Object Name
$rows = @()
foreach ($f in $files) {
    $sha = (Get-FileHash -Path $f.FullName -Algorithm SHA256).Hash
    $md = (Get-FileHash -Path $f.FullName -Algorithm MD5).Hash
    $mb = [math]::Round($f.Length / 1MB, 2)
    $rows += [PSCustomObject]@{
        FileName = $f.Name
        SizeBytes = $f.Length
        SizeMB = "$mb MB"
        MD5 = $md
        SHA256 = $sha
    }
    Write-Host "$($f.Name)`t$($f.Length)`t$mb MB`t$md`t$sha"
}
if ($rows.Count -gt 0) {
    $rows | Export-Csv -Path "D:\A.I Project\A.I Project - YomiHub Project\output\checksums_0.3.8.csv" -NoTypeInformation -Encoding UTF8
    Write-Host "Exported checksums_0.3.8.csv successfully." -ForegroundColor Green
}
