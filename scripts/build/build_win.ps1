# Build YomiHub for Windows 10/11 x64 (needs VS 2022 Build Tools with C++).
. "$PSScriptRoot\common.ps1"
$stamp = Get-Date -Format HHmmss
Start-Transcript "$LOGS\buildwin_log_$stamp.txt" -Force | Out-Null
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
  Say "WIN BUILD START"
  $env:CARGO_HTTP_MULTIPLEXING = "false"; $env:CARGO_NET_RETRY = "10"
  $ng = "$TOOLS\nuget"; New-Item -ItemType Directory -Force $ng | Out-Null
  if (-not (Test-Path "$ng\nuget.exe")) { Say "Downloading nuget.exe"; & curl.exe -L --fail --retry 3 -o "$ng\nuget.exe" "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe" }
  $env:PATH = "$ng;" + $env:PATH
  $src = "$KIT\src\mangayomi"; $bld = "$YH\buildwin\mangayomi"
  New-Item -ItemType Directory -Force $bld | Out-Null
  Get-ChildItem $bld -Recurse -Force -Attributes ReparsePoint -ErrorAction SilentlyContinue |
    Sort-Object { $_.FullName.Length } -Descending |
    ForEach-Object { if ($_.PSIsContainer) { cmd /c rmdir "$($_.FullName)" } else { cmd /c del /f /q "$($_.FullName)" } }
  & robocopy $src $bld /MIR /XJ /NFL /NDL /NJH /NJS /NP /R:2 /W:2 /XD .dart_tool build ephemeral .plugin_symlinks | Out-Null
  if (Test-Path "$KIT\overlay.tgz") { & tar.exe -xzf "$KIT\overlay.tgz" -C $bld }
  if (Test-Path "$KIT\overlay") { & robocopy "$KIT\overlay" $bld /E /NFL /NDL /NJH /NJS /NP | Out-Null }
  & tar.exe -xzf "$KIT\overlay_win.tgz" -C $bld
  # YomiHub 0.1.5: files the overlay deletes from the upstream source
  $delList = Join-Path $bld '.yh_deleted.txt'
  if (Test-Path $delList) {
    Get-Content $delList | Where-Object { $_.Trim() -ne '' } | ForEach-Object {
      $f = Join-Path $bld ($_.Trim() -replace '/', '\')
      if (Test-Path $f) { Remove-Item $f -Force; Say "  deleted $($_.Trim())" }
    }
  }
  Say "Source + overlays copied to $bld"
  Run "$env:CARGO_HOME\bin\rustup.exe" @('target','add','x86_64-pc-windows-msvc') 'win_rustup.txt'
  # a stale cache from an earlier failed configure pins the install prefix to C:\Program Files
  Remove-Item "$bld\build\windows\x64\CMakeCache.txt" -ErrorAction SilentlyContinue
  Push-Location $bld
  Run 'flutter.bat' @('config','--enable-windows-desktop') 'win_flutter.txt'
  Run 'flutter.bat' @('pub','get','--offline') 'win_pub_get.txt'
  Run 'flutter.bat' @('gen-l10n') 'win_gen_l10n.txt'
  Run 'flutter.bat' @('build','windows','--no-pub','--release') 'win_build.txt'
  Pop-Location
  $rel = "$bld\build\windows\x64\runner\Release"
  $ver = ([regex]::Match((Get-Content "$bld\pubspec.yaml" -Raw), '(?m)^version:\s*([\d\.]+)')).Groups[1].Value
  $out = "$KIT\output"; New-Item -ItemType Directory -Force $out | Out-Null
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
  Say "WIN BUILD DONE"
} catch {
  Say "ERROR: $($_.Exception.Message)"
} finally { Pop-Location -ErrorAction SilentlyContinue; Stop-Transcript | Out-Null }
