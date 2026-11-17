[CmdletBinding()]
param(
    [ValidateSet('all', 'sync', 'patch', 'apk', 'post', 'verify')]
    [string]$step = 'all',
    [string[]]$abis = @('arm64-v8a', 'armeabi-v7a', 'x86_64'),
    [string]$buildName = '0.5.6.1',
    # versionCode cơ sở (pubspec 0.5.6+49); mỗi ABI = 1000/2000/4000 + buildNumber (armeabi-v7a/arm64-v8a/x86_64)
    [string]$buildNumber = '49',
    # APK Android 7.0+ chính dùng để đối chiếu chữ ký (cùng khóa phát hành)
    [string]$refApk = '',
    # Giữ chặn WireGuard/WARP dưới API 24 (mặc định: bỏ chặn)
    [switch]$keepVpnGuard,
    # Giữ chặn Tor dưới API 24 và dùng tor-android gốc (mặc định: tor-android đã vá FileObserver + bỏ chặn)
    [switch]$keepTorGuard,
    # Không thêm bộ CA Mozilla đóng gói (mặc định: thêm, chỉ có hiệu lực khi SDK < 24)
    [switch]$noCaBundle,
    [int]$lockWaitMin = 60
)
# build_0561_android6.ps1 - YomiHub 0.5.6.1: dựng 3 APK RIÊNG cho Android 6.0 (API 23)
# (arm64-v8a, armeabi-v7a, x86_64) trong D:\yh\build23 - KHÔNG đụng APK Android 7.0+ chính.
#   sync  : chép mã từ $YH\build\mangayomi sang $YH\build23\mangayomi (robocopy /MIR, giữ bộ đệm build)
#   patch : minSdk 23, vmSafeMode, embedding Flutter có kiểm tra phiên bản, jniLibs đã vá (audit-0.5.7\android6\jnilibs23),
#           tắt cargokit (dùng librust_lib_mangayomi.so của bản chính), bỏ chặn WireGuard/WARP/Tor < API 24 (tor-android vá FileObserver),
#           bộ CA Mozilla đóng gói cho Dart HttpClient + Java (chỉ khi SDK < 24)
#   apk   : flutter build apk --split-per-abi --build-name 0.5.6.1 (ký bằng khóa phát hành qua key.properties)
#   post  : chép ra audit-0.5.7\android6\out\YomiHub-0.5.6.1-android6-<abi>.apk
#   verify: aapt2 (sdkVersion 23, versionName, ABI, nhãn), sha256 thư viện đã vá, apksigner + so chứng chỉ với APK chính
# Bước sync/patch/apk giữ audit-0.5.6\coordination\BUILD_LOCK.txt ("A6 <giờ>") và luôn trả khóa (try/finally).
# Chi tiết kỹ thuật: audit-0.5.7\android6\A6_FEASIBILITY.md
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$root = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Item .).FullName }
. "$root\common.ps1"
$ErrorActionPreference = 'Stop'

$A6 = "$root\audit-0.5.7\android6"
$J23 = "$A6\jnilibs23"
$outDir = "$A6\out"
$SRC = "$YH\build\mangayomi"
$B = "$YH\build23\mangayomi"
$lockFile = "$root\audit-0.5.6\coordination\BUILD_LOCK.txt"
$ENGINE = '692136cb6582dbfc5af3fb33c2515a069f2f66d0'   # engine Flutter 3.47.6 mà libflutter.so/embedding đã vá thuộc về
$EMB = "$A6\embedding\flutter_embedding_release-yh23.jar"
$platMap = @{ 'arm64-v8a' = 'android-arm64'; 'armeabi-v7a' = 'android-arm'; 'x86_64' = 'android-x64' }
if (-not $refApk) { $refApk = "$root\output\0.5.6\YomiHub-0.5.6-arm64-v8a.apk" }
New-Item -ItemType Directory -Force $outDir | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
Start-Transcript "$LOGS\build0561_android6_${step}_$stamp.txt" -Force | Out-Null

$aapt2 = (Get-ChildItem "$TOOLS\android-sdk\build-tools" -Recurse -Filter 'aapt2.exe' | Sort-Object FullName | Select-Object -Last 1).FullName
$apksigner = (Get-ChildItem "$TOOLS\android-sdk\build-tools" -Recurse -Filter 'apksigner.bat' | Sort-Object FullName | Select-Object -Last 1).FullName

