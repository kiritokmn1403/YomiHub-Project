[CmdletBinding()]
param(
    [ValidateSet('all', 'test', 'unit', 'apk', 'tv', 'win', 'pack', 'verify', 'verify-package', 'verify_package', 'none')]
    [string]$step = 'all'
)

# build_055.ps1 - YomiHub 0.5.6 build & packaging script with strict artifact, ABI, versionCode, and signature verification.
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$root = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Item .).FullName }
$skipFile = Join-Path $root "audit-0.5.6\SKIP_STEPS"
if ((Test-Path $skipFile) -and ((Get-Content $skipFile -Raw) -split '\s+' -contains $step)) {
    Write-Host "Bỏ qua step $step do khai báo trong SKIP_STEPS" -ForegroundColor Yellow
    exit 0
}

. "$root\common.ps1"

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$buildLogPath = Join-Path $LOGS "build056_${step}_$stamp.txt"
Start-Transcript $buildLogPath -Force | Out-Null
$ErrorActionPreference = 'Stop'

function Run($exe, [string[]]$a, $logName) {
    $shown = ($a -join ' ')
    if ($script:secret) { $shown = $shown.Replace($script:secret, '***') }
    Say "> $exe $shown"
    $outLog = Join-Path $LOGS $logName
    $fullExe = if (Test-Path "$TOOLS\flutter\bin\$exe") { "$TOOLS\flutter\bin\$exe" }
               elseif (Test-Path "$TOOLS\cargo\bin\$exe") { "$TOOLS\cargo\bin\$exe" }
               elseif (Test-Path "$TOOLS\git\cmd\$exe") { "$TOOLS\git\cmd\$exe" }
               else { $exe }
    $quotedArgs = @()
    foreach ($arg in $a) {
        if ($arg -match '\s' -and -not ($arg.StartsWith('\"') -or $arg.StartsWith('"'))) {
            $quotedArgs += "`"$arg`""
        } else {
            $quotedArgs += $arg
        }
    }
    $cmdStr = if ($quotedArgs.Count -gt 0) { "`"$fullExe`" $($quotedArgs -join ' ')" } else { "`"$fullExe`"" }
    cmd.exe /c "set `"PATH=$TOOLS\git\cmd;$TOOLS\mingw64\bin;$TOOLS\flutter\bin;$TOOLS\jdk\bin;$TOOLS\cargo\bin;$TOOLS\android-sdk\cmdline-tools\latest\bin;$TOOLS\android-sdk\platform-tools;%PATH%`" && $cmdStr >> `"$outLog`" 2>&1"
    if ($LASTEXITCODE -ne 0) { throw "$exe thất bại (exit $LASTEXITCODE) - xem chi tiết tại logs\$logName" }
}

$abld = "$YH\build\mangayomi"
$wbld = "$YH\buildwin\mangayomi"
$strXml = "$abld\android\app\src\main\res\values\strings.xml"

function Set-AppName([string]$n) {
    $c = [IO.File]::ReadAllText($strXml)
    $c = [regex]::Replace($c, '<string name="app_name">[^<]*</string>', "<string name=`"app_name`">$n</string>")
    [IO.File]::WriteAllText($strXml, $c, (New-Object Text.UTF8Encoding($false)))
    Say "app_name = $n"
}

# Công cụ Android SDK
$aapt2 = (Get-ChildItem "$TOOLS\android-sdk\build-tools" -Recurse -Filter "aapt2.exe" | Select-Object -Last 1).FullName
$apksigner = (Get-ChildItem "$TOOLS\android-sdk\build-tools" -Recurse -Filter "apksigner.bat" | Select-Object -Last 1).FullName

if (-not (Test-Path $aapt2)) { throw "Không tìm thấy aapt2.exe trong $TOOLS\android-sdk\build-tools" }
if (-not (Test-Path $apksigner)) { throw "Không tìm thấy apksigner.bat trong $TOOLS\android-sdk\build-tools" }

function Get-ExpectedVersionCode([string]$abi, [int]$baseCode) {
    switch ($abi) {
        'armeabi-v7a' { return (1000 + $baseCode).ToString() }
        'arm64-v8a'   { return (2000 + $baseCode).ToString() }
        'x86'         { return (3000 + $baseCode).ToString() }
        'x86_64'      { return (4000 + $baseCode).ToString() }
        default       { return $baseCode.ToString() }
    }
}

function Verify-ApkDetails([string]$apkPath, [string]$expectedLabel, [string]$expectedAbi, [string]$expectedVer, [string]$expectedCode) {
    Say "--- Kiểm tra toàn diện APK: $(Split-Path $apkPath -Leaf) ---"
    
    if (-not (Test-Path $apkPath)) {
        throw "LỖI ARTIFACT THIẾU: Không tìm thấy tệp APK tại $apkPath"
    }
    $len = (Get-Item $apkPath).Length
    if ($len -le 0) {
        throw "LỖI ARTIFACT HỎNG: Tệp APK $apkPath có kích thước 0 byte"
    }

    # 1. Xác minh qua aapt2 dump badging
    $badging = & $aapt2 dump badging $apkPath 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "LỖI aapt2: Không thể đọc thông tin badging từ $apkPath"
    }

    # Label
    $labelLine = ($badging | Select-String "^application-label:'(.*)'" | Select-Object -First 1).Line
    if ($labelLine -ne "application-label:'$expectedLabel'") {
        throw "LỖI NHÃN ỨNG DỤNG: Nhận '$labelLine', kỳ vọng 'application-label:''$expectedLabel''' trong $apkPath"
    }

    # VersionName & VersionCode
    $pkgLine = ($badging | Select-String "^package:\s+" | Select-Object -First 1).Line
    if ($pkgLine -notmatch "versionName='$expectedVer'") {
        throw "LỖI PHIÊN BẢN (versionName): '$pkgLine' không chứa versionName='$expectedVer' trong $apkPath"
    }
    if ($pkgLine -notmatch "versionCode='$expectedCode'") {
        throw "LỖI MÃ PHIÊN BẢN (versionCode): '$pkgLine' không chứa versionCode='$expectedCode' trong $apkPath"
    }

    # ABI native-code
    $abiLine = ($badging | Select-String "^native-code:\s+" | Select-Object -First 1).Line
    if ($abiLine -notmatch "'$expectedAbi'") {
        throw "LỖI KIẾN TRÚC ABI: '$abiLine' không chứa ABI '$expectedAbi' trong $apkPath"
    }

    # 2. Kiểm tra nội dung thực bên trong tệp APK (ZIP entries)
    Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
    $zip = [System.IO.Compression.ZipFile]::OpenRead($apkPath)
    try {
        $entryNames = $zip.Entries | ForEach-Object { $_.FullName }
        if (-not ($entryNames -contains "AndroidManifest.xml")) {
            throw "LỖI NỘI DUNG APK: $apkPath thiếu AndroidManifest.xml"
        }
        if (-not ($entryNames -contains "classes.dex")) {
            throw "LỖI NỘI DUNG APK: $apkPath thiếu classes.dex"
        }
        $appSo = $zip.Entries | Where-Object { $_.FullName -eq "lib/$expectedAbi/libapp.so" }
        if (-not $appSo -or $appSo.Length -le 0) {
            throw "LỖI NỘI DUNG APK: $apkPath thiếu thư viện mã máy lib/$expectedAbi/libapp.so hoặc tệp 0 byte"
        }
        $flutterSo = $zip.Entries | Where-Object { $_.FullName -eq "lib/$expectedAbi/libflutter.so" }
        if (-not $flutterSo -or $flutterSo.Length -le 0) {
            throw "LỖI NỘI DUNG APK: $apkPath thiếu thư viện động lib/$expectedAbi/libflutter.so hoặc tệp 0 byte"
        }
        $assetCount = ($zip.Entries | Where-Object { $_.FullName -like "assets/flutter_assets/*" }).Count
        if ($assetCount -le 0) {
            throw "LỖI NỘI DUNG APK: $apkPath thiếu thư mục tài nguyên assets/flutter_assets/"
        }
        Say ("Nội dung thực APK hợp lệ: libapp.so ({0:N1} MB), libflutter.so ({1:N1} MB), $assetCount assets" -f ($appSo.Length / 1MB), ($flutterSo.Length / 1MB))
    } finally {
        $zip.Dispose()
    }

    # 3. Kiểm tra nâng cấp tương thích từ 0.5.4 -> 0.5.5 cho ABI này
    $fileName = Split-Path $apkPath -Leaf
    $prevFileName = $fileName.Replace("-$expectedVer-", "-0.5.4-")
    $prevApkPath = Join-Path $KIT "output\0.5.4\$prevFileName"
    if (Test-Path $prevApkPath) {
        $prevBadging = & $aapt2 dump badging $prevApkPath 2>$null
        $prevPkgLine = ($prevBadging | Select-String "^package:\s+" | Select-Object -First 1).Line
        if ($prevPkgLine -match "versionCode='(\d+)'") {
            $prevCode = [int]$matches[1]
            $currentCode = [int]$expectedCode
            if ($currentCode -le $prevCode) {
                throw "LỖI NÂNG CẤP ABI: versionCode của $expectedVer ($currentCode) không lớn hơn 0.5.4 ($prevCode) cho ABI '$expectedAbi' tại $apkPath"
            }
            Say "XÁC MINH NÂNG CẤP ABI HỢP LỆ: $expectedAbi (0.5.4 code=$prevCode -> $expectedVer code=$currentCode)"
        }
    } else {
        Say "Lưu ý: Không tìm thấy tệp 0.5.4 đối chiếu ($prevFileName) để so sánh nâng cấp versionCode"
    }

    # 4. Xác minh chữ ký số bằng apksigner
    Say "Kiểm tra chữ ký số bằng apksigner..."
    $sigOutput = & cmd.exe /c "`"$apksigner`" verify --verbose `"$apkPath`" 2>&1"
    if ($LASTEXITCODE -ne 0) {
        throw "LỖI CHỮ KÝ APK: Chữ ký số không hợp lệ trong $apkPath`n$($sigOutput -join "`n")"
    }

    Say ("XÁC MINH THÀNH CÔNG: $(Split-Path $apkPath -Leaf) | Label: $expectedLabel | ABI: $expectedAbi | Ver: $expectedVer ($expectedCode) | Chữ ký: HỢP LỆ ({0:N1} MB)" -f ($len / 1MB))
}

function Verify-WindowsPackageContent([string]$outDir, [string]$ver) {
    Say "--- Kiểm tra toàn diện nội dung thực các gói Windows ---"
    Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue

    # 1. Kiểm tra Portable ZIP
    $zipPath = "$outDir\YomiHub-$ver-windows-x64.zip"
    if (-not (Test-Path $zipPath)) { throw "LỖI ARTIFACT THIẾU: Không tìm thấy $zipPath" }
    $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
    try {
        $entries = $zip.Entries | ForEach-Object { $_.FullName }
        if (-not ($entries -contains "YomiHub.exe")) {
            throw "LỖI NỘI DUNG WINDOWS ZIP: $zipPath thiếu YomiHub.exe"
        }
        if (-not ($entries -contains "flutter_windows.dll")) {
            throw "LỖI NỘI DUNG WINDOWS ZIP: $zipPath thiếu flutter_windows.dll"
        }
        if (-not ($entries -contains "libisar.dll")) {
            throw "LỖI NỘI DUNG WINDOWS ZIP: $zipPath thiếu libisar.dll"
        }
        $appSo = $zip.Entries | Where-Object { $_.FullName -like "*data/app.so*" -or $_.FullName -like "*data\app.so*" }
        if (-not $appSo -or $appSo.Length -le 0) {
            throw "LỖI NỘI DUNG WINDOWS ZIP: $zipPath thiếu data/app.so hoặc tệp 0 byte"
        }
        $dllCount = ($zip.Entries | Where-Object { $_.FullName -like "*.dll" }).Count
        if ($dllCount -lt 30) {
            throw "LỖI NỘI DUNG WINDOWS ZIP: $zipPath chỉ chứa $dllCount DLLs, kỳ vọng tối thiểu 30 DLLs"
        }
        Say ("Xác minh Portable ZIP thành công: YomiHub.exe, flutter_windows.dll, libisar.dll, data/app.so, $dllCount DLLs ({0:N1} MB)" -f ((Get-Item $zipPath).Length / 1MB))
    } finally {
        $zip.Dispose()
    }

    # 2. Kiểm tra Full ZIP (kèm MES JRE)
    $fullZipPath = "$outDir\YomiHub-$ver-windows-x64-full.zip"
    if (-not (Test-Path $fullZipPath)) { throw "LỖI ARTIFACT THIẾU: Không tìm thấy $fullZipPath" }
    $fullZip = [System.IO.Compression.ZipFile]::OpenRead($fullZipPath)
    try {
        $hasJar = ($fullZip.Entries | Where-Object { $_.FullName -like "*yomihub_bin/mes/*.jar*" -or $_.FullName -like "*yomihub_bin\mes\*.jar*" }).Count -gt 0
        if (-not $hasJar) {
            throw "LỖI NỘI DUNG WINDOWS FULL ZIP: $fullZipPath thiếu MExtensionServer JAR trong yomihub_bin/mes/"
        }
        $hasJava = ($fullZip.Entries | Where-Object { $_.FullName -like "*yomihub_bin/mes/jre*java.exe*" -or $_.FullName -like "*yomihub_bin\mes\jre*java.exe*" }).Count -gt 0
        if (-not $hasJava) {
            throw "LỖI NỘI DUNG WINDOWS FULL ZIP: $fullZipPath thiếu Java JRE nhúng trong yomihub_bin/mes/jre"
        }
        Say ("Xác minh Full ZIP thành công: Đầy đủ MExtensionServer và nhúng JRE ({0:N1} MB)" -f ((Get-Item $fullZipPath).Length / 1MB))
    } finally {
        $fullZip.Dispose()
    }

    # 3. Kiểm tra Inno Setup .exe
    $setupExe = "$outDir\YomiHub-$ver-windows-x64-Setup.exe"
    if (-not (Test-Path $setupExe)) { throw "LỖI ARTIFACT THIẾU: Không tìm thấy $setupExe" }
    $setupLen = (Get-Item $setupExe).Length
    if ($setupLen -lt 50MB) {
        throw "LỖI ARTIFACT HỎNG: $setupExe có dung lượng bất thường ({0:N1} MB < 50 MB)" -f ($setupLen / 1MB)
    }
    # Kiểm tra PE header (MZ)
    $fs = [System.IO.File]::OpenRead($setupExe)
    $buf = New-Object byte[] 2
    $fs.Read($buf, 0, 2) | Out-Null
    $fs.Close()
    if ($buf[0] -ne 0x4D -or $buf[1] -ne 0x5A) {
        throw "LỖI ĐỊNH DẠNG SETUP: $setupExe không có PE executable header (MZ)"
    }
    Say ("Xác minh Setup.exe thành công: PE header MZ hợp lệ ({0:N1} MB)" -f ($setupLen / 1MB))

    # 4. Kiểm tra AppxBundle
    $appxBundle = "$outDir\YomiHub-$ver-windows-x64.appxbundle"
    if (-not (Test-Path $appxBundle)) { throw "LỖI ARTIFACT THIẾU: Không tìm thấy $appxBundle" }
    $appxZip = [System.IO.Compression.ZipFile]::OpenRead($appxBundle)
    try {
        $appxEntries = $appxZip.Entries | ForEach-Object { $_.FullName }
        if (-not ($appxEntries -contains "AppxMetadata/AppxBundleManifest.xml")) {
            throw "LỖI NỘI DUNG APPX: $appxBundle thiếu AppxMetadata/AppxBundleManifest.xml"
        }
        if (-not ($appxEntries -contains "AppxSignature.p7x")) {
            throw "LỖI NỘI DUNG APPX: $appxBundle thiếu AppxSignature.p7x"
        }
        $innerAppx = $appxZip.Entries | Where-Object { $_.FullName -like "*.appx" }
        if (-not $innerAppx -or $innerAppx.Length -le 0) {
            throw "LỖI NỘI DUNG APPX: $appxBundle thiếu gói con .appx bên trong"
        }
        Say ("Xác minh AppxBundle thành công: Manifest, AppxSignature.p7x, và payload .appx ({0:N1} MB)" -f ((Get-Item $appxBundle).Length / 1MB))
    } finally {
        $appxZip.Dispose()
    }

    # 5. Kiểm tra Certificate Root CA
    $certPath = "$outDir\YomiHub-RootCA.cer"
    if (-not (Test-Path $certPath)) { throw "LỖI ARTIFACT THIẾU: Không tìm thấy $certPath" }
    $cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($certPath)
    if ($cert.Thumbprint -ne '4C62D3C542A9EE3B0136F9AE49E65C0E38652A49') {
        throw "LỖI CHỨNG CHỈ: Thumbprint nhận được '$($cert.Thumbprint)', kỳ vọng '4C62D3C542A9EE3B0136F9AE49E65C0E38652A49'"
    }
    Say "Xác minh Chứng chỉ YomiHub-RootCA.cer thành công: Thumbprint 4C62D3C542A9EE3B0136F9AE49E65C0E38652A49"

    # 6. Kiểm tra Script cài đặt
    foreach ($scriptName in 'Install-YomiHub.bat', 'Install-YomiHub.ps1') {
        $sp = "$outDir\$scriptName"
        if (-not (Test-Path $sp) -or (Get-Item $sp).Length -le 0) {
            throw "LỖI SCRIPT THIẾU: Không tìm thấy script cài đặt $sp hoặc tệp 0 byte"
        }
    }
    Say "Xác minh Script cài đặt Install-YomiHub.bat và Install-YomiHub.ps1 thành công"

    # 7. Kiểm tra SHA256SUMS.txt
    $sumsPath = "$outDir\SHA256SUMS-$ver.txt"
    if (-not (Test-Path $sumsPath)) { throw "LỖI ARTIFACT THIẾU: Không tìm thấy $sumsPath" }
    $sumsContent = Get-Content $sumsPath
    $expectedFiles = @(
        "YomiHub-$ver-arm64-v8a.apk",
        "YomiHub-$ver-armeabi-v7a.apk",
        "YomiHub-$ver-x86_64.apk",
        "YumiHub-Android-TV-$ver-arm64-v8a.apk",
        "YumiHub-Android-TV-$ver-armeabi-v7a.apk",
        "YumiHub-Android-TV-$ver-x86_64.apk",
        "YomiHub-$ver-windows-x64.zip",
        "YomiHub-$ver-windows-x64-full.zip",
        "YomiHub-$ver-windows-x64-Setup.exe",
        "YomiHub-$ver-windows-x64.appxbundle",
        "YomiHub-RootCA.cer",
        "Install-YomiHub.bat",
        "Install-YomiHub.ps1"
    )
    foreach ($ef in $expectedFiles) {
        if (-not ($sumsContent | Select-String "\s+$ef$")) {
            throw "LỖI BẢNG BĂM: $sumsPath thiếu mục kiểm tra cho $ef"
        }
    }
    Say "Xác minh Bảng băm SHA256SUMS-$ver.txt thành công: Đầy đủ các gói phân phối"
}

function Verify-AllPackages([string]$outDir, [string]$ver, [string]$code) {
    Say "=== BẮT ĐẦU XÁC MINH NỘI DUNG THỰC TOÀN BỘ CÁC GÓI ĐÃ ĐÓNG GÓI (VERIFY PACKAGE) ==="
    # 1. Xác minh 3 APK Mobile
    foreach ($abi in @('arm64-v8a', 'armeabi-v7a', 'x86_64')) {
        $apk = "$outDir\YomiHub-$ver-$abi.apk"
        $expectedCode = Get-ExpectedVersionCode -abi $abi -baseCode ([int]$code)
        Verify-ApkDetails $apk 'YomiHub' $abi $ver $expectedCode
    }
    # 2. Xác minh 3 APK Android TV
    foreach ($abi in @('arm64-v8a', 'armeabi-v7a', 'x86_64')) {
        $apk = "$outDir\YumiHub-Android-TV-$ver-$abi.apk"
        $expectedCode = Get-ExpectedVersionCode -abi $abi -baseCode ([int]$code)
        Verify-ApkDetails $apk 'YumiHub Android TV' $abi $ver $expectedCode
    }
    # 3. Xác minh toàn bộ các gói Windows
    Verify-WindowsPackageContent $outDir $ver
    Say "=== TẤT CẢ GÓI APK VÀ WINDOWS ĐÃ ĐƯỢC XÁC MINH NỘI DUNG THỰC THÀNH CÔNG (100% ĐẠT) ==="
}

if ($step -eq 'none') {
    return
}

$out = Join-Path $KIT "output\0.5.6"
New-Item -ItemType Directory -Force $out | Out-Null

$pubspecRaw = Get-Content "$abld\pubspec.yaml" -Raw
$verMatch = [regex]::Match($pubspecRaw, '(?m)^version:\s*([0-9\.]+)\+?([0-9]*)')
$ver = $verMatch.Groups[1].Value
$code = $verMatch.Groups[2].Value

if ($ver -ne '0.5.6') { throw "Phiên bản pubspec là '$ver', kỳ vọng '0.5.6'" }
if (-not $code) { $code = '48' }

$targetAbis = @('arm64-v8a', 'armeabi-v7a', 'x86_64')

try {
    Say "=== BẮT ĐẦU QUY TRÌNH BUILD YOMIHUB 0.5.6 (step=$step, ver=$ver+$code) ==="
    $env:PATH = "$TOOLS\android-sdk\cmake\3.22.1\bin;" + $env:PATH
    $env:CARGO_HTTP_MULTIPLEXING = "false"
    $env:CARGO_NET_RETRY = "10"

    # BƯỚC 1: KIỂM THỬ TĨNH & ĐƠN VỊ
    if ($step -in 'all', 'test') {
        Push-Location $abld
        Remove-Item "$LOGS\b056_analyze.txt", "$LOGS\b056_test.txt" -ErrorAction SilentlyContinue
        Run 'flutter.bat' @('pub', 'get', '--offline') 'b056_pub_get.txt'
        Run 'flutter.bat' @('gen-l10n') 'b056_gen_l10n.txt'
        Run 'dart.bat' @('analyze', '--no-fatal-warnings', 'lib/repositories/db_write_queue.dart') 'b056_analyze.txt'
        Pop-Location
    }

    if ($step -in 'all', 'test', 'unit') {
        Push-Location $abld
        # Bắt buộc chạy cả onboarding D-pad test, test 0.5.6 mới, và test 0.5.4 cùng các test hồi quy
        Say "Chạy bộ kiểm thử tự động toàn diện..."
        Run 'flutter.bat' @(
            'test', '--no-pub',
            'test/widgets/onboarding_screen_test.dart',
            'test/yh_055_test.dart',
            'test/yh_054_test.dart',
            'test/yh_053_test.dart',
            'test/yh_052_test.dart',
            'test/yh_051_test.dart',
            'test/yh_050_test.dart',
            'test/yh_049_test.dart',
            'test/yh_048_test.dart',
            'test/yh_047_test.dart',
            'test/yh_046_test.dart',
            'test/yh_045_test.dart',
            'test/yh_044_test.dart',
            'test/yh_043_test.dart',
            'test/yh_042_test.dart',
            'test/yh_041_test.dart',
            'test/yh_040_test.dart'
        ) 'b056_test.txt'
        Pop-Location
    }

    # BƯỚC 2: BUILD APK MOBILE (BẮT THIẾU ARTIFACT & XÁC MINH CHỮ KÝ)
    if ($step -in 'all', 'apk') {
        Set-AppName 'YomiHub'
        Push-Location $abld
        Run 'flutter.bat' @('build', 'apk', '--no-pub', '--release', '--split-per-abi', '--target-platform', 'android-arm,android-arm64,android-x64', '--split-debug-info', "$YH\symbols") 'b056_apk.txt'
        
        foreach ($abi in $targetAbis) {
            $f = "$abld\build\app\outputs\flutter-apk\app-$abi-release.apk"
            if (-not (Test-Path $f)) {
                throw "LỖI ARTIFACT THIẾU: Quá trình build không tạo ra APK cho ABI '$abi' tại $f"
            }
            $destApk = "$out\YomiHub-$ver-$abi.apk"
            Copy-Item $f $destApk -Force
            # Tính expectedCode theo đúng quy tắc ABI split của Flutter
            $expectedAbiCode = Get-ExpectedVersionCode -abi $abi -baseCode ([int]$code)
            # Xác minh nhãn, ABI, versionCode, versionName, kiểm tra nâng cấp từ 0.5.4, và chữ ký
            Verify-ApkDetails $destApk 'YomiHub' $abi $ver $expectedAbiCode
        }
        Pop-Location
    }

    # BƯỚC 3: BUILD APK ANDROID TV (BẮT THIẾU ARTIFACT & XÁC MINH CHỮ KÝ)
    if ($step -in 'all', 'tv') {
        Push-Location $abld
        Set-AppName 'YumiHub Android TV'
        try {
            Run 'flutter.bat' @(
                'build', 'apk', '--no-pub', '--release', '--split-per-abi',
                '--target-platform', 'android-arm,android-arm64,android-x64',
                '--split-debug-info', "$YH\symbols_tv",
                '--dart-define=IS_TV_BUILD=true',
                '--dart-define=APP_NAME=YumiHub Android TV'
            ) 'b056_tv.txt'

            foreach ($abi in $targetAbis) {
                $f = "$abld\build\app\outputs\flutter-apk\app-$abi-release.apk"
                if (-not (Test-Path $f)) {
                    throw "LỖI ARTIFACT THIẾU: Quá trình build không tạo ra TV APK cho ABI '$abi' tại $f"
                }
                $destApk = "$out\YumiHub-Android-TV-$ver-$abi.apk"
                Copy-Item $f $destApk -Force
                # Tính expectedCode theo đúng quy tắc ABI split của Flutter
                $expectedAbiCode = Get-ExpectedVersionCode -abi $abi -baseCode ([int]$code)
                # Xác minh nhãn, ABI, versionCode, versionName, kiểm tra nâng cấp từ 0.5.4, và chữ ký
                Verify-ApkDetails $destApk 'YumiHub Android TV' $abi $ver $expectedAbiCode
            }
        } finally {
            Set-AppName 'YomiHub'
            Pop-Location
        }
    }

    # BƯỚC 4: BUILD WINDOWS (X64, BẮT THIẾU ARTIFACT)
    if ($step -in 'all', 'win') {
        $ng = "$TOOLS\nuget"
        $env:PATH = "$ng;" + $env:PATH
        $bld = $wbld
        Remove-Item "$bld\build\windows\x64\CMakeCache.txt" -ErrorAction SilentlyContinue
        Push-Location $bld
        Run 'flutter.bat' @('pub', 'get', '--offline') 'b056_win_pub_get.txt'
        Run 'flutter.bat' @('gen-l10n') 'b056_win_gen_l10n.txt'
        Run 'flutter.bat' @('build', 'windows', '--no-pub', '--release') 'b056_win_build.txt'
        Pop-Location

        $rel = "$bld\build\windows\x64\runner\Release"
        if (-not (Test-Path "$rel\YomiHub.exe")) {
            throw "LỖI ARTIFACT THIẾU: Không tìm thấy YomiHub.exe tại $rel\YomiHub.exe"
        }

        # Gói VC++ Redistributable
        $crt = Get-ChildItem "C:\Program Files*\Microsoft Visual Studio\*\*\VC\Redist\MSVC\*\x64\Microsoft.VC14*.CRT" -Directory -ErrorAction SilentlyContinue | Sort-Object FullName | Select-Object -Last 1
        if ($crt) {
            foreach ($n in 'msvcp140.dll', 'msvcp140_1.dll', 'msvcp140_2.dll', 'vcruntime140.dll', 'vcruntime140_1.dll', 'concrt140.dll') {
                Copy-Item "$($crt.FullName)\$n" $rel -Force -ErrorAction SilentlyContinue
            }
            Say "VC++ runtime bundled từ $($crt.FullName)"
        }

        # Gói VPN helpers (xray, tor)
        $deps = "$YH\win_deps"
        $bin = "$rel\yomihub_bin"
        Remove-Item $bin -Recurse -Force -ErrorAction SilentlyContinue
        New-Item -ItemType Directory -Force "$bin\tor\pluggable_transports" | Out-Null
        if (Test-Path "$deps\xray\xray.exe") {
            Copy-Item "$deps\xray\xray.exe" $bin
            Copy-Item "$deps\xray\LICENSE" "$bin\LICENSE-xray.txt" -ErrorAction SilentlyContinue
            Copy-Item "$deps\tor\tor\tor.exe" "$bin\tor"
            Copy-Item "$deps\tor\data\geoip" "$bin\tor"
            Copy-Item "$deps\tor\tor\pluggable_transports\lyrebird.exe" "$bin\tor\pluggable_transports"
            Copy-Item "$deps\tor\tor\pluggable_transports\pt_config.json" "$bin\tor\pluggable_transports"
            Copy-Item "$deps\tor\docs\tor.txt" "$bin\tor\LICENSE-tor.txt" -ErrorAction SilentlyContinue
            Copy-Item "$deps\tor\docs\lyrebird.txt" "$bin\tor\LICENSE-lyrebird.txt" -ErrorAction SilentlyContinue
            Say "yomihub_bin: xray + tor đã được tích hợp"
        }

        # JVM bridge
        $br = "$bld\tools\yomihub_bridge"
        if (Test-Path "$br\build.gradle") {
            $g = Get-ChildItem "$YH\gradle-home\wrapper\dists\gradle-9.3.1-bin" -Recurse -Filter gradle.bat | Select-Object -First 1
            Push-Location $br
            & $g.FullName --no-daemon --console=plain installDist *>&1 | Tee-Object -FilePath "$LOGS\win_bridge_056.txt" | Out-Null
            Pop-Location
            $bl = "$br\build\install\yomihub-bridge\lib"
            if (Test-Path "$bl\yomihub-bridge-0.2.1.jar") {
                New-Item -ItemType Directory -Force "$bin\bridge\lib" | Out-Null
                Copy-Item "$bl\*.jar" "$bin\bridge\lib" -Force
                Say ("yomihub_bin\bridge: {0} jars ({1:N1} MB)" -f (Get-ChildItem "$bin\bridge\lib").Count, ((Get-ChildItem "$bin\bridge\lib" | Measure-Object Length -Sum).Sum / 1MB))
            }
        }

        # Đóng gói ZIP Portable
        $zip = "$out\YomiHub-$ver-windows-x64.zip"
        Remove-Item $zip -ErrorAction SilentlyContinue
        Compress-Archive -Path "$rel\*" -DestinationPath $zip -CompressionLevel Optimal
        if (-not (Test-Path $zip)) { throw "LỖI ARTIFACT THIẾU: Không tạo được file ZIP portable $zip" }
        Say ("TẠO THÀNH CÔNG: {0} ({1:N1} MB)" -f (Split-Path $zip -Leaf), ((Get-Item $zip).Length / 1MB))

        # Đóng gói ZIP Full (kèm MES JRE)
        if (Test-Path "$deps\mes-windows-x64-bundle.zip") {
            Expand-Archive "$deps\mes-windows-x64-bundle.zip" "$bin\mes" -Force
            $zipF = "$out\YomiHub-$ver-windows-x64-full.zip"
            Remove-Item $zipF -ErrorAction SilentlyContinue
            Compress-Archive -Path "$rel\*" -DestinationPath $zipF -CompressionLevel Optimal
            if (-not (Test-Path $zipF)) { throw "LỖI ARTIFACT THIẾU: Không tạo được file ZIP full $zipF" }
            Say ("TẠO THÀNH CÔNG FULL: {0} ({1:N1} MB)" -f (Split-Path $zipF -Leaf), ((Get-Item $zipF).Length / 1MB))
        }
    }

    # BƯỚC 5: ĐÓNG GÓI SETUP.EXE & .APPXBUNDLE (BẮT THIẾU ARTIFACT)
    if ($step -in 'all', 'pack') {
        $srcZip = if (Test-Path "$out\YomiHub-$ver-windows-x64-full.zip") { "$out\YomiHub-$ver-windows-x64-full.zip" } else { "$out\YomiHub-$ver-windows-x64.zip" }
        if (-not (Test-Path $srcZip)) {
            throw "LỖI ARTIFACT THIẾU: Payload ZIP để đóng gói installer không tồn tại: $srcZip"
        }
        Say "Installer payload: $(Split-Path $srcZip -Leaf)"
        Copy-Item $srcZip "$KIT\output\YomiHub-$ver-windows-x64.zip" -Force

        $requiredPackItems = @(
            "YomiHub-$ver-windows-x64-Setup.exe",
            "YomiHub-$ver-windows-x64.appxbundle",
            "YomiHub-RootCA.cer",
            "Install-YomiHub.bat",
            "Install-YomiHub.ps1"
        )

        # Xóa các gói cũ trong output trước khi đóng gói để tránh nhận nhầm
        foreach ($n in $requiredPackItems) {
            Remove-Item "$KIT\output\$n" -Force -ErrorAction SilentlyContinue
        }

        Say "Đang thực thi make_installer_exe.ps1..."
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$KIT\make_installer_exe.ps1"
        if ($LASTEXITCODE -ne 0) {
            throw "LỖI ĐÓNG GÓI: make_installer_exe.ps1 kết thúc với mã lỗi $LASTEXITCODE"
        }
        $installerExe = "$KIT\output\YomiHub-$ver-windows-x64-Setup.exe"
        if (-not (Test-Path $installerExe) -or ((Get-Item $installerExe).Length -le 0)) {
            throw "LỖI ARTIFACT: make_installer_exe.ps1 không tạo ra tệp $installerExe hoặc tệp 0 byte"
        }
        Say "make_installer_exe.ps1 hoàn tất thành công (exit $LASTEXITCODE, {0:N1} MB)" -f ((Get-Item $installerExe).Length / 1MB)

        Remove-Item "$KIT\output\YomiHub-$ver-windows-x64.zip" -ErrorAction SilentlyContinue

        Say "Đang thực thi make_appxbundle.ps1..."
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$KIT\make_appxbundle.ps1"
        if ($LASTEXITCODE -ne 0) {
            throw "LỖI ĐÓNG GÓI: make_appxbundle.ps1 kết thúc với mã lỗi $LASTEXITCODE"
        }
        $appxFile = "$KIT\output\YomiHub-$ver-windows-x64.appxbundle"
        if (-not (Test-Path $appxFile) -or ((Get-Item $appxFile).Length -le 0)) {
            throw "LỖI ARTIFACT: make_appxbundle.ps1 không tạo ra tệp $appxFile hoặc tệp 0 byte"
        }
        Say "make_appxbundle.ps1 hoàn tất thành công (exit $LASTEXITCODE, {0:N1} MB)" -f ((Get-Item $appxFile).Length / 1MB)

        foreach ($n in $requiredPackItems) {
            $packSrc = "$KIT\output\$n"
            $packDest = "$out\$n"
            if (-not (Test-Path $packSrc)) {
                throw "LỖI ARTIFACT THIẾU: Không tìm thấy gói đã đóng gói $n tại $packSrc"
            }
            Move-Item $packSrc $packDest -Force
            Say "Đã xuất bản gói Windows: $n ({0:N1} MB)" -f ((Get-Item $packDest).Length / 1MB)
        }

        # Tạo bảng băm SHA256 cho toàn bộ thư mục output
        Get-ChildItem $out -File | Where-Object { $_.Extension -in '.apk', '.exe', '.zip', '.appxbundle' } | ForEach-Object {
            "{0}  {1}" -f (Get-FileHash $_.FullName -Algorithm SHA256).Hash.ToLower(), $_.Name
        } | Set-Content "$out\SHA256SUMS-$ver.txt" -Encoding ascii
        Say "Bảng băm SHA256SUMS-$ver.txt đã được tạo thành công!"
    }

    # BƯỚC 6: XÁC MINH TOÀN DIỆN NỘI DUNG THỰC CÁC GÓI ĐÃ ĐÓNG GÓI (VERIFY PACKAGE)
    if ($step -in 'all', 'verify', 'verify-package', 'verify_package') {
        Verify-AllPackages -outDir $out -ver $ver -code $code
    }

    Say "=== QUY TRÌNH BUILD YOMIHUB 0.5.6 HOÀN TẤT THÀNH CÔNG (step=$step) ==="
} catch {
    Say "LỖI NGHIÊM TRỌNG: $($_.Exception.Message)"
    if ($host -and $host.SetShouldExit) {
        $host.SetShouldExit(1)
    }
    exit 1
} finally {
    Pop-Location -ErrorAction SilentlyContinue
    Stop-Transcript | Out-Null
}
