# sync_0561.ps1 - Dong bo overlay 0.5.6.1 (0.5.6+49) sang D:\yh\build\mangayomi va D:\yh\buildwin\mangayomi.
# Danh sach tep: audit-0.5.7\release\changed_files_0561.txt (tao lai bang  -Regen : git diff HEAD + tep chua theo doi trong overlay).
# Sao luu truoc khi ghi de: audit-0.5.7\backup\{baseline,runs}. Khong xoa tep nao.
param([switch]$Regen)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"

$root = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Item .).FullName }
$manifestPath = Join-Path $root "audit-0.5.7\release\changed_files_0561.txt"
if ($Regen) {
    $git = if (Get-Command git -ErrorAction SilentlyContinue) { 'git' } else { 'D:\yh\tools\git\cmd\git.exe' }
    $l = @(& $git -C $root diff --name-only HEAD -- overlay) + @(& $git -C $root ls-files -o --exclude-standard -- overlay)
    $l = @($l | Where-Object { $_ -match '\S' } | Sort-Object -Unique)
    if ($l.Count -eq 0) { Write-Error "LỖI: git không báo tệp overlay nào thay đổi"; exit 1 }
    [IO.File]::WriteAllText($manifestPath, (($l -join "`n") + "`n"), (New-Object Text.UTF8Encoding($false)))
    Write-Host "Đã tạo lại $manifestPath ($($l.Count) tệp)" -ForegroundColor Yellow
}

if (-not (Test-Path $manifestPath)) {
    Write-Error "LỖI: Không tìm thấy tệp manifest 0.5.6.1: $manifestPath"
    exit 1
}

$list = Get-Content -Path $manifestPath -Encoding UTF8 | Where-Object { $_ -match '\S' }

# Danh mục build targets phân tách theo nền tảng
$targets = @(
    [PSCustomObject]@{ Name = "android"; Path = "D:\yh\build\mangayomi" },
    [PSCustomObject]@{ Name = "windows"; Path = "D:\yh\buildwin\mangayomi" }
)

$ps = Get-Content (Join-Path $root "overlay\pubspec.yaml") -Raw
if ($ps -notmatch '(?m)^version:\s*0\.5\.6\+49\s*$') { Write-Error "LỖI: overlay/pubspec.yaml phải là version: 0.5.6+49"; exit 1 }
if ($list -notcontains 'overlay/pubspec.yaml' -and ($list | Where-Object { $_ -match 'pubspec\.yaml$' }).Count -eq 0) { Write-Error "LỖI: manifest thiếu overlay/pubspec.yaml"; exit 1 }

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
    Write-Error "LỖI: Có $($missingFiles.Count) tệp overlay được khai báo trong manifest 0.5.6.1 nhưng không tồn tại trên đĩa:`n$($missingFiles -join "`n")"
    exit 1
}

# 2. KHỞI TẠO ĐƯỜNG DẪN SAO LƯU RIÊNG CHO 0.5.6.1
$backupBaseDir = Join-Path $root "audit-0.5.7\backup"
$baselineBackupDir = Join-Path $backupBaseDir "baseline"
$runTimestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
$runBackupDir = Join-Path (Join-Path $backupBaseDir "runs") $runTimestamp

New-Item -ItemType Directory -Force $baselineBackupDir | Out-Null
New-Item -ItemType Directory -Force $runBackupDir | Out-Null

Write-Host "=== Bắt đầu đồng bộ YomiHub 0.5.6.1 ===" -ForegroundColor Cyan
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
$manifestOut = Join-Path $root "audit-0.5.7\release\overlay_manifest_0561.txt"
$hashLines = @()
foreach ($entry in $syncEntries) {
    $rel = $entry.Rel
    $src = $entry.Src
    $h = (Get-FileHash -Path $src -Algorithm SHA256).Hash
    $hashLines += "$h  overlay/$rel"
}
$hashLines | Sort-Object | Set-Content -Path $manifestOut -Encoding UTF8

Write-Host "=== Hoàn tất đồng bộ YomiHub 0.5.6.1 ===" -ForegroundColor Cyan
Write-Host "Tổng số lượt copy: $copied"
Write-Host "Manifest SHA256 đã lưu tại: $manifestOut"