function Sha([string]$p) { (Get-FileHash $p -Algorithm SHA256).Hash.ToLower() }
function Read-Manifest {
    $m = @{}
    foreach ($l in Get-Content "$J23\MANIFEST.txt" -Encoding UTF8) {
        if ($l -match '^#' -or -not $l.Trim()) { continue }
        $f = $l -split '\s+'; $m["$($f[0])/$($f[1])"] = $f[3]
    }
    return $m
}
function Lock-Build {
    $t0 = Get-Date
    while ($true) {
        $c = "$(Get-Content $lockFile -Raw -ErrorAction SilentlyContinue)".Trim([char]0xFEFF, ' ', "`r", "`n")
        if (-not $c) { break }
        if (((Get-Date) - $t0).TotalMinutes -gt $lockWaitMin) { throw "BUILD_LOCK đang bị giữ: '$c' (đã chờ $lockWaitMin phút)" }
        Say "BUILD_LOCK đang bị giữ: '$c' - chờ 30 giây"; Start-Sleep 30
    }
    Set-Content $lockFile ('A6 ' + (Get-Date -Format 'HH:mm')) -Encoding UTF8
    $script:locked = $true; Say 'Đã giữ BUILD_LOCK'
}
function Unlock-Build {
    if (-not $script:locked) { return }
    $c = "$(Get-Content $lockFile -Raw -ErrorAction SilentlyContinue)".Trim([char]0xFEFF, ' ', "`r", "`n")
    if ($c -match '^A6') { Set-Content $lockFile '' -NoNewline; Say 'Đã trả BUILD_LOCK' }
    $script:locked = $false
}
function Edit-File([string]$path, [string]$pattern, [string]$replacement, [int]$min = 1) {
    $t = [IO.File]::ReadAllText($path)
    $n = ([regex]::Matches($t, $pattern)).Count
    if ($n -lt $min) { throw "VÁ THẤT BẠI: '$pattern' khớp $n lần (cần >= $min) trong $path" }
    $t = [regex]::Replace($t, $pattern, $replacement)
    [IO.File]::WriteAllText($path, $t, (New-Object Text.UTF8Encoding($false)))
    Say ("  vá {0}: {1} chỗ" -f (Split-Path $path -Leaf), $n)
}

# Điều kiện đầu vào
$eng = (Get-Content "$TOOLS\flutter\bin\internal\engine.version" -Raw).Trim()
if ($eng -ne $ENGINE) { throw "Engine Flutter đã đổi ($eng). libflutter.so/embedding đã vá thuộc engine $ENGINE - chạy lại prepare_jnilibs23.py và dựng lại embedding (audit-0.4.3\compat23\embedding)." }
if (-not (Test-Path $EMB)) { throw "Thiếu $EMB" }
$man = Read-Manifest
foreach ($k in $man.Keys) {
    $p = "$J23\$($k.Replace('/', '\'))"
    if (-not (Test-Path $p)) { throw "Thiếu thư viện đã vá: $p" }
    if ((Sha $p) -ne $man[$k]) { throw "Sai sha256: $p (khác MANIFEST.txt)" }
}
Say "Đầu vào hợp lệ: engine $ENGINE, $($man.Count) thư viện đã vá, embedding yh23"

