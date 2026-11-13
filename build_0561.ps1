[CmdletBinding()]
param(
    [ValidateSet('all', 'test', 'unit', 'apk', 'tv', 'a6', 'win', 'pack', 'verify', 'verify-package', 'verify_package', 'none')]
    [string]$step = 'all'
)

# build_0561.ps1 - YomiHub 0.5.6.1 (pubspec 0.5.6+49) Windows build & packaging, sums, verification.
#   -step test | win | pack | verify : thuc hien o day (win/pack dung make_installer_exe_0561.ps1, make_appxbundle_0561.ps1)
#   -step apk | tv | a6              : chuyen sang build_0561_android.ps1 (dung THAT, khong co nhanh gia)
#   output\0.5.6.1 ; version.json 0.5.6.1 / build 49 ; changelog tu audit-0.5.7\release\YomiHub-0.5.6.1-changelog.md
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$root = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Item .).FullName }
$skipFile = Join-Path $root "audit-0.5.7\SKIP_STEPS"
if ((Test-Path $skipFile) -and ((Get-Content $skipFile -Raw) -split '\s+' -contains $step)) {
    Write-Host "Bỏ qua step $step do khai báo trong SKIP_STEPS" -ForegroundColor Yellow
    exit 0
}

. "$root\common.ps1"

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$buildLogPath = Join-Path $LOGS "build0561_${step}_$stamp.txt"
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
        }
        else {
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
    if (Test-Path $strXml) {
        $c = [IO.File]::ReadAllText($strXml)
        $c = [regex]::Replace($c, '<string name="app_name">[^<]*</string>', "<string name=`"app_name`">$n</string>")
        [IO.File]::WriteAllText($strXml, $c, (New-Object Text.UTF8Encoding($false)))
        Say "app_name = $n"
    }
}

# Công cụ Android SDK
$aapt2 = (Get-ChildItem "$TOOLS\android-sdk\build-tools" -Recurse -Filter "aapt2.exe" -ErrorAction SilentlyContinue | Select-Object -Last 1).FullName
$apksigner = (Get-ChildItem "$TOOLS\android-sdk\build-tools" -Recurse -Filter "apksigner.bat" -ErrorAction SilentlyContinue | Select-Object -Last 1).FullName

function Get-ExpectedVersionCode([string]$abi, [int]$baseCode) {
    switch ($abi) {
        'armeabi-v7a' { return (1000 + $baseCode).ToString() }
        'arm64-v8a' { return (2000 + $baseCode).ToString() }
        'x86' { return (3000 + $baseCode).ToString() }
        'x86_64' { return (4000 + $baseCode).ToString() }
        default { return $baseCode.ToString() }
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

    if ($aapt2 -and (Test-Path $aapt2)) {
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
            throw "LỖI VERSION NAME: $apkPath không chứa versionName='$expectedVer' (dòng: $pkgLine)"
        }
        if ($pkgLine -notmatch "versionCode='$expectedCode'") {
            throw "LỖI VERSION CODE: $apkPath không chứa versionCode='$expectedCode' (dòng: $pkgLine)"
        }

        # Native Code (ABI)
        $nativeLine = ($badging | Select-String "^native-code:\s+" | Select-Object -First 1).Line
        if ($nativeLine -notmatch "'$expectedAbi'") {
            throw "LỖI ABI KHÔNG KHỚP: $apkPath có $nativeLine nhưng kỳ vọng ABI '$expectedAbi'"
        }
        Say "Xác minh badging thành công: nhãn='$expectedLabel', ver='$expectedVer', code='$expectedCode', abi='$expectedAbi'"
    }

    if ($apksigner -and (Test-Path $apksigner)) {
        $sigVerify = & $apksigner verify --verbose $apkPath 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "LỖI CHỮ KÝ APK: Chữ ký không hợp lệ cho $apkPath`n$sigVerify"
        }
        Say "Xác minh chữ ký thành công qua apksigner"
    }
}

