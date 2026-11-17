# build_045.ps1 - YomiHub 0.4.5 build (sources already synced from overlay
# into D:\yh\build and D:\yh\buildwin by the 0.4.5 session; no mirror copy).
# Usage: powershell -ExecutionPolicy Bypass -File build_045.ps1 -step test|apk|tv|win|pack|all
param([string]$step = 'all')
. "$PSScriptRoot\common.ps1"
$stamp = Get-Date -Format HHmmss
Start-Transcript "$LOGS\build045_${step}_$stamp.txt" -Force | Out-Null
$ErrorActionPreference = 'Continue'
function Run($exe, [string[]]$a, $logName) {
  $shown = ($a -join ' '); if ($script:secret) { $shown = $shown.Replace($script:secret, '***') }
  Say "> $exe $shown"
  $outLog = "$LOGS\$logName"
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
  if ($LASTEXITCODE -ne 0) { throw "$exe failed (exit $LASTEXITCODE) - see logs\$logName" }
}

$abld = "$YH\build\mangayomi"; $wbld = "$YH\buildwin\mangayomi"
$out = "$KIT\output\0.4.5"; New-Item -ItemType Directory -Force $out | Out-Null
$ver = ([regex]::Match((Get-Content "$abld\pubspec.yaml" -Raw), '(?m)^version:\s*([\d\.]+)')).Groups[1].Value
try {
  Say "BUILD 0.4.5 START step=$step ver=$ver"
  if ($ver -ne '0.4.5') { throw "pubspec version is $ver, expected 0.4.5" }
  $env:PATH = "$TOOLS\android-sdk\cmake\3.22.1\bin;" + $env:PATH
  $env:CARGO_HTTP_MULTIPLEXING = "false"; $env:CARGO_NET_RETRY = "10"
  if ($step -in 'all','test') {
    Push-Location $abld
    Run 'flutter.bat' @('pub','get','--offline') 'b045_pub_get.txt'
    Run 'flutter.bat' @('gen-l10n') 'b045_gen_l10n.txt'
    $al = @('analyze','--no-fatal-warnings') + (Get-Content "$KIT\audit-0.4.5\changed_files.txt" | Where-Object { $_ -like 'lib/*.dart' -and (Test-Path "$abld\$_") })
    Run 'dart.bat' $al 'b045_analyze.txt'
    Pop-Location
  }
  if ($step -in 'all','test','unit') {
    Push-Location $abld
    Run 'flutter.bat' @('test','--no-pub','test/yh_045_test.dart','test/yh_044_test.dart','test/yh_043_test.dart','test/yh_042_test.dart','test/yh_041_test.dart','test/yh_040_test.dart') 'b045_test.txt'
    Pop-Location
  }
  if ($step -eq 'probe23') {
    Push-Location $abld
    Run 'flutter.bat' @('build','apk','--no-pub','--release','--target-platform','android-x64') 'b045_probe23.txt'
    Copy-Item "$abld\build\app\outputs\flutter-apk\app-release.apk" "$out\probe23-x86_64.apk" -Force
    Pop-Location
  }
  if ($step -eq 'apkx64') {
    Push-Location $abld
    Run 'flutter.bat' @('build','apk','--no-pub','--release','--split-per-abi','--target-platform','android-x64','--split-debug-info',"$YH\symbols") 'b045_apkx64.txt'
    $f = "$abld\build\app\outputs\flutter-apk\app-x86_64-release.apk"
    if (Test-Path $f) { Copy-Item $f "$out\YomiHub-$ver-x86_64.apk" -Force; Say ("APK: YomiHub-$ver-x86_64.apk ({0:N1} MB)" -f ((Get-Item $f).Length/1MB)) }
    Pop-Location
  }
  if ($step -eq 'apk64') {
    Push-Location $abld
    Run 'flutter.bat' @('build','apk','--no-pub','--release','--split-per-abi','--target-platform','android-arm64','--split-debug-info',"$YH\symbols") 'b045_apk64.txt'
    $f = "$abld\build\app\outputs\flutter-apk\app-arm64-v8a-release.apk"
    if (Test-Path $f) { Copy-Item $f "$out\YomiHub-$ver-arm64-v8a.apk" -Force; Say ("APK: YomiHub-$ver-arm64-v8a.apk ({0:N1} MB)" -f ((Get-Item $f).Length/1MB)) }
    Pop-Location
  }
  if ($step -in 'all','apk') {
    Push-Location $abld
    Run 'flutter.bat' @('build','apk','--no-pub','--release','--split-per-abi','--target-platform','android-arm,android-arm64,android-x64','--split-debug-info',"$YH\symbols") 'b045_apk.txt'
    foreach ($abi in 'arm64-v8a','armeabi-v7a','x86_64') {
      $f = "$abld\build\app\outputs\flutter-apk\app-$abi-release.apk"
      if (Test-Path $f) { Copy-Item $f "$out\YomiHub-$ver-$abi.apk" -Force; Say ("APK: YomiHub-$ver-$abi.apk ({0:N1} MB)" -f ((Get-Item $f).Length/1MB)) }
    }
    Pop-Location
  }
  if ($step -in 'all','tv') {
    Push-Location $abld
    $strXml = "$abld\android\app\src\main\res\values\strings.xml"
    $origStr = Get-Content $strXml -Raw -Encoding UTF8
    Set-Content -Path $strXml -Value ($origStr -replace '<string name="app_name">YomiHub</string>', '<string name="app_name">YumiHub Android TV</string>') -Encoding UTF8
    try {
      Run 'flutter.bat' @('build','apk','--no-pub','--release','--split-per-abi','--target-platform','android-arm,android-arm64,android-x64','--split-debug-info',"$YH\symbols_tv",'--dart-define=IS_TV_BUILD=true','--dart-define=APP_NAME=YumiHub Android TV') 'b045_tv.txt'
      foreach ($abi in 'arm64-v8a','armeabi-v7a','x86_64') {
        $f = "$abld\build\app\outputs\flutter-apk\app-$abi-release.apk"
        if (Test-Path $f) { Copy-Item $f "$out\YumiHub-Android-TV-$ver-$abi.apk" -Force; Say ("TV APK: YumiHub-Android-TV-$ver-$abi.apk ({0:N1} MB)" -f ((Get-Item $f).Length/1MB)) }
      }
    } finally { Set-Content -Path $strXml -Value $origStr -Encoding UTF8 }
    Pop-Location
  }
  if ($step -in 'all','win') {
    $ng = "$TOOLS\nuget"; $env:PATH = "$ng;" + $env:PATH
    $bld = $wbld
    Remove-Item "$bld\build\windows\x64\CMakeCache.txt" -ErrorAction SilentlyContinue
    Push-Location $bld
    Run 'flutter.bat' @('pub','get','--offline') 'b045_win_pub_get.txt'
    Run 'flutter.bat' @('gen-l10n') 'b045_win_gen_l10n.txt'
    Run 'flutter.bat' @('build','windows','--no-pub','--release') 'b045_win_build.txt'
    Pop-Location
    $out0 = $out
  $rel = "$bld\build\windows\x64\runner\Release"
  $ver = ([regex]::Match((Get-Content "$bld\pubspec.yaml" -Raw), '(?m)^version:\s*([\d\.]+)')).Groups[1].Value
  
  # YomiHub 0.1.7: helper programs for VPN & DNS (xray.exe, tor.exe + lyrebird)
  $deps = "$YH\win_deps"; $bin = "$rel\yomihub_bin"
  Remove-Item $bin -Recurse -Force -ErrorAction SilentlyContinue
  New-Item -ItemType Directory -Force "$bin\tor\pluggable_transports" | Out-Null
  if (Test-Path "$deps\xray\xray.exe") {
    Copy-Item "$deps\xray\xray.exe" $bin; Copy-Item "$deps\xray\LICENSE" "$bin\LICENSE-xray.txt" -ErrorAction SilentlyContinue
    Copy-Item "$deps\tor\tor\tor.exe" "$bin\tor"
    Copy-Item "$deps\tor\data\geoip" "$bin\tor"
    Copy-Item "$deps\tor\tor\pluggable_transports\lyrebird.exe" "$bin\tor\pluggable_transports"
    Copy-Item "$deps\tor\tor\pluggable_transports\pt_config.json" "$bin\tor\pluggable_transports"
    Copy-Item "$deps\tor\docs\tor.txt" "$bin\tor\LICENSE-tor.txt" -ErrorAction SilentlyContinue
    Copy-Item "$deps\tor\docs\lyrebird.txt" "$bin\tor\LICENSE-lyrebird.txt" -ErrorAction SilentlyContinue
    Say "yomihub_bin: xray + tor added"
  } else { Say "WARNING: $deps missing - VPN helpers not bundled" }
  # YomiHub 0.2.1: JVM bridge (Kotatsu + IReader on Windows) -> yomihub_bin\bridge\lib
  $br = "$bld\tools\yomihub_bridge"
  if (Test-Path "$br\build.gradle") {
    $g = Get-ChildItem "$YH\gradle-home\wrapper\dists\gradle-9.3.1-bin" -Recurse -Filter gradle.bat | Select-Object -First 1
    Push-Location $br
    & $g.FullName --no-daemon --console=plain installDist *>&1 | Tee-Object -FilePath "$LOGS\win_bridge.txt" | Out-Null
    Pop-Location
    $bl = "$br\build\install\yomihub-bridge\lib"
    if (Test-Path "$bl\yomihub-bridge-0.2.1.jar") {
      New-Item -ItemType Directory -Force "$bin\bridge\lib" | Out-Null
      Copy-Item "$bl\*.jar" "$bin\bridge\lib" -Force
      Say ("yomihub_bin\bridge: {0} jars ({1:N1} MB)" -f (Get-ChildItem "$bin\bridge\lib").Count, ((Get-ChildItem "$bin\bridge\lib" | Measure-Object Length -Sum).Sum/1MB))
    } else { Say "WARNING: JVM bridge build failed - see logs\win_bridge.txt" }
  }
  $zip = "$out\YomiHub-$ver-windows-x64.zip"
  Remove-Item $zip -ErrorAction SilentlyContinue
  Compress-Archive -Path "$rel\*" -DestinationPath $zip -CompressionLevel Optimal
  Say ("ZIP: {0} ({1:N1} MB)" -f (Split-Path $zip -Leaf), ((Get-Item $zip).Length/1MB))
  # full package: M-Extension-Server (JRE + JAR) preinstalled in yomihub_bin\mes
  if (Test-Path "$deps\mes-windows-x64-bundle.zip") {
    Expand-Archive "$deps\mes-windows-x64-bundle.zip" "$bin\mes" -Force
    $zipF = "$out\YomiHub-$ver-windows-x64-full.zip"
    Remove-Item $zipF -ErrorAction SilentlyContinue
    Compress-Archive -Path "$rel\*" -DestinationPath $zipF -CompressionLevel Optimal
    Say ("ZIP full: {0} ({1:N1} MB)" -f (Split-Path $zipF -Leaf), ((Get-Item $zipF).Length/1MB))
  }

  }
  if ($step -in 'all','pack') {
    Copy-Item "$out\YomiHub-$ver-windows-x64.zip" "$KIT\output\YomiHub-$ver-windows-x64.zip" -Force
    & powershell -ExecutionPolicy Bypass -File "$KIT\make_installer_exe.ps1"
    Remove-Item "$KIT\output\YomiHub-$ver-windows-x64.zip" -ErrorAction SilentlyContinue
    & powershell -ExecutionPolicy Bypass -File "$KIT\make_appxbundle.ps1"
    foreach ($n in "YomiHub-$ver-windows-x64-Setup.exe","YomiHub-$ver-windows-x64.appxbundle","YomiHub-RootCA.cer","Install-YomiHub.bat","Install-YomiHub.ps1") {
      if (Test-Path "$KIT\output\$n") { Move-Item "$KIT\output\$n" "$out\$n" -Force; Say "packed: $n" }
    }
    Get-ChildItem $out -File | Where-Object { $_.Extension -in '.apk','.exe','.zip','.appxbundle' } | ForEach-Object {
      "{0}  {1}" -f (Get-FileHash $_.FullName -Algorithm SHA256).Hash.ToLower(), $_.Name
    } | Set-Content "$out\SHA256SUMS-$ver.txt" -Encoding ascii
    Say "checksums written"
  }
  Say "BUILD 0.4.5 DONE step=$step"
} catch {
  Say "ERROR: $($_.Exception.Message)"
} finally { Pop-Location -ErrorAction SilentlyContinue; Stop-Transcript | Out-Null }
