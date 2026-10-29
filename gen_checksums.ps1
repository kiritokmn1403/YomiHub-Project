$files = Get-ChildItem -Path "D:\A.I Project\A.I Project - YomiHub Project\output\*0.3.5*" | Sort-Object Name
foreach ($f in $files) {
    $sha = (Get-FileHash -Path $f.FullName -Algorithm SHA256).Hash
    $md = (Get-FileHash -Path $f.FullName -Algorithm MD5).Hash
    $mb = [math]::Round($f.Length / 1MB, 2)
    Write-Host "$($f.Name)`t$($f.Length)`t$mb MB`t$md`t$sha"
}
