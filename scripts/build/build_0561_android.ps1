[CmdletBinding()]
param(
    [ValidateSet('all', 'test', 'unit', 'apk', 'tv', 'a6', 'verify', 'verify-package', 'verify_package', 'none')]
    [string]$step = 'all'
)

# build_0561_android.ps1 - YomiHub 0.5.6.1 (pubspec 0.5.6+49): dung THAT 3 APK dien thoai + 3 APK Android TV,
# chep 3 APK android6 vao output\0.5.6.1, kiem nhan/versionName/versionCode theo ABI/ABI/noi dung/chu ky.
#   -step test|unit : pub get, gen-l10n, analyze, flutter test (gom test VPN 0.5.6.1)
#   -step apk | tv  : flutter build apk --split-per-abi --build-name 0.5.6.1 --build-number 49 (khong co nhanh gia)
#   -step a6        : chep + kiem 3 APK android6 tu audit-0.5.7\android6\out (phai dung lai bang build_0561_android6.ps1 voi build-number 49)
#   -step verify    : kiem lai toan bo APK trong output\0.5.6.1
# Windows (win/pack) nam trong build_0561.ps1. Giu audit-0.5.6\coordination\BUILD_LOCK.txt ("B0561 <gio>") o test/apk/tv.
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$root = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Item .).FullName }
$skipFile = Join-Path $root "audit-0.5.7\SKIP_STEPS"
if ((Test-Path $skipFile) -and ((Get-Content $skipFile -Raw) -split '\s+' -contains $step)) {
    Write-Host "Bỏ qua step $step do khai báo trong SKIP_STEPS" -ForegroundColor Yellow
    exit 0
}

. "$root\common.ps1"

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$buildLogPath = Join-Path $LOGS "build0561_android_${step}_$stamp.txt"
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

