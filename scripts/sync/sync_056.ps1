﻿# sync_056.ps1 - Synchronize overlay changes for YomiHub 0.5.6 with SHA256 verification and baseline protection
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"

$root = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Item .).FullName }
$manifestPath = Join-Path $root "audit-0.5.6\changed_files.txt"

if (-not (Test-Path $manifestPath)) {
    Write-Error "LỖI: Không tìm thấy tệp manifest 0.5.6: $manifestPath"
    exit 1
}

$list = Get-Content -Path $manifestPath -Encoding UTF8 | Where-Object { $_ -match '\S' }

# Danh mục build targets phân tách theo nền tảng
$targets = @(
    [PSCustomObject]@{ Name = "android"; Path = "D:\yh\build\mangayomi" },
    [PSCustomObject]@{ Name = "windows"; Path = "D:\yh\buildwin\mangayomi" }
)

# 1. PRE-FLIGHT CHECK: Kiểm tra sự tồn tại của toàn bộ tệp overlay trong manifest
$missingFiles = @()
$syncEntries = @()
foreach ($line in $list) {
    $cleanLine = $line.Trim()
    $rel = ($cleanLine -replace "^overlay[/\\]","").TrimStart("/\").Trim()
    $src = Join-Path (Join-Path $root "overlay") $rel
    if (-not (Test-Path $src)) {
        $missingFiles += $src
    } else {
        $syncEntries += @{ Rel = $rel; Src = $src }
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Error "LỖI: Có $($missingFiles.Count) tệp overlay được khai báo trong manifest 0.5.6 nhưng không tồn tại trên đĩa:`n$($missingFiles -join "`n")"
    exit 1
}

# 2. KHỞI TẠO ĐƯỜNG DẪN SAO LƯU RIÊNG CHO 0.5.6
$backupBaseDir = Join-Path $root "audit-0.5.6\backup"
$baselineBackupDir = Join-Path $backupBaseDir "baseline"
$runTimestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
$runBackupDir = Join-Path (Join-Path $backupBaseDir "runs") $runTimestamp

New-Item -ItemType Directory -Force $baselineBackupDir | Out-Null
New-Item -ItemType Directory -Force $runBackupDir | Out-Null

Write-Host "=== Bắt đầu đồng bộ YomiHub 0.5.6 ===" -ForegroundColor Cyan
Write-Host "Lượt chạy: $runTimestamp"
Write-Host "Tổng số tệp overlay cần đồng bộ: $($syncEntries.Count)"

$copied = 0
foreach ($entry in $syncEntries) {
    $rel = $entry.Rel
    $src = $entry.Src

    foreach ($target in $targets) {
        $tName = $target.Name
        $tPath = $target.Path

        if ([string]::IsNullOrWhiteSpace($tPath) -or -not (Test-Path $tPath)) {
            Write-Warning "Thư mục đích không tồn tại hoặc rỗng: '$tPath' (bỏ qua target $tName)"
            continue
        }

        $dest = Join-Path $tPath $rel
        $destDir = Split-Path $dest -Parent
        if ($destDir -and -not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Force $destDir | Out-Null
        }

        # Sao lưu bảo toàn:
        if (Test-Path $dest) {
            # a) Baseline backup - không bao giờ ghi đè lên baseline đã có
            $baseBkFile = Join-Path (Join-Path $baselineBackupDir $tName) $rel
            if (-not (Test-Path $baseBkFile)) {
                $baseBkParent = Split-Path $baseBkFile -Parent
                if ($baseBkParent -and -not (Test-Path $baseBkParent)) {
                    New-Item -ItemType Directory -Force $baseBkParent | Out-Null
                }
                Copy-Item $dest $baseBkFile -Force
            }

            # b) Snapshot theo từng lượt chạy
            $runBkFile = Join-Path (Join-Path $runBackupDir $tName) $rel
            $runBkParent = Split-Path $runBkFile -Parent
            if ($runBkParent -and -not (Test-Path $runBkParent)) {
                New-Item -ItemType Directory -Force $runBkParent | Out-Null
            }
            Copy-Item $dest $runBkFile -Force
        }

        # Đồng bộ tệp mới từ overlay vào đích
        Copy-Item $src $dest -Force
        $copied++
        Write-Host "[$tName] Đã đồng bộ: $rel" -ForegroundColor Green
    }
}

# 3. TẠO HASH MANIFEST SAU ĐỒNG BỘ
$manifestOut = Join-Path $root "audit-0.5.6\overlay_manifest_056.txt"
$hashLines = @()
foreach ($entry in $syncEntries) {
    $rel = $entry.Rel
    $src = $entry.Src
    $h = (Get-FileHash -Path $src -Algorithm SHA256).Hash
    $hashLines += "$h  overlay/$rel"
}
$hashLines | Sort-Object | Set-Content -Path $manifestOut -Encoding UTF8

Write-Host "=== Hoàn tất đồng bộ YomiHub 0.5.6 ===" -ForegroundColor Cyan
Write-Host "Tổng số lượt copy: $copied"
Write-Host "Manifest SHA256 đã lưu tại: $manifestOut"