$script:locked = $false
try {
    Say "=== YomiHub $buildName Android 6.0 (step=$step, abi=$($abis -join ','))"
    if ($step -in 'all', 'sync', 'patch', 'apk') { Lock-Build }

    if ($step -in 'all', 'sync') {
        Say "Đồng bộ $SRC -> $B"
        New-Item -ItemType Directory -Force $B | Out-Null
        # build/.gradle (bộ đệm) và .dart_tool\flutter_build (dấu thời gian trỏ về thư mục chính) không chép, không xóa
        $xd = foreach ($d in 'build', 'android\.gradle', 'android\build', 'android\app\build', '.dart_tool\flutter_build') { "$SRC\$d"; "$B\$d" }
        & robocopy $SRC $B /MIR /XD @xd /XJ /R:1 /W:1 /NFL /NDL /NP /MT:8 | Select-Object -Last 8
        if ($LASTEXITCODE -ge 8) { throw "robocopy lỗi (exit $LASTEXITCODE)" }
        if (-not (Test-Path "$B\android\key.properties")) { throw "Thiếu android\key.properties trong build23 (cần để ký bằng khóa phát hành)" }
    }

    if ($step -in 'all', 'patch') {
        Say 'Vá build23 cho API 23'
        $app = "$B\android\app"
        $strXml = "$app\src\main\res\values\strings.xml"
        Edit-File $strXml '<string name="app_name">[^<]*</string>' '<string name="app_name">YomiHub</string>'
        Edit-File "$app\build.gradle" 'def yhMinSdk = \d+' 'def yhMinSdk = 23 // A6 0.5.6.1: APK Android 6.0 riêng (build_0561_android6.ps1)'
        $g = [IO.File]::ReadAllText("$app\build.gradle")
        if ($g -notmatch 'A6 0\.5\.6\.1 BLOCK') {
            $g += @'

// ===== A6 0.5.6.1 BLOCK (build_0561_android6.ps1, chỉ có trong build23) =====
// jniLibs/<abi> của app (thư viện đã vá cho API 23) phải thắng bản trong AAR/plugin
// và không bị strip lại (sha256 được kiểm sau khi dựng).
android {
    packagingOptions {
        jniLibs {
            pickFirsts += ['**/libflutter.so', '**/libisar.so', '**/libtor.so', '**/libmpv.so', '**/librust_lib_mangayomi.so', '**/libyhcompat.so']
            keepDebugSymbols += ['**/libflutter.so', '**/libisar.so', '**/libtor.so', '**/libmpv.so', '**/librust_lib_mangayomi.so', '**/libyhcompat.so']
        }
    }
}
// Embedding Flutter có kiểm tra phiên bản cho 4 lời gọi API 24 (audit-0.4.3/compat23/embedding)
configurations.all {
    exclude group: 'io.flutter', module: 'flutter_embedding_release'
}
dependencies {
    implementation files('libs/flutter_embedding_release-yh23.jar')
    implementation 'androidx.lifecycle:lifecycle-common:2.7.0'
    implementation 'androidx.lifecycle:lifecycle-common-java8:2.7.0'
    implementation 'androidx.lifecycle:lifecycle-process:2.7.0'
    implementation 'androidx.lifecycle:lifecycle-runtime:2.7.0'
    implementation 'androidx.fragment:fragment:1.7.1'
    implementation 'androidx.annotation:annotation:1.8.1'
    implementation 'androidx.tracing:tracing:1.2.0'
    implementation 'androidx.core:core:1.13.1'
    implementation 'androidx.window:window-java:1.2.0'
    implementation 'com.getkeepsafe.relinker:relinker:1.4.5'
    implementation 'androidx.exifinterface:exifinterface:1.4.1'
}
'@
            [IO.File]::WriteAllText("$app\build.gradle", $g, (New-Object Text.UTF8Encoding($false)))
            Say '  vá build.gradle: thêm khối A6'
        }
        # Plugin theo đường dẫn (rust_builder, packages\*) phải trỏ vào build23, không phải thư mục chính
        foreach ($pf in '.flutter-plugins-dependencies', '.flutter-plugins') {
            $pp = "$B\$pf"
            if (Test-Path $pp) {
                $t = [IO.File]::ReadAllText($pp)
                $t = [regex]::Replace($t, '(?<=[\\/])build(?=[\\/]+mangayomi[\\/])', 'build23')
                [IO.File]::WriteAllText($pp, $t, (New-Object Text.UTF8Encoding($false)))
                if ($t -match '[\\/]build[\\/]+mangayomi[\\/]') { throw "$pf vẫn trỏ về thư mục chính" }
                Say "  $pf -> build23"
            }
        }
        if (Test-Path "$B\.dart_tool\flutter_build") { Remove-Item "$B\.dart_tool\flutter_build" -Recurse -Force; Say '  xóa .dart_tool\flutter_build (dựng lại Dart từ mã build23)' }
        # ART 6.0: dex2oat (bộ tối ưu của Android 6) biên dịch sai phương thức gộp lớn do R8 tạo
        # (tc0.onMethodCall = handler kênh yomihub/vpn + yomihub/tunnels) -> SIGSEGV khi mở app.
        # vmSafeMode=true: Android 6 biên dịch APK ở chế độ interpret-only (đã kiểm: hết lỗi).
        $mf = "$app\src\main\AndroidManifest.xml"
        if ([IO.File]::ReadAllText($mf) -notmatch 'android:vmSafeMode=') {
            Edit-File $mf '<application(?=\s)' '<application android:vmSafeMode="true"'
        }
        New-Item -ItemType Directory -Force "$app\libs" | Out-Null
        Copy-Item $EMB "$app\libs\" -Force
        # Rust: tắt cargokit trong build23, dùng librust_lib_mangayomi.so của bản chính (jnilibs23)
        $rb = "$B\rust_builder\android\build.gradle"
        $t = [IO.File]::ReadAllText($rb)
        if ($t -match 'apply from: "\.\./cargokit/gradle/plugin\.gradle"') {
            Edit-File $rb 'apply from: "\.\./cargokit/gradle/plugin\.gradle"' '// A6: cargokit tắt trong build23 (librust_lib_mangayomi.so lấy từ bản chính)'
            Edit-File $rb '(?s)\ncargokit\s*\{[^}]*\}' "`n// A6: khối cargokit đã bỏ"
        }
        # VPN: bỏ chặn WireGuard/WARP dưới API 24 (GoBackend + VpnService chạy trên API 23).
        # GIỮ chặn Tor: tor-android 0.4.9.13 gọi FileObserver(File) (API 29) -> NoSuchMethodError, app thoát (đã kiểm A6).
        if (-not $keepVpnGuard) {
            # wireguard-android GoBackend dùng CompletableFuture (API 24, không desugar) -> NoClassDefFoundError trên Android 6.
            # AAR đã đổi tham chiếu sang YhA6Future (wg\RemapCompletableFuture.java, ASM) + lớp thay thế YhA6Future.kt.
            Copy-Item "$A6\wg\tunnel-1.0.20260102-yh23.aar" "$app\libs\" -Force
            Copy-Item "$A6\wg\YhA6Future.kt" "$app\src\main\kotlin\com\kodjodevf\mangayomi\YhA6Future.kt" -Force
            Edit-File "$app\build.gradle" "implementation 'com\.wireguard\.android:tunnel:1\.0\.20260102'" "implementation(name: 'tunnel-1.0.20260102-yh23', ext: 'aar') // A6: CompletableFuture -> YhA6Future"
            foreach ($k in 'YomiVpn.kt', 'YomiTunnels.kt') {
                $kp = "$app\src\main\kotlin\com\kodjodevf\mangayomi\$k"
                if ([IO.File]::ReadAllText($kp) -match 'SDK_INT < 24\) \{\s*result\.error\("WG"') {
                    Edit-File $kp 'android\.os\.Build\.VERSION\.SDK_INT < 24\) \{(\s*)result\.error\("WG"' 'android.os.Build.VERSION.SDK_INT < 23) /* A6: WireGuard/WARP chạy trên API 23 */ {$1result.error("WG"'
                }
            }
        }
        # Tor: tor-android 0.4.9.13 gọi FileObserver(File) (API 29) -> NoSuchMethodError trên Android 6.
        # Dùng AAR đã vá (tor\PatchTorFileObserver.java, ASM: File.getAbsolutePath + FileObserver(String)) và bỏ chặn Tor.
        if (-not $keepTorGuard) {
            Copy-Item "$A6\tor\tor-android-0.4.9.13-yh23.aar" "$app\libs\" -Force
            Edit-File "$app\build.gradle" "implementation 'info\.guardianproject:tor-android:0\.4\.9\.13'" "implementation(name: 'tor-android-0.4.9.13-yh23', ext: 'aar') // A6: FileObserver(File) -> FileObserver(String)"
            $kp = "$app\src\main\kotlin\com\kodjodevf\mangayomi\YomiVpn.kt"
            if ([IO.File]::ReadAllText($kp) -match 'SDK_INT < 24\) \{\s*result\.error\("TOR"') {
                Edit-File $kp 'android\.os\.Build\.VERSION\.SDK_INT < 24\) \{(\s*)result\.error\("TOR"' 'android.os.Build.VERSION.SDK_INT < 23) /* A6: tor-android đã vá */ {$1result.error("TOR"'
            }
        }
        # HTTPS: Android 6 thiếu CA gốc mới -> CERTIFICATE_VERIFY_FAILED. Thêm bộ CA Mozilla (tls\cacert.pem)
        # cho Dart (SecurityContext.defaultContext, main + isolate tải/tiện ích) và Java (YomiA6Tls.kt), chỉ khi SDK < 24.
        if (-not $noCaBundle) {
            $T = "$A6\tls"
            New-Item -ItemType Directory -Force "$app\src\main\assets", "$B\lib\yomihub\a6" | Out-Null
            Copy-Item "$T\cacert.pem" "$app\src\main\assets\yh_a6_cacert.pem" -Force
            Copy-Item "$T\YomiA6Tls.kt" "$app\src\main\kotlin\com\kodjodevf\mangayomi\YomiA6Tls.kt" -Force
            $pem = [IO.File]::ReadAllText("$T\cacert.pem").Replace("`r`n", "`n")
            $dart = [IO.File]::ReadAllText("$T\a6_tls.dart.tmpl").Replace('__PEM__', $pem.Trim()).Replace('__CA_SOURCE__', "Git for Windows ucrt64/etc/ssl/certs/ca-bundle.crt (Mozilla, sha256 $((Sha "$T\cacert.pem").Substring(0,16)))")
            [IO.File]::WriteAllText("$B\lib\yomihub\a6\a6_tls.dart", $dart, (New-Object Text.UTF8Encoding($false)))
            $imp = "import 'package:mangayomi/yomihub/a6/a6_tls.dart'; // A6`n"
            $edits = @(
                @("$B\lib\main.dart", '(WidgetsFlutterBinding\.ensureInitialized\(\);)(\s*if \(Platform\.isLinux && runWebViewTitleBarWidget)', '$1 yhA6InstallCa();$2'),
                @("$B\lib\services\download_manager\download_isolate_pool.dart", '(void _workerEntryPoint\(SendPort mainPort\) async \{)', '$1 yhA6InstallCa();'),
                @("$B\lib\services\isolate_service.dart", '(_getIsolateServiceEntryPoint\(\s*_IsolateData isolateData,\s*\) async \{)', '$1 yhA6InstallCa();')
            )
            foreach ($e in $edits) {
                if ([IO.File]::ReadAllText($e[0]) -notmatch 'yhA6InstallCa') {
                    Edit-File $e[0] $e[1] $e[2]
                    [IO.File]::WriteAllText($e[0], $imp + [IO.File]::ReadAllText($e[0]), (New-Object Text.UTF8Encoding($false)))
                }
            }
            $ma = "$app\src\main\kotlin\com\kodjodevf\mangayomi\MainActivity.kt"
            if ([IO.File]::ReadAllText($ma) -notmatch 'YomiA6Tls') {
                Edit-File $ma '(\n(\s*)super\.configureFlutterEngine\(flutterEngine\))' "`n`$2YomiA6Tls.install(applicationContext) // A6: CA gốc cho Java khi SDK < 24`$1"
            }
            # Android 6: Back ở màn gốc -> đưa app xuống nền (như Android 12+) thay vì finish(): finish làm engine Flutter
            # bị hủy, mở lại trong cùng tiến trình thì engine mới kẹt ở logo (đã tái hiện trên AVD API 23).
            if ([IO.File]::ReadAllText($ma) -notmatch 'A6 finish') {
                Edit-File $ma '(class MainActivity\s*:\s*FlutterFragmentActivity\(\)\s*\{)' ('$1' + "`n    // A6 finish: Android 6 - Back o man goc dua app xuong nen thay vi finish() (tranh ket logo khi mo lai)`n    override fun finish() {`n        if (android.os.Build.VERSION.SDK_INT < 24 && isTaskRoot && Thread.currentThread().stackTrace.any { it.methodName == `"onBackPressed`" || it.methodName == `"finishAfterTransition`" }) {`n            moveTaskToBack(true)`n            return`n        }`n        super.finish()`n    }`n")
            }
            $pg = "$app\proguard-rules.pro"
            if ([IO.File]::ReadAllText($pg) -notmatch 'YomiA6') {
                # chỉ ASCII + UTF-8 (R8 đọc UTF-8; Add-Content của PS 5 ghi ANSI -> "Failed to read file")
                [IO.File]::AppendAllText($pg, "`n# A6: TrustManagerFactory provider loaded by class name`n-keep class com.kodjodevf.mangayomi.YomiA6** { *; }`n", (New-Object Text.UTF8Encoding($false)))
            }
        }
        # Thư viện gốc đã vá
        foreach ($abi in $abis) {
            $d = "$app\src\main\jniLibs\$abi"; New-Item -ItemType Directory -Force $d | Out-Null
            Copy-Item "$J23\$abi\*.so" $d -Force
            Say "  jniLibs\$abi : $((Get-ChildItem "$J23\$abi\*.so" | ForEach-Object Name) -join ', ')"
        }
    }

    if ($step -in 'all', 'apk') {
        Say 'Dựng APK (flutter build apk)'
        $env:PATH = "$TOOLS\android-sdk\cmake\3.22.1\bin;" + $env:PATH
        $plat = ($abis | ForEach-Object { $platMap[$_] }) -join ','
        $apkLog = "$LOGS\b0561_android6_apk.txt"
        Remove-Item $apkLog -ErrorAction SilentlyContinue
        $script:apkStart = Get-Date
        Push-Location $B
        try {
            cmd.exe /c "set `"PATH=$TOOLS\git\cmd;$TOOLS\mingw64\bin;$TOOLS\flutter\bin;$TOOLS\jdk\bin;$TOOLS\cargo\bin;$TOOLS\android-sdk\platform-tools;%PATH%`" && `"$TOOLS\flutter\bin\flutter.bat`" build apk --no-pub --release --split-per-abi --target-platform $plat --build-name $buildName --build-number $buildNumber --split-debug-info `"$YH\build23\symbols`" > `"$apkLog`" 2>&1"
            $rc = $LASTEXITCODE
        } finally { Pop-Location }
        Get-Content $apkLog -Tail 6
        if ($rc -ne 0) { throw "flutter build apk thất bại (exit $rc) - xem $apkLog" }
    }
    Unlock-Build

    if ($step -in 'all', 'post') {
        foreach ($abi in $abis) {
            $f = "$B\build\app\outputs\flutter-apk\app-$abi-release.apk"
            if (-not (Test-Path $f)) { throw "LỖI ARTIFACT THIẾU: $f" }
            if ($script:apkStart -and (Get-Item $f).LastWriteTime -lt $script:apkStart) { throw "APK cũ (không được dựng lại): $f" }
            Copy-Item $f "$outDir\YomiHub-$buildName-android6-$abi.apk" -Force
            Say "Đã chép YomiHub-$buildName-android6-$abi.apk"
        }
    }

    if ($step -in 'all', 'post', 'verify') {
        Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
        $refCert = ((& cmd.exe /c "`"$apksigner`" verify --print-certs `"$refApk`" 2>&1") | Select-String 'Signer #1 certificate SHA-256 digest:\s*(\w+)').Matches[0].Groups[1].Value
        if (-not $refCert) { throw "Không đọc được chứng chỉ của APK đối chiếu $refApk" }
        foreach ($abi in $abis) {
            $apk = "$outDir\YomiHub-$buildName-android6-$abi.apk"
            if (-not (Test-Path $apk)) { throw "LỖI ARTIFACT THIẾU: $apk" }
            $bad = & $aapt2 dump badging $apk 2>$null
            $pkg = ($bad | Select-String '^package:').Line
            # aapt2 in "minSdkVersion:'23'", aapt (v1) in "sdkVersion:'23'"
            $sdk = ($bad | Select-String "^(?:min)?[sS]dkVersion:'(\d+)'" | Select-Object -First 1).Matches[0].Groups[1].Value
            $aapt1 = Join-Path (Split-Path $aapt2) 'aapt.exe'
            if (Test-Path $aapt1) {
                $sdk1 = ((& $aapt1 dump badging $apk 2>$null) | Select-String "^sdkVersion:'(\d+)'" | Select-Object -First 1).Matches[0].Groups[1].Value
                if ($sdk1 -ne '23') { throw "aapt dump badging: sdkVersion='$sdk1' (cần 23)" }
            }
            $lab = ($bad | Select-String "^application-label:'(.*)'").Matches[0].Groups[1].Value
            $nat = ($bad | Select-String '^native-code:').Line
            if ($pkg -notmatch "name='com\.yomihub\.app'") { throw "Sai package: $pkg" }
            if ($pkg -notmatch "versionName='$([regex]::Escape($buildName))'") { throw "Sai versionName: $pkg" }
            $vcBase = @{ 'armeabi-v7a' = 1000; 'arm64-v8a' = 2000; 'x86_64' = 4000 }[$abi] + [int]$buildNumber
            if ($pkg -notmatch "versionCode='$vcBase'") { throw "Sai versionCode (cần $vcBase = build-number $buildNumber; dựng lại APK android6 sau khi nâng lên +49?): $pkg" }
            if ($sdk -ne '23') { throw "sdkVersion = '$sdk' (cần 23) trong $apk" }
            if ($lab -ne 'YomiHub') { throw "Nhãn '$lab' (cần YomiHub)" }
            if ($nat -notmatch "'$abi'" -or ($nat -split "'" | Where-Object { $_ -match '^(arm|x86)' }).Count -ne 1) { throw "native-code sai: $nat" }
            $xt = (& $aapt2 dump xmltree --file AndroidManifest.xml $apk 2>$null) -join "`n"
            if ($xt -notmatch 'vmSafeMode\(0x[0-9a-f]+\)=true') { throw "Thiếu android:vmSafeMode=true trong $apk" }
            $zip = [IO.Compression.ZipFile]::OpenRead($apk)
            try {
                foreach ($k in ($man.Keys | Where-Object { $_ -like "$abi/*" })) {
                    $n = $k.Split('/')[1]; $e = $zip.GetEntry("lib/$abi/$n")
                    if (-not $e) { throw "APK thiếu lib/$abi/$n" }
                    $s = $e.Open(); $h = [Security.Cryptography.SHA256]::Create().ComputeHash($s); $s.Close()
                    $hx = -join ($h | ForEach-Object { $_.ToString('x2') })
                    if ($hx -ne $man[$k]) { throw "lib/$abi/$n trong APK khác bản đã vá (bị thay/strip?)" }
                }
                foreach ($n in 'classes.dex', "lib/$abi/libapp.so", 'AndroidManifest.xml') { if (-not $zip.GetEntry($n)) { throw "APK thiếu $n" } }
                if (-not $noCaBundle -and -not $zip.GetEntry('assets/yh_a6_cacert.pem')) { throw "APK thiếu assets/yh_a6_cacert.pem" }
            } finally { $zip.Dispose() }
            $sig = & cmd.exe /c "`"$apksigner`" verify --print-certs `"$apk`" 2>&1"
            if ($LASTEXITCODE -ne 0) { throw "Chữ ký không hợp lệ: $apk" }
            $cert = ($sig | Select-String 'Signer #1 certificate SHA-256 digest:\s*(\w+)').Matches[0].Groups[1].Value
            if ($cert -ne $refCert) { throw "Chứng chỉ $cert khác APK chính $refCert" }
            Say ("ĐẠT {0}: {1} | sdkVersion 23 | {2} | thư viện vá khớp sha | chứng chỉ = APK chính ({3:N1} MB)" -f (Split-Path $apk -Leaf), (($pkg -split ' ' | Where-Object { $_ -match 'version' }) -join ' '), $nat, ((Get-Item $apk).Length / 1MB))
        }
        Get-ChildItem "$outDir\YomiHub-$buildName-android6-*.apk" | ForEach-Object { '{0}  {1}' -f (Sha $_.FullName), $_.Name } | Set-Content "$outDir\SHA256SUMS-$buildName-android6.txt" -Encoding ascii
        Say "SHA256SUMS-$buildName-android6.txt đã ghi"
    }
    Say "=== HOÀN TẤT (step=$step)"
} catch {
    Say "LỖI: $($_.Exception.Message)"
    $host.SetShouldExit(1); exit 1
} finally {
    Unlock-Build
    Stop-Transcript | Out-Null
}
