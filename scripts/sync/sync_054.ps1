# sync_054.ps1 - Synchronize overlay changes to D:\yh\build\mangayomi (Android) and D:\yh\buildwin\mangayomi (Windows)
$ErrorActionPreference = "Stop"
$root = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Item .).FullName }
$manifestPath = Join-Path $root "audit-0.5.4\changed_files.txt"

if (-not (Test-Path $manifestPath)) {
    Write-Error "LỖI: Không tìm thấy tệp manifest: $manifestPath"
    exit 1
}

$list = Get-Content $manifestPath | Where-Object { $_ -match '\S' }

# Targets phân tách rõ ràng theo môi trường build (tránh trùng tên leaf 'mangayomi')
$targets = @(
    @{ Name = "android"; Path = "D:\yh\build\mangayomi" },
    @{ Name = "windows"; Path = "D:\yh\buildwin\mangayomi" }
)

# 1. PRE-FLIGHT CHECK: Báo lỗi ngay nếu tệp overlay trong manifest không tồn tại
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
    Write-Error "LỖI: Có $($missingFiles.Count) tệp overlay được khai báo trong manifest nhưng không tồn tại trên đĩa:`n$($missingFiles -join "`n")"
    exit 1
}

# 2. KHỞI TẠO ĐƯỜNG DẪN SAO LƯU BẢO TOÀN
$backupBaseDir = Join-Path $root "audit-0.5.4\backup"
$baselineBackupDir = Join-Path $backupBaseDir "baseline"
$runTimestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
$runBackupDir = Join-Path (Join-Path $backupBaseDir "runs") $runTimestamp

New-Item -ItemType Directory -Force $baselineBackupDir | Out-Null
New-Item -ItemType Directory -Force $runBackupDir | Out-Null

Write-Host "=== Bắt đầu đồng bộ YomiHub 0.5.4 ===" -ForegroundColor Cyan
Write-Host "Lượt chạy: $runTimestamp"
Write-Host "Tổng số tệp overlay cần đồng bộ: $($syncEntries.Count)"

$copied = 0
foreach ($entry in $syncEntries) {
    $rel = $entry.Rel
    $src = $entry.Src

    foreach ($target in $targets) {
        $tName = $target.Name
        $tPath = $target.Path

        if (-not (Test-Path $tPath)) {
            Write-Warning "Thư mục đích không tồn tại: $tPath (bỏ qua target $tName)"
            continue
        }

        $dest = Join-Path $tPath $rel
        $destDir = Split-Path $dest -Parent
        if ($destDir -and -not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Force $destDir | Out-Null
        }

        # Nếu đích đã có file, thực hiện sao lưu bảo toàn:
        if (Test-Path $dest) {
            # a) Bảo toàn bản gốc ban đầu (baseline) - không bao giờ ghi đè lên baseline đã có
            $baseBkFile = Join-Path (Join-Path $baselineBackupDir $tName) $rel
            if (-not (Test-Path $baseBkFile)) {
                $baseBkParent = Split-Path $baseBkFile -Parent
                if ($baseBkParent -and -not (Test-Path $baseBkParent)) {
                    New-Item -ItemType Directory -Force $baseBkParent | Out-Null
                }
                Copy-Item $dest $baseBkFile -Force
            }

            # b) Sao lưu theo từng lượt chạy (run snapshot)
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
        Write-Host "[$tName] Đã đồng bộ: $rel -> $dest" -ForegroundColor Green
    }
}

Write-Host "=== Đồng bộ hoàn tất: Đã sao chép $copied lượt tệp vào các target ===" -ForegroundColor Cyan
Write-Host "Backup baseline bảo toàn tại: $baselineBackupDir"
Write-Host "Backup lượt chạy này tại: $runBackupDir"
