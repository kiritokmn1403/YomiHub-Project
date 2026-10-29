param([string]$target = 'all')
# Step 2: apply YomiHub overlay on top of Mangayomi source and build the APKs
. "$PSScriptRoot\common.ps1"
# Get-CimInstance Win32_Process | Where-Object { ($_.CommandLine -match 'build_apk\.ps1' -and $_.ProcessId -ne $PID) -or $_.Name -eq 'curl.exe' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
$stamp = Get-Date -Format HHmmss
Start-Transcript "$LOGS\build_log_$stamp.txt" -Force | Out-Null
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
try {
  Remove-Item "$LOGS\status.txt" -ErrorAction SilentlyContinue
  Say "BUILD START"
  $env:PATH = "$TOOLS\android-sdk\cmake\3.22.1\bin;" + $env:PATH
  $env:CARGO_HTTP_MULTIPLEXING = "false"   # many parallel connections instead of one HTTP/2 stream
  $env:CARGO_NET_RETRY = "10"
  $src = "$KIT\src\mangayomi"; $bld = "$YH\build\mangayomi"
  if (-not (Test-Path "$src\pubspec.yaml")) { throw "Source missing - run 1_setup_tools.bat first" }

  # 1) fresh copy of the source + YomiHub overlay (keeps .dart_tool / build caches)
  New-Item -ItemType Directory -Force $bld | Out-Null
  # Flutter leaves plugin symlinks (ephemeral/.plugin_symlinks) that point into
  # the pub cache. Remove the links themselves first, or a mirror copy would
  # follow them and empty the packages they point to.
  if (Test-Path $bld) {
    Get-ChildItem $bld -Recurse -Force -Attributes ReparsePoint -ErrorAction SilentlyContinue |
      Sort-Object { $_.FullName.Length } -Descending |
      ForEach-Object { if ($_.PSIsContainer) { cmd /c rmdir "$($_.FullName)" } else { cmd /c del /f /q "$($_.FullName)" } }
  }
  # Repair packages a previous mirror run emptied: drop empty hosted package
  # folders and all git checkouts (pub re-creates them from the local git cache).
  Get-ChildItem "$env:PUB_CACHE\hosted\pub.dev" -Directory -ErrorAction SilentlyContinue |
    Where-Object { -not (Test-Path (Join-Path $_.FullName 'pubspec.yaml')) } |
    ForEach-Object { Say "  repairing pub cache: $($_.Name)"; Remove-Item $_.FullName -Recurse -Force }
  if (-not (Test-Path "$YH\pubcache-repaired.ok")) {
    Get-ChildItem "$env:PUB_CACHE\git" -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne 'cache' } |
      ForEach-Object { Remove-Item $_.FullName -Recurse -Force }
    Set-Content "$YH\pubcache-repaired.ok" ok
  }
  & robocopy $src $bld /MIR /XJ /NFL /NDL /NJH /NJS /NP /R:2 /W:2 /XD .dart_tool build .gradle ephemeral .plugin_symlinks | Out-Null
  if (Test-Path "$KIT\overlay.tgz") { & tar.exe -xzf "$KIT\overlay.tgz" -C $bld; Say "overlay.tgz applied" }
  if (Test-Path "$KIT\overlay") { & robocopy "$KIT\overlay" $bld /E /NFL /NDL /NJH /NJS /NP | Out-Null }
  # YomiHub 0.1.5: files the overlay deletes from the upstream source
  $delList = Join-Path $bld '.yh_deleted.txt'
  if (Test-Path $delList) {
    Get-Content $delList | Where-Object { $_.Trim() -ne '' } | ForEach-Object {
      $f = Join-Path $bld ($_.Trim() -replace '/', '\')
      if (Test-Path $f) { Remove-Item $f -Force; Say "  deleted $($_.Trim())" }
    }
  }
  Say "Source + overlay copied to $bld"

  # 2) Gradle distribution from a local file (GitHub CDN is slow here)
  $wp = "$bld\android\gradle\wrapper\gradle-wrapper.properties"
  $gv = ([regex]::Match((Get-Content $wp -Raw), 'gradle-([\d\.]+)-')).Groups[1].Value
  $gz = "$YH\gradle-$gv-bin.zip"
  if (-not (Test-Path $gz)) { Say "Downloading Gradle $gv"; Get-FileFast "https://services.gradle.org/distributions/gradle-$gv-bin.zip" $gz 48 }
  (Get-Content $wp) -replace '^distributionUrl=.*$', ("distributionUrl=file\:///" + ($gz -replace '\\','/')) | Set-Content $wp -Encoding ascii

  # 3) local.properties + release keystore (keep D:\yh\yomihub-release.jks safe!)
  $fl = ($env:FLUTTER_ROOT -replace '\\','\\'); $sd = ($env:ANDROID_HOME -replace '\\','\\')
  Set-Content "$bld\android\local.properties" "flutter.sdk=$fl`nsdk.dir=$sd" -Encoding ascii
  $jks = "$YH\yomihub-release.jks"; $pwf = "$YH\keystore-password.txt"
  if (-not (Test-Path $jks)) {
    $pw = -join ((48..57)+(65..90)+(97..122) | Get-Random -Count 20 | ForEach-Object {[char]$_}); $script:secret = $pw
    Set-Content $pwf $pw -Encoding ascii
    Run "$env:JAVA_HOME\bin\keytool.exe" @('-genkeypair','-v','-keystore',$jks,'-alias','yomihub','-keyalg','RSA','-keysize','2048','-validity','10000','-storepass',$pw,'-keypass',$pw,'-dname','CN=YomiHub, O=YomiHub, C=VN') 'keytool.txt'
  }
  $pw = (Get-Content $pwf -Raw).Trim()
  Set-Content "$bld\android\key.properties" ("storePassword=$pw`nkeyPassword=$pw`nkeyAlias=yomihub`nstoreFile=" + ($jks -replace '\\','/')) -Encoding ascii
  Copy-Item $jks "$KIT\yomihub-release.jks" -Force
  Copy-Item $pwf "$KIT\keystore-password.txt" -Force

  # 4) Flutter build
  Push-Location $bld
  Run 'flutter.bat' @('--version') 'flutter.txt'
  Run 'flutter.bat' @('pub','get','--offline') 'pub_get.txt'
  Run 'flutter.bat' @('gen-l10n') 'gen_l10n.txt'

  $out = "$KIT\output"; New-Item -ItemType Directory -Force $out | Out-Null
  $ver = ([regex]::Match((Get-Content "$bld\pubspec.yaml" -Raw), '(?m)^version:\s*([\d\.]+)')).Groups[1].Value

  # 4a) Standard Mobile APK build
  if ($target -in 'all','mobile') {
    Say "--- BUILDING MOBILE APKS (YomiHub $ver) ---"
    Run 'flutter.bat' @('build','apk','--no-pub','--release','--split-per-abi','--target-platform','android-arm,android-arm64,android-x64','--split-debug-info',"$YH\symbols") 'flutter_build.txt'
    foreach ($abi in 'arm64-v8a','armeabi-v7a','x86_64') {
      $f = "$bld\build\app\outputs\flutter-apk\app-$abi-release.apk"
      if (Test-Path $f) {
        Copy-Item $f "$out\YomiHub-$ver-$abi.apk" -Force
        Say ("APK: YomiHub-$ver-$abi.apk ({0:N1} MB)" -f ((Get-Item $f).Length/1MB))
      }
    }
  }

  # 4b) Dedicated Android TV APK build (YumiHub Android TV)
  if ($target -in 'all','tv') {
    Say "--- BUILDING ANDROID TV APKS (YumiHub Android TV $ver) ---"
    $strXml = "$bld\android\app\src\main\res\values\strings.xml"
    $origStr = Get-Content $strXml -Raw -Encoding UTF8
    $tvStr = $origStr -replace '<string name="app_name">YomiHub</string>', '<string name="app_name">YumiHub Android TV</string>'
    Set-Content -Path $strXml -Value $tvStr -Encoding UTF8

    try {
      Run 'flutter.bat' @('build','apk','--no-pub','--release','--split-per-abi','--target-platform','android-arm,android-arm64,android-x64','--split-debug-info',"$YH\symbols",'--dart-define=IS_TV_BUILD=true','--dart-define=APP_NAME=YumiHub Android TV') 'flutter_build_tv.txt'
      foreach ($abi in 'arm64-v8a','armeabi-v7a','x86_64') {
        $f = "$bld\build\app\outputs\flutter-apk\app-$abi-release.apk"
        if (Test-Path $f) {
          Copy-Item $f "$out\YumiHub-Android-TV-$ver-$abi.apk" -Force
          Say ("TV APK: YumiHub-Android-TV-$ver-$abi.apk ({0:N1} MB)" -f ((Get-Item $f).Length/1MB))
        }
      }
    } finally {
      Set-Content -Path $strXml -Value $origStr -Encoding UTF8
    }
  }

  Pop-Location
  Say "BUILD DONE"
} catch {
  Say "ERROR: $($_.Exception.Message)"
} finally { Pop-Location -ErrorAction SilentlyContinue; Stop-Transcript | Out-Null }
