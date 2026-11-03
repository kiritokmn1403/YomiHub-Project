# sync_050.ps1 - Synchronize overlay changes to D:\yh\build\mangayomi and D:\yh\buildwin\mangayomi
$root = $PSScriptRoot
$list = Get-Content "$root\audit-0.5.0\changed_files.txt" | Where-Object { $_ -match '\S' }
$targets = @("D:\yh\build\mangayomi", "D:\yh\buildwin\mangayomi")
$backupDir = "$root\audit-0.5.0\backup"
New-Item -ItemType Directory -Force $backupDir | Out-Null

$copied = 0
foreach ($line in $list) {
    $rel = ($line -replace "^overlay[/\\]","").Trim()
    $src = "$root\overlay\$rel"
    if (-not (Test-Path $src)) {
        Write-Warning "Source file not found: $src"
        continue
    }

    foreach ($t in $targets) {
        $dest = "$t\$rel"
        $destDir = Split-Path $dest -Parent
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Force $destDir | Out-Null
        }
        if (Test-Path $dest) {
            $bkFile = "$backupDir\$(Split-Path $t -Leaf)\$rel"
            $bkParent = Split-Path $bkFile -Parent
            if (-not (Test-Path $bkParent)) {
                New-Item -ItemType Directory -Force $bkParent | Out-Null
            }
            Copy-Item $dest $bkFile -Force
        }
        Copy-Item $src $dest -Force
        $copied++
        Write-Host "Synced: $rel -> $dest"
    }
}
Write-Host "Total synced files: $copied"