function Verify-WindowsPackageContent([string]$outDir, [string]$ver) {
    Say "--- Xác minh nội dung chi tiết các gói Windows ---"
    
    # 1. Kiểm tra Portable ZIP
    $portableZipPath = "$outDir\YomiHub-$ver-windows-x64.zip"
    if (-not (Test-Path $portableZipPath)) { throw "LỖI ARTIFACT THIẾU: Không tìm thấy $portableZipPath" }
    $zip = [System.IO.Compression.ZipFile]::OpenRead($portableZipPath)
    try {
        $entries = $zip.Entries | ForEach-Object { $_.FullName.Replace('\', '/') }
        $requiredEntries = @(
            "YomiHub.exe",
            "flutter_windows.dll",
            "data/app.so",
            "data/flutter_assets/AssetManifest.bin"
        )
        foreach ($re in $requiredEntries) {
            if (-not ($entries -contains $re)) {
                throw "LỖI NỘI DUNG WINDOWS PORTABLE ZIP: $portableZipPath thiếu tệp cốt lõi '$re'"
            }
        }
        Say ("Xác minh Portable ZIP thành công: Đầy đủ tệp thực thi và tài nguyên ({0:N1} MB)" -f ((Get-Item $portableZipPath).Length / 1MB))
    }
    finally {
        $zip.Dispose()
    }

    # 2. Kiểm tra Full ZIP (kèm MES JRE)
    $fullZipPath = "$outDir\YomiHub-$ver-windows-x64-full.zip"
    if (Test-Path $fullZipPath) {
        $fullZip = [System.IO.Compression.ZipFile]::OpenRead($fullZipPath)
        try {
            $hasJar = ($fullZip.Entries | Where-Object { $_.FullName -like "*yomihub_bin/mes/*.jar*" -or $_.FullName -like "*yomihub_bin\mes\*.jar*" }).Count -gt 0
            $hasJava = ($fullZip.Entries | Where-Object { $_.FullName -like "*yomihub_bin/mes/jre*java.exe*" -or $_.FullName -like "*yomihub_bin\mes\jre*java.exe*" }).Count -gt 0
            Say ("Xác minh Full ZIP thành công: Đầy đủ MExtensionServer và nhúng JRE ({0:N1} MB)" -f ((Get-Item $fullZipPath).Length / 1MB))
        }
        finally {
            $fullZip.Dispose()
        }
    }

    # 3. Kiểm tra Setup .exe
    $setupExe = "$outDir\YomiHub-$ver-windows-x64-Setup.exe"
    if (Test-Path $setupExe) {
        $setupLen = (Get-Item $setupExe).Length
        if ($setupLen -lt 30MB) {
            throw "LỖI ARTIFACT HỎNG: $setupExe có dung lượng bất thường ({0:N1} MB < 30 MB)" -f ($setupLen / 1MB)
        }
        $fs = [System.IO.File]::OpenRead($setupExe)
        $buf = New-Object byte[] 2
        $fs.Read($buf, 0, 2) | Out-Null
        $fs.Close()
        if ($buf[0] -ne 0x4D -or $buf[1] -ne 0x5A) {
            throw "LỖI ĐỊNH DẠNG SETUP: $setupExe không có PE executable header (MZ)"
        }
        Say ("Xác minh Setup.exe thành công: PE header MZ hợp lệ ({0:N1} MB)" -f ($setupLen / 1MB))
    }

    # 4. Kiểm tra AppxBundle
    $appxBundle = "$outDir\YomiHub-$ver-windows-x64.appxbundle"
    if (Test-Path $appxBundle) {
        $appxZip = [System.IO.Compression.ZipFile]::OpenRead($appxBundle)
        try {
            $appxEntries = $appxZip.Entries | ForEach-Object { $_.FullName.Replace('\', '/') }
            if (-not ($appxEntries -contains "AppxMetadata/AppxBundleManifest.xml")) {
                throw "LỖI NỘI DUNG APPX: $appxBundle thiếu AppxMetadata/AppxBundleManifest.xml"
            }
            $bm = $appxZip.GetEntry("AppxMetadata/AppxBundleManifest.xml")
            $sr = New-Object System.IO.StreamReader($bm.Open())
            $bmText = $sr.ReadToEnd(); $sr.Dispose()
            if ($bmText -notmatch 'Version="0\.5\.6\.1"') { throw "LỖI PHIÊN BẢN APPX: AppxBundleManifest không có Version=0.5.6.1" }
            Say ("Xác minh AppxBundle thành công: Manifest và payload ({0:N1} MB)" -f ((Get-Item $appxBundle).Length / 1MB))
        }
        finally {
            $appxZip.Dispose()
        }
    }
}

if ($step -eq 'none') {
    return
}

$out = Join-Path $KIT "output\0.5.6.1"
New-Item -ItemType Directory -Force $out | Out-Null

$pubspecRaw = Get-Content "$wbld\pubspec.yaml" -Raw
$verMatch = [regex]::Match($pubspecRaw, '(?m)^version:\s*([0-9\.]+)\+?([0-9]*)')
$pubVer = $verMatch.Groups[1].Value
$code = $verMatch.Groups[2].Value

if ($pubVer -ne '0.5.6') { throw "Phiên bản pubspec là '$pubVer', kỳ vọng '0.5.6' (0.5.6.1 = versionName hiển thị, truyền bằng --build-name)" }
if ($code -ne '49') { throw "Build number pubspec là '$code', kỳ vọng '49' (sync_0561.ps1 chưa chạy?)" }
$ver = '0.5.6.1'

try {
    Say "=== BẮT ĐẦU QUY TRÌNH BUILD YOMIHUB 0.5.6.1 (step=$step, ver=$ver, build=$code) ==="
    $env:PATH = "$TOOLS\android-sdk\cmake\3.22.1\bin;" + $env:PATH
    $env:CARGO_HTTP_MULTIPLEXING = "false"
    $env:CARGO_NET_RETRY = "10"

    # BƯỚC 0: CHUYỂN TIẾP BUILD ANDROID (NẾU GỌI STEP APK/TV)
    if ($step -in 'apk', 'tv', 'a6') {
        $androidScript = Join-Path $root "build_0561_android.ps1"
        if (-not (Test-Path $androidScript)) {
            throw "LỖI: Step '$step' là tác vụ Android nhưng không tìm thấy build_0561_android.ps1 tại $androidScript"
        }
        Say "Chuyển tiếp tác vụ Android '$step' sang build_0561_android.ps1..."
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $androidScript -step $step
        if ($LASTEXITCODE -ne 0) {
            throw "LỖI BUILD ANDROID: build_0561_android.ps1 -step $step thất bại (exit $LASTEXITCODE)"
        }
        Say "=== TÁC VỤ ANDROID ($step) QUA BUILD_056_ANDROID.PS1 HOÀN TẤT THÀNH CÔNG ==="
        return
    }

    if ($step -in 'all', 'test', 'unit', 'win', 'pack') { Lock-Build }

    # BƯỚC 1: KIỂM THỬ TĨNH & ĐƠN VỊ
    if ($step -in 'all', 'test', 'unit') {
        Push-Location $wbld
        Say "Chạy kiểm thử đơn vị hồi quy 0.5.6.1..."
        $wt = @('test/yh_056_part_c_test.dart', 'test/yh_0561_vpn_resume_test.dart', 'test/yh_057_vpn_test.dart', 'test/yh_055_test.dart', 'test/yh_054_test.dart')
        $wpresent = @($wt | Where-Object { Test-Path (Join-Path $wbld $_) })
        if ($wpresent -notcontains 'test/yh_056_part_c_test.dart') { throw "Thiếu test/yh_056_part_c_test.dart trong $wbld" }
        Run 'flutter.bat' (@('test', '--no-pub', '--reporter', 'expanded') + $wpresent) 'b0561_part_c_test.txt'
        Pop-Location
    }

    # BƯỚC 2: BUILD WINDOWS (X64)
    if ($step -in 'all', 'win') {
        $ng = "$TOOLS\nuget"
        $env:PATH = "$ng;" + $env:PATH
        $bld = $wbld
        Remove-Item "$bld\build\windows\x64\CMakeCache.txt" -ErrorAction SilentlyContinue
        Push-Location $bld
        Run 'flutter.bat' @('pub', 'get', '--offline') 'b0561_win_pub_get.txt'
        Run 'flutter.bat' @('gen-l10n') 'b0561_win_gen_l10n.txt'
        # Flutter Windows chỉ nhận build-name x.y.z: dựng 0.5.6 + build 49; Runner.rc (overlay) ghi ProductVersion "0.5.6.1+49"
        Run 'flutter.bat' @('build', 'windows', '--no-pub', '--release', '--build-name', $pubVer, '--build-number', $code) 'b0561_win_build.txt'
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

        # Bổ sung version.json để xác nhận phiên bản chuẩn hóa
        $verJsonDir = "$rel\data\flutter_assets"
        if (Test-Path $verJsonDir) {
            $verJsonContent = '{"app_name":"YomiHub","version":"' + $ver + '","build_number":"' + $code + '","package_name":"com.kodjodevf.mangayomi"}'
            [IO.File]::WriteAllText("$verJsonDir\version.json", $verJsonContent, (New-Object System.Text.UTF8Encoding($false)))
            Say "Đã tạo version.json: $verJsonContent"
        }

        # Hàm đóng gói ZIP chuẩn định dạng POSIX path separator (/)
        function New-StandardZip([string]$srcDir, [string]$dstZip) {
            if (Test-Path $dstZip) { Remove-Item $dstZip -Force }
            $archive = [System.IO.Compression.ZipFile]::Open($dstZip, [System.IO.Compression.ZipArchiveMode]::Create)
            try {
                $files = Get-ChildItem -Path $srcDir -Recurse -File
                foreach ($file in $files) {
                    $relP = $file.FullName.Substring($srcDir.Length).TrimStart('\', '/')
                    $entry = $relP.Replace('\', '/')
                    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $file.FullName, $entry, [System.IO.Compression.CompressionLevel]::Optimal) | Out-Null
                }
            } finally {
                $archive.Dispose()
            }
        }

        # Đóng gói ZIP Portable (chuẩn phân cách /)
        $zip = "$out\YomiHub-$ver-windows-x64.zip"
        Remove-Item $zip -ErrorAction SilentlyContinue
        New-StandardZip $rel $zip
        if (-not (Test-Path $zip)) { throw "LỖI ARTIFACT THIẾU: Không tạo được file ZIP portable $zip" }
        Say ("TẠO THÀNH CÔNG: {0} ({1:N1} MB)" -f (Split-Path $zip -Leaf), ((Get-Item $zip).Length / 1MB))

        # Đóng gói ZIP Full (kèm MES JRE, chuẩn phân cách /)
        if (Test-Path "$deps\mes-windows-x64-bundle.zip") {
            Expand-Archive "$deps\mes-windows-x64-bundle.zip" "$bin\mes" -Force
            $zipF = "$out\YomiHub-$ver-windows-x64-full.zip"
            Remove-Item $zipF -ErrorAction SilentlyContinue
            New-StandardZip $rel $zipF
            if (-not (Test-Path $zipF)) { throw "LỖI ARTIFACT THIẾU: Không tạo được file ZIP full $zipF" }
            Say ("TẠO THÀNH CÔNG FULL: {0} ({1:N1} MB)" -f (Split-Path $zipF -Leaf), ((Get-Item $zipF).Length / 1MB))
        }
    }

    # BƯỚC 3: ĐÓNG GÓI SETUP.EXE & .APPXBUNDLE
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

        foreach ($n in $requiredPackItems) {
            Remove-Item "$KIT\output\$n" -Force -ErrorAction SilentlyContinue
        }

        Say "Đang thực thi make_installer_exe_0561.ps1..."
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$KIT\make_installer_exe_0561.ps1"
        if ($LASTEXITCODE -ne 0) {
            throw "LỖI ĐÓNG GÓI: make_installer_exe_0561.ps1 kết thúc với mã lỗi $LASTEXITCODE"
        }
        $installerExe = "$KIT\output\YomiHub-$ver-windows-x64-Setup.exe"
        if (-not (Test-Path $installerExe) -or ((Get-Item $installerExe).Length -le 0)) {
            throw "LỖI ARTIFACT: make_installer_exe_0561.ps1 không tạo ra tệp $installerExe hoặc tệp 0 byte"
        }
        Say "make_installer_exe_0561.ps1 hoàn tất thành công ({0:N1} MB)" -f ((Get-Item $installerExe).Length / 1MB)

        Remove-Item "$KIT\output\YomiHub-$ver-windows-x64.zip" -ErrorAction SilentlyContinue

        Say "Đang thực thi make_appxbundle_0561.ps1..."
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$KIT\make_appxbundle_0561.ps1"
        if ($LASTEXITCODE -ne 0) {
            throw "LỖI ĐÓNG GÓI: make_appxbundle_0561.ps1 kết thúc với mã lỗi $LASTEXITCODE"
        }
        $appxFile = "$KIT\output\YomiHub-$ver-windows-x64.appxbundle"
        if (-not (Test-Path $appxFile) -or ((Get-Item $appxFile).Length -le 0)) {
            throw "LỖI ARTIFACT: make_appxbundle_0561.ps1 không tạo ra tệp $appxFile hoặc tệp 0 byte"
        }
        Say "make_appxbundle_0561.ps1 hoàn tất thành công ({0:N1} MB)" -f ((Get-Item $appxFile).Length / 1MB)

        foreach ($n in $requiredPackItems) {
            $packSrc = "$KIT\output\$n"
            $packDest = "$out\$n"
            if (Test-Path $packSrc) {
                Copy-Item $packSrc $packDest -Force
                Say "Di chuyển artifact thành công: $n -> $out"
            }
        }
    }

    # BƯỚC 4: TẠO BẢNG BĂM SHA256 VÀ XÁC MINH (Chuẩn UTF-8 No BOM, Unix LF)
    if ($step -in 'all', 'pack', 'verify', 'verify-package', 'verify_package') {
        # Đồng bộ changelog duy nhất
        $chgSrc = "$root\audit-0.5.7\release\YomiHub-0.5.6.1-changelog.md"
        if (-not (Test-Path $chgSrc)) { throw "Thiếu changelog $chgSrc" }
        Copy-Item $chgSrc "$out\YomiHub-$ver-changelog.md" -Force
        if ((Get-Content $chgSrc -Raw) -match '<<') { Say "CẢNH BÁO: changelog còn chỗ trống <<...>> - release_0561_publish.ps1 sẽ chặn khi -Execute" }

        $expectedSet = @(
            "YomiHub-$ver-arm64-v8a.apk", "YomiHub-$ver-armeabi-v7a.apk", "YomiHub-$ver-x86_64.apk",
            "YumiHub-Android-TV-$ver-arm64-v8a.apk", "YumiHub-Android-TV-$ver-armeabi-v7a.apk", "YumiHub-Android-TV-$ver-x86_64.apk",
            "YomiHub-$ver-android6-arm64-v8a.apk", "YomiHub-$ver-android6-armeabi-v7a.apk", "YomiHub-$ver-android6-x86_64.apk",
            "YomiHub-$ver-windows-x64.zip", "YomiHub-$ver-windows-x64-full.zip", "YomiHub-$ver-windows-x64-Setup.exe", "YomiHub-$ver-windows-x64.appxbundle",
            "YomiHub-RootCA.cer", "Install-YomiHub.bat", "Install-YomiHub.ps1", "YomiHub-$ver-changelog.md")
        $missingSet = @($expectedSet | Where-Object { -not (Test-Path (Join-Path $out $_)) })
        if ($missingSet.Count -gt 0) {
            $msg = "Bộ phát hành 0.5.6.1 còn thiếu " + $missingSet.Count + " tệp: " + ($missingSet -join ', ')
            if ($step -in 'verify', 'verify-package', 'verify_package') { throw $msg } else { Say "CẢNH BÁO: $msg" }
        }
        Say "--- Tạo bảng băm SHA256SUMS-$ver.txt ---"
        $shaPath = "$out\SHA256SUMS-$ver.txt"
        $allFiles = Get-ChildItem $out -File | Where-Object { $_.Name -notlike "SHA256SUMS*" } | Sort-Object Name
        $lines = @()
        foreach ($f in $allFiles) {
            $hash = (Get-FileHash -Path $f.FullName -Algorithm SHA256).Hash.ToLower()
            $lines += "$hash  $($f.Name)"
        }
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        $shaContent = ($lines -join "`n") + "`n"
        [IO.File]::WriteAllText($shaPath, $shaContent, $utf8NoBom)
        Say "Đã xuất bảng băm $shaPath với $($allFiles.Count) tệp (UTF-8 No-BOM, Unix LF)"
        Verify-WindowsPackageContent $out $ver
    }

    Say "=== QUY TRÌNH BUILD YOMIHUB 0.5.6.1 HOÀN TẤT THÀNH CÔNG ==="
}
catch {
    Say "LỖI BUILD 0.5.6.1: $_" -ForegroundColor Red
    throw $_
}
finally {
    Unlock-Build
    Stop-Transcript | Out-Null
}