$lockFile = Join-Path $root "audit-0.5.6\coordination\BUILD_LOCK.txt"
$lockWaitMin = 60
$script:locked = $false
function Lock-Build {
    $t0 = Get-Date
    while ($true) {
        $c = "$(Get-Content $lockFile -Raw -ErrorAction SilentlyContinue)".Trim([char]0xFEFF, ' ', "`r", "`n")
        if (-not $c) { break }
        if (((Get-Date) - $t0).TotalMinutes -gt $lockWaitMin) { throw "BUILD_LOCK đang bị giữ: '$c' (đã chờ $lockWaitMin phút)" }
        Say "BUILD_LOCK đang bị giữ: '$c' - chờ 30 giây"; Start-Sleep 30
    }
    Set-Content $lockFile ('B0561 ' + (Get-Date -Format 'HH:mm')) -Encoding UTF8
    $script:locked = $true; Say 'Đã giữ BUILD_LOCK'
}
function Unlock-Build {
    if (-not $script:locked) { return }
    $c = "$(Get-Content $lockFile -Raw -ErrorAction SilentlyContinue)".Trim([char]0xFEFF, ' ', "`r", "`n")
    if ($c -match '^B0561') { Set-Content $lockFile '' -NoNewline; Say 'Đã trả BUILD_LOCK' }
    $script:locked = $false
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

    # 3. Kiểm tra nâng cấp tương thích từ 0.5.6 -> 0.5.6.1 cho ABI này
    $fileName = Split-Path $apkPath -Leaf
    $prevFileName = $fileName.Replace("-$expectedVer-", "-0.5.6-")
    $prevApkPath = Join-Path $KIT "output\0.5.6\$prevFileName"
    if (Test-Path $prevApkPath) {
        $prevBadging = & $aapt2 dump badging $prevApkPath 2>$null
        $prevPkgLine = ($prevBadging | Select-String "^package:\s+" | Select-Object -First 1).Line
        if ($prevPkgLine -match "versionCode='(\d+)'") {
            $prevCode = [int]$matches[1]
            $currentCode = [int]$expectedCode
            if ($currentCode -le $prevCode) {
                throw "LỖI NÂNG CẤP ABI: versionCode của $expectedVer ($currentCode) không lớn hơn 0.5.6 ($prevCode) cho ABI '$expectedAbi' tại $apkPath"
            }
            Say "XÁC MINH NÂNG CẤP ABI HỢP LỆ: $expectedAbi (0.5.6 code=$prevCode -> $expectedVer code=$currentCode)"
        }
    } else {
        Say "Lưu ý: Không tìm thấy tệp 0.5.6 đối chiếu ($prevFileName) để so sánh nâng cấp versionCode"
    }

    # 4. Xác minh chữ ký số bằng apksigner
    Say "Kiểm tra chữ ký số bằng apksigner..."
    $sigOutput = & cmd.exe /c "`"$apksigner`" verify --verbose `"$apkPath`" 2>&1"
    if ($LASTEXITCODE -ne 0) {
        throw "LỖI CHỮ KÝ APK: Chữ ký số không hợp lệ trong $apkPath`n$($sigOutput -join "`n")"
    }

    Say ("XÁC MINH THÀNH CÔNG: $(Split-Path $apkPath -Leaf) | Label: $expectedLabel | ABI: $expectedAbi | Ver: $expectedVer ($expectedCode) | Chữ ký: HỢP LỆ ({0:N1} MB)" -f ($len / 1MB))
}

function Verify-AllPackages([string]$outDir, [string]$ver, [string]$code) {
    Say "=== XÁC MINH NỘI DUNG THỰC CÁC APK 0.5.6.1 (VERIFY PACKAGE) ==="
    foreach ($abi in @('arm64-v8a', 'armeabi-v7a', 'x86_64')) {
        Verify-ApkDetails "$outDir\YomiHub-$ver-$abi.apk" 'YomiHub' $abi $ver (Get-ExpectedVersionCode -abi $abi -baseCode ([int]$code))
    }
    foreach ($abi in @('arm64-v8a', 'armeabi-v7a', 'x86_64')) {
        Verify-ApkDetails "$outDir\YumiHub-Android-TV-$ver-$abi.apk" 'YumiHub Android TV' $abi $ver (Get-ExpectedVersionCode -abi $abi -baseCode ([int]$code))
    }
    foreach ($abi in @('arm64-v8a', 'armeabi-v7a', 'x86_64')) {
        $a6 = "$outDir\YomiHub-$ver-android6-$abi.apk"
        Verify-ApkDetails $a6 'YomiHub' $abi $ver (Get-ExpectedVersionCode -abi $abi -baseCode ([int]$code))
        $bad = & $aapt2 dump badging $a6 2>$null
        $sdk = ($bad | Select-String "^(?:min)?[sS]dkVersion:'(\d+)'" | Select-Object -First 1).Matches[0].Groups[1].Value
        if ($sdk -ne '23') { throw "LỖI ANDROID 6: $a6 có minSdkVersion '$sdk' (cần 23)" }
    }
    Say "=== TẤT CẢ 9 APK ĐÃ ĐƯỢC XÁC MINH (100% ĐẠT) ==="
}

if ($step -eq 'none') {
    return
}

$out = Join-Path $KIT "output\0.5.6.1"
New-Item -ItemType Directory -Force $out | Out-Null

$pubspecRaw = Get-Content "$abld\pubspec.yaml" -Raw
$verMatch = [regex]::Match($pubspecRaw, '(?m)^version:\s*([0-9\.]+)\+?([0-9]*)')
$pubVer = $verMatch.Groups[1].Value
$code = $verMatch.Groups[2].Value
if ($pubVer -ne '0.5.6') { throw "Phiên bản pubspec là '$pubVer', kỳ vọng '0.5.6' (0.5.6.1 = versionName hiển thị, truyền bằng --build-name)" }
if ($code -ne '49') { throw "Build number pubspec là '$code', kỳ vọng '49' (sync_0561.ps1 chưa chạy?)" }
$ver = '0.5.6.1'   # versionName hiển thị (--build-name)

$targetAbis = @('arm64-v8a', 'armeabi-v7a', 'x86_64')

try {
    Say "=== BẮT ĐẦU QUY TRÌNH BUILD YOMIHUB 0.5.6.1 (step=$step, ver=$ver, build=$code) ==="
    $env:PATH = "$TOOLS\android-sdk\cmake\3.22.1\bin;" + $env:PATH
    $env:CARGO_HTTP_MULTIPLEXING = "false"
    $env:CARGO_NET_RETRY = "10"

    if ($step -in 'all', 'test', 'unit', 'apk', 'tv') { Lock-Build }

    # BƯỚC 1: KIỂM THỬ TĨNH & ĐƠN VỊ
    if ($step -in 'all', 'test') {
        Push-Location $abld
        Remove-Item "$LOGS\b0561_analyze.txt", "$LOGS\b0561_test.txt" -ErrorAction SilentlyContinue
        Run 'flutter.bat' @('pub', 'get', '--offline') 'b0561_pub_get.txt'
        Run 'flutter.bat' @('gen-l10n') 'b0561_gen_l10n.txt'
        Run 'dart.bat' @('analyze', '--no-fatal-warnings', 'lib/repositories/db_write_queue.dart', 'lib/yomihub/vpn', 'lib/yomihub/app_identity.dart') 'b0561_analyze.txt'
        Pop-Location
    }

    if ($step -in 'all', 'test', 'unit') {
        Push-Location $abld
        # Bắt buộc chạy cả onboarding D-pad test, test 0.5.6 mới, và test 0.5.4 cùng các test hồi quy
        Say "Chạy bộ kiểm thử tự động toàn diện..."
        $testFiles = @('test/widgets/onboarding_screen_test.dart', 'test/yh_0561_vpn_resume_test.dart', 'test/yh_057_vpn_test.dart',
            'test/yh_056_a_test.dart', 'test/yh_056_test.dart', 'test/yh_056_part_c_test.dart', 'test/yh_056_c2_ui_test.dart', 'test/yh_056_r22_hub_phone_test.dart') +
            @(55, 54, 53, 52, 51, 50, 49, 48, 47, 46, 45, 44, 43, 42, 41, 40 | ForEach-Object { 'test/yh_{0:D3}_test.dart' -f $_ })
        $present = @($testFiles | Where-Object { Test-Path (Join-Path $abld $_) })
        $absent = @($testFiles | Where-Object { -not (Test-Path (Join-Path $abld $_)) })
        if ($absent.Count -gt 0) { Say ("CẢNH BÁO: bỏ qua test không có trong build dir: " + ($absent -join ', ')) }
        foreach ($must in 'test/yh_0561_vpn_resume_test.dart', 'test/yh_057_vpn_test.dart', 'test/yh_055_test.dart') {
            if ($present -notcontains $must) { throw "Thiếu test bắt buộc $must trong $abld (sync_0561.ps1 chưa chạy?)" }
        }
        Run 'flutter.bat' (@('test', '--no-pub') + $present) 'b0561_test.txt'
        Pop-Location
    }

    # BƯỚC 2: BUILD APK MOBILE (BẮT THIẾU ARTIFACT & XÁC MINH CHỮ KÝ)
    if ($step -in 'all', 'apk') {
        Set-AppName 'YomiHub'
        Push-Location $abld
        $apkStart = Get-Date
        Run 'flutter.bat' @('build', 'apk', '--no-pub', '--release', '--split-per-abi', '--target-platform', 'android-arm,android-arm64,android-x64', '--build-name', $ver, '--build-number', $code, '--split-debug-info', "$YH\symbols") 'b0561_apk.txt'
        
        foreach ($abi in $targetAbis) {
            $f = "$abld\build\app\outputs\flutter-apk\app-$abi-release.apk"
            if (-not (Test-Path $f)) {
                throw "LỖI ARTIFACT THIẾU: Quá trình build không tạo ra APK cho ABI '$abi' tại $f"
            }
            if ((Get-Item $f).LastWriteTime -lt $apkStart) { throw "LỖI APK CŨ: $f không được dựng lại trong lần chạy này (R19)" }
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
            $tvStart = Get-Date
            Run 'flutter.bat' @(
                'build', 'apk', '--no-pub', '--release', '--split-per-abi',
                '--target-platform', 'android-arm,android-arm64,android-x64',
                '--build-name', $ver, '--build-number', $code,
                '--split-debug-info', "$YH\symbols_tv",
                '--dart-define=IS_TV_BUILD=true',
                '--dart-define=APP_NAME=YumiHub Android TV'
            ) 'b0561_tv.txt'

            foreach ($abi in $targetAbis) {
                $f = "$abld\build\app\outputs\flutter-apk\app-$abi-release.apk"
                if (-not (Test-Path $f)) {
                    throw "LỖI ARTIFACT THIẾU: Quá trình build không tạo ra TV APK cho ABI '$abi' tại $f"
                }
                if ((Get-Item $f).LastWriteTime -lt $tvStart) { throw "LỖI APK CŨ: $f không được dựng lại trong lần chạy này (R19)" }
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

    # BƯỚC 4: CHÉP + KIỂM 3 APK ANDROID 6.0 (dựng bằng build_0561_android6.ps1)
    if ($step -in 'all', 'a6') {
        $a6out = Join-Path $root 'audit-0.5.7\android6\out'
        foreach ($abi in $targetAbis) {
            $a6src = "$a6out\YomiHub-$ver-android6-$abi.apk"
            if (-not (Test-Path $a6src)) { throw "LỖI ARTIFACT THIẾU: $a6src - chạy build_0561_android6.ps1 trước" }
            $expectedAbiCode = Get-ExpectedVersionCode -abi $abi -baseCode ([int]$code)
            # APK android6 phải được dựng lại sau khi nâng build-number lên 49; nếu versionCode cũ (48) sẽ báo lỗi ở đây
            Verify-ApkDetails $a6src 'YomiHub' $abi $ver $expectedAbiCode
            $destA6 = "$out\YomiHub-$ver-android6-$abi.apk"
            Copy-Item $a6src $destA6 -Force
            Say ("Đã chép {0} ({1:N1} MB)" -f (Split-Path $destA6 -Leaf), ((Get-Item $destA6).Length / 1MB))
        }
    }

    # BƯỚC 6: XÁC MINH TOÀN DIỆN NỘI DUNG THỰC CÁC GÓI ĐÃ ĐÓNG GÓI (VERIFY PACKAGE)
    if ($step -in 'verify', 'verify-package', 'verify_package') {
        Verify-AllPackages -outDir $out -ver $ver -code $code
    }

    Say "=== QUY TRÌNH BUILD YOMIHUB 0.5.6.1 (ANDROID) HOÀN TẤT THÀNH CÔNG (step=$step) ==="
} catch {
    Say "LỖI NGHIÊM TRỌNG: $($_.Exception.Message)"
    if ($host -and $host.SetShouldExit) {
        $host.SetShouldExit(1)
    }
    exit 1
} finally {
    Unlock-Build
    Pop-Location -ErrorAction SilentlyContinue
    Stop-Transcript | Out-Null
}
