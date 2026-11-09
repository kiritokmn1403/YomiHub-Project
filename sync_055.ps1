# sync_055.ps1 - Synchronize overlay changes for YomiHub 0.5.5 with SHA256 verification and baseline protection
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"

$root = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Item .).FullName }
$manifestPath = Join-Path $root "audit-0.5.5\changed_files.txt"

if (-not (Test-Path $manifestPath)) {
    Write-Error "LỖI: Không tìm thấy tệp manifest 0.5.5: $manifestPath"
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
    Write-Error "LỖI: Có $($missingFiles.Count) tệp overlay được khai báo trong manifest 0.5.5 nhưng không tồn tại trên đĩa:`n$($missingFiles -join "`n")"
    exit 1
}

# 2. KHỞI TẠO ĐƯỜNG DẪN SAO LƯU RIÊNG CHO 0.5.5
$backupBaseDir = Join-Path $root "audit-0.5.5\backup"
$baselineBackupDir = Join-Path $backupBaseDir "baseline"
$runTimestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
$runBackupDir = Join-Path (Join-Path $backupBaseDir "runs") $runTimestamp

New-Item -ItemType Directory -Force $baselineBackupDir | Out-Null
New-Item -ItemType Directory -Force $runBackupDir | Out-Null

Write-Host "=== Bắt đầu đồng bộ YomiHub 0.5.5 ===" -ForegroundColor Cyan
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

Write-Host "=== Đồng bộ hoàn tất: Đã sao chép $copied lượt tệp vào các target ===" -ForegroundColor Cyan
Write-Host "Backup baseline bảo toàn tại: $baselineBackupDir"
Write-Host "Backup lượt chạy này tại: $runBackupDir"

# 3. KIỂM TRA SHA256 ĐỐI CHIẾU 3 BẢN (OVERLAY, ANDROID, WINDOWS)
Write-Host "`n=== BẮT ĐẦU KIỂM TRA BẢNG BĂM SHA256 (OVERLAY vs ANDROID vs WINDOWS) ===" -ForegroundColor Yellow
$hashReportLines = @()
$hashReportLines += "BÁO CÁO ĐỐI CHIẾU MÃ BĂM SHA256 - YOMIHUB 0.5.5"
$hashReportLines += "Thời gian: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$hashReportLines += "------------------------------------------------------------------------------------------------------------------------"
$hashReportLines += [string]::Format("{0,-45} | {1,-64} | {2}", "Tệp tin", "Mã băm SHA256 (Overlay)", "Kết quả so khớp")
$hashReportLines += "------------------------------------------------------------------------------------------------------------------------"

$mismatchCount = 0
foreach ($entry in $syncEntries) {
    $rel = $entry.Rel
    $src = $entry.Src
    $androidDest = Join-Path "D:\yh\build\mangayomi" $rel
    $windowsDest = Join-Path "D:\yh\buildwin\mangayomi" $rel

    $srcHash = (Get-FileHash -Path $src -Algorithm SHA256).Hash
    $androidHash = if (Test-Path $androidDest) { (Get-FileHash -Path $androidDest -Algorithm SHA256).Hash } else { "MISSING" }
    $windowsHash = if (Test-Path $windowsDest) { (Get-FileHash -Path $windowsDest -Algorithm SHA256).Hash } else { "MISSING" }

    $match = ($srcHash -eq $androidHash) -and ($srcHash -eq $windowsHash)
    $statusText = if ($match) { "KHỚP 100% (Android & Windows)" } else { "LỖI LỆCH MÃ BĂM!" }

    if (-not $match) {
        $mismatchCount++
        Write-Host "[LỖI LỆCH HASH] $rel" -ForegroundColor Red
        Write-Host "  Overlay: $srcHash" -ForegroundColor Red
        Write-Host "  Android: $androidHash" -ForegroundColor Red
        Write-Host "  Windows: $windowsHash" -ForegroundColor Red
    } else {
        Write-Host "[KHỚP SHA256] $rel -> $srcHash" -ForegroundColor Green
    }

    $hashReportLines += [string]::Format("{0,-45} | {1,-64} | {2}", $rel, $srcHash, $statusText)
}
$hashReportLines += "------------------------------------------------------------------------------------------------------------------------"

$verificationReportPath = Join-Path $root "audit-0.5.5\sha256_verification.txt"
$hashReportLines | Set-Content -Path $verificationReportPath -Encoding UTF8

if ($mismatchCount -gt 0) {
    Write-Error "LỖI: Phát hiện $mismatchCount tệp bị lệch mã băm SHA256 giữa Overlay và các thư mục build! Dừng quy trình."
    exit 1
}

Write-Host "`n>>> TẤT CẢ $($syncEntries.Count) TỆP ĐÃ XÁC MINH TRÙNG KHỚP 100% SHA256 GIỮA OVERLAY, ANDROID VÀ WINDOWS <<<" -ForegroundColor Cyan
Write-Host "Báo cáo chi tiết đã lưu tại: $verificationReportPath`n"
